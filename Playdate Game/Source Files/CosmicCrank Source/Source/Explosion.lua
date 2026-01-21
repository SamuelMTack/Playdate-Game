
local pd <const> = playdate
local gfx <const> = pd.graphics

class('Explosion').extends(gfx.sprite)

function Explosion:init(x, y)
    Explosion.super.init(self)
    self.particles = {}
    self.life = 20
    
    for i=1, 8 do
        table.insert(self.particles, {
            x = 0, y = 0,
            vx = (math.random() - 0.5) * 4,
            vy = (math.random() - 0.5) * 4
        })
    end
    
    self:moveTo(x, y)
    self:setSize(32, 32)
    self:setCenter(0.5, 0.5)
end

function Explosion:update()
    self.life = self.life - 1
    if self.life <= 0 then
        self:remove()
        return
    end
    
    -- Draw particles manually on sprite image?
    -- Better: draw directly in draw() if extending sprite, 
    -- BUT sprites usually use baked images.
    -- Let's update an image or just use multiple small sprites? 
    -- For performance, 1 sprite drawing multiple points is better.
    
    local img = gfx.image.new(32, 32)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        for _, p in ipairs(self.particles) do
             p.x = p.x + p.vx
             p.y = p.y + p.vy
             gfx.fillCircleAtPoint(16 + p.x, 16 + p.y, 2)
        end
    gfx.popContext()
    self:setImage(img)
end
