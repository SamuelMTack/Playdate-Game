local gfx = playdate.graphics

class('Crosshair').extends(gfx.sprite)

function Crosshair:init()
    local size = 20
    local img = gfx.image.new(size, size)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawCircleAtPoint(size/2, size/2, size/2-2)
        gfx.drawLine(size/2, 0, size/2, size)
        gfx.drawLine(0, size/2, size, size/2)
    gfx.popContext()
    
    self:setImage(img)
    self:setZIndex(100) -- Always on top
    self:moveTo(200, 120)
    self:add()
    
    self.speed = 5
end

function Crosshair:update()
    local dx, dy = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonUp) then dy = -self.speed end
    if playdate.buttonIsPressed(playdate.kButtonDown) then dy = self.speed end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then dx = -self.speed end
    if playdate.buttonIsPressed(playdate.kButtonRight) then dx = self.speed end
    
    if dx ~= 0 or dy ~= 0 then
        -- Bounds check
        local x, y = self:getPosition()
        local newX = x + dx
        local newY = y + dy
        
        if newX < 0 then newX = 0 end
        if newX > 400 then newX = 400 end
        if newY < 0 then newY = 0 end
        if newY > 240 then newY = 240 end
        
        self:moveTo(newX, newY)
    end
end
