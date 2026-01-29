local pd = playdate
local gfx = pd.graphics
import "deck"
import "player"
import "card"

class('Game').extends()

function Game:init(mode)
    self.mode = mode -- "single" or "hotseat"
    self.deck = Deck()
    self.discardPile = {}
    self.players = {}
    
    -- Setup Players
    if self.mode == "hotseat" then
        table.insert(self.players, Player("Player 1", false))
        table.insert(self.players, Player("Player 2", false))
        self.state = "TRANSITION" -- Start by asking P1 to get ready
    else
        -- Single Player (1 Human vs 3 CPU)
        table.insert(self.players, Player("You", false))
        table.insert(self.players, Player("CPU 1", true))
        table.insert(self.players, Player("CPU 2", true))
        table.insert(self.players, Player("CPU 3", true))
        self.state = "PLAYING"
    end
    
    self.currentPlayerIndex = 1
    self.direction = 1
    self.gameOver = false
    self.winner = nil
    
    -- Deal 7 cards to each
    for _, player in ipairs(self.players) do
        for i=1, 7 do
            self:drawCardForPlayer(player)
        end
    end
    
    -- Flip first card
    local firstCard = self.deck:draw()
    while firstCard.type == Card.TYPE_WILD4 do -- Reshuffle if Wild 4
         self.deck.cards = {firstCard} -- Put back
         self.deck:shuffle()
         firstCard = self.deck:draw()
    end
    table.insert(self.discardPile, firstCard)
    
    -- Valid first card
    self.topCard = firstCard
    
    -- UI State
    self.selectedCardIndex = 1
    self.message = "Game Start!"
    self.messageTimer = 0
end

function Game:drawCardForPlayer(player)
    local card = self.deck:draw()
    if not card then
        self:reshuffleDiscard()
        card = self.deck:draw()
    end
    if card then
        player:addCard(card)
    end
end

function Game:reshuffleDiscard()
    if #self.discardPile <= 1 then return end
    
    local top = table.remove(self.discardPile) -- Keep top
    
    for _, card in ipairs(self.discardPile) do
        if card.type == Card.TYPE_WILD or card.type == Card.TYPE_WILD4 then
            card.color = Card.COLOR_WILD -- Reset wild color
        end
        table.insert(self.deck.cards, card)
    end
    self.discardPile = {top}
    self.deck:shuffle()
end

function Game:update()
    if self.state == "TRANSITION" then
        if pd.buttonJustPressed(pd.kButtonA) then
            self.state = "PLAYING"
            self.message = "Turn Start!"
            self.messageTimer = 30
        end
        return
    end

    if self.gameOver then
        if pd.buttonJustPressed(pd.kButtonA) then
            return "QUIT" -- Go back to menu
        end
        return
    end

    local currentPlayer = self.players[self.currentPlayerIndex]
    
    if currentPlayer.isAI then
        -- AI Turn
        self:handleAITurn(currentPlayer)
    else
        -- Human Turn
        self:handleHumanInput(currentPlayer)
    end
    
    if self.messageTimer > 0 then
        self.messageTimer -= 1
        if self.messageTimer == 0 then self.message = "" end
    end
end

function Game:handleHumanInput(player)
    if pd.buttonJustPressed(pd.kButtonLeft) then
        self.selectedCardIndex -= 1
        if self.selectedCardIndex < 1 then self.selectedCardIndex = #player.hand end
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        self.selectedCardIndex += 1
        if self.selectedCardIndex > #player.hand then self.selectedCardIndex = 1 end
    end
    
    if pd.buttonJustPressed(pd.kButtonA) then
        local card = player.hand[self.selectedCardIndex]
        if card and card:matches(self.topCard) then
            self:playCard(player, self.selectedCardIndex)
        else
            self:showMessage("Cannot play that card!")
        end
    elseif pd.buttonJustPressed(pd.kButtonB) then
        -- Draw card
        self:drawCardForPlayer(player)
        self:showMessage("Drew a card")
        self:nextTurn()
    end
end

function Game:handleAITurn(player)
    -- Simple delay simulation
    -- In real game, use timer, but for now instant or fast
    
    local index = player:aiChooseCard(self.topCard)
    if index then
        self:playCard(player, index)
    else
        self:drawCardForPlayer(player)
        self:showMessage(player.name .. " drew a card")
        self:nextTurn()
    end
end

function Game:playCard(player, index)
    local card = player:removeCard(index)
    self.topCard = card
    table.insert(self.discardPile, card)
    
    if #player.hand == 0 then
        self.gameOver = true
        self.winner = player.name
        self:showMessage(player.name .. " Wins!")
        return
    end
    
    -- Handle Special Cards
    if card.type == Card.TYPE_SKIP then
        self:showMessage("Skip!")
        self:advancePlayerIndex() -- Skip next
    elseif card.type == Card.TYPE_REVERSE then
        self:showMessage("Reverse!")
        self.direction *= -1
        if #self.players == 2 then self:advancePlayerIndex() end -- In 2 player, reverse is skip
    elseif card.type == Card.TYPE_DRAW2 then
        self:showMessage("Draw 2!")
        local victimIndex = self:getNextPlayerIndex()
        local victim = self.players[victimIndex]
        self:drawCardForPlayer(victim)
        self:drawCardForPlayer(victim)
        self:advancePlayerIndex() -- Skip victim
    elseif card.type == Card.TYPE_WILD then
        self:handleWild(player, card)
    elseif card.type == Card.TYPE_WILD4 then
        self:showMessage("Wild +4!")
        self:handleWild(player, card)
        local victimIndex = self:getNextPlayerIndex()
        local victim = self.players[victimIndex]
        for i=1, 4 do self:drawCardForPlayer(victim) end
        self:advancePlayerIndex()
    end
    
    self:nextTurn()
end

function Game:handleWild(player, card)
    -- If Human, need menu to pick color. For now, random or fixed for MVP
    -- For AI, pick random or most abundant
    
    if player.isAI then
        local colors = {Card.COLOR_RED, Card.COLOR_GREEN, Card.COLOR_BLUE, Card.COLOR_YELLOW}
        card.color = colors[math.random(4)]
    else
        -- Only supporting random for human in MVP first pass to ensure compilation
        -- TODO: Add Color Picker UI
        local colors = {Card.COLOR_RED, Card.COLOR_GREEN, Card.COLOR_BLUE, Card.COLOR_YELLOW}
        card.color = colors[math.random(4)] 
    end
    self:showMessage("Color set to " .. self:getColorName(card.color))
end

function Game:getColorName(color)
    if color == Card.COLOR_RED then return "Red"
    elseif color == Card.COLOR_GREEN then return "Green"
    elseif color == Card.COLOR_BLUE then return "Blue"
    elseif color == Card.COLOR_YELLOW then return "Yellow"
    end
    return "Wild"
end

function Game:advancePlayerIndex()
    self.currentPlayerIndex = self.currentPlayerIndex + self.direction
    if self.currentPlayerIndex > #self.players then self.currentPlayerIndex = 1 end
    if self.currentPlayerIndex < 1 then self.currentPlayerIndex = #self.players end
end

function Game:getNextPlayerIndex()
    local nextIdx = self.currentPlayerIndex + self.direction
    if nextIdx > #self.players then nextIdx = 1 end
    if nextIdx < 1 then nextIdx = #self.players end
    return nextIdx
end

function Game:nextTurn()
    self:advancePlayerIndex()
    
    -- Reset selection for human
    if not self.players[self.currentPlayerIndex].isAI then
        self.selectedCardIndex = 1
    end

    if self.mode == "hotseat" then
        self.state = "TRANSITION"
    end
end

function Game:showMessage(msg)
    self.message = msg
    self.messageTimer = 60 -- 2 seconds at 30fps
end

function Game:draw()
    gfx.clear()
    
    if self.state == "TRANSITION" then
        local padding = 50
        gfx.fillRect(padding, 60, 400 - padding*2, 120)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(padding+2, 60+2, 400 - padding*2 - 4, 120 - 4)
        gfx.setColor(gfx.kColorBlack)
        
        gfx.drawTextInRect("Pass Device to:", padding+10, 80, 200, 30, nil, kTextAlignment.center)
        gfx.drawTextInRect("*" .. self.players[self.currentPlayerIndex].name .. "*", padding+10, 110, 200, 30, nil, kTextAlignment.center)
        gfx.drawTextInRect("Press A when ready", padding+10, 140, 200, 30, nil, kTextAlignment.center)
        return
    end

    -- Draw Top Card
    self.topCard:draw(180, 100, true)
    gfx.drawText("Pile", 180, 80)
    
    -- Draw Info
    gfx.drawText("Turn: " .. self.players[self.currentPlayerIndex].name, 10, 10)
    
    -- Moved message to top right to avoid hand overlap
    gfx.drawText(self.message, 200, 10) 
    
    if self.gameOver then
        local popupW = 260
        local popupH = 100
        local popupX = (400 - popupW) / 2
        local popupY = (240 - popupH) / 2
        
        -- Draw Popup Background
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(popupX, popupY, popupW, popupH)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(popupX, popupY, popupW, popupH)
        
        -- Draw Text
        local text = "GAME OVER\n" .. self.winner .. " Wins!\n\nPress A to Menu"
        gfx.drawTextInRect(text, popupX, popupY + 20, popupW, popupH, nil, kTextAlignment.center)
        return
    end

    -- Draw Hand (Human only visible)
    local currentPlayer = self.players[self.currentPlayerIndex]
    
    -- Only draw hand if it's a human player (or if we want to debug)
    -- In Hotseat, we show current player's hand.
    if not currentPlayer.isAI then
        local handX = 10
        local handY = 180
        local spacing = 25
        
        for i, card in ipairs(currentPlayer.hand) do
            local yOffset = 0
            if i == self.selectedCardIndex then yOffset = -10 end -- Highlight selected
            card:draw(handX + (i-1)*spacing, handY + yOffset, true)
        end
    else
        -- Draw AI HUD?
        gfx.drawText("Thinking...", 10, 220)
    end
    
    -- Draw Opponent counts
    if self.mode == "single" then
        gfx.drawText(self.players[2].name .. ": " .. #self.players[2].hand, 10, 40)
        gfx.drawText(self.players[3].name .. ": " .. #self.players[3].hand, 150, 40)
        gfx.drawText(self.players[4].name .. ": " .. #self.players[4].hand, 300, 40)
    else
        -- Hotseat opponent info
        local otherIndex = (self.currentPlayerIndex == 1) and 2 or 1
        gfx.drawText(self.players[otherIndex].name .. ": " .. #self.players[otherIndex].hand, 10, 40)
    end
end
