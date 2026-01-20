local pd <const> = playdate
local gfx <const> = pd.graphics

class('Mushroom').extends(gfx.sprite)

function Mushroom:init(x, y)
    self.hp = 4
    self:updateImage()
    self:moveTo(x, y)
    self:setCollideRect(0, 0, 16, 16)
    self:add()
end

function Mushroom:updateImage()
    local img = gfx.image.new(16, 16, gfx.kColorClear)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        -- Draw mushroom cap based on HP (full circle -> broken)
        local radius = 6
        if self.hp < 4 then radius = 4 end
        gfx.fillCircleAtPoint(8, 6, radius)
        gfx.fillRect(6, 6, 4, 8) -- Stem
    gfx.popContext()
    self:setImage(img)
end

function Mushroom:hit()
    self.hp = self.hp - 1
    if self.hp <= 0 then
        self:remove()
    else
        self:updateImage()
    end
end
