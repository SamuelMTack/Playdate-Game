import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics

-- Sound
local fireSynth = playdate.sound.synth.new(playdate.sound.kWaveSawtooth)
local boomSynth = playdate.sound.synth.new(playdate.sound.kWaveNoise)

-- Constants
local SCREEN_W = 400
local SCREEN_H = 240

-- Game State
local gameState = "START"
local score = 0
local lives = 3
local level = 1

local ship = {x=200, y=120, vx=0, vy=0, angle=270, radius=8, active=true, immuneTimer=0}
local bullets = {}
local asteroids = {}

function setupGame()
    score = 0
    lives = 3
    level = 1
    resetShip()
    startLevel()
end

function resetShip()
    ship.x, ship.y = 200, 120
    ship.vx, ship.vy = 0, 0
    ship.angle = 270
    ship.active = true
    ship.immuneTimer = 60 -- 2 seconds immunity (assuming 30fps)
end

function startLevel()
    asteroids = {}
    bullets = {}
    local count = 2 + level
    for i=1, count do
        spawnAsteroid(math.random(SCREEN_W), math.random(SCREEN_H), 3) -- Size 3 = Large
    end
end

function spawnAsteroid(x, y, size)
    local radius = size * 10 
    local speed = (4 - size) * 0.5 + (level * 0.1)
    local angle = math.random() * math.pi * 2
    
    -- Generate random polygon shape
    local points = {}
    local numPoints = math.random(8, 12)
    for i=1, numPoints do
        local a = (i / numPoints) * math.pi * 2
        local r = radius * (0.8 + math.random() * 0.4) -- variance
        table.insert(points, {x = math.cos(a) * r, y = math.sin(a) * r})
    end
    
    table.insert(asteroids, {
        x = x, y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        size = size, -- 3=Large, 2=Med, 1=Small
        radius = radius,
        points = points
    })
end

function playdate.update()
    gfx.clear()
    
    if gameState == "START" then
        gfx.drawText("BLASTEROIDS", 155, 100)
        gfx.drawText("Press A to Start", 145, 120)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            setupGame()
            gameState = "PLAY"
        end
    elseif gameState == "PLAY" then
        -- ---------- SHIP INPUT ----------
        if ship.active then
            local change = playdate.getCrankChange()
            ship.angle = ship.angle + change
            
            if playdate.buttonIsPressed(playdate.kButtonUp) then
                 -- Thrust
                 local rad = math.rad(ship.angle)
                 ship.vx = ship.vx + math.cos(rad) * 0.1
                 ship.vy = ship.vy + math.sin(rad) * 0.1
            end
            
            -- Drag/Friction (optional, keeps it controllable)
            ship.vx = ship.vx * 0.99
            ship.vy = ship.vy * 0.99
            
            -- Fire
            if playdate.buttonJustPressed(playdate.kButtonA) then
                local rad = math.rad(ship.angle)
                table.insert(bullets, {
                    x = ship.x + math.cos(rad)*10,
                    y = ship.y + math.sin(rad)*10,
                    vx = math.cos(rad) * 5 + ship.vx,
                    vy = math.sin(rad) * 5 + ship.vy,
                    life = 40
                })
                fireSynth:playNote("A4", 0.05, 0.2)
            end
            
            -- Physics
            ship.x = ship.x + ship.vx
            ship.y = ship.y + ship.vy
            
            -- Screen Wrap
            if ship.x < 0 then ship.x = SCREEN_W end
            if ship.x > SCREEN_W then ship.x = 0 end
            if ship.y < 0 then ship.y = SCREEN_H end
            if ship.y > SCREEN_H then ship.y = 0 end
            
            -- Immunity
            if ship.immuneTimer > 0 then ship.immuneTimer = ship.immuneTimer - 1 end
        end
        
        -- ---------- BULLETS ----------
        for i = #bullets, 1, -1 do
            local b = bullets[i]
            b.x = b.x + b.vx
            b.y = b.y + b.vy
            b.life = b.life - 1
            
            if b.x < 0 then b.x = SCREEN_W end
            if b.x > SCREEN_W then b.x = 0 end
            if b.y < 0 then b.y = SCREEN_H end
            if b.y > SCREEN_H then b.y = 0 end
            
            if b.life <= 0 then
                table.remove(bullets, i)
            end
        end
        
        -- ---------- ASTEROIDS ----------
        local asteroidDestroyed = false 
        
        for i = #asteroids, 1, -1 do
            local a = asteroids[i]
            a.x = a.x + a.vx
            a.y = a.y + a.vy
            
            if a.x < 0 then a.x = SCREEN_W end
            if a.x > SCREEN_W then a.x = 0 end
            if a.y < 0 then a.y = SCREEN_H end
            if a.y > SCREEN_H then a.y = 0 end
            
            -- Collision: Bullet vs Asteroid
            local hit = false
            for j = #bullets, 1, -1 do
                local b = bullets[j]
                local dist = math.sqrt((b.x - a.x)^2 + (b.y - a.y)^2)
                if dist < a.radius then
                    table.remove(bullets, j)
                    hit = true
                    score = score + (4 - a.size) * 10
                    boomSynth:playNote("C3", 0.1, 0.3)
                    break
                end
            end
            
            -- Collision: Ship vs Asteroid
            if ship.active and ship.immuneTimer <= 0 then
                local dist = math.sqrt((ship.x - a.x)^2 + (ship.y - a.y)^2)
                if dist < a.radius + ship.radius then
                    lives = lives - 1
                    boomSynth:playNote("C2", 0.5, 0.5)
                    if lives > 0 then
                        resetShip()
                    else
                        gameState = "GAMEOVER"
                    end
                end
            end
            
            if hit then
                table.remove(asteroids, i)
                -- Split
                if a.size > 1 then
                    spawnAsteroid(a.x, a.y, a.size - 1)
                    spawnAsteroid(a.x, a.y, a.size - 1)
                end
                asteroidDestroyed = true
            end
        end
        
        -- Level End Check
        if asteroidDestroyed and #asteroids == 0 then
             level = level + 1
             startLevel()
        end
        
        -- ---------- DRAWING ----------
        -- Ship (Vector Triangle)
        if ship.active and (ship.immuneTimer % 4 < 2) then -- Flicker if immune
            local rad = math.rad(ship.angle)
            local tipX = ship.x + math.cos(rad) * 10
            local tipY = ship.y + math.sin(rad) * 10
            local leftX = ship.x + math.cos(rad + 2.5) * 8
            local leftY = ship.y + math.sin(rad + 2.5) * 8
            local rightX = ship.x + math.cos(rad - 2.5) * 8
            local rightY = ship.y + math.sin(rad - 2.5) * 8
            
            gfx.drawLine(tipX, tipY, leftX, leftY)
            gfx.drawLine(leftX, leftY, rightX, rightY)
            gfx.drawLine(rightX, rightY, tipX, tipY)
        end
        
        -- Asteroids
        for _, a in ipairs(asteroids) do
            local pts = a.points
            for j=1, #pts do
                local p1 = pts[j]
                local p2 = pts[(j % #pts) + 1]
                gfx.drawLine(a.x + p1.x, a.y + p1.y, a.x + p2.x, a.y + p2.y)
            end
        end
        
        -- Bullets
        for _, b in ipairs(bullets) do
            gfx.drawPixel(b.x, b.y)
        end
        
        -- UI
        gfx.drawText("Score: " .. score, 5, 5)
        gfx.drawText("Lives: " .. lives, 340, 5)
        
    elseif gameState == "GAMEOVER" then
        -- Draw simple background scene?
        gfx.drawText("GAME OVER", 160, 100)
        gfx.drawText("Final Score: " .. score, 145, 120)
        gfx.drawText("Press A to Restart", 140, 140)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "START"
        end
    end
    
    playdate.drawFPS(0,0)
end
