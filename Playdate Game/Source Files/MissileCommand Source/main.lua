import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics

-- Sound
local shootSynth = playdate.sound.synth.new(playdate.sound.kWaveNoise)
local boomSynth = playdate.sound.synth.new(playdate.sound.kWaveNoise)

-- Game State
local gameState = "START"
local score = 0
local level = 1

local crosshair = {x = 200, y = 120, speed = 4}
local cities = {}
local playerMissiles = {}
local enemyMissiles = {}
local explosions = {}

function setupGame()
    score = 0
    level = 1
    
    -- Reset Entities
    playerMissiles = {}
    enemyMissiles = {}
    explosions = {}
    
    -- Setup Cities (6 cities)
    cities = {}
    local spacing = 50
    local startX = 40
    for i=0, 5 do
        -- Skip middle for base? (Playdate screen is small, maybe just line them up)
        table.insert(cities, {
            x = startX + i * spacing + (i >= 3 and 40 or 0), -- Gap in middle
            y = 220,
            w = 30,
            h = 15,
            active = true
        })
    end
end

function spawnEnemyMissile()
    local targetCity = nil
    -- Pick a random active city or just a random ground spot
    local activeCities = {}
    for _, c in ipairs(cities) do if c.active then table.insert(activeCities, c) end end
    
    local targetX = math.random(20, 380)
    local targetY = 230
    
    if #activeCities > 0 and math.random() < 0.7 then
        local c = activeCities[math.random(#activeCities)]
        targetX = c.x + c.w/2
        targetY = c.y + c.h/2
    end
    
    local startX = math.random(0, 400)
    local startY = 0
    
    -- Calculate velocity vector
    local angle = math.atan2(targetY - startY, targetX - startX)
    local speed = 0.5 + (level * 0.1)
    
    table.insert(enemyMissiles, {
        x = startX, y = startY,
        dx = math.cos(angle) * speed,
        dy = math.sin(angle) * speed,
        tx = targetX, ty = targetY, -- Target coordinates
        active = true
    })
end

function createExplosion(x, y)
    table.insert(explosions, {
        x = x, y = y,
        radius = 0,
        maxRadius = 25,
        growing = true,
        active = true
    })
    boomSynth:playNote("C2", 0.3, 0.4)
end

function playdate.update()
    gfx.clear()
    
    if gameState == "START" then
        gfx.drawText("MISSILE COMMAND", 135, 100)
        gfx.drawText("Defend the Cities!", 140, 120)
        gfx.drawText("Press A to Start", 145, 140)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            setupGame()
            gameState = "PLAY"
        end
    elseif gameState == "PLAY" then
        -- INPUT: Crosshair
        if playdate.buttonIsPressed(playdate.kButtonUp) then crosshair.y = crosshair.y - crosshair.speed end
        if playdate.buttonIsPressed(playdate.kButtonDown) then crosshair.y = crosshair.y + crosshair.speed end
        if playdate.buttonIsPressed(playdate.kButtonLeft) then crosshair.x = crosshair.x - crosshair.speed end
        if playdate.buttonIsPressed(playdate.kButtonRight) then crosshair.x = crosshair.x + crosshair.speed end
        
        -- Clamp
        if crosshair.x < 0 then crosshair.x = 0 end
        if crosshair.x > 400 then crosshair.x = 400 end
        if crosshair.y < 0 then crosshair.y = 0 end
        if crosshair.y > 220 then crosshair.y = 220 end
        
        -- INPUT: Fire
        if playdate.buttonJustPressed(playdate.kButtonA) then
            -- Determine source (Central Base: 200, 230)
            local startX, startY = 200, 230
            local tx, ty = crosshair.x, crosshair.y
            local angle = math.atan2(ty - startY, tx - startX)
            local speed = 5
            
            table.insert(playerMissiles, {
                x = startX, y = startY,
                dx = math.cos(angle) * speed,
                dy = math.sin(angle) * speed,
                tx = tx, ty = ty,
                active = true
            })
            shootSynth:playNote("C5", 0.05, 0.2)
        end
        
        -- SPAWN ENEMIES
        if math.random() < (0.01 * level) then
            spawnEnemyMissile()
        end
        
        -- UPDATE: Player Missiles
        for _, m in ipairs(playerMissiles) do
            if m.active then
                m.x = m.x + m.dx
                m.y = m.y + m.dy
                
                -- Check if reached target
                local dist = math.sqrt((m.x - m.tx)^2 + (m.y - m.ty)^2)
                if dist < 5 or m.y < m.ty then -- Simple check logic
                     m.active = false
                     createExplosion(m.tx, m.ty)
                end
            end
        end
        
        -- UPDATE: Explosions
        for _, e in ipairs(explosions) do
            if e.active then
                if e.growing then
                    e.radius = e.radius + 1
                    if e.radius >= e.maxRadius then e.growing = false end
                else
                    e.radius = e.radius - 0.5
                    if e.radius <= 0 then e.active = false end
                end
            end
        end
        
        -- UPDATE: Enemy Missiles
        local anyCityActive = false
        for _, c in ipairs(cities) do if c.active then anyCityActive = true end end
        if not anyCityActive then
            gameState = "GAMEOVER"
        end
        
        for _, m in ipairs(enemyMissiles) do
            if m.active then
                m.x = m.x + m.dx
                m.y = m.y + m.dy
                
                -- Check Ground/City collision
                if m.y > 230 then
                    m.active = false
                    createExplosion(m.x, m.y)
                    -- Check city hit
                    for _, c in ipairs(cities) do
                        if c.active and m.x > c.x and m.x < c.x + c.w then
                            c.active = false
                        end
                    end
                end
                
                -- Check Explosion Collision (Defense)
                for _, e in ipairs(explosions) do
                    if e.active then
                        local dist = math.sqrt((m.x - e.x)^2 + (m.y - e.y)^2)
                        if dist < e.radius then
                            m.active = false
                            score = score + 25
                            -- Chain reaction? Missile doesn't explode, just dies.
                            -- Or create tiny explosion?
                        end
                    end
                end
            end
        end
        
        -- Level Up over time?
        if score > level * 500 then level = level + 1 end
        
        drawGame()
        
    elseif gameState == "GAMEOVER" then
        drawGame()
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(130, 90, 140, 60)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawText("GAME OVER", 160, 100)
        gfx.drawText("Score: " .. score, 165, 120)
        gfx.drawText("Press A to Restart", 140, 140)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "START"
        end
    end
    
    playdate.drawFPS(0,0)
end

function drawGame()
    -- Ground
    gfx.fillRect(0, 230, 400, 10)
    -- Base
    gfx.fillTriangle(190, 230, 210, 230, 200, 215)
    
    -- Cities
    for _, c in ipairs(cities) do
        if c.active then
            gfx.fillRect(c.x, c.y, c.w, c.h)
            -- Roof
            gfx.drawLine(c.x, c.y, c.x + c.w/2, c.y - 5)
            gfx.drawLine(c.x + c.w/2, c.y - 5, c.x + c.w, c.y)
        end
    end
    
    -- Player Missiles
    for _, m in ipairs(playerMissiles) do
        if m.active then
            gfx.drawLine(200, 215, m.x, m.y) -- Draw trail from base
            gfx.drawPixel(m.x, m.y)
        end
    end
    
    -- Enemy Missiles
    for _, m in ipairs(enemyMissiles) do
        if m.active then
            gfx.drawLine(m.x - m.dx * 10, m.y - m.dy * 10, m.x, m.y) -- Short trail
            gfx.drawPixel(m.x, m.y)
        end
    end
    
    -- Explosions
    gfx.setColor(gfx.kColorBlack)
    for _, e in ipairs(explosions) do
        if e.active then
            if (e.radius % 4) < 2 then -- Flashing effect
                gfx.fillCircleAtPoint(e.x, e.y, e.radius)
            else
                gfx.drawCircleAtPoint(e.x, e.y, e.radius)
            end
        end
    end
    
    -- Crosshair
    if gameState == "PLAY" then
        local x, y = crosshair.x, crosshair.y
        gfx.drawLine(x - 5, y, x + 5, y)
        gfx.drawLine(x, y - 5, x, y + 5)
    end
    
    -- UI
    gfx.drawText("Score: " .. score, 5, 5)
    gfx.drawText("Level: " .. level, 340, 5)
end
