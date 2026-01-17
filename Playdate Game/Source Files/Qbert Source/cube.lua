local pd <const> = playdate
local gfx <const> = pd.graphics

class('Cube').extends(gfx.sprite)

function Cube:init(row, col, x, y)
    self.row = row
    self.col = col
    self.state = 0 -- 0: Initial, 1: Changed
    
    -- Isometric Cube Drawing
    -- Size: 32x32 sprite. Cube visual is approx 28w x 32h.
    local w = 32
    local h = 32
    local img = gfx.image.new(w, h, gfx.kColorClear)
    gfx.pushContext(img)
        -- Colors
        local colorTop = gfx.kColorWhite -- Top face
        local colorLeft = gfx.kColorBlack -- Left face (shaded)
        local colorRight = gfx.kColorBlack -- Right face (shaded)
        -- We will use patterns for shading since purely black/white.
        -- Top: White (Target color) or Pattern (Start color)
        
        -- Coords relative to 16,16 center roughly
        -- Top face (Rhombus)
        --      16,0
        --  2,8     30,8
        --     16,16
        gfx.setColor(gfx.kColorWhite)
        if self.state == 0 then
             -- Checker pattern for 'unset' state
             gfx.setPattern({0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA})
        end
        gfx.fillPolygon(16,0, 30,8, 16,16, 2,8)
        
        -- Left face (Parallelogram)
        --    2,8
        -- 16,16
        -- 16,30
        --  2,22
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer4x4)
        gfx.fillPolygon(2,8, 16,16, 16,30, 2,22)
        
        -- Right face
        --      30,8
        --     16,16
        --     16,30
        --      30,22
        gfx.setColor(gfx.kColorBlack) -- darker
        gfx.setDitherPattern(0.2, gfx.image.kDitherTypeBayer4x4) -- darker dither
        gfx.fillPolygon(16,16, 30,8, 30,22, 16,30)
        
        -- Outlines
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)
        gfx.drawPolygon(16,0, 30,8, 16,16, 2,8) -- Top
        gfx.drawLine(2,8, 2,22) -- Left edge
        gfx.drawLine(16,16, 16,30) -- Middle
        gfx.drawLine(30,8, 30,22) -- Right edge
        gfx.drawLine(2,22, 16,30) -- Bottom Left
        gfx.drawLine(16,30, 30,22) -- Bottom Right
        
    gfx.popContext()
    
    self:setImage(img)
    self:moveTo(x, y)
    self:add()
end

function Cube:changeColor()
    if self.state == 0 then
        self.state = 1
        -- Re-run init logic to draw new state (simpler than separate function for now)
        -- Actually, better to just call a draw function.
        -- For now, let's just copy the draw logic or make a new method 'drawCube'
        -- Or just create new image here.
        
        local img = self:getImage()
        gfx.pushContext(img)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillPolygon(16,0, 30,8, 16,16, 2,8) -- Top solid white
            gfx.setColor(gfx.kColorBlack)
            gfx.drawPolygon(16,0, 30,8, 16,16, 2,8) -- Outline
        gfx.popContext()
    end
end

function Cube:updateVisuals()
    local w = 32
    local h = 32
    local img = gfx.image.new(w, h, gfx.kColorClear)
    gfx.pushContext(img)
        -- Colors
        gfx.setColor(gfx.kColorWhite)
        if self.state == 0 then
             gfx.setPattern({0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA})
        else
             -- White for target state
        end
        gfx.fillPolygon(16,0, 30,8, 16,16, 2,8)
        
        gfx.setColor(gfx.kColorBlack)
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer4x4)
        gfx.fillPolygon(2,8, 16,16, 16,30, 2,22)
        
        gfx.setColor(gfx.kColorBlack) 
        gfx.setDitherPattern(0.2, gfx.image.kDitherTypeBayer4x4) 
        gfx.fillPolygon(16,16, 30,8, 30,22, 16,30)
        
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)
        gfx.drawPolygon(16,0, 30,8, 16,16, 2,8)
        gfx.drawLine(2,8, 2,22)
        gfx.drawLine(16,16, 16,30)
        gfx.drawLine(30,8, 30,22)
        gfx.drawLine(2,22, 16,30)
        gfx.drawLine(16,30, 30,22)
    gfx.popContext()
    self:setImage(img)
end
