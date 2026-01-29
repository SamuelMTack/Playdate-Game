local gfx = playdate.graphics

Terrain = {}
Terrain.heights = {}
Terrain.segmentWidth = 2 -- Width in pixels of each terrain segment
Terrain.numSegments = 400 / Terrain.segmentWidth

function Terrain.generate()
    Terrain.heights = {}
    local noiseScale = 0.01 + (math.random() * 0.02)
    local groundLevel = 160 -- Moved up to ensure visibility (Screen height is 240)
    local amplitude = 20 + math.random(20) -- Max potential deviation approx 1.5 * 40 = 60. 160+60=220 < 240.
    local phase1 = math.random() * 100
    local phase2 = math.random() * 100
    
    -- Simple perlin-like noise or sine waves for now
    for i = 1, Terrain.numSegments do
        local x = i * Terrain.segmentWidth
        local noise = math.sin(x * noiseScale + phase1) * amplitude + math.sin(x * noiseScale * 2.5 + phase2) * (amplitude / 2)
        Terrain.heights[i] = groundLevel - noise
    end
end

function Terrain.getHeight(x)
    local index = math.floor(x / Terrain.segmentWidth) + 1
    if index < 1 then index = 1 end
    if index > #Terrain.heights then index = #Terrain.heights end
    return Terrain.heights[index]
end

function Terrain.draw()
    gfx.setColor(gfx.kColorBlack)
    for i = 1, #Terrain.heights - 1 do
        local x1 = (i - 1) * Terrain.segmentWidth
        local y1 = Terrain.heights[i]
        local x2 = i * Terrain.segmentWidth
        local y2 = Terrain.heights[i+1]
        
        gfx.fillPolygon(x1, 240, x2, 240, x2, y2, x1, y1)
    end
end

function Terrain.explode(x, radius)
    -- Deform terrain
    local impactIndex = math.floor(x / Terrain.segmentWidth) + 1
    local segmentsAffected = math.ceil(radius / Terrain.segmentWidth)
    
    for i = impactIndex - segmentsAffected, impactIndex + segmentsAffected do
        if i >= 1 and i <= #Terrain.heights then
            local dist = math.abs((i - 1) * Terrain.segmentWidth - x)
            if dist < radius then
                local depression = math.sqrt(radius*radius - dist*dist)
                Terrain.heights[i] = Terrain.heights[i] + depression
                if Terrain.heights[i] > 240 then Terrain.heights[i] = 240 end
            end
        end
    end
end
