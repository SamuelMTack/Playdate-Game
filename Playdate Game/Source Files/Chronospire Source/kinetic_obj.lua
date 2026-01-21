local gfx = playdate.graphics

class('KineticObject').extends(gfx.sprite)

function KineticObject:init(x, y)
    KineticObject.super.init(self)
    self:moveTo(x, y)
    self.baseRotation = 0
end

-- Rotator Class: Platforms that rotate with the crank
class('Rotator').extends(KineticObject)

function Rotator:init(x, y, width, height)
    Rotator.super.init(self, x, y)
    self.width = width
    self.height = height
    self.rect = playdate.geometry.rect.new(0, 0, width, height)
    
    local image = gfx.image.new(width, height)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(0, 0, width, height, 4)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(0, 0, width, height, 4)
        -- Draw "gear" teeth approximations or bolts
        gfx.fillCircleAtPoint(width/2, height/2, 4)
        gfx.drawLine(0, height/2, width, height/2)
    gfx.popContext()
    
    self:setImage(image)
    self:setCollideRect(0, 0, width, height)
end

function Rotator:update()
    -- Sync rotation directly to crank position
    local crankAngle = playdate.getCrankPosition()
    self:setRotation(crankAngle)
end

-- Pistons: Move linearly based on Crank Change
class('Piston').extends(KineticObject)

function Piston:init(x, y, travelDist, axis)
    Piston.super.init(self, x, y)
    self.originX = x
    self.originY = y
    self.travel = travelDist
    self.axis = axis -- "x" or "y"
    
    local w, h = 32, 16 
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, w, h)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(0, 0, w, h)
        gfx.drawLine(4, 4, 28, 12)
        gfx.drawLine(4, 12, 28, 4)
    gfx.popContext()
    self:setImage(image)
    self:setCollideRect(0, 0, w, h)
end

function Piston:update()
    local crankChange = playdate.getCrankChange()
    -- Map crank change to linear movement
    if self.axis == "y" then
        local newY = self.y + crankChange
        -- Clamp logic would go here
        self:moveTo(self.x, newY)
    end
end
