import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics
local pd = playdate

-- --- CONSTANTS ---
local GRID_SIZE = 4
local TILE_SIZE = 50
local TILE_MARGIN = 5
local BOARD_OFFSET_X = 90
local BOARD_OFFSET_Y = 10

-- Colors / Styles
local FONT = gfx.font.kVariantBold

-- Game State
local grid = {} -- 1D array, 1-16
local score = 0
local state = "PLAYING" -- "PLAYING", "GAMEOVER", "WIN" (opt)

-- --- HELPER FUNCTIONS ---

function initGame()
    grid = {}
    for i=1, GRID_SIZE*GRID_SIZE do
        grid[i] = 0
    end
    score = 0
    state = "PLAYING"
    
    spawnTile()
    spawnTile()
end

function spawnTile()
    local empty = {}
    for i=1, #grid do
        if grid[i] == 0 then table.insert(empty, i) end
    end
    
    if #empty > 0 then
        local idx = empty[math.random(#empty)]
        -- 90% chance of 2, 10% chance of 4
        grid[idx] = (math.random() < 0.9) and 2 or 4
    end
end

-- Index Mapping: (row, col) 1-based -> index 1-16
function getIndex(r, c)
    return (r-1) * GRID_SIZE + c
end

-- --- CORE LOGIC ---

-- Slide and merge a single row/column (array of 4)
function processLine(line)
    local moved = false
    local scoreAdd = 0
    
    -- 1. Compress (remove zeros)
    local compressed = {}
    for _, v in ipairs(line) do
        if v ~= 0 then table.insert(compressed, v) end
    end
    
    -- 2. Merge
    local merged = {}
    local skip = false
    for i=1, #compressed do
        if skip then
            skip = false
        else
            if i < #compressed and compressed[i] == compressed[i+1] then
                local newVal = compressed[i] * 2
                table.insert(merged, newVal)
                scoreAdd = scoreAdd + newVal
                skip = true
                moved = true -- Technically a merge counts as a move type event
            else
                table.insert(merged, compressed[i])
            end
        end
    end
    
    -- 3. Pad with zeros
    while #merged < GRID_SIZE do
        table.insert(merged, 0)
    end
    
    -- Check if actually changed from original line
    for i=1, GRID_SIZE do
        if line[i] ~= merged[i] then moved = true end
    end
    
    return merged, moved, scoreAdd
end

function move(dir)
    if state ~= "PLAYING" then return end
    
    local lines = {}
    local anyMoved = false
    
    -- Extract lines based on direction
    if dir == "LEFT" or dir == "RIGHT" then
        for r=1, GRID_SIZE do
            local line = {}
            for c=1, GRID_SIZE do table.insert(line, grid[getIndex(r,c)]) end
            if dir == "RIGHT" then 
                -- Reverse for processing
                local rev = {}
                for i=#line, 1, -1 do table.insert(rev, line[i]) end
                line = rev
            end
            
            local newLine, moved, sAdd = processLine(line)
            if moved then anyMoved = true end
            score = score + sAdd
            
            if dir == "RIGHT" then
                 -- Reverse back
                local rev = {}
                for i=#newLine, 1, -1 do table.insert(rev, newLine[i]) end
                newLine = rev
            end
            
            -- Write back to grid
            for c=1, GRID_SIZE do grid[getIndex(r,c)] = newLine[c] end
        end
    elseif dir == "UP" or dir == "DOWN" then
        for c=1, GRID_SIZE do
            local line = {}
            for r=1, GRID_SIZE do table.insert(line, grid[getIndex(r,c)]) end
            if dir == "DOWN" then
                local rev = {}
                for i=#line, 1, -1 do table.insert(rev, line[i]) end
                line = rev
            end
            
            local newLine, moved, sAdd = processLine(line)
            if moved then anyMoved = true end
            score = score + sAdd
            
            if dir == "DOWN" then
                 local rev = {}
                for i=#newLine, 1, -1 do table.insert(rev, newLine[i]) end
                newLine = rev
            end
            
            for r=1, GRID_SIZE do grid[getIndex(r,c)] = newLine[r] end
        end
    end
    
    if anyMoved then
        spawnTile()
        checkGameOver()
    end
end

function checkGameOver()
    -- 1. Any empty spots?
    for i=1, #grid do
        if grid[i] == 0 then return end
    end
    
    -- 2. Any possible merges?
    for r=1, GRID_SIZE do
        for c=1, GRID_SIZE do
            local val = grid[getIndex(r,c)]
            -- Check Right
            if c < GRID_SIZE then
                if grid[getIndex(r,c+1)] == val then return end
            end
            -- Check Down
            if r < GRID_SIZE then
                if grid[getIndex(r+1,c)] == val then return end
            end
        end
    end
    
    state = "GAMEOVER"
end

-- --- RENDERING ---

function drawTile(r, c, val)
    local x = BOARD_OFFSET_X + (c-1) * (TILE_SIZE + TILE_MARGIN)
    local y = BOARD_OFFSET_Y + (r-1) * (TILE_SIZE + TILE_MARGIN)
    
    gfx.drawRoundRect(x, y, TILE_SIZE, TILE_SIZE, 5)
    
    if val > 0 then
        -- Aesthetics
        -- Invert colors for simple contrast logic
        -- Maybe outline thickness based on value?
        
        gfx.pushContext()
            -- Fill for contrast
            gfx.fillRoundRect(x, y, TILE_SIZE, TILE_SIZE, 5)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            
            local text = tostring(val)
            local w, h = gfx.getTextSize(text)
            gfx.drawText(text, x + (TILE_SIZE-w)/2, y + (TILE_SIZE-h)/2)
        gfx.popContext()
    end
end

function drawBoard()
    for r=1, GRID_SIZE do
        for c=1, GRID_SIZE do
            drawTile(r, c, grid[getIndex(r,c)])
        end
    end
end

function drawUI()
    -- Side panel
    gfx.drawText("SCORE", 10, 20)
    gfx.drawText(tostring(score), 10, 45)
    
    gfx.drawText("2048", 10, 150)
    
    if state == "GAMEOVER" then
        -- White box with black border
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(50, 80, 300, 80)
        
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(50, 80, 300, 80)
        gfx.setLineWidth(2)
        gfx.drawRect(52, 82, 296, 76) -- Inner border
        gfx.setLineWidth(1)
        
        gfx.drawTextAligned("GAME OVER", 200, 100, kTextAlignment.center)
        gfx.drawTextAligned("Press A to Restart", 200, 130, kTextAlignment.center)
    end
end

-- --- MAIN LOOP ---

initGame()
math.randomseed(pd.getSecondsSinceEpoch())

function pd.update()
    gfx.clear()
    
    -- Input
    if state == "PLAYING" then
        if pd.buttonJustPressed(pd.kButtonLeft) then move("LEFT") end
        if pd.buttonJustPressed(pd.kButtonRight) then move("RIGHT") end
        if pd.buttonJustPressed(pd.kButtonUp) then move("UP") end
        if pd.buttonJustPressed(pd.kButtonDown) then move("DOWN") end
    elseif state == "GAMEOVER" then
        if pd.buttonJustPressed(pd.kButtonA) then
            initGame()
        end
    end
    
    drawBoard()
    drawUI()
end
