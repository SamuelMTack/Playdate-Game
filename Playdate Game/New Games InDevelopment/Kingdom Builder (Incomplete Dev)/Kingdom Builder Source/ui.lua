local gfx = playdate.graphics

UI = {}

function UI.drawMenu()
    gfx.drawTextAligned("KINGDOM BUILDER", 200, 100, kTextAlignment.center)
    gfx.drawTextAligned("Press A to Start", 200, 130, kTextAlignment.center)
end

function UI.drawGame()
    -- Draw Board
    local cx, cy = Game.cam.x, Game.cam.y
    local tileSize = 30
    
    -- Draw placed tiles
    for k, tile in pairs(Game.board.tiles) do
        local x = cx + tile.x * tileSize
        local y = cy + tile.y * tileSize
        
        -- Cull
        if x > -30 and x < 400 and y > -30 and y < 240 then
            local img = tile:getImage()
            img:draw(x, y)
        end
    end
    
    -- Draw Cursor / Current Tile
    if Game.currentState == Game.STATE.PLACE then
        local x = cx + Game.cursor.x * tileSize
        local y = cy + Game.cursor.y * tileSize
        
        local img = Game.currentTile:getImage()
        img:drawFaded(x, y, 0.5, gfx.image.kDitherTypeBayer4x4)
        
        
        gfx.setLineWidth(2)
        gfx.drawRect(x, y, tileSize, tileSize)
        gfx.setLineWidth(1)
    elseif Game.currentState == Game.STATE.PLACE_MEEPLE then
        -- Draw Arrow/Highlight on the just-placed tile?
        -- We need to know WHERE the just placed tile is.
        -- It's at Game.cursor because we haven't moved it yet
        local x = cx + Game.cursor.x * tileSize
        local y = cy + Game.cursor.y * tileSize
        
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(x, y, tileSize, tileSize)
        
        -- Draw Meeple Ghost
        local mx, my = x + 15, y + 15
        if Game.meepleCursor == 1 then my = y + 5
        elseif Game.meepleCursor == 2 then mx = x + 25
        elseif Game.meepleCursor == 3 then my = y + 25
        elseif Game.meepleCursor == 4 then mx = x + 5
        end
        
        -- Blink
        if (playdate.getCurrentTimeMilliseconds() % 500) < 250 then
            gfx.fillCircleAtPoint(mx, my, 4)
        else
            gfx.drawCircleAtPoint(mx, my, 4)
        end
        
        -- Clear area for text
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(100, 215, 200, 25)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawTextAligned("A: Place  B: Skip", 200, 220, kTextAlignment.center)
    end
    
    -- HUD
    -- HUD
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, 400, 25)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(0, 0, 400, 25) -- Optional border
    gfx.drawText("Left: " .. #Game.deck, 5, 5)
    gfx.drawText("P1: " .. Game.scores[1] .. " ("..Game.meeples[1].."m)", 80, 5)
    gfx.drawText("P2: " .. Game.scores[2] .. " ("..Game.meeples[2].."m)", 200, 5)
    
    if Game.message ~= "" then
        -- Clear bottom area for message
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 215, 400, 25)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawTextAligned(Game.message, 200, 220, kTextAlignment.center)
    end
    
    -- Draw HELD TILE in Top Right
    if Game.currentState == Game.STATE.PLACE then
        local bx, by = 350, 30
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(bx, by, 40, 40)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(bx, by, 40, 40)
        
        -- Draw the tile simply?
        -- We can just use the image again but scaled? Or 30x30 centered
        local img = Game.currentTile:getImage()
        img:draw(bx+5, by+5)
        
        -- Draw Name below tile
        local name = Game.currentTile.name or "Tile"
        -- Draw text background to ensure readability over map?
        -- Actually this is in the corner, map might be there.
        -- Let's draw a white box behind text too.
        gfx.setColor(gfx.kColorWhite)
        local w, h = gfx.getTextSize(name)
        gfx.fillRect(bx+20 - w/2 - 2, by+45 - h/2, w+4, h)
        
        gfx.setImageDrawMode(gfx.kDrawModeCopy) -- Normal Black Text
        gfx.drawTextAligned(name, bx+20, by+45, kTextAlignment.center)
    end
end

function UI.drawGameOver()
    gfx.drawTextAligned("GAME OVER", 200, 100, kTextAlignment.center)
    gfx.drawTextAligned("Press A to Restart", 200, 130, kTextAlignment.center)
end
