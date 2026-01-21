
local pd <const> = playdate
local gfx <const> = pd.graphics

class('Starfield').extends(gfx.sprite)

function Starfield:init()
    Starfield.super.init(self)
    self:setZIndex(-10) -- Background
    self:moveTo(200, 120)
    
    local img = gfx.image.new(400, 240, gfx.kColorBlack)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        for i=1, 50 do
            local x = math.random(0, 400)
            local y = math.random(0, 240)
            gfx.drawPixel(x, y)
        end
    gfx.popContext()
    
    self:setImage(img)
end
