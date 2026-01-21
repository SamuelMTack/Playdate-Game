local gfx = playdate.graphics

UI = {}

function UI.drawMenu()
    gfx.drawTextAligned("CHRONOSPIRE", 200, 80, kTextAlignment.center)
    gfx.drawTextAligned("Press A to Start", 200, 140, kTextAlignment.center)
    
    -- Decorative rotating gears
    local crank = playdate.getCrankPosition()
    gfx.drawCircleAtPoint(100, 120, 30)
    gfx.drawLine(100, 120, 100 + 30 * math.cos(math.rad(crank)), 120 + 30 * math.sin(math.rad(crank)))
    
    gfx.drawCircleAtPoint(300, 120, 30)
    gfx.drawLine(300, 120, 300 + 30 * math.cos(math.rad(crank+45)), 120 + 30 * math.sin(math.rad(crank+45)))
end

function UI.drawHUD()
    -- Crank Indicator
    local crank = playdate.getCrankPosition()
    local cx, cy = 380, 220
    local r = 15
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawCircleAtPoint(cx, cy, r)
    gfx.drawLine(cx, cy, cx + r * math.cos(math.rad(crank)), cy + r * math.sin(math.rad(crank)))
    
    -- Stopwatch (Game Timer)
    local s = math.floor(playdate.getCurrentTimeMilliseconds() / 1000)
    gfx.drawText("T: " .. s, 10, 220)
end
