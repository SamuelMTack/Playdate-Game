local gfx = playdate.graphics

TILE_SIZE = 20
walls = {}
dots = {}

-- 20 cols x 11 rows (leaving space for UI)
-- 400 wide / 20 = 20 cols
-- 220 tall / 20 = 11 rows
local levelMap = {
    "####################",
    "#..................#",
    "#.###.###..###.###.#",
    "#.#...#......#...#.#",
    "#.###.###..###.###.#",
    "#..................#",
    "#.###.## .. ##.###.#",
    "#......#    #......#",
    "#.###.##    ##.###.#",
    "#..................#",
    "####################"
}

-- Spawn points found during parsing
pacmanSpawn = {x=0, y=0}
ghostSpawns = {}

function buildLevel()
    walls = {}
    dots = {}
    ghostSpawns = {}
    
    -- Hardcoded spawn points for MVP simplicity based on map layout
    -- Start Pacman at bottom center
    pacmanSpawn = {x = 10 * TILE_SIZE, y = 9 * TILE_SIZE}
    -- Ghosts center
    ghostSpawns = { {x=10 * TILE_SIZE, y=7 * TILE_SIZE} }

    for r, row in ipairs(levelMap) do
        for c = 1, #row do
            local char = row:sub(c, c)
            local x = (c-1) * TILE_SIZE
            local y = (r-1) * TILE_SIZE
            
            if char == "#" then
                local wall = gfx.sprite.new()
                wall:setBounds(x, y, TILE_SIZE, TILE_SIZE)
                wall:setCollideRect(0, 0, TILE_SIZE, TILE_SIZE)
                
                -- Draw Wall
                local img = gfx.image.new(TILE_SIZE, TILE_SIZE)
                gfx.pushContext(img)
                    gfx.setColor(gfx.kColorBlack)
                    gfx.fillRect(0, 0, TILE_SIZE, TILE_SIZE)
                    gfx.setColor(gfx.kColorWhite)
                    gfx.drawRect(2, 2, TILE_SIZE-4, TILE_SIZE-4)
                gfx.popContext()
                wall:setImage(img)
                
                wall:setTag(1) -- Tag 1: Wall
                wall:setGroups({1})
                wall:add()
                table.insert(walls, wall)
            elseif char == "." then
                local dot = gfx.sprite.new()
                dot:setBounds(x + 8, y + 8, 4, 4) -- Small center hitbox
                dot:setCollideRect(0, 0, 4, 4)
                
                local img = gfx.image.new(4, 4)
                gfx.pushContext(img)
                    gfx.fillRect(0,0,4,4)
                gfx.popContext()
                dot:setImage(img)
                
                dot:setTag(2) -- Tag 2: Dot
                dot:setGroups({2})
                dot:add()
                table.insert(dots, dot)
            end
        end
    end
end

function isLevelCleared()
    return #dots == 0
end
