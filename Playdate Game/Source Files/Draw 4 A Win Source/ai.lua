-- AI Logic
-- Rudimentary Minimax or Heuristic check

local AI = {}

function AI.getBestMove(board, aiPlayer)
    -- 1. Check for WIN
    local moves = board:getValidMoves()
    for _, col in ipairs(moves) do
        board:dropPiece(col, aiPlayer)
        if board:checkWin(aiPlayer) then
            board:undoMove(col)
            return col
        end
        board:undoMove(col)
    end
    
    -- 2. Check for BLOCK (Opponent Win)
    local opponent = (aiPlayer == 1) and 2 or 1
    for _, col in ipairs(moves) do
        board:dropPiece(col, opponent)
        if board:checkWin(opponent) then
            board:undoMove(col)
            return col -- Block this!
        end
        board:undoMove(col)
    end
    
    -- 3. Center Preference
    local center = 4
    for _, col in ipairs(moves) do
        if col == center then return center end
    end
    
    -- 4. Random
    return moves[math.random(#moves)]
end

return AI
