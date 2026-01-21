import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/crank"
import "CoreLibs/timer"

import "Core"
import "Shield"
import "Asteroid"

import "Starfield"
import "Explosion"
import "AudioManager"

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Global Variables
local gameState = "start" -- "start", "play", "gameover"
local score = 0
local highScore = 0

local core = nil
local shield = nil
local starfield = nil
local asteroidTimer = nil
local audioManager = nil

local centerX = 200
local centerY = 120

-- Initialize
math.randomseed(pd.getSecondsSinceEpoch())

function startGame()
    gfx.sprite.removeAll()
    
    score = 0
    
    if not audioManager then
        audioManager = AudioManager()
    end
    audioManager:startMusic()
    
    -- Background
    starfield = Starfield()
    starfield:add()
    
    core = Core(centerX, centerY)
    core:add()
    
    shield = Shield(centerX, centerY, 30)
    shield:add()
    
    gameState = "play"
    
    -- Spawn asteroids every 1-2 seconds
    asteroidTimer = pd.timer.new(1500, spawnAsteroid)
    asteroidTimer.repeats = true
end

function spawnAsteroid()
    if gameState == "play" then
        local a = Asteroid(centerX, centerY)
        a:add()
        -- Speed up over time?
        local nextTime = math.max(500, 1500 - (score * 10))
        asteroidTimer.duration = nextTime
    end
end

function checkCollisions()
    local asteroids = gfx.sprite.getAllSprites()
    for _, sprite in ipairs(asteroids) do
        if sprite:isa(Asteroid) then
            -- Check collision with Shield
            -- Since Shield is an arc, simple rect collision might be too generous, 
            -- but for now let's use the built-in collision check or distance.
            
            -- Specifically check if Asteroid overlaps Shield sprite
             -- Ideally we check angle, but let's use the collision rects for now.
             local actualX, actualY, cols, len = sprite:checkCollisions(sprite.x, sprite.y)
             for _, col in ipairs(cols) do
                local other = col.other
                if other == shield then
                     -- Check relative angle
                     local dx = sprite.x - shield.x
                     local dy = sprite.y - shield.y
                     local angleToAst = math.deg(math.atan2(dy, dx)) + 90 -- adjust for sprite rotation 0 being up?
                     
                     -- Shield rotation is the angle.
                     -- Shield draws arc from -45 to +45 (90 deg total) relative to its rotation.
                     local shieldRot = shield:getRotation() 
                     
                     -- Normalize angles
                     local diff = (angleToAst - shieldRot) % 360
                     if diff > 180 then diff -= 360 end
                     
                     -- If within arc range (approx 45 degrees either side)
                     if math.abs(diff) < 45 then 
                         -- Check Distance to avoid corner hits on square collision rect
                         local dist = math.sqrt(dx*dx + dy*dy)
                         local astRadius = sprite.width / 2
                         -- Visual outer edge is approx 33 + buffer
                         if dist < (34 + astRadius + 4) then
                             local ex = Explosion(sprite.x, sprite.y)
                             ex:add()
                             audioManager:playExplosion()
                             
                             sprite:remove()
                             score += 10
                             break -- Stop checking collisions for this asteroid (it's gone)
                         end
                     end
                elseif other == core then
                     local ex = Explosion(sprite.x, sprite.y)
                     ex:add()
                     audioManager:playHit()
                     
                     sprite:remove()
                     core:hit(20)
                     if core.health <= 0 then
                         gameOver()
                     end
                     -- TODO: Shake effect
                end
             end
        end
    end
end

function gameOver()
    gameState = "gameover"
    if score > highScore then
        highScore = score
    end
    if asteroidTimer then
        asteroidTimer:remove()
    end
    if audioManager then
        audioManager:stopMusic()
    end
end

function playdate.update()
    pd.timer.updateTimers()
    gfx.clear()
    
    if gameState == "start" then
        gfx.drawTextAligned("COSMIC CRANK", centerX, 80, kTextAlignment.center)
        gfx.drawTextAligned("Press A to Start", centerX, 140, kTextAlignment.center)
        
        if pd.buttonJustPressed(pd.kButtonA) then
            startGame()
        end
        
    elseif gameState == "play" then
        gfx.sprite.update()
        checkCollisions()
        
        -- HUD
        gfx.fillRect(0, 0, 400, 20) -- Top bar background
        gfx.setColor(gfx.kColorWhite)
        gfx.drawText("Score: " .. score, 10, 2)
        
        -- Health Bar
        local hpWidth = (core.health / 100) * 100
        gfx.drawRect(290, 5, 102, 12)
        gfx.fillRect(291, 6, hpWidth, 10)
        
        gfx.setColor(gfx.kColorBlack) -- Reset for other drawing if needed
        
        -- manual shield update and asteroid update handled by gfx.sprite.update()
        
    elseif gameState == "gameover" then
        gfx.sprite.update() -- Freeze them or keep moving? Let's keep drawing them.
        
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(centerX - 80, centerY - 40, 160, 80)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(centerX - 80, centerY - 40, 160, 80)
        
        gfx.drawTextAligned("GAME OVER", centerX, centerY - 20, kTextAlignment.center)
        gfx.drawTextAligned("Score: " .. score, centerX, centerY, kTextAlignment.center)
        gfx.drawTextAligned("Press A to Restart", centerX, centerY + 20, kTextAlignment.center)
        
        if pd.buttonJustPressed(pd.kButtonA) then
            startGame() -- resets everything
        end
    end
end
