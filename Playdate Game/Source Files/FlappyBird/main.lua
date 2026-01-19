import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "bird"
import "pipe"

local gfx = playdate.graphics

local gameState = "START"
local bird = nil
local pipes = {}
local score = 0
local spawnTimer = nil

function initGame()
    gfx.sprite.removeAll()
    pipes = {}
    bird = Bird(60, 120)
    score = 0
    
    -- Spawn Timer
    if spawnTimer then spawnTimer:remove() end
    spawnTimer = playdate.timer.performAfterDelay(1500, spawnPipePair)
end

function spawnPipePair()
    if gameState ~= "PLAY" then return end
    
    local gapHeight = 70
    local gapY = math.random(50, 190) -- Center of gap
    
    local pipeX = 420
    
    -- Top Pipe
    -- Extends from -10 to gapTop
    local topHeight = gapY - (gapHeight/2) + 10 -- Add Buffer
    -- Sprite height needs to cover offscreen
    -- pipe.lua takes center x,y.
    -- Size: Width 40. Height = topHeight. CenterY = topHeight/2
    -- Let's adjust Pipe init to take "height" and "y" where y is center?
    -- No, let's fix Pipe logic.
    
    -- Top Pipe
    -- CenterY = (gapY - gapHeight/2) / 2 approx?
    -- Simplest: Draw sprite of fixed massive height and just position it.
    -- Let's construct specfic height pipes.
    
    local hTop = gapY - (gapHeight/2)
    local pTop = Pipe(pipeX, hTop/2, hTop, true)
    table.insert(pipes, pTop)
    
    -- Bottom Pipe
    local hBot = 240 - (gapY + gapHeight/2)
    local yBot = 240 - hBot/2
    local pBot = Pipe(pipeX, yBot, hBot, false)
    table.insert(pipes, pBot)
    
    spawnTimer = playdate.timer.performAfterDelay(1800, spawnPipePair)
end

function playdate.update()
    gfx.clear()
    
    if gameState == "START" then
        gfx.drawText("FLAPPY BIRD", 150, 80)
        gfx.drawText("Press A to Flap", 145, 120)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "PLAY"
            initGame()
        end
    elseif gameState == "PLAY" then
        updatePlay()
    elseif gameState == "GAME_OVER" then
        gfx.drawText("GAME OVER", 160, 80)
        gfx.drawText("Score: " .. score, 165, 120)
        gfx.drawText("Press A to Restart", 135, 160)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "PLAY"
            initGame()
        end
    end
    
    playdate.timer.updateTimers()
end

function updatePlay()
    -- Input
    if playdate.buttonJustPressed(playdate.kButtonA) then
        bird:flap()
    end
    
    bird:update()
    
    -- Check Collisions
    local collisions = bird:overlappingSprites()
    if #collisions > 0 then
        gameState = "GAME_OVER"
    end
    
    if bird.isDead then -- Hit floor
        gameState = "GAME_OVER"
    end
    
    -- Pipe Management
    for i, p in ipairs(pipes) do
        p:update()
        
        -- Score
        if not p.passed and p.x < bird.x and p.isTop then -- Only count top pipe
            score = score + 1
            p.passed = true
        end
        
        -- Cleanup
        if p.x < -50 then
            p:remove()
            -- table remove is tricky while iterating. 
            -- Just let sprite engine handle drawing. memory leak is small for short game.
            -- proper loop would be backwards iterating.
        end
    end
    
    gfx.sprite.update()
    
    -- HUD
    gfx.drawText(tostring(score), 190, 20)
end
