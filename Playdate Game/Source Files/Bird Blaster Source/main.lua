import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "crosshair"
import "duck"
import "dog"

local gfx = playdate.graphics

local gameState = "START" -- START, ROUND, DOG_SHOW
local crosshair = nil
local dog = nil
local ducks = {}

local round = 1
local ammo = 3
local ducksHit = 0
local ducksSpawned = 0
local maxDucksPerRound = 10
local requiredToWin = 6
local dogMessage = ""

local currentDuck = nil -- Single duck for now (classic mode)

function initGame()
    gfx.sprite.removeAll()
    crosshair = Crosshair()
    dog = Dog()
    
    round = 1
    startRound()
end

function startRound()
    ducksHit = 0
    ducksSpawned = 0
    nextDuck()
end

function nextDuck()
    if ducksSpawned >= maxDucksPerRound then
        endRound()
        return
    end
    
    ducksSpawned = ducksSpawned + 1
    ammo = 3
    currentDuck = Duck()
    gameState = "ROUND"
end

function endRound()
    if ducksHit >= requiredToWin then
        -- Win Round
        round = round + 1
        -- Increase difficulty?
        requiredToWin = math.min(maxDucksPerRound, requiredToWin + 1)
        
        gameState = "ROUND_TRANSITION"
        playdate.timer.performAfterDelay(2000, startRound)
    else
        gameState = "GAME_OVER"
    end
end

function playdate.update()
    gfx.clear()
    
    -- Draw Background
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, 400, 240)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 200, 400, 40) -- Ground
    
    if gameState == "START" then
        gfx.setColor(gfx.kColorBlack)
        gfx.drawText("Bird Blaster", 155, 80)
        gfx.drawText("Round " .. round, 170, 110)
        gfx.drawText("Press A to Start", 145, 140)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            initGame()
        end
        
    elseif gameState == "ROUND" then
        updateRound()
        
    elseif gameState == "DOG_SHOW" then
        gfx.sprite.update()
        
        -- Text Overlay for clarity (Moved higher to not cover dog)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(145, 140, 110, 20)
        
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawText(dogMessage, 150, 142)
    elseif gameState == "ROUND_TRANSITION" then
         gfx.clear()
         gfx.setImageDrawMode(gfx.kDrawModeCopy)
         gfx.drawText("ROUND " .. round, 160, 100)
         if round > 1 then
             gfx.drawText("Target: " .. requiredToWin, 150, 130)
         end
    end
    
    playdate.timer.updateTimers()
end

function updateRound()
    crosshair:update()
    
    if currentDuck then
        currentDuck:update()
        
        -- Missed (Despawned)
        if currentDuck.state == "DEAD" then
             dogMessage = "MISSED!"
             dog:show("LAUGH")
             gameState = "DOG_SHOW"
             currentDuck = nil
             playdate.timer.performAfterDelay(2000, nextDuck)
             return
        end
    end
    
    -- Shooting
    if playdate.buttonJustPressed(playdate.kButtonA) and ammo > 0 then
        fireShot()
    end
    
    gfx.sprite.update()
    
    -- HUD Background
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 210, 400, 30)
    
    -- Text (White on Black)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText("R=" .. round, 10, 215)
    gfx.drawText("Shot=" .. ammo, 100, 215)
    gfx.drawText("Hit=" .. ducksHit .. "/" .. maxDucksPerRound, 300, 215)
    gfx.setImageDrawMode(gfx.kDrawModeCopy) -- Reset
end

function fireShot()
    ammo = ammo - 1
    playdate.display.setInverted(true)
    playdate.timer.performAfterDelay(50, function() playdate.display.setInverted(false) end)
    
    local cx, cy = crosshair:getPosition()
    local dx, dy = currentDuck:getPosition()
    
    if currentDuck.state == "FLY" and math.abs(cx - dx) < 20 and math.abs(cy - dy) < 20 then
        currentDuck:hit()
        ducksHit = ducksHit + 1
        
        playdate.timer.performAfterDelay(1000, function()
             dogMessage = "GOT IT!"
             dog:show("CATCH")
             gameState = "DOG_SHOW"
             playdate.timer.performAfterDelay(2000, nextDuck)
        end)
    else
        -- MISS check empty
         if ammo == 0 then
             -- No ammo left, duck flies away
             currentDuck.state = "FLY"
             currentDuck.dy = -4 -- Fly away
             -- Will eventually hit boundary and trigger miss logic in updateRound
        end
    end
end
