local pd <const> = playdate
local gfx <const> = pd.graphics

class('Grid').extends(gfx.sprite)

function Grid:init()
    self.tileWidth = 16
    self.tileHeight = 16
    self.cols = 25
    self.rows = 15

    self.currTilemap = gfx.tilemap.new()
    
    -- Create terrain images
    local soilImg = gfx.image.new(self.tileWidth, self.tileHeight, gfx.kColorBlack)
    -- Add some pattern
    gfx.pushContext(soilImg)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawPixel(4, 4)
        gfx.drawPixel(12, 10)
        gfx.drawPixel(8, 8)
    gfx.popContext()
    
    local emptyImg = gfx.image.new(self.tileWidth, self.tileHeight, gfx.kColorClear)
    
    -- Imagetable: 1 = soil, 2 = empty
    self.table = gfx.imagetable.new(2)
    self.table:setImage(1, soilImg)
    self.table:setImage(2, emptyImg)
    
    self.currTilemap:setImageTable(self.table)
    self.currTilemap:setSize(self.cols, self.rows)
    
    -- Initialize grid: top 2 rows sky (2), rest soil (1)
    for y=1, self.rows do
        for x=1, self.cols do
            if y <= 2 then
                self.currTilemap:setTileAtPosition(x, y, 2)
            else
                self.currTilemap:setTileAtPosition(x, y, 1)
            end
        end
    end
    
    self:setTilemap(self.currTilemap)
    self:setCenter(0, 0)
    self:moveTo(0, 0)
    self:setZIndex(-1) -- Background
    self:add()
    
    self:generateTunnels()
end

function Grid:generateTunnels()
    -- Clear map first (fill with soil)
    for y=3, self.rows do
        for x=1, self.cols do
            self.currTilemap:setTileAtPosition(x, y, 1)
        end
    end

    self.tunnelSpawns = {}
    
    -- Random walker / Drunkard's walk
    local count = math.random(3, 5) -- Number of tunnels
    for i=1, count do
        local tx = math.random(2, self.cols-1)
        local ty = math.random(3, self.rows-1)
        local len = math.random(5, 15)
        local dir = math.random(1, 2) -- 1: Horiz, 2: Vert
        
        for j=1, len do
            if tx >= 1 and tx <= self.cols and ty >= 3 and ty <= self.rows then
                self.currTilemap:setTileAtPosition(tx, ty, 2)
                -- Add potential spawn point (center of tile)
                if j == math.floor(len/2) then
                    table.insert(self.tunnelSpawns, {x=(tx-1)*16 + 8, y=(ty-1)*16 + 8})
                end
            end
            
            if dir == 1 then tx = tx + 1 else ty = ty + 1 end
        end
    end
end

function Grid:getTunnelSpawns()
    if not self.tunnelSpawns or #self.tunnelSpawns == 0 then
        return {{x=100, y=100}}
    end
    return self.tunnelSpawns
end

function Grid:dig(x, y)
    -- Convert world coordinates to grid coordinates
    local tx = math.floor(x / self.tileWidth) + 1
    local ty = math.floor(y / self.tileHeight) + 1
    
    if tx >= 1 and tx <= self.cols and ty >= 1 and ty <= self.rows then
        if self.currTilemap:getTileAtPosition(tx, ty) == 1 then
             self.currTilemap:setTileAtPosition(tx, ty, 2)
             return true
        end
    end
    return false
end

function Grid:isSolid(x, y)
    -- Check if a pixel coordinate is solid soil
    local tx = math.floor(x / self.tileWidth) + 1
    local ty = math.floor(y / self.tileHeight) + 1
    if tx >= 1 and tx <= self.cols and ty >= 1 and ty <= self.rows then
        return self.currTilemap:getTileAtPosition(tx, ty) == 1
    end
    return false
end

function Grid:update()
end
