local pd <const> = playdate
local gfx <const> = pd.graphics

class('Centipede').extends(gfx.sprite)

function Centipede:init(x, y, isHead, speed)
    -- Circle segment
    local img = gfx.image.new(16, 16, gfx.kColorClear)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        if isHead then
            gfx.fillCircleAtPoint(8, 8, 7)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(5, 5, 2) -- Eye
        else
            gfx.drawCircleAtPoint(8, 8, 7)
        end
    gfx.popContext()
    
    self:setImage(img)
    self:moveTo(x, y)
    self:setCollideRect(0, 0, 16, 16)
    self:add()
    
    self.validDir = {1, 0} -- Moving right
    self.speed = speed or 2
    self.dropping = false
    self.dropCount = 0
end

function Centipede:update()
    if self.dropping then
        -- Move down 16 pixels
        self:moveBy(0, self.speed)
        self.dropCount = self.dropCount + self.speed
        if self.dropCount >= 16 then
            self.dropping = false
            self.dropCount = 0
            -- Resume horizontal movement
        end
    else
        -- Move horizontally
        local dx = self.validDir[1] * self.speed
        self:moveBy(dx, 0)
        
        -- Check collisions ahead
        local nextX = self.x + (self.validDir[1] * 8) -- Look ahead
        
        -- Screen Edge
        local hitEdge = (nextX < 8 or nextX > 392)
        
        -- Mushroom Collision
        local hitMushroom = false
        if MUSHROOMS then
            local x,y,w,h = self:getBounds()
            for _, m in ipairs(MUSHROOMS) do
               local mx,my,mw,mh = m:getBounds()
               -- Check if overlap would occur in next step roughly
               if x < mx + mw and x + w > mx and y < my + mh and y + h > my then
                  hitMushroom = true
                  break
               end
            end
        end
        
        if hitEdge or hitMushroom then
            -- Snap to grid X to align? Or just turn.
            -- Start drop
            self.dropping = true
            -- Reverse direction
            self.validDir[1] = -self.validDir[1]
        end
    end
end
