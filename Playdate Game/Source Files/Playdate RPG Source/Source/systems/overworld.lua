local pd = playdate
local gfx = pd.graphics

import "consts"
import "../data/maps"
import "battle"
import "quest"
import "ui"
import "../data/sprites"
import "sound"

Overworld = {}

local playerX = 2
local playerY = 2
local playerSprite = nil

local cameraX = 0
local cameraY = 0

function Overworld.init()
    -- Initialize Sound
    if Sound then 
        Sound.init() 
        Sound.playOverworldMusic()
    end

    if not playerSprite then
        local pImage = Sprites.createPlayer()
        playerSprite = gfx.sprite.new(pImage)
        playerSprite:moveTo(playerX * Consts.TILE_SIZE + Consts.TILE_SIZE/2, playerY * Consts.TILE_SIZE + Consts.TILE_SIZE/2)
        playerSprite:add()
    end
end

function Overworld.update()
    Overworld.handleInput()
    Overworld.updateCamera()
    Overworld.drawMap()
    
    -- Draw player relative to camera
    local drawX = (playerX * Consts.TILE_SIZE + Consts.TILE_SIZE/2) - cameraX
    local drawY = (playerY * Consts.TILE_SIZE + Consts.TILE_SIZE/2) - cameraY
    
    playerSprite:moveTo(drawX, drawY)
end

function Overworld.updateCamera()
    -- Center camera on player
    local targetX = (playerX * Consts.TILE_SIZE) - (Consts.SCREEN_WIDTH / 2) + (Consts.TILE_SIZE / 2)
    local targetY = (playerY * Consts.TILE_SIZE) - (Consts.SCREEN_HEIGHT / 2) + (Consts.TILE_SIZE / 2)
    
    -- Clamp camera to map bounds
    local mapWidth = #Maps.worldValue[1] * Consts.TILE_SIZE
    local mapHeight = #Maps.worldValue * Consts.TILE_SIZE
    
    cameraX = math.max(0, math.min(targetX, mapWidth - Consts.SCREEN_WIDTH))
    cameraY = math.max(0, math.min(targetY, mapHeight - Consts.SCREEN_HEIGHT))
end

function Overworld.handleInput(key)
    if key == "A" then
        Overworld.checkInteraction()
        return
    end

    local dx, dy = 0, 0
    
    if pd.buttonJustPressed(pd.kButtonUp) then dy = -1 end
    if pd.buttonJustPressed(pd.kButtonDown) then dy = 1 end
    if pd.buttonJustPressed(pd.kButtonLeft) then dx = -1 end
    if pd.buttonJustPressed(pd.kButtonRight) then dx = 1 end
    
    if dx ~= 0 or dy ~= 0 then
        local newX = playerX + dx
        local newY = playerY + dy
        
        if Overworld.isWalkable(newX, newY) then
            playerX = newX
            playerY = newY
            -- Random Encounter Check
            -- Only on Grass/unsafe tiles
            local tile = Maps.worldValue[newY][newX]
            if tile == Maps.TILES.GRASS then
                if math.random(1, 100) <= 15 then -- 15% chance
                     local enemy = {name="Pixel Monster", danger=1}
                     if Battle then Battle.start(enemy) end
                end
            end
        end
    end
end

function Overworld.checkInteraction()
    local tile = Maps.worldValue[playerY] and Maps.worldValue[playerY][playerX]
    if tile == Maps.TILES.VILLAGE or tile == Maps.TILES.CASTLE or tile == Maps.TILES.TOWER or tile == Maps.TILES.CAVE then
        
        local tileName = "Unknown"
        if tile == Maps.TILES.VILLAGE then tileName = "Village" end
        if tile == Maps.TILES.CASTLE then tileName = "Castle" end
        if tile == Maps.TILES.TOWER then tileName = "Tower" end
        if tile == Maps.TILES.CAVE then tileName = "Cave" end
        
        print("Interacted with " .. tileName)
        
        -- Default text
        local desc = "You visit a " .. tileName .. "."
        
        -- Logic: If we are here, update "Visit" progress
        if Quest then Quest.updateProgress(Quest.TYPES.VISIT, tileName, 1) end
        
        -- Logic: Give new Quest if applicable
        if Quest then
            local newQ = Quest.assignFromLocation(tileName)
            if newQ then
                desc = "Quest Accepted: " .. newQ
             end
        end
        
        if UI then 
             -- Hack to show variable text in UI popup, assume UI has a method or we'll modify it
             UI.showLocationPopup(tile, desc) 
        end
    end
end

function Overworld.isWalkable(x, y)
    local tile = Maps.worldValue[y] and Maps.worldValue[y][x]
    if not tile then return false end
    
    if tile == Maps.TILES.WATER or tile == Maps.TILES.MOUNTAIN then
        return false
    end
    return true
end

function Overworld.drawMap()
    -- SIMPLIFIED RENDERING TO GUARANTEE VISIBILITY
    
    -- Force start at top-left
    local startX = 0
    local startY = 0
    
    -- Draw 20x20 grid directly
    for y = 1, 20 do
        for x = 1, 20 do
            local tileVal = 1
            if Maps and Maps.worldValue and Maps.worldValue[y] then
                tileVal = Maps.worldValue[y][x] or 1
            end
            
            -- Calculate position relative to camera
            local screenX = (x-1) * 32 - cameraX
            local screenY = (y-1) * 32 - cameraY
            
            -- Only draw if on screen (basic check)
            if screenX > -32 and screenX < 400 and screenY > -32 and screenY < 240 then
                
                -- RAW DRAWING - NO IMAGES
                gfx.setColor(gfx.kColorBlack)
                
                if tileVal == 1 then -- Grass
                    -- Empty box
                    gfx.drawRect(screenX, screenY, 32, 32)
                    -- Small dot in middle
                    gfx.fillRect(screenX + 14, screenY + 14, 4, 4)
                    
                elseif tileVal == 2 then -- Water
                    -- Horizontal lines
                    gfx.drawRect(screenX, screenY, 32, 32)
                    gfx.drawLine(screenX, screenY+10, screenX+32, screenY+10)
                    gfx.drawLine(screenX, screenY+20, screenX+32, screenY+20)
                    
                else -- Everything else (Solid Box)
                   gfx.fillRect(screenX, screenY, 32, 32)
                   -- Invert text for contrast
                   gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
                   gfx.drawText(tostring(tileVal), screenX+8, screenY+8)
                   gfx.setImageDrawMode(gfx.kDrawModeCopy)
                end
            end
        end
    end
end

-- Initialize on load
Overworld.init()
