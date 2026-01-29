local pd = playdate
local gfx = pd.graphics

UI = {}

-- Menu Items
local MENU = {
    {name="Feed", key="feed"},
    {name="Play", key="play"},
    {name="Clean", key="clean"},
    {name="Sleep", key="toggleSleep"}
}

local currentSelection = 1

function UI.update()
    if pd.buttonJustPressed(pd.kButtonLeft) then
        currentSelection = currentSelection - 1
        if currentSelection < 1 then currentSelection = #MENU end
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        currentSelection = currentSelection + 1
        if currentSelection > #MENU then currentSelection = 1 end
    end
    
    if pd.buttonJustPressed(pd.kButtonA) then
        return MENU[currentSelection].key
    end
    
    return nil
end

function UI.draw(pet)
    gfx.setLineWidth(1)
    
    -- Draw Stats Top
    local y = 5
    gfx.drawText(string.format("Hunger: %.0f%%", pet.stats.hunger), 5, y)
    gfx.drawText(string.format("Happy: %.0f%%", pet.stats.happiness), 105, y)
    gfx.drawText(string.format("Energy: %.0f%%", pet.stats.energy), 205, y)
    gfx.drawText(string.format("Hygiene: %.0f%%", pet.stats.hygiene), 305, y)
    
    -- Draw Menu Bottom
    local menuY = 210
    local width = 400 / #MENU
    
    for i, item in ipairs(MENU) do
        local x = (i-1) * width
        
        if i == currentSelection then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(x, menuY, width, 30)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        else
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
        
        gfx.drawRect(x, menuY, width, 30)
        gfx.drawTextAligned(item.name, x + width/2, menuY + 8, kTextAlignment.center)
        
        gfx.setColor(gfx.kColorBlack) -- Reset color
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end
