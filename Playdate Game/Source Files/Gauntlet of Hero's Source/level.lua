-- Tile Types
-- 0: Floor
-- 1: Wall
-- 2: Generator (Spawns ghosts)
-- 3: Food (+Health)
-- 4: Key
-- 5: Door (Needs Key)
-- 6: Exit
-- 7: Player Start

local T = {
    FLOOR = 0,
    WALL = 1,
    GEN = 2,
    FOOD = 3,
    KEY = 4,
    DOOR = 5,
    EXIT = 6,
    START = 7
}

local mapString = [[
11111111111111111111
17000000001000020001
10111110101011111101
10130010100000000101
10100010111110000101
10111110000000000501
10000000111112000101
12000000130000000101
11111000101111111101
10000000100000000001
10111111111110000001
10002000000000000001
10111111111111110001
10000040000000000061
11111111111111111111
]]

function CreateLevelData()
    local MapData = {}
    MapData.tiles = {}
    MapData.width = 20
    MapData.height = 15
    MapData.TileSize = 20

    -- Parse map string
    local y = 1
    for line in mapString:gmatch("[^\r\n]+") do
        local row = {}
        for x = 1, #line do
            local char = line:sub(x, x)
            table.insert(row, tonumber(char))
        end
        table.insert(MapData.tiles, row)
        y = y + 1
    end

    MapData.Types = T
    return MapData
end
