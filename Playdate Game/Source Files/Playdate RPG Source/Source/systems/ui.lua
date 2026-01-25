local pd = playdate
local gfx = pd.graphics
import "consts"

import "gamestate"
import "quest"

UI = {}

local activePopup = nil

function UI.showLocationPopup(tileType, customText)
    local text = customText or ""
    if text == "" then
        if tileType == 4 then text = "You visit a quiet Village." end
        if tileType == 5 then text = "You approach a grand Castle." end
        if tileType == 6 then text = "A tall Tower stands here." end
        if tileType == 7 then text = "A dark Cave entrance." end
    end
    
    activePopup = {
        text = text,
        timer = 90 -- Show for 3 seconds
    }
end

function UI.updateMenu()
    gfx.clear()
    gfx.drawText("QUEST LOG", 150, 10)
    gfx.drawLine(0, 30, 400, 30)
    
    local y = 40
    
    -- Show Stats
    if Inventory then
        gfx.drawText("Inventory:", 20, y)
        gfx.drawText("+1 Mod: " .. Inventory.modifiers[1], 40, y+20)
        gfx.drawText("+2 Mod: " .. Inventory.modifiers[2], 150, y+20)
        gfx.drawText("+3 Mod: " .. Inventory.modifiers[3], 260, y+20)
        y = y + 50
    end
    
    for _, q in ipairs(Quest.activeQuests) do
        local status = q.completed and "[COMPLETED]" or ""
        local progress = "(" .. q.current .. "/" .. q.required .. ")"
        gfx.drawText(q.desc .. " " .. progress .. " " .. status, 20, y)
        y = y + 20
    end
    
    gfx.drawText("Press B to Return", 140, 220)
end

function UI.toggleQuestMenu()
    if GameState.current == GameState.TYPES.OVERWORLD then
        GameState.switch(GameState.TYPES.MENU)
    elseif GameState.current == GameState.TYPES.MENU then
        GameState.switch(GameState.TYPES.OVERWORLD)
    end
end

-- Hook into main update loop if we want global UI overlay
function UI.drawOverlay()
    if activePopup then
        local w, h = 300, 50
        local x = (Consts.SCREEN_WIDTH - w) / 2
        local y = Consts.SCREEN_HEIGHT - h - 20
        
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x, y, w, h)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(x, y, w, h)
        gfx.drawTextInRect(activePopup.text, x+10, y+10, w-20, h-20)
        
        activePopup.timer = activePopup.timer - 1
        if activePopup.timer <= 0 then
            activePopup = nil
        end
    end
end
