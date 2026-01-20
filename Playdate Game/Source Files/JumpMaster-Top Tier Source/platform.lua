local gfx = playdate.graphics

class('Platform').extends(gfx.sprite)

function Platform:init(x, y, type)
    self:moveTo(x, y)
    self.type = type or "NORMAL" -- NORMAL, MOVING, BREAK
    
    local width = 50
    local height = 10
    
    local img = gfx.image.new(width, height)
    gfx.pushContext(img)
        if self.type == "NORMAL" then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(0, 0, width, height)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(2, 2, width-4, height-4) -- Green-ish look inverted
        elseif self.type == "MOVING" then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(0, 0, width, height)
            gfx.drawLine(0, height/2, width, height/2) -- Stripe
        end
    gfx.popContext()
    
    self:setImage(img)
    self:setCollideRect(0, 0, width, height)
    self.width = width
    self:add()
    
    -- Moving logic
    self.speed = 2
    self.direction = 1
end

function Platform:update()
    if self.type == "MOVING" then
        self:moveBy(self.speed * self.direction, 0)
        local x, y = self:getPosition()
        if x > 380 then self.direction = -1 end
        if x < 20 then self.direction = 1 end
    end
end
