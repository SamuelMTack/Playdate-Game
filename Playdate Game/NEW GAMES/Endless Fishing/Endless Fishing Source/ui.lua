local gfx = playdate.graphics

UI = {}

-- Visual State
UI.clouds = {}
for i=1, 3 do
    table.insert(UI.clouds, {x = math.random(0, 400), y = math.random(10, 60), speed = math.random(1, 3) * 0.5})
end

UI.bgFish = {}
for i=1, 5 do
    table.insert(UI.bgFish, {x = math.random(0, 400), y = math.random(130, 230), speed = math.random(1, 4) * 0.5, size = math.random(2, 5)})
end

UI.timer = 0

function UI.drawTitle()
    gfx.drawText("ENDLESS FISHING", 100, 80)
    gfx.drawText("Highscore: " .. GlobalData.highScore .. " lbs", 110, 110)
    gfx.drawText("Press A to Start", 120, 150)
    gfx.drawText("Use Crank to Reel!", 115, 200)
end

function UI.drawFishing()
    UI.timer = UI.timer + 0.1
    
    -- Sky
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, 400, 120)
    
    -- Sun
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(360, 40, 20)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(360, 40, 18) -- Ring effect or just white inside if we want outline
    -- Let's just do a solid black sun since it's 1-bit
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(360, 40, 15)
    
    -- Clouds
    for _, c in ipairs(UI.clouds) do
        c.x = c.x + c.speed
        if c.x > 420 then c.x = -50 c.y = math.random(10, 60) end
        
        gfx.fillEllipseInRect(c.x, c.y, 40, 20)
        -- Clear inside to make it an outline cloud?
        gfx.setColor(gfx.kColorWhite)
        gfx.fillEllipseInRect(c.x+2, c.y+2, 36, 16)
        gfx.setColor(gfx.kColorBlack)
    end
    
    -- Water
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 120, 400, 120)
    
    -- Background Fish (Underwater Life)
    gfx.setColor(gfx.kColorWhite)
    for _, f in ipairs(UI.bgFish) do
        f.x = f.x - f.speed
        if f.x < -20 then f.x = 420 f.y = math.random(130, 230) end
        
        gfx.fillCircleAtPoint(f.x, f.y, f.size)
        -- Tail
        gfx.drawLine(f.x + f.size, f.y, f.x + f.size + 4, f.y - 3)
        gfx.drawLine(f.x + f.size, f.y, f.x + f.size + 4, f.y + 3)
    end
    
    -- Waves (Surface)
    gfx.setColor(gfx.kColorWhite) 
    for i = 0, 400, 10 do
        local waveY = 120 + math.sin(UI.timer + (i * 0.1)) * 3
        gfx.drawLine(i, 120, i, waveY) -- Little spikes? Or just a line?
        -- Let's draw a continuous line approx
        local nextY = 120 + math.sin(UI.timer + ((i+10) * 0.1)) * 3
        gfx.drawLine(i, waveY, i+10, nextY)
    end
    
    -- Restore Black for Boat/Fisherman
    gfx.setColor(gfx.kColorBlack)
    
    -- Draw Boat
    -- Bobbing boat
    local boatY = 110 + math.sin(UI.timer) * 2 -- Raised from 120
    gfx.fillPolygon(150, boatY, 250, boatY, 230, boatY+20, 170, boatY+20) -- Hull
    gfx.drawLine(200, boatY, 200, boatY-30) -- Mast
    gfx.fillTriangle(200, boatY-30, 200, boatY-10, 220, boatY-10) -- Sail
    
    -- Draw Fisherman
    local manY = boatY - 10
    gfx.fillCircleAtPoint(180, manY, 5) -- Head
    gfx.drawLine(180, manY+5, 180, manY+15) -- Body
    gfx.drawLine(180, manY+8, 195, manY+5) -- Arm holding rod
    
    -- Draw Rod
    local rodX, rodY = 220, manY-10 -- Tip of rod
    gfx.drawLine(195, manY+5, rodX, rodY)
    
    -- Line
    gfx.setColor(gfx.kColorWhite) -- White line in dark water
    local endX, endY = rodX, rodY + Fishing.lineLength
    
    if endY > 120 then
        gfx.drawLine(rodX, rodY, endX, endY)
        -- Draw part above water in black
        gfx.setColor(gfx.kColorBlack)
        -- Intersect Y=120
        -- x = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
        if (endY - rodY) ~= 0 then
             local intersectX = rodX + (120 - rodY) * (endX - rodX) / (endY - rodY)
             gfx.drawLine(rodX, rodY, intersectX, 120)
        end
    else
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(rodX, rodY, endX, endY)
    end

    -- Bobber / Fish
    if Fishing.currentState == Fishing.STATE.REELING and Fishing.currentFish.isPulling then
         gfx.fillCircleAtPoint(endX + (math.random(-2,2)), endY, 5) -- Shake
    else
         gfx.fillCircleAtPoint(endX, endY, 5)
    end
    
    -- GUI Elements
    gfx.setColor(gfx.kColorBlack)
    
    -- Tension Bar
    gfx.drawText("Tension", 10, 10)
    gfx.drawRect(70, 10, 100, 15)
    
    local fillWidth = Fishing.tension 
    if fillWidth > 100 then fillWidth = 100 end
    
    gfx.fillRect(70, 10, fillWidth, 15)
    
    -- Message
    if Fishing.message ~= "" then
        gfx.drawTextAligned(Fishing.message, 200, 50, kTextAlignment.center)
    end
    
    if Fishing.currentState == Fishing.STATE.RESULT then
        gfx.drawTextAligned("Press A to fish again", 200, 160, kTextAlignment.center)
    end
end
