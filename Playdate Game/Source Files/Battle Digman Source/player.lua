local pd <const> = playdate
local gfx <const> = pd.graphics

class('Player').extends(gfx.sprite)

function Player:init(x, y)
    self:moveTo(x, y)
    
    -- "Cool" Spaceman Sprite
    local img = gfx.image.new(16, 16, gfx.kColorClear)
    gfx.pushContext(img)
        -- Body/Suit (White)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(4, 8, 8, 8) 
        -- Helmet (White Circle)
        gfx.fillCircleAtPoint(8, 6, 5)
        -- Visor (Black Box)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(6, 5, 5, 2)
        -- Backpack (Gray/dithered logic simulation -> simple rect)
        gfx.drawRect(2, 6, 2, 6)
        -- Legs (Black lines for now to separate)
        gfx.drawLine(8, 12, 8, 16)
    gfx.popContext()
    
    self:setImage(img)
    -- Collision rect slightly smaller than visual
    self:setCollideRect(2, 2, 12, 12)
    self:add()
    self.speed = 2
    self.dir = 2 -- Default right
    self.pump = Pump()
    self.health = 3
    self.invincible = false
end

function Player:takeDamage()
    if self.invincible then return end
    self.health = self.health - 1
    if self.health <= 0 then
        GAME_OVER = true
    else
        self.invincible = true
        pd.timer.performAfterDelay(2000, function() self.invincible = false end)
    end
end

function Player:update()
    local dx, dy = 0, 0
    if pd.buttonIsPressed(pd.kButtonUp) then
        dy = -self.speed
        self.dir = 1
    elseif pd.buttonIsPressed(pd.kButtonDown) then
        dy = self.speed
        self.dir = 3
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        dx = -self.speed
        self.dir = 4
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        dx = self.speed
        self.dir = 2
    end
    
    if pd.buttonJustPressed(pd.kButtonA) then
        self.pump:fire(self.x, self.y, self.dir)
    end
    
    if dx ~= 0 or dy ~= 0 then
        local actualX, actualY, collisions, length = self:moveWithCollisions(self.x + dx, self.y + dy)
        
        -- Digging logic
        if GRID then
            -- Check center point for digging
            GRID:dig(self.x, self.y)
        end
    end
    
    -- Check collision with Enemies
    if ENEMIES then
        local x,y,w,h = self:getBounds()
        for _, e in ipairs(ENEMIES) do
            local ex,ey,ew,eh = e:getBounds()
             if x < ex + ew and x + w > ex and y < ey + eh and y + h > ey then
                 if not e.dead then
                     self:takeDamage()
                 end
             end
        end
    end
end
