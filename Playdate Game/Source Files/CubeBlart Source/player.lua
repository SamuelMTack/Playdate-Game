local pd <const> = playdate
local gfx <const> = pd.graphics

class('Player').extends(gfx.sprite)

function Player:init(x, y)
    -- Q*bert sprite
    -- Orange body, nose.
    -- Size 16x16
    local img = gfx.image.new(16, 20, gfx.kColorClear)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorBlack)
        -- Body
        gfx.fillCircleAtPoint(8, 8, 7)
        -- Nose (Tube)
        gfx.fillRect(8, 6, 8, 4) -- Protruding right
        gfx.fillCircleAtPoint(16, 8, 2)
        
        -- Eyes
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(6, 6, 2)
        gfx.fillCircleAtPoint(10, 6, 2)
        
        -- Legs (simple lines)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(6, 14, 4, 19)
        gfx.drawLine(10, 14, 12, 19)
    gfx.popContext()
    
    self:setImage(img)
    self:moveTo(x, y)
    self:add()
    self:setZIndex(100) -- Always on top
    
    self.currRow = 1
    self.currCol = 1
    
    self.state = 0 -- 0: Idle, 1: Jumping
    self.jumpTimer = 0
    self.targetX = x
    self.targetY = y
    self.startX = x
    self.startY = y
end

function Player:update()
    if self.state == 0 then
        local targetRow, targetCol = self.currRow, self.currCol
        
        if playdate.buttonJustPressed(playdate.kButtonUp) then
             -- Up-Left: r-1, c-1 (if c>1)
             targetRow = self.currRow - 1
             targetCol = self.currCol - 1
             if targetRow > 0 and targetCol > targetRow then targetCol = targetRow end -- clamp? No, math is (r, c). Row r has c 1..r
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
             -- Down-Left: r+1, c
             targetRow = self.currRow + 1
             targetCol = self.currCol
        elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
             -- Up-Right (Standard Qbert controls are rotated 45 deg)
             -- Let's map arrows visually:
             -- Up -> Up-Right? Or Up-Left?
             -- Left -> Up-Left?
             -- Right -> Down-Right?
             -- Down -> Down-Left?
             -- Actually let's just stick to:
             -- Up: r-1, c
             -- Down: r+1, c
             -- Left: r+1, c+1 (Wait, that's Down-Right?)
             -- Qbert controls:
             -- Up Arrow: Top-Left Jump (r-1, c-1)
             -- Right Arrow: Top-Right Jump (r-1, c)
             -- Left Arrow: Bottom-Left Jump (r+1, c)
             -- Down Arrow: Bottom-Right Jump (r+1, c+1)
             
             -- Let's stick to this mapping:
             -- Up: r-1, c-1
             -- Right: r-1, c
             -- Left: r+1, c
             -- Down: r+1, c+1
             targetRow = self.currRow + 1
             targetCol = self.currCol
        elseif playdate.buttonJustPressed(playdate.kButtonRight) then
             targetRow = self.currRow - 1
             targetCol = self.currCol
        end
        
        -- Correct mapping attempt 2:
        -- Up: Top-Right (r-1, c)
        -- Left: Top-Left (r-1, c-1)
        -- Right: Bottom-Right (r+1, c+1)
        -- Down: Bottom-Left (r+1, c)
        
        if playdate.buttonJustPressed(playdate.kButtonUp) then
             targetRow = self.currRow - 1
             targetCol = self.currCol
        end
        if playdate.buttonJustPressed(playdate.kButtonLeft) then
             targetRow = self.currRow - 1
             targetCol = self.currCol - 1
        end
        if playdate.buttonJustPressed(playdate.kButtonDown) then
             targetRow = self.currRow + 1
             targetCol = self.currCol
        end
        if playdate.buttonJustPressed(playdate.kButtonRight) then
             targetRow = self.currRow + 1
             targetCol = self.currCol + 1
        end

        if targetRow ~= self.currRow or targetCol ~= self.currCol then
             self:jumpTo(targetRow, targetCol)
        end
        
    elseif self.state == 1 then
        self.jumpTimer = self.jumpTimer + 0.1
        if self.jumpTimer >= 1 then
            self:finishJump()
        else
            -- Lerp position + parabolic arc for Z/Y
            local t = self.jumpTimer
            local currX = self.startX + (self.targetX - self.startX) * t
            local currY = self.startY + (self.targetY - self.startY) * t
            -- Arc height: 4 * h * t * (1-t)
            local jumpHeight = 16 * 4 * t * (1-t)
            
            self:moveTo(currX, currY - jumpHeight)
            
            -- Simple frame animation
            if t > 0.5 then self:setImage(self:getImage()) end -- placeholder
        end
    end
end

function Player:jumpTo(r, c)
    self.state = 1
    self.jumpTimer = 0
    self.startX = self.x
    self.startY = self.y -- approximate current purely logic Y
    -- Actually self.y includes previous jump offset if we don't reset, but we finishJump so it's fine.
    
    -- Calculate target world coords
    -- We can get them from GRID if valid, or calculate if off-screen
    
    if GRID and GRID.cubes[r] and GRID.cubes[r][c] then
        local cube = GRID.cubes[r][c]
        self.targetX = cube.x
        self.targetY = cube.y - 12 -- Stand on top
        self.nextRow = r
        self.nextCol = c
        self:setZIndex(r + 100) -- Always on top of everything
    else
        -- Off board! Game Over logic trigger eventually
        -- For now, jump into void
        -- Math from grid.lua:
        -- x = 200 + (c - (r + 1) / 2) * 28
        -- y = 50 + (r - 1) * 22
        local x = 200 + (c - (r + 1) / 2) * 28
        local y = 50 + (r - 1) * 22
        self.targetX = x
        self.targetY = y
        self.nextRow = r
        self.nextCol = c
        self.isDeathJump = true
    end
end

function Player:finishJump()
    self.state = 0
    self.currRow = self.nextRow
    self.currCol = self.nextCol
    self.startX = self.targetX
    self.startY = self.targetY
    self:moveTo(self.targetX, self.targetY)
    
    if self.isDeathJump then
        -- Trigger Reset/Death
        -- For now just reset to top
        self.currRow = 1
        self.currCol = 1
        local startCube = GRID.cubes[1][1]
        self.x = startCube.x
        self.y = startCube.y - 12
        self:moveTo(self.x, self.y)
        self.isDeathJump = false
        SCORE = 0 -- Reset score on death
    else
        -- Landed on cube
        local cube = GRID.cubes[self.currRow][self.currCol]
        if cube.state == 0 then
            cube:changeColor()
            SCORE = SCORE + 25
        end
    end
end
