local gfx = playdate.graphics

class('Duck').extends(gfx.sprite)

function Duck:init()
    local size = 30
    local img = gfx.image.new(size, size)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        -- Simple Duck Shape
        gfx.fillEllipseInRect(5, 10, 20, 10) -- Body
        gfx.fillCircleAtPoint(22, 10, 5) -- Head
        gfx.drawLine(15, 15, 5, 25) -- Wing back
    gfx.popContext()
    
    self:setImage(img)
    self:setCollideRect(0, 0, size, size)
    self:setZIndex(50)
    
    self:reset()
    self:add()
end

function Duck:reset()
    -- Start at random bottom location
    self:moveTo(math.random(50, 350), 240)
    self.state = "FLY" -- FLY, HIT, FALL, DEAD
    
    -- Launch Velocity (Arc)
    self.dx = math.random(2, 5)
    if math.random() > 0.5 then self.dx = -self.dx end
    
    self.dy = -math.random(9, 12) -- Launch up fast
    self.gravity = 0.25
    
    self.timer = 0
end

function Duck:update()
    if self.state == "FLY" then
        local x, y = self:getPosition()
        
        -- Gravity Arc
        self.dy = self.dy + self.gravity
        self:moveBy(self.dx, self.dy)
        
        -- Bounce off SIDE walls only
        if x < 10 or x > 390 then self.dx = -self.dx end
        
        -- Despawn at bottom
        if y > 250 then 
             self.state = "DEAD"
             self:remove()
        end
        
    elseif self.state == "HIT" then
        self.timer = self.timer + 1
        -- Freeze for a moment
        if self.timer > 20 then
            self.state = "FALL"
        end
        
    elseif self.state == "FALL" then
        self:moveBy(0, 6) -- Fast fall
        local x, y = self:getPosition()
        if y > 250 then
            self.state = "DEAD"
            self:remove()
        end
    end
end

function Duck:hit()
    if self.state == "FLY" then
        self.state = "HIT"
        -- Change graphic to "X" eyes if possible, or invert
        local img = self:getImage()
        gfx.pushContext(img)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawText("X", 8, 8)
        gfx.popContext()
        self:setImage(img)
        return true
    end
    return false
end
