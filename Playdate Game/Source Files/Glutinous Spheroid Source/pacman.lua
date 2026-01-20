local gfx = playdate.graphics

local pacman = nil
local direction = {x=0, y=0}
local nextDirection = {x=0, y=0}
local speed = 2

function setupPacman()
    local img = gfx.image.new(TILE_SIZE, TILE_SIZE)
    gfx.pushContext(img)
        gfx.fillCircleInRect(1, 1, TILE_SIZE-2, TILE_SIZE-2)
    gfx.popContext()
    
    pacman = gfx.sprite.new(img)
    pacman:moveTo(pacmanSpawn.x + TILE_SIZE/2, pacmanSpawn.y + TILE_SIZE/2)
    pacman:setCollideRect(0, 0, TILE_SIZE-2, TILE_SIZE-2) -- Smaller than tile to fit
    pacman:setTag(10) -- Tag 10: Pacman
    pacman:setGroups({10})
    pacman:setCollidesWithGroups({1, 2, 20}) -- Walls, Dots, Ghosts
    pacman:add()
    
    direction = {x=0, y=0}
    nextDirection = {x=0, y=0}
    
    function pacman:update()
        -- Input handling
        if playdate.buttonIsPressed(playdate.kButtonUp) then nextDirection = {x=0, y=-1}
        elseif playdate.buttonIsPressed(playdate.kButtonDown) then nextDirection = {x=0, y=1}
        elseif playdate.buttonIsPressed(playdate.kButtonLeft) then nextDirection = {x=-1, y=0}
        elseif playdate.buttonIsPressed(playdate.kButtonRight) then nextDirection = {x=1, y=0}
        end
        
        -- Try to change direction if aligned to grid
        local x, y = self:getPosition()
        local centerX = x 
        local centerY = y
        
        -- Very basic grid snap logic: only change dir if close to center of tile
        -- (This is a simplified MVP movement)
        
        if nextDirection.x ~= 0 or nextDirection.y ~= 0 then
             direction = nextDirection
        end

        local actualX, actualY, collisions, length = self:moveWithCollisions(x + direction.x * speed, y + direction.y * speed)
        
        -- Handle collisions
        for _, collision in ipairs(collisions) do
            local tag = collision.other:getTag()
            if tag == 2 then -- Dot
                collision.other:remove()
                score = score + 10
                -- Remove from dots list efficiently? 
                -- Ideally we modify creating dots to track them better, 
                -- but for MVP just setting un-visible or relying on 'tileAt' check is better.
                -- Here we just rely on sprite system.
                -- Need to update `dots` table in level.lua to check win condition?
                -- Quick hack:
                for i=#dots, 1, -1 do
                    if dots[i] == collision.other then
                        table.remove(dots, i)
                    end
                end
            elseif tag == 20 then -- Ghost
                gameState = "GAMEOVER"
            end
        end
        
        -- Screen Wrap
        if actualX < -10 then self:moveTo(410, actualY) end
        if actualX > 410 then self:moveTo(-10, actualY) end
    end
end
