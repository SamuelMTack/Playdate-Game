local pd <const> = playdate
local gfx <const> = pd.graphics

Board = {}
Board.__index = Board

Board.EMPTY = 0
Board.RED = 1
Board.BLACK = 2
Board.MAN = 4
Board.KING = 8

function Board.new()
    local self = setmetatable({}, Board)
    self.grid = {}
    self:setupBoard()
    self.cursor = {x = 1, y = 1}
    self.selected = nil 
    self.legalMoves = {} 
    self.turn = Board.RED -- Player starts
    self.chainPiece = nil -- Tracks piece that must continue jumping
    
    -- Ensure cursor starts on a valid dark square
    if (self.cursor.x + self.cursor.y) % 2 == 0 then self.cursor.x = 2 end
    
    -- Pre-calculate legal moves for the starting turn
    self.legalMoves = self:getLegalMoves(self.turn)
    return self
end

function Board:setupBoard()
    for y = 1, 8 do
        self.grid[y] = {}
        for x = 1, 8 do
            self.grid[y][x] = Board.EMPTY
            
            -- Dark squares: (x+y)%2 == 1
            if (x + y) % 2 == 1 then
                if y <= 3 then
                    self.grid[y][x] = Board.BLACK | Board.MAN
                elseif y >= 6 then
                    self.grid[y][x] = Board.RED | Board.MAN
                end
            end
        end
    end
end

function Board:draw()
    local tileSize = 30
    local offsetX = (400 - 240) / 2
    local offsetY = 0
    
    for y = 1, 8 do
        for x = 1, 8 do
            local rect = pd.geometry.rect.new(offsetX + (x-1)*tileSize, offsetY + (y-1)*tileSize, tileSize, tileSize)
            
            if (x + y) % 2 == 0 then
                -- Light square
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(rect)
            else
                -- Dark square
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(rect)
            end
            
            -- Highlight valid moves/selections
            if self.selected and self.selected.x == x and self.selected.y == y then
                gfx.setColor(gfx.kColorWhite)
                gfx.setLineWidth(2)
                gfx.drawRect(rect.x+1, rect.y+1, rect.width-2, rect.height-2)
            end
            
            -- Show legal destinations if piece selected
            if self.selected then
                for _, move in ipairs(self.currentLegalMovesForSelection or {}) do
                    if move.to.x == x and move.to.y == y then
                        gfx.setColor(gfx.kColorXOR)
                        gfx.fillEllipseInRect(rect.x+10, rect.y+10, 10, 10)
                    end
                end
            end
            
            local piece = self.grid[y][x]
            if piece ~= Board.EMPTY then
                local color = piece & 3
                local type = piece & 12
                
                local cx, cy = rect.x + tileSize/2, rect.y + tileSize/2
                local r = 10
                
                if color == Board.RED then
                    gfx.setColor(gfx.kColorWhite) 
                    gfx.fillEllipseInRect(cx-r, cy-r, r*2, r*2) -- White filled circle for Red
                    -- Add inner dot to distinguish from light squares?
                    -- Red pieces are usually lighter in grayscale, Black are black.
                    -- Let's make Red pieces White circle with black outline.
                    -- Black pieces Black circle with white outline.
                    gfx.setColor(gfx.kColorBlack)
                    gfx.setLineWidth(1)
                    gfx.drawEllipseInRect(cx-r, cy-r, r*2, r*2)
                else
                    gfx.setColor(gfx.kColorBlack)
                     gfx.fillEllipseInRect(cx-r, cy-r, r*2, r*2) -- Black filled
                     gfx.setColor(gfx.kColorWhite)
                     gfx.setLineWidth(1)
                    gfx.drawEllipseInRect(cx-r, cy-r, r*2, r*2)
                end
                
                if type == Board.KING then
                    -- Draw crown/star
                    gfx.setColor(color == Board.RED and gfx.kColorBlack or gfx.kColorWhite)
                    gfx.fillEllipseInRect(cx-3, cy-3, 6, 6)
                end
            end
            
            if self.cursor.x == x and self.cursor.y == y then
                gfx.setColor(gfx.kColorXOR)
                gfx.setLineWidth(3)
                gfx.drawRect(rect)
            end
        end
    end
end

function Board:moveCursor(dx, dy)
    self.cursor.x = math.max(1, math.min(8, self.cursor.x + dx))
    self.cursor.y = math.max(1, math.min(8, self.cursor.y + dy))
end

function Board:selectSquare()
    local x, y = self.cursor.x, self.cursor.y
    local piece = self.grid[y][x]
    
    if self.selected then
        -- Execute move if valid
        for _, move in ipairs(self.currentLegalMovesForSelection or {}) do
            if move.to.x == x and move.to.y == y then
                self:makeMove(move)
                return
            end
        end
        
        -- Deselect or switch selection
        if piece ~= Board.EMPTY and (piece & 3) == self.turn then
             self.selected = {x=x, y=y}
             self:updateMovesForSelection()
        else
            self.selected = nil
            self.currentLegalMovesForSelection = nil
        end
    else
        if piece ~= Board.EMPTY and (piece & 3) == self.turn then
             self.selected = {x=x, y=y}
             self:updateMovesForSelection()
        end
    end
end

function Board:updateMovesForSelection()
    self.currentLegalMovesForSelection = {}
    for _, move in ipairs(self.legalMoves) do
        if move.from.x == self.selected.x and move.from.y == self.selected.y then
            table.insert(self.currentLegalMovesForSelection, move)
        end
    end
end

function Board:getLegalMoves(playerColor)
    local moves = {}
    local jumps = {}
    
    for y = 1, 8 do
        for x = 1, 8 do
            -- If in a chain, strictly filter for the chain piece
            if self.chainPiece and (x ~= self.chainPiece.x or y ~= self.chainPiece.y) then
                -- Skip other pieces
            else
                local piece = self.grid[y][x]
                if piece ~= Board.EMPTY and (piece & 3) == playerColor then
                    local pMoves, pJumps = self:getPieceMoves(x, y, piece)
                    -- If in chain, ONLY allow jumps
                    if self.chainPiece then
                        for _, j in ipairs(pJumps) do table.insert(moves, j) end
                    else
                        for _, m in ipairs(pMoves) do table.insert(moves, m) end
                        for _, j in ipairs(pJumps) do table.insert(jumps, j) end
                    end
                end
            end
        end
    end
    
    -- Disabled Forced Jumps (User Request)
    -- Flatten jumps into moves
    for _, j in ipairs(jumps) do table.insert(moves, j) end
    print("Legal moves for player " .. playerColor .. ": " .. #moves)
    return moves
end

function Board:getPieceMoves(x, y, piece)
    local moves = {}
    local jumps = {}
    local color = piece & 3
    local type = piece & 12
    local dirs = {}
    
    if type == Board.KING then
        dirs = {{-1,-1}, {1,-1}, {-1,1}, {1,1}}
    else
        if color == Board.RED then -- Moves up (y decreasing)
            dirs = {{-1,-1}, {1,-1}}
        else -- Black moves down
            dirs = {{-1,1}, {1,1}}
        end
    end
    
    for _, d in ipairs(dirs) do
        local tx, ty = x + d[1], y + d[2]
        
        -- Normal Move
        if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
            if self.grid[ty][tx] == Board.EMPTY then
                table.insert(moves, {from={x=x, y=y}, to={x=tx, y=ty}, capture=nil})
            else
                -- Jump?
                local other = self.grid[ty][tx]
                if (other & 3) ~= color then
                    local jx, jy = tx + d[1], ty + d[2]
                    if jx >= 1 and jx <= 8 and jy >= 1 and jy <= 8 then
                        if self.grid[jy][jx] == Board.EMPTY then
                             print("Jump found for", x, y, "to", jx, jy)
                             table.insert(jumps, {from={x=x, y=y}, to={x=jx, y=jy}, capture={x=tx, y=ty}})
                        end
                    end
                end
            end
        end
    end
    
    return moves, jumps
end

function Board:makeMove(move)
    local p = self.grid[move.from.y][move.from.x]
    self.grid[move.from.y][move.from.x] = Board.EMPTY
    self.grid[move.to.y][move.to.x] = p
    
    local capture = nil
    if move.capture then
        print("Executing capture at", move.capture.x, move.capture.y)
        capture = self.grid[move.capture.y][move.capture.x]
        self.grid[move.capture.y][move.capture.x] = Board.EMPTY
    end
    
    -- Promotion
    local promoted = false
    if (p & 12) == Board.MAN then
        if (p & 3) == Board.RED and move.to.y == 1 then
            self.grid[move.to.y][move.to.x] = Board.RED | Board.KING
            promoted = true
        elseif (p & 3) == Board.BLACK and move.to.y == 8 then
            self.grid[move.to.y][move.to.x] = Board.BLACK | Board.KING
            promoted = true
        end
    end
    
    -- Switch turn or continue jump?
    local continuedJump = false
    local prevChainPiece = self.chainPiece
    
    -- Rule: Promotion ends the turn immediately
    if move.capture and not promoted then
        -- Check for chained jumps
        local _, moreJumps = self:getPieceMoves(move.to.x, move.to.y, self.grid[move.to.y][move.to.x])
        if #moreJumps > 0 then
            continuedJump = true
            self.turn = self.turn -- Turn stays
            self.selected = {x=move.to.x, y=move.to.y}
            -- Identify this piece as the chain piece
            self.chainPiece = {x=move.to.x, y=move.to.y}
            -- Note: legalMoves updated below
        else
            self.chainPiece = nil
        end
    else
        self.chainPiece = nil
    end
    
    if not continuedJump then
        self.turn = (self.turn == Board.RED) and Board.BLACK or Board.RED
        self.selected = nil
        self.currentLegalMovesForSelection = nil
    end
    
    self.legalMoves = self:getLegalMoves(self.turn) 
    
    return {
        move = move,
        capture = capture,
        promoted = promoted,
        prevTurn = (self.turn == Board.RED) and Board.BLACK or Board.RED,
        continuedJump = continuedJump,
        prevChainPiece = prevChainPiece
    }
end

function Board:undoMove(context)
    local move = context.move
    local p = self.grid[move.to.y][move.to.x]
    
    -- Undo promotion
    if context.promoted then
        p = (p & 3) | Board.MAN
    end
    
    self.grid[move.from.y][move.from.x] = p
    self.grid[move.to.y][move.to.x] = Board.EMPTY
    
    -- Undo capture
    if move.capture then
        self.grid[move.capture.y][move.capture.x] = context.capture
    end
    
    -- Switch turn back
    self.turn = context.prevTurn
    self.chainPiece = context.prevChainPiece
    
    self.selected = nil
    self.currentLegalMovesForSelection = nil
end

function Board:getPieceCount(color)
    local count = 0
    for y = 1, 8 do
        for x = 1, 8 do
            local p = self.grid[y][x]
            if p ~= Board.EMPTY and (p & 3) == color then
                count = count + 1
            end
        end
    end
    return count
end

function Board:getAllLegalMoves(color)
    return self:getLegalMoves(color)
end

return Board
