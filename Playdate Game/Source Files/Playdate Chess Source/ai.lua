import "board"

AI = {}
AI.__index = AI

local SCORES = {
    [Board.PAWN] = 10,
    [Board.KNIGHT] = 30,
    [Board.BISHOP] = 30,
    [Board.ROOK] = 50,
    [Board.QUEEN] = 90,
    [Board.KING] = 900
}

function AI.new()
    local self = setmetatable({}, AI)
    return self
end

function AI:getBestMove(board, depth)
    local bestMove = nil
    local bestScore = -99999
    local moves = board:getAllLegalMoves(board.turn)
    
    -- Simple randomization to avoid identical games
    -- Shuffle moves lightly? keeping it simple for now.
    
    for _, move in ipairs(moves) do
        local context = board:makeMove(move.from, move.to)
        local score = -self:minimax(board, depth - 1, -100000, 100000, false)
        board:undoMove(move.from, move.to, context)
        
        if score > bestScore then
            bestScore = score
            bestMove = move
        end
    end
    
    return bestMove
end

function AI:minimax(board, depth, alpha, beta, isMaximizing)
    if depth == 0 then
        return self:evaluate(board)
    end
    
    local moves = board:getAllLegalMoves(board.turn)
    
    if #moves == 0 then
        if board:isInCheck(board.turn) then
            return -10000 + depth -- Checkmate (prefer faster mates)
        else
            return 0 -- Stalemate
        end
    end
    
    if isMaximizing then
        local maxEval = -100000
        for _, move in ipairs(moves) do
            local context = board:makeMove(move.from, move.to)
            local eval = self:minimax(board, depth - 1, alpha, beta, false)
            board:undoMove(move.from, move.to, context)
            maxEval = math.max(maxEval, eval)
            alpha = math.max(alpha, eval)
            if beta <= alpha then break end
        end
        return maxEval
    else
        -- Actually, since makeMove switches turn, we are always effectively "maximizing" for the *current* player in the recursive call relative to *their* perspective?
        -- Standard Minimax:
        -- if turn is AI (Black): maximize.
        -- if turn is Player (White): minimize.
        -- But my makeMove switches turn.
        -- So:
        -- Level 0 (Black): Calls makeMove -> Turn is White. Recurse.
        -- Level 1 (White): Calculates heuristic for White?
        -- Evaluation function usually is (White Material - Black Material).
        -- If I look from perspective of current turn:
        -- Negamax approach is cleaner with turn switching.
        -- Let's stick to Negamax loop in getBestMove: score = -minimax(...).
        
        -- So here:
        local maxEval = -100000
        for _, move in ipairs(moves) do
             local context = board:makeMove(move.from, move.to)
             -- Negamax: return -minimax(...)
             local eval = -self:minimax(board, depth - 1, -beta, -alpha, true) 
             board:undoMove(move.from, move.to, context)
             maxEval = math.max(maxEval, eval)
             alpha = math.max(alpha, eval)
             if alpha >= beta then break end
        end
        return maxEval
    end
    
    -- Wait, the isMaximizing arg is confusing with Negamax. 
    -- Let's just use pure Negamax.
    -- Remove isMaximizing from signature.
end

function AI:negamax(board, depth, alpha, beta)
    if depth == 0 then
        return self:evaluate(board)
    end
    
    local moves = board:getAllLegalMoves(board.turn)
    
    if #moves == 0 then
        if board:isInCheck(board.turn) then
            return -10000 + depth -- Losing
        else
            return 0 -- Draw
        end
    end
    
    local maxEval = -100000
    for _, move in ipairs(moves) do
        local context = board:makeMove(move.from, move.to)
        local eval = -self:negamax(board, depth - 1, -beta, -alpha)
        board:undoMove(move.from, move.to, context)
        maxEval = math.max(maxEval, eval)
        alpha = math.max(alpha, eval)
        if alpha >= beta then break end
    end
    return maxEval
end

function AI:evaluate(board)
    -- Eval from perspective of board.turn
    -- Score = My Material - Opponent Material
    -- Or constant perspective (White - Black) and then flip if Black turn.
    
    local whiteScore = 0
    local blackScore = 0
    
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = board.grid[y][x]
            if piece ~= Board.EMPTY then
                local pType = piece & 7
                local color = piece & 24
                local val = SCORES[pType] or 0
                
                if color == Board.WHITE then
                    whiteScore = whiteScore + val
                else
                    blackScore = blackScore + val
                end
            end
        end
    end
    
    if board.turn == Board.WHITE then
        return whiteScore - blackScore
    else
        return blackScore - whiteScore
    end
end

-- Re-implement getBestMove to use negamax
function AI:getBestMove(board, depth)
    local bestMove = nil
    local bestScore = -99999
    local moves = board:getAllLegalMoves(board.turn)
    
    for _, move in ipairs(moves) do
        local context = board:makeMove(move.from, move.to)
        local score = -self:negamax(board, depth - 1, -100000, 100000)
        board:undoMove(move.from, move.to, context)
        
        -- Simple logging
        -- print("Move " .. move.from.x ..","..move.from.y .. " to " .. move.to.x..","..move.to.y .. " Score: " .. score)
        
        if score > bestScore then
            bestScore = score
            bestMove = move
        end
    end
    return bestMove
end

return AI
