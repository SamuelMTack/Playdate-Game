local gfx = playdate.graphics

UI = {}

function UI.drawMenu()
    gfx.drawText("Playdate Tanks", 100, 50)
    
    local opt1 = "1 Player (vs AI)"
    local opt2 = "2 Players (Hot Seat)"
    
    if Game.menuOption == 1 then opt1 = "> " .. opt1 end
    if Game.menuOption == 2 then opt2 = "> " .. opt2 end
    
    gfx.drawText(opt1, 80, 100)
    gfx.drawText(opt2, 80, 130)
end

function UI.drawGame()
    local currentPlayer = Game.players[Game.currentPlayerIndex]
    
    -- Status Bar
    gfx.fillRect(0, 0, 400, 20)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    
    local pText = "P" .. Game.currentPlayerIndex
    if Game.currentMode == Game.MODE.PVE and Game.currentPlayerIndex == 2 then
        pText = "CPU"
    end
    
    gfx.drawText(pText, 10, 2)
    gfx.drawText("Ang: " .. math.floor(currentPlayer.angle), 60, 2)
    gfx.drawText("Pow: " .. math.floor(currentPlayer.power), 140, 2)
    gfx.drawText("Fuel: " .. math.floor(currentPlayer.fuel), 220, 2)
    
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    
    if Game.currentState == Game.STATE.GAME_OVER then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(50, 100, 300, 50)
        gfx.drawText("GAME OVER! Player " .. Game.winnerIndex .. " Wins!", 100, 110)
        gfx.drawText("Press A to return to Menu", 100, 130)
    end
end
