Pattern = {}
Pattern.index = 1
Pattern.count = 3

function Pattern.next()
    Pattern.index = (Pattern.index % Pattern.count) + 1
end

function Pattern.draw(geo, t)
    if Pattern.index == 1 then
        Pattern.drawMandala(geo, t)
    elseif Pattern.index == 2 then
        Pattern.drawGridWave(geo, t)
    elseif Pattern.index == 3 then
        Pattern.drawParticles(geo, t)
    end
end

-- 1. Expanding Mandala
function Pattern.drawMandala(geo, t)
    local rings = 5
    for i=0, rings do
        local offset = (i * 0.5)
        local r = 20 + ((t + offset) % 6) * 40 -- Expanding radius
        local thickness = 2 + i
        
        -- Draw main ring
        -- Since we don't have geo.drawCircle, we use points or fillCircle
        -- Let's use orbiting dots to form rings or just a single large circle if geo supported it
        -- Geo only supports pointRotate, line, fillCircle.
        -- Let's simulate a ring with a line perpendicular to center? No, circle at point is easiest.
        
        local dots = 12
        for j=0, dots-1 do
            local a = (j / dots) * 360 + t * 20
            local rad = math.rad(a)
            local x = 200 + math.cos(rad) * r
            local y = 120 + math.sin(rad) * r
            
            geo.fillCircleAtPoint(x, y, thickness + math.sin(t*2+i)*2)
        end
        
        -- Connecting lines between rings
        if i > 0 then
             local r_prev = 20 + ((t + (i-1)*0.5) % 6) * 40
             -- Draw line from current ring dot to prev ring dot?
             -- Just draw some radial lines
             local x1 = 200 + math.cos(t) * r_prev
             local y1 = 120 + math.sin(t) * r_prev
             local x2 = 200 + math.cos(t) * r
             local y2 = 120 + math.sin(t) * r
             geo.drawLine(x1, y1, x2, y2)
        end
    end
end

-- 2. Grid Wave
function Pattern.drawGridWave(geo, t)
    local gap = 20
    local rows = 10
    local cols = 6
    
    for r=0, rows do
        for c=0, cols do
            -- Base position
            local bx = 150 + c * gap
            local by = 50 + r * gap
            
            -- Waviness
            local waveX = math.sin(t + r*0.5) * 15
            local waveY = math.cos(t + c*0.5) * 15
            
            local x = bx + waveX
            local y = by + waveY
            
            -- Draw Cross
            geo.drawLine(x-5, y, x+5, y)
            geo.drawLine(x, y-5, x, y+5)
            
            -- Connect to neighbor?
            if c > 0 then
                local prevX = (150 + (c-1)*gap) + math.sin(t + r*0.5)*15
                local prevY = by + math.cos(t + (c-1)*0.5)*15
                geo.drawLine(prevX, prevY, x, y)
            end
        end
    end
end

-- 3. Particles / Moire
function Pattern.drawParticles(geo, t)
    local count = 20
    for i=0, count do
        local speed = 1 + (i%5) * 0.5
        local a = (t * speed) + i * (360/count)
        local rad = math.rad(a)
        
        -- Spiraling out
        local r = 10 + (i * 8) + math.sin(t * 0.5) * 50
        
        local x = 200 + math.cos(rad) * r
        local y = 120 + math.sin(rad) * r
        
        local size = 3 + math.sin(t*5 + i)*2
        
        geo.fillCircleAtPoint(x, y, size)
        
        -- Trail line
        local tailX = 200 + math.cos(rad - 0.2) * (r - 10)
        local tailY = 120 + math.sin(rad - 0.2) * (r - 10)
        geo.drawLine(tailX, tailY, x, y)
    end
end
