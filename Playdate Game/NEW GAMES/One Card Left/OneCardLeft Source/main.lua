import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics

import "card"
import "deck"
import "player"
import "menu"
import "game"

-- Global game states
MenuInstance = nil
GameInstance = nil
CurrentState = "MENU" -- MENU or GAME

function playdate.update()
    gfx.sprite.update()
    playdate.timer.updateTimers()
    
    if CurrentState == "MENU" then
        if not MenuInstance then MenuInstance = Menu() end
        local selection = MenuInstance:update()
        MenuInstance:draw()
        
        if selection then
            MenuInstance = nil
            GameInstance = Game(selection)
            CurrentState = "GAME"
        end
        
    elseif CurrentState == "GAME" then
        if GameInstance then
            local result = GameInstance:update()
            if result == "QUIT" then
                GameInstance = nil
                CurrentState = "MENU"
            else
                GameInstance:draw()
            end
        else
            -- Should not happen, but recover
            CurrentState = "MENU"
        end
    end
end
