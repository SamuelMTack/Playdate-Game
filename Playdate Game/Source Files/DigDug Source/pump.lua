local pd <const> = playdate
local gfx <const> = pd.graphics

class('Pump').extends(gfx.sprite)

function Pump:init()
    -- visual representation (simple black arrow)
    local img = gfx.image.new(16, 16, gfx.kColorClear)
    -- draw arrow
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        -- Shaft
        gfx.drawLine(0, 8, 16, 8)
        -- Head
        gfx.fillTriangle(12, 4, 12, 12, 16, 8)
    gfx.popContext()
    
    self:setImage(img)
    self:setZIndex(10)
    self:setVisible(false)
    self:add()
    self.active = false
end

function Pump:fire(x, y, dir)
    self.active = true
    self:setVisible(true)
    self:moveTo(x, y)
    
    -- Rotate based on dir (1:Up, 2:Right, 3:Down, 4:Left)
    local angle = 0
    if dir == 1 then angle = -90
    elseif dir == 2 then angle = 0
    elseif dir == 3 then angle = 90
    elseif dir == 4 then angle = 180
    end
    self:setRotation(angle)
    
    -- Move forward a bit to show extension
    local dx, dy = 0, 0
    if dir == 1 then dy = -16
    elseif dir == 2 then dx = 16
    elseif dir == 3 then dy = 16
    elseif dir == 4 then dx = -16
    end
    self:moveBy(dx, dy)
    
    -- Timer to retract
    pd.timer.performAfterDelay(200, function()
        self:setVisible(false)
        self.active = false
    end)
end

function Pump:update()
    if self.active and self:isVisible() then
        if ENEMIES then
            local x, y, w, h = self:getBounds()
            
            for _, e in ipairs(ENEMIES) do
                local ex, ey, ew, eh = e:getBounds()
                -- Simple AABB check
                if x < ex + ew and x + w > ex and y < ey + eh and y + h > ey then
                     if not e.dead then
                         e:die()
                     end
                end
            end
        end
    end
end
