import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics

import "game"

-- Seed random
math.randomseed(playdate.getSecondsSinceEpoch())

function playdate.update()
    gfx.clear()
    Game.update()
    Game.draw()
    playdate.timer.updateTimers()
end
