Game = {}

Game.STATE = {
    TITLE = 1,
    SETUP = 2, -- Placing ships
    TURN_P1 = 3,
    TURN_P2 = 4,
    AI_THINKING = 5,
    AI_RESULT = 6,
    TRANSITION = 7, -- Pass device
    GAMEOVER = 8
}

Game.MODE = {
    PVE = 1,
    PVP = 2
}

Game.currentState = Game.STATE.TITLE
Game.mode = Game.MODE.PVE
Game.boards = {} -- [1] and [2]
Game.cursor = {x=1, y=1}
Game.setupShipIndex = 1
Game.setupHoriz = true
Game.shipsToPlace = {5, 4, 3, 3, 2} -- Lengths
Game.message = ""
Game.winner = 0
Game.aiTimer = 0

function Game.reset()
    Game.boards[1] = Board()
    Game.boards[2] = Board()
    Game.cursor = {x=1, y=1}
    Game.setupShipIndex = 1
    Game.setupHoriz = true
    Game.message = ""
end

function Game.update()
    if Game.currentState == Game.STATE.TITLE then
        if playdate.buttonJustPressed(playdate.kButtonUp) then Game.mode = Game.MODE.PVE end
        if playdate.buttonJustPressed(playdate.kButtonDown) then Game.mode = Game.MODE.PVP end
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            Game.reset()
            Game.phase = 1 -- Player 1 Setup
            Game.currentState = Game.STATE.SETUP
            -- If PVE, maybe auto-setup AI boad later
        end
        
    elseif Game.currentState == Game.STATE.SETUP then
        Game.handleSetupInput()
        
    elseif Game.currentState == Game.STATE.TURN_P1 then
        Game.handleAttackInput(2) -- Attack Player 2's board
        
    elseif Game.currentState == Game.STATE.TURN_P2 then
        if Game.mode == Game.MODE.PVE then
            -- Switch to Thinking State
            Game.aiTimer = 60 -- 2 seconds? (30fps)
            Game.currentState = Game.STATE.AI_THINKING
            Game.message = "CPU Thinking..."
        else
             Game.handleAttackInput(1) -- Attack Player 1's board
        end

    elseif Game.currentState == Game.STATE.AI_THINKING then
        Game.aiTimer = Game.aiTimer - 1
        if Game.aiTimer <= 0 then
            -- Perform Attack
            local x, y = AI.getAttack(Game.boards[1])
            local result, sunk = Game.boards[1]:receiveAttack(x, y)
            Game.message = "CPU: " .. result
            if sunk then Game.message = Game.message .. " & SUNK!" end
            
            Game.aiTimer = 90 -- 3 seconds to read result
            Game.currentState = Game.STATE.AI_RESULT
            
            if Game.boards[1]:allSunk() then
                Game.winner = 2
                Game.aiTimer = 30
            end
        end
        
    elseif Game.currentState == Game.STATE.AI_RESULT then
         Game.aiTimer = Game.aiTimer - 1
         if Game.aiTimer <= 0 then
             if Game.winner ~= 0 then
                 Game.currentState = Game.STATE.GAMEOVER
             else
                 Game.currentState = Game.STATE.TURN_P1
                 Game.message = "Your Turn"
             end
         end

    elseif Game.currentState == Game.STATE.TRANSITION then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            Game.currentState = Game.nextState
        end
        
    elseif Game.currentState == Game.STATE.GAMEOVER then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            Game.currentState = Game.STATE.TITLE
        end
    end
end

function Game.handleSetupInput()
    -- Move Cursor
    if playdate.buttonJustPressed(playdate.kButtonUp) then Game.cursor.y = math.max(1, Game.cursor.y - 1) end
    if playdate.buttonJustPressed(playdate.kButtonDown) then Game.cursor.y = math.min(10, Game.cursor.y + 1) end
    if playdate.buttonJustPressed(playdate.kButtonLeft) then Game.cursor.x = math.max(1, Game.cursor.x - 1) end
    if playdate.buttonJustPressed(playdate.kButtonRight) then Game.cursor.x = math.min(10, Game.cursor.x + 1) end
    
    if playdate.buttonJustPressed(playdate.kButtonB) then
        Game.setupHoriz = not Game.setupHoriz
    end
    
    if playdate.buttonJustPressed(playdate.kButtonA) then
        local len = Game.shipsToPlace[Game.setupShipIndex]
        local board = Game.boards[Game.phase]
        if board:place(Game.cursor.x, Game.cursor.y, len, Game.setupHoriz) then
            Game.setupShipIndex = Game.setupShipIndex + 1
            if Game.setupShipIndex > #Game.shipsToPlace then
                -- current player done setup
                if Game.phase == 1 then
                    if Game.mode == Game.MODE.PVE then
                        -- Auto setup AI
                        AI.setupBoard(Game.boards[2], Game.shipsToPlace)
                        Game.currentState = Game.STATE.TURN_P1
                    else
                        -- P2 Setup Next
                        Game.phase = 2
                        Game.setupShipIndex = 1
                        Game.nextState = Game.STATE.SETUP
                        Game.currentState = Game.STATE.TRANSITION
                    end
                else
                    -- Both done
                    Game.currentState = Game.STATE.TRANSITION
                    Game.nextState = Game.STATE.TURN_P1
                end
            end
        end
    end
end

function Game.handleAttackInput(targetPlayerIndex)
    -- Logic for cursor moving on "Target Grid" (which displays Enemy board but hides logic)
    -- ...
    if playdate.buttonJustPressed(playdate.kButtonUp) then Game.cursor.y = math.max(1, Game.cursor.y - 1) end
    if playdate.buttonJustPressed(playdate.kButtonDown) then Game.cursor.y = math.min(10, Game.cursor.y + 1) end
    if playdate.buttonJustPressed(playdate.kButtonLeft) then Game.cursor.x = math.max(1, Game.cursor.x - 1) end
    if playdate.buttonJustPressed(playdate.kButtonRight) then Game.cursor.x = math.min(10, Game.cursor.x + 1) end
    
    if playdate.buttonJustPressed(playdate.kButtonA) then
        local board = Game.boards[targetPlayerIndex]
        local res, sunk = board:receiveAttack(Game.cursor.x, Game.cursor.y)
        if res then -- valid attack
            Game.message = res
            if sunk then Game.message = Game.message .. " & SUNK!" end
            
            if board:allSunk() then
                Game.winner = (targetPlayerIndex == 1) and 2 or 1
                Game.currentState = Game.STATE.GAMEOVER
            else
                if Game.mode == Game.MODE.PVP then
                    Game.nextState = (targetPlayerIndex == 1) and Game.STATE.TURN_P1 or Game.STATE.TURN_P2
                    Game.currentState = Game.STATE.TRANSITION
                else
                    Game.currentState = Game.STATE.TURN_P2 -- AI Turn
                end
            end
        end
    end
end

function Game.draw()
    if Game.currentState == Game.STATE.TITLE then
        UI.drawTitle()
    elseif Game.currentState == Game.STATE.SETUP then
        UI.drawSetup(Game.boards[Game.phase])
    elseif Game.currentState == Game.STATE.TURN_P1 then
        UI.drawBattle(1, Game.boards[2]) -- P1 viewing P2's board (FoW)
    elseif Game.currentState == Game.STATE.TURN_P2 then
         if Game.mode == Game.MODE.PVE then
             -- This shouldn't happen much now, transitions instantly
         else
             UI.drawBattle(2, Game.boards[1])
         end
    elseif Game.currentState == Game.STATE.AI_THINKING or Game.currentState == Game.STATE.AI_RESULT then
        UI.drawBattle(2, Game.boards[1]) -- Show CPU Board? No, show CPU attacking YOUR board
        -- Actually, we want to see OUR board (P1 board) getting hit
        UI.drawBattle(2, Game.boards[1])
    elseif Game.currentState == Game.STATE.TRANSITION then
        UI.drawTransition()
    elseif Game.currentState == Game.STATE.GAMEOVER then
        UI.drawGameOver()
    end
end
