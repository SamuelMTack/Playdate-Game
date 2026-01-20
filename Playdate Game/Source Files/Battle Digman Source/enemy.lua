local pd <const> = playdate
local gfx <const> = pd.graphics

class('Enemy').extends(gfx.sprite)

function Enemy:init(x, y, type)
    self:moveTo(x, y)
    -- Distinct visual: Red-ish circle with eyes
    local img = gfx.image.new(16, 16, gfx.kColorClear)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(8, 8, 7)
        gfx.setColor(gfx.kColorWhite)
        -- Eyes
        gfx.fillCircleAtPoint(5, 6, 2)
        gfx.fillCircleAtPoint(11, 6, 2)
        gfx.setColor(gfx.kColorBlack)
        -- Pupils
        gfx.fillCircleAtPoint(5, 6, 1)
        gfx.fillCircleAtPoint(11, 6, 1)
    gfx.popContext()
    
    self:setImage(img)
    self:setCollideRect(0, 0, 14, 14)
    self:add()
    self.type = type
end

function Enemy:update()
    local speed = 1
    local dx, dy = 0, 0
    
    -- Change direction occasionally or if blocked
    if not self.dir or math.random(1, 50) == 1 then
        self:pickRandomDir()
    end
    
    if self.dir == 1 then dy = -speed
    elseif self.dir == 2 then dx = speed
    elseif self.dir == 3 then dy = speed
    elseif self.dir == 4 then dx = -speed
    end
    
    local newX = self.x + dx
    local newY = self.y + dy
    
    -- Boundary and Solid check
    if newX > 0 and newX < 400 and newY > 0 and newY < 240 then
        -- Check center point
        local cx = newX + 8
        local cy = newY + 8
        if GRID and not GRID:isSolid(cx, cy) then
             self:moveTo(newX, newY)
        else
             self:pickRandomDir()
        end
    else
        self:pickRandomDir()
    end
end

function Enemy:pickRandomDir()
     self.dir = math.random(1, 4)
end

function Enemy:die()
    self.dead = true
end
