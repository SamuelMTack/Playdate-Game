import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics

-- Import Constants (Global Consts)
import "consts"

-- Import Systems (Global Modules)
import "systems/overworld"
import "systems/battle"
import "systems/quest"
import "systems/inventory"
import "systems/ui"
import "systems/gamestate"

function playdate.update()
    gfx.clear(gfx.kColorWhite)
    playdate.timer.updateTimers()
    
    if GameState.current == GameState.TYPES.OVERWORLD then
        Overworld.update()
        gfx.sprite.update() -- Necessary to draw the Player Sprite
        if UI then UI.drawOverlay() end
    elseif GameState.current == GameState.TYPES.BATTLE then
        Battle.update()
    elseif GameState.current == GameState.TYPES.MENU then
        UI.updateMenu()
    end
    
    playdate.drawFPS(0,0)
end

-- Input handling
function playdate.AButtonDown()
    if GameState.current == GameState.TYPES.OVERWORLD then
        Overworld.handleInput("A")
    elseif GameState.current == GameState.TYPES.BATTLE then
        Battle.handleInput("A")
    end
end

function playdate.BButtonDown()
    if GameState.current == GameState.TYPES.OVERWORLD or GameState.current == GameState.TYPES.MENU then
        -- Toggle Quest Menu
        UI.toggleQuestMenu()
    elseif GameState.current == GameState.TYPES.BATTLE then
        Battle.handleInput("B")
    end
end
