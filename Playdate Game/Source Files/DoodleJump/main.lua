import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "doodle"
import "platform"

local gfx = playdate.graphics

local gameState = "START"
local doodle = nil
local platforms = {}
local cameraY = 0
local score = 0
local highestY = 0

function initGame()
    gfx.sprite.removeAll()
    platforms = {}
    
    -- Start Platform
    local startPlat = Platform(200, 220, "NORMAL")
    table.insert(platforms, startPlat)
    
    -- Generate initial platforms
    generatePlatforms(220, 20) -- Start from Y=220 (player level) and go up
    
    -- Player
    doodle = Doodle(200, 200)
    
    cameraY = 0
    score = 0
    highestY = 220
end

function generatePlatforms(startY, count)
    local currentY = startY
    for i=1, count do
        currentY = currentY - (30 + math.random(40)) -- Gap 30-70 (Safer for jump height of ~80)
        local x = math.random(20, 380)
        local type = "NORMAL"
        if math.random(100) > 80 then type = "MOVING" end
        
        local p = Platform(x, currentY, type)
        table.insert(platforms, p)
    end
end

function playdate.update()
    gfx.clear()
    
    if gameState == "START" then
        gfx.drawText("DOODLE JUMP", 150, 80)
        gfx.drawText("Press A to Start", 140, 120)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "PLAY"
            initGame()
        end
    elseif gameState == "PLAY" then
        updatePlay()
    elseif gameState == "GAME_OVER" then
        gfx.drawText("GAME OVER", 160, 80)
        gfx.drawText("Score: " .. math.floor(score), 150, 120)
        gfx.drawText("Press A to Restart", 130, 160)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "PLAY"
            initGame()
        end
    end
    
    playdate.timer.updateTimers()
end

function updatePlay()
    doodle:update()
    
    -- Camera Scroll Logic
    -- If doodle goes above mid-screen (y < 120), move camera up (increase cameraY)
    local doodleScreenY = doodle.y + cameraY
    if doodleScreenY < 120 then
        local diff = 120 - doodleScreenY
        cameraY = cameraY + diff
        score = score + diff -- Score is height
    end
    
    -- Apply Camera Offset
    gfx.setDrawOffset(0, cameraY)
    
    for _, p in ipairs(platforms) do
        p:update()
        
        -- Improved Collision Detection
        -- Check if doodle passed through the platform's top edge
        local dx, dy = doodle:getPosition()
        local prevDy = dy - doodle.dy -- Approximation of previous Y
        
        -- Falling?
        if doodle.dy > 0 then
            local px, py = p:getPosition()
            local pTop = py - 5 -- Top of platform (height 10)
            
            -- X overlap check
            if math.abs(dx - px) < (p.width/2 + 10) then
                 -- Y crossing check
                 -- Feet (dy+10) were above pTop previously?
                 -- Feet are now below pTop?
                 -- We add a buffer of doodle.dy to catch fast movements
                 if (dy + 10) >= pTop and (dy + 10 - doodle.dy) <= (pTop + 5) then
                     doodle:moveTo(dx, pTop - 10) -- Snap to top
                     doodle:bounce()
                 end
            end
        end
        
        -- Cleanup
        local screenPy = p.y + cameraY
        if screenPy > 250 then
            p:remove()
        end
    end
    
    -- Endless generation
    local highestP = platforms[#platforms]
    local highestPy = highestP.y + cameraY
    if highestPy > -50 then 
        generatePlatforms(highestP.y, 5)
    end
    
    -- Check Death
    if doodle.y + cameraY > 250 then
        gameState = "GAME_OVER"
    end
    
    gfx.sprite.update()
    
    -- HUD
    gfx.setDrawOffset(0, 0)
    gfx.drawText("Score: " .. math.floor(score), 10, 10)
end
