local gfx = playdate.graphics

class('Dog').extends(gfx.sprite)

function Dog:init()
    local size = 40
    local img = gfx.image.new(size, size)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        -- Dog Head
        gfx.fillEllipseInRect(5, 5, 30, 25)
        gfx.setColor(gfx.kColorWhite)
        -- Ears
        gfx.fillEllipseInRect(0, 5, 10, 15)
        gfx.fillEllipseInRect(30, 5, 10, 15)
        -- Nose
        gfx.fillCircleAtPoint(20, 20, 3)
    gfx.popContext()
    
    self:setImage(img)
    self:setZIndex(80) -- Behind grass (if we had it) but in front of ducks
    self:moveTo(200, 240)
    self.targetY = 200 -- Pop up height
end

function Dog:show(type) -- LAUGH, CATCH
    self:add()
    self:moveTo(200, 240)
    
    local img = self:getImage()
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        -- Mouth/Face Reset or changes
        -- gfx.fillRect(10, 25, 20, 10) 
        -- Actually, avoiding modify logic is cleaner since we use overlay text now.
        -- Just let the dog exist.
    gfx.popContext()
    
    -- Pop up animation
    local startP = playdate.geometry.point.new(200, 240)
    local endP = playdate.geometry.point.new(200, 200)
    local animator = playdate.graphics.animator.new(500, startP, endP, playdate.easingFunctions.outBack)
    self:setAnimator(animator)
    
    -- Hide after delay
    playdate.timer.performAfterDelay(1500, function() self:remove() end)
end
