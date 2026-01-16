import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics

-- Constants
local SCREEN_W = 400
local SCREEN_H = 240
local PADDLE_W = 10
local PADDLE_H = 50
local BALL_SIZE = 8
local PADDLE_SPEED = 5

-- Sound
local beepSynth = playdate.sound.synth.new(playdate.sound.kWaveSquare)

-- Game State
local playerY = (SCREEN_H - PADDLE_H) / 2
local aiY = (SCREEN_H - PADDLE_H) / 2
local ball = {x = SCREEN_W/2, y = SCREEN_H/2, dx = 3, dy = 3}
local scorePlayer = 0
local scoreAI = 0

function resetBall()
    ball.x = SCREEN_W/2
    ball.y = SCREEN_H/2
    ball.dx = -ball.dx -- Serve to winner/loser
    ball.dy = math.random(-3, 3)
    if ball.dy == 0 then ball.dy = 2 end
end

function playdate.update()
    gfx.clear()
    
    -- INPUT: Player Paddle (Crank or D-Pad)
    local change, acceleratedChange = playdate.getCrankChange()
    if change ~= 0 then
        playerY = playerY + change
    else
        if playdate.buttonIsPressed(playdate.kButtonUp) then
            playerY = playerY - PADDLE_SPEED
        elseif playdate.buttonIsPressed(playdate.kButtonDown) then
            playerY = playerY + PADDLE_SPEED
        end
    end
    
    -- Clamp Player
    if playerY < 0 then playerY = 0 end
    if playerY > SCREEN_H - PADDLE_H then playerY = SCREEN_H - PADDLE_H end
    
    -- AI Paddle
    -- Simple tracking with speed limit
    local centerAI = aiY + PADDLE_H/2
    if centerAI < ball.y - 10 then
        aiY = aiY + 3
    elseif centerAI > ball.y + 10 then
        aiY = aiY - 3
    end
    
    -- Clamp AI
    if aiY < 0 then aiY = 0 end
    if aiY > SCREEN_H - PADDLE_H then aiY = SCREEN_H - PADDLE_H end
    
    -- Ball Movement
    ball.x = ball.x + ball.dx
    ball.y = ball.y + ball.dy
    
    -- Ball Collision: Top/Bottom
    if ball.y < 0 or ball.y > SCREEN_H - BALL_SIZE then
        ball.dy = -ball.dy
        beepSynth:playNote("C4", 0.05, 0.3)
    end
    
    -- Ball Collision: Paddles
    -- Player Paddle Rect
    local playerRect = {x=10, y=playerY, w=PADDLE_W, h=PADDLE_H}
    -- AI Paddle Rect
    local aiRect = {x=SCREEN_W - 20, y=aiY, w=PADDLE_W, h=PADDLE_H}
    
    -- Check collision with Player
    if ball.x < playerRect.x + playerRect.w and
       ball.x + BALL_SIZE > playerRect.x and
       ball.y + BALL_SIZE > playerRect.y and
       ball.y < playerRect.y + playerRect.h then
           ball.dx = math.abs(ball.dx) + 0.5 -- Speed up slightly
           ball.x = playerRect.x + playerRect.w -- Push out
           beepSynth:playNote("E4", 0.1, 0.5)
    end
    
    -- Check collision with AI
    if ball.x + BALL_SIZE > aiRect.x and
       ball.x < aiRect.x + aiRect.w and
       ball.y + BALL_SIZE > aiRect.y and
       ball.y < aiRect.y + aiRect.h then
           ball.dx = -math.abs(ball.dx) - 0.5
           ball.x = aiRect.x - BALL_SIZE -- Push out
           beepSynth:playNote("G4", 0.1, 0.5)
    end
    
    -- Scoring
    if ball.x < 0 then
        scoreAI = scoreAI + 1
        resetBall()
    elseif ball.x > SCREEN_W then
        scorePlayer = scorePlayer + 1
        resetBall()
    end
    
    -- DRAW
    -- Player
    gfx.fillRect(10, playerY, PADDLE_W, PADDLE_H)
    -- AI
    gfx.fillRect(SCREEN_W - 20, aiY, PADDLE_W, PADDLE_H)
    -- Ball
    gfx.fillRect(ball.x, ball.y, BALL_SIZE, BALL_SIZE)
    -- Center Line
    gfx.drawLine(SCREEN_W/2, 0, SCREEN_W/2, SCREEN_H)
    -- Score
    gfx.drawText(tostring(scorePlayer), SCREEN_W/2 - 40, 10)
    gfx.drawText(tostring(scoreAI), SCREEN_W/2 + 30, 10)
    
    playdate.drawFPS(0,0)
end
