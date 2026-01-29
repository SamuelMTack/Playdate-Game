import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics

import "fishing"
import "ui"

-- Persisted Data
local DATA_FILE = "highscore.json"
GlobalData = {
    highScore = 0
}

function loadData()
    local data = playdate.datastore.read(DATA_FILE)
    if data then
        GlobalData = data
    end
end

function saveData()
    playdate.datastore.write(GlobalData, DATA_FILE)
end

-- Game State
STATE = {
    TITLE = 1,
    GAME = 2
}
currentState = STATE.TITLE

-- Init
loadData()
math.randomseed(playdate.getSecondsSinceEpoch())

function playdate.update()
    gfx.clear()
    
    if currentState == STATE.TITLE then
        UI.drawTitle()
        if playdate.buttonJustPressed(playdate.kButtonA) then
            Fishing.reset()
            currentState = STATE.GAME
        end
    elseif currentState == STATE.GAME then
        Fishing.update()
        Fishing.draw()
    end
    
    playdate.timer.updateTimers()
end
