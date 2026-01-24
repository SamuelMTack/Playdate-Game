import "board"

AI = {}
AI.__index = AI

function AI.new()
    local self = setmetatable({}, AI)
    return self
end

function AI:evaluate(board)
    local score = 0
    for y = 1, 8 do
        for x = 1, 8 do
            local piece = board.grid[y][x]
            if piece ~= Board.EMPTY then
                local color = piece & 3
                local type = piece & 12
                local val = 10
                if type == Board.KING then val = 50 end -- Kings are valuable
                
                -- Positional Bonus (advancing is good for men)
                -- Black moves down (y increases). Red moves up (y decreases).
                if type == Board.MAN then
                    if color == Board.BLACK then
                        val = val + y*2 -- Incentivize advancing
                    else
                        val = val + (8 - y)*2
                    end
                end
                
                if color == Board.BLACK then
                    score = score + val
                else
                    score = score - val
                end
            end
        end
    end
    
    -- Material diff scaling to encourage trading when ahead or taking pieces
    -- Score is relative to Black (AI). Higher is better for AI.
    return score
end

function AI:getBestMove(board, depth)
    local moves = board:getAllLegalMoves(board.turn)
    local bestMove = nil
    local bestScore = -99999
    
    for _, move in ipairs(moves) do
        local context = board:makeMove(move)
        local score = self:minimax(board, depth - 1, -100000, 100000, false)
        board:undoMove(context)
        
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
        if board.turn == Board.BLACK then return -10000 -- Black loses
        else return 10000 -- Red loses (Black wins)
        end
    end
    
    if isMaximizing then
        local maxEval = -100000
        for _, move in ipairs(moves) do
            local context = board:makeMove(move)
            local eval = self:minimax(board, depth - 1, alpha, beta, false)
            board:undoMove(context)
            maxEval = math.max(maxEval, eval)
            alpha = math.max(alpha, eval)
            if beta <= alpha then break end
        end
        return maxEval
    else
        local minEval = 100000
        for _, move in ipairs(moves) do
            local context = board:makeMove(move)
            local eval = self:minimax(board, depth - 1, alpha, beta, true)
            board:undoMove(context)
            minEval = math.min(minEval, eval)
            beta = math.min(beta, eval)
            if beta <= alpha then break end
        end
        return minEval
    end
end

return AI
