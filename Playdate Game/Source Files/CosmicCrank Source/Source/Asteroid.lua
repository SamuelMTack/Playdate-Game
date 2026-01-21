
local pd <const> = playdate
local gfx <const> = pd.graphics

class('Asteroid').extends(gfx.sprite)

function Asteroid:init(targetX, targetY)
    Asteroid.super.init(self)
    
    -- Spawn at random edge
    local angle = math.random() * math.pi * 2
    local spawnDist = 220 
    local startX = targetX + math.cos(angle) * spawnDist
    local startY = targetY + math.sin(angle) * spawnDist
    
    self:moveTo(startX, startY)
    
    -- Random sprite
    local size = math.random(8, 16)
    local img = gfx.image.new(size, size)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(size/2, size/2, size/2)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(size/2, size/2, size/2 - 1)
    gfx.popContext()
    
    self:setImage(img)
    self:setCollideRect(0, 0, size, size)
    
    self.speed = 1 + math.random()
    self.targetX = targetX
    self.targetY = targetY
    
    self:setGroups(2) -- Group 2 for Enemeies
    self:setCollidesWithGroups({1, 3}) -- Collides with Core (Group 1) and Shield (Group 3)
end

function Asteroid:update()
    -- Move towards center
    if not self.targetX or not self.targetY then
        print("Error: Asteroid target is nil")
        self:remove()
        return
    end

    local x, y = self:getPosition()
    local dx = self.targetX - x
    local dy = self.targetY - y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist > 0 then
        self:moveBy((dx/dist) * self.speed, (dy/dist) * self.speed)
    end
    
    -- Remove if too close (hit core) or handled by collision in main
end
