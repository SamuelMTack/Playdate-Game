import "board"
import "ai"

local pd <const> = playdate
local gfx <const> = pd.graphics

local gameBoard = Board.new()
local ai = AI.new()
local aiThinking = false
local gameOver = false
local winner = nil

function pd.update()
    gfx.clear()
    
    if gameOver then
        gameBoard:draw()
        -- Game Over Box
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(50, 80, 300, 80)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(50, 80, 300, 80)
        
        gfx.drawText("Game Over!", 160, 100)
        if winner then
            gfx.drawText(winner .. " Wins!", 160, 120)
        else
            gfx.drawText("Draw!", 180, 120)
        end
        gfx.drawText("Press A to Restart", 140, 140)
        
        if pd.buttonJustPressed(pd.kButtonA) then
            gameBoard = Board.new()
            gameOver = false
            winner = nil
        end
        return
    end

    if gameBoard.turn == Board.BLACK then
        if not aiThinking then
            aiThinking = true
            gameBoard:draw()
            gfx.drawText("Thinking...", 150, 10)
            return
        else
            local bestMove = ai:getBestMove(gameBoard, 3) 
            if bestMove then
                gameBoard:makeMove(bestMove)
            else
                 -- No moves for AI? AI loses.
                 winner = "Red" -- Player is Red (White color technically, but logic calls it Red/Black usually or White/Black)
                 gameOver = true
            end
            aiThinking = false
        end
    else
        -- Player Turn
        if pd.buttonJustPressed(pd.kButtonUp) then
            gameBoard:moveCursor(0, -1)
        elseif pd.buttonJustPressed(pd.kButtonDown) then
            gameBoard:moveCursor(0, 1)
        elseif pd.buttonJustPressed(pd.kButtonLeft) then
            gameBoard:moveCursor(-1, 0)
        elseif pd.buttonJustPressed(pd.kButtonRight) then
            gameBoard:moveCursor(1, 0)
        end
        
        if pd.buttonJustPressed(pd.kButtonA) then
            gameBoard:selectSquare()
        end
    end

    -- Check Game Over for Player (Only lose if 0 pieces, per user request)
    local redCount = gameBoard:getPieceCount(Board.RED)
    local blackCount = gameBoard:getPieceCount(Board.BLACK)
    
    if redCount == 0 then
        gameOver = true
        winner = "Black"
    elseif blackCount == 0 then
        gameOver = true
        winner = "Red"
    elseif #gameBoard:getAllLegalMoves(gameBoard.turn) == 0 then
        -- Blocked but has pieces. Standard rule is loss, but User requested play continues (Pass Turn).
        -- We must force a turn switch so the other player can move.
        gfx.drawText("Blocked! Passing Turn...", 5, 230)
        gameBoard.turn = (gameBoard.turn == Board.RED) and Board.BLACK or Board.RED
        gameBoard.legalMoves = gameBoard:getLegalMoves(gameBoard.turn)
    end

    gameBoard:draw()
    
    if aiThinking then
        gfx.drawText("Thinking...", 150, 10)
    end
    
    -- Debug Stats (Moved to Left Sidebar)
    local turnStr = (gameBoard.turn == Board.RED) and "Red" or "Black"
    gfx.drawText("Turn: " .. turnStr, 5, 40)
    gfx.drawText("Moves: " .. #gameBoard.legalMoves, 5, 60)
    gfx.drawText("Red: " .. redCount, 5, 80)
    gfx.drawText("Black: " .. blackCount, 5, 100)
    
    if gameBoard.chainPiece then
        gfx.drawText("Chain!", 5, 120)
    end
    
    pd.drawFPS(0,0)
end
