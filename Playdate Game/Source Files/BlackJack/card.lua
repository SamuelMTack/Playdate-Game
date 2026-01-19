local gfx = playdate.graphics

class('Card').extends(gfx.sprite)

function Card:init(suit, rank, value)
    self.suit = suit -- "H", "D", "C", "S"
    self.rank = rank -- "A", "2"..."10", "J", "Q", "K"
    self.value = value -- 1-11
    
    local width, height = 40, 60
    local img = gfx.image.new(width, height)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, width, height)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(0, 0, width, height) -- Border
        
        
        
        -- Draw Rank (Top-Left)
        gfx.drawText(self.rank, 3, 3)
        
        -- Draw Rank (Bottom-Right, no rotation so just text)
        local font = gfx.getFont()
        local tw = font:getTextWidth(self.rank)
        gfx.drawText(self.rank, width - tw - 3, height - 15)
        
        -- Draw Suit Symbol (Center)
        local cx, cy = width/2, height/2
        if self.suit == "H" or self.suit == "D" then
             -- Red suits (No color on PD, but we can fill vs outline if we wanted, let's Stick to Black/White)
             -- Actually Standard PD is 1-bit. We'll draw filled black shape.
        end
        
        if self.suit == "H" then -- Heart
            gfx.fillEllipseInRect(cx-6, cy-6, 7, 7) -- Left bump
            gfx.fillEllipseInRect(cx-1, cy-6, 7, 7) -- Right bump
            -- Triangle bottom
            gfx.fillPolygon(cx-6, cy-2, cx+6, cy-2, cx, cy+6)
        elseif self.suit == "D" then -- Diamond
            gfx.fillPolygon(cx, cy-7, cx+6, cy, cx, cy+7, cx-6, cy)
        elseif self.suit == "C" then -- Club
            gfx.fillCircleAtPoint(cx, cy-4, 3) -- Top
            gfx.fillCircleAtPoint(cx-4, cy+1, 3) -- Left
            gfx.fillCircleAtPoint(cx+4, cy+1, 3) -- Right
            gfx.fillTriangle(cx, cy, cx-2, cy+7, cx+2, cy+7) -- Stem
        elseif self.suit == "S" then -- Spade
            gfx.fillEllipseInRect(cx-6, cy-4, 7, 7) -- Left bump
            gfx.fillEllipseInRect(cx-1, cy-4, 7, 7) -- Right bump
            gfx.fillPolygon(cx-6, cy, cx+6, cy, cx, cy-7) -- Point up inverse of heart? Spade points UP.
            -- Actually Spade is heart upside down with stem.
            -- Correct Spade: Point at Top (cy-7). Bumps at bottom (cy).
            -- Let's redraw Spade better:
            gfx.fillPolygon(cx, cy-7, cx+6, cy+1, cx-6, cy+1) -- Main body triangle-ish
            gfx.fillEllipseInRect(cx-6, cy-2, 7, 7) -- Left bump (bulge)
            gfx.fillEllipseInRect(cx-1, cy-2, 7, 7) -- Right bump
            gfx.fillTriangle(cx, cy+2, cx-2, cy+7, cx+2, cy+7) -- Stem
        end
    gfx.popContext()
    self:setImage(img)
    self:setZIndex(10)
end

function Card:addAt(x, y)
    self:moveTo(x, y)
    self:add()
end
