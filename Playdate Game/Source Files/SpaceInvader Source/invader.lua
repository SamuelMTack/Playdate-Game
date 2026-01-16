local gfx = playdate.graphics

local invaders = {}
local moveDirection = 1 -- 1 for right, -1 for left
local moveSpeed = 2
local dropAmount = 10
local invaderStepTimer = nil

function setupInvaders()
    invaders = {}
    local rows = 4
    local cols = 8
    local startX = 40
    local startY = 30
    local padding = 30

    for r = 1, rows do
        for c = 1, cols do
            local invaderImage = gfx.image.new(20, 20)
            gfx.pushContext(invaderImage)
                gfx.fillRect(0, 0, 20, 20) -- Simple square for now
            gfx.popContext()

            local invader = gfx.sprite.new(invaderImage)
            invader:moveTo(startX + (c-1)*padding, startY + (r-1)*padding)
            invader:setCollideRect(0, 0, invader:getSize())
            invader:setTag(2) -- Tag 2: Invaders
            invader:setGroups({2}) -- Group 2: For physics mask
            invader:add()
            
            table.insert(invaders, invader)
        end
    end
    
    -- Reset movement
    moveDirection = 1
end

function updateInvaders()
   -- Simple movement logic: Move all, check if any hit edge, if so, drop down and reverse
   
   local hitEdge = false
   for _, invader in ipairs(invaders) do
       local x, y = invader:getPosition()
       if (x > 380 and moveDirection == 1) or (x < 20 and moveDirection == -1) then
           hitEdge = true
       end
   end

   if hitEdge then
       moveDirection = -moveDirection
       for _, invader in ipairs(invaders) do
           invader:moveBy(0, dropAmount)
           -- Check game over condition
           local _, y = invader:getPosition()
           if y > 200 then
               setGameOver()
           end
       end
   else
       for _, invader in ipairs(invaders) do
           invader:moveBy(moveSpeed * moveDirection, 0)
           
           -- Random shooting
           if math.random() < 0.005 then -- Low chance per frame per invader
               local ix, iy = invader:getPosition()
               spawnBullet(ix, iy + 10, 3, "enemy") -- Speed 3 down, type enemy
           end
       end
   end
   
   -- Cleanup destroyed invaders (sprites remove themselves from display list, but we keep track in table? 
   -- Actually, let's just use gfx.sprite.getAllSprites() or rely on collision callbacks if possible, 
   -- but for this simple loop we iterate our table.
   -- Better yet, let's just make sure we remove them from the table when destroyed.
   -- For now, `invaders` table is just for movement updates.
   
   -- Prune destroyed invaders from table
   for i = #invaders, 1, -1 do
       if invaders[i].isDestroyed then
            table.remove(invaders, i)
       end
   end
   
   if #invaders == 0 then
       -- Win state or respawn? For now, respawn
       setupInvaders()
   end
end
