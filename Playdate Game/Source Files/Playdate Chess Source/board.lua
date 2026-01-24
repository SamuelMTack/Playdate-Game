local pd <const> = playdate
local gfx <const> = pd.graphics

Board = {}
Board.__index = Board

-- Piece definitions
Board.EMPTY = 0
Board.WHITE = 8
Board.BLACK = 16
Board.PAWN = 1
Board.KNIGHT = 2
Board.BISHOP = 3
Board.ROOK = 4
Board.QUEEN = 5
Board.KING = 6

function Board.new()
    local self = setmetatable({}, Board)
    self.grid = {}
    self:setupBoard()
    -- Load sprite sheet (assuming 32x32 tiles, 12 frames total)
    -- We might need to adjust sprite width/height based on actual image
    -- For now, let's try to load it as an imagetable if naming convention was used, 
    -- but since we just have pieces.png, we load as image and will split manually or use draw logic
    self.piecesImage = nil
    self.cursor = {x = 4, y = 4}
    self.selected = nil -- {x, y}
    self.legalMoves = {} -- List of {x, y}
    return self
end

function Board:setupBoard()
    for y = 1, 8 do
        self.grid[y] = {}
        for x = 1, 8 do
            self.grid[y][x] = Board.EMPTY
        end
    end

    -- Setup Pawns
    for x = 1, 8 do
        self.grid[2][x] = Board.BLACK | Board.PAWN
        self.grid[7][x] = Board.WHITE | Board.PAWN
    end

    -- Setup Pieces
    local pieces = {Board.ROOK, Board.KNIGHT, Board.BISHOP, Board.QUEEN, Board.KING, Board.BISHOP, Board.KNIGHT, Board.ROOK}
    for x = 1, 8 do
        self.grid[1][x] = Board.BLACK | pieces[x]
        self.grid[8][x] = Board.WHITE | pieces[x]
    end
    
    self.turn = Board.WHITE
end

function Board:selectSquare()
    local x, y = self.cursor.x, self.cursor.y
    local piece = self.grid[y][x]
    local color = piece & 24 -- 8 or 16
    
    if self.selected then
        -- Try to move
        local moveIdx = -1
        for i, move in ipairs(self.legalMoves) do
            if move.x == x and move.y == y then
                moveIdx = i
                break
            end
        end
        
        if moveIdx ~= -1 then
            self:makeMove(self.selected, {x=x, y=y})
            self.selected = nil
            self.legalMoves = {}
        else
            -- If clicked on own piece, change selection
            if piece ~= Board.EMPTY and color == self.turn then
                self.selected = {x = x, y = y}
                self.legalMoves = self:getLegalMoves(x, y)
            else
                -- Deselect
                self.selected = nil
                self.legalMoves = {}
            end
        end
    else
        -- Select piece
        if piece ~= Board.EMPTY and color == self.turn then
            self.selected = {x = x, y = y}
            self.legalMoves = self:getLegalMoves(x, y)
        end
    end
end

function Board:makeMove(from, to)
    local piece = self.grid[from.y][from.x]
    local captured = self.grid[to.y][to.x]
    
    self.grid[to.y][to.x] = piece
    self.grid[from.y][from.x] = Board.EMPTY
    
    -- Check for pawn promotion (auto Queen for now)
    local pType = piece & 7
    local promoted = false
    if pType == Board.PAWN then
        if to.y == 1 or to.y == 8 then
            local color = piece & 24
            self.grid[to.y][to.x] = color | Board.QUEEN
            promoted = true
        end
    end
    
    -- Switch turn
    if self.turn == Board.WHITE then
        self.turn = Board.BLACK
    else
        self.turn = Board.WHITE
    end
    
    return {captured = captured, promoted = promoted}
end

function Board:undoMove(from, to, context)
    -- Switch turn back
    if self.turn == Board.WHITE then
        self.turn = Board.BLACK
    else
        self.turn = Board.WHITE
    end

    local piece = self.grid[to.y][to.x]
    
    -- Untransform promotion
    if context.promoted then
        local color = piece & 24
        piece = color | Board.PAWN
    end
    
    self.grid[from.y][from.x] = piece
    self.grid[to.y][to.x] = context.captured
end

function Board:getAllLegalMoves(color)
    local moves = {}
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = self.grid[y][x]
            if piece ~= Board.EMPTY and (piece & 24) == color then
                local pieceMoves = self:getLegalMoves(x, y)
                for _, move in ipairs(pieceMoves) do
                    table.insert(moves, {from={x=x, y=y}, to=move})
                end
            end
        end
    end
    return moves
end



function Board:findKing(color)
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = self.grid[y][x]
            if piece ~= Board.EMPTY and (piece & 24) == color and (piece & 7) == Board.KING then
                return {x=x, y=y}
            end
        end
    end
    return nil
end

function Board:isSquareAttacked(x, y, byColor)
    -- Check for attacks from all directions for 'byColor'
    -- This effectively checks if a piece of 'byColor' *could* move to (x,y)
    -- We can reverse the thinking: if a Knight is at (x,y), could it attack a Knight?
    -- Actually simpler: Loop through all enemy pieces and see if they can move to (x,y)
    
    for py = 1, 8 do
        for px = 1, 8 do
            local piece = self.grid[py][px]
            if piece ~= Board.EMPTY and (piece & 24) == byColor then
                local pType = piece & 7
                -- Specialized checks are faster than generating all moves
                local dx = math.abs(x - px)
                local dy = math.abs(y - py)
                
                if pType == Board.PAWN then
                    local dir = (byColor == Board.WHITE) and -1 or 1
                    -- Pawn attacks diagonally
                    if dy == math.abs(dir) and dx == 1 and (py + dir == y) then
                        return true
                    end
                elseif pType == Board.KNIGHT then
                    if (dx == 1 and dy == 2) or (dx == 2 and dy == 1) then return true end
                elseif pType == Board.KING then
                    if dx <= 1 and dy <= 1 then return true end
                elseif pType == Board.ROOK or pType == Board.QUEEN then
                    if dx == 0 or dy == 0 then
                        if self:isPathClear(px, py, x, y) then return true end
                    end
                end
                
                if pType == Board.BISHOP or pType == Board.QUEEN then
                    if dx == dy then
                        if self:isPathClear(px, py, x, y) then return true end
                    end
                end
            end
        end
    end
    return false
end

function Board:isPathClear(sx, sy, ex, ey)
    local dx = ex - sx
    local dy = ey - sy
    local steps = math.max(math.abs(dx), math.abs(dy))
    local stepX = dx / steps
    local stepY = dy / steps
    
    for i = 1, steps - 1 do
        local x = sx + i * stepX
        local y = sy + i * stepY
        if self.grid[y][x] ~= Board.EMPTY then return false end
    end
    return true
end

function Board:isInCheck(color)
    local kingPos = self:findKing(color)
    if not kingPos then return false end -- Should not happen
    local opponent = (color == Board.WHITE) and Board.BLACK or Board.WHITE
    return self:isSquareAttacked(kingPos.x, kingPos.y, opponent)
end

function Board:getLegalMoves(x, y)
    local pseudoMoves = self:getPseudoLegalMoves(x, y)
    local legalMoves = {}
    local originalPiece = self.grid[y][x]
    local color = originalPiece & 24
    
    for _, move in ipairs(pseudoMoves) do
        -- Try move
        local captured = self.grid[move.y][move.x]
        self.grid[move.y][move.x] = originalPiece
        self.grid[y][x] = Board.EMPTY
        
        if not self:isInCheck(color) then
            table.insert(legalMoves, move)
        end
        
        -- Undo move
        self.grid[y][x] = originalPiece
        self.grid[move.y][move.x] = captured
    end
    
    return legalMoves
end

function Board:getPseudoLegalMoves(x, y)
    local moves = {}
    local piece = self.grid[y][x]
    local pType = piece & 7
    local color = piece & 24
    
    local function addMove(tx, ty)
        if tx < 1 or tx > 8 or ty < 1 or ty > 8 then return false end
        local target = self.grid[ty][tx]
        if target == Board.EMPTY then
            table.insert(moves, {x=tx, y=ty})
            return true
        else
            local tColor = target & 24
            if tColor ~= color then
                table.insert(moves, {x=tx, y=ty})
            end
            return false -- Blocked
        end
    end
    
    if pType == Board.PAWN then
        local dir = (color == Board.WHITE) and -1 or 1
        local startRow = (color == Board.WHITE) and 7 or 2
        
        -- Move forward
        if self.grid[y+dir] and self.grid[y+dir][x] == Board.EMPTY then
            table.insert(moves, {x=x, y=y+dir})
            -- Double move
            if y == startRow and self.grid[y+dir*2][x] == Board.EMPTY then
                -- Must check path clear for double move? Yes, grid[y+dir] checked above.
                if self.grid[y+dir][x] == Board.EMPTY then -- Check intermediate square
                    table.insert(moves, {x=x, y=y+dir*2})
                end
            end
        end
        
        -- Capture
        for _, dx in ipairs({-1, 1}) do
            local tx, ty = x + dx, y + dir
            if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
                local target = self.grid[ty][tx]
                if target ~= Board.EMPTY and (target & 24) ~= color then
                    table.insert(moves, {x=tx, y=ty})
                end
            end
        end
        
    elseif pType == Board.KNIGHT then
        local offsets = {{-1,-2}, {1,-2}, {-2,-1}, {2,-1}, {-2,1}, {2,1}, {-1,2}, {1,2}}
        for _, off in ipairs(offsets) do
            addMove(x+off[1], y+off[2])
        end
        
    elseif pType == Board.KING then
        for dy = -1, 1 do
            for dx = -1, 1 do
                if dx ~= 0 or dy ~= 0 then
                    addMove(x+dx, y+dy)
                end
            end
        end
        
    elseif pType == Board.ROOK or pType == Board.BISHOP or pType == Board.QUEEN then
        local dirs = {}
        if pType ~= Board.BISHOP then -- Rook or Queen
            table.insert(dirs, {1,0}); table.insert(dirs, {-1,0})
            table.insert(dirs, {0,1}); table.insert(dirs, {0,-1})
        end
        if pType ~= Board.ROOK then -- Bishop or Queen
            table.insert(dirs, {1,1}); table.insert(dirs, {-1,-1})
            table.insert(dirs, {1,-1}); table.insert(dirs, {-1,1})
        end
        
        for _, d in ipairs(dirs) do
            for i = 1, 8 do
                if not addMove(x + d[1]*i, y + d[2]*i) then break end
            end
        end
    end
    
    return moves
end

function Board:draw()
    -- Draw Checkerboard
    local tileSize = 30 
    local offsetX = (400 - 240) / 2
    local offsetY = 0

    for y = 1, 8 do
        for x = 1, 8 do
            local rect = pd.geometry.rect.new(offsetX + (x-1)*tileSize, offsetY + (y-1)*tileSize, tileSize, tileSize)
            
            -- Draw background
            if (x + y) % 2 == 0 then
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(rect)
                gfx.setColor(gfx.kColorWhite)
            else
                gfx.drawRect(rect)
            end
            
            -- Highlight valid moves
            for _, move in ipairs(self.legalMoves) do
                if move.x == x and move.y == y then
                    gfx.setColor(gfx.kColorXOR)
                    gfx.fillEllipseInRect(rect.x + tileSize/2 - 2, rect.y + tileSize/2 - 2, 4, 4)
                    gfx.setColor(gfx.kColorWhite)
                end
            end
            
            -- Draw Piece
            local piece = self.grid[y][x]
            if piece ~= Board.EMPTY then
                self:drawPiece(piece, rect)
            end
            
            -- Draw Cursor
            if self.cursor.x == x and self.cursor.y == y then
                gfx.setLineWidth(3)
                gfx.drawRect(rect)
                gfx.setLineWidth(1)
            end
            
            -- Draw Selection
            if self.selected and self.selected.x == x and self.selected.y == y then
                gfx.setLineWidth(2)
                gfx.drawRect(rect.x+2, rect.y+2, rect.width-4, rect.height-4)
                gfx.setLineWidth(1)
            end
        end
    end
end

function Board:drawPiece(piece, rect)
    -- Draw primitives since image loading is fragile
    local x, y = rect.x, rect.y
    local w, h = rect.width, rect.height
    local cx, cy = x + w/2, y + h/2
    
    local pType = piece & 7
    local color = piece & 24
    
    -- Set color based on piece color
    if color == Board.BLACK then
        gfx.setColor(gfx.kColorBlack)
    else
        gfx.setColor(gfx.kColorWhite)
        -- We need a background/outline for white pieces to be visible on white squares? 
        -- Actually white pieces on black squares are fine. White pieces on white squares need outline.
        -- But easier: Draw filled shape in piece color, with contrasting outline.
    end
    
    local function drawShape()
        if pType == Board.PAWN then
            gfx.fillEllipseInRect(cx - w/4, cy - w/4, w/2, w/2)
        elseif pType == Board.ROOK then
            gfx.fillRect(cx - w/4, cy - w/4, w/2, w/2)
        elseif pType == Board.KNIGHT then
            gfx.fillTriangle(cx - w/4, cy + w/4, cx + w/4, cy + w/4, cx, cy - w/3)
        elseif pType == Board.BISHOP then
            gfx.fillEllipseInRect(cx - w/6, cy - w/3, w/3, w/1.5)
        elseif pType == Board.QUEEN then
            gfx.fillEllipseInRect(cx - w/3, cy - w/3, w/1.5, w/1.5)
            gfx.fillRect(cx - w/8, cy - w/2, w/4, w/4) -- Crown
        elseif pType == Board.KING then
            gfx.fillRect(cx - w/6, cy - w/3, w/3, w/1.5)
            gfx.drawLine(cx, cy - w/2, cx, cy + w/3) -- Cross?
            gfx.drawLine(cx - w/4, cy - w/4, cx + w/4, cy - w/4)
        end
    end
    
    -- Draw outline first (contrasting)
    local oldColor = gfx.getColor()
    if color == Board.BLACK then gfx.setColor(gfx.kColorWhite) else gfx.setColor(gfx.kColorBlack) end
    -- Initial primitive drawing for outline (slightly larger?) 
    -- Simpler: Just toggle color.
    -- Better: Draw filled in piece color. Then draw outline in opposite color.
    
    local function setPieceColor()
         if color == Board.BLACK then gfx.setColor(gfx.kColorBlack) else gfx.setColor(gfx.kColorWhite) end
    end
    
    local function setOutlineColor()
        if color == Board.BLACK then gfx.setColor(gfx.kColorWhite) else gfx.setColor(gfx.kColorBlack) end
    end
    
    -- Fill
    setPieceColor()
    drawShape()
    
    -- Outline (Stroke)
    -- This requires switching fill/stroke or just drawing wireframe.
    -- Primitive functions usually fill or stroke based on current mode?
    -- Playdate gfx:
    -- fillRect vs drawRect.
    -- fillCircleAtPoint vs drawCircleAtPoint.
    -- I used fill functions above.
    
    -- Let's just draw an inner detail/outline for visibility.
    setOutlineColor()
    -- Heuristic outlines
     if pType == Board.PAWN then
        gfx.drawEllipseInRect(cx - w/4, cy - w/4, w/2, w/2)
    elseif pType == Board.ROOK then
        gfx.drawRect(cx - w/4, cy - w/4, w/2, w/2)
    elseif pType == Board.KNIGHT then
        gfx.drawTriangle(cx - w/4, cy + w/4, cx + w/4, cy + w/4, cx, cy - w/3)
    elseif pType == Board.BISHOP then
        gfx.drawEllipseInRect(cx - w/6, cy - w/3, w/3, w/1.5)
    elseif pType == Board.QUEEN then
        gfx.drawEllipseInRect(cx - w/3, cy - w/3, w/1.5, w/1.5)
        gfx.drawRect(cx - w/8, cy - w/2, w/4, w/4)
    elseif pType == Board.KING then
        gfx.drawRect(cx - w/6, cy - w/3, w/3, w/1.5)
    end
    
    -- If piece is white (white fill), on white square (white fill), it's invisible if no outline.
    -- But we drew outline. 
    -- If piece is black (black fill) on black square, invisible if no outline.
    -- We drew outline. This should be okay.
end

function Board:moveCursor(dx, dy)
    self.cursor.x = math.max(1, math.min(8, self.cursor.x + dx))
    self.cursor.y = math.max(1, math.min(8, self.cursor.y + dy))
end

return Board
