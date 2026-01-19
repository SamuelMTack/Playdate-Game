local gfx = playdate.graphics

class('Doodle').extends(gfx.sprite)

function Doodle:init(x, y)
    self:moveTo(x, y)
    
    local size = 20
    local img = gfx.image.new(size, size)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(size/2, size/2, size/2 - 1) 
        -- Eyes
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(size/2 - 4, size/2 - 2, 2)
        gfx.fillCircleAtPoint(size/2 + 4, size/2 - 2, 2)
        -- Snoot
        gfx.drawLine(size/2 + 2, size/2 + 2, size/2 +6, size/2 +2)
    gfx.popContext()
    
    self:setImage(img)
    self:setCollideRect(2, 2, size-4, size-4)
    self:add()
    
    self.dy = 0
    self.gravity = 0.5
    self.jumpForce = -9
    self.moveSpeed = 6
    self.isDead = false
    self.canDoubleJump = true
end

function Doodle:update()
    -- Input
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        self:moveBy(-self.moveSpeed, 0)
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        self:moveBy(self.moveSpeed, 0)
    end
    
    -- Double Jump
    if playdate.buttonJustPressed(playdate.kButtonA) and self.canDoubleJump then
        self.dy = self.jumpForce
        self.canDoubleJump = false
    end
    
    -- Screen Wrap
    local x, y = self:getPosition()
    if x < -10 then self:moveTo(410, y) end
    if x > 410 then self:moveTo(-10, y) end
    
    -- Physics
    self.dy = self.dy + self.gravity
    self:moveBy(0, self.dy)
    
    -- Check death (fallen below screen buffer)
    if y > 600 then 
        self.isDead = true
    end
end

function Doodle:bounce()
    self.dy = self.jumpForce
    self.canDoubleJump = true -- Reset on landing
end
