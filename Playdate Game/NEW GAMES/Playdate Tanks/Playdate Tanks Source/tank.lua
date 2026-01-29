local gfx = playdate.graphics

class('Tank').extends()

function Tank:init(x, y, playerNum)
    self.x = x
    self.y = y
    self.playerNum = playerNum
    self.angle = 45
    if playerNum == 2 then self.angle = 135 end
    self.power = 50
    self.health = 100
    self.fuel = 100
end

function Tank:update()
    -- Crank controls angle
    local change = playdate.getCrankChange()
    self.angle = self.angle - change
    
    -- D-pad controls power
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        self.power = self.power + 1
        if self.power > 100 then self.power = 100 end
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        self.power = self.power - 1
        if self.power < 0 then self.power = 0 end
    end

    -- D-pad Left/Right controls Movement
    if self.fuel > 0 then
        if playdate.buttonIsPressed(playdate.kButtonLeft) then
            self.x = self.x - 1
            self.fuel = self.fuel - 1
        elseif playdate.buttonIsPressed(playdate.kButtonRight) then
            self.x = self.x + 1
             self.fuel = self.fuel - 1
        end
        
        -- Clamp X
        if self.x < 10 then self.x = 10 end
        if self.x > 390 then self.x = 390 end
    end

    -- Update Y based on terrain (falling)
    local groundY = Terrain.getHeight(self.x)
    if self.y < groundY then
        self.y = self.y + 2 -- Basic gravity
        if self.y > groundY then self.y = groundY end
    elseif self.y > groundY then -- Snap up if terrain destroyed below
        self.y = groundY
    end
end

function Tank:draw()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(self.x - 10, self.y - 10, 20, 10)
    
    -- Draw Barrel
    local radian = math.rad(self.angle)
    local x2 = self.x + math.cos(radian) * 15
    local y2 = self.y - math.sin(radian) * 15 -- Y is flipped
    
    gfx.setLineWidth(2)
    gfx.drawLine(self.x, self.y - 5, x2, y2)
    
    -- Health bar
    gfx.fillRect(self.x - 10, self.y - 20, 20 * (self.health / 100), 3)
end

function Tank:takeDamage(amount)
    self.health = self.health - amount
    if self.health < 0 then self.health = 0 end
end
