import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics
local geom = playdate.geometry
local pd = playdate

-- --- CONSTANTS & CONFIG ---
local GRAVITY = geom.vector2D.new(0, 15) -- Gravity vector
local AIR_RESISTANCE = 0.999
local FRICTION = 0.98 -- Wall friction
local BOUNCE = 0.6 -- Elasticity
local FLIPPER_SPEED = 15 -- Radians per second approx
local FLIPPER_MAX_ANGLE = 30
local FLIPPER_MIN_ANGLE = -30

-- Game States
local STATE = { TITLE=0, GAME=1, GAMEOVER=2 }
local currentState = STATE.TITLE

local score = 0
local lives = 3
local message = ""

-- Entities Lists
local walls = {} -- Line Segments
local bumpers = {} -- Circles
local speedPads = {} -- Rect triggers
local flippers = {} -- Special objects
local ball = nil

-- --- CLASSES ---

-- 1. BALL
local Ball = {}
Ball.__index = Ball
function Ball:new(x, y)
    local s = setmetatable({}, Ball)
    s.pos = geom.vector2D.new(x, y)
    s.vel = geom.vector2D.new(0, 0)
    s.radius = 6
    s.mass = 1
    return s
end

function Ball:update(dt)
    -- Apply Forces
    self.vel = self.vel + (GRAVITY * dt * 50) -- Scale gravity
    self.vel = self.vel * AIR_RESISTANCE
    
    -- Integrate Position
    self.pos = self.pos + (self.vel * dt)
    
    -- Terminal velocity clamp (prevent tunneling)
    local maxSpeed = 1000
    if self.vel:magnitudeSquared() > maxSpeed*maxSpeed then
        self.vel = self.vel:normalized() * maxSpeed
    end
end

function Ball:draw()
    gfx.fillCircleAtPoint(self.pos.x, self.pos.y, self.radius)
end

-- 2. WALL (Line Segment)
local Wall = {}
Wall.__index = Wall
function Wall:new(x1, y1, x2, y2)
    local s = setmetatable({}, Wall)
    s.p1 = geom.vector2D.new(x1, y1)
    s.p2 = geom.vector2D.new(x2, y2)
    -- Precalculate normal/length?
    local vec = s.p2 - s.p1
    s.length = vec:magnitude()
    s.normal = geom.vector2D.new(-vec.y, vec.x):normalized() -- Left facing normal
    return s
end

function Wall:draw()
    gfx.drawLine(self.p1.x, self.p1.y, self.p2.x, self.p2.y)
end

-- 3. BUMPER (Circle)
local Bumper = {}
Bumper.__index = Bumper
function Bumper:new(x, y, r, scoreVal)
    local s = setmetatable({}, Bumper)
    s.pos = geom.vector2D.new(x, y)
    s.radius = r
    s.score = scoreVal or 100
    s.activeResultTimer = 0
    return s
end
function Bumper:draw()
    if self.activeResultTimer > 0 then
        gfx.fillCircleAtPoint(self.pos.x, self.pos.y, self.radius)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(self.pos.x, self.pos.y, self.radius)
        gfx.setColor(gfx.kColorBlack)
    else
        gfx.drawCircleAtPoint(self.pos.x, self.pos.y, self.radius)
        gfx.drawCircleAtPoint(self.pos.x, self.pos.y, self.radius - 3) -- Double ring
    end
end

-- 4. FLIPPER
local Flipper = {}
Flipper.__index = Flipper
function Flipper:new(pivotX, pivotY, angleMin, angleMax, length, isLeft)
    local s = setmetatable({}, Flipper)
    s.pivot = geom.vector2D.new(pivotX, pivotY)
    s.angle = angleMin
    s.minAngle = angleMin
    s.maxAngle = angleMax
    s.length = length
    s.isLeft = isLeft
    s.tip = geom.vector2D.new(0,0)
    s:updateTip()
    return s
end

function Flipper:updateTip()
    -- Calculate tip position based on angle
    local rad = math.rad(self.angle)
    local dx = math.cos(rad) * self.length
    local dy = math.sin(rad) * self.length
    self.tip = self.pivot + geom.vector2D.new(dx, dy)
end

function Flipper:update(dt)
    -- Control Input
    local button = self.isLeft and pd.kButtonLeft or pd.kButtonA
    local target = pd.buttonIsPressed(button) and self.maxAngle or self.minAngle
    
    -- Smooth rotation towards target
    -- Simple approach: move by speed
    local diff = target - self.angle
    local change = FLIPPER_SPEED * dt * 100 -- speed scale
    
    if math.abs(diff) < change then
        self.angle = target
        self.angularVel = 0
    else
        if diff > 0 then 
            self.angle = self.angle + change 
            self.angularVel = 1 -- Moving UP (usually)
        else 
            self.angle = self.angle - change 
            self.angularVel = -1 -- Moving DOWN
        end
    end
    
    self:updateTip()
end

function Flipper:draw()
    gfx.setLineWidth(3)
    gfx.drawLine(self.pivot.x, self.pivot.y, self.tip.x, self.tip.y)
    gfx.setLineWidth(1)
    gfx.fillCircleAtPoint(self.pivot.x, self.pivot.y, 3)
    gfx.fillCircleAtPoint(self.tip.x, self.tip.y, 3)
end

-- 5. SPEED PAD
local SpeedPad = {}
SpeedPad.__index = SpeedPad
function SpeedPad:new(x, y, w, h, vx, vy)
    local s = setmetatable({}, SpeedPad)
    s.rect = geom.rect.new(x, y, w, h)
    s.boost = geom.vector2D.new(vx, vy)
    return s
end
function SpeedPad:draw()
    gfx.drawRect(self.rect)
    -- Arrow visualization
    local center = self.rect:centerPoint()
    local cx, cy = center.x, center.y
    gfx.drawLine(cx, cy, cx + self.boost.x*0.1, cy + self.boost.y*0.1)
end


-- --- PHYSICS ENGINE ---

function resolveCollisions()
    if not ball then return end
    
    -- 1. Wall Collisions (Line Segments)
    for _, wall in ipairs(walls) do
        local segVec = wall.p2 - wall.p1
        local ptVec = ball.pos - wall.p1
        local segLen = segVec:magnitude()
        local t = (ptVec:dotProduct(segVec)) / (segLen * segLen)
        
        -- Clamp t to segment [0, 1]
        local closestT = math.max(0, math.min(1, t))
        local closestPt = wall.p1 + (segVec * closestT)
        
        local distVec = ball.pos - closestPt
        local dist = distVec:magnitude()
        
        if dist < ball.radius then
            -- COLLISION
            local normal = distVec:normalized()
            
            -- Push out
            local overlap = ball.radius - dist
            ball.pos = ball.pos + (normal * overlap)
            
            -- Reflect Velocity (Frictionless bounce to prevent sticking)
            local dot = ball.vel:dotProduct(normal)
            if dot < 0 then -- Only reflect if moving towards wall
                 -- Standard reflection with restitution: v' = v - (1 + e)(v.n)n
                 -- Preserves tangential velocity!
                 ball.vel = ball.vel - (normal * (dot * (1 + BOUNCE)))
            end
        end
    end
    
    -- 2. Flipper Collisions (Dynamic Lines)
    for _, f in ipairs(flippers) do
        -- Treat as Line Segment P1->P2
        -- Add "kick" velocity if flipper is moving
        
        local segVec = f.tip - f.pivot
        local ptVec = ball.pos - f.pivot
        local segLen = segVec:magnitude()
        local t = (ptVec:dotProduct(segVec)) / (segLen * segLen)
        local closestT = math.max(0, math.min(1, t))
        local closestPt = f.pivot + (segVec * closestT)
        local distVec = ball.pos - closestPt
        local dist = distVec:magnitude()
        local normal = geom.vector2D.new(-segVec.y, segVec.x):normalized()
        -- Ensure normal points towards ball roughly
        if distVec:dotProduct(normal) < 0 then normal = -normal end

        if dist < ball.radius + 2 then -- Slightly fatter check for fast flippers
            -- Penetration fix
            local overlap = (ball.radius + 2) - dist
            ball.pos = ball.pos + (normal * overlap)
            
            -- Bounce
            local dot = ball.vel:dotProduct(normal)
            if dot < 0 then
               -- Frictionless bounce
               local bounceVel = ball.vel - (normal * (dot * (1 + BOUNCE)))
               -- ADD FLIPPER KICK
               -- If flipper is moving UP (towards ball usually)
               -- Simple logic: if angularVel != 0, add kick
               -- Kick direction matches normal?
               if f.angularVel ~= 0 then
                   -- Is the flipper hitting the ball or receding?
                   -- Simplification: If button pressed, add boost
                   local button = f.isLeft and pd.kButtonLeft or pd.kButtonA
                   if pd.buttonIsPressed(button) then
                        bounceVel = bounceVel + (normal * 600) -- KICK! (Boosted)
                   end
               end
               
               ball.vel = bounceVel
            end
        end
    end
    
    -- 3. Bumper Collisions (Circle)
    for _, bump in ipairs(bumpers) do
        local distVec = ball.pos - bump.pos
        local dist = distVec:magnitude()
        local minDist = ball.radius + bump.radius
        
        if dist < minDist then
            -- Collision
            local normal = distVec:normalized()
            local overlap = minDist - dist
            ball.pos = ball.pos + (normal * overlap)
            
            local dot = ball.vel:dotProduct(normal)
            if dot < 0 then
                ball.vel = (ball.vel - (normal * (2 * dot))) * 1.5 -- Super bounce!
                score = score + bump.score
                bump.activeResultTimer = 10
            end
        end
    end
    
    -- 4. Speed Pads
    for _, pad in ipairs(speedPads) do
        if pad.rect:containsPoint(ball.pos.x, ball.pos.y) then
             -- Only boost if moving roughly in direction of boost (UP)
             -- Prevention of sticking when falling down
             if ball.vel.y < 0 then 
                ball.vel = ball.vel + (pad.boost * 0.1)
             end
        end
    end
    
    -- 5. Screen Boundaries (just bottom death)
    if ball.pos.y > 250 then
        return "dead"
    end
    
    return "alive"
end

-- --- GAME LOGIC ---

function setupBoard()
    walls = {}
    bumpers = {}
    flippers = {}
    speedPads = {}
    
    -- 1. Outer Walls
    -- Left + Safety Layer
    table.insert(walls, Wall:new(0, 0, 0, 240))
    table.insert(walls, Wall:new(-10, 0, -10, 240)) -- Double thick
    
    -- Right + Safety Layer
    table.insert(walls, Wall:new(400, 0, 400, 240))
    table.insert(walls, Wall:new(410, 0, 410, 240)) -- Double thick
    
    -- Top (Approximated Arch) + Safety Layer (Offset up by 10)
    table.insert(walls, Wall:new(0, 50, 50, 10))
    table.insert(walls, Wall:new(-10, 40, 50, 0)) -- Backup
    
    table.insert(walls, Wall:new(50, 10, 150, 0))
    table.insert(walls, Wall:new(50, 0, 150, -10)) -- Backup
    
    table.insert(walls, Wall:new(150, 0, 250, 0))
    table.insert(walls, Wall:new(150, -10, 250, -10)) -- Backup
    
    table.insert(walls, Wall:new(250, 0, 350, 10)) 
    table.insert(walls, Wall:new(250, -10, 350, 0)) -- Backup
    
    table.insert(walls, Wall:new(350, 10, 400, 50))
    table.insert(walls, Wall:new(350, 0, 410, 40)) -- Backup
    
    -- Bottom Funnel (Leading to flippers)
    -- Shifted UP by 20px total (Original-20)
    table.insert(walls, Wall:new(0, 130, 110, 205)) -- Left slope - Overlapped
    table.insert(walls, Wall:new(370, 130, 260, 205)) -- Right slope (Lane) - Overlapped
    
    -- Plunger Lane Wall
    table.insert(walls, Wall:new(370, 100, 370, 240))
    
    -- 2. Flippers
    -- Shifted Y to 200. Length 65.
    -- Left Flipper: Pivot at (100, 200).
    table.insert(flippers, Flipper:new(100, 200, 30, -30, 65, true)) 
    
    -- Right Flipper: Pivot at (270, 200).
    table.insert(flippers, Flipper:new(270, 200, 150, 210, 65, false))
    
    -- 3. Bumpers
    -- Shifted Y (Top 80, Mids 110)
    table.insert(bumpers, Bumper:new(200, 80, 15, 100)) -- Center Top
    table.insert(bumpers, Bumper:new(140, 110, 12, 50)) -- Left Mid
    table.insert(bumpers, Bumper:new(260, 110, 12, 50)) -- Right Mid
    
    -- Rubber Posts (Seal the gaps above flippers)
    -- Shifted Y to 195
    table.insert(bumpers, Bumper:new(90, 195, 10, 0)) -- Left Post
    table.insert(bumpers, Bumper:new(270, 195, 5, 0)) -- Right Post
    
    -- 4. Speed Pads / Ramps
    -- Shifted Y to 90
    table.insert(speedPads, SpeedPad:new(20, 90, 20, 60, 0, -400)) 
end

function spawnBall()
    ball = Ball:new(385, 200) -- In Plunger Lane
    -- Initial shot velocity? Or manual plunger?
    -- Let's give it a manual plunger logic or just auto-shoot for now
    ball.vel = geom.vector2D.new(0, -700) -- Auto launch (Boosted)
end

function resetGame()
    score = 0
    lives = 3
    setupBoard()
    spawnBall()
    currentState = STATE.GAME
end

function updateGame()
    local frameDt = 1.0/30.0
    local steps = 8 -- Increased to 8 for high speed safety
    local dt = frameDt / steps
    
    for i=1, steps do
        -- Update Ball
        if ball then
            local status = ball:update(dt)
            local resolveStatus = resolveCollisions()
            
            if status == "dead" or resolveStatus == "dead" then
                lives = lives - 1
                if lives > 0 then
                    spawnBall()
                else
                    ball = nil
                    currentState = STATE.GAMEOVER
                end
                break -- Create new ball next frame
            end
        end
        
        -- Update Flippers (Physics logic needs to run here too for smooth movement in substeps)
        for _, f in ipairs(flippers) do f:update(dt) end
        
        -- Update Bumpers (anim)
        for _, b in ipairs(bumpers) do 
            if b.activeResultTimer > 0 then b.activeResultTimer = b.activeResultTimer - (1/steps) end
        end
    end
end

function drawGame()
    -- Draw Board
    gfx.setLineWidth(2)
    for _, w in ipairs(walls) do w:draw() end
    
    for _, b in ipairs(bumpers) do b:draw() end
    
    for _, f in ipairs(flippers) do f:draw() end
    
    for _, s in ipairs(speedPads) do s:draw() end
    
    if ball then ball:draw() end
    
    -- UI
    gfx.drawText("Score: " .. score, 10, 10)
    gfx.drawText("Lives: " .. lives, 300, 10)
end

function pd.update()
    gfx.clear()
    playdate.timer.updateTimers()
    
    if currentState == STATE.TITLE then
        gfx.drawTextAligned("*SUPER PINBALL*", 200, 80, kTextAlignment.center)
        gfx.drawTextAligned("Start: A Button", 200, 120, kTextAlignment.center)
        gfx.drawTextAligned("Flippers: Left / A", 200, 140, kTextAlignment.center)
        
        if pd.buttonJustPressed(pd.kButtonA) then
            resetGame()
        end
    elseif currentState == STATE.GAMEOVER then
         gfx.drawTextAligned("GAME OVER", 200, 80, kTextAlignment.center)
         gfx.drawTextAligned("Final Score: " .. score, 200, 110, kTextAlignment.center)
         gfx.drawTextAligned("Restart: A", 200, 150, kTextAlignment.center)
         
         if pd.buttonJustPressed(pd.kButtonA) then
            resetGame()
         end
    else
        updateGame()
        drawGame()
    end
end

function init()
    math.randomseed(pd.getSecondsSinceEpoch())
    -- setupBoard() -- Optional pre-setup if needed, but resetGame does it
end

init()
