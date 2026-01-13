
local pd <const> = playdate
local gfx <const> = pd.graphics

class('Tetromino').extends()

-- 1 = filled, 0 = empty
-- Shapes defined in 4x4 or 3x3 grids primarily, or 2x2 for O
Tetromino.SHAPES = {
    I = {
        {0,0,0,0},
        {1,1,1,1},
        {0,0,0,0},
        {0,0,0,0}
    },
    O = {
        {1,1},
        {1,1}
    },
    T = {
        {0,1,0},
        {1,1,1},
        {0,0,0}
    },
    S = {
        {0,1,1},
        {1,1,0},
        {0,0,0}
    },
    Z = {
        {1,1,0},
        {0,1,1},
        {0,0,0}
    },
    J = {
        {1,0,0},
        {1,1,1},
        {0,0,0}
    },
    L = {
        {0,0,1},
        {1,1,1},
        {0,0,0}
    }
}

Tetromino.COLORS = {
    I = gfx.kColorBlack, -- We'll use patterns or shades for Playdate, currently simplified to black
    O = gfx.kColorBlack,
    T = gfx.kColorBlack,
    S = gfx.kColorBlack,
    Z = gfx.kColorBlack,
    J = gfx.kColorBlack,
    L = gfx.kColorBlack
}

function Tetromino:init(type)
    self.type = type
    self.shape = self:_copyShape(Tetromino.SHAPES[type])
    self.x = 4 -- Start near-center
    self.y = 1
    self.rotation = 0
end

function Tetromino:_copyShape(shape)
    local newShape = {}
    for r, row in ipairs(shape) do
        newShape[r] = {}
        for c, val in ipairs(row) do
            newShape[r][c] = val
        end
    end
    return newShape
end

function Tetromino:rotate()
    local N = #self.shape
    local newShape = {}
    for i = 1, N do
        newShape[i] = {}
        for j = 1, N do
            newShape[i][j] = self.shape[N - j + 1][i]
        end
    end
    self.shape = newShape
end

-- Revert rotation (useful if collision detected after rotation)
function Tetromino:unrotate()
    local N = #self.shape
    local newShape = {}
    for i = 1, N do
        newShape[i] = {}
        for j = 1, N do
            newShape[i][j] = self.shape[j][N - i + 1]
        end
    end
    self.shape = newShape
end
