
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "Tetromino"
import "Grid"
import "SoundManager"

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Constants
local BLOCK_SIZE = 10
local GRID_ROWS = 20
local GRID_COLS = 10
local BOARD_OFFSET_X = 150
local BOARD_OFFSET_Y = 20

-- Game State
local grid
local currentPiece
local nextPiece
local score = 0
local linesClearedTotal = 0
local level = 1
local gameOver = false
local paused = false

-- Timers
local dropTimer
local dropInterval = 1000 -- ms

-- Audio
local soundManager

-- Input
local crankAccumulator = 0
local CRANK_THRESHOLD = 45 -- degrees to trigger a move

function pd.update()
    if not grid then initializeGame() end -- Lazy init to ensure classes are loaded

    if not gameOver and not paused then
        handleInput()
        gfx.clear()
        drawGame()
        pd.timer.updateTimers()
    elseif gameOver then
        gfx.clear()
        drawGame()
        drawGameOver()
        if pd.buttonJustPressed(pd.kButtonA) then
            resetGame()
        end
    end
end

function initializeGame()
    math.randomseed(pd.getSecondsSinceEpoch())
    grid = Grid(GRID_ROWS, GRID_COLS, BLOCK_SIZE)
    soundManager = SoundManager()
    soundManager:startBGM()
    
    spawnNewPiece()
    resetDropTimer()
end

function resetGame()
    grid = Grid(GRID_ROWS, GRID_COLS, BLOCK_SIZE)
    score = 0
    linesClearedTotal = 0
    level = 1
    gameOver = false
    spawnNewPiece()
    resetDropTimer()
end

function spawnNewPiece()
    local types = {"I", "O", "T", "S", "Z", "J", "L"}
    local type = types[math.random(#types)]
    currentPiece = Tetromino(type)
    
    -- Check immediate collision (Game Over condition)
    if not grid:isValidPosition(currentPiece, currentPiece.x, currentPiece.y) then
        gameOver = true
        soundManager:playGameOver()
    end
end

function resetDropTimer()
    if dropTimer then dropTimer:remove() end
    -- Speed increases with level
    local speed = math.max(100, 1000 - (level - 1) * 100)
    dropTimer = pd.timer.performAfterDelay(speed, function()
        if not movePiece(0, 1) then
             lockPiece()
        else
            resetDropTimer()
        end
    end)
end

function handleInput()
    -- Crank Input
    local change, acceleratedChange = pd.getCrankChange()
    crankAccumulator = crankAccumulator + change
    
    if crankAccumulator > CRANK_THRESHOLD then
        movePiece(1, 0)
        soundManager:playMove()
        crankAccumulator = crankAccumulator - CRANK_THRESHOLD
    elseif crankAccumulator < -CRANK_THRESHOLD then
        movePiece(-1, 0)
        soundManager:playMove()
        crankAccumulator = crankAccumulator + CRANK_THRESHOLD
    end

    -- D-Pad Input
    if pd.buttonJustPressed(pd.kButtonLeft) then
        movePiece(-1, 0)
        soundManager:playMove()
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        movePiece(1, 0)
        soundManager:playMove()
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        if not movePiece(0, 1) then
            lockPiece()
        else
            resetDropTimer()
        end
        soundManager:playMove()
    elseif pd.buttonJustPressed(pd.kButtonUp) then
        -- Hard drop
        while movePiece(0, 1) do end
        soundManager:playDrop()
        lockPiece()
    end

    -- Rotation
    if pd.buttonJustPressed(pd.kButtonA) then
        currentPiece:rotate()
        if not grid:isValidPosition(currentPiece, currentPiece.x, currentPiece.y) then
            currentPiece:unrotate() -- Wall kick simplified: just reject
        else
            soundManager:playRotate()
        end
    elseif pd.buttonJustPressed(pd.kButtonB) then
         -- Allow reverse rotation? Or maybe B is also rotate
        currentPiece:rotate() -- Simple: make both rotate for now to be friendly
         if not grid:isValidPosition(currentPiece, currentPiece.x, currentPiece.y) then
            currentPiece:unrotate()
         else
            soundManager:playRotate()
         end
    end
end

function movePiece(dx, dy)
    if grid:isValidPosition(currentPiece, currentPiece.x + dx, currentPiece.y + dy) then
        currentPiece.x = currentPiece.x + dx
        currentPiece.y = currentPiece.y + dy
        return true
    end
    return false
end

function lockPiece()
    grid:lock(currentPiece)
    soundManager:playDrop()
    
    local cleared = grid:clearLines()
    if cleared > 0 then
        updateScore(cleared)
        soundManager:playClear()
    end
    
    spawnNewPiece()
end

function updateScore(lines)
    linesClearedTotal = linesClearedTotal + lines
    
    -- Scoring (Standard Nintendo)
    local points = {40, 100, 300, 1200}
    score = score + (points[lines] * level)
    
    -- Level up every 10 lines
    level = math.floor(linesClearedTotal / 10) + 1
end

function drawGame()
    grid:draw(BOARD_OFFSET_X, BOARD_OFFSET_Y)
    
    -- Draw Phantom/Ghost piece (optional, let's skip for simplicity first)
    
    -- Draw Current Piece
    if currentPiece then
        gfx.pushContext()
        -- Need to match offsets
        local drawX = BOARD_OFFSET_X + (currentPiece.x - 1) * BLOCK_SIZE
        local drawY = BOARD_OFFSET_Y + (currentPiece.y - 1) * BLOCK_SIZE
        
        for r, row in ipairs(currentPiece.shape) do
            for c, val in ipairs(row) do
                if val ~= 0 then
                    gfx.fillRect(drawX + (c-1)*BLOCK_SIZE, drawY + (r-1)*BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
                    -- Invert color for piece to distinguish from potential black background or just use outline
                    -- Playdate is 1bit. Using fillRect (black).
                    -- Let's make pieces have white inside
                    gfx.setColor(gfx.kColorWhite)
                    gfx.fillRect(drawX + (c-1)*BLOCK_SIZE + 2, drawY + (r-1)*BLOCK_SIZE + 2, BLOCK_SIZE - 4, BLOCK_SIZE - 4)
                    gfx.setColor(gfx.kColorBlack) -- Reset
                end
            end
        end
        gfx.popContext()
    end
    
    drawUI()
end

function drawUI()
    gfx.drawText("SCORE", 10, 30)
    gfx.drawText(tostring(score), 10, 50)
    
    gfx.drawText("LEVEL", 10, 80)
    gfx.drawText(tostring(level), 10, 100)
    
    gfx.drawText("LINES", 10, 130)
    gfx.drawText(tostring(linesClearedTotal), 10, 150)
end

function drawGameOver()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(50, 80, 300, 60)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(50, 80, 300, 60)
    gfx.drawText("GAME OVER", 160, 100)
    gfx.drawText("Press A to Restart", 140, 120)
end
