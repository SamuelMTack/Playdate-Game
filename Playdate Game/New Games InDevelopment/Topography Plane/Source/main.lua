import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics
local geom <const> = playdate.geometry
local snd <const> = playdate.sound

local SCREEN_W <const> = 400
local SCREEN_H <const> = 240
local NUM_SEGMENTS <const> = 80
local STEP_X <const> = SCREEN_W / NUM_SEGMENTS

-- Sound synthesizer for tactile creative feedback
local synth = snd.synth.new(snd.kWaveSine)
synth:setVolume(0.2)
synth:setADSR(0.005, 0.06, 0.0, 0.04)

local noiseSynth = snd.synth.new(snd.kWaveTriangle)
noiseSynth:setVolume(0.15)
noiseSynth:setADSR(0.01, 0.08, 0.0, 0.05)

-- Game / Art Canvas State
local stampedLines = {}
local canvasImage = gfx.image.new(SCREEN_W, SCREEN_H, gfx.kColorWhite)

-- Brush & Style settings
local STYLES <const> = { "Ridge", "Contour", "Shaded", "Bold" }
local styleIndex = 1
local showHUD = true
local autoAdvanceY = true
local baseY = 120
local roughness = 1.0 -- 0.2 to 2.5

-- Current active preview line
local currentWave = nil
local crankAccumulator = 0

-- Generate a random harmonic wave descriptor
local function createRandomWaveParams(yPos, ampScale)
    local harmonics = {}
    local numHarmonics = math.random(3, 5)
    for i = 1, numHarmonics do
        harmonics[i] = {
            freq = (math.random(8, 45) / 10.0) * i * 0.55,
            amp = (math.random(6, 22) / (i ^ 0.85)) * ampScale,
            phase = math.random() * math.pi * 2,
            speed = (math.random(5, 20) / 10.0) * (math.random(0, 1) == 1 and 1 or -1)
        }
    end

    -- Optional localized peak/valley (Gaussian bump) for topographic interest
    local numPeaks = math.random(1, 3)
    local peaks = {}
    for p = 1, numPeaks do
        peaks[p] = {
            center = math.random(40, SCREEN_W - 40),
            width = math.random(25, 80),
            height = (math.random(-36, 36)) * ampScale
        }
    end

    return {
        y = yPos,
        harmonics = harmonics,
        peaks = peaks,
        style = STYLES[styleIndex],
        points = {}
    }
end

-- Evaluate Y points along the screen width for a wave descriptor
local function computeWavePoints(wave)
    local pts = {}
    local yBase = wave.y
    for i = 0, NUM_SEGMENTS do
        local x = i * STEP_X
        local normX = x / SCREEN_W
        local dy = 0

        for _, h in ipairs(wave.harmonics) do
            dy = dy + math.sin(normX * math.pi * 2 * h.freq + h.phase) * h.amp
        end

        for _, pk in ipairs(wave.peaks) do
            local dist = (x - pk.center) / pk.width
            dy = dy + pk.height * math.exp(-(dist * dist))
        end

        local finalY = math.max(4, math.min(SCREEN_H - 4, yBase + dy))
        pts[i + 1] = { x = x, y = finalY }
    end
    wave.points = pts
end

-- Morph the active wave when the crank turns
local function morphWaveWithCrank(wave, crankDeltaDegrees)
    local radDelta = math.rad(crankDeltaDegrees)
    -- Slowly re-randomize frequencies and shift phases as the crank turns
    for i, h in ipairs(wave.harmonics) do
        h.phase = h.phase + radDelta * h.speed
        -- Subtle organic drift in amplitude and frequency
        h.amp = math.max(2 * roughness, math.min(35 * roughness, h.amp + math.sin(h.phase * 1.7) * (math.abs(radDelta) * 1.8) * (math.random() - 0.5) * 4))
    end

    for _, pk in ipairs(wave.peaks) do
        pk.center = pk.center + math.sin(radDelta * 2) * math.random(-6, 6)
        if pk.center < 20 then pk.center = SCREEN_W - 20 end
        if pk.center > SCREEN_W - 20 then pk.center = 20 end
        pk.height = math.max(-45 * roughness, math.min(45 * roughness, pk.height + (math.random() - 0.5) * math.abs(crankDeltaDegrees) * 0.35 * roughness))
    end

    computeWavePoints(wave)
end

-- Draw a single wave onto the current draw target
local function renderWave(wave, isPreview)
    local pts = wave.points
    if not pts or #pts < 2 then return end

    local style = wave.style or STYLES[styleIndex]

    if not isPreview then
        -- If style occludes the terrain below (Ridge or Shaded), fill polygon to bottom
        if style == "Ridge" or style == "Shaded" or style == "Bold" then
            local polyCoords = {}
            for i = 1, #pts do
                polyCoords[#polyCoords + 1] = pts[i].x
                polyCoords[#polyCoords + 1] = pts[i].y
            end
            polyCoords[#polyCoords + 1] = SCREEN_W
            polyCoords[#polyCoords + 1] = SCREEN_H
            polyCoords[#polyCoords + 1] = 0
            polyCoords[#polyCoords + 1] = SCREEN_H

            local poly = geom.polygon.new(table.unpack(polyCoords))
            poly:close()
            gfx.setColor(gfx.kColorWhite)
            gfx.fillPolygon(poly)

            if style == "Shaded" then
                -- Draw vertical topographic slope ticks below the ridge
                gfx.setColor(gfx.kColorBlack)
                gfx.setLineWidth(1)
                for i = 1, #pts - 1, 2 do
                    local p1 = pts[i]
                    local p2 = pts[i + 1]
                    local slope = p2.y - p1.y
                    local tickLen = math.min(18, math.max(3, math.floor(math.abs(slope) * 3.5 + 4)))
                    gfx.drawLine(p1.x, p1.y, p1.x, math.min(SCREEN_H, p1.y + tickLen))
                end
            end
        end
    end

    -- Draw the main wavy line
    gfx.setColor(gfx.kColorBlack)
    if style == "Bold" and not isPreview then
        gfx.setLineWidth(3)
    else
        gfx.setLineWidth(isPreview and 2 or 1)
    end

    for i = 1, #pts - 1 do
        local p1 = pts[i]
        local p2 = pts[i + 1]
        if isPreview then
            -- Animated or dashed feel on preview: draw main curve plus subtle highlight
            gfx.drawLine(p1.x, p1.y, p2.x, p2.y)
        else
            gfx.drawLine(p1.x, p1.y, p2.x, p2.y)
        end
    end

    -- Add small elevation markers on the preview line so it stands out from stamped lines
    if isPreview then
        gfx.setLineWidth(1)
        for i = 1, #pts, 10 do
            local p = pts[i]
            gfx.fillCircleAtPoint(p.x, p.y, 2)
        end
    end

    gfx.setLineWidth(1)
end

-- Rebuild the stamped canvas image from history (used on initialization and Undo/B)
local function redrawCanvas()
    canvasImage:clear(gfx.kColorWhite)
    gfx.pushContext(canvasImage)
    -- Subtle topographic grid ticks along edges
    gfx.setColor(gfx.kColorBlack)
    for _, wave in ipairs(stampedLines) do
        renderWave(wave, false)
    end
    gfx.popContext()
end

-- Stamp the active line onto the canvas (A button)
local function stampCurrentWave()
    if not currentWave then return end

    -- Deep copy current wave into stamped history
    local stampedPts = {}
    for i, p in ipairs(currentWave.points) do
        stampedPts[i] = { x = p.x, y = p.y }
    end

    local savedWave = {
        y = currentWave.y,
        style = STYLES[styleIndex],
        points = stampedPts
    }

    table.insert(stampedLines, savedWave)

    -- Render directly onto canvasImage for instant performance
    gfx.pushContext(canvasImage)
    renderWave(savedWave, false)
    gfx.popContext()

    -- Play pleasant stamp chord/tone
    local noteFreq = 220 + ((SCREEN_H - baseY) / SCREEN_H) * 330
    synth:playNote(noteFreq, 0.25, 0.08)

    -- Advance elevation slightly downward (foreground layering) if autoAdvanceY is active
    if autoAdvanceY then
        baseY = baseY + 6
        if baseY > SCREEN_H - 24 then
            baseY = 36
        end
    end

    -- Create a fresh random wavy line for the next stamp
    currentWave = createRandomWaveParams(baseY, roughness)
    computeWavePoints(currentWave)
end

-- Remove the previously stamped line (B button)
local function undoLastWave()
    if #stampedLines > 0 then
        local removed = table.remove(stampedLines)
        if removed and removed.y then
            baseY = removed.y
            if currentWave then
                currentWave.y = baseY
                computeWavePoints(currentWave)
            end
        end
        redrawCanvas()
        noiseSynth:playNote(180, 0.2, 0.07)
    else
        noiseSynth:playNote(110, 0.12, 0.05)
    end
end

-- Clear all lines
local function clearAllWaves()
    stampedLines = {}
    baseY = 60
    redrawCanvas()
    currentWave = createRandomWaveParams(baseY, roughness)
    computeWavePoints(currentWave)
    noiseSynth:playNote(140, 0.2, 0.1)
end

-- Configure Playdate System Menu
local function setupSystemMenu()
    local menu = playdate.getSystemMenu()
    menu:removeAllMenuItems()

    menu:addOptionsMenuItem("Style", STYLES, STYLES[styleIndex], function(selected)
        for i, name in ipairs(STYLES) do
            if name == selected then
                styleIndex = i
                if currentWave then
                    currentWave.style = selected
                end
                break
            end
        end
    end)

    menu:addCheckmarkMenuItem("Auto Step Y", autoAdvanceY, function(val)
        autoAdvanceY = val
    end)

    menu:addCheckmarkMenuItem("Show HUD", showHUD, function(val)
        showHUD = val
    end)

    menu:addMenuItem("Clear Plane", function()
        clearAllWaves()
    end)
end

-- Draw top and bottom HUD bars
local function drawHUD()
    if not showHUD then return end

    -- Top banner: Title & Layer Count
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_W, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, 18, SCREEN_W, 18)

    local headerText = string.format("*TOPOGRAPHY PLANE*  |  Style: %s  |  Lines: %d", STYLES[styleIndex], #stampedLines)
    gfx.drawText(headerText, 6, 2)

    -- Bottom helper bar
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, SCREEN_H - 18, SCREEN_W, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, SCREEN_H - 18, SCREEN_W, SCREEN_H - 18)

    local controlsText = "Crank: Random Wave   A: Stamp   B: Undo   D-Pad: Elev/Rough"
    gfx.drawText(controlsText, 6, SCREEN_H - 15)

    -- Left-side elevation tick indicator
    gfx.fillTriangle(0, baseY - 3, 5, baseY, 0, baseY + 3)
end

-- Initialize game
local function init()
    math.randomseed(playdate.getSecondsSinceEpoch())
    baseY = 65
    currentWave = createRandomWaveParams(baseY, roughness)
    computeWavePoints(currentWave)
    redrawCanvas()
    setupSystemMenu()
end

init()

function playdate.update()
    -- 1. Handle Crank input: generates/morphs the random wavy line on screen
    local crankChange, acceleratedChange = playdate.getCrankChange()
    if math.abs(crankChange) > 0.05 then
        crankAccumulator = crankAccumulator + math.abs(crankChange)

        -- Every 25 degrees of cranking injects fresh random wave components,
        -- while continuous turning smoothly morphs the wavy contour in real time
        if crankAccumulator >= 25 then
            crankAccumulator = crankAccumulator - 25
            currentWave = createRandomWaveParams(baseY, roughness)
            computeWavePoints(currentWave)
            local tickNote = 380 + math.random(-60, 120)
            synth:playNote(tickNote, 0.08, 0.02)
        else
            morphWaveWithCrank(currentWave, acceleratedChange)
        end
    end

    -- 2. Handle A Button: Stamp the screen with the current random wavy line
    if playdate.buttonJustPressed(playdate.kButtonA) then
        stampCurrentWave()
    end

    -- 3. Handle B Button: Remove the previously made line (Undo)
    if playdate.buttonJustPressed(playdate.kButtonB) then
        undoLastWave()
    end

    -- 4. Handle D-Pad: Adjust elevation (Up/Down) and wave amplitude/roughness (Left/Right)
    local elevationChanged = false
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        baseY = math.max(24, baseY - 2)
        elevationChanged = true
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        baseY = math.min(SCREEN_H - 24, baseY + 2)
        elevationChanged = true
    end

    if playdate.buttonJustPressed(playdate.kButtonLeft) then
        roughness = math.max(0.25, roughness - 0.25)
        currentWave = createRandomWaveParams(baseY, roughness)
        computeWavePoints(currentWave)
    elseif playdate.buttonJustPressed(playdate.kButtonRight) then
        roughness = math.min(2.5, roughness + 0.25)
        currentWave = createRandomWaveParams(baseY, roughness)
        computeWavePoints(currentWave)
    end

    if elevationChanged and currentWave then
        currentWave.y = baseY
        computeWavePoints(currentWave)
    end

    -- 5. Render Frame
    gfx.clear(gfx.kColorWhite)
    canvasImage:draw(0, 0)

    if currentWave then
        renderWave(currentWave, true)
    end

    drawHUD()
    playdate.timer.updateTimers()
end
