import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "player"
import "invader"
import "bullet"
import "barricade"

local gfx = playdate.graphics

-- Game Constants
SCREEN_WIDTH = 400
SCREEN_HEIGHT = 240

-- Game State
local gameState = "TITLE" -- TITLE, PLAY, GAMEOVER
local score = 0

function setupGame()
    gfx.sprite.removeAll()
    score = 0 -- Reset score
    createPlayer()
    setupInvaders()
    setupBarricades()
end

function addToScore(points)
    score = score + points
end

function playdate.update()
    gfx.clear()
    playdate.timer.updateTimers()

    if gameState == "TITLE" then
        drawTitleScreen()
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "PLAY"
            setupGame()
        end
    elseif gameState == "PLAY" then
        gfx.sprite.update()
        updateInvaders() -- Global function from invader.lua
        gfx.drawText("Score: " .. score, 5, 5)
    elseif gameState == "GAMEOVER" then
        gfx.sprite.update()
        drawGameOverScreen()
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "TITLE"
        end
    end
    
    playdate.drawFPS(0,0)
end

function drawTitleScreen()
    gfx.drawText("Alien Space Invaders", 130, 100)
    gfx.drawText("Press A to Start", 145, 120)
end

function drawGameOverScreen()
    gfx.drawText("GAME OVER", 155, 100)
    gfx.drawText("Press A to Restart", 140, 120)
end

function setGameOver()
    gameState = "GAMEOVER"
end
