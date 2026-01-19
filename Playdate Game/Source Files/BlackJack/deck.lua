import "card"

class('Deck').extends()

function Deck:init()
    self.cards = {}
    self:reset()
end

function Deck:reset()
    self.cards = {}
    local suits = {"H", "D", "C", "S"}
    local ranks = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}
    
    for _, s in ipairs(suits) do
        for _, r in ipairs(ranks) do
            local val = 0
            if r == "A" then val = 11
            elseif r == "J" or r == "Q" or r == "K" then val = 10
            else val = tonumber(r) end
            
            table.insert(self.cards, {suit=s, rank=r, value=val})
            -- We store data, create Sprites only when dealt ideally to save memory?
            -- Or just pre-create. Let's store data and create Card objects on deal.
        end
    end
    self:shuffle()
end

function Deck:shuffle()
    for i = #self.cards, 2, -1 do
        local j = math.random(i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
end

function Deck:deal()
    if #self.cards == 0 then self:reset() end
    local data = table.remove(self.cards)
    return Card(data.suit, data.rank, data.value)
end
