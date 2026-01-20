import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "cube"
import "grid"
import "player"
import "enemy"

local gfx = playdate.graphics

-- Global Game State
SCORE = 0
GRID = nil
PLAYER = nil
ENEMIES = {}
GAME_OVER = false
LEVEL = 1

function playdate.update()
    if GAME_OVER then
        gfx.clear()
        gfx.drawText("GAME OVER", 130, 100)
        gfx.drawText("Score: " .. SCORE, 140, 120)
        gfx.drawText("Press A to Restart", 110, 140)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            -- Restart
            SCORE = 0
            LEVEL = 1
            GAME_OVER = false
            if PLAYER then PLAYER:remove() PLAYER = nil end
            if GRID then 
                for r=1, 7 do
                    for c=1, r do
                         GRID.cubes[r][c]:remove()
                    end
                end
                GRID = nil 
            end
            for _, e in ipairs(ENEMIES) do e:remove() end
            ENEMIES = {}
        end
        return
    end

    if not GRID then
        GRID = Grid()
    end
    if not PLAYER then
        -- Start at top of pyramid (Row 1, Col 1), approx x=200, y=50
        PLAYER = Player(200, 50)
    end
    
    -- Enemy Spawning
    if #ENEMIES == 0 and not GAME_OVER then
         -- Random spawn chance? Or fixed interval?
         -- For now, ensure 1 enemy exists after a brief check
         -- Or spawn randomly. Let's spawn one if none exist, with a small delay logic roughly
         if math.random(1, 100) < 2 then -- 2% chance per frame approx 1 sec at 50fps?
             local e = Enemy(1, 1) -- Spawn at top
             table.insert(ENEMIES, e)
         end
    end
    
    -- Update Enemies
    for i=#ENEMIES, 1, -1 do
        local e = ENEMIES[i]
        if e.dead then
            table.remove(ENEMIES, i)
        else
            e:update()
            -- logic update
            
            -- Collision Check
            if PLAYER then
                -- Distance check or Row/Col check
                if e.currRow == PLAYER.currRow and e.currCol == PLAYER.currCol then
                    -- Touching same cube? Or close enough physically?
                    -- Since they hop, check physical distance or logical
                    -- Logical is safer for "landed on same tile"
                    -- But let's check distance for mid-air hits too
                    local dx = e.x - PLAYER.x
                    local dy = e.y - PLAYER.y
                    if (dx*dx + dy*dy) < 256 then -- 16px radius
                        GAME_OVER = true
                    end
                end
            end
        end
    end
    
    PLAYER:update()
    
    gfx.sprite.update()
    playdate.timer.updateTimers()
    
    -- Win Check (Level Complete)
    if GRID and GRID:checkWin() then
        -- Reset Level
        LEVEL = LEVEL + 1
        -- Reset Cubes
        for r=1, 7 do
            for c=1, r do
                GRID.cubes[r][c].state = 0
                GRID.cubes[r][c]:updateVisuals() -- Need to add this method to Cube or re-init image
            end
        end
        -- Reset Player pos
        PLAYER.currRow = 1
        PLAYER.currCol = 1
        local startCube = GRID.cubes[1][1]
        PLAYER:moveTo(startCube.x, startCube.y - 12)
        PLAYER.state = 0
        
        -- Clear Enemies
        for _, e in ipairs(ENEMIES) do e:remove() end
        ENEMIES = {}
        
        -- Maybe show a flash or message briefly?
    end
    
    gfx.drawText("Score: " .. SCORE, 5, 5)
    gfx.drawText("Lvl: " .. LEVEL, 350, 5)
end
