local gfx = playdate.graphics

class('Bullet').extends()

function Bullet:init(x, y, angle, power)
    self.x = x
    self.y = y - 10
    local radian = math.rad(angle)
    local speed = power * 0.4
    self.vx = math.cos(radian) * speed
    self.vy = -math.sin(radian) * speed
    self.dead = false
end

function Bullet:update()
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.vy = self.vy + 0.35 -- Gravity
    
    -- Check collision with ground
    if self.x > 0 and self.x < 400 then
        local groundY = Terrain.getHeight(self.x)
        if self.y >= groundY then
            self:explode()
            return
        end
    end
    
    -- Check collision with tanks
    for i, tank in ipairs(Game.players) do
        local dist = math.sqrt((self.x - tank.x)^2 + (self.y - tank.y)^2)
        if dist < 15 then -- Hit radius
            self:explode()
            tank:takeDamage(25) -- Basic damage
            return
        end
    end
    
    -- Check out of bounds
    if self.x < -50 or self.x > 450 or self.y > 250 then
        self.dead = true
    end
end

function Bullet:explode()
    self.dead = true
    Terrain.explode(self.x, 20)
end

function Bullet:draw()
    gfx.fillCircleAtPoint(self.x, self.y, 2)
end
