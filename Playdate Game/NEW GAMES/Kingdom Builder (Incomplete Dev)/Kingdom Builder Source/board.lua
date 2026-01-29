class('Board').extends()

function Board:init()
    self.tiles = {} -- Key format "x,y" -> Tile object
    self.minX, self.maxX = 0, 0
    self.minY, self.maxY = 0, 0
    -- Place starting tile
    self:placeTile(0, 0, Tile(2)) -- Road Curve as start
end

function Board:placeTile(x, y, tile)
    self.tiles[x .. "," .. y] = tile
    tile.x = x
    tile.y = y
    
    self.minX = math.min(self.minX, x)
    self.maxX = math.max(self.maxX, x)
    self.minY = math.min(self.minY, y)
    self.maxY = math.max(self.maxY, y)
end

function Board:getTile(x, y)
    return self.tiles[x .. "," .. y]
end

function Board:canPlace(x, y, tile)
    if self:getTile(x, y) then return false end -- Occupied
    
    local neighbors = {
        {x=0, y=-1, opp=3, my=1}, -- N, opposes S (3)
        {x=1, y=0, opp=4, my=2},  -- E, opposes W (4)
        {x=0, y=1, opp=1, my=3},  -- S, opposes N (1)
        {x=-1, y=0, opp=2, my=4}  -- W, opposes E (2)
    }
    
    local hasNeighbor = false
    
    for _, n in ipairs(neighbors) do
        local neighborTile = self:getTile(x + n.x, y + n.y)
        if neighborTile then
            hasNeighbor = true
            -- Check edge matching
            if tile.edges[n.my] ~= neighborTile.edges[n.opp] then
                return false
            end
        end
    end
    
    return hasNeighbor
end

function Board:getValidMoves(tile)
    local moves = {}
    -- Naive approach: check empty spots around all existing tiles
    local checked = {}
    
    for k, t in pairs(self.tiles) do
        local neighbors = {{0,-1}, {1,0}, {0,1}, {-1,0}}
        for _, n in ipairs(neighbors) do
            local tx, ty = t.x + n[1], t.y + n[2]
            local key = tx .. "," .. ty
            if not self.tiles[key] and not checked[key] then
                checked[key] = true
                -- Try all rotations
                for r=0, 3 do
                    if self:canPlace(tx, ty, tile) then
                         table.insert(moves, {x=tx, y=ty, rot=r})
                    end
                    tile:rotate()
                end
            end
        end
    end
    return moves
end

function Board:checkScoring(tile)
    local results = {}
    
    -- 1. Check Monastery (Self)
    if tile.center == 3 then
        local score = self:checkMonastery(tile)
        if score == 9 then table.insert(results, {type="Monastery", score=9, tile=tile}) end
    end
    
    -- 2. Check Neighbor Monasteries
    local neighbors = {{0,-1}, {1,0}, {0,1}, {-1,0}, {-1,-1}, {1,-1}, {-1,1}, {1,1}}
    for _, n in ipairs(neighbors) do
        local nt = self:getTile(tile.x+n[1], tile.y+n[2])
        if nt and nt.center == 3 then
            local score = self:checkMonastery(nt)
            if score == 9 then table.insert(results, {type="Monastery (Neighbor)", score=9, tile=nt}) end
        end
    end
    
    -- 3. Check Roads/Cities (Features connected to edges)
    -- We need to traverse from each edge of the new tile
    local checkedFeatures = {} -- Avoid duplicate reports
    for i=1, 4 do
        local edgeType = tile.edges[i]
        if edgeType == 1 or edgeType == 2 then -- Road or City
             -- Check if complete
             local isClosed, tiles, meeples, shields = self:traverseFeature(tile, i, edgeType)
             if isClosed then
                 -- Calculate Score
                 local score = 0
                 if edgeType == 1 then score = #tiles -- Road 1pt
                 else score = (#tiles * 2) + (shields * 2) end -- City 2pts + 2/shield
                 
                 -- Determine Winner (Who has most meeples?)
                 local p1 = 0
                 local p2 = 0
                 for _, m in ipairs(meeples) do
                     if m == 1 then p1 = p1 + 1 else p2 = p2 + 1 end
                 end
                 
                 local winner = 0
                 if p1 > p2 then winner = 1
                 elseif p2 > p1 then winner = 2
                 elseif p1 > 0 and p1 == p2 then winner = 3 -- Tie
                 end
                 
                 if winner > 0 and not self:featureAlreadyScored(tiles, edgeType) then
                     table.insert(results, {type=(edgeType==1 and "Road" or "City"), score=score, winner=winner, meeples=meeples, tiles=tiles})
                 end
             end
        end
    end
    
    return results
end

function Board:checkMonastery(tile)
    local count = 0
    for y=-1, 1 do
        for x=-1, 1 do
            if self:getTile(tile.x+x, tile.y+y) then count = count + 1 end
        end
    end
    return count
end

function Board:traverseFeature(startTile, startEdge, type)
    -- Graph traversal (BFS/DFS)
    -- We need to track visited EDGES, not just tiles, because a tile can have multiple separate roads
    local visited = {} -- Key: "x,y,edgeIndex"
    local queue = {{t=startTile, e=startEdge}}
    local tileSet = {} -- Unique tiles
    tileSet[startTile.x..","..startTile.y] = startTile
    local meeples = {}
    local shields = 0
    if startTile.shield then shields = 1 end -- Rough counting, might double count if loop, handle carefully
    
    -- Check if start tile has meeple on this feature
    -- Map MeepleSpot (0-4) to edges?
    -- 0: Center. 1: N. 2: E. 3: S. 4: W.
    -- If center matches type?
    -- Complexity: "Center" feature connects edges.
    -- E.g. Road Cross (4) connects N,E,S,W.
    -- Road T (4) connects 3 edges.
    -- Road Straight (1) connects N-S or E-W.
    
    -- Simplified Logic:
    -- If meeple spot matches the edge direction OR is Center and Center connects to edge... 
    -- For now assume simpler connectivity provided by Tile definitions is implicitly trusted
    
    local isClosed = true
    
    while #queue > 0 do
        local curr = table.remove(queue, 1)
        local t, e = curr.t, curr.e
        
        -- Check Logic:
        -- From tile t, edge e, we go to Neighbor in direction e
        -- DIR: 1=N, 2=E, 3=S, 4=W
        local dx, dy = 0, 0
        local nextOpp = 0
        if e == 1 then dx=0; dy=-1; nextOpp=3
        elseif e == 2 then dx=1; dy=0; nextOpp=4
        elseif e == 3 then dx=0; dy=1; nextOpp=1
        elseif e == 4 then dx=-1; dy=0; nextOpp=2
        end
        
        local nextTile = self:getTile(t.x+dx, t.y+dy)
        if not nextTile then
            isClosed = false -- Open end!
        else
            -- Visit neighbor
            -- But does the neighbor connect internally?
            -- We entered neighbor at 'nextOpp'.
            -- We need to find all edges linked to 'nextOpp' on nextTile.
            -- This requires "Internal Connectivity" data on Tile.
            
            -- FOR MVP: Assume roads connect opposing sides for Straights, or Adjacent for curves...
            -- We need lookup table for internal paths.
            -- Or just Flood Fill recursively on the Tile's logical graph.
            
            -- Let's just create a list of edges connected to 'nextOpp' on NextTile
            local connectedEdges = self:getConnectedEdges(nextTile, nextOpp)
            
            for _, ce in ipairs(connectedEdges) do
                local key = nextTile.x..","..nextTile.y..","..ce
                if not visited[key] then
                    visited[key] = true
                    table.insert(queue, {t=nextTile, e=ce})
                    tileSet[nextTile.x..","..nextTile.y] = nextTile
                    -- Check Meeple
                    if nextTile.meepleSpot == ce or (nextTile.meepleSpot == 0 and Utils.centerConnects(nextTile, ce)) then
                         if nextTile.meeple then table.insert(meeples, nextTile.meeple) end
                    end
                     if nextTile.shield and not nextTile.shieldCounted then
                        shields = shields + 1
                        nextTile.shieldCounted = true -- Hacky temp flag, clear later?
                    end
                end
            end
        end
    end
    
    -- Cleanup flags
    for k,t in pairs(tileSet) do t.shieldCounted = nil end
    local tileList = {}
    for k,t in pairs(tileSet) do table.insert(tileList, t) end
    
    return isClosed, tileList, meeples, shields
end

-- Helper: Returns list of edge indices connected to 'inputEdge' on 'tile'
function Board:getConnectedEdges(tile, inputEdge)
    -- This relies on Tile Type logic. 
    -- Road Straight: 1<->3, 2<->4
    -- Road Curve: 1<->2, etc.
    -- All City: 1,2,3,4 connected.
    -- City Tunnel: 1<->3, 2<->4 (separate).
    
    -- Simplification: If Center matches EdgeType, ALL edges of that type are connected via center.
    -- Exception: City Tunnel (Bridge) and Road Straight/Cross? No, Road Cross connects all 4? yes.
    -- Road straight connects pairs.
    
    local type = tile.edges[inputEdge]
    local rotation = tile.rotation
    
    -- We need to reverse-engineer logical connections from visual edges...
    -- Or just hardcode "ConnectedGroups" in Tile definition.
    -- Let's assume for MVP: If it hits center, it connects to all others hitting center.
    -- If center is diff, it connects to nothing (cap)? OR logic is messy.
    
    -- MVP Hack: Just return all edges of same type on this tile.
    -- This treats "City Tunnel" as "City Cross" (connected). Acceptable for V1.
    local connected = {}
    for i=1, 4 do
        if i ~= inputEdge and tile.edges[i] == type then
            table.insert(connected, i)
        end
    end
    return connected
end

function Board:featureAlreadyScored(tiles, type)
    -- Check if these tiles have been marked as scored for this feature type?
    -- Complexity high. Skip for now, assume player won't re-trigger?
    -- Actually essential. We can mark tiles "RoadScored = true".
    for _, t in ipairs(tiles) do
        if type == 1 and t.roadScored then return true end
        if type == 2 and t.cityScored then return true end
    end
    return false
end

