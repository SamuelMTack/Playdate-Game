local gfx = playdate.graphics

local barricadeBlocks = {}

function setupBarricades()
    -- Clear existing blocks if any
    for _, block in ipairs(barricadeBlocks) do
        block:remove()
    end
    barricadeBlocks = {}

    local startY = 190
    local positions = {60, 140, 220, 300} -- X positions for 4 barricades
    local blockWidth = 6
    local blockHeight = 6
    local rows = 4
    local cols = 6

    for _, startX in ipairs(positions) do
        for r = 1, rows do
            for c = 1, cols do
                -- Create a simple shape (skip some blocks to make an arch)
                -- Skip bottom middle blocks to make an arch shape
                if not (r == 4 and (c == 3 or c == 4)) then
                    local blockImage = gfx.image.new(blockWidth, blockHeight)
                    gfx.pushContext(blockImage)
                        gfx.fillRect(0, 0, blockWidth, blockHeight)
                    gfx.popContext()

                    local block = gfx.sprite.new(blockImage)
                    local x = startX + (c-1) * blockWidth
                    local y = startY + (r-1) * blockHeight
                    
                    block:moveTo(x, y)
                    block:setCollideRect(0, 0, block:getSize())
                    block:setTag(3) -- Tag 3: Barricades
                    block:setGroups({3}) -- Group 3: For physics mask
                    block:add()
                    
                    table.insert(barricadeBlocks, block)
                end
            end
        end
    end
end
