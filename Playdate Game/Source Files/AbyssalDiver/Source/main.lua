import "timer"
import "text_helper"
import "sound_manager"
import "particles"
import "player"
import "entity_manager"

local gfx = playdate.graphics

-- Game States
local STATE_START = 1
local STATE_PLAY = 2
local STATE_GAMEOVER = 3
local gameState = STATE_START


-- Globals
local score = 0
local depth = 0
local highScore = 0
_G.screenShake = 0

function playdate.update()
    -- Update Timers
    playdate.timer.updateTimers()

    -- Load High Score
    if highScore == 0 then
        local data = playdate.datastore.read()
        if data and data.highScore then
            highScore = data.highScore
        end
    end

    -- Screen Shake
    local shakeX, shakeY = 0, 0
    if _G.screenShake > 0 then
        shakeX = math.random(-_G.screenShake, _G.screenShake)
        shakeY = math.random(-_G.screenShake, _G.screenShake)
        _G.screenShake -= 1
        gfx.setDrawOffset(shakeX, shakeY)
    else
        gfx.setDrawOffset(0, 0)
    end

    -- Biome Rendering Setup
    local isMidnight = (depth > 100)
    if isMidnight then
        gfx.clear(gfx.kColorBlack)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.setColor(gfx.kColorWhite)
    else
        gfx.clear(gfx.kColorWhite)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorBlack)
    end
    
    if gameState == STATE_START then
        drawStartScreen()
        if playdate.buttonJustPressed(playdate.kButtonA) then
            resetGame()
            gameState = STATE_PLAY
            SoundManager.playBGM()
            SoundManager.playBubble()
        end
    elseif gameState == STATE_PLAY then
        updateGame()
        drawGame()
    elseif gameState == STATE_GAMEOVER then
        drawGameOverScreen()
        if playdate.buttonJustPressed(playdate.kButtonA) then
            resetGame()
            gameState = STATE_PLAY
            SoundManager.playBGM()
        end
    end
    
    playdate.drawFPS(0,0)
end

function drawStartScreen()
    gfx.fillEllipseInRect(200 - (80 + math.sin(playdate.getCurrentTimeMilliseconds()/300)*5), 120 - (80 + math.sin(playdate.getCurrentTimeMilliseconds()/300)*5), (80 + math.sin(playdate.getCurrentTimeMilliseconds()/300)*5)*2, (80 + math.sin(playdate.getCurrentTimeMilliseconds()/300)*5)*2)
    
    -- Invert text inside circle
    local oldMode = gfx.getImageDrawMode()
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.drawTextAligned("*ABYSSAL DIVER*", 200, 80, kTextAlignment.center)
    gfx.setImageDrawMode(oldMode)
    
    gfx.drawTextAligned("Press A to Dive", 200, 140, kTextAlignment.center)
    gfx.drawTextAligned("Best Depth: " .. math.floor(highScore) .. "m", 200, 220, kTextAlignment.center)
end

function drawGameOverScreen()
    gfx.drawTextAligned("GAME OVER", 200, 80, kTextAlignment.center)
    gfx.drawTextAligned("Depth: " .. math.floor(depth) .. "m", 200, 110, kTextAlignment.center)
    
    if depth >= highScore then
        gfx.drawTextAligned("*NEW RECORD*", 200, 130, kTextAlignment.center)
    else
        gfx.drawTextAligned("Best: " .. math.floor(highScore) .. "m", 200, 130, kTextAlignment.center)
    end
    
    gfx.drawTextAligned("Press A to Retry", 200, 160, kTextAlignment.center)
end

function resetGame()
    score = 0
    depth = 0
    Player.reset()
    EntityManager.reset()
    Particles.reset()
    _G.screenShake = 0
end

function updateGame()
    Player.update()
    EntityManager.update(depth)
    Particles.update()
    
    local speed = 0.1
    if Player.speedTimer > 0 then speed = 0.3 end
    depth += speed
    
    if Player.isDead then
        gameState = STATE_GAMEOVER
        SoundManager.stopBGM()
        SoundManager.playGameOver()
        
        if depth > highScore then
            highScore = depth
            playdate.datastore.write({highScore = highScore})
        end
    end
end

function drawGame()
    -- Draw Depth Gradient (Simulated by lines)
    if depth > 50 then
        gfx.setLineWidth(1)
        for i=0, 240, 10 do
            if i % 20 == 0 then gfx.drawLine(0, i, 400, i) end
        end
    end

    EntityManager.draw()
    Player.draw()
    Particles.draw()
    
    -- UI
    -- Invert UI based on global state already set in playdate.update?
    -- No, we need to enforce specific colors for visibility
    if depth > 100 then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, 400, 20)
        gfx.setColor(gfx.kColorBlack) -- Text color
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    else
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, 400, 20)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(0, 0, 400, 20)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
    
    gfx.drawText("Depth: " .. math.floor(depth) .. "m", 5, 2)
    
    -- Oxygen Bar
    gfx.drawRect(300, 4, 90, 12)
    gfx.fillRect(302, 6, (Player.oxygen/100) * 86, 8)
    gfx.drawTextAligned("O2", 295, 2, kTextAlignment.right)
    
    -- Powerup Icons
    if Player.invincibleTimer > 0 then
        gfx.drawText("S", 270, 2)
    end
    if Player.speedTimer > 0 then
        gfx.drawText(">>", 250, 2)
    end
    
    -- Restore draw mode
    if depth > 100 then
         gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
         gfx.setColor(gfx.kColorWhite)
    end
end
