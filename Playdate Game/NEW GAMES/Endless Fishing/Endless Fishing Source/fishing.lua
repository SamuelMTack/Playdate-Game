local gfx = playdate.graphics
import "fish"

Fishing = {}

Fishing.STATE = {
    CASTING = 1,
    WAITING = 2,
    HOOKED = 3,
    REELING = 4,
    RESULT = 5
}

Fishing.currentState = Fishing.STATE.CASTING
Fishing.bobberY = 0
Fishing.bobberX = 200
Fishing.lineLength = 0
Fishing.tension = 0
Fishing.maxTension = 100
Fishing.currentFish = nil
Fishing.message = ""

function Fishing.reset()
    Fishing.currentState = Fishing.STATE.CASTING
    Fishing.lineLength = 0
    Fishing.tension = 0
    Fishing.currentFish = nil
    Fishing.currentFish = nil
    Fishing.message = ""
    Fishing.resultTimer = 0
end

function Fishing.update()
    if Fishing.currentState == Fishing.STATE.CASTING then
        -- Simple animation of casting
        Fishing.lineLength = Fishing.lineLength + 5
        if Fishing.lineLength > 150 then
            Fishing.currentState = Fishing.STATE.WAITING
            Fishing.waitTime = math.random(60, 180) -- 2-6 seconds
        end
        
    elseif Fishing.currentState == Fishing.STATE.WAITING then
        Fishing.waitTime = Fishing.waitTime - 1
        if Fishing.waitTime <= 0 then
            Fishing.currentState = Fishing.STATE.HOOKED
            Fishing.currentFish = Fish(math.random(1, 10)) -- Level/Difficulty
        end
        
    elseif Fishing.currentState == Fishing.STATE.HOOKED then
        Fishing.message = "FISH ON! CRANK!"
        -- Auto transition to reeling if player cranks
        local change = math.abs(playdate.getCrankChange())
        if change > 5 then
            Fishing.currentState = Fishing.STATE.REELING
            Fishing.message = ""
        end
        
    elseif Fishing.currentState == Fishing.STATE.REELING then
        if not Fishing.currentFish then return end
        
        local crankChange = playdate.getCrankChange() -- Can be pos or neg depending on direction
        local reelSpeed = math.abs(crankChange)
        
        -- Fish fight logic
        Fishing.currentFish:update()
        
        -- Tension Calculation
        -- Tension increases with Reel Speed AND Fish Pulling
        -- Tension decreases over time naturally
        
        local tensionAdd = 0
        if reelSpeed > 0 then
            tensionAdd = reelSpeed * 0.2 -- Reduced from 0.5
        end
        
        if Fishing.currentFish.isPulling then
            tensionAdd = tensionAdd + (Fishing.currentFish.strength * 1.5) -- Reduced from 2
            -- If pulling and reeling, MASSIVE tension
            if reelSpeed > 5 then
                tensionAdd = tensionAdd + 3 -- Reduced from 5
            end
        else
            -- Fish tired, reeling reduces tension slightly or stays neutral
             tensionAdd = tensionAdd * 0.3 -- Reduced from 0.5
        end
        
        Fishing.tension = Fishing.tension + tensionAdd - 4 -- Increased decay from 2 to 4
        if Fishing.tension < 0 then Fishing.tension = 0 end
        
        -- Check Snap
        -- Check Snap
        if Fishing.tension >= Fishing.maxTension then
            Fishing.message = "SNAP! Line Broke!"
            Fishing.currentState = Fishing.STATE.RESULT
            Fishing.resultTimer = 30 -- Short delay (0.5s - 1s) to read msg before allowing reset
            -- Remove blocking wait
        end
        
        -- Move fish closer
        if reelSpeed > 0 then
            Fishing.lineLength = Fishing.lineLength - (reelSpeed * 0.1)
        end
        
        -- Fish pulls line out
        if Fishing.currentFish.isPulling then
             Fishing.lineLength = Fishing.lineLength + (Fishing.currentFish.strength * 0.05)
        end
        
        if Fishing.lineLength <= 0 then
            Fishing.catchSuccess()
        end
    elseif Fishing.currentState == Fishing.STATE.RESULT then
        if Fishing.resultTimer > 0 then
            Fishing.resultTimer = Fishing.resultTimer - 1
        elseif playdate.buttonJustPressed(playdate.kButtonA) then
            Fishing.reset()
        end
    end
end

function Fishing.catchSuccess()
    Fishing.currentState = Fishing.STATE.RESULT
    Fishing.message = "CAUGHT IT! " .. Fishing.currentFish.weight .. " lbs"
    
    if Fishing.currentFish.weight > GlobalData.highScore then
        GlobalData.highScore = Fishing.currentFish.weight
        saveData()
        Fishing.message = Fishing.message .. "\nNEW RECORD!"
    end
end

function Fishing.draw()
    UI.drawFishing()
end
