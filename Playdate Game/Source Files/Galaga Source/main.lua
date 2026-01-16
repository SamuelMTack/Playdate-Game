import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics

-- Sound
local fireSynth = playdate.sound.synth.new(playdate.sound.kWaveSawtooth)
local boomSynth = playdate.sound.synth.new(playdate.sound.kWaveNoise)

-- Game State
local gameState = "START"
local score = 0
local wave = 1
local ticks = 0

-- Entities
local ship = {x = 200, y = 210, w=16, h=16, active = true}
local playerBullets = {}
local enemyBullets = {}
local enemies = {} -- State: ENTRY, IDLE, DIVE

-- Formation Grid
local GRID_ROWS = 4
local GRID_COLS = 6
local GRID_START_X = 60
local GRID_START_Y = 30
local GRID_SPACING_X = 40
local GRID_SPACING_Y = 25

function setupGame()
    score = 0
    wave = 1
    ticks = 0
    resetShip()
    startWave()
end

function resetShip()
    ship.x = 200
    ship.y = 210
    ship.active = true
end

function startWave()
    enemies = {}
    playerBullets = {}
    enemyBullets = {}
    
    -- Spawn enemies in "ENTRY" state
    -- They start off-screen and fly to their grid position
    for r=1, GRID_ROWS do
        for c=1, GRID_COLS do
            local targetX = GRID_START_X + (c-1)*GRID_SPACING_X
            local targetY = GRID_START_Y + (r-1)*GRID_SPACING_Y
            
            table.insert(enemies, {
                x = math.random() < 0.5 and -20 or 420, -- Left or Right side
                y = math.random(-50, 100),
                tx = targetX, ty = targetY, -- Target Grid Pos
                state = "ENTRY",
                w=16, h=16,
                diveTimer = math.random(200, 1000) -- Time until dive
            })
        end
    end
end

function updateEnemies()
    local swarmOffset = math.sin(ticks * 0.05) * 20 -- Idle sway
    
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        
        if e.state == "ENTRY" then
            -- Move towards grid pos + swarm offset
            local destX = e.tx + swarmOffset
            local destY = e.ty
            
            local dx = destX - e.x
            local dy = destY - e.y
            e.x = e.x + dx * 0.05
            e.y = e.y + dy * 0.05
            
            if math.abs(dx) < 2 and math.abs(dy) < 2 then
                e.state = "IDLE"
            end
            
        elseif e.state == "IDLE" then
            e.x = e.tx + swarmOffset
            e.y = e.ty
            
            e.diveTimer = e.diveTimer - 1
            if e.diveTimer <= 0 then
                e.state = "DIVE"
                -- Calculate dive vector (Bezier or simple homing?)
                -- Simple homing for now
                local angle = math.atan2(ship.y - e.y, ship.x - e.x)
                e.vx = math.cos(angle) * 3
                e.vy = math.sin(angle) * 3
            end
            
        elseif e.state == "DIVE" then
            e.x = e.x + e.vx
            e.y = e.y + e.vy
            
            -- Curve back up if missed? Or just fly off screen
            if e.y > 250 or e.x < -20 or e.x > 420 then
                 -- Re-enter
                 e.x = math.random(0, 400)
                 e.y = -20
                 e.state = "ENTRY"
                 e.diveTimer = math.random(300, 800)
            end
            
            -- Fire bullet logic (random chance)
            if math.random() < 0.02 then
                table.insert(enemyBullets, {x=e.x+8, y=e.y+16, vy=4})
            end
        end
        
        -- Collision: Enemy body vs Ship
        if ship.active and e.x < ship.x + ship.w and e.x + e.w > ship.x and
           e.y < ship.y + ship.h and e.y + e.h > ship.y then
            gameState = "GAMEOVER"
            boomSynth:playNote("C2", 0.5, 0.5)
        end
    end
    
    if #enemies == 0 then
        wave = wave + 1
        startWave()
    end
end

function playdate.update()
    gfx.clear()
    ticks = ticks + 1
    
    if gameState == "START" then
        gfx.drawText("GALAGA CLONE", 145, 100)
        gfx.drawText("Press A to Start", 145, 140)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            setupGame()
            gameState = "PLAY"
        end
        
    elseif gameState == "PLAY" then
        -- ---------- SHIP ----------
        if ship.active then
            local change = playdate.getCrankChange()
            if change ~= 0 then
                 ship.x = ship.x + change
            else
                if playdate.buttonIsPressed(playdate.kButtonLeft) then ship.x = ship.x - 3 end
                if playdate.buttonIsPressed(playdate.kButtonRight) then ship.x = ship.x + 3 end
            end
            
            if ship.x < 0 then ship.x = 0 end
            if ship.x > 384 then ship.x = 384 end
            
            if playdate.buttonJustPressed(playdate.kButtonA) then
                table.insert(playerBullets, {x=ship.x+8, y=ship.y, vy=-6})
                fireSynth:playNote("C5", 0.05, 0.2)
            end
        end
        
        -- ---------- BULLETS ----------
        for i = #playerBullets, 1, -1 do
            local b = playerBullets[i]
            b.y = b.y + b.vy
            if b.y < -10 then table.remove(playerBullets, i) end
            
            -- Check Hit
            for j = #enemies, 1, -1 do
                 local e = enemies[j]
                 if b.x > e.x and b.x < e.x + e.w and b.y > e.y and b.y < e.y + e.h then
                     table.remove(enemies, j)
                     table.remove(playerBullets, i) -- One shot one kill
                     score = score + 100
                     if e.state == "DIVE" then score = score + 100 end -- Bonus for diving hit
                     boomSynth:playNote("G3", 0.1, 0.2)
                     break
                 end
            end
        end
        
        for i = #enemyBullets, 1, -1 do
            local b = enemyBullets[i]
            b.y = b.y + b.vy
            if b.y > 250 then table.remove(enemyBullets, i) end
            
            -- Hit Player
            if ship.active and b.x > ship.x and b.x < ship.x + ship.w and b.y > ship.y and b.y < ship.y + ship.w then
                 gameState = "GAMEOVER"
                 boomSynth:playNote("C2", 0.5, 0.5)
            end
        end
        
        -- ---------- ENEMIES ----------
        updateEnemies()
        
        drawGame()
        
    elseif gameState == "GAMEOVER" then
        drawGame()
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(130, 90, 140, 60)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawText("GAME OVER", 160, 100)
        gfx.drawText("Score: " .. score, 160, 120)
        gfx.drawText("Press A to Restart", 140, 140)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "START"
        end
    end
    
    playdate.drawFPS(0,0)
end

function drawGame()
    -- Ship
    if ship.active then
        -- Simple Fighter Shape
        gfx.fillTriangle(ship.x + 8, ship.y, ship.x, ship.y + 16, ship.x + 16, ship.y + 16)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(ship.x+8, ship.y+4, ship.x+8, ship.y+12)
        gfx.setColor(gfx.kColorBlack)
    end
    
    -- Enemies (Bug Shape)
    for _, e in ipairs(enemies) do
         -- Body
         gfx.fillRect(e.x, e.y+4, 16, 8)
         -- Wings
         if (ticks % 20) < 10 then -- Flap
             gfx.drawLine(e.x, e.y+4, e.x-4, e.y-2)
             gfx.drawLine(e.x+16, e.y+4, e.x+20, e.y-2)
         else
             gfx.drawLine(e.x, e.y+4, e.x-4, e.y+10)
             gfx.drawLine(e.x+16, e.y+4, e.x+20, e.y+10)
         end
         -- Eyes
         gfx.setColor(gfx.kColorWhite)
         gfx.drawPixel(e.x+4, e.y+6)
         gfx.drawPixel(e.x+12, e.y+6)
         gfx.setColor(gfx.kColorBlack)
    end
    
    -- Bullets
    for _, b in ipairs(playerBullets) do
        gfx.drawLine(b.x, b.y, b.x, b.y+4)
    end
    for _, b in ipairs(enemyBullets) do
        gfx.drawRect(b.x-1, b.y, 3, 3)
    end
    
    -- UI
    gfx.drawText("Score: " .. score, 5, 220)
    gfx.drawText("Wave: " .. wave, 340, 220)
end
