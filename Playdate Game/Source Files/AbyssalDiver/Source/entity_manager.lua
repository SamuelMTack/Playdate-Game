local gfx = playdate.graphics

EntityManager = {}
local entities = {}
local spawnTimer = 0

function EntityManager.reset()
    entities = {}
    spawnTimer = 0
end

function EntityManager.update(depth)
    spawnTimer += 1
    
    -- Spawn Logic
    -- Determine spawn rate based on depth (deeper = faster spawns)
    local spawnThreshold = math.max(30, 100 - (depth / 10))
    
    if spawnTimer > spawnThreshold then
        spawnTimer = 0
        spawnEntity(depth)
    end
    
    -- Update Entities
    for i = #entities, 1, -1 do
        local e = entities[i]
        
        -- Movement logic
        e.x += e.dx
        if e.type == "jelly" then
            e.y -= 0.5 -- Floating up
            e.wobbleOffset = math.sin(playdate.getCurrentTimeMilliseconds() / 200 + e.id) * 3
        else
            e.wobbleOffset = math.sin(playdate.getCurrentTimeMilliseconds() / 100 + e.id) * 3
        end
        
        -- Check Collision with Player
        local pBounds = Player.getBounds()
        local eBounds = {x = e.x, y = e.y + e.wobbleOffset, w = e.w, h = e.h} -- Approximate collision box
        
        -- Simple AABB
        if checkCollision(pBounds, eBounds) then
            if e.type == "enemy" or e.type == "angler" or e.type == "jelly" then
                if Player.invincibleTimer > 0 then
                    -- Shield Deflect
                    SoundManager.playBubble() -- Reuse or new sound?
                    table.remove(entities, i)
                else
                    Player.oxygen -= 20
                    SoundManager.playHit()
                    Particles.spawn(e.x, e.y, "explosion")
                    table.remove(entities, i)
                    _G.screenShake = 10
                end 
            elseif e.type == "oxygen" then
                Player.oxygen += 15
                if Player.oxygen > 100 then Player.oxygen = 100 end
                SoundManager.playPickup()
                Particles.spawn(e.x, e.y, "sparkle")
                table.remove(entities, i)
            elseif e.type == "shield" then
                 Player.activatePowerup("shield")
                 SoundManager.playPickup()
                 table.remove(entities, i)
            elseif e.type == "turbo" then
                 Player.activatePowerup("turbo")
                 SoundManager.playPickup()
                 table.remove(entities, i)
            end
        elseif e.x < -30 or e.x > 430 or e.y < -50 then
            table.remove(entities, i)
        end
    end
end

function spawnEntity(depth)
    local e = {}
    e.id = math.random(1000)
    e.y = math.random(40, 230)
    e.w = 16
    e.h = 10
    e.wobbleOffset = 0
    
    -- Determine side
    if math.random() > 0.5 then
        e.x = -20
        e.dx = math.random(2, 5)
        e.facing = 1
    else
        e.x = 420
        e.dx = -math.random(2, 5)
        e.facing = -1
    end
    
    -- Biome Logic
    local rand = math.random()
    e.type = "enemy" -- Default
    
    -- Biome 1: Shallows (0-100) -> Fish, Oxygen
    -- Biome 2: Midnight (100-200) -> Angler, Oxygen, Powerups
    -- Biome 3: Abyss (200+) -> Jelly, Angler, Powerups
    
    if depth < 100 then
        if rand < 0.1 then e.type = "oxygen" end
    elseif depth < 200 then
        if rand < 0.1 then e.type = "oxygen"
        elseif rand < 0.15 then e.type = "shield"
        elseif rand < 0.18 then e.type = "turbo"
        elseif rand < 0.6 then e.type = "angler" end
    else
        if rand < 0.08 then e.type = "oxygen"
        elseif rand < 0.12 then e.type = "shield"
        elseif rand < 0.15 then e.type = "turbo"
        elseif rand < 0.5 then e.type = "jelly"
        else e.type = "angler" end
    end
    
    -- Adjust dimensions based on type
    if e.type == "angler" then e.w = 20; e.h=14 end
    if e.type == "jelly" then e.w = 12; e.h=20; e.dx = e.dx * 0.5 end
    
    table.insert(entities, e)
end

function checkCollision(r1, r2)
    return r1.x < r2.x + r2.w and
           r1.x + r1.w > r2.x and
           r1.y < r2.y + r2.h and
           r1.y + r1.h > r2.y
end

function EntityManager.draw()
    gfx.setLineWidth(1)
    for _, e in ipairs(entities) do
        local y = e.y + (e.wobbleOffset or 0)
        
        -- Invert color if in Midnight Zone? Handled by main.lua clearing to black/white?
        -- We should draw using localized colors or let the global draw mode handle it.
        
        if e.type == "enemy" then
           drawFish(e.x, y, e.facing)
        elseif e.type == "angler" then
           drawAngler(e.x, y, e.facing)
        elseif e.type == "jelly" then
           drawJelly(e.x, y)
        elseif e.type == "oxygen" then
            gfx.drawRect(e.x, y, 12, 16)
            gfx.drawText("O2", e.x+1, y+2)
        if e.type == "shield" then
            gfx.drawEllipseInRect(e.x+8-8, y+8-8, 16, 16)
            gfx.drawText("S", e.x+4, y+2)
        elseif e.type == "turbo" then
            gfx.drawRect(e.x, y, 16, 16)
            gfx.drawText(">>", e.x+2, y+2)
        end
    end
end

function drawFish(x, y, dir)
    gfx.fillEllipseInRect(x, y, 16, 10)
    if dir == 1 then
        gfx.fillTriangle(x, y+5, x-5, y, x-5, y+10)
    else
        gfx.fillTriangle(x+16, y+5, x+21, y, x+21, y+10)
    end
end

function drawAngler(x, y, dir)
    gfx.fillEllipseInRect(x, y, 20, 14)
    -- Lure
    if dir == 1 then
        gfx.drawLine(x+15, y, x+22, y-5)
        gfx.fillEllipseInRect(x+22-2, y-5-2, 4, 4)
    else
        gfx.drawLine(x+5, y, x-2, y-5)
        gfx.fillEllipseInRect(x-2-2, y-5-2, 4, 4)
    end
end

function drawJelly(x, y)
    gfx.fillEllipseInRect(x+6-6, y-6, 12, 12)
    gfx.drawLine(x+2, y, x+2, y+15)
    gfx.drawLine(x+6, y, x+6, y+15)
    gfx.drawLine(x+10, y, x+10, y+15)
end
end
