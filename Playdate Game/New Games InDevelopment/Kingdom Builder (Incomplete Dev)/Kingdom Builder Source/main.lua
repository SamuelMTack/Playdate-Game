import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics

Utils = {}
function Utils.centerConnects(tile, edge)
    return true -- For now assume center connects to everything
end

import "tile"
import "board"
import "game"
import "ui"
import "ai"

math.randomseed(playdate.getSecondsSinceEpoch())

function playdate.update()
    gfx.clear()
    Game.update()
    Game.draw()
    playdate.timer.updateTimers()
end
