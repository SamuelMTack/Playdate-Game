import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "level"
import "pacman"
import "ghost"

local gfx = playdate.graphics

-- Global Game State
score = 0
gameState = "START" -- START, PLAY, GAMEOVER, WIN

function setupGame()
    gfx.sprite.removeAll()
    score = 0
    buildLevel() -- From level.lua
    setupPacman() -- From pacman.lua
    setupGhosts() -- From ghost.lua
end

function playdate.update()
    gfx.clear()
    playdate.timer.updateTimers()

    if gameState == "START" then
        gfx.drawText("Glutinous Spheroid", 130, 100)
        gfx.drawText("Press A to Start", 145, 120)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "PLAY"
            setupGame()
        end
    elseif gameState == "PLAY" then
        gfx.sprite.update()
        gfx.drawText("Score: " .. score, 5, 220)
        
        -- Check win condition
        if isLevelCleared() then
            gameState = "WIN"
        end
    elseif gameState == "GAMEOVER" then
        gfx.sprite.update()
        gfx.drawText("GAME OVER", 150, 100)
        gfx.drawText("Press A to Restart", 135, 120)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "START"
        end
    elseif gameState == "WIN" then
        gfx.sprite.update()
        gfx.drawText("YOU WIN!", 160, 100)
        gfx.drawText("Press A to Restart", 135, 120)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "START"
        end
    end
end
