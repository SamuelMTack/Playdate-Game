
local pd <const> = playdate
local gfx <const> = pd.graphics

class('Shield').extends(gfx.sprite)

function Shield:init(x, y, radius)
    Shield.super.init(self)
    self.radius = radius
    self.screenX = x
    self.screenY = y
    
    local thickness = 6
    local arcLength = 90 -- degrees
    
    -- Draw the shield
    local img = gfx.image.new(radius * 2 + thickness, radius * 2 + thickness)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(thickness)
        gfx.drawArc(radius + thickness/2, radius + thickness/2, radius, -arcLength/2, arcLength/2)
    gfx.popContext()
    
    self:setImage(img)
    self:setCollideRect(0, 0, self:getSize())
    self:setGroups(3) -- Group 3 for Shield
    self:moveTo(x, y)
    
    -- Precise collision shape could be an arc, but for now we rotate the sprite
    -- Actually, for collisions, we might need a custom check if we want it pixel perfect, 
    -- but let's stick to sprite rotation first.
end

function Shield:update()
    local change, acceleratedChange = pd.getCrankChange()
    self:setRotation(self:getRotation() + change)
end
