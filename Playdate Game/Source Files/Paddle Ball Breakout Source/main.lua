import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics

-- Sound
local hitSynth = playdate.sound.synth.new(playdate.sound.kWaveSquare)

-- Constants
local SCREEN_W = 400
local SCREEN_H = 240
local PADDLE_W = 40
local PADDLE_H = 8
local BALL_SIZE = 6

-- Game State
local score = 0
local lives = 3
local gameState = "START"

local paddle = {x = 180, y = 220}
local ball = {x = 200, y = 150, dx = 0, dy = 0, speed = 4}
local bricks = {}

function setupGame()
    score = 0
    lives = 3
    resetBall()
    setupBricks()
end

function resetBall()
    ball.x = paddle.x + PADDLE_W/2
    ball.y = paddle.y - 10
    ball.dx = 2
    ball.dy = -ball.speed
end

function setupBricks()
    bricks = {}
    local rows = 5
    local cols = 8
    local brickW = 48
    local brickH = 12
    local padding = 2
    local offsetX = 2
    local offsetY = 30
    
    for r=1, rows do
        for c=1, cols do
            table.insert(bricks, {
                x = offsetX + (c-1)*(brickW+padding),
                y = offsetY + (r-1)*(brickH+padding),
                w = brickW,
                h = brickH,
                active = true,
                color = r -- Just an ID for coloring
            })
        end
    end
end

function playdate.update()
    gfx.clear()
    
    if gameState == "START" then
        gfx.drawText("Paddle Ball Breakout", 120, 100)
        gfx.drawText("Press A to Start", 145, 120)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            setupGame()
            gameState = "PLAY"
        end
    elseif gameState == "PLAY" then
        -- INPUT
        local change, accel = playdate.getCrankChange()
        if change ~= 0 then
            paddle.x = paddle.x + change
        else
            if playdate.buttonIsPressed(playdate.kButtonLeft) then paddle.x = paddle.x - 5 end
            if playdate.buttonIsPressed(playdate.kButtonRight) then paddle.x = paddle.x + 5 end
        end
        
        -- Clamp Paddle
        if paddle.x < 0 then paddle.x = 0 end
        if paddle.x > SCREEN_W - PADDLE_W then paddle.x = SCREEN_W - PADDLE_W end
        
        -- Ball Movement
        ball.x = ball.x + ball.dx
        ball.y = ball.y + ball.dy
        
        -- WALL COLLISIONS
        if ball.x < 0 then 
            ball.x = 0
            ball.dx = -ball.dx
            hitSynth:playNote("C4", 0.05, 0.2)
        end
        if ball.x > SCREEN_W - BALL_SIZE then
            ball.x = SCREEN_W - BALL_SIZE
            ball.dx = -ball.dx
            hitSynth:playNote("C4", 0.05, 0.2)
        end
        if ball.y < 0 then
            ball.y = 0
            ball.dy = -ball.dy
            hitSynth:playNote("C4", 0.05, 0.2)
        end
        
        -- FLOOR COLLISION (Death)
        if ball.y > SCREEN_H then
            lives = lives - 1
            if lives <= 0 then
                gameState = "GAMEOVER"
            else
                resetBall()
            end
        end
        
        -- PADDLE COLLISION
        if ball.y + BALL_SIZE >= paddle.y and ball.y <= paddle.y + PADDLE_H and
           ball.x + BALL_SIZE >= paddle.x and ball.x <= paddle.x + PADDLE_W then
            ball.dy = -math.abs(ball.dy)
            -- Add some English based on hit position
            local hitPos = (ball.x + BALL_SIZE/2) - (paddle.x + PADDLE_W/2)
            ball.dx = hitPos * 0.2
            hitSynth:playNote("E4", 0.05, 0.2)
        end
        
        -- BRICK COLLISION
        for _, b in ipairs(bricks) do
            if b.active then
                if ball.x + BALL_SIZE > b.x and ball.x < b.x + b.w and
                   ball.y + BALL_SIZE > b.y and ball.y < b.y + b.h then
                    b.active = false
                    ball.dy = -ball.dy -- Simple reflection
                    score = score + 10
                    hitSynth:playNote("G4", 0.05, 0.2)
                    break -- Only hit one brick per frame
                end
            end
        end
        
        -- WIN Check
        local bricksLeft = false
        for _, b in ipairs(bricks) do
            if b.active then bricksLeft = true break end
        end
        if not bricksLeft then gameState = "WIN" end
        
        drawGame()
        
    elseif gameState == "GAMEOVER" or gameState == "WIN" then
        drawGame()
        gfx.fillRect(100, 90, 200, 60)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(102, 92, 196, 56)
        gfx.setColor(gfx.kColorBlack)
        if gameState == "WIN" then
            gfx.drawText("YOU WIN!", 160, 100)
        else
            gfx.drawText("GAME OVER", 160, 100)
        end
        gfx.drawText("Final Score: " .. score, 145, 120)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "START"
        end
    end
    
    playdate.drawFPS(0,0)
end

function drawGame()
    -- Paddle
    gfx.fillRect(paddle.x, paddle.y, PADDLE_W, PADDLE_H)
    
    -- Ball
    gfx.fillRect(ball.x, ball.y, BALL_SIZE, BALL_SIZE)
    
    -- Bricks
    local patterns = {gfx.kColorBlack, gfx.kColorDarkGray, gfx.kColorGray, gfx.kColorLightGray}
    for _, b in ipairs(bricks) do
        if b.active then
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(b.x, b.y, b.w, b.h)
            -- Simple dithering effect based on row color
            local p = patterns[(b.color % 3) + 1]
            if p then
                 gfx.setColor(p)
                 gfx.fillRect(b.x + 1, b.y + 1, b.w - 2, b.h - 2)
            end
            gfx.setColor(gfx.kColorBlack)
        end
    end
    
    -- UI
    gfx.drawText("Score: " .. score, 5, 225)
    gfx.drawText("Lives: " .. lives, 340, 225)
end
