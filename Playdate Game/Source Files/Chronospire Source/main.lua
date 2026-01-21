import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics

-- Global Game State
GameState = {
    MENU = 1,
    PLAYING = 2,
    GAMEOVER = 3,
    WIN = 4
}
currentState = GameState.MENU

-- Import Modules
import "audio_manager"
import "ui"
import "level"
import "player"
import "particles"

-- Game Globals
playerInstance = nil
currentLevel = nil

function playdate.update()
    gfx.clear()
    
    if currentState == GameState.MENU then
        UI.drawMenu()
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startGame()
        end
        
    elseif currentState == GameState.PLAYING then
        -- Updates
        playdate.timer.updateTimers()
        gfx.sprite.update()
        Particles.update()
        Level.update()
        
        -- Draw Background Grid (Simulate Blueprint)
        drawGrid()
        
        -- UI Overlay
        UI.drawHUD()
        
        -- Check Win/Loss
        if playerInstance.y > 240 then
            gameOver()
        end
        
        -- Check Goal
        if Level.goal then
            local pRect = playerInstance:getBoundsRect()
            local gRect = Level.goal:getBoundsRect()
            if pRect:intersects(gRect) then
                nextLevel()
            end
        end
        
    elseif currentState == GameState.GAMEOVER then
        gfx.drawText("GAME OVER", 160, 110)
        gfx.drawText("Press A to Restart", 140, 130)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startGame()
        end
    elseif currentState == GameState.WIN then
        gfx.drawTextAligned("VICTORY!", 200, 100, kTextAlignment.center)
        local s = math.floor(playdate.getCurrentTimeMilliseconds() / 1000)
        gfx.drawTextAligned("Time: " .. s .. "s", 200, 120, kTextAlignment.center)
        gfx.drawTextAligned("Press A to Play Again", 200, 150, kTextAlignment.center)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startGame()
        end
    end
    
    -- Global Audio Update
    AudioManager.update()
end

function nextLevel()
    if currentLevel < 5 then
        currentLevel = currentLevel + 1
        gfx.sprite.removeAll()
        Level.load(currentLevel)
        playerInstance = Player(Level.spawnX, Level.spawnY)
        Particles.reset()
        AudioManager.playSFX(AudioManager.SFX.JUMP) -- Positive sound
    else
        -- Win!
        currentState = GameState.WIN
        AudioManager.stopMusic()
        AudioManager.playSFX(AudioManager.SFX.CRANK)
    end
end


function startGame()
    currentState = GameState.PLAYING
    currentLevel = 1
    gfx.sprite.removeAll()
    
    Level.load(currentLevel)
    playerInstance = Player(Level.spawnX, Level.spawnY)
    Particles.reset()
    AudioManager.playMusic()
end

function gameOver()
    currentState = GameState.GAMEOVER
    AudioManager.stopMusic()
    AudioManager.playSFX(AudioManager.SFX.IMPACT)
end

function drawGrid()
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    -- Simple grid for blueprint look
    for x = 0, 400, 20 do
        gfx.drawLine(x, 0, x, 240)
    end
    for y = 0, 240, 20 do
        gfx.drawLine(0, y, 400, y)
    end
end
