local pd <const> = playdate
local gfx <const> = pd.graphics

class('Bullet').extends(gfx.sprite)

function Bullet:init(x, y)
    local img = gfx.image.new(4, 8, gfx.kColorBlack)
    gfx.pushContext(img)
        gfx.fillRect(0, 0, 4, 8)
    gfx.popContext()
    
    self:setImage(img)
    self:moveTo(x, y)
    self:setCollideRect(0, 0, 4, 8)
    self:add()
    
    self.speed = 10
end

function Bullet:update()
    self:moveBy(0, -self.speed)
    if self.y < -10 then
        self:remove()
        return
    end
    
    -- Collision with Mushrooms
    if MUSHROOMS then
        local x,y,w,h = self:getBounds()
        for _, m in ipairs(MUSHROOMS) do
            local mx,my,mw,mh = m:getBounds()
            if x < mx + mw and x + w > mx and y < my + mh and y + h > my then
                m:hit()
                self:remove()
                return
            end
        end
    end
    
    -- Collision with Centipede
    if CENTIPEDES then
        local x,y,w,h = self:getBounds()
        for i, c in ipairs(CENTIPEDES) do
            local cx,cy,cw,ch = c:getBounds()
            if x < cx + cw and x + w > cx and y < cy + ch and y + h > cy then
                -- Kill segment
                table.remove(CENTIPEDES, i)
                c:remove()
                
                -- Spawn Mushroom at its place
                local m = Mushroom(c.x, c.y)
                table.insert(MUSHROOMS, m)
                
                SCORE = SCORE + 100
                self:remove()
                return
            end
        end
    end
end
