import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "board"
local AI = import "ai"

local gfx = playdate.graphics

local gameState = "MENU" -- MENU, PLAY, GAME_OVER
local onePlayerMode = true
local turn = 1 -- 1 or 2
local board = nil
local cursorCol = 4
local resultMessage = ""

function initGame()
    gfx.sprite.removeAll()
    board = Board()
    turn = 1
    cursorCol = 4
    gameState = "PLAY"
    resultMessage = ""
end

function playdate.update()
    gfx.clear()
    
    if gameState == "MENU" then
        gfx.drawText("* Draw 4 A Win *", 140, 80)
        
        gfx.drawText("Select Mode:", 155, 120)
        
        if onePlayerMode then
            gfx.fillCircleAtPoint(130, 145, 5) -- Cursor
        else
            gfx.fillCircleAtPoint(130, 165, 5)
        end
        
        gfx.drawText("1 PLAYER (vs AI)", 145, 137)
        gfx.drawText("2 PLAYERS", 145, 157)
        
        gfx.drawText("A to Start", 160, 200)
        
        if playdate.buttonJustPressed(playdate.kButtonUp) or playdate.buttonJustPressed(playdate.kButtonDown) then
            onePlayerMode = not onePlayerMode
        end
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            initGame()
        end
        
    elseif gameState == "PLAY" then
        gfx.sprite.update()
        playdate.timer.updateTimers()
        
        -- Draw Cursor
        local boardX, boardY = board:getPosition()
        local cell = board.cellSize
        local startX = boardX - (board.width/2) + 2 + (cell/2)
        local cx = startX + (cursorCol-1) * cell
        local cy = boardY - (board.height/2) - 20
        
        gfx.fillTriangle(cx, cy+10, cx-5, cy, cx+5, cy) -- Arrow pointing down
        
        -- HUD
        gfx.drawText("Turn: P" .. turn, 10, 10)
        
        -- AI Turn
        if onePlayerMode and turn == 2 then
             -- Tiny delay for realism?
             -- Hacky non-blocking delay: just do it next frame or logic block
             -- For simple AI, just do it.
             local move = AI.getBestMove(board, 2)
             if move then
                performMove(move)
             end
             return
        end
        
        -- Player Input
        if playdate.buttonJustPressed(playdate.kButtonLeft) then
            if cursorCol > 1 then cursorCol = cursorCol - 1 end
        elseif playdate.buttonJustPressed(playdate.kButtonRight) then
            if cursorCol < board.cols then cursorCol = cursorCol + 1 end
        end
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            performMove(cursorCol)
        end
        
    elseif gameState == "GAME_OVER" then
        gfx.sprite.update()
        
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(80, 90, 240, 60)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(80, 90, 240, 60)
        
        local w, h = gfx.getTextSize(resultMessage)
        gfx.drawText(resultMessage, 200 - w/2, 100)
        
        gfx.drawText("B to Menu", 165, 130)
        
        if playdate.buttonJustPressed(playdate.kButtonB) then
            gameState = "MENU"
            gfx.sprite.removeAll()
        end
    end
end

function performMove(col)
    local success, row = board:dropPiece(col, turn)
    if success then
        -- Check Win
        if board:checkWin(turn) then
            gameState = "GAME_OVER"
            if onePlayerMode and turn == 2 then
                resultMessage = "AI WINS!"
            else
                resultMessage = "PLAYER " .. turn .. " WINS!"
            end
            return
        end
        
        -- Switch Turn
        turn = (turn == 1) and 2 or 1
    end
end
