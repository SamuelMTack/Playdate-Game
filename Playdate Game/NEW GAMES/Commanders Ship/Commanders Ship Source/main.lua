import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics

import "board"
import "ui"
import "ai"
import "game"

math.randomseed(playdate.getSecondsSinceEpoch())

function playdate.update()
    gfx.clear()
    Game.update()
    Game.draw()
    playdate.timer.updateTimers()
end
