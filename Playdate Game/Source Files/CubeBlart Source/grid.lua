local pd <const> = playdate
local gfx <const> = pd.graphics

class('Grid').extends(Object)

function Grid:init()
    self.cubes = {} -- Table to store cube objects
    self:buildPyramid()
end

function Grid:buildPyramid()
    local startX = 200
    local startY = 50
    local size = 32
    -- Build 7 rows
    for r=1, 7 do
        self.cubes[r] = {}
        for c=1, r do
            -- Isometric position math
            -- Cube width approx 28, height overlapping.
            -- Top face is 28 wide, 16 high.
            -- Step X: +1 Col -> +14 x, +8 y?
            -- Let's use standard:
            -- Row 1, Col 1: Top Center.
            -- Row+1 -> Down-Left or Down-Right.
            -- Visual Y step per row: 24 pixels (16 for top face height + some side)
            
            -- Center X = 200.
            -- Row r has r cubes.
            -- The x-span of row r is (r-1)*Width.
            -- Center of row r should be 200?
            -- Cube width spacing = 28. (Horizontal distance between centers of neighbors)
            -- Wait, standard Qbert:
            --      1
            --     2 3
            --    4 5 6
            -- Horizontal spacing between 2 and 3 is Full Width?
            
            -- Let's try:
            -- Row 1: 200, 40
            -- Row 2: 
            --    Col 1 (Left): 200 - 14, 40 + 24
            --    Col 2 (Right): 200 + 14, 40 + 24
            
            local rowY = startY + (r - 1) * 24
            
            -- X offset for the whole row to center it
            -- (r-1) * (Width/2) is the total spread?
            -- Let's say horizontal step is 28 (width of tile).
            -- Actually, neighbors are staggered.
            -- Col 1 is "Leftmost" of the row.
            
            -- Let's define x,y based on (r,c) in a skewed grid.
            -- x = 200 + (c-1)*14 - (r-c)*14  (Col moves right, Row moves left?)
            -- Or:
            -- x = 200 + (c - (r+1)/2) * 28
            
            local x = 200 + (c - (r + 1) / 2) * 28
            local y = startY + (r - 1) * 22
            
            local cube = Cube(r, c, x, y)
            cube:setZIndex(r) -- Lower rows draw on top of upper rows? No, front to back.
            -- In Qbert, lower rows overlap upper rows visually if they are "in front".
            -- Actually, Row 1 is "Back". Row 7 is "Front".
            -- So Z = r.
            self.cubes[r][c] = cube
        end
    end
end

function Grid:checkWin()
    for r=1, 7 do
        for c=1, r do
            if self.cubes[r][c].state == 0 then
                return false
            end
        end
    end
    return true
end
