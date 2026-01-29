class('Board').extends()

function Board:init()
    self.grid = {} -- 10x10. 0=Empty, 1=Ship, 2=Miss, 3=HIT
    for y=1,10 do
        self.grid[y] = {}
        for x=1,10 do
            self.grid[y][x] = 0
        end
    end
    self.ships = {} -- List of ship objects {x, y, len, horizontal, hits}
end

function Board:canPlace(x, y, length, horizontal)
    if horizontal then
        if x + length - 1 > 10 then return false end
        for i=0, length-1 do
            if self.grid[y][x+i] ~= 0 then return false end
        end
    else
        if y + length - 1 > 10 then return false end
        for i=0, length-1 do
            if self.grid[y+i][x] ~= 0 then return false end
        end
    end
    return true
end

function Board:place(x, y, length, horizontal)
    if not self:canPlace(x, y, length, horizontal) then return false end
    
    local newShip = {x=x, y=y, len=length, horiz=horizontal, hits=0}
    table.insert(self.ships, newShip)
    
    if horizontal then
        for i=0, length-1 do
            self.grid[y][x+i] = 1 -- Ship
        end
    else
        for i=0, length-1 do
            self.grid[y+i][x] = 1 -- Ship
        end
    end
    return true
end

function Board:receiveAttack(x, y)
    if self.grid[y][x] == 2 or self.grid[y][x] == 3 then
        return false -- Already hit
    end
    
    if self.grid[y][x] == 1 then
        self.grid[y][x] = 3 -- HIT
        -- Find which ship was hit
        for _, ship in ipairs(self.ships) do
            if ship.horiz then
                if y == ship.y and x >= ship.x and x < ship.x + ship.len then
                    ship.hits = ship.hits + 1
                    return "HIT", self:checkSunk(ship)
                end
            else
                if x == ship.x and y >= ship.y and y < ship.y + ship.len then
                    ship.hits = ship.hits + 1
                     return "HIT", self:checkSunk(ship)
                end
            end
        end
        return "HIT"
    else
        self.grid[y][x] = 2 -- MISS
        return "MISS"
    end
end

function Board:checkSunk(ship)
    if ship.hits >= ship.len then
        return true
    end
    return false
end

function Board:allSunk()
    for _, ship in ipairs(self.ships) do
        if ship.hits < ship.len then return false end
    end
    return true
end
