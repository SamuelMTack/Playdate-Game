local gfx = playdate.graphics

class('Player').extends(gfx.sprite)

function Player:init(x, y)
    Player.super.init(self)
    self:moveTo(x, y)
    
    -- Physics
    self.dx = 0
    self.dy = 0
    self.gravity = 0.5
    self.jumpForce = -9
    self.speed = 3
    self.grounded = false
    
    -- Visuals
    local w, h = 16, 16 
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, w, h)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(2, 2, w-4, h-4)
        -- Eyes
        gfx.drawPixel(4, 4)
        gfx.drawPixel(10, 4)
    gfx.popContext()
    self:setImage(image)
    self:setCollideRect(0, 0, w, h)
    self:add()
end

function Player:update()
    -- Input
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        self.dx = -self.speed
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        self.dx = self.speed
    else
        self.dx = 0
    end
    
    if playdate.buttonJustPressed(playdate.kButtonA) and self.grounded then
        self.dy = self.jumpForce
        self.grounded = false
        Particles.spawn(self.x, self.y + 8, 1, 5)
        AudioManager.playSFX(AudioManager.SFX.JUMP)
    end
    
    -- Gravity
    self.dy = self.dy + self.gravity
    if self.dy > 10 then self.dy = 10 end
    
    -- Movement & Collision
    local actualX, actualY, collisions, length = self:moveWithCollisions(self.x + self.dx, self.y + self.dy)
    
    -- Check Grounded State
    self.grounded = false
    for i=1, length do
        local col = collisions[i]
        if col.normal.y == -1 then
            self.grounded = true
            self.dy = 0
        elseif col.normal.y == 1 then
             self.dy = 0 -- Create ceiling bump
        end
    end
    
    -- Screen Bounds (Death logic is in main.lua)
    if self.x < 0 then self:moveTo(0, self.y) end
    if self.x > 400 then self:moveTo(400, self.y) end
end

function Player:collisionResponse(other)
    return gfx.sprite.kCollisionTypeSlide
end
