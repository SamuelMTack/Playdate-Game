import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/crank"

local gfx = playdate.graphics

import "pattern"

-- Configuration
local WIDTH = 400
local HEIGHT = 240
local CX = 200
local CY = 120

-- State
local crankAngle = 0
local patternTimer = 0
local segments = 8 -- Total slices (e.g. 8 = 4 pairs of mirrored slices)
local symmetry = true -- Mirroring on/off

-- Geometry Helper
-- Draws a function N times rotated around CX, CY
local function drawSymmetric(drawFunc)
    local angleStep = 360 / segments
    
    for i=0, segments-1 do
        local baseAngle = i * angleStep + crankAngle
        
        -- We want to mirror every other segment if symmetry is on
        -- But simpler kaleidoscope is: Draw Wedge, Mirror Wedge, Rotate pair.
        -- Let's stick to simple rotation of a "Symetrical Pair" or just Rotate single slice?
        -- Real kaleidoscope: Mirror neighbors.
        
        -- To achieve simple visual:
        -- Just rotate the coordinate space? Playdate doesn't have a context matrix stack we can push/pop easily for primitives.
        -- We have to manually transform points.
    end
end

-- We will inject a 'geo' table into Pattern to handle drawing
local geo = {}

function geo.pointRotate(x, y, angle_deg)
    local rad = math.rad(angle_deg)
    local s = math.sin(rad)
    local c = math.cos(rad)
    
    -- Translate to origin
    local ox = x - CX
    local oy = y - CY
    
    -- Rotate
    local rx = ox * c - oy * s
    local ry = ox * s + oy * c
    
    -- Translate back
    return rx + CX, ry + CY
end

function geo.drawLine(x1, y1, x2, y2)
    local angleStep = 360 / segments
    
    for i=0, segments-1 do
        local angle = i * angleStep + crankAngle
        local isMirrored = (i % 2 == 1) and symmetry
        
        local tx1, ty1 = x1, y1
        local tx2, ty2 = x2, y2
        
        -- Apply Mirroring relative to the "Wedge" center axis?
        -- Simpler: Mirror X relative to Center before rotating?
        if isMirrored then
            tx1 = CX - (tx1 - CX)
            tx2 = CX - (tx2 - CX)
        end
        
        local rx1, ry1 = geo.pointRotate(tx1, ty1, angle)
        local rx2, ry2 = geo.pointRotate(tx2, ty2, angle)
        
        gfx.drawLine(rx1, ry1, rx2, ry2)
    end
end

function geo.fillCircleAtPoint(x, y, r)
    local angleStep = 360 / segments
    for i=0, segments-1 do
        local angle = i * angleStep + crankAngle
        local isMirrored = (i % 2 == 1) and symmetry
        
        local tx, ty = x, y
        if isMirrored then tx = CX - (tx - CX) end
        
        local rx, ry = geo.pointRotate(tx, ty, angle)
        gfx.fillCircleAtPoint(rx, ry, r)
    end
end

-- Main Loop
function playdate.update()
    gfx.clear()
    
    local change, acceleratedChange = playdate.getCrankChange()
    crankAngle = crankAngle + change
    
    patternTimer = patternTimer + 0.05
    
    -- Inputs
    if playdate.buttonJustPressed(playdate.kButtonUp) then segments = math.min(segments + 2, 16) end
    if playdate.buttonJustPressed(playdate.kButtonDown) then segments = math.max(segments - 2, 2) end
    if playdate.buttonJustPressed(playdate.kButtonA) then Pattern.next() end
    
    -- Draw Pattern
    gfx.setColor(gfx.kColorBlack)
    Pattern.draw(geo, patternTimer)
    
    -- UI
    gfx.drawText("Seg: "..segments, 5, 220)
end
