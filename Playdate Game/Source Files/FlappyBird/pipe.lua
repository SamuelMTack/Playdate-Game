local gfx = playdate.graphics

class('Pipe').extends(gfx.sprite)

function Pipe:init(x, y, height, isTop)
    -- isTop: true if this pipe hangs from top, false if grows from bottom
    self.isTop = isTop
    local width = 40
    
    -- Create image
    local img = gfx.image.new(width, height)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, width, height)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(2, 2, width-4, height-4) -- Border
        -- Cap
        if isTop then
            gfx.fillRect(0, height-20, width, 20)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(2, height-18, width-4, 16)
        else
            gfx.fillRect(0, 0, width, 20)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(2, 2, width-4, 16)
        end
    gfx.popContext()
    
    self:setImage(img)
    
    -- Bounding box
    self:setCollideRect(0, 0, width, height)
    self:setGroups(2)
    
    -- Position logic
    -- sprite center logic is default. 
    -- If top pipe, y should be such that bottom edge is at 'y' param?
    -- No, let's pass center coordinates or direct rect coords from main.
    -- Let's stick to center for simplicity if we calculate it in main.
    -- BUT main will likely picking "Gap Start" and "Gap End".
    
    self:moveTo(x, y)
    self:add()
    
    self.speed = 2
    self.passed = false
end

function Pipe:update()
    self:moveBy(-self.speed, 0)
    
    if self.x < -30 then
        self:remove()
    end
end
