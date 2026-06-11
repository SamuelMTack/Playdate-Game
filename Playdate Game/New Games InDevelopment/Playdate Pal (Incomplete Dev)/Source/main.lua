import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"

local pd = playdate
local gfx = pd.graphics

import "pet"
import "ui"

local myPet = Pet.new()

-- Initialization
myPet:loadData()

function playdate.update()
    gfx.clear()
    
    -- Inputs
    local action = UI.update()
    if action then
        if action == "feed" then myPet:feed()
        elseif action == "play" then myPet:play()
        elseif action == "clean" then myPet:clean()
        elseif action == "toggleSleep" then myPet:toggleSleep()
        end
    end
    
    -- Update
    myPet:update()
    
    -- Draw
    myPet:draw()
    UI.draw(myPet)
    
    -- Auto-save logic? 
    -- Best to save on terminate, but maybe periodically too in case of crash
    if pd.getCurrentTimeMilliseconds() % 30000 < 50 then
        -- Optional: periodical save
    end
end

function playdate.gameWillTerminate()
    myPet:saveData()
end

function playdate.deviceWillSleep()
    myPet:saveData()
end
