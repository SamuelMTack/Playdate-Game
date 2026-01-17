local pd <const> = playdate
local gfx <const> = pd.graphics

class('Enemy').extends(gfx.sprite)

function Enemy:init(row, col)
    self.currRow = row
    self.currCol = col
    
    -- Visuals: Purple Snake/Ball
    local w, h = 16, 16
    local img = gfx.image.new(w, h, gfx.kColorClear)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(8, 8, 7)
        -- Eyes
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(5, 6, 2)
        gfx.fillCircleAtPoint(11, 6, 2)
        
        -- Purple tint (using pattern since 1-bit)
        -- Checker pattern specific to enemy to look different from player
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
        gfx.fillCircleAtPoint(8, 8, 7)
    gfx.popContext()
    
    self:setImage(img)
    self:setZIndex(100 + row)
    self:add()
    
    -- Position on grid
    if GRID and GRID.cubes[row] and GRID.cubes[row][col] then
        local cube = GRID.cubes[row][col]
        self:moveTo(cube.x, cube.y - 12)
    end
    
    self.moveTimer = 0
    self.moveDelay = 1.5 -- Seconds between jumps
    self.state = 0 -- 0: Idle, 1: Jumping
    self.jumpTimer = 0
end

function Enemy:update()
    if self.state == 0 then
        self.moveTimer = self.moveTimer + 0.1 -- simplified dt
        -- Real delta time would be better but this matches existing pattern
        
        if self.moveTimer >= (self.moveDelay * 10) then -- approx logic
             self:decideMove()
        end
    elseif self.state == 1 then
        self.jumpTimer = self.jumpTimer + 0.1
        if self.jumpTimer >= 1 then
            self:finishJump()
        else
            -- Jump animation
            local t = self.jumpTimer
            local currX = self.startX + (self.targetX - self.startX) * t
            local currY = self.startY + (self.targetY - self.startY) * t
            local jumpHeight = 16 * 4 * t * (1-t)
            self:moveTo(currX, currY - jumpHeight)
        end
    end
end

function Enemy:decideMove()
    -- Simple AI: move down towards player
    -- Options: Down-Left (r+1, c) or Down-Right (r+1, c+1)
    
    local nextRow = self.currRow + 1
    if nextRow > 7 then
        -- Jump off screen (remove)
        self:remove()
        -- In main we should probably remove from table
        self.dead = true
        return
    end
    
    -- Pick direction
    local opt1Col = self.currCol
    local opt2Col = self.currCol + 1
    
    -- Check player pos
    local targetCol = opt1Col -- default
    
    if PLAYER then
        local pCol = PLAYER.currCol
        -- If player is to the right, try to go right
        if pCol > self.currCol then
            targetCol = opt2Col
        else
            targetCol = opt1Col
        end
    else
        -- Random if no player
        if math.random() > 0.5 then targetCol = opt2Col end
    end
    
    self:jumpTo(nextRow, targetCol)
end

function Enemy:jumpTo(r, c)
    self.state = 1
    self.jumpTimer = 0
    self.moveTimer = 0
    self.startX = self.x
    self.startY = self.y
    self.nextRow = r
    self.nextCol = c
    
    if GRID and GRID.cubes[r] and GRID.cubes[r][c] then
        local cube = GRID.cubes[r][c]
        self.targetX = cube.x
        self.targetY = cube.y - 12
        self:setZIndex(r + 100)
    else
        -- Off board
        local x = 200 + (c - (r + 1) / 2) * 28
        local y = 50 + (r - 1) * 22
        self.targetX = x
        self.targetY = y
        self.isDeathJump = true
    end
end

function Enemy:finishJump()
    self.state = 0
    self.currRow = self.nextRow
    self.currCol = self.nextCol
    self:moveTo(self.targetX, self.targetY)
    
    if self.isDeathJump then
        self:remove()
        self.dead = true
    end
end
