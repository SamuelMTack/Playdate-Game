local gfx = playdate.graphics

Particles = {}
local activeParticles = {}

class('Particle').extends(gfx.sprite)

function Particle:init(x, y, type)
    Particle.super.init(self)
    self:moveTo(x, y)
    self.type = type
    
    self.vx = math.random(-2, 2)
    self.vy = math.random(-2, 2)
    self.life = 30
    
    local s = 2
    local img = gfx.image.new(s, s)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, s, s)
    gfx.popContext()
    self:setImage(img)
    self:add()
end

function Particle:update()
    self:moveBy(self.vx, self.vy)
    self.life = self.life - 1
    
    if self.life < 10 then
        -- Blink out
        if self.life % 2 == 0 then self:setVisible(false) else self:setVisible(true) end
    end
    
    if self.life <= 0 then
        self:remove()
    end
end

function Particles.spawn(x, y, type, count)
    for i=1, count do
        Particle(x, y, type)
    end
end

function Particles.update()
    -- Sprites update themselves
end

function Particles.reset()
    gfx.sprite.performOnAllSprites(function(s)
        if s.className == "Particle" then s:remove() end
    end)
end
