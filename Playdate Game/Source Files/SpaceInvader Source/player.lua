local gfx = playdate.graphics

local playerSprite = nil
local playerSpeed = 4

function createPlayer()
    local playerImage = gfx.image.new(20, 10)
    gfx.pushContext(playerImage)
        gfx.fillRect(0, 0, 20, 10) -- Simple rectangle for now
    gfx.popContext()

    playerSprite = gfx.sprite.new(playerImage)
    playerSprite:moveTo(200, 220)
    playerSprite:setCollideRect(0, 0, playerSprite:getSize()) -- Add collision rect
    playerSprite:setCollideRect(0, 0, playerSprite:getSize()) -- Add collision rect
    playerSprite:setTag(1) -- Tag 1: Player
    playerSprite:setGroups({1}) -- Group 1: For physics mask
    playerSprite:setCollidesWithGroups({3}) -- Collides with Group 3: Alien Bullets (if added)
    playerSprite:add()

    function playerSprite:update()
        if playdate.buttonIsPressed(playdate.kButtonLeft) then
            playerSprite:moveBy(-playerSpeed, 0)
        elseif playdate.buttonIsPressed(playdate.kButtonRight) then
            playerSprite:moveBy(playerSpeed, 0)
        end

        -- Clamp position
        local x, y = playerSprite:getPosition()
        if x < 10 then playerSprite:moveTo(10, y) end
        if x > 390 then playerSprite:moveTo(390, y) end

        if playdate.buttonJustPressed(playdate.kButtonA) then
            spawnBullet(x, y - 10, -5, "player")
        end
    end
end

function getPlayerPosition()
    if playerSprite then
        return playerSprite:getPosition()
    end
    return 200, 220
end
