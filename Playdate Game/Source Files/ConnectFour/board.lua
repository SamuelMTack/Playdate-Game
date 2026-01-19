local gfx = playdate.graphics

class('Board').extends(gfx.sprite)

function Board:init()
    self.cols = 7
    self.rows = 6
    self.cellSize = 32
    self.grid = {} 
    
    -- Initialize Grid (0=Empty, 1=P1, 2=P2)
    for c = 1, self.cols do
        self.grid[c] = {}
        for r = 1, self.rows do
            self.grid[c][r] = 0
        end
    end
    
    local width = self.cols * self.cellSize
    local height = self.rows * self.cellSize
    
    local img = gfx.image.new(width + 4, height + 4)
    self:setImage(img)
    self:moveTo(200, 140) -- Center roughly
    self:add()
    
    self:redraw()
end

function Board:redraw()
    local img = self:getImage()
    gfx.pushContext(img)
        gfx.clear(gfx.kColorWhite) -- Clear transparent/white
        
        -- Draw Blue Structure
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, img.width, img.height)
        
        -- Draw Holes/Pieces
        for c = 1, self.cols do
            for r = 1, self.rows do
                local x = (c-1) * self.cellSize + 2
                local y = (self.rows - r) * self.cellSize + 2 -- Draw upside down (row 1 is bottom)
                -- Actually let's map grid[1] as bottom row.
                
                local val = self.grid[c][r]
                
                -- Draw Empty Slot (White) or Piece
                if val == 0 then
                    gfx.setColor(gfx.kColorWhite)
                    gfx.fillCircleAtPoint(x + 16, y + 16, 12)
                elseif val == 1 then
                    gfx.setColor(gfx.kColorWhite)
                    gfx.fillCircleAtPoint(x + 16, y + 16, 12)
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillCircleAtPoint(x + 16, y + 16, 8) -- P1: Dot
                elseif val == 2 then
                    gfx.setColor(gfx.kColorWhite)
                    gfx.fillCircleAtPoint(x + 16, y + 16, 12)
                    gfx.setColor(gfx.kColorBlack)
                    gfx.setLineWidth(4)
                    gfx.drawCircleAtPoint(x + 16, y + 16, 8) -- P2: Ring
                end
            end
        end
    gfx.popContext()
end

function Board:dropPiece(col, player)
    if col < 1 or col > self.cols then return false end
    
    for r = 1, self.rows do
        if self.grid[col][r] == 0 then
            self.grid[col][r] = player
            self:redraw()
            return true, r -- Return success and row index
        end
    end
    return false -- Column full
end

function Board:getValidMoves()
    local moves = {}
    for c = 1, self.cols do
        if self.grid[c][self.rows] == 0 then
            table.insert(moves, c)
        end
    end
    return moves
end

function Board:checkWin(player)
    -- Horizontal
    for r = 1, self.rows do
        for c = 1, self.cols - 3 do
            if self.grid[c][r] == player and
               self.grid[c+1][r] == player and
               self.grid[c+2][r] == player and
               self.grid[c+3][r] == player then
                return true
            end
        end
    end
    
    -- Vertical
    for c = 1, self.cols do
        for r = 1, self.rows - 3 do
            if self.grid[c][r] == player and
               self.grid[c][r+1] == player and
               self.grid[c][r+2] == player and
               self.grid[c][r+3] == player then
                return true
            end
        end
    end
    
    -- Diagonal /
    for c = 1, self.cols - 3 do
        for r = 1, self.rows - 3 do
            if self.grid[c][r] == player and
               self.grid[c+1][r+1] == player and
               self.grid[c+2][r+2] == player and
               self.grid[c+3][r+3] == player then
                return true
            end
        end
    end
    
    -- Diagonal \
    for c = 1, self.cols - 3 do
        for r = 4, self.rows do
            if self.grid[c][r] == player and
               self.grid[c+1][r-1] == player and
               self.grid[c+2][r-2] == player and
               self.grid[c+3][r-3] == player then
                return true
            end
        end
    end
    
    return false
end

function Board:copy()
    local b = Board()
    for c=1, self.cols do
        for r=1, self.rows do
            b.grid[c][r] = self.grid[c][r]
        end
    end
    -- We don't add(b) to display list to keep it invisible/sim only
    b:remove() 
    return b
end

function Board:undoMove(col)
     for r = self.rows, 1, -1 do
         if self.grid[col][r] ~= 0 then
             self.grid[col][r] = 0
             return
         end
     end
end
