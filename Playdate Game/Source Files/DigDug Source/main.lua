import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "grid"
import "player"
import "enemy"
import "pump"

local gfx = playdate.graphics

-- Global game state
-- Global game state
GRID = nil
ENEMIES = {}
SCORE = 0
GAME_OVER = false
local player

function playdate.update()
    if GAME_OVER then
        -- Cleanup sprites if they exist (transition to Game Over state)
        if player then 
            player:remove() 
            player = nil
        end
        if GRID then 
            GRID:remove() 
            GRID = nil
        end
        for _, e in ipairs(ENEMIES) do e:remove() end
        ENEMIES = {}

        gfx.clear()
        gfx.drawText("GAME OVER", 130, 100)
        gfx.drawText("Score: " .. SCORE, 140, 120)
        gfx.drawText("Press A to Restart", 110, 140)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            -- Restart
            SCORE = 0
            GAME_OVER = false
            -- Sprites will be recreated by the main loop below
        end
        return
    end

    if not GRID then
        GRID = Grid()
    end
    if not player then
        player = Player(200, 120)
    end
    
    if #ENEMIES == 0 then
        -- Level Reset / Next Level
        if GRID then
           GRID:remove()
           GRID = Grid()
        end
        
        -- Reset Player Health for new level
        if player then
            player.health = 3
        end
        
        -- Spawn new enemies (increase count for difficulty)
        local count = 2 + math.floor(SCORE / 1000)
        local validSpawns = GRID:getTunnelSpawns()
        
        for i=1, count do
            -- Spawn in tunnels using new Grid method or fallback
            local spawn = validSpawns[math.random(#validSpawns)]
            if not spawn then spawn = {x=100, y=100} end
            
            local e = Enemy(spawn.x, spawn.y, 1)
            table.insert(ENEMIES, e)
        end
    end

    for i=#ENEMIES, 1, -1 do
        local e = ENEMIES[i]
        if e.dead then
            table.remove(ENEMIES, i)
            e:remove()
            SCORE = SCORE + 100
        else
            e:update()
        end
    end

    gfx.sprite.update()
    playdate.timer.updateTimers()
    
    -- HUD
    gfx.drawText("Score: " .. SCORE, 5, 5)
    if player then
        gfx.drawText("HP: " .. player.health, 340, 5)
    end
end
