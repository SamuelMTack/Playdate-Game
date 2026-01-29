local pd = playdate
import "card"

class('Deck').extends()

function Deck:init()
    self.cards = {}
    self:generate()
    self:shuffle()
end

function Deck:generate()
    self.cards = {}
    local colors = {Card.COLOR_RED, Card.COLOR_GREEN, Card.COLOR_BLUE, Card.COLOR_YELLOW}
    
    for _, color in ipairs(colors) do
        -- 0 (one per color)
        table.insert(self.cards, Card(color, Card.TYPE_NUMBER, 0))
        
        -- 1-9 (two per color)
        for i=1, 9 do
            table.insert(self.cards, Card(color, Card.TYPE_NUMBER, i))
            table.insert(self.cards, Card(color, Card.TYPE_NUMBER, i))
        end
        
        -- Actions (two per color)
        for i=1, 2 do
            table.insert(self.cards, Card(color, Card.TYPE_SKIP, nil))
            table.insert(self.cards, Card(color, Card.TYPE_REVERSE, nil))
            table.insert(self.cards, Card(color, Card.TYPE_DRAW2, nil))
        end
    end
    
    -- Wilds (4 each)
    for i=1, 4 do
        table.insert(self.cards, Card(Card.COLOR_WILD, Card.TYPE_WILD, nil))
        table.insert(self.cards, Card(Card.COLOR_WILD, Card.TYPE_WILD4, nil))
    end
end

function Deck:shuffle()
    for i = #self.cards, 2, -1 do
        local j = math.random(i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
end

function Deck:draw()
    if #self.cards == 0 then
        return nil -- Handle reshuffle in Game class preferably, or here
    end
    return table.remove(self.cards)
end

function Deck:addCount()
    return #self.cards
end
