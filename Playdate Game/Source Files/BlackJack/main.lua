import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "deck"
import "card"

local gfx = playdate.graphics

local gameState = "START"
local deck = Deck() -- Create Deck
local playerHand = {}
local dealerHand = {}
local resultMessage = ""

local chips = 100
local currentBet = 10

function initGame()
    gfx.sprite.removeAll()
    deck:reset() 
    chips = 100
    currentBet = 10
    gameState = "BETTING"
end

function startRound()
    gfx.sprite.removeAll()
    playerHand = {}
    dealerHand = {}
    resultMessage = ""
    
    if chips < currentBet then currentBet = chips end
    if chips == 0 then 
        gameState = "BROKE" -- Handle Game Over specifically
        return
    end
    
    chips = chips - currentBet
    
    -- Deal initial cards
    hit(playerHand, false)
    hit(dealerHand, false)
    hit(playerHand, false)
    hit(dealerHand, true) 
    
    gameState = "PLAYER_TURN"
end

function hit(hand, hidden)
    local c = deck:deal()
    table.insert(hand, c)
    
    -- Positioning
    local startX = 50
    local y = 160 -- Player
    if hand == dealerHand then y = 85 end
    
    local spacing = 30
    local x = startX + (#hand - 1) * spacing
    
    c:addAt(x, y)
    
    -- If calculating bust immediately
    if hand == playerHand then
        local score = calculateScore(playerHand)
        if score > 21 then
            gameState = "GAME_OVER"
            resultMessage = "BUST! YOU LOSE."
        end
    end
end

function stand()
    gameState = "DEALER_TURN"
    
    local score = calculateScore(dealerHand)
    while score < 17 do
        hit(dealerHand, false)
        score = calculateScore(dealerHand)
    end
    
    determineWinner()
end

function determineWinner()
    local pScore = calculateScore(playerHand)
    local dScore = calculateScore(dealerHand)
    
    gameState = "GAME_OVER"
    
    if pScore > 21 then
        resultMessage = "BUST! YOU LOSE."
        -- Money already gone
    elseif dScore > 21 then
        resultMessage = "DEALER BUST! WIN!"
        chips = chips + (currentBet * 2)
    elseif pScore > dScore then
        resultMessage = "YOU WIN!"
        chips = chips + (currentBet * 2)
    elseif pScore < dScore then
        resultMessage = "DEALER WINS."
    else
        resultMessage = "PUSH (TIE)."
        chips = chips + currentBet
    end
end

function calculateScore(hand)
    local score = 0
    local aces = 0
    
    for _, c in ipairs(hand) do
        score = score + c.value
        if c.rank == "A" then aces = aces + 1 end
    end
    
    while score > 21 and aces > 0 do
        score = score - 10
        aces = aces - 1
    end
    
    return score
end

function playdate.update()
    gfx.clear()
    
    -- Background
    gfx.setPattern({0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55})
    gfx.fillRect(0, 0, 400, 240)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(3)
    gfx.drawRoundRect(2, 2, 396, 236, 5)
    
    -- Draw Sprites (Cards) BELOW UI
    gfx.sprite.update()
    
    -- Always show Chips & Bet info unless on Start Screen
    if gameState ~= "START" then
         drawCenteredBox(120, 5, 160, 30)
         -- Draw Chips (Left) and Bet (Right)
         local info = "Chips: $" .. chips .. "  Bet: $" .. currentBet
         local w, h = gfx.getTextSize(info)
         gfx.drawText(info, 200 - w/2, 12)
    end
    
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    
    if gameState == "START" then
        drawCenteredBox(120, 80, 160, 80)
        gfx.drawText("* BLACKJACK *", 155, 95)
        gfx.drawText("Press A to Start", 150, 125)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            initGame()
        end
        
    elseif gameState == "BETTING" then
        drawCenteredBox(100, 80, 200, 100)
        gfx.drawText("PLACE YOUR BET", 145, 90)
        gfx.drawText("$" .. currentBet, 190, 120)
        
        gfx.drawText("UP/DOWN to Change", 130, 145)
        gfx.drawText("A to DEAL", 165, 165)
        
        if playdate.buttonJustPressed(playdate.kButtonUp) and (currentBet + 10) <= chips then
            currentBet = currentBet + 10
        elseif playdate.buttonJustPressed(playdate.kButtonDown) and (currentBet - 10) >= 10 then
            currentBet = currentBet - 10
        end
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startRound()
        end
        
    elseif gameState == "PLAYER_TURN" then
        -- UI Panels
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(5, 5, 100, 40, 5) 
        gfx.fillRoundRect(5, 195, 100, 40, 5) 
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(5, 5, 100, 40, 5)
        gfx.drawRoundRect(5, 195, 100, 40, 5)
        
        displayScores()
        
        -- Action Panel
        drawCenteredBox(290, 180, 105, 55)
        gfx.drawText("A: HIT", 310, 190)
        gfx.drawText("B: STAND", 310, 210)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            hit(playerHand, false)
        elseif playdate.buttonJustPressed(playdate.kButtonB) then
            stand()
        end
        
    elseif gameState == "DEALER_TURN" then
         -- UI Panels
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(5, 5, 100, 40, 5) 
        gfx.fillRoundRect(5, 195, 100, 40, 5) 
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(5, 5, 100, 40, 5)
        gfx.drawRoundRect(5, 195, 100, 40, 5)
        
        displayScores()
        gfx.drawText("DEALER...", 300, 20)
        
    elseif gameState == "GAME_OVER" then
        -- UI Panels
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(5, 5, 100, 40, 5) 
        gfx.fillRoundRect(5, 195, 100, 40, 5) 
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(5, 5, 100, 40, 5)
        gfx.drawRoundRect(5, 195, 100, 40, 5)
        displayScores()
        
        drawCenteredBox(80, 90, 240, 70)
        
        -- Center Result Text
        local w, h = gfx.getTextSize(resultMessage)
        gfx.drawText(resultMessage, 200 - w/2, 105)
        
        gfx.drawText("DOWN to Continue", 140, 135)
        
        if playdate.buttonJustPressed(playdate.kButtonDown) then
            if chips > 0 then
                gameState = "BETTING"
            else
                gameState = "BROKE"
            end
        end
    elseif gameState == "BROKE" then
        drawCenteredBox(80, 80, 240, 80)
        gfx.drawText("YOU ARE BROKE!", 145, 100)
        gfx.drawText("Restarting...", 160, 130)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            initGame()
        end
    end
end

function drawCenteredBox(x, y, w, h)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(x, y, w, h, 5)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(x, y, w, h, 5)
end

function displayScores()
    gfx.drawText("Dealer: " .. calculateScore(dealerHand), 15, 15)
    gfx.drawText("Player: " .. calculateScore(playerHand), 15, 205)
end
