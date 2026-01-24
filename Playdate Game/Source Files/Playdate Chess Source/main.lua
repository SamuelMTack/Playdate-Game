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
        -- Draw semi-transparent background or filled box
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
            -- Draw one frame with "Thinking..."
            gameBoard:draw()
            gfx.drawText("Thinking...", 150, 10)
            return -- Wait for next frame to run AI
        else
            -- Run AI
            local bestMove = ai:getBestMove(gameBoard, 2) -- Depth 2
            if bestMove then
                gameBoard:makeMove(bestMove.from, bestMove.to)
            else
                 -- No moves? Checkmate or Stalemate check below
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

    -- Check Game Over
    if #gameBoard:getAllLegalMoves(gameBoard.turn) == 0 then
        gameOver = true
        if gameBoard:isInCheck(gameBoard.turn) then
            if gameBoard.turn == Board.WHITE then winner = "Black"
            else winner = "White" end
        else
            winner = nil -- Stalemate
        end
    end

    gameBoard:draw()
    
    if aiThinking then
        gfx.drawText("Thinking...", 150, 10)
    end
    
    if gameBoard:isInCheck(gameBoard.turn) then
        gfx.drawText("Check!", 5, 220)
    end
    
    pd.drawFPS(0,0)
end
