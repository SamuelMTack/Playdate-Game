local pd = playdate
local gfx = pd.graphics

import "gamestate"
import "inventory"
import "quest"
import "consts"
import "../data/sprites"
import "sound"

Battle = {}

local PHASE = {
    START = 1,
    MENU = 2,
    ROLLING = 3,
    RESULT = 4,
    WIN = 5,
    LOSE = 6
}

local currentPhase = PHASE.START
local playerRoll = 0
local enemyRoll = 0
local enemyType = nil
local activeModifier = 0

local enemySprite = nil

function Battle.start(enemy)
    currentPhase = PHASE.START
    enemyType = enemy
    activeModifier = 0
    GameState.switch(GameState.TYPES.BATTLE)
    
    if Sound then Sound.playBattleMusic() end
    
    if not enemySprite then
         -- Procedural Sprite
         enemySprite = Sprites.createEnemy()
    end
end

function Battle.update()
    gfx.drawText("BATTLE!", 150, 20)
    
    -- Draw Enemy
    if enemySprite then
        enemySprite:draw(168, 60)
    end
    
    if currentPhase == PHASE.START then
        gfx.drawText("Enemy: " .. (enemyType and enemyType.name or "Monster"), 120, 140)
        gfx.drawText("Press A to Start", 140, 200)
        
    elseif currentPhase == PHASE.MENU then
        gfx.drawText("Choose Action:", 20, 140)
        gfx.drawText("(A) ROLL DICE", 40, 160)
        
        gfx.drawText("Modifiers (B to Cycle):", 20, 190)
        local modText = "None"
        if activeModifier > 0 then modText = "+" .. activeModifier end
        gfx.drawText("Active: " .. modText, 40, 210)
        
        -- Show counts
        gfx.drawText("+1: x" .. Inventory.modifiers[1], 250, 190)
        gfx.drawText("+2: x" .. Inventory.modifiers[2], 250, 205)
        gfx.drawText("+3: x" .. Inventory.modifiers[3], 250, 220)
        
    elseif currentPhase == PHASE.ROLLING then
        local r1 = math.random(1, 6)
        local r2 = math.random(1, 6)
        gfx.drawText("Player: " .. r1, 50, 160)
        gfx.drawText("Enemy: " .. r2, 300, 160)
    elseif currentPhase == PHASE.RESULT then
        gfx.drawText("Player: " .. playerRoll .. " (+" .. activeModifier .. ") = " .. (playerRoll+activeModifier), 20, 160)
        
        gfx.drawText("Enemy: " .. enemyRoll, 280, 160)
        
        local totalPlayer = playerRoll + activeModifier
        
        if totalPlayer > enemyRoll then
            gfx.drawText("YOU WIN!", 150, 190)
            local rewardStr = "+1" 
             -- Rewards handled in input
            gfx.drawText("Reward: Random Mod!", 110, 210)
        elseif totalPlayer < enemyRoll then
            gfx.drawText("YOU LOSE...", 150, 190)
        else
            gfx.drawText("DRAW! Roll Again", 140, 190)
        end
    end
end

function Battle.handleInput(key)
    if key == "A" then
        if currentPhase == PHASE.START then
            currentPhase = PHASE.MENU
        
        elseif currentPhase == PHASE.MENU then
            -- Commit to roll
            -- Consume modifier if selected
            if activeModifier > 0 then
                if Inventory.useModifier(activeModifier) == 0 then
                    activeModifier = 0 -- Failed to use (shouldn't happen if logic correct)
                end
            end
            Battle.rollDice()
            
        elseif currentPhase == PHASE.RESULT then
            local totalPlayer = playerRoll + activeModifier
            if totalPlayer > enemyRoll then
                -- Win
                -- Random Reward
                local reward = math.random(1, 3)
                Inventory.addModifier(reward)
                Quest.updateProgress(Quest.TYPES.KILL, enemyType.name, 1)
                
                if Sound then 
                    Sound.playFanfare()
                    playdate.timer.performAfterDelay(1000, function()
                         if Sound then Sound.playOverworldMusic() end
                         GameState.switch(GameState.TYPES.OVERWORLD)
                    end)
                else
                    GameState.switch(GameState.TYPES.OVERWORLD)
                end
            elseif totalPlayer < enemyRoll then
                -- Lose
                 if Sound then Sound.playOverworldMusic() end
                GameState.switch(GameState.TYPES.OVERWORLD)
            else
                -- Draw
                currentPhase = PHASE.MENU -- Go back to menu to potentially use another mod? Or force re-roll?
                -- Let's allow re-roll options
                activeModifier = 0 -- Reset mod for re-roll? Or keep it? Usually modifiers are consumed per roll.
                -- User said "Use... removed". Implies per use.
            end
        end
    end
    
    if key == "B" and currentPhase == PHASE.MENU then
        -- Cycle modifiers
        if activeModifier == 0 then activeModifier = 1
        elseif activeModifier == 1 then activeModifier = 2
        elseif activeModifier == 2 then activeModifier = 3
        else activeModifier = 0 end
        
        -- Skip if we don't have any of that type
        -- Simple loop safety
        for i=1,4 do
             if activeModifier > 0 and Inventory.modifiers[activeModifier] <= 0 then
                 activeModifier = activeModifier + 1
                 if activeModifier > 3 then activeModifier = 0 end
             else
                 break
             end
        end
    end
end

function Battle.rollDice()
    currentPhase = PHASE.ROLLING
    
    pd.timer.performAfterDelay(1000, function()
        playerRoll = math.random(1, 6)
        enemyRoll = math.random(1, 6)
        currentPhase = PHASE.RESULT
        
        -- Sound effect for dice result?
    end)
end
