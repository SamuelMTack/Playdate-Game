import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics
local pd = playdate

-- --- CONSTANTS ---
local TILE_SIZE = 20
local MAP_W = 40
local MAP_H = 30
local VIEW_W = 400
local VIEW_H = 240
local SPEED = 3
local FUEL_MAX = 1000

-- Radar Config
local RADAR_SCALE = 2 -- Scale down factor (needs to fit 40x30 tiles into side of screen)
-- Actually, let's draw Radar on the Right side overlay.
-- Map is 40*20 = 800px wide. Radar needs to small.
-- Let's say Radar is 80x60 pixels. (Scale 2px per tile)
local RADAR_W = MAP_W * 2
local RADAR_H = MAP_H * 2
local RADAR_X = 400 - RADAR_W - 5
local RADAR_Y = 120 - RADAR_H/2 

-- --- STATE ---
local map = {} -- 2D array: 1 = Wall, 0 = Road
local flags = {} -- List of {x, y, collected} (Tile coords)
local rocks = {} -- List of {x, y}
local enemies = {} -- List of {x, y, dir}

local player = {
    x = 0, y = 0, -- Pixel coords
    dir = "RIGHT",
    nextDir = "RIGHT",
    fuel = FUEL_MAX,
    smoke = 0
}

local camera = { x = 0, y = 0 }
local gameState = "PLAYING"
local score = 0
local level = 1

-- --- GENERATION ---

function initMap()
    map = {}
    -- Fill with walls
    for y=1, MAP_H do
        map[y] = {}
        for x=1, MAP_W do
            map[y][x] = 1
        end
    end
    
    -- Recursive Backtracker Maze - simplified or just random digger?
    -- Let's do a simple random walker digger to ensure connectivity, but keep it open (loops).
    -- Actually, Rally-X is very open. Let's make a grid of blocks.
    
    for y=2, MAP_H-1 do
        for x=2, MAP_W-1 do
            -- Create a grid of pillars
            if x % 4 == 0 and y % 4 == 0 then
                -- Wall clusters (Pillars/Buildings)
                map[y][x] = 1
                map[y+1][x] = 1
                map[y][x+1] = 1
                map[y+1][x+1] = 1
            else
                map[y][x] = 0 -- Road
            end
            
            -- Add random walls to create maze-like feel
            if math.random() < 0.1 then map[y][x] = 1 end
        end
    end
    
    -- Clear spawn area
    for y=2, 5 do for x=2, 5 do map[y][x] = 0 end end
    
    -- Spawn Flags
    flags = {}
    local flagsNeeded = 10
    while #flags < flagsNeeded do
        local fx, fy = math.random(2, MAP_W-1), math.random(2, MAP_H-1)
        if map[fy][fx] == 0 then
            table.insert(flags, {x=fx, y=fy, collected=false})
        end
    end
    
    -- Spawn Rocks
    rocks = {}
    for i=1, 15 do
        local rx, ry = math.random(5, MAP_W-1), math.random(5, MAP_H-1)
        if map[ry][rx] == 0 then
             -- Don't put rock on flag
             local safe = true
             for _,f in pairs(flags) do if f.x==rx and f.y==ry then safe=false end end
             if safe then table.insert(rocks, {x=rx, y=ry}) end
        end
    end
    
    -- Spawn Enemies
    enemies = {}
    for i=1, 3 do
        table.insert(enemies, {x = (MAP_W-2)*TILE_SIZE, y = (MAP_H-2)*TILE_SIZE, dir="LEFT"})
    end
    
    -- Reset Player
    player.x = 3 * TILE_SIZE
    player.y = 3 * TILE_SIZE
    player.dir = "RIGHT"
    player.nextDir = "RIGHT"
    player.fuel = FUEL_MAX
end

-- --- LOGIC ---

function isSolid(px, py)
    -- Check collision with map walls
    -- px, py are pixel coordinates of center/corners
    local tx = math.floor(px / TILE_SIZE) + 1
    local ty = math.floor(py / TILE_SIZE) + 1
    
    if tx < 1 or tx > MAP_W or ty < 1 or ty > MAP_H then return true end
    return map[ty][tx] == 1
end

function checkCollision(objX, objY, size)
    local margin = 2
    -- Check 4 corners
    if isSolid(objX + margin, objY + margin) then return true end
    if isSolid(objX + size - margin, objY + margin) then return true end
    if isSolid(objX + margin, objY + size - margin) then return true end
    if isSolid(objX + size - margin, objY + size - margin) then return true end
    
    -- Check Rocks
    local cx = objX + size/2
    local cy = objY + size/2
    for _, r in ipairs(rocks) do
        local rx = (r.x-1)*TILE_SIZE + TILE_SIZE/2
        local ry = (r.y-1)*TILE_SIZE + TILE_SIZE/2
        if (cx-rx)^2 + (cy-ry)^2 < (TILE_SIZE/2 + size/2 - 4)^2 then
            return true -- Hit rock
        end
    end
    
    return false
end

function updatePlayer()
    if gameState ~= "PLAYING" then return end
    
    -- Input buffer
    if pd.buttonIsPressed(pd.kButtonUp) then player.nextDir = "UP" end
    if pd.buttonIsPressed(pd.kButtonDown) then player.nextDir = "DOWN" end
    if pd.buttonIsPressed(pd.kButtonLeft) then player.nextDir = "LEFT" end
    if pd.buttonIsPressed(pd.kButtonRight) then player.nextDir = "RIGHT" end
    
    -- Try to switch direction
    -- Only allow turn if centered on tile axis?
    -- Rally-X style: Continuous movement, turn anywhere? No, usually grid snapped or smooth but collides.
    -- Let's try smooth movement but eager turning.
    
    local moves = {
        UP = {0, -SPEED},
        DOWN = {0, SPEED},
        LEFT = {-SPEED, 0},
        RIGHT = {SPEED, 0}
    }
    
    -- Attempt Next Dir
    local dx, dy = table.unpack(moves[player.nextDir])
    if not checkCollision(player.x + dx, player.y + dy, TILE_SIZE) then
        player.dir = player.nextDir
    end
    
    -- Move Current Dir
    dx, dy = table.unpack(moves[player.dir])
    if not checkCollision(player.x + dx, player.y + dy, TILE_SIZE) then
        player.x = player.x + dx
        player.y = player.y + dy
    else
        -- Wall hit, stop? No, Rally-X you just stop.
    end
    
    -- Fuel
    player.fuel = player.fuel - 0.5
    if player.fuel <= 0 then
        player.fuel = 0
        SPEED = 1 -- Snail pace
    end
    
    -- Flag Collection
    local cx = player.x + TILE_SIZE/2
    local cy = player.y + TILE_SIZE/2
    local allCollected = true
    for _, f in ipairs(flags) do
        if not f.collected then
            local fx = (f.x-1)*TILE_SIZE + TILE_SIZE/2
            local fy = (f.y-1)*TILE_SIZE + TILE_SIZE/2
            if (cx-fx)^2 + (cy-fy)^2 < (TILE_SIZE/2 + TILE_SIZE/2)^2 then
                f.collected = true
                score = score + 100
                player.fuel = math.min(FUEL_MAX, player.fuel + 100)
            else
                allCollected = false
            end
        end
    end
    
    if allCollected then
        -- Win Level
        gameState = "WIN"
    end
    
    -- Camera Follow
    camera.x = player.x - VIEW_W/2
    camera.y = player.y - VIEW_H/2
    
    -- Clamp Camera
    camera.x = math.max(0, math.min(camera.x, MAP_W*TILE_SIZE - VIEW_W))
    camera.y = math.max(0, math.min(camera.y, MAP_H*TILE_SIZE - VIEW_H))
end

function updateEnemies()
    -- Simple chase logic
    for _, e in ipairs(enemies) do
        local dx = 0
        local dy = 0
        if e.x < player.x then dx = 1 end
        if e.x > player.x then dx = -1 end
        if e.y < player.y then dy = 1 end
        if e.y > player.y then dy = -1 end
        
        -- Move slower than player
        local eSpeed = 1.5
        
        -- Try X
        if not checkCollision(e.x + dx*eSpeed, e.y, TILE_SIZE) then
            e.x = e.x + dx*eSpeed
        -- Try Y
        elseif not checkCollision(e.x, e.y + dy*eSpeed, TILE_SIZE) then
            e.y = e.y + dy*eSpeed
        end
        
        -- Collision with player
        local dist = (e.x - player.x)^2 + (e.y - player.y)^2
        if dist < (TILE_SIZE*0.8)^2 then
            gameState = "GAMEOVER"
        end
    end
end

-- --- RENDER ---

function drawMap()
    -- Draw Visible Tiles
    local startCol = math.floor(camera.x / TILE_SIZE) + 1
    local endCol = startCol + (VIEW_W / TILE_SIZE) + 1
    local startRow = math.floor(camera.y / TILE_SIZE) + 1
    local endRow = startRow + (VIEW_H / TILE_SIZE) + 1
    
    gfx.setColor(gfx.kColorBlack)
    
    for y=startRow, endRow do
        for x=startCol, endCol do
            if y>=1 and y<=MAP_H and x>=1 and x<=MAP_W then
                local px = (x-1)*TILE_SIZE - camera.x
                local py = (y-1)*TILE_SIZE - camera.y
                
                if map[y][x] == 1 then
                    -- Wall
                    gfx.fillRect(px, py, TILE_SIZE, TILE_SIZE)
                    gfx.setColor(gfx.kColorWhite)
                    gfx.drawRect(px+2, py+2, TILE_SIZE-4, TILE_SIZE-4)
                    gfx.setColor(gfx.kColorBlack)
                else
                    -- Road
                    -- Maybe dots?
                end
            end
        end
    end
end

function drawEntities()
    -- FLAGS
    for _, f in ipairs(flags) do
        if not f.collected then
            local px = (f.x-1)*TILE_SIZE - camera.x
            local py = (f.y-1)*TILE_SIZE - camera.y
            gfx.drawText("F", px+5, py+2)
        end
    end
    
    -- ROCKS
    for _, r in ipairs(rocks) do
        local px = (r.x-1)*TILE_SIZE - camera.x
        local py = (r.y-1)*TILE_SIZE - camera.y
        gfx.fillCircleAtPoint(px+TILE_SIZE/2, py+TILE_SIZE/2, 6)
    end
    
    -- ENEMIES
    for _, e in ipairs(enemies) do
        local px = e.x - camera.x
        local py = e.y - camera.y
        gfx.fillRect(px, py, TILE_SIZE, TILE_SIZE)
        -- Red is dithered gray/black?
        gfx.setColor(gfx.kColorWhite)
        gfx.drawText("E", px+5, py+2)
        gfx.setColor(gfx.kColorBlack)
    end
    
    -- PLAYER
    local px = player.x - camera.x
    local py = player.y - camera.y
    gfx.fillRect(px, py, TILE_SIZE, TILE_SIZE)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(px+TILE_SIZE/2, py+TILE_SIZE/2, 4) -- Driver helmet
    gfx.setColor(gfx.kColorBlack)
end

function drawRadar()
    -- Draw Background
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(RADAR_X - 2, RADAR_Y - 2, RADAR_W + 4, RADAR_H + 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(RADAR_X, RADAR_Y, RADAR_W, RADAR_H)
    
    -- Draw Dots
    gfx.setColor(gfx.kColorWhite)
    
    -- Player
    local px = (player.x / (MAP_W*TILE_SIZE)) * RADAR_W
    local py = (player.y / (MAP_H*TILE_SIZE)) * RADAR_H
    gfx.fillCircleAtPoint(RADAR_X + px, RADAR_Y + py, 2)
    
    -- Flags
    for _, f in ipairs(flags) do
        if not f.collected then
            local fx = ((f.x-1) / MAP_W) * RADAR_W
            local fy = ((f.y-1) / MAP_H) * RADAR_H
            gfx.drawPixel(RADAR_X + fx, RADAR_Y + fy)
        end
    end
    
    -- Enemies
    for _, e in ipairs(enemies) do
         local ex = (e.x / (MAP_W*TILE_SIZE)) * RADAR_W
         local ey = (e.y / (MAP_H*TILE_SIZE)) * RADAR_H
         -- Blink enemies?
         if pd.getCurrentTimeMilliseconds() % 500 < 250 then
             gfx.drawPixel(RADAR_X + ex, RADAR_Y + ey)
         end
    end
end

function drawUI()
    gfx.drawText("SCORE: " .. score, 5, 220)
    gfx.drawText("FUEL", 350, 210)
    gfx.drawRect(350, 225, 40, 5)
    local w = (player.fuel / FUEL_MAX) * 40
    gfx.fillRect(350, 225, w, 5)
    
    drawRadar()
    
    if gameState == "GAMEOVER" then
        gfx.drawTextAligned("GAME OVER", 200, 100, kTextAlignment.center)
        gfx.drawTextAligned("A to Restart", 200, 120, kTextAlignment.center)
    elseif gameState == "WIN" then
        gfx.drawTextAligned("LEVEL CLEARED!", 200, 100, kTextAlignment.center)
        gfx.drawTextAligned("A to Countinue", 200, 120, kTextAlignment.center)
    end
end

-- --- MAIN ---

math.randomseed(pd.getSecondsSinceEpoch())
initMap()

function pd.update()
    if gameState == "PLAYING" then
        updatePlayer()
        updateEnemies()
    elseif gameState == "GAMEOVER" or gameState == "WIN" then
        if pd.buttonJustPressed(pd.kButtonA) then
            initMap()
            score = 0
            gameState = "PLAYING"
        end
    end
    
    gfx.clear()
    drawMap()
    drawEntities()
    drawUI()
end
