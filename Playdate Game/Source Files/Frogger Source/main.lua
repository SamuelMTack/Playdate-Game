import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics
local pd = playdate

-- --- CONSTANTS ---
local GRID = 20
local SCR_W = 400
local SCR_H = 240
local START_X = 200
local START_Y = 220 -- Bottom row
local LIVES_START = 3
local TIME_LIMIT = 60 * 30 -- 60 seconds (approx)

-- --- STATE ---
local frog = {x=START_X, y=START_Y, w=14, h=14, state="IDLE"} -- State: IDLE, JUMP, DEAD, WIN
local lives = LIVES_START
local score = 0
local timeVal = TIME_LIMIT
local level = 1
local bays = {false, false, false, false, false} -- 5 home bays
local lanes = {}
local gameState = "PLAYING"

-- --- LANE CONFIG ---
-- Rows from Top (0) to Bottom (11)
-- 0: Score/HUD
-- 1: Home Bays
-- 2-6: River
-- 7: Safe Strip
-- 8-12: Road
-- 13: Start Bank

function initLanes()
    lanes = {}
    -- RIVER (Rows 2-6 / Y: 40, 60, 80, 100, 120)
    table.insert(lanes, {y=40, type="RIVER", speed=1.5, dir=-1, items={}, spawnRate=120, width=60}) -- Logs
    table.insert(lanes, {y=60, type="RIVER", speed=2.5, dir=1, items={}, spawnRate=90, width=40}) -- Turtles
    table.insert(lanes, {y=80, type="RIVER", speed=1.0, dir=-1, items={}, spawnRate=150, width=80}) -- Long Logs
    table.insert(lanes, {y=100, type="RIVER", speed=2.0, dir=1, items={}, spawnRate=80, width=40}) -- Turtles
    table.insert(lanes, {y=120, type="RIVER", speed=1.2, dir=-1, items={}, spawnRate=110, width=50}) -- Logs
    
    -- SAFE (Row 7 / Y: 140)
    -- Road (Rows 8-12 / Y: 160, 180, 200, 220, 240 - wait, 240 is off screen bottom)
    -- Let's adjust grid alignments.
    -- Screen Height 240. 12 rows of 20px.
    -- Row 0: 0-20 (HUD)
    -- Row 1: 20-40 (HOME)
    -- Row 2: 40-60 (River)
    -- Row 3: 60-80 (River)
    -- Row 4: 80-100 (River)
    -- Row 5: 100-120 (River)
    -- Row 6: 120-140 (River)
    -- Row 7: 140-160 (SAFE)
    -- Row 8: 160-180 (Road)
    -- Row 9: 180-200 (Road)
    -- Row 10: 200-220 (Road)
    -- Row 11: 220-240 (Road) -- WAIT, Frog starts here relative to bottom?
    -- No, usually 5 lanes road + 5 lanes river + 1 safe + 1 home + 1 start = 13 rows.
    -- 13 * 20 = 260. Too tall for 240 screen.
    -- We'll shrink: 4 Road, 1 Safe, 4 River, 1 Home.
    -- Total 10 rows + HUD + Start.
    -- Let's define Y coords explicitly.
    
    -- Y Centers:
    -- Home: 30
    -- River: 50, 70, 90, 110
    -- Safe: 130
    -- Road: 150, 170, 190, 210
    -- Start: 230
    
    lanes = {}
    -- River
    table.insert(lanes, {y=50, type="RIVER", speed=1.5, dir=-1, items={}, spawnTimer=0, spawnRate=90, width=50})
    table.insert(lanes, {y=70, type="RIVER", speed=2.0, dir=1, items={}, spawnTimer=0, spawnRate=80, width=30})
    table.insert(lanes, {y=90, type="RIVER", speed=2.5, dir=-1, items={}, spawnTimer=0, spawnRate=60, width=60})
    table.insert(lanes, {y=110, type="RIVER", speed=1.2, dir=1, items={}, spawnTimer=0, spawnRate=100, width=40})
    
    -- Road
    table.insert(lanes, {y=150, type="ROAD", speed=2.0, dir=-1, items={}, spawnTimer=0, spawnRate=70, width=25})
    table.insert(lanes, {y=170, type="ROAD", speed=1.5, dir=1, items={}, spawnTimer=0, spawnRate=90, width=30})
    table.insert(lanes, {y=190, type="ROAD", speed=3.0, dir=-1, items={}, spawnTimer=0, spawnRate=60, width=20})
    table.insert(lanes, {y=210, type="ROAD", speed=1.8, dir=1, items={}, spawnTimer=0, spawnRate=80, width=25})
    
    -- Pre-populate
    for _, l in ipairs(lanes) do
        -- Add a few random items
        local cx = math.random(0, 400)
        table.insert(l.items, {x=cx, w=l.width})
    end
end

function resetFrog()
    frog.x = START_X
    frog.y = 230 -- Center of bottom row
    frog.state = "IDLE"
    timeVal = TIME_LIMIT
end

function initGame()
    lives = LIVES_START
    score = 0
    level = 1
    bays = {false, false, false, false, false}
    initLanes()
    resetFrog()
    gameState = "PLAYING"
end

-- --- HELPERS ---

function checkAABB(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx+bw and ax+aw > bx and ay < by+bh and ay+ah > by
end

function updateLanes()
    for _, l in ipairs(lanes) do
        -- Spawn
        l.spawnTimer = l.spawnTimer + 1
        if l.spawnTimer > l.spawnRate then
            l.spawnTimer = 0 + math.random(-20, 20)
            local itemX = (l.dir == 1) and -l.width or 400
            table.insert(l.items, {x=itemX, w=l.width})
        end
        
        -- Move & Despawn
        for i=#l.items, 1, -1 do
            local item = l.items[i]
            item.x = item.x + (l.speed * l.dir)
            if (l.dir == 1 and item.x > 450) or (l.dir == -1 and item.x < -50) then
                table.remove(l.items, i)
            end
        end
    end
end

function updateFrog()
    if frog.state == "DEAD" or frog.state == "WIN" then return end
    
    -- Controls
    if pd.buttonJustPressed(pd.kButtonUp) then frog.y = frog.y - GRID end
    if pd.buttonJustPressed(pd.kButtonDown) then frog.y = frog.y + GRID end
    if pd.buttonJustPressed(pd.kButtonLeft) then frog.x = frog.x - GRID end
    if pd.buttonJustPressed(pd.kButtonRight) then frog.x = frog.x + GRID end
    
    -- Bounds
    frog.x = math.max(10, math.min(frog.x, 390))
    frog.y = math.max(30, math.min(frog.y, 230))
    
    -- Mechanics
    local onLog = false
    local inRiver = false
    
    for _, l in ipairs(lanes) do
        -- Check if frog is vertically in this lane (approx)
        if math.abs(frog.y - l.y) < 10 then
            -- In a lane
            local hit = false
            for _, item in ipairs(l.items) do
                -- Centered hitbox for item
                local ix = item.x - item.w/2
                local iy = l.y - 10
                if checkAABB(frog.x-7, frog.y-7, 14, 14, ix, iy, item.w, 20) then
                    hit = true
                    if l.type == "RIVER" then
                        onLog = true
                        frog.x = frog.x + (l.speed * l.dir) -- Ride log
                    elseif l.type == "ROAD" then
                        killFrog()
                        return
                    end
                end
            end
            
            if l.type == "RIVER" then
                inRiver = true
            end
        end
    end
    
    -- Water Logic
    if inRiver and not onLog then
        killFrog()
        return
    end
    
    -- Home Logic (Row 1 / Y=30)
    if frog.y == 30 then
        -- Check bays
        -- 5 bays evenly spaced?
        -- Screen 400. 5 bays.
        -- Let's say bays are at X: 40, 120, 200, 280, 360
        local dist = 999
        local bayIdx = -1
        local closestX = 0
        
        local bayLocs = {40, 120, 200, 280, 360}
        
        for i, bx in ipairs(bayLocs) do
            local d = math.abs(frog.x - bx)
            if d < dist then
                dist = d
                bayIdx = i
                closestX = bx
            end
        end
        
        if dist < 15 then
            if not bays[bayIdx] then
                bays[bayIdx] = true
                score = score + 500 + timeVal*10
                landSafe()
            else
                killFrog() -- Landed in occupied bay
            end
        else
            killFrog() -- Missed bay (hit wall)
        end
    end
    
    -- Timer
    timeVal = timeVal - 1
    if timeVal <= 0 then killFrog() end
end

function killFrog()
    lives = lives - 1
    if lives < 0 then
        gameState = "GAMEOVER"
    else
        resetFrog()
    end
end

function landSafe()
    -- Check if all bays full
    local allFull = true
    for i=1, 5 do if not bays[i] then allFull = false end end
    
    if allFull then
        score = score + 1000
        gameState = "LEVEL_CLEAR"
    else
        resetFrog()
    end
end

-- --- DRAW ---

function drawGame()
    -- Draw Water
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 40, 400, 80) -- River band (Rows 2-5: 40-120)
    
    -- Draw Safe
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 120, 400, 20) -- Safe strip
    
    -- Draw Road
    gfx.setColor(gfx.kColorBlack) -- Road bg (maybe gray dither?)
    gfx.setPattern({0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA})
    gfx.fillRect(0, 140, 400, 80)
    gfx.setColor(gfx.kColorBlack) -- Reset
    
    -- Draw Lanes Objects
    for _, l in ipairs(lanes) do
        local y = l.y
        for _, item in ipairs(l.items) do
            local x = item.x
            local w = item.w
            if l.type == "RIVER" then
                -- Defaut: Log (Brown/Wood rect)
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRoundRect(x-w/2, y-8, w, 16, 4)
                gfx.setColor(gfx.kColorBlack)
                gfx.drawRoundRect(x-w/2, y-8, w, 16, 4)
            else
                -- Car
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(x-w/2, y-8, w, 16)
                -- Wheels
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(x-w/2+2, y-8+2, w-4, 16-4)
            end
        end
    end
    
    -- Draw Home Bays
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 20, 400, 20) -- Header wall
    local bayLocs = {40, 120, 200, 280, 360}
    for i, bx in ipairs(bayLocs) do
        -- Draw Slot
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(bx-15, 20, 30, 20)
        
        if bays[i] then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillCircleAtPoint(bx, 30, 8) -- Frog in bay
        end
    end
    
    -- Draw Frog
    -- Simple shape
    if gameState == "PLAYING" then
        local fx, fy = frog.x, frog.y
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(fx, fy, 8)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(fx, fy, 8)
        -- Legs?
        gfx.drawLine(fx-8, fy, fx-12, fy+5)
        gfx.drawLine(fx+8, fy, fx+12, fy+5)
    end
    
    -- UI
    gfx.drawText("SCORE: " .. score, 5, 2)
    gfx.drawText("LIVES: " .. lives, 300, 2)
    -- Time bar
    gfx.drawRect(100, 5, 100, 10)
    local tW = (timeVal / TIME_LIMIT) * 100
    gfx.fillRect(100, 5, tW, 10)
    
    if gameState == "GAMEOVER" then
        gfx.fillRect(100, 100, 200, 50)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(102, 102, 196, 46)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawTextAligned("GAME OVER", 200, 110, kTextAlignment.center)
        gfx.drawTextAligned("A to Restart", 200, 130, kTextAlignment.center)
    elseif gameState == "LEVEL_CLEAR" then
         gfx.drawTextAligned("LEVEL CLEAR!", 200, 120, kTextAlignment.center)
    end
end

-- --- MAIN ---

math.randomseed(pd.getSecondsSinceEpoch())
initGame()

function pd.update()
    gfx.clear(gfx.kColorWhite)
    
    if gameState == "PLAYING" then
        updateLanes()
        updateFrog()
    elseif gameState == "GAMEOVER" then
        if pd.buttonJustPressed(pd.kButtonA) then
            initGame()
        end
    elseif gameState == "LEVEL_CLEAR" then
        if pd.buttonJustPressed(pd.kButtonA) then
            -- Next level logic? Just reset for now
            bays = {false, false, false, false, false}
            resetFrog()
            gameState = "PLAYING"
            level = level + 1
        end
    end
    
    drawGame()
end
