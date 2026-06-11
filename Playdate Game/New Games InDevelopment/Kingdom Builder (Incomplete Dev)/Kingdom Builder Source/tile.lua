class('Tile').extends()

-- Edge Types
Tile.EDGE = {
    FIELD = 0,
    ROAD = 1,
    CITY = 2
}

-- Tile Definitions (north, east, south, west, center_feature)
-- Center: 0=None/Field, 1=Road, 2=City, 3=Monastery, 4=Crossroads
Tile.TYPES = {
    {edges={1, 0, 1, 0}, center=1, name="Road Straight"},
    {edges={1, 1, 0, 0}, center=1, name="Road Curve"},
    {edges={1, 1, 1, 0}, center=4, name="Road T-Split"},
    {edges={1, 1, 1, 1}, center=4, name="Road Cross"},
    {edges={2, 2, 2, 2}, center=2, shield=true, name="City (Shield)"},
    {edges={2, 2, 2, 2}, center=2, name="City Information"},
    {edges={0, 2, 0, 2}, center=2, shield=true, name="City Bridge (S)"},
    {edges={0, 2, 0, 2}, center=2, name="City Bridge"},
    {edges={2, 0, 0, 0}, center=0, name="City Cap"},
    {edges={2, 1, 1, 2}, center=1, name="Road thru City"},
    {edges={2, 1, 1, 0}, center=1, name="City w/ Road"},
    {edges={2, 0, 1, 1}, center=1, name="City w/ Road"},
    {edges={0, 0, 0, 0}, center=3, name="Monastery"},
    {edges={0, 0, 1, 0}, center=3, name="Monastery Rd"},
    {edges={2, 2, 0, 0}, center=2, name="City Wedge"}
}

function Tile:init(typeIndex)
    self.typeIndex = typeIndex
    self.edges = {table.unpack(Tile.TYPES[typeIndex].edges)} -- Copy
    self.center = Tile.TYPES[typeIndex].center
    self.shield = Tile.TYPES[typeIndex].shield or false
    self.name = Tile.TYPES[typeIndex].name
    self.rotation = 0 -- 0, 1, 2, 3 (90 degree steps clockwise)
    self.meeple = nil -- 1 or 2 (Player Index)
    self.meepleSpot = nil -- 0=Center, 1=N, 2=E, 3=S, 4=W
end

function Tile:rotate()
    self.rotation = (self.rotation + 1) % 4
    -- Rotate edges array
    local last = self.edges[4]
    table.remove(self.edges, 4)
    table.insert(self.edges, 1, last)
end

function Tile:getImage()
    local img = playdate.graphics.image.new(30, 30)
    playdate.graphics.pushContext(img)
        -- 1. Draw Field (Grass) Base
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
        playdate.graphics.setDitherPattern(0.2, playdate.graphics.image.kDitherTypeBayer8x8) -- Light grass
        playdate.graphics.fillRect(0, 0, 30, 30)
        
        -- Reset to solid for drawing features
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
        
        -- 2. Draw City Segments
        -- Define City Pattern: Darker
        playdate.graphics.setDitherPattern(0.7, playdate.graphics.image.kDitherTypeBayer4x4)
        
        local cx, cy = 15, 15
        local dirs = {{15,0}, {30,15}, {15,30}, {0,15}} -- N, E, S, W
        local corners = {{0,0}, {30,0}, {30,30}, {0,30}} -- TL, TR, BR, BL
        
        if self.center == 2 then -- Center is City
             if self.edges[1]==2 and self.edges[2]==2 and self.edges[3]==2 and self.edges[4]==2 then
                 -- All City
                 playdate.graphics.fillRect(0,0,30,30)
             else
                 -- Fill simplified polygon to connect city edges to center
                 -- Draw a big rect in middle and connect to edges
                 playdate.graphics.fillRect(5, 5, 20, 20)
                 for i=1, 4 do
                     if self.edges[i] == 2 then
                         if i==1 then playdate.graphics.fillRect(5, 0, 20, 10)
                         elseif i==2 then playdate.graphics.fillRect(20, 5, 10, 20)
                         elseif i==3 then playdate.graphics.fillRect(5, 20, 20, 10)
                         elseif i==4 then playdate.graphics.fillRect(0, 5, 10, 20)
                         end
                     end
                 end
                 -- If corner between two city edges, fill the corner too?
                 -- Carcassonne logic: if N and E are city, TR corner is usually city.
                 for i=1, 4 do
                     local nextI = (i % 4) + 1
                     if self.edges[i] == 2 and self.edges[nextI] == 2 then
                         -- Fill Corner
                         if i==1 then playdate.graphics.fillRect(15, 0, 15, 15) -- TR
                         elseif i==2 then playdate.graphics.fillRect(15, 15, 15, 15) -- BR
                         elseif i==3 then playdate.graphics.fillRect(0, 15, 15, 15) -- BL
                         elseif i==4 then playdate.graphics.fillRect(0, 0, 15, 15) -- TL
                         end
                     end
                 end
             end
        else
            -- Disconnected Cities (Caps, Bridges)
             for i=1, 4 do
                 if self.edges[i] == 2 then
                     -- Draw Cap (Semi-circleish)
                     if i==1 then playdate.graphics.fillEllipseInRect(5, -10, 20, 20)
                     elseif i==2 then playdate.graphics.fillEllipseInRect(20, 5, 20, 20)
                     elseif i==3 then playdate.graphics.fillEllipseInRect(5, 20, 20, 20)
                     elseif i==4 then playdate.graphics.fillEllipseInRect(-10, 5, 20, 20)
                     end
                 end
             end
             -- Bridge (Tunnel) Logic
             if self.name == "City Bridge" or self.name == "City Bridge (S)" then
                  -- Draw narrower bridge with clear walls
                  if self.edges[1]==2 and self.edges[3]==2 then 
                      playdate.graphics.fillRect(10,0,10,30) -- N-S
                      playdate.graphics.setColor(playdate.graphics.kColorBlack)
                      playdate.graphics.drawLine(10, 0, 10, 30) -- Left Wall
                      playdate.graphics.drawLine(20, 0, 20, 30) -- Right Wall
                  end
                  if self.edges[2]==2 and self.edges[4]==2 then 
                      playdate.graphics.fillRect(0,10,30,10) -- E-W
                      playdate.graphics.setColor(playdate.graphics.kColorBlack)
                      playdate.graphics.drawLine(0, 10, 30, 10) -- Top Wall
                      playdate.graphics.drawLine(0, 20, 30, 20) -- Bottom Wall
                  end
                  -- Reapply pattern for next draws if necessary (though strict scope controls this)
                  playdate.graphics.setDitherPattern(0.7, playdate.graphics.image.kDitherTypeBayer4x4)
             end
        end
        
        -- Draw City Outlines (Walls)
        playdate.graphics.setColor(playdate.graphics.kColorBlack) -- Solid Black
        -- We can just outline the same shapes logic but creating it is hard.
        -- Alternative: Draw Thick Black lines at boundaries.
        -- Or just rely on contrast. Let's add simple edge lines for now.
        
        
        -- 3. Draw Roads (White with Black Outline)
        for i=1, 4 do
            if self.edges[i] == 1 then
                -- Draw simple thick black line first as border
                playdate.graphics.setLineWidth(5)
                playdate.graphics.drawLine(cx, cy, dirs[i][1], dirs[i][2])
            end
        end
        
        -- Draw Road Connections (Curve/Straight) logic roughly
        -- If center is road/crossroads/monasteryRD, we connect to center
         if self.center == 1 or self.center == 4 or self.center == 3 then
             -- No specific logic needed if we just draw lines to center, but curves look pointy.
             -- Improved Curve: if adjacent edges are roads, draw Bezier? Too complex for rapid fix.
             -- Keep lines for now but make them white on top of black.
         end
         
         playdate.graphics.setColor(playdate.graphics.kColorWhite)
         for i=1, 4 do
            if self.edges[i] == 1 then
                playdate.graphics.setLineWidth(3)
                playdate.graphics.drawLine(cx, cy, dirs[i][1], dirs[i][2])
            end
        end
        
        -- 4. Draw Features
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
        if self.center == 3 then -- Monastery
            playdate.graphics.fillRect(10, 10, 10, 10)
            playdate.graphics.setColor(playdate.graphics.kColorWhite)
            playdate.graphics.fillTriangle(10, 15, 20, 15, 15, 10) -- Roof
            playdate.graphics.drawRect(12, 16, 6, 4) -- Base
        end
        
        -- 5. Draw Shield
        if self.shield then
            playdate.graphics.setColor(playdate.graphics.kColorBlack)
            playdate.graphics.fillPolygon(22, 5, 28, 5, 25, 11) 
            playdate.graphics.setColor(playdate.graphics.kColorWhite)
            playdate.graphics.drawPolygon(22, 5, 28, 5, 25, 11)
            playdate.graphics.drawLine(25, 5, 25, 11)
        end
        
        -- Border
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
        playdate.graphics.setLineWidth(1)
        playdate.graphics.drawRect(0, 0, 30, 30)
        
         -- Draw Meeple if placed
        if self.meeple then
             if self.meeple == 1 then
                playdate.graphics.setColor(playdate.graphics.kColorBlack)
             else
                playdate.graphics.setColor(playdate.graphics.kColorWhite)
             end
             
             local mx, my = cx, cy
             if self.meepleSpot == 1 then my = 5
             elseif self.meepleSpot == 2 then mx = 25
             elseif self.meepleSpot == 3 then my = 25
             elseif self.meepleSpot == 4 then mx = 5
             end
             
             playdate.graphics.fillCircleAtPoint(mx, my, 4)
             playdate.graphics.setColor(playdate.graphics.kColorBlack)
             playdate.graphics.drawCircleAtPoint(mx, my, 4)
             if self.meeple == 2 then
                 playdate.graphics.drawCircleAtPoint(mx, my, 1) -- Dot for P2
             end
        end
        
    playdate.graphics.popContext()
    return img
end
