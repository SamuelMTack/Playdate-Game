AI = {}

function AI.setupBoard(board, shipsLengths)
    for _, len in ipairs(shipsLengths) do
        local placed = false
        while not placed do
            local x = math.random(1, 10)
            local y = math.random(1, 10)
            local horiz = math.random() > 0.5
            if board:place(x, y, len, horiz) then
                placed = true
            end
        end
    end
end

function AI.getAttack(board)
    -- Random hunt for now
    local valid = false
    local x, y
    while not valid do
        x = math.random(1, 10)
        y = math.random(1, 10)
        if board.grid[y][x] ~= 2 and board.grid[y][x] ~= 3 then
            valid = true
        end
    end
    return x, y
end
