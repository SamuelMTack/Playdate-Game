local pd = playdate
local gfx = pd.graphics

class('Menu').extends()

function Menu:init()
    self.options = {"Single Player", "Hotseat (2P)"}
    self.selectedOption = 1
end

function Menu:update()
    if pd.buttonJustPressed(pd.kButtonUp) then
        self.selectedOption -= 1
        if self.selectedOption < 1 then self.selectedOption = #self.options end
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        self.selectedOption += 1
        if self.selectedOption > #self.options then self.selectedOption = 1 end
    elseif pd.buttonJustPressed(pd.kButtonA) then
        local mode = (self.selectedOption == 1) and "single" or "hotseat"
        return mode
    end
    return nil
end

function Menu:draw()
    gfx.clear()
    
    gfx.drawText("One Card Left", 140, 50)
    
    for i, option in ipairs(self.options) do
        local prefix = (i == self.selectedOption) and "> " or "  "
        gfx.drawText(prefix .. option, 140, 100 + (i-1)*30)
    end
    
    gfx.drawText("Use D-pad to select, A to start", 80, 220)
end
