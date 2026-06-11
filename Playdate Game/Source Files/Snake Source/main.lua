import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics
local snd = playdate.sound

-- Game States
local STATE_TITLE = 1
local STATE_PLAYING = 2
local STATE_GAMEOVER = 3
local gameState = STATE_TITLE

-- Dimensions & Coordinates
local SCREEN_W = 400
local SCREEN_H = 240
local HUD_H = 32
local CELL_SIZE = 16
local GRID_COLS = 22
local GRID_ROWS = 12

-- Position centering for the 352x192 grid
local leftOffset = 24
local topOffset = 36

-- Persistent High Score
local highScore = 0
local saveData = playdate.datastore.read()
if saveData and saveData.highScore then
    highScore = saveData.highScore
end

-- Sound Synthesizers
local sfxSynth = snd.synth.new(snd.kWaveSquare)
local crankSynth = snd.synth.new(snd.kWaveNoise)
local crashSynth = snd.synth.new(snd.kWaveSawtooth)

-- Music Sequencer
local musicSeq = snd.sequence.new()
local musicPlaying = true

-- Setup sound envelopes
sfxSynth:setVolume(0.3)
crankSynth:setVolume(0.15)
crashSynth:setVolume(0.4)

local function playEatSFX()
    sfxSynth:playNote("G4", 0.08, 0.4)
    playdate.timer.performAfterDelay(80, function()
        sfxSynth:playNote("C5", 0.12, 0.4)
    end)
end

local function playCrankSFX()
    crankSynth:playNote("C8", 0.01, 0.05)
end

local function playDeathSFX()
    crashSynth:playNote("C3", 0.1, 0.6)
    playdate.timer.performAfterDelay(100, function()
        crashSynth:playNote("G2", 0.1, 0.6)
        playdate.timer.performAfterDelay(100, function()
            crashSynth:playNote("C2", 0.35, 0.6)
        end)
    end)
end

local function playHighScoreSFX()
    sfxSynth:playNote("C5", 0.08, 0.5)
    playdate.timer.performAfterDelay(80, function()
        sfxSynth:playNote("E5", 0.08, 0.5)
        playdate.timer.performAfterDelay(80, function()
            sfxSynth:playNote("G5", 0.08, 0.5)
            playdate.timer.performAfterDelay(80, function()
                sfxSynth:playNote("C6", 0.25, 0.5)
            end)
        end)
    end)
end

-- Programmatic Looping Music Composition
local function initMusic()
    local bassSynth = snd.synth.new(snd.kWaveTriangle)
    local melodySynth = snd.synth.new(snd.kWaveTriangle)
    
    bassSynth:setVolume(0.3)
    melodySynth:setVolume(0.2)
    
    local bassTrack = musicSeq:addTrack()
    bassTrack:setInstrument(bassSynth)
    
    local melodyTrack = musicSeq:addTrack()
    melodyTrack:setInstrument(melodySynth)
    
    -- Bass notes (Step, Note, Length)
    local bassNotes = {
        -- Section A
        {1, "C2", 2}, {5, "C2", 2}, {9, "A2", 2}, {13, "A2", 2},
        {17, "F2", 2}, {21, "F2", 2}, {25, "G2", 2}, {29, "G2", 2},
        {33, "C2", 2}, {37, "C2", 2}, {41, "A2", 2}, {45, "A2", 2},
        {49, "F2", 2}, {53, "F2", 2}, {57, "G2", 2}, {61, "G2", 2},
        -- Section B
        {65, "A2", 2}, {69, "A2", 2}, {73, "F2", 2}, {77, "F2", 2},
        {81, "C2", 2}, {85, "C2", 2}, {89, "G2", 2}, {93, "G2", 2},
        {97, "A2", 2}, {101, "A2", 2}, {105, "F2", 2}, {109, "F2", 2},
        {113, "D2", 2}, {117, "D2", 2}, {121, "G2", 2}, {125, "G2", 2}
    }
    
    -- Melody notes (Step, Note, Length)
    local melodyNotes = {
        -- Section A
        {1, "C4", 2}, {3, "E4", 2}, {5, "G4", 2}, {7, "E4", 2},
        {9, "A4", 2}, {11, "C5", 2}, {13, "E5", 2}, {15, "C5", 2},
        {17, "F4", 2}, {19, "A4", 2}, {21, "C5", 2}, {23, "A4", 2},
        {25, "G4", 2}, {27, "B4", 2}, {29, "D5", 2}, {31, "B4", 2},
        
        {33, "C4", 2}, {35, "E4", 2}, {37, "G4", 2}, {39, "C5", 2},
        {41, "E4", 2}, {43, "G4", 2}, {45, "B4", 2}, {47, "E5", 2},
        {49, "F4", 2}, {51, "A4", 2}, {53, "C5", 2}, {55, "F5", 2},
        {57, "G4", 2}, {59, "B4", 2}, {61, "D5", 2}, {63, "G5", 2},
        
        -- Section B
        {65, "E5", 4}, {69, "D5", 4}, {73, "C5", 4}, {77, "A4", 4},
        {81, "G4", 4}, {85, "C5", 4}, {89, "B4", 8},
        {97, "E5", 4}, {101, "F5", 4}, {105, "E5", 4}, {109, "C5", 4},
        {113, "F5", 4}, {117, "E5", 4}, {121, "D5", 4}, {125, "G5", 4}
    }
    
    for _, n in ipairs(bassNotes) do
        bassTrack:addNote(n[1], n[2], n[3])
    end
    
    for _, n in ipairs(melodyNotes) do
        melodyTrack:addNote(n[1], n[2], n[3])
    end
    
    musicSeq:setLoops(0, 128, 0)
    musicSeq:setTempo(140) -- Upbeat BPM
end

initMusic()

local function playMusic()
    if musicPlaying and not musicSeq:isPlaying() then
        musicSeq:play()
    end
end

local function stopMusic()
    if musicSeq:isPlaying() then
        musicSeq:stop()
    end
end

-- System Menu Setup
local sysMenu = playdate.getSystemMenu()
sysMenu:addCheckmarkMenuItem("Music", musicPlaying, function(value)
    musicPlaying = value
    if musicPlaying then
        if gameState == STATE_PLAYING then playMusic() end
    else
        stopMusic()
    end
end)

-- Gameplay variables
local snake = {}
local dx, dy = 1, 0
local nextDx, nextDy = 1, 0
local foodX, foodY = 0, 0
local score = 0
local isNewHighScore = false
local wasHighScoreBeaten = false
local updateInterval = 8
local frameCounter = 0
local crankAccumulator = 0
local particles = {}

-- Title screen decorative snake
local titleSnake = {}
local titleSnakeDir = 1 -- 1=right, 2=down, 3=left, 4=up
local titleSnakeTimer = 0

-- Helper: Get cell center coordinates
local function getCellCenter(gridX, gridY)
    local cx = (gridX - 1) * CELL_SIZE + leftOffset + CELL_SIZE / 2
    local cy = (gridY - 1) * CELL_SIZE + topOffset + CELL_SIZE / 2
    return cx, cy
end

-- Helper: Spawn food away from the snake
local function spawnFood()
    local attempts = 0
    local ok = false
    while not ok and attempts < 100 do
        attempts = attempts + 1
        foodX = math.random(1, GRID_COLS)
        foodY = math.random(1, GRID_ROWS)
        
        ok = true
        for _, segment in ipairs(snake) do
            if segment.x == foodX and segment.y == foodY then
                ok = false
                break
            end
        end
    end
end

-- Helper: Spawn score explosion particles
local function spawnExplosion(gridX, gridY)
    local px, py = getCellCenter(gridX, gridY)
    for i = 1, 12 do
        local angle = math.rad(math.random(0, 360))
        local speed = math.random(2, 6)
        table.insert(particles, {
            x = px,
            y = py,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = math.random(8, 15)
        })
    end
end

-- Initialize Game
local function initGame()
    snake = {
        {x = 6, y = 6},
        {x = 5, y = 6},
        {x = 4, y = 6}
    }
    dx, dy = 1, 0
    nextDx, nextDy = 1, 0
    score = 0
    isNewHighScore = false
    wasHighScoreBeaten = false
    updateInterval = 8
    frameCounter = 0
    crankAccumulator = 0
    particles = {}
    spawnFood()
end

-- Init Title Screen Snake
local function initTitleSnake()
    titleSnake = {}
    for i = 1, 15 do
        table.insert(titleSnake, {x = 16 - i, y = 1})
    end
    titleSnakeDir = 1 -- right
end

initTitleSnake()

-- Update title snake along screen border
local function updateTitleSnake()
    titleSnakeTimer = titleSnakeTimer + 1
    if titleSnakeTimer < 4 then return end
    titleSnakeTimer = 0
    
    local head = titleSnake[1]
    local tx, ty = head.x, head.y
    
    if titleSnakeDir == 1 then -- Right
        tx = tx + 1
        if tx >= GRID_COLS then titleSnakeDir = 2 end
    elseif titleSnakeDir == 2 then -- Down
        ty = ty + 1
        if ty >= GRID_ROWS then titleSnakeDir = 3 end
    elseif titleSnakeDir == 3 then -- Left
        tx = tx - 1
        if tx <= 1 then titleSnakeDir = 4 end
    elseif titleSnakeDir == 4 then -- Up
        ty = ty - 1
        if ty <= 1 then titleSnakeDir = 1 end
    end
    
    table.insert(titleSnake, 1, {x = tx, y = ty})
    table.remove(titleSnake)
end

-- Main Game loop
function playdate.update()
    gfx.clear()
    
    if gameState == STATE_TITLE then
        updateTitleSnake()
        
        -- Draw Background Grid dots
        gfx.setColor(gfx.kColorBlack)
        for col = 1, GRID_COLS do
            for row = 1, GRID_ROWS do
                local cx, cy = getCellCenter(col, row)
                gfx.fillRect(cx, cy, 1, 1)
            end
        end
        
        -- Draw Border
        gfx.drawRect(leftOffset - 2, topOffset - 2, GRID_COLS * CELL_SIZE + 4, GRID_ROWS * CELL_SIZE + 4)
        gfx.drawRect(leftOffset - 5, topOffset - 5, GRID_COLS * CELL_SIZE + 10, GRID_ROWS * CELL_SIZE + 10)
        
        -- Draw Title Snake
        for i, seg in ipairs(titleSnake) do
            local cx, cy = getCellCenter(seg.x, seg.y)
            local r = math.max(3, 7 - (i / #titleSnake) * 4)
            gfx.fillCircleAtPoint(cx, cy, r)
        end
        
        -- Title Text Layout
        local titleY = 65
        gfx.fillRect(60, titleY, 280, 52)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRoundRect(63, titleY + 3, 274, 46, 4)
        gfx.drawTextAligned("**S N A K E**", 200, titleY + 12, kTextAlignment.center)
        
        gfx.setColor(gfx.kColorBlack)
        gfx.drawTextAligned("Press (A) to Start Game", 200, 135, kTextAlignment.center)
        gfx.drawTextAligned("D-Pad: Move  |  Crank: Relative Turn", 200, 160, kTextAlignment.center)
        
        if highScore > 0 then
            gfx.drawTextAligned("BEST SCORE: " .. highScore, 200, 195, kTextAlignment.center)
            gfx.drawTextAligned("Press (B) to Clear Best Score", 200, 212, kTextAlignment.center)
        end
        
        -- Button Press Events
        if playdate.buttonJustPressed(playdate.kButtonA) then
            sfxSynth:playNote("E5", 0.06, 0.4)
            initGame()
            gameState = STATE_PLAYING
            playMusic()
        elseif playdate.buttonJustPressed(playdate.kButtonB) and highScore > 0 then
            playDeathSFX()
            highScore = 0
            playdate.datastore.write({ highScore = 0 })
        end
        
    elseif gameState == STATE_PLAYING then
        
        -- 1. INPUT HANDLING
        -- D-pad controls (absolute directions, overrides opposite movements)
        if playdate.buttonJustPressed(playdate.kButtonUp) and dy == 0 then
            nextDx, nextDy = 0, -1
        elseif playdate.buttonJustPressed(playdate.kButtonDown) and dy == 0 then
            nextDx, nextDy = 0, 1
        elseif playdate.buttonJustPressed(playdate.kButtonLeft) and dx == 0 then
            nextDx, nextDy = -1, 0
        elseif playdate.buttonJustPressed(playdate.kButtonRight) and dx == 0 then
            nextDx, nextDy = 1, 0
        end
        
        -- Crank controls (relative steering)
        local crankChange = playdate.getCrankChange()
        if crankChange ~= 0 then
            crankAccumulator = crankAccumulator + crankChange
            
            if crankAccumulator >= 75 then
                -- Turn Right
                playCrankSFX()
                if dx == 1 then nextDx, nextDy = 0, 1
                elseif dx == -1 then nextDx, nextDy = 0, -1
                elseif dy == 1 then nextDx, nextDy = -1, 0
                elseif dy == -1 then nextDx, nextDy = 1, 0
                end
                crankAccumulator = crankAccumulator - 75
            elseif crankAccumulator <= -75 then
                -- Turn Left
                playCrankSFX()
                if dx == 1 then nextDx, nextDy = 0, -1
                elseif dx == -1 then nextDx, nextDy = 0, 1
                elseif dy == 1 then nextDx, nextDy = 1, 0
                elseif dy == -1 then nextDx, nextDy = -1, 0
                end
                crankAccumulator = crankAccumulator + 75
            end
        end
        
        -- 2. UPDATE GAMESTATE (based on timer frames)
        frameCounter = frameCounter + 1
        if frameCounter >= updateInterval then
            frameCounter = 0
            
            -- Apply direction change
            dx, dy = nextDx, nextDy
            
            -- Move Head
            local nextHeadX = snake[1].x + dx
            local nextHeadY = snake[1].y + dy
            
            -- Collision Check: Wall
            if nextHeadX < 1 or nextHeadX > GRID_COLS or nextHeadY < 1 or nextHeadY > GRID_ROWS then
                playDeathSFX()
                stopMusic()
                gameState = STATE_GAMEOVER
                if score > highScore then
                    highScore = score
                    playdate.datastore.write({ highScore = highScore })
                    isNewHighScore = true
                end
            else
                -- Collision Check: Self
                local selfCollision = false
                for i = 1, #snake do
                    if snake[i].x == nextHeadX and snake[i].y == nextHeadY then
                        selfCollision = true
                        break
                    end
                end
                
                if selfCollision then
                    playDeathSFX()
                    stopMusic()
                    gameState = STATE_GAMEOVER
                    if score > highScore then
                        highScore = score
                        playdate.datastore.write({ highScore = highScore })
                        isNewHighScore = true
                    end
                else
                    -- Move Ahead
                    table.insert(snake, 1, {x = nextHeadX, y = nextHeadY})
                    
                    -- Collision Check: Food
                    if nextHeadX == foodX and nextHeadY == foodY then
                        score = score + 10
                        playEatSFX()
                        spawnExplosion(foodX, foodY)
                        spawnFood()
                        
                        -- Speed increase ramp
                        updateInterval = math.max(2, 8 - math.floor(score / 60))
                        
                        -- High score check
                        if score > highScore then
                            if not wasHighScoreBeaten and highScore > 0 then
                                wasHighScoreBeaten = true
                                playHighScoreSFX()
                            end
                            highScore = score
                        end
                    else
                        table.remove(snake)
                    end
                end
            end
        end
        
        -- 3. PARTICLE PHYSICS
        for i = #particles, 1, -1 do
            local p = particles[i]
            p.x = p.x + p.vx
            p.y = p.y + p.vy
            p.life = p.life - 1
            if p.life <= 0 then
                table.remove(particles, i)
            end
        end
        
        -- 4. RENDER PLAYFIELD
        -- Dot Grid Pattern
        gfx.setColor(gfx.kColorBlack)
        for col = 1, GRID_COLS do
            for row = 1, GRID_ROWS do
                local cx, cy = getCellCenter(col, row)
                gfx.fillRect(cx, cy, 1, 1)
            end
        end
        
        -- Playfield borders (double frame)
        gfx.drawRect(leftOffset - 2, topOffset - 2, GRID_COLS * CELL_SIZE + 4, GRID_ROWS * CELL_SIZE + 4)
        gfx.drawRect(leftOffset - 5, topOffset - 5, GRID_COLS * CELL_SIZE + 10, GRID_ROWS * CELL_SIZE + 10)
        
        -- Draw Food (Pulsing apple design)
        local fx, fy = getCellCenter(foodX, foodY)
        local t = playdate.getElapsedTime()
        local pulse = 1.0 + 0.15 * math.sin(t * 12)
        local r = 6 * pulse
        gfx.fillCircleAtPoint(fx, fy, r)
        -- Apple stem and leaf
        gfx.drawLine(fx, fy - r + 1, fx + 2, fy - r - 3)
        gfx.fillRect(fx + 2, fy - r - 4, 2, 2)
        
        -- Draw Snake (Cartoon style with eyes and tapering tail)
        gfx.setLineWidth(1)
        for i = #snake, 2, -1 do
            local seg = snake[i]
            local prevSeg = snake[i-1]
            local scx, scy = getCellCenter(seg.x, seg.y)
            local pcx, pcy = getCellCenter(prevSeg.x, prevSeg.y)
            
            local radius = math.max(3, 7 - (i / #snake) * 3.5)
            gfx.fillCircleAtPoint(scx, scy, radius)
            
            -- Thick connection line
            gfx.setLineWidth(radius * 2 - 1)
            gfx.drawLine(scx, scy, pcx, pcy)
        end
        
        -- Draw Snake Head
        local hx, hy = getCellCenter(snake[1].x, snake[1].y)
        gfx.setLineWidth(1)
        gfx.fillCircleAtPoint(hx, hy, 7.5)
        
        -- Draw Head Eyes facing moving direction
        gfx.setColor(gfx.kColorWhite)
        local ex1, ey1, ex2, ey2 = 0, 0, 0, 0
        if dx == 1 then     -- Right
            ex1, ey1 = hx + 3, hy - 3
            ex2, ey2 = hx + 3, hy + 3
        elseif dx == -1 then -- Left
            ex1, ey1 = hx - 3, hy - 3
            ex2, ey2 = hx - 3, hy + 3
        elseif dy == 1 then  -- Down
            ex1, ey1 = hx - 3, hy + 3
            ex2, ey2 = hx + 3, hy + 3
        elseif dy == -1 then -- Up
            ex1, ey1 = hx - 3, hy - 3
            ex2, ey2 = hx + 3, hy - 3
        end
        gfx.fillCircleAtPoint(ex1, ey1, 2)
        gfx.fillCircleAtPoint(ex2, ey2, 2)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(ex1, ey1, 0.8)
        gfx.fillCircleAtPoint(ex2, ey2, 0.8)
        
        -- Draw Particles
        gfx.setColor(gfx.kColorBlack)
        for _, p in ipairs(particles) do
            gfx.fillRect(p.x - 1, p.y - 1, 2, 2)
        end
        
        -- 5. HUD RENDERING (Upper Area)
        gfx.fillRect(0, 0, SCREEN_W, HUD_H)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(0, HUD_H - 1, SCREEN_W, HUD_H - 1)
        
        -- Draw Score / Info
        gfx.drawText("SCORE: **" .. score .. "**", 15, 8)
        gfx.drawText("BEST: **" .. highScore .. "**", 120, 8)
        
        -- Draw Crank Info & Accumulator Widget
        if playdate.isCrankDocked() then
            gfx.drawTextAligned("UNFOLD CRANK TO STEER", 280, 8, kTextAlignment.right)
        else
            gfx.drawTextAligned("CRANK STEER", 280, 8, kTextAlignment.right)
            
            -- Crank needle meter UI
            local wx, wy = 370, 16
            gfx.drawCircleAtPoint(wx, wy, 8)
            gfx.drawCircleAtPoint(wx, wy, 1) -- center pin
            -- Tick marks at +/- 75 degrees
            local r1, r2 = 5, 8
            local tAngle1 = math.rad(75)
            local tAngle2 = math.rad(-75)
            gfx.drawLine(wx + r1*math.sin(tAngle1), wy - r1*math.cos(tAngle1), wx + r2*math.sin(tAngle1), wy - r2*math.cos(tAngle1))
            gfx.drawLine(wx + r1*math.sin(tAngle2), wy - r1*math.cos(tAngle2), wx + r2*math.sin(tAngle2), wy - r2*math.cos(tAngle2))
            
            -- Current angle needle
            local needleAngle = math.rad(crankAccumulator)
            gfx.drawLine(wx, wy, wx + 8 * math.sin(needleAngle), wy - 8 * math.cos(needleAngle))
        end
        
    elseif gameState == STATE_GAMEOVER then
        -- Static background render (frozen playfield state)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(leftOffset - 2, topOffset - 2, GRID_COLS * CELL_SIZE + 4, GRID_ROWS * CELL_SIZE + 4)
        
        -- Draw game components statically
        local fx, fy = getCellCenter(foodX, foodY)
        gfx.fillCircleAtPoint(fx, fy, 6)
        
        for i = #snake, 2, -1 do
            local scx, scy = getCellCenter(snake[i].x, snake[i].y)
            local pcx, pcy = getCellCenter(snake[i-1].x, snake[i-1].y)
            local radius = math.max(3, 7 - (i / #snake) * 3.5)
            gfx.fillCircleAtPoint(scx, scy, radius)
            gfx.setLineWidth(radius * 2 - 1)
            gfx.drawLine(scx, scy, pcx, pcy)
        end
        local hx, hy = getCellCenter(snake[1].x, snake[1].y)
        gfx.setLineWidth(1)
        gfx.fillCircleAtPoint(hx, hy, 7.5)
        
        -- HUD overlay frozen
        gfx.fillRect(0, 0, SCREEN_W, HUD_H)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(0, HUD_H - 1, SCREEN_W, HUD_H - 1)
        gfx.drawText("SCORE: **" .. score .. "**", 15, 8)
        gfx.drawText("BEST: **" .. highScore .. "**", 120, 8)
        
        -- Draw central dialog panel
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRoundRect(60, 55, 280, 150, 6)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRoundRect(62, 57, 276, 146, 5)
        
        gfx.drawTextAligned("**GAME OVER**", 200, 70, kTextAlignment.center)
        gfx.drawTextAligned("FINAL SCORE: **" .. score .. "**", 200, 95, kTextAlignment.center)
        
        if isNewHighScore then
            local t = playdate.getElapsedTime()
            if math.floor(t * 4) % 2 == 0 then
                gfx.drawTextAligned("* NEW HIGH SCORE! *", 200, 120, kTextAlignment.center)
            end
        else
            gfx.drawTextAligned("BEST SCORE: " .. highScore, 200, 120, kTextAlignment.center)
        end
        
        gfx.drawTextAligned("Press (A) to Play Again", 200, 152, kTextAlignment.center)
        gfx.drawTextAligned("Press (B) to return to Title", 200, 172, kTextAlignment.center)
        
        -- Button Handling
        if playdate.buttonJustPressed(playdate.kButtonA) then
            sfxSynth:playNote("E5", 0.06, 0.4)
            initGame()
            gameState = STATE_PLAYING
            playMusic()
        elseif playdate.buttonJustPressed(playdate.kButtonB) then
            sfxSynth:playNote("C5", 0.06, 0.4)
            gameState = STATE_TITLE
        end
    end
    
    -- Tick standard timers
    playdate.timer.updateTimers()
end
