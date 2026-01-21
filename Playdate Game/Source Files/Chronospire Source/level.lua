import "kinetic_obj"

local gfx = playdate.graphics

Level = {}
Level.walls = {}
Level.objects = {}
Level.spawnX = 50
Level.goal = nil

class('Goal').extends(gfx.sprite)

function Goal:init(x, y)
    Goal.super.init(self)
    self:moveTo(x, y)
    local w, h = 20, 30
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(0, 0, w, h)
        -- Chequered flag pattern
        for i=0, w, 5 do
            for j=0, h, 5 do
                if (i+j)%10 == 0 then gfx.fillRect(i, j, 5, 5) end
            end
        end
    gfx.popContext()
    self:setImage(image)
    -- triggers don't need physical collision
end

function Level.load(levelNum)
    Level.clear()
    
    if levelNum == 1 then
        -- Basic Floor
        Level.addWall(0, 200, 400, 40)
        
        -- Platforms
        Level.addWall(100, 160, 50, 10)
        Level.addWall(250, 130, 50, 10)
        
        -- Kinetic Objects
        local r1 = Rotator(200, 100, 80, 20)
        r1:add()
        table.insert(Level.objects, r1)
        
        -- Goal
        local g = Goal(350, 185)
        g:add()
        Level.goal = g
        
        -- Start pos
        Level.spawnX = 20
        Level.spawnY = 180
        
    elseif levelNum == 2 then
        -- Level 2: The Climb
        Level.addWall(0, 220, 400, 20) -- Floor
        
        -- Pistons
        local p1 = Piston(100, 180, 50, "y")
        p1:add()
        table.insert(Level.objects, p1)
        
        local p2 = Piston(200, 120, 60, "y")
        p2:add()
        table.insert(Level.objects, p2)
        
        -- Rotator
        local r2 = Rotator(300, 80, 60, 10)
        r2:add()
        table.insert(Level.objects, r2)
        
        -- Goal (High up)
        Level.addWall(350, 60, 50, 10)
        local g = Goal(370, 45)
        g:add()
        Level.goal = g
        
        Level.spawnX = 20
        Level.spawnY = 200
        
    elseif levelNum == 3 then
        -- Level 3: Clocktower (Vertical Rotators)
        Level.addWall(0, 230, 400, 10) 
        
        -- Stacked gears
        local r1 = Rotator(100, 180, 70, 15)
        r1:add()
        table.insert(Level.objects, r1)
        
        local r2 = Rotator(200, 130, 70, 15)
        r2:add()
        table.insert(Level.objects, r2)
        
        local r3 = Rotator(300, 80, 70, 15)
        r3:add()
        table.insert(Level.objects, r3)
        
        Level.addWall(350, 50, 50, 10)
        local g = Goal(370, 35)
        g:add()
        Level.goal = g
        
        Level.spawnX = 20
        Level.spawnY = 200
        
    elseif levelNum == 4 then
        -- Level 4: Piston Press
        Level.addWall(0, 230, 400, 10)
        
        -- Horizontal Pistons reducing gap
        local p1 = Piston(80, 180, 40, "y")
        p1:add()
        table.insert(Level.objects, p1)
        
        local p2 = Piston(160, 160, -40, "y") -- Move opposite
        p2:add()
        table.insert(Level.objects, p2)
        
        local p3 = Piston(240, 140, 40, "y")
        p3:add()
        table.insert(Level.objects, p3)
        
        local p4 = Piston(320, 120, -40, "y")
        p4:add()
        table.insert(Level.objects, p4)
        
        Level.addWall(370, 100, 30, 10)
        local g = Goal(380, 85)
        g:add()
        Level.goal = g
        
        Level.spawnX = 20
        Level.spawnY = 200
        
    elseif levelNum == 5 then
        -- Level 5: The Summit
        Level.addWall(0, 230, 50, 10) -- Tiny start floor
        
        local r1 = Rotator(100, 200, 60, 10)
        r1:add()
        table.insert(Level.objects, r1)
        
        local p1 = Piston(180, 150, 50, "y")
        p1:add()
        table.insert(Level.objects, p1)
        
        local r2 = Rotator(260, 100, 80, 10)
        r2:add()
        table.insert(Level.objects, r2)
        
        local p2 = Piston(340, 60, 30, "y")
        p2:add()
        table.insert(Level.objects, p2)
        
        Level.addWall(360, 40, 40, 10)
        local g = Goal(380, 25)
        g:add()
        Level.goal = g
        
        Level.spawnX = 10
        Level.spawnY = 200
    end
end

function Level.addWall(x, y, w, h)
    local wall = gfx.sprite.new()
    wall:setCenter(0, 0)
    wall:moveTo(x, y)
    
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(0, 0, w, h)
        -- Hatching for style
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeDiagonalLine)
        gfx.fillRect(0, 0, w, h)
    gfx.popContext()
    
    wall:setImage(image)
    wall:setCollideRect(0, 0, w, h)
    wall:add()
    
    table.insert(Level.walls, wall)
end

function Level.update()
    -- Objects update themselves via sprite system
end

function Level.clear()
    for _, wall in ipairs(Level.walls) do wall:remove() end
    for _, obj in ipairs(Level.objects) do obj:remove() end
    Level.walls = {}
    Level.objects = {}
    if Level.goal then Level.goal:remove() end
    Level.walls = {}
    Level.objects = {}
    Level.goal = nil
end
