local gfx = playdate.graphics

ghosts = {}

function setupGhosts()
    ghosts = {}
    for _, spawn in ipairs(ghostSpawns) do
        local img = gfx.image.new(TILE_SIZE, TILE_SIZE)
        gfx.pushContext(img)
            gfx.fillRect(2, 2, TILE_SIZE-4, TILE_SIZE-4) -- Square ghost
            -- Eyes
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(4, 4, 4, 4)
            gfx.fillRect(12, 4, 4, 4)
        gfx.popContext()
        
        local ghost = gfx.sprite.new(img)
        ghost:moveTo(spawn.x + TILE_SIZE/2, spawn.y + TILE_SIZE/2)
        ghost:setCollideRect(0, 0, TILE_SIZE-2, TILE_SIZE-2)
        ghost:setTag(20) -- Tag 20: Ghost
        ghost:setGroups({20})
        ghost:setCollidesWithGroups({1}) -- Walls only (Pacman checks collision with ghost)
        ghost:add()
        
        -- Add custom properties
        ghost.dir = {x=1, y=0}
        ghost.speed = 1.5 -- Slower than Pacman
        
        function ghost:update()
            local x, y = self:getPosition()
            local ax, ay, cols, len = self:moveWithCollisions(x + self.dir.x * self.speed, y + self.dir.y * self.speed)
            
            -- If hit wall or randomly at intersection, change direction
            if len > 0 or math.random() < 0.02 then
                -- Pick random new valid direction
                local dirs = {{x=1,y=0}, {x=-1,y=0}, {x=0,y=1}, {x=0,y=-1}}
                self.dir = dirs[math.random(#dirs)]
            end
             
             -- Screen wrap
            if ax < -10 then self:moveTo(410, ay) end
            if ax > 410 then self:moveTo(-10, ay) end
        end
        
        table.insert(ghosts, ghost)
    end
end
