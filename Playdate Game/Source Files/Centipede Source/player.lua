local pd <const> = playdate
local gfx <const> = pd.graphics

class('Player').extends(gfx.sprite)

function Player:init(x, y)
    -- Simple triangle ship
    local img = gfx.image.new(16, 16, gfx.kColorClear)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillTriangle(8, 0, 16, 16, 0, 16)
    gfx.popContext()
    
    self:setImage(img)
    self:moveTo(x, y)
    self:setCollideRect(0, 0, 16, 16)
    self:add()
    
    self.speed = 4
end

function Player:update()
    local dx, dy = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonUp) then dy = -self.speed end
    if playdate.buttonIsPressed(playdate.kButtonDown) then dy = self.speed end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then dx = -self.speed end
    if playdate.buttonIsPressed(playdate.kButtonRight) then dx = self.speed end
    
    if dx ~= 0 or dy ~= 0 then
        local x, y = self.x + dx, self.y + dy
        -- Constrain to screen X
        if x < 8 then x = 8 end
        if x > 392 then x = 392 end
        -- Constrain to bottom Y (approx bottom 20% -> > 192)
        if y < 192 then y = 192 end
        if y > 232 then y = 232 end
        
        self:moveTo(x, y)
    end
    
    if playdate.buttonJustPressed(playdate.kButtonA) then
        local b = Bullet(self.x, self.y - 8)
        table.insert(BULLETS, b)
    end
    
    -- Collision with Centipedes
    if CENTIPEDES then
        local x,y,w,h = self:getBounds()
        for _, c in ipairs(CENTIPEDES) do
            local cx,cy,cw,ch = c:getBounds()
            if x < cx + cw and x + w > cx and y < cy + ch and y + h > cy then
                GAME_OVER = true
            end
        end
    end
end
