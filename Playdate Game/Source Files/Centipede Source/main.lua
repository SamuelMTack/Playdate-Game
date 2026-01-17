import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "player"
import "centipede"
import "mushroom"
import "bullet"

local gfx = playdate.graphics

-- Global Game State
SCORE = 0
BULLETS = {}
MUSHROOMS = {}
MUSHROOMS = {}
CENTIPEDES = {}
GAME_OVER = false
DIFFICULTY_LEVEL = 0
local player

function playdate.update()
    if GAME_OVER then
        gfx.clear()
        gfx.drawText("GAME OVER", 130, 100)
        gfx.drawText("Score: " .. SCORE, 140, 120)
        gfx.drawText("Press A to Restart", 110, 140)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            -- Restart
            SCORE = 0
            DIFFICULTY_LEVEL = 0
            GAME_OVER = false
            -- Clear entities
            if player then player:remove() player = nil end
            for _, b in ipairs(BULLETS) do b:remove() end
            BULLETS = {}
            for _, m in ipairs(MUSHROOMS) do m:remove() end
            MUSHROOMS = {}
            for _, c in ipairs(CENTIPEDES) do c:remove() end
            CENTIPEDES = {}
        end
        return
    end

    if not player then
        player = Player(200, 220)
        
        -- Generate Mushrooms
        math.randomseed(playdate.getSecondsSinceEpoch())
        local cols = 25
        local rows = 12 -- Top area
        for i=1, 30 do -- Spawn 30 mushrooms
            local mx = math.random(1, cols) * 16 - 8
            local my = math.random(1, rows) * 16 + 8 
            -- Keep away from player area (>192) and spawn area
            if my < 192 then
                local m = Mushroom(mx, my)
                table.insert(MUSHROOMS, m)
            end
        end
        
        -- Spawn Centipede Chain (Level 0 speed)
        local speed = 2
        for i=0, 9 do
             local isHead = (i == 0)
             local c = Centipede(200 + (i*16), 0, isHead, speed)
             table.insert(CENTIPEDES, c)
        end
    end
    
    -- Respawn Centipede if all dead
    if #CENTIPEDES == 0 then
        DIFFICULTY_LEVEL = DIFFICULTY_LEVEL + 1
        local speed = 2 + (DIFFICULTY_LEVEL * 0.5)
        
        for i=0, 9 do
             local isHead = (i == 0)
             local c = Centipede(200 + (i*16), -16, isHead, speed) 
             table.insert(CENTIPEDES, c)
        end
    end
    
    player:update()
    
    -- Update Centipedes
    for i=#CENTIPEDES, 1, -1 do
        local c = CENTIPEDES[i]
        c:update()
    end
    
    -- Update Bullets
    for i=#BULLETS, 1, -1 do
        local b = BULLETS[i]
        b:update()
        if not b:isVisible() then -- removed by collision or offscreen
             table.remove(BULLETS, i)
        end
    end
    
    -- Update Mushrooms (mostly for visuals if needed, but they are static)
    for i=#MUSHROOMS, 1, -1 do
        local m = MUSHROOMS[i]
        if m.hp <= 0 then
             table.remove(MUSHROOMS, i)
        end
    end
    
    gfx.sprite.update()
    playdate.timer.updateTimers()
    
    gfx.drawText("Score: " .. SCORE, 5, 5)
end
