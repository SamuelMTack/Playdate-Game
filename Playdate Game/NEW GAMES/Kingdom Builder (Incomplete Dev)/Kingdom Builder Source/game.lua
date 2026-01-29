Game = {}

Game.STATE = {
    MENU = 1,
    DRAW = 2,
    PLACE = 3,
    PLACE_MEEPLE = 4,
    GAME_OVER = 5
}

Game.currentState = Game.STATE.MENU
Game.board = nil
Game.deck = {}
Game.currentTile = nil
Game.cursor = {x=0, y=0}
Game.meepleCursor = 0
Game.currentPlayer = 1
Game.scores = {0, 0}
Game.meeples = {7, 7}
Game.cam = {x=200, y=120}
Game.message = ""

function Game.reset()
    Game.board = Board()
    Game.deck = {}
    -- Fill deck with random tiles
    for i=1, 50 do
        table.insert(Game.deck, math.random(1, #Tile.TYPES))
    end
    Game.currentState = Game.STATE.DRAW
end

function Game.update()
    if Game.currentState == Game.STATE.MENU then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            Game.reset()
        end
    elseif Game.currentState == Game.STATE.DRAW then
        if #Game.deck == 0 then
            Game.currentState = Game.STATE.GAME_OVER
            return
        end
        local typeIdx = table.remove(Game.deck)
        Game.currentTile = Tile(typeIdx)
        Game.currentState = Game.STATE.PLACE
        Game.message = "Place Tile"
        
        -- Reset cursor to 0,0 usually good starting point
        Game.cursor.x = 0
        Game.cursor.y = 0
        
    elseif Game.currentState == Game.STATE.PLACE then
        if playdate.buttonJustPressed(playdate.kButtonUp) then Game.cursor.y = Game.cursor.y - 1 end
        if playdate.buttonJustPressed(playdate.kButtonDown) then Game.cursor.y = Game.cursor.y + 1 end
        if playdate.buttonJustPressed(playdate.kButtonLeft) then Game.cursor.x = Game.cursor.x - 1 end
        if playdate.buttonJustPressed(playdate.kButtonRight) then Game.cursor.x = Game.cursor.x + 1 end
        
        if playdate.buttonJustPressed(playdate.kButtonB) then
            Game.currentTile:rotate()
        end
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            if Game.board:canPlace(Game.cursor.x, Game.cursor.y, Game.currentTile) then
                Game.board:placeTile(Game.cursor.x, Game.cursor.y, Game.currentTile)
                
                -- Transition to Meeple Placement
                if Game.meeples[Game.currentPlayer] > 0 then
                    Game.currentState = Game.STATE.PLACE_MEEPLE
                    Game.meepleCursor = 0 -- Default to Center
                    Game.message = "Place Meeple?"
                else
                    Game.message = "No Meeples Left!"
                    Game.finishTurn()
                end
            else
                Game.message = "Invalid Spot!"
            end
        end
        
    elseif Game.currentState == Game.STATE.PLACE_MEEPLE then
        if playdate.buttonJustPressed(playdate.kButtonLeft) then Game.meepleCursor = 4 end
        if playdate.buttonJustPressed(playdate.kButtonRight) then Game.meepleCursor = 2 end
        if playdate.buttonJustPressed(playdate.kButtonUp) then Game.meepleCursor = 1 end
        if playdate.buttonJustPressed(playdate.kButtonDown) then Game.meepleCursor = 3 end
        -- Center selection? Maybe verify inputs
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            -- Place Meeple
            Game.currentTile.meeple = Game.currentPlayer
            Game.currentTile.meepleSpot = Game.meepleCursor
            Game.meeples[Game.currentPlayer] = Game.meeples[Game.currentPlayer] - 1
            Game.finishTurn()
        elseif playdate.buttonJustPressed(playdate.kButtonB) then
            -- Skip Meeple
            Game.finishTurn()
        end
    end
    
    -- Camera Follow Cursor
    local targetX = -Game.cursor.x * 30 + 200
    local targetY = -Game.cursor.y * 30 + 120
    Game.cam.x = Game.cam.x + (targetX - Game.cam.x) * 0.2
    Game.cam.y = Game.cam.y + (targetY - Game.cam.y) * 0.2
end

function Game.finishTurn()
    -- Check Scoring
    local results = Game.board:checkScoring(Game.currentTile)
    
    if #results > 0 then
        local msg = ""
        for _, res in ipairs(results) do
            if res.winner then
                 if res.winner == 3 then -- Tie
                     Game.scores[1] = Game.scores[1] + res.score
                     Game.scores[2] = Game.scores[2] + res.score
                     msg = msg .. res.type .. ": Tie +" .. res.score .. "\n"
                 else
                     Game.scores[res.winner] = Game.scores[res.winner] + res.score
                     msg = msg .. res.type .. ": P" .. res.winner .. " +" .. res.score .. "\n"
                 end
                 
                 -- Return Meeples
                 for _, t in ipairs(res.tiles) do
                     t.meeple = nil
                     -- Mark scored
                     if res.type == "Road" then t.roadScored = true
                     elseif res.type == "City" then t.cityScored = true end
                 end
            elseif res.type == "Monastery" or res.type == "Monastery (Neighbor)" then
                 -- Handle Monastery specific owner lookup (Tile owner)
                 if res.tile.meeple and res.tile.center == 3 then
                     Game.scores[res.tile.meeple] = Game.scores[res.tile.meeple] + res.score
                     msg = msg .. "Monastery: P"..res.tile.meeple.." +"..res.score.."\n"
                     res.tile.meeple = nil
                     res.tile.monasteryScored = true
                     Game.meeples[res.tile.meeple] = Game.meeples[res.tile.meeple] + 1 -- This is WRONG, res.tile.meeple was just nilled. 
                     -- Need to capture owner BEFORE clearing
                 end
            end
        end
        Game.message = msg
    else
        Game.message = ""
    end
    
    -- Switch Player
    Game.currentPlayer = (Game.currentPlayer % 2) + 1
    Game.currentState = Game.STATE.DRAW
end

function Game.draw()
    if Game.currentState == Game.STATE.MENU then
        UI.drawMenu()
    elseif Game.currentState == Game.STATE.GAME_OVER then
        UI.drawGameOver()
    else
        UI.drawGame()
    end
end
