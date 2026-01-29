local pd = playdate
local gfx = pd.graphics

class('Card').extends()

Card.COLOR_RED = 1
Card.COLOR_GREEN = 2
Card.COLOR_BLUE = 3
Card.COLOR_YELLOW = 4
Card.COLOR_WILD = 5

Card.TYPE_NUMBER = 1
Card.TYPE_SKIP = 2
Card.TYPE_REVERSE = 3
Card.TYPE_DRAW2 = 4
Card.TYPE_WILD = 5
Card.TYPE_WILD4 = 6

function Card:init(color, type, value)
    self.color = color
    self.type = type
    self.value = value -- 0-9 for numbers, nil or ignored for others usually
    self.width = 40
    self.height = 60
end

function Card:draw(x, y, isFaceUp)
    -- Simple drawing logic for now
    local rect = pd.geometry.rect.new(x, y, self.width, self.height)
    
    if not isFaceUp then
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(x, y, self.width, self.height)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(x, y, self.width, self.height)
        return
    end

    -- Background
    if self.color == Card.COLOR_RED then gfx.setColor(gfx.kColorBlack) -- Simple stand-in, hatched?
    elseif self.color == Card.COLOR_GREEN then gfx.setColor(gfx.kColorWhite)
    end
    -- For now just draw outline and text
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(x, y, self.width, self.height)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(x, y, self.width, self.height)

    local text = ""
    if self.type == Card.TYPE_NUMBER then text = tostring(self.value)
    elseif self.type == Card.TYPE_SKIP then text = "S"
    elseif self.type == Card.TYPE_REVERSE then text = "R"
    elseif self.type == Card.TYPE_DRAW2 then text = "+2"
    elseif self.type == Card.TYPE_WILD then text = "W"
    elseif self.type == Card.TYPE_WILD4 then text = "+4"
    end
    
    local colorName = ""
    if self.color == Card.COLOR_RED then colorName = "R"
    elseif self.color == Card.COLOR_GREEN then colorName = "G"
    elseif self.color == Card.COLOR_BLUE then colorName = "B"
    elseif self.color == Card.COLOR_YELLOW then colorName = "Y"
    elseif self.color == Card.COLOR_WILD then colorName = "*"
    end

    gfx.drawTextInRect(colorName .. "\n" .. text, x + 2, y + 20, self.width, 40, nil, kTextAlignment.center)
end

function Card:matches(other)
    -- Wilds always match
    if self.color == Card.COLOR_WILD or other.color == Card.COLOR_WILD then return true end
    -- Color match
    if self.color == other.color then return true end
    -- Value/Type match
    if self.type == other.type then
        if self.type == Card.TYPE_NUMBER then
            return self.value == other.value
        else
            return true -- Matching Actions/Wilds
        end
    end
    return false
end
