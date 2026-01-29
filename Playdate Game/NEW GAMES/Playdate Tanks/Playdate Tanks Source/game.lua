import "terrain"
import "tank"
import "bullet"
import "ui"
import "ai"

local gfx = playdate.graphics

Game = {}

Game.STATE = {
    MENU = 1,
    PLAYER_TURN = 2,
    BULLET_FLYING = 3,
    GAME_OVER = 4,
    AI_TURN = 5
}

Game.MODE = {
    PVP = 1,
    PVE = 2
}

Game.currentState = Game.STATE.MENU
Game.currentMode = Game.MODE.PVE
Game.players = {}
Game.currentPlayerIndex = 1
Game.bullets = {}
Game.menuOption = 1 -- 1: 1 Player, 2: 2 Players

function Game.init()
    -- Initial setup if needed
end

function Game.startGame(mode)
    Game.currentMode = mode
    Terrain.generate()
    Game.players = {}
    Game.players[1] = Tank(50, Terrain.getHeight(50), 1)
    Game.players[2] = Tank(350, Terrain.getHeight(350), 2)
    Game.currentPlayerIndex = 1
    Game.currentState = Game.STATE.PLAYER_TURN
    Game.bullets = {}
end

function Game.update()
    if Game.currentState == Game.STATE.MENU then
        if playdate.buttonJustPressed(playdate.kButtonDown) then
            Game.menuOption = 2
        elseif playdate.buttonJustPressed(playdate.kButtonUp) then
            Game.menuOption = 1
        end
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            if Game.menuOption == 1 then
                Game.startGame(Game.MODE.PVE)
            else
                Game.startGame(Game.MODE.PVP)
            end
        end

    elseif Game.currentState == Game.STATE.PLAYER_TURN then
        local currentPlayer = Game.players[Game.currentPlayerIndex]
        currentPlayer:update()
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
           Game.fireBullet(currentPlayer)
        end
        
    elseif Game.currentState == Game.STATE.AI_TURN then
         -- AI Logic
         local me = Game.players[2]
         local target = Game.players[1]
         
         -- Slight delay for realism or animation could go here
         AI.turn(me, target)
         
         -- Fire!
         if math.random() < 0.05 then -- Small random delay chance
             Game.fireBullet(me)
         end

    elseif Game.currentState == Game.STATE.BULLET_FLYING then
        if #Game.bullets > 0 then
            for i, b in ipairs(Game.bullets) do
                b:update()
                if b.dead then
                    table.remove(Game.bullets, i)
                    
                    -- Check for game over
                    local gameOver = false
                    for pid, p in ipairs(Game.players) do
                        if p.health <= 0 then
                            Game.winnerIndex = (pid == 1) and 2 or 1 -- Other player wins
                            Game.currentState = Game.STATE.GAME_OVER
                            gameOver = true
                            break
                        end
                    end
                    
                    if not gameOver then
                        Game.switchTurn()
                    end
                end
            end
        else
             Game.switchTurn()
        end
    elseif Game.currentState == Game.STATE.GAME_OVER then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            Game.currentState = Game.STATE.MENU
        end
    end
end

function Game.fireBullet(tank)
    local b = Bullet(tank.x, tank.y, tank.angle, tank.power)
    table.insert(Game.bullets, b)
    Game.currentState = Game.STATE.BULLET_FLYING
end

function Game.switchTurn()
    Game.currentPlayerIndex = (Game.currentPlayerIndex % 2) + 1
    
    -- Reset fuel
    Game.players[Game.currentPlayerIndex].fuel = 100
    
    if Game.currentMode == Game.MODE.PVE and Game.currentPlayerIndex == 2 then
        Game.currentState = Game.STATE.AI_TURN
    else
        Game.currentState = Game.STATE.PLAYER_TURN
    end
end

function Game.draw()
    if Game.currentState == Game.STATE.MENU then
        UI.drawMenu()
    else
        Terrain.draw()
        
        for _, p in ipairs(Game.players) do
            p:draw()
        end
        
        for _, b in ipairs(Game.bullets) do
            b:draw()
        end
        
        UI.drawGame()
    end
end

-- Init game on load
Game.init()
