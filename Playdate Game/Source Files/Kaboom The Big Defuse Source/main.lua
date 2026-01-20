import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics

-- Sound
local catchSynth = playdate.sound.synth.new(playdate.sound.kWaveSquare)
local explodeSynth = playdate.sound.synth.new(playdate.sound.kWaveNoise)

-- Globals
local bombs = {}
local bucketCount = 3
local score = 0
local difficulty = 1
local gameState = "START" -- START, PLAY, GAMEOVER

-- Entities
local bomber = {x = 200, y = 30, width = 20, height = 20, dir = 1, speed = 2}
local bucket = {x = 200, y = 220, width = 26, height = 10}

function setupGame()
    bombs = {}
    bucketCount = 3
    score = 0
    difficulty = 1
    bomber.x = 200
    bucket.x = 200
end

function playdate.update()
    gfx.clear()
    
    if gameState == "START" then
        gfx.drawText("Kaboom The Big Defuse", 130, 100)
        gfx.drawText("Use Crank to move", 135, 120)
        gfx.drawText("Press A to Start", 145, 140)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            setupGame()
            gameState = "PLAY"
        end
    elseif gameState == "PLAY" then
        -- Mad Bomber Movement
        bomber.x = bomber.x + (bomber.dir * bomber.speed)
        
        -- Erratic behavior: random change or edge bounce
        if math.random() < 0.02 then bomber.dir = -bomber.dir end
        if bomber.x < 10 then bomber.dir = 1 end
        if bomber.x > 390 then bomber.dir = -1 end
        
        -- Bomb Spawning
        -- Higher difficulty = more frequent bombs
        local spawnChance = 0.02 + (difficulty * 0.005)
        if math.random() < spawnChance then
            table.insert(bombs, {x = bomber.x, y = bomber.y + 10, speed = 2 + (difficulty * 0.2)})
        end
        
        -- Player Movement (Crank)
        local change = playdate.getCrankChange()
        bucket.x = bucket.x + change
        -- Clamp
        if bucket.x < 15 then bucket.x = 15 end
        if bucket.x > 385 then bucket.x = 385 end
        
        -- Update Bombs
        for i = #bombs, 1, -1 do
            local b = bombs[i]
            b.y = b.y + b.speed
            
            -- Collision with Bucket
            -- Only check if hits the TOP bucket (roughly y=210-220 range)
            local catchY = 220 - (bucketCount * 12) -- Stack upwards
            
            if b.y >= catchY and b.y <= catchY + 10 and 
               b.x >= bucket.x - 15 and b.x <= bucket.x + 15 then
                table.remove(bombs, i)
                score = score + 10
                catchSynth:playNote("C5", 0.05, 0.2)
                
                -- Difficulty scaling
                if score % 100 == 0 then difficulty = difficulty + 1 end
            
            -- Missed (Floor)
            elseif b.y > 240 then
                table.remove(bombs, i)
                explodeSynth:playNote("C2", 0.5, 0.5)
                loseLife()
            end
        end
        
        drawGame()
        
    elseif gameState == "GAMEOVER" then
        drawGame() -- Keep drawing the frozen state
        gfx.drawText("GAME OVER", 160, 100)
        gfx.drawText("Score: " .. score, 165, 120)
        gfx.drawText("Press A to Restart", 135, 140)
        
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = "START"
        end
    end
    
    playdate.drawFPS(0,0)
end

function loseLife()
    -- Clear all bombs on screen
    bombs = {}
    bucketCount = bucketCount - 1
    
    if bucketCount <= 0 then
        gameState = "GAMEOVER"
    else
        -- Pause briefly? For simplicity, we just continue
    end
end

function drawGame()
    -- Draw Bomber (Mad Face)
    gfx.fillRect(bomber.x - 10, bomber.y - 10, 20, 20)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(bomber.x - 5, bomber.y - 5, 2)
    gfx.fillCircleAtPoint(bomber.x + 5, bomber.y - 5, 2)
    gfx.drawLine(bomber.x - 5, bomber.y + 5, bomber.x + 5, bomber.y + 5)
    gfx.setColor(gfx.kColorBlack)
    
    -- Draw Bombs
    for _, b in ipairs(bombs) do
        gfx.fillCircleAtPoint(b.x, b.y, 4)
        -- Fuse spark?
        if math.random() < 0.5 then
            gfx.drawPixel(b.x, b.y - 5)
        end
    end
    
    -- Draw Buckets
    for i = 0, bucketCount - 1 do
        local y = 220 - (i * 12)
        gfx.drawRect(bucket.x - 13, y, 26, 10)
        gfx.fillRect(bucket.x - 12, y + 1, 24, 8) -- Filled interior look
    end
    
    -- Draw UI
    gfx.drawText("Score: " .. score, 5, 5)
end
