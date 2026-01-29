local pd = playdate
import "card"

class('Player').extends()

function Player:init(name, isAI)
    self.name = name
    self.isAI = isAI
    self.hand = {}
end

function Player:addCard(card)
    table.insert(self.hand, card)
end

function Player:removeCard(index)
    return table.remove(self.hand, index)
end

function Player:hasPlayableCard(topCard)
    for i, card in ipairs(self.hand) do
        if card:matches(topCard) then
            return true
        end
    end
    return false
end

-- Returns index of card to play, or nil if none/drawing
function Player:aiChooseCard(topCard)
    -- Simple AI: Play first matching card
    -- If Wild, pick random color
    
    local bestCardIndex = nil
    
    for i, card in ipairs(self.hand) do
        if card:matches(topCard) then
            -- Prioritize Action cards if we want, but for now just pick first
            bestCardIndex = i
            break
        end
    end
    
    return bestCardIndex
end

function Player:getHandCount()
    return #self.hand
end
