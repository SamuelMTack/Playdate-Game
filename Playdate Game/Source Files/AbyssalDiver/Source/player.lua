local gfx = playdate.graphics

Player = {}

function Player.reset()
    Player.x = 200
    Player.y = 120
    Player.radius = 8
    Player.oxygen = 100
    Player.isDead = false
    
    -- Powerups
    Player.invincibleTimer = 0
    Player.speedTimer = 0
end

function Player.update()
    -- Timers
    if Player.invincibleTimer > 0 then Player.invincibleTimer -= 1 end
    if Player.speedTimer > 0 then Player.speedTimer -= 1 end

    local speedMult = (Player.speedTimer > 0) and 2.0 or 1.0

    -- Movement X
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        Player.x -= 3 * speedMult
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        Player.x += 3 * speedMult
    end
    
    -- Movement Y (Crank)
    local change = playdate.getCrankChange()
    Player.y += change * speedMult 
    
    -- Constrain to screen
    if Player.x < Player.radius then Player.x = Player.radius end
    if Player.x > 400 - Player.radius then Player.x = 400 - Player.radius end
    if Player.y < 30 then Player.y = 30 end -- Below top UI
    if Player.y > 240 - Player.radius then Player.y = 240 - Player.radius end
    
    -- Oxygen Drain (Reduced if Turbo?)
    Player.oxygen -= 0.05
    if Player.oxygen <= 0 then
        Player.oxygen = 0
        Player.isDead = true
    end
    
    -- Bubble Particles
    if math.random() < 0.05 or (Player.speedTimer > 0 and math.random() < 0.2) then
        Particles.spawn(Player.x, Player.y - 5, "bubble")
    end
end

function Player.activatePowerup(type)
    if type == "shield" then
        Player.invincibleTimer = 300 -- 10 seconds at 30fps
    elseif type == "turbo" then
        Player.speedTimer = 300
    end
end

function Player.draw()
    local x, y = Player.x, Player.y
    local animOffset = math.sin(playdate.getCurrentTimeMilliseconds() / 200) * 2
    
    -- Draw Cable
    gfx.setLineWidth(2)
    gfx.drawLine(x, -50, x, y - 8)
    gfx.setLineWidth(1)
    
    -- Turbo Trail
    if Player.speedTimer > 0 then
         gfx.setColor(gfx.kColorBlack)
         for i=1,3 do
             gfx.drawLine(x - 5*i, y + animOffset + i*2, x - 5*i, y + animOffset + i*2 + 5)
         end
    end

    -- Shield Visual
    if Player.invincibleTimer > 0 then
        if (Player.invincibleTimer > 60) or (Player.invincibleTimer % 4 < 2) then -- Flicker at end
            gfx.setLineWidth(1)
            gfx.drawEllipseInRect(x - 14, y + animOffset - 14, 28, 28)
        end
    end
    
    -- Draw Diver Body (Circle)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillEllipseInRect(x - 8, y + animOffset - 8, 16, 16)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawEllipseInRect(x - 8, y + animOffset - 8, 16, 16)
    
    -- Draw Goggles
    gfx.fillRect(x - 6, y + animOffset - 2, 12, 4)
    
    -- Draw Tank
    gfx.fillRect(x - 4, y + animOffset - 10, 8, 6)
    
    -- Draw Flippers
    local flipY = y + animOffset + 6
    gfx.drawLine(x - 3, flipY, x - 6, flipY + 6)
    gfx.drawLine(x + 3, flipY, x + 6, flipY + 6)
end

function Player.getBounds()
    return {
        x = Player.x - Player.radius,
        y = Player.y - Player.radius,
        w = Player.radius * 2,
        h = Player.radius * 2
    }
end
