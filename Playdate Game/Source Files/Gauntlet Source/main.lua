import "CoreLibs/graphics"
import "CoreLibs/timer"
import "level"

local gfx = playdate.graphics

-- Sound
local shotSynth = playdate.sound.synth.new(playdate.sound.kWaveSawtooth)
local hitSynth = playdate.sound.synth.new(playdate.sound.kWaveNoise)

-- Game State
local gameState = "START"
local health = 2000 -- Ticks down
local score = 0
local keys = 0
local levelData = nil

local hero = {x=0, y=0, w=14, h=14, dir=0} -- dir: 0=Right, 1=Down, 2=Left, 3=Up
local projectiles = {}
local enemies = {}
local TILE_SIZE = 20

function setupGame()
    health = 2000
    score = 0
    keys = 0
    loadLevel()
end

function loadLevel()
    levelData = CreateLevelData()
    projectiles = {}
    enemies = {}
    
    -- Scan for entities and start pos
    for y=1, levelData.height do
        for x=1, levelData.width do
            local t = levelData.tiles[y][x]
            if t == levelData.Types.START then
                hero.x = (x-1) * TILE_SIZE + 3
                hero.y = (y-1) * TILE_SIZE + 3
                levelData.tiles[y][x] = levelData.Types.FLOOR -- Clear start tile
            elseif t == levelData.Types.GEN then
                 -- Generator is a static tile in our map, but we could make it an entity.
                 -- For simplicity, we'll scan map for generators in update loop or turn them into entities here.
                 -- Let's turn them into entities so they can be destroyed.
                 table.insert(enemies, {
                     type = "GEN",
                     x = (x-1) * TILE_SIZE,
                     y = (y-1) * TILE_SIZE,
                     w = TILE_SIZE, h = TILE_SIZE,
                     hp = 3,
                     spawnTimer = 0
                 })
                 levelData.tiles[y][x] = levelData.Types.FLOOR -- Replace with floor under generator
            end
        end
    end
end

function checkWall(x, y)
    local tx = math.floor(x / TILE_SIZE) + 1
    local ty = math.floor(y / TILE_SIZE) + 1
    
    if tx < 1 or tx > levelData.width or ty < 1 or ty > levelData.height then return true end
    
    local t = levelData.tiles[ty][tx]
    if t == levelData.Types.WALL or t == levelData.Types.DOOR then return true, t, tx, ty end
    return false
end

function playdate.update()
    gfx.clear()
    
    if gameState == "START" then
        gfx.drawText("GAUNTLET CLONE", 140, 100)
        gfx.drawText("Find the EXIT", 155, 120)
        gfx.drawText("Press A to Start", 145, 140)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            setupGame()
            gameState = "PLAY"
        end
    elseif gameState == "PLAY" then
        -- ---------- HEALTH DRAIN ----------
        health = health - 1
        if health <= 0 then gameState = "GAMEOVER" end
        
        -- ---------- HERO INPUT ----------
        local dx, dy = 0, 0
        local speed = 2
        
        if playdate.buttonIsPressed(playdate.kButtonUp) then dy = -speed; hero.dir = 3 end
        if playdate.buttonIsPressed(playdate.kButtonDown) then dy = speed; hero.dir = 1 end
        if playdate.buttonIsPressed(playdate.kButtonLeft) then dx = -speed; hero.dir = 2 end
        if playdate.buttonIsPressed(playdate.kButtonRight) then dx = speed; hero.dir = 0 end
        
        -- Collision (Wall/Door)
        if not checkWall(hero.x + dx, hero.y) and not checkWall(hero.x + hero.w + dx, hero.y) and
           not checkWall(hero.x + dx, hero.y + hero.h) and not checkWall(hero.x + hero.w + dx, hero.y + hero.h) then
            hero.x = hero.x + dx
        end
        
        if not checkWall(hero.x, hero.y + dy) and not checkWall(hero.x + hero.w, hero.y + dy) and
           not checkWall(hero.x, hero.y + hero.h + dy) and not checkWall(hero.x + hero.w, hero.y + hero.h + dy) then
             hero.y = hero.y + dy
        end
        
        -- Interact with Door/Key/Food/Exit
        local cx = hero.x + hero.w/2
        local cy = hero.y + hero.h/2
        local tx = math.floor(cx / TILE_SIZE) + 1
        local ty = math.floor(cy / TILE_SIZE) + 1
        local tile = levelData.tiles[ty][tx]
        
        if tile == levelData.Types.FOOD then
            health = health + 100
            levelData.tiles[ty][tx] = levelData.Types.FLOOR
            score = score + 10
        elseif tile == levelData.Types.KEY then
            keys = keys + 1
            levelData.tiles[ty][tx] = levelData.Types.FLOOR
            score = score + 100
        elseif tile == levelData.Types.EXIT then
            gameState = "WIN"
        end
        
        -- Check Door collision slightly differently (ahead of player)
        -- Actually, checkWall returns the tile, we can loop nearby tiles to open doors
        local nearby = {
            {tx, ty-1}, {tx, ty+1}, {tx-1, ty}, {tx+1, ty}
        }
        for _, pos in ipairs(nearby) do
            if levelData.tiles[pos[2]] and levelData.tiles[pos[2]][pos[1]] == levelData.Types.DOOR then
                -- Open door if key
                -- Simple check: if player is pushing against it.
                -- For MVP, just proximity + key opens it
                if keys > 0 then
                    keys = keys - 1
                    levelData.tiles[pos[2]][pos[1]] = levelData.Types.FLOOR
                    score = score + 50
                end
            end
        end
        
        
        -- Fire
        if playdate.buttonJustPressed(playdate.kButtonA) then
            local vx, vy = 0, 0
            if hero.dir == 0 then vx = 5 end
            if hero.dir == 1 then vy = 5 end
            if hero.dir == 2 then vx = -5 end
            if hero.dir == 3 then vy = -5 end
            table.insert(projectiles, {x = cx, y = cy, vx = vx, vy = vy, life = 30})
            shotSynth:playNote("C5", 0.05, 0.2)
        end
        
        -- ---------- ENTITIES ----------
        
        -- Projectiles
        for i = #projectiles, 1, -1 do
            local p = projectiles[i]
            p.x = p.x + p.vx
            p.y = p.y + p.vy
            p.life = p.life - 1
            
            -- Hit Wall
            if checkWall(p.x, p.y) then p.life = 0 end
            
            -- Hit Enemy
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if p.x > e.x and p.x < e.x + e.w and p.y > e.y and p.y < e.y + e.h then
                    e.hp = e.hp - 1
                    p.life = 0
                    if e.hp <= 0 then
                        table.remove(enemies, j)
                        score = score + (e.type == "GEN" and 50 or 10)
                        hitSynth:playNote("G3", 0.1, 0.3)
                    else
                        hitSynth:playNote("C4", 0.05, 0.2)
                    end
                    break
                end
            end
            
            if p.life <= 0 then table.remove(projectiles, i) end
        end
        
        -- Enemies
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            if e.type == "GEN" then
                e.spawnTimer = e.spawnTimer + 1
                if e.spawnTimer > 120 then -- Spawn every 4 secs
                    e.spawnTimer = 0
                    -- Spawn Ghost
                    table.insert(enemies, {
                        type = "GHOST",
                        x = e.x, y = e.y,
                        w = 12, h = 12,
                        hp = 1,
                        vx = 0, vy = 0
                    })
                end
            elseif e.type == "GHOST" then
                -- Move towards hero
                local speed = 0.5
                if e.x < hero.x then e.x = e.x + speed end
                if e.x > hero.x then e.x = e.x - speed end
                if e.y < hero.y then e.y = e.y + speed end
                if e.y > hero.y then e.y = e.y - speed end
                
                -- Collide with Hero
                if e.x + e.w > hero.x and e.x < hero.x + hero.w and
                   e.y + e.h > hero.y and e.y < hero.y + hero.h then
                    health = health - 10 -- Hurt hero
                    -- Push back?
                end
            end
        end
        
        drawGame()
        
    elseif gameState == "GAMEOVER" or gameState == "WIN" then
        drawGame()
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(100, 90, 200, 60)
        gfx.setColor(gfx.kColorBlack)
        
        if gameState == "WIN" then
             gfx.drawText("LEVEL COMPLETE", 145, 100)
        else
             gfx.drawText("GAME OVER", 160, 100)
        end
        
        gfx.drawText("Score: " .. score, 160, 120)
        gfx.drawText("Press A to Restart", 135, 140)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "START"
        end
    end
    
    playdate.drawFPS(0,0)
end

function drawGame()
    -- Draw Map
    for y=1, levelData.height do
        for x=1, levelData.width do
            local t = levelData.tiles[y][x]
            local px, py = (x-1)*TILE_SIZE, (y-1)*TILE_SIZE
            if t == levelData.Types.WALL then
                gfx.fillRect(px, py, TILE_SIZE, TILE_SIZE)
            elseif t == levelData.Types.FOOD then
                gfx.drawRect(px+5, py+5, 10, 10) -- Box
                gfx.drawText("+", px+6, py+2)
            elseif t == levelData.Types.KEY then
                 gfx.drawText("k", px+5, py+2)
            elseif t == levelData.Types.DOOR then
                 gfx.fillRect(px+2, py+2, 16, 16)
                 gfx.setColor(gfx.kColorWhite)
                 gfx.drawRect(px+4, py+4, 12, 12)
                 gfx.setColor(gfx.kColorBlack)
            elseif t == levelData.Types.EXIT then
                 gfx.drawText("E", px+5, py+2)
            end
        end
    end
    
    -- Draw Enemies
    for _, e in ipairs(enemies) do
        if e.type == "GEN" then
            gfx.drawRect(e.x, e.y, e.w, e.h)
            gfx.drawRect(e.x+2, e.y+2, e.w-4, e.h-4)
        elseif e.type == "GHOST" then
            gfx.fillCircleAtPoint(e.x + e.w/2, e.y + e.h/2, e.w/2)
        end
    end
    
    -- Draw Hero
    gfx.fillRect(hero.x, hero.y, hero.w, hero.h)
    
    -- Draw Projectiles
    for _, p in ipairs(projectiles) do
        gfx.drawPixel(p.x, p.y)
    end
    
    -- UI
    gfx.fillRect(0, 0, 400, 15) -- Bar background
    gfx.setColor(gfx.kColorWhite)
    gfx.drawText("Health: " .. health, 5, 0)
    gfx.drawText("Score: " .. score, 150, 0)
    gfx.drawText("Keys: " .. keys, 300, 0)
    gfx.setColor(gfx.kColorBlack)
end
