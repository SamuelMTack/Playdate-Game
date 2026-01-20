import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics
local pd = playdate

-- --- CONFIG ---
local GRID_W = 15
local GRID_H = 10
local CELL_SIZE = 24
local OFFSET_X = 20
local OFFSET_Y = 0
local MINE_COUNT = 20

-- --- STATE ---
local grid = {} -- { isMine=bool, isRevealed=bool, isFlagged=bool, neighbors=int }
local cursorX = 1
local cursorY = 1
local gameState = "PLAYING" -- PLAYING, WON, LOST
local firstClick = true

function initGrid()
    grid = {}
    for y=1, GRID_H do
        grid[y] = {}
        for x=1, GRID_W do
            grid[y][x] = {
                isMine = false,
                isRevealed = false,
                isFlagged = false,
                neighbors = 0
            }
        end
    end
    gameState = "PLAYING"
    firstClick = true
    cursorX = math.floor(GRID_W/2)
    cursorY = math.floor(GRID_H/2)
end

function placeMines(safeX, safeY)
    local minesPlaced = 0
    math.randomseed(pd.getSecondsSinceEpoch())
    
    while minesPlaced < MINE_COUNT do
        local x = math.random(1, GRID_W)
        local y = math.random(1, GRID_H)
        
        -- Don't place on existing mine
        -- Don't place on first click spot OR neighbors (safe zone)
        local isSafeZone = (math.abs(x - safeX) <= 1 and math.abs(y - safeY) <= 1)
        
        if not grid[y][x].isMine and not isSafeZone then
            grid[y][x].isMine = true
            minesPlaced = minesPlaced + 1
        end
    end
    
    calcNeighbors()
end

function calcNeighbors()
    for y=1, GRID_H do
        for x=1, GRID_W do
            if not grid[y][x].isMine then
                local count = 0
                for dy=-1, 1 do
                    for dx=-1, 1 do
                        local ny = y + dy
                        local nx = x + dx
                        if ny >= 1 and ny <= GRID_H and nx >= 1 and nx <= GRID_W then
                            if grid[ny][nx].isMine then count = count + 1 end
                        end
                    end
                end
                grid[y][x].neighbors = count
            end
        end
    end
end

function reveal(x, y)
    if x < 1 or x > GRID_W or y < 1 or y > GRID_H then return end
    local cell = grid[y][x]
    
    if cell.isRevealed or cell.isFlagged then return end
    
    cell.isRevealed = true
    
    if cell.isMine then
        gameState = "LOST"
        revealAll()
    else
        if cell.neighbors == 0 then
            -- Flood fill
            for dy=-1, 1 do
                for dx=-1, 1 do
                    if not (dx == 0 and dy == 0) then
                        reveal(x+dx, y+dy)
                    end
                end
            end
        end
        checkWin()
    end
end

function revealAll()
    for y=1, GRID_H do
        for x=1, GRID_W do
            grid[y][x].isRevealed = true
        end
    end
end

function checkWin()
    if gameState == "LOST" then return end
    
    local hiddenNonMines = 0
    for y=1, GRID_H do
        for x=1, GRID_W do
            local cell = grid[y][x]
            if not cell.isMine and not cell.isRevealed then
                hiddenNonMines = hiddenNonMines + 1
            end
        end
    end
    
    if hiddenNonMines == 0 then
        gameState = "WON"
    end
end

function toggleFlag()
    if gameState ~= "PLAYING" then return end
    local cell = grid[cursorY][cursorX]
    if not cell.isRevealed then
        cell.isFlagged = not cell.isFlagged
    end
end

function handleInput()
    if gameState == "PLAYING" then
        if pd.buttonJustPressed(pd.kButtonUp) then cursorY = math.max(1, cursorY - 1) end
        if pd.buttonJustPressed(pd.kButtonDown) then cursorY = math.min(GRID_H, cursorY + 1) end
        if pd.buttonJustPressed(pd.kButtonLeft) then cursorX = math.max(1, cursorX - 1) end
        if pd.buttonJustPressed(pd.kButtonRight) then cursorX = math.min(GRID_W, cursorX + 1) end
        
        if pd.buttonJustPressed(pd.kButtonA) then
            if firstClick then
                placeMines(cursorX, cursorY)
                firstClick = false
            end
            reveal(cursorX, cursorY)
        end
        
        if pd.buttonJustPressed(pd.kButtonB) then
            toggleFlag()
        end
    else
        -- Restart
        if pd.buttonJustPressed(pd.kButtonA) then
            initGrid()
        end
    end
end

function draw()
    gfx.clear()
    
    -- Draw Grid
    for y=1, GRID_H do
        for x=1, GRID_W do
            local px = OFFSET_X + (x-1)*CELL_SIZE
            local py = OFFSET_Y + (y-1)*CELL_SIZE
            local cell = grid[y][x]
            
            -- Border
            gfx.drawRect(px, py, CELL_SIZE, CELL_SIZE)
            
            if cell.isRevealed then
                if cell.isMine then
                    gfx.fillCircleAtPoint(px + CELL_SIZE/2, py + CELL_SIZE/2, 8) -- Mine
                else
                    gfx.setColor(gfx.kColorWhite)
                    gfx.fillRect(px+1, py+1, CELL_SIZE-2, CELL_SIZE-2) -- White bg
                    gfx.setColor(gfx.kColorBlack)
                    
                    if cell.neighbors > 0 then
                         gfx.drawTextAligned(tostring(cell.neighbors), px + CELL_SIZE/2, py + 4, kTextAlignment.center)
                    end
                end
            else
                -- Hidden: Gray Pattern
                gfx.setPattern({0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55}) -- 50% Gray
                gfx.fillRect(px+1, py+1, CELL_SIZE-2, CELL_SIZE-2)
                gfx.setColor(gfx.kColorBlack) -- Reset
                
                if cell.isFlagged then
                     -- Draw Flag with white background circle for visibility
                     gfx.setColor(gfx.kColorWhite)
                     gfx.fillCircleAtPoint(px + CELL_SIZE/2, py + CELL_SIZE/2, 8)
                     gfx.setColor(gfx.kColorBlack)
                     gfx.drawTextAligned("F", px + CELL_SIZE/2, py+4, kTextAlignment.center)
                end
            end
        end
    end
    
    -- Cursor
    local cx = OFFSET_X + (cursorX-1)*CELL_SIZE
    local cy = OFFSET_Y + (cursorY-1)*CELL_SIZE
    gfx.setLineWidth(3)
    gfx.drawRect(cx, cy, CELL_SIZE, CELL_SIZE)
    gfx.setLineWidth(1)
    
    -- UI
    if gameState == "WON" or gameState == "LOST" then
        -- Black Background Box
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(50, 80, 300, 80)
        
        -- White Text
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        if gameState == "WON" then
            gfx.drawTextAligned("YOU WIN!", 200, 100, kTextAlignment.center)
            gfx.drawTextAligned("Press A to Restart", 200, 130, kTextAlignment.center)
        else
            gfx.drawTextAligned("BOOM!", 200, 100, kTextAlignment.center)
            gfx.drawTextAligned("Restart: A", 200, 130, kTextAlignment.center)
        end
        gfx.setImageDrawMode(gfx.kDrawModeCopy) -- Reset
    end
end

initGrid()

function pd.update()
    handleInput()
    draw()
end
