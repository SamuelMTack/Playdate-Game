local gfx = playdate.graphics

Sprites = {}

local cache = {}
-- Ensure cache is clear if reloading
cache = {}

function Sprites.getTile(type)
    if not cache[type] then
        cache[type] = Sprites.generateTile(type)
    end
    return cache[type]
end

-- Helper to create image from 1-bit patterns
function Sprites.createPlayer()
    local img = gfx.image.new(32, 32)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        -- Head
        gfx.fillCircleAtPoint(16, 8, 6)
        -- Body
        gfx.fillRect(10, 14, 12, 10)
        -- Legs
        gfx.fillRect(10, 24, 4, 8)
        gfx.fillRect(18, 24, 4, 8)
        -- Sword
        gfx.fillRect(4, 10, 4, 16)
        gfx.fillRect(2, 22, 8, 2)
        -- Shield
        gfx.drawRect(20, 14, 8, 10)
        gfx.fillRect(22, 16, 4, 6)
    gfx.popContext()
    return img
end

function Sprites.createEnemy(type)
    local img = gfx.image.new(64, 64)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        -- Monster Body (Blob-ish)
        gfx.fillEllipseInRect(10, 10, 44, 44)
        -- Eyes
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(24, 25, 6)
        gfx.fillCircleAtPoint(40, 25, 6)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(24, 25, 2)
        gfx.fillCircleAtPoint(40, 25, 2)
        -- Mouth
        gfx.setColor(gfx.kColorWhite)
        gfx.fillEllipseInRect(22, 40, 20, 8)
        
        -- Dithering/Texture
        gfx.setColor(gfx.kColorBlack)
        for i=0,64,2 do
            gfx.drawPixel(i, i)
            gfx.drawPixel(64-i, i)
        end
    gfx.popContext()
    return img
end

function Sprites.generateTile(type)
    -- Initialize with TRANSPARENT background (default)
    -- This matches the working Player sprite
    local img = gfx.image.new(32, 32)
    gfx.pushContext(img)
    
    gfx.setColor(gfx.kColorBlack)
    
    -- Draw border for every tile to ensure visibility
    gfx.drawRect(0, 0, 32, 32)
    
    if type == 1 then -- GRASS
        for i=1,10 do
            local x = (i * 7) % 24 + 4
            local y = (i * 3) % 24 + 4
            gfx.drawLine(x, y, x+2, y-2)
            gfx.drawLine(x+4, y, x+2, y-2)
        end
        
    elseif type == 2 then -- WATER
        for i=1,4 do
            local y = i*6
            gfx.drawLine(2, y, 30, y)
        end
        
    elseif type == 3 then -- MOUNTAIN
        gfx.fillTriangle(4, 30, 16, 4, 28, 30)
        
    elseif type == 4 then -- VILLAGE
        gfx.fillRect(8, 12, 16, 20) -- House
        gfx.fillTriangle(4, 12, 16, 2, 28, 12) -- Roof
        gfx.fillRect(14, 22, 4, 10) -- Door
        
    elseif type == 5 then -- CASTLE
        gfx.fillRect(6, 6, 20, 26)
        gfx.setColor(gfx.kColorWhite) -- Cutout details
        gfx.fillRect(8, 8, 2, 4)
        gfx.fillRect(22, 8, 2, 4)
        gfx.fillCircleAtPoint(16, 22, 6) -- Gate
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(6, 6, 20, 26) -- Border back
        
    elseif type == 6 then -- TOWER
        gfx.fillRect(10, 2, 12, 30)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(14, 6, 4, 6)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(10, 2, 12, 30)
        
    elseif type == 7 then -- CAVE
        gfx.fillEllipseInRect(2, 2, 28, 28)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillEllipseInRect(6, 10, 20, 20)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillEllipseInRect(8, 16, 16, 14)

    elseif type == 8 then -- FOREST
        gfx.fillTriangle(16, 4, 8, 20, 24, 20)
        gfx.fillRect(14, 20, 4, 8)
        gfx.fillTriangle(8, 12, 2, 24, 14, 24)
        gfx.fillRect(6, 24, 4, 6)
    end
    
    gfx.popContext()
    return img
end

return Sprites
