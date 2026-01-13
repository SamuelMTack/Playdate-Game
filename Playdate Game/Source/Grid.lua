
local pd <const> = playdate
local gfx <const> = pd.graphics

class('Grid').extends()

function Grid:init(rows, cols, cellSize)
    self.rows = rows or 20
    self.cols = cols or 10
    self.cellSize = cellSize or 20
    self.cells = {} -- 2D array: cells[y][x] = 0 (empty) or 1 (filled)

    -- Initialize empty grid
    for y = 1, self.rows do
        self.cells[y] = {}
        for x = 1, self.cols do
            self.cells[y][x] = 0
        end
    end
end

-- Check if a tetromino at (tx, ty) violates boundaries or overlaps existing blocks
function Grid:isValidPosition(tetromino, tx, ty)
    for r, row in ipairs(tetromino.shape) do
        for c, val in ipairs(row) do
            if val ~= 0 then
                local boardX = tx + c - 1
                local boardY = ty + r - 1

                -- Boundary checks
                if boardX < 1 or boardX > self.cols or boardY > self.rows then
                    return false
                end
                
                -- Overlap check (only if inside board vertically)
                if boardY >= 1 then
                    if self.cells[boardY][boardX] ~= 0 then
                        return false
                    end
                end
            end
        end
    end
    return true
end

-- Lock piece into the grid
function Grid:lock(tetromino)
    for r, row in ipairs(tetromino.shape) do
        for c, val in ipairs(row) do
            if val ~= 0 then
                local boardX = tetromino.x + c - 1
                local boardY = tetromino.y + r - 1
                if boardY >= 1 and boardY <= self.rows and boardX >= 1 and boardX <= self.cols then
                    self.cells[boardY][boardX] = 1
                end
            end
        end
    end
end

-- Clear full lines and return count
function Grid:clearLines()
    local linesCleared = 0
    local y = self.rows
    while y >= 1 do
        local full = true
        for x = 1, self.cols do
            if self.cells[y][x] == 0 then
                full = false
                break
            end
        end

        if full then
            linesCleared = linesCleared + 1
            -- Shift everything down
            for k = y, 2, -1 do
                self.cells[k] = self:_copyRow(self.cells[k-1])
            end
            -- Clear top row
            for x = 1, self.cols do
                self.cells[1][x] = 0
            end
            -- Don't decrement y, check this row index again (since it's now a new row)
        else
            y = y - 1
        end
    end
    return linesCleared
end

function Grid:_copyRow(row)
    local newRow = {}
    for i, v in ipairs(row) do
        newRow[i] = v
    end
    return newRow
end

function Grid:draw(offsetX, offsetY)
    gfx.pushContext()
    gfx.setLineWidth(1)
    
    -- Draw Border
    local width = self.cols * self.cellSize
    local height = self.rows * self.cellSize
    gfx.drawRect(offsetX, offsetY, width, height)

    -- Draw Blocks
    for y = 1, self.rows do
        for x = 1, self.cols do
            if self.cells[y][x] ~= 0 then
                local drawX = offsetX + (x - 1) * self.cellSize
                local drawY = offsetY + (y - 1) * self.cellSize
                -- Simple filled rect for now, can be improved with sprites
                gfx.fillRect(drawX, drawY, self.cellSize, self.cellSize)
                gfx.drawRect(drawX, drawY, self.cellSize, self.cellSize) -- outline
            end
        end
    end
    gfx.popContext()
end
