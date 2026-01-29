local gfx = playdate.graphics

UI = {}
UI.cellSize = 20
UI.offsetX = 100
UI.offsetY = 20

function UI.drawTitle()
    gfx.drawText("COMMANDERS SHIP", 100, 50)
    
    local txt1 = "1 Player (vs AI)"
    local txt2 = "2 Players (Hotseat)"
    
    if Game.mode == Game.MODE.PVE then txt1 = "> " .. txt1 end
    if Game.mode == Game.MODE.PVP then txt2 = "> " .. txt2 end
    
    gfx.drawText(txt1, 80, 100)
    gfx.drawText(txt2, 80, 130)
end

function UI.drawGrid(board, hideShips)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2) -- Thicker grid lines
    
    local w, h = 10, 10
    
    -- Outline
    gfx.drawRect(UI.offsetX, UI.offsetY, w * UI.cellSize, h * UI.cellSize)
    
    gfx.setLineWidth(1)
    for y=1, 10 do
        for x=1, 10 do
            local cellX = UI.offsetX + (x-1)*UI.cellSize
            local cellY = UI.offsetY + (y-1)*UI.cellSize
            
            -- Grid lines (inner)
            gfx.drawRect(cellX, cellY, UI.cellSize, UI.cellSize)
            
            local val = board.grid[y][x]
            if val == 1 and not hideShips then
                -- Draw Ship Segment (Filled Box with rounded corners)
                gfx.fillRoundRect(cellX+2, cellY+2, UI.cellSize-4, UI.cellSize-4, 3)
            elseif val == 2 then -- Miss (Cross or Splash)
                gfx.drawLine(cellX+4, cellY+4, cellX+UI.cellSize-4, cellY+UI.cellSize-4)
                gfx.drawLine(cellX+UI.cellSize-4, cellY+4, cellX+4, cellY+UI.cellSize-4)
            elseif val == 3 then -- Hit (Explosion / Circle)
                 -- Draw Ship Underneath if needed, but HIT covers it usually, or combine
                 if not hideShips then
                    gfx.drawRoundRect(cellX+2, cellY+2, UI.cellSize-4, UI.cellSize-4, 3) -- Ghost of ship
                 end
                 
                 gfx.setColor(gfx.kColorBlack)
                 gfx.fillCircleAtPoint(cellX + UI.cellSize/2, cellY + UI.cellSize/2, 6)
                 -- Inner white dot
                 gfx.setColor(gfx.kColorWhite)
                 gfx.fillCircleAtPoint(cellX + UI.cellSize/2, cellY + UI.cellSize/2, 2)
                 gfx.setColor(gfx.kColorBlack)
            end
        end
    end
end

function UI.drawSetup(board)
    gfx.drawText("Place Ship " .. Game.setupShipIndex, 10, 5)
    UI.drawGrid(board, false)
    
    -- Draw Cursor Ghost w/ Validity Check
    local len = Game.shipsToPlace[Game.setupShipIndex]
    
    if len then
        local isValid = board:canPlace(Game.cursor.x, Game.cursor.y, len, Game.setupHoriz)
        
        -- Dotted pattern for ghost? Or just outline
        if isValid then
            gfx.setLineWidth(2)
        else
            -- Blink if invalid
            if (playdate.getCurrentTimeMilliseconds() % 500) < 250 then
                 gfx.setLineWidth(1)
            else
                 return -- Don't draw
            end
        end
        
        for i=0, len-1 do
            local gx, gy = Game.cursor.x, Game.cursor.y
            if Game.setupHoriz then gx = gx + i else gy = gy + i end
            
            -- Only draw if within bounds (visual check, though logic handles it)
            if gx <= 10 and gy <= 10 then
                local cx = UI.offsetX + (gx-1)*UI.cellSize
                local cy = UI.offsetY + (gy-1)*UI.cellSize
                
                if isValid then
                     -- Draw solid rounded rect
                     gfx.drawRoundRect(cx+2, cy+2, UI.cellSize-4, UI.cellSize-4, 3)
                else
                     -- Draw X or Dotted
                     gfx.drawLine(cx+2, cy+2, cx+UI.cellSize-4, cy+UI.cellSize-4)
                     gfx.drawLine(cx+UI.cellSize-4, cy+2, cx+2, cy+UI.cellSize-4)
                end
            end
        end
        gfx.setLineWidth(1)
    end
end

function UI.drawBattle(playerIndex, enemyBoard)
    gfx.drawText("Player " .. playerIndex .. " Attack", 10, 5)
    
    UI.drawGrid(enemyBoard, true) -- Hide ships
    
    -- Cursor
    local cx = UI.offsetX + (Game.cursor.x-1)*UI.cellSize
    local cy = UI.offsetY + (Game.cursor.y-1)*UI.cellSize
    gfx.setLineWidth(3)
    gfx.drawRect(cx, cy, UI.cellSize, UI.cellSize)
    gfx.setLineWidth(1)
    
    if Game.message ~= "" then
        gfx.drawText(Game.message, 10, 220)
    end
end

function UI.drawTransition()
    gfx.fillRect(0, 0, 400, 240)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("PASS THE DEVICE", 200, 100, kTextAlignment.center)
    gfx.drawTextAligned("Press A to Continue", 200, 130, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function UI.drawGameOver()
    gfx.fillRect(50, 80, 300, 80)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("GAME OVER", 200, 100, kTextAlignment.center)
    local winnerText = (Game.winner == 1) and "Player 1 Wins!" or "Player 2 Wins!"
    gfx.drawTextAligned(winnerText, 200, 130, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end
