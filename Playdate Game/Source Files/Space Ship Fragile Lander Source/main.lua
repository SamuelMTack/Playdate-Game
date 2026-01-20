import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx = playdate.graphics
local geo = playdate.geometry
local pd = playdate

-- --- CONSTANTS ---
local GRAVITY = 0.05
local THRUST_POWER = 0.12
local ROTER_SPEED = 3
local FRICTION = 0.999 -- Space drag (very low)
local SAFE_LANDING_SPEED = 1.5
local SAFE_LANDING_ANGLE = 15 -- degrees
local START_FUEL = 500

-- --- STATE ---
local lander = {}
local terrain = {} -- Array of Points
local pads = {} -- Array of indices {start, end} that are flat
local particles = {}
local gameState = "TITLE" -- TITLE, PLAYING, LANDED, CRASHED
local message = ""

-- --- CLASSES ---

-- 1. LANDER
function initLander()
    lander = {
        pos = geo.point.new(200, 30),
        vel = geo.vector2D.new(0.5, 0), -- Initial drift
        angle = 0, -- degrees, 0 is pointing UP
        fuel = START_FUEL,
        radius = 8,
        shape = nil, -- Base shape
        poly = nil -- Transformed polygon for collision
    }
    
    -- Define the triangle shape once
    local p1 = geo.point.new(0, -10) -- Nose
    local p2 = geo.point.new(-7, 7) -- Left Leg
    local p3 = geo.point.new(7, 7) -- Right Leg
    lander.shape = geo.polygon.new(p1, p2, p3)
end

function updateLander()
    if gameState ~= "PLAYING" then return end
    
    -- Inputs
    if pd.buttonIsPressed(pd.kButtonLeft) then
        lander.angle -= ROTER_SPEED
    end
    if pd.buttonIsPressed(pd.kButtonRight) then
        lander.angle += ROTER_SPEED
    end
    
    local thrusting = false
    if (pd.buttonIsPressed(pd.kButtonA) or pd.buttonIsPressed(pd.kButtonUp)) and lander.fuel > 0 then
        thrusting = true
        lander.fuel -= 1
        -- Calculate thrust vector (Angle 0 is UP (0, -1))
        -- playdate coordinates: Y is Down.
        -- Angle 0 should thrust UP (0, -1). 
        -- Rotation is clockwise.
        -- rad(0) -> [0, -1]. rad(90) -> [1, 0]
        local rad = math.rad(lander.angle - 90)
        local thrust = geo.vector2D.new(math.cos(rad), math.sin(rad)) * THRUST_POWER
        lander.vel += thrust
        
        -- Add Particle
        local pPos = lander.pos - (thrust * 50) -- opposite direction
        addParticle(lander.pos.x, lander.pos.y, math.random(-10,10)*0.1, math.random(10,30)*0.1)
    end
    
    -- Gravity
    lander.vel.y += GRAVITY
    
    -- Friction/Air Resistance (minimal)
    lander.vel *= FRICTION
    
    -- Update Position
    lander.pos += lander.vel
    
    -- Wrap Screen X
    if lander.pos.x < 0 then lander.pos.x = 400 end
    if lander.pos.x > 400 then lander.pos.x = 0 end
    
    -- Update Polygon for drawing/collision
    -- Manual transform for safety: Local Rotation FIRST, then World Translation
    
    -- 1. Create Rotation Matrix
    local rot = geo.affineTransform.new()
    rot:rotate(lander.angle)
    
    -- 2. Rotate Local Points
    local p1_rot = rot * geo.point.new(0, -10)
    local p2_rot = rot * geo.point.new(-7, 7)
    local p3_rot = rot * geo.point.new(7, 7)
    
    -- 3. Add World Position (Translation)
    local p1 = geo.point.new(p1_rot.x + lander.pos.x, p1_rot.y + lander.pos.y)
    local p2 = geo.point.new(p2_rot.x + lander.pos.x, p2_rot.y + lander.pos.y)
    local p3 = geo.point.new(p3_rot.x + lander.pos.x, p3_rot.y + lander.pos.y)
    
    -- Construct using explicit coordinates
    lander.poly = geo.polygon.new(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y)
    lander.poly:close() 
    
    checkCollision()
end

function drawLander()
    if gameState == "CRASHED" then return end
    
    gfx.setLineWidth(2)
    -- Collision uses the poly, let's draw it
    if lander.poly then
        gfx.drawPolygon(lander.poly)
    end
    
    -- Flame
    if (pd.buttonIsPressed(pd.kButtonA) or pd.buttonIsPressed(pd.kButtonUp)) and lander.fuel > 0 then
        -- Same explicit transform for flame
        local rot = geo.affineTransform.new()
        rot:rotate(lander.angle)
        
        local f1_rot = rot * geo.point.new(-4, 7)
        local f2_rot = rot * geo.point.new(4, 7)
        local f3_rot = rot * geo.point.new(0, 15 + math.random(0,5))
        
        -- Add world pos
        local f1 = geo.point.new(f1_rot.x + lander.pos.x, f1_rot.y + lander.pos.y)
        local f2 = geo.point.new(f2_rot.x + lander.pos.x, f2_rot.y + lander.pos.y)
        local f3 = geo.point.new(f3_rot.x + lander.pos.x, f3_rot.y + lander.pos.y)
        
        gfx.drawLine(f1.x, f1.y, f3.x, f3.y)
        gfx.drawLine(f2.x, f2.y, f3.x, f3.y)
    end
    gfx.setLineWidth(1)
end


-- 2. TERRAIN
function generateTerrain()
    terrain = {}
    pads = {}
    
    -- Simple heightmap generation
    local segments = 20
    local step = 420 / segments
    local x = -10
    local y = 180
    
    -- We want 2 guaranteed flat spots
    local flatOne = math.random(3, 8)
    local flatTwo = math.random(12, 17)
    
    for i=0, segments do
        if i == flatOne or i == flatOne+1 or i == flatTwo or i == flatTwo+1 then
            -- Flat! (Landing Pad)
            -- Keep Y same as previous
            local prevY = (i>0) and terrain[#terrain].y or 200
            y = prevY
            
            -- Store pad info
            if i == flatOne then table.insert(pads, {start=i, type="x2"}) end
            if i == flatTwo then table.insert(pads, {start=i, type="x5"}) end
        else
            -- Jagged
            y = math.random(150, 230)
        end
        x = i * step
        table.insert(terrain, geo.point.new(x, y))
    end
end

function drawTerrain()
    for i=1, #terrain-1 do
        local p1 = terrain[i]
        local p2 = terrain[i+1]
        
        -- Check if this segment is a pad
        local isPad = false
        if p1.y == p2.y then 
             gfx.setLineWidth(3)
             gfx.drawLine(p1.x, p1.y, p2.x, p2.y)
             
             -- Draw Multiplier Text below pad
             if (i % 2 == 0) then -- Hacky check, but good enough visually
                 gfx.drawTextAligned("PAD", (p1.x+p2.x)/2, p1.y+5, kTextAlignment.center)
             end
             gfx.setLineWidth(1)
        else
             gfx.drawLine(p1.x, p1.y, p2.x, p2.y)
        end
    end
end


-- 3. PARTICLES
function addParticle(x, y, vx, vy)
    table.insert(particles, {x=x, y=y, vx=vx, vy=vy, life=20})
end

function updateParticles()
    for i=#particles, 1, -1 do
        local p = particles[i]
        p.x += p.vx
        p.y += p.vy
        p.life -= 1
        if p.life <= 0 then table.remove(particles, i) end
    end
end

function drawParticles()
    for _, p in ipairs(particles) do
        gfx.drawPixel(p.x, p.y)
    end
end

-- 4. COLLISION
function checkCollision()
    if not lander.poly then return end
    
    -- Check screen bounds (Floor is implicit by terrain, but just in case)
    if lander.pos.y > 240 then 
        crash() 
        return
    end
    
    -- Check Terrain Intersection
    -- We check line segment intersections between Lander Poly edges and Terrain segments
    
    local polyCount = lander.poly:count()
    
    for i=1, #terrain-1 do
        local t1 = terrain[i]
        local t2 = terrain[i+1]
        local tLine = geo.lineSegment.new(t1.x, t1.y, t2.x, t2.y)
        
        -- Check intersects with any lander edge
        -- polygon:intersects only checks against other polygons.
        -- We must check edge vs edge.
        local hit = false
        local count = lander.poly:count()
        for j=1, count do
            local pA = lander.poly:getPointAt(j)
            local pB = lander.poly:getPointAt((j % count) + 1)
            local edge = geo.lineSegment.new(pA.x, pA.y, pB.x, pB.y)
            
            if edge:intersectsLineSegment(tLine) then
                hit = true
                break
            end
        end

        if hit then
            -- Collision detected!
            -- Is it a landing or a crash?
            
            -- Logic:
            -- 1. Must be a flat segment (t1.y == t2.y)
            -- 2. Must be Landing Legs (p2, p3) touching, not Nose (p1)
            -- 3. Speed must be low
            -- 4. Angle must be upright
            
            local isFlat = (t1.y == t2.y)
            local speed = lander.vel:magnitude()
            local angleOk = (math.abs(lander.angle) % 360) < SAFE_LANDING_ANGLE or (math.abs(lander.angle) % 360) > (360-SAFE_LANDING_ANGLE)
            local speedOk = (speed < SAFE_LANDING_SPEED)
            
            if isFlat and speedOk and angleOk then
                landSuccess()
            else
                crash()
            end
            return
        end
    end
end

function crash()
    gameState = "CRASHED"
    message = "CRASHED! Too Fast or Bad Angle."
    -- Explosion particles
    for i=1, 20 do
        addParticle(lander.pos.x, lander.pos.y, math.random(-20,20)*0.1, math.random(-20,20)*0.1)
    end
end

function landSuccess()
    gameState = "LANDED"
    message = "TOUCHDOWN! Perfect Landing."
end


-- --- MAIN LOOP ---

math.randomseed(pd.getSecondsSinceEpoch())

initLander()
generateTerrain()

function resetGame()
    initLander()
    generateTerrain()
    gameState = "PLAYING"
    message = ""
end

function pd.update()
    gfx.clear(gfx.kColorWhite)
    gfx.setColor(gfx.kColorBlack) -- Ensure we draw in black by default
    
    if gameState == "TITLE" then
        gfx.drawTextAligned("Space Ship Fragile Lander", 200, 100, kTextAlignment.center)
        gfx.drawTextAligned("Press A to Launch", 200, 140, kTextAlignment.center)
        if pd.buttonJustPressed(pd.kButtonA) then
            resetGame()
        end
    else
        -- Update
        updateLander()
        updateParticles()
        
        -- Draw
        drawTerrain()
        drawLander()
        drawParticles()
        
        -- UI
        gfx.drawText("FUEL: " .. math.floor(lander.fuel), 5, 5)
        gfx.drawText("VEL: " .. math.floor(lander.vel:magnitude()*10), 5, 20)
        
        if gameState == "CRASHED" or gameState == "LANDED" then
            -- Black Box
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(20, 100, 360, 50)
            
            -- White Border
            gfx.setColor(gfx.kColorWhite)
            gfx.drawRect(22, 102, 356, 46)
            
            -- White Text
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.drawTextAligned(message, 200, 110, kTextAlignment.center)
            gfx.drawTextAligned("Press B to Restart", 200, 130, kTextAlignment.center)
            gfx.setImageDrawMode(gfx.kDrawModeCopy) -- Reset
            
            if pd.buttonJustPressed(pd.kButtonB) then
                resetGame()
            end
        end
    end
end
