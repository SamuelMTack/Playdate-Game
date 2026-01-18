import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics
local pd = playdate

-- Constants
local STARTING_TOKENS = 100
local DEFAULT_BET = 5
local SYMBOL_SIZE = 50 -- Slightly larger for shapes
local GRID_X = 40
local GRID_Y = 50
local CELL_PADDING = 10

-- Symbols
-- 1: Cherry, 2: Bell, 3: Clover, 4: 7, 5: Bar, 6: Diamond
local SYMBOLS = {
    CHERRY = 1,
    BELL = 2,
    CLOVER = 3,
    SEVEN = 4,
    BAR = 5,
    DIAMOND = 6
}
local NUM_SYMBOLS = 6

-- Paylines: 3 Horizontal, 2 Diagonal
-- Each line is list of {col, row} coordinates (1-based)
-- But wait, my grid is 3x3. I can just index cleanly.
--  (1,1) (2,1) (3,1)
--  (1,2) (2,2) (3,2)
--  (1,3) (2,3) (3,3)

-- Game State
local STATE = {
    TITLE = 0,
    IDLE = 1,
    SPINNING = 2,
    RESULT = 3,
    GAMEOVER = 4
}
local currentState = STATE.TITLE

-- Variables
local tokens = STARTING_TOKENS
local currentBet = DEFAULT_BET
-- Grid: 3 columns, 3 rows. Access as grid[col][row]
local grid = {{1, 1, 1}, {1, 1, 1}, {1, 1, 1}} 
local spinTimer = nil
local winAmount = 0
local message = ""

-- Graphics setup
gfx.setBackgroundColor(gfx.kColorWhite)

function init()
    math.randomseed(pd.getSecondsSinceEpoch())
end

function resetGame()
    tokens = STARTING_TOKENS
    currentBet = DEFAULT_BET
    resetGrid()
    winAmount = 0
    message = ""
    currentState = STATE.TITLE
end

function resetGrid()
    for col=1, 3 do
        for row=1, 3 do
            grid[col][row] = math.random(1, NUM_SYMBOLS)
        end
    end
end

function spinReels()
    for col=1, 3 do
        for row=1, 3 do
            grid[col][row] = math.random(1, NUM_SYMBOLS)
        end
    end
end

function getSymbolMultiplier(symbolType)
    if symbolType == SYMBOLS.SEVEN then return 50 end
    if symbolType == SYMBOLS.DIAMOND then return 25 end
    if symbolType == SYMBOLS.BAR then return 15 end
    if symbolType == SYMBOLS.BELL then return 10 end
    if symbolType == SYMBOLS.CLOVER then return 5 end
    if symbolType == SYMBOLS.CHERRY then return 3 end
    return 0
end

function checkWin()
    local totalWin = 0
    
    -- Helper to check a line of 3 symbols
    local function checkLine(s1, s2, s3)
        if s1 == s2 and s2 == s3 then
            return currentBet * getSymbolMultiplier(s1)
        end
        return 0
    end
    
    -- Rows (Horizontal)
    for row=1, 3 do
        totalWin = totalWin + checkLine(grid[1][row], grid[2][row], grid[3][row])
    end
    
    -- Diagonals
    totalWin = totalWin + checkLine(grid[1][1], grid[2][2], grid[3][3])
    totalWin = totalWin + checkLine(grid[1][3], grid[2][2], grid[3][1])
    
    return totalWin
end

----------- GRAPHICS -----------

function drawSymbol(x, y, type)
    gfx.pushContext()
    gfx.setLineWidth(2)
    local cx, cy = x + SYMBOL_SIZE/2, y + SYMBOL_SIZE/2
    local s = SYMBOL_SIZE / 2 - 4 -- Scale factor/radius constraint
    
    if type == SYMBOLS.CHERRY then
        -- Two circles with stems
        gfx.fillCircleAtPoint(cx - 8, cy + 5, 6)
        gfx.fillCircleAtPoint(cx + 8, cy + 5, 6)
        gfx.drawLine(cx - 8, cy + 5, cx, cy - 10)
        gfx.drawLine(cx + 8, cy + 5, cx, cy - 10)
        
    elseif type == SYMBOLS.BELL then
        -- Simplistic bell shape (triangle with rounded bottom?)
        -- Or just outline
        gfx.drawArc(cx, cy+5, 12, 180, 0) -- Bottom curve
        gfx.drawLine(cx-12, cy+5, cx, cy-15)
        gfx.drawLine(cx+12, cy+5, cx, cy-15)
        gfx.fillCircleAtPoint(cx, cy+5, 3) -- Clapper
        
    elseif type == SYMBOLS.CLOVER then
        -- 3 Circles and a stem
        gfx.drawCircleAtPoint(cx, cy-8, 6) -- Top
        gfx.drawCircleAtPoint(cx-7, cy+2, 6) -- Left
        gfx.drawCircleAtPoint(cx+7, cy+2, 6) -- Right
        gfx.drawLine(cx, cy, cx, cy+15) -- Stem
        
    elseif type == SYMBOLS.SEVEN then
        -- Number 7
        local p = {
            cx-10, cy-15,
            cx+15, cy-15,
            cx-5, cy+15
        }
        gfx.drawLine(cx-10, cy-15, cx+15, cy-15)
        gfx.drawLine(cx+15, cy-15, cx-5, cy+15)
        
    elseif type == SYMBOLS.BAR then
        -- Rectangle with text "BAR"
        gfx.drawRect(cx-20, cy-10, 40, 20)
        gfx.drawTextAligned("BAR", cx, cy-6, kTextAlignment.center)
        
    elseif type == SYMBOLS.DIAMOND then
        -- Rhombus
        gfx.drawPolygon(
            cx, cy-15,
            cx+12, cy,
            cx, cy+15,
            cx-12, cy
        )
    end
    
    gfx.popContext()
end

function updateTitle()
    gfx.drawTextAligned("*SLOT MACHINE*", 200, 80, kTextAlignment.center)
    gfx.drawTextAligned("3x3 Edition", 200, 105, kTextAlignment.center)
    gfx.drawTextAligned("Press A to Start", 200, 150, kTextAlignment.center)
    
    if pd.buttonJustPressed(pd.kButtonA) then
        currentState = STATE.IDLE
        message = "Pull Crank or Press A!"
        resetGrid()
    end
end

function updateIdle()
    -- Controls
    local crankChange = pd.getCrankChange()
    
    if pd.buttonJustPressed(pd.kButtonA) or math.abs(crankChange) > 45 then
        if tokens >= currentBet then
            tokens = tokens - currentBet
            currentState = STATE.SPINNING
            
            -- Spin animation setup
            playdate.timer.performAfterDelay(1200, function()
                spinReels()
                winAmount = checkWin()
                if winAmount > 0 then
                    tokens = tokens + winAmount
                    message = "WIN! " .. winAmount
                else
                    message = "No Luck..."
                end
                
                currentState = STATE.RESULT
            end)
        else
            message = "Not enough tokens!"
        end
    end
    
    -- Adjust Bet (Up/Down)
    if pd.buttonJustPressed(pd.kButtonUp) then
        currentBet = math.min(tokens, currentBet + 5)
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        currentBet = math.max(5, currentBet - 5)
    end
end

function updateSpinning()
    -- Randomize reels for visual effect every frame
    if pd.getCurrentTimeMilliseconds() % 80 < 40 then
         spinReels()
    end
    message = "SPINNING..."
end

function updateResult()
    if pd.buttonJustPressed(pd.kButtonA) or math.abs(pd.getCrankChange()) > 10 then
        if tokens <= 0 then
            currentState = STATE.GAMEOVER
        else
            currentState = STATE.IDLE
            message = "Spin Again?"
        end
    end
end

function updateGameOver()
    gfx.drawTextAligned("GAME OVER", 200, 100, kTextAlignment.center)
    gfx.drawTextAligned("Press A to Restart", 200, 140, kTextAlignment.center)
    
    if pd.buttonJustPressed(pd.kButtonA) then
        resetGame()
    end
end

function drawUI()
    -- Draw 3x3 Grid
    -- 3 Columns x 3 Rows
    local startX = 100
    local startY = 40
    local cellW = 60
    local cellH = 60
    
    gfx.drawRect(startX - 5, startY - 5, cellW*3 + 10, cellH*3 + 10) -- Outer Border
    
    for col=1, 3 do
        for row=1, 3 do
            local x = startX + (col-1)*cellW
            local y = startY + (row-1)*cellH
            
            gfx.drawRect(x, y, cellW, cellH) -- Cell border
            
            local type = grid[col][row]
            drawSymbol(x + (cellW-SYMBOL_SIZE)/2, y + (cellH-SYMBOL_SIZE)/2, type)
        end
    end
    
    -- Stats
    gfx.drawText("Tokens: " .. tokens, 300, 200)
    gfx.drawText("Bet: " .. currentBet, 300, 220)
    gfx.drawTextAligned(message, 200, 15, kTextAlignment.center)
end

function pd.update()
    gfx.clear()
    playdate.timer.updateTimers()
    
    if currentState == STATE.TITLE then
        updateTitle()
    elseif currentState == STATE.GAMEOVER then
        updateGameOver()
    else
        drawUI()
        
        if currentState == STATE.IDLE then
            updateIdle()
        elseif currentState == STATE.SPINNING then
            updateSpinning()
        elseif currentState == STATE.RESULT then
            updateResult()
        end
    end
end

init()
