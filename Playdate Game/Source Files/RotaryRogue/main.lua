import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/ui"
import "CoreLibs/timer"
import "CoreLibs/easing"

local gfx = playdate.graphics
local snd = playdate.sound

-- Game Constants
local SCREEN_W <const> = 400
local SCREEN_H <const> = 240
local CENTER_X <const> = 200
local CENTER_Y <const> = 120
local MAX_DEPTH = 1000
local FOCAL_LENGTH = 150 -- Adjust for FOV
local BASE_RADIUS = 120  -- Radius at z=0 (Screen Plane). Matches Player distance.

local MOVE_SPEED_INITIAL = 10
local SPAWN_RATE_INITIAL = 35 -- Frames

-- Game State
local state = "menu" -- menu, playing, gameover
local score = 0
local highScore = 0
local speed = MOVE_SPEED_INITIAL
local spawnTimer = 0
local tunnelRotation = 0

-- Entities
local obstacles = {}
local particles = {}

-- Audio
local crashSynth = snd.synth.new(snd.kWaveNoise)
local scoreSynth = snd.synth.new(snd.kWaveSine)
local musicSeq = nil

-- Setup Audio
-- Setup Audio
local function setupAudio()
    -- Simple crash sound
    -- Fix: Use 0 sustain so it fades out automatically without needing noteOff
    crashSynth:setAttack(0.01)
    crashSynth:setDecay(0.3)
    crashSynth:setSustain(0.0) 
    crashSynth:setRelease(0.1)
    
    -- Score sound
    scoreSynth:setAttack(0.01)
    scoreSynth:setDecay(0.05)
    scoreSynth:setSustain(0.0)
    scoreSynth:setRelease(0.05)
    
    -- Background Music (Simple arpeggio)
    musicSeq = snd.sequence.new()
    local track = musicSeq:addTrack()
    local notes = {60, 64, 67, 72, 67, 64} -- C major ish
    for i, note in ipairs(notes) do
        track:addNote(i, note, 1)
    end
    musicSeq:setLoops(0, -1) -- Loop infinitely
end

setupAudio()

-- Visual Helpers
local function getScale(depth)
    -- Prevent divide by zero if objects get too close behind camera
    local d = math.max(depth + FOCAL_LENGTH, 1)
    return FOCAL_LENGTH / d
end

local function drawTunnelRing(depth)
    local scale = getScale(depth)
    local radius = BASE_RADIUS * scale
    
    if radius < 1 then return end
    
    gfx.setLineWidth(math.max(1, 4 * scale))
    -- Using gray for wireframe depth
    if depth > 500 then gfx.setColor(gfx.kColorWhite) else gfx.setColor(gfx.kColorWhite) end
    gfx.drawCircleAtPoint(CENTER_X, CENTER_Y, radius)
end

-- Game Logic
local function resetGame()
    score = 0
    speed = MOVE_SPEED_INITIAL
    spawnTimer = 0
    tunnelRotation = 0
    obstacles = {}
    particles = {}
    musicSeq:play()
    crashSynth:noteOff() -- Ensure sound stops
end

local function spawnObstacle()
    local angle = math.random(0, 360)
    local width = math.random(60, 100) -- Degrees
    table.insert(obstacles, {
        depth = MAX_DEPTH,
        angle = angle,
        width = width,
        passed = false
    })
end

local function createExplosion()
    for i=1, 25 do
        table.insert(particles, {
            x = CENTER_X,
            y = CENTER_Y + BASE_RADIUS, -- Explosion where player is
            vx = math.random(-8, 8),
            vy = math.random(-8, 8),
            life = 40
        })
    end
end

local function updateGame()
    -- Input
    local change = playdate.getCrankChange()
    tunnelRotation -= change

    -- Obstacles
    spawnTimer += 1
    if spawnTimer > math.max(15, SPAWN_RATE_INITIAL - (score * 0.4)) then
        spawnObstacle()
        spawnTimer = 0
    end

    speed = MOVE_SPEED_INITIAL + (score * 0.05)

    for i = #obstacles, 1, -1 do
        local ob = obstacles[i]
        ob.depth -= speed

        -- Collision Zone
        local COLLISION_DEPTH_START = 20
        local COLLISION_DEPTH_END = -20
        
        if ob.depth <= COLLISION_DEPTH_START and ob.depth >= COLLISION_DEPTH_END then
             -- Check collision
            local playerAngle = 90
            local obsScreenAngle = (ob.angle + tunnelRotation) % 360
            
            -- Normalize difference to -180..180
            local diff = (playerAngle - obsScreenAngle + 360) % 360
            if diff > 180 then diff = diff - 360 end
            diff = math.abs(diff)
            
            local forgiveness = 10 
            local safeWidth = math.max(0, ob.width - forgiveness)
            
            if diff < (safeWidth / 2) then
                 -- CRASH
                if not ob.passed then
             
                    -- Debug: Visually confirm hit
                    -- State change handles this, but maybe we want to see it?
                    
                    crashSynth:playNote(60)
                    musicSeq:stop()
                    createExplosion()
                    if score > highScore then highScore = score end
                    state = "gameover"
                end
            end
        end
        
        if ob.depth < COLLISION_DEPTH_END and not ob.passed then
            ob.passed = true
            score += 1
            scoreSynth:playNote(80, 0.5) 
        end

        if ob.depth < -200 then
            table.remove(obstacles, i)
        end
    end
    
    -- Particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x += p.vx
        p.y += p.vy
        p.life -= 1
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

-- Drawing
local function drawGame()
    gfx.clear(gfx.kColorBlack)
    gfx.setColor(gfx.kColorWhite)
    
    -- Draw Infinite Tunnel
    local ringGap = 100
    local offset = (playdate.getCurrentTimeMilliseconds() * (speed/20)) % ringGap
    
    for d = 0, MAX_DEPTH, ringGap do
        local drawDepth = MAX_DEPTH - d - offset
        if drawDepth > -100 then
            drawTunnelRing(drawDepth)
        end
    end
    
    -- Draw Obstacles
    for _, ob in ipairs(obstacles) do
        local scale = getScale(ob.depth)
        local radius = BASE_RADIUS * scale
        
        if scale > 0 and radius > 1 then
             -- Made obstacles thicker (was 8) for better visibility
             local thickness = 15 * scale
             local drawAngleStart = (ob.angle + tunnelRotation) - (ob.width/2)
             local drawAngleEnd = (ob.angle + tunnelRotation) + (ob.width/2)
             
             gfx.setLineWidth(math.max(3, thickness))
             
             -- Draw Main Wall (White)
             gfx.drawArc(CENTER_X, CENTER_Y, radius, drawAngleStart, drawAngleEnd)
             
             -- Draw Active Hitbox (Dithered/Checkerboard) ON TOP
             -- Hitbox is narrower than visual wall (Forgiveness)
             if ob.depth <= 20 and ob.depth >= -20 then
                 local forgiveness = 15 -- Increased forgiveness to 15 degrees
                 local safeW = math.max(0, ob.width - forgiveness)
                 local hitStart = (ob.angle + tunnelRotation) - (safeW/2)
                 local hitEnd = (ob.angle + tunnelRotation) + (safeW/2)
                 
                 gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer4x4)
                 -- Draw the DANGER ZONE (The part that actually kills you)
                 -- It should be smaller than the white wall.
                 gfx.drawArc(CENTER_X, CENTER_Y, radius, hitStart, hitEnd)
                 gfx.setColor(gfx.kColorWhite) -- Reset
                 
                 -- Debug: Draw Player Collision Line
                 -- gfx.drawLine(CENTER_X, CENTER_Y, CENTER_X, CENTER_Y + BASE_RADIUS)
             end
        end
    end
    
    -- Draw Player
    local playerY = CENTER_Y + BASE_RADIUS
    gfx.setColor(gfx.kColorWhite)
    gfx.fillTriangle(CENTER_X, playerY - 10, CENTER_X - 10, playerY + 10, CENTER_X + 10, playerY + 10)
    
    -- Debug: Draw Collision Zone Ring
    -- gfx.setLineWidth(1)
    -- gfx.drawCircleAtPoint(CENTER_X, CENTER_Y, BASE_RADIUS)
    
    -- HUD
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("Score: " .. score, 5, 5)
    
    -- Particles
    for _, p in ipairs(particles) do
        gfx.fillCircleAtPoint(p.x, p.y, 2)
    end
end

local function drawMenu()
    gfx.clear()
    gfx.drawTextAligned("*ROTARY ROGUE*", CENTER_X, 80, kTextAlignment.center)
    gfx.drawTextAligned("High Score: " .. highScore, CENTER_X, 110, kTextAlignment.center)
    
    if playdate.getCurrentTimeMilliseconds() % 1000 < 500 then
        gfx.drawTextAligned("Crank to Start", CENTER_X, 150, kTextAlignment.center)
    end
end

local function drawGameOver()
    -- Draw game underlay
    drawGame()
    
    -- Overlay
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(50, 80, 300, 80)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(50, 80, 300, 80)
    
    -- Fix: Ensure text is drawn in black (FillBlack) so it's visible on white background
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.drawTextAligned("CRASHED!", CENTER_X, 90, kTextAlignment.center)
    gfx.drawTextAligned("Final Score: " .. score, CENTER_X, 115, kTextAlignment.center)
    gfx.drawTextAligned("Press A to Restart", CENTER_X, 140, kTextAlignment.center)
end


function playdate.update()
    if state == "menu" then
        if math.abs(playdate.getCrankChange()) > 5 then
            resetGame()
            state = "playing"
        end
        drawMenu()
    elseif state == "playing" then
        updateGame()
        drawGame()
    elseif state == "gameover" then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            resetGame()
            state = "playing"
        end
        drawGameOver()
    end
end
