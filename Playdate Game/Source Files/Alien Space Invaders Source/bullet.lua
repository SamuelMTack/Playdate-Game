local gfx = playdate.graphics

function spawnBullet(x, y, speedY, type)
    local bulletImage = gfx.image.new(4, 10)
    gfx.pushContext(bulletImage)
        gfx.fillRect(0, 0, 4, 10)
    gfx.popContext()

    local bullet = gfx.sprite.new(bulletImage)
    bullet:moveTo(x, y)
    bullet:setCollideRect(0, 0, bullet:getSize())
    
    if type == "player" then
        bullet:setTag(4) -- Tag 4: Player Bullet
        bullet:setGroups({4}) 
        bullet:setCollidesWithGroups({2, 3}) -- Invaders, Barricades
    else
        bullet:setTag(5) -- Tag 5: Enemy Bullet
        bullet:setGroups({5}) 
        bullet:setCollidesWithGroups({1, 3}) -- Player, Barricades
    end
    
    bullet:add()

    function bullet:update()
        local actualX, actualY, collisions, length = self:moveWithCollisions(self.x, self.y + speedY)
        
        if self.y < -10 or self.y > 250 then
            self:remove()
        else
            -- Check collisions
            if #collisions > 0 then
                for _, collision in ipairs(collisions) do
                     local other = collision.other
                     local tag = other:getTag()
                     
                     if type == "player" then
                        -- Player bullet hitting Invader (Tag 2)
                        if tag == 2 then 
                             other:remove() 
                             other.isDestroyed = true
                             if addToScore then addToScore(100) end
                             self:remove() 
                             break
                        -- Player bullet hitting Barricade (Tag 3)
                        elseif tag == 3 then
                             other:remove()
                             self:remove()
                             break
                        end
                     elseif type == "enemy" then
                        -- Enemy bullet hitting Player (Tag 1)
                        if tag == 1 then
                             setGameOver()
                             self:remove()
                             break
                        -- Enemy bullet hitting Barricade (Tag 3)
                        elseif tag == 3 then
                             other:remove()
                             self:remove()
                             break
                        end
                     end
                end
            end
        end
    end
end
