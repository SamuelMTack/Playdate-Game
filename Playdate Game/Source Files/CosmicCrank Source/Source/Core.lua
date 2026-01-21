
local pd <const> = playdate
local gfx <const> = pd.graphics

class('Core').extends(gfx.sprite)

function Core:init(x, y)
    Core.super.init(self)
    self.health = 100
    
    local size = 20
    local img = gfx.image.new(size, size)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(size/2, size/2, size/2 - 2)
    gfx.popContext()
    
    self:setImage(img)
    self:moveTo(x, y)
    self:setCollideRect(0, 0, size, size)
    self:setGroups(1) -- Group 1 for Core
end

function Core:hit(damage)
    self.health = self.health - damage
    -- Simple flash effect or shake could go here
    if self.health <= 0 then
        -- Game Over logic triggered elsewhere
    end
end
