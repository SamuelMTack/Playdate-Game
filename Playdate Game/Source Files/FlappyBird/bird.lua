local gfx = playdate.graphics

class('Bird').extends(gfx.sprite)

function Bird:init(x, y)
    self:moveTo(x, y)
    
    local size = 18
    local img = gfx.image.new(size, size-4)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillEllipseInRect(0, 0, size, size-4)
        gfx.setColor(gfx.kColorWhite)
        -- Eye
        gfx.fillCircleAtPoint(14, 4, 3)
        -- Wing
        gfx.fillEllipseInRect(4, 6, 8, 4)
    gfx.popContext()
    
    self:setImage(img)
    self:setCollideRect(2, 2, size-4, size-8)
    self:setGroups(1)
    self:setCollidesWithGroups(2) -- Pipes group
    
    self:add()
    
    self.dy = 0
    self.gravity = 0.3
    self.flapStrength = -5
    self.isDead = false
end

function Bird:update()
    if self.isDead then return end
    
    -- Gravity
    self.dy = self.dy + self.gravity
    self:moveBy(0, self.dy)
    
    -- Rotation based on velocity
    -- PlayDate sprites don't rotate easily without re-drawing or setRotation (expensive?)
    -- setRotation is available. Let's try it.
    local rotation = self.dy * 3
    if rotation > 90 then rotation = 90 end
    if rotation < -45 then rotation = -45 end
    self:setRotation(rotation)
    
    -- Floor Collision
    if self.y > 230 then
        self.isDead = true
    end
end

function Bird:flap()
    if not self.isDead then
        self.dy = self.flapStrength
    end
end
