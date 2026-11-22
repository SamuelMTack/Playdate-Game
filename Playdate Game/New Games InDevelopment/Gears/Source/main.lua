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

-- Mechanical click synthesizer for gear teeth meshing
local sfxTick = snd.synth.new(snd.kWaveTriangle)
sfxTick:setVolume(0.14)
sfxTick:setADSR(0.001, 0.018, 0.0, 0.01)

local sfxShift = snd.synth.new(snd.kWaveSine)
sfxShift:setVolume(0.20)
sfxShift:setADSR(0.005, 0.06, 0.0, 0.04)

-- Visual & Simulation State
local WHEEL_STYLES <const> = { "Spoked", "Drilled", "Blueprint", "Solid" }
local styleIndex = 1
local soundEnabled = true
local showVectors = true
local autoMotor = false
local motorSpeed = 75.0 -- Degrees per second when Auto-Motor is ON

-- Drive gear master angle (degrees) and angular velocity (degrees/sec)
local driveAngle = 0.0
local driveVel = 0.0
local tickAccumulator = 0.0

-- Active gear combination index and inspected gear index
local comboIndex = 1
local inspectedGearIdx = 1
local activeGears = {}
local activeComboName = ""
local activeComboDesc = ""

-- Constant tooth pitch module (pixels of pitch radius per tooth)
-- Pitch radius R = teeth * PITCH_FACTOR
local PITCH_FACTOR <const> = 1.95
local TOOTH_ADDENDUM <const> = 3.2
local TOOTH_DEDENDUM <const> = 2.8

-- Helper to build a gear train where each gear's position, ratio, and phase offset
-- are computed directly from its parent gear so the teeth always mesh cleanly!
-- Spec entries:
--   teeth: number of teeth
--   x, y: only required for root gear (id=1); child gears specify parentId and placementAngleDeg
--   parentId: index of the gear this gear meshes with (or shares an axle with if compound=true)
--   dirDeg: angle (in degrees, 0=right, 90=down, -90=up) from parent gear center to this gear's center
--   compound: if true, mounted on the exact same axle as parentId (rotates at same angular velocity)
--   hubStyle: optional override ("spoked", "drilled", "solid")
--   label: optional role label ("DRIVE", "IDLER", "OUTPUT", etc.)
local COMBINATIONS <const> = {
    {
        name = "1. Classic 3-Gear Idler Train",
        desc = "Idler gear reverses rotation so Drive & Output spin the same way",
        specs = {
            { teeth = 16, x = 86, y = 122, label = "DRIVE" },
            { teeth = 12, parentId = 1, dirDeg = -18, label = "IDLER" },
            { teeth = 24, parentId = 2, dirDeg = 12, label = "OUTPUT" }
        }
    },
    {
        name = "2. Speed Overdrive (1:4 Step-Up)",
        desc = "Large 32T Drive Gear accelerates an 8T high-speed pinion to 4x RPM",
        specs = {
            { teeth = 32, x = 112, y = 124, label = "DRIVE 32T" },
            { teeth = 16, parentId = 1, dirDeg = -12, label = "STEP 16T" },
            { teeth = 12, parentId = 2, dirDeg = 22, label = "STEP 12T" },
            { teeth = 8,  parentId = 3, dirDeg = -28, label = "FAST 8T" }
        }
    },
    {
        name = "3. High-Torque Compound Reducer",
        desc = "Compound dual-gear axles multiply torque by 6:1 at low output speed",
        specs = {
            { teeth = 10, x = 74, y = 148, label = "DRIVE 10T" },
            { teeth = 24, parentId = 1, dirDeg = -22, label = "STAGE 1" },
            { teeth = 10, parentId = 2, compound = true, label = "AXLE PINION" },
            { teeth = 25, parentId = 3, dirDeg = 18, label = "TORQUE 6:1" }
        }
    },
    {
        name = "4. Planetary Sun & Planet Cluster",
        desc = "Central 18T Sun Gear simultaneously drives four orbiting Planet Gears",
        specs = {
            { teeth = 18, x = 200, y = 122, label = "SUN DRIVE" },
            { teeth = 12, parentId = 1, dirDeg = 0,   label = "EAST PLANET" },
            { teeth = 12, parentId = 1, dirDeg = 180, label = "WEST PLANET" },
            { teeth = 10, parentId = 1, dirDeg = -90, label = "NORTH PLANET" },
            { teeth = 10, parentId = 1, dirDeg = 90,  label = "SOUTH PLANET" }
        }
    },
    {
        name = "5. Clockwork Horology Train",
        desc = "Precision multi-wheel watch train with compound escapement gears",
        specs = {
            { teeth = 20, x = 76, y = 128, label = "MAINSPRING" },
            { teeth = 12, parentId = 1, dirDeg = -26, label = "CENTER WHL" },
            { teeth = 22, parentId = 2, compound = true, label = "COMPOUND" },
            { teeth = 10, parentId = 3, dirDeg = 20, label = "THIRD WHL" },
            { teeth = 18, parentId = 4, compound = true, label = "FOURTH WHL" },
            { teeth = 9,  parentId = 5, dirDeg = -15, label = "ESCAPE WHL" }
        }
    },
    {
        name = "6. Twin-Branch Differential Split",
        desc = "Central drive splits power into upper and lower counter-rotating branches",
        specs = {
            { teeth = 16, x = 196, y = 122, label = "CENTER DRIVE" },
            { teeth = 14, parentId = 1, dirDeg = -142, label = "UPPER L" },
            { teeth = 18, parentId = 2, dirDeg = 170,  label = "OUT LEFT" },
            { teeth = 14, parentId = 1, dirDeg = -38,  label = "UPPER R" },
            { teeth = 18, parentId = 4, dirDeg = 10,   label = "OUT RIGHT" },
            { teeth = 11, parentId = 1, dirDeg = 90,   label = "LOWER IDLE" }
        }
    },
    {
        name = "7. Heavy Industrial Gearbox",
        desc = "Dual-stage compound transmission with high-ratio flywheel output",
        specs = {
            { teeth = 14, x = 68, y = 92, label = "INPUT" },
            { teeth = 22, parentId = 1, dirDeg = 28, label = "COUNTER 1" },
            { teeth = 11, parentId = 2, compound = true, label = "PINION 1" },
            { teeth = 22, parentId = 3, dirDeg = -24, label = "COUNTER 2" },
            { teeth = 12, parentId = 4, compound = true, label = "PINION 2" },
            { teeth = 26, parentId = 5, dirDeg = 16, label = "FLYWHEEL" }
        }
    },
    {
        name = "8. 8-Gear Serpentine Cascade",
        desc = "Full-screen serpentine chain of 8 interlocking gears across the plane",
        specs = {
            { teeth = 14, x = 44, y = 148, label = "DRIVE #1" },
            { teeth = 12, parentId = 1, dirDeg = -42, label = "GEAR #2" },
            { teeth = 14, parentId = 2, dirDeg = 32,  label = "GEAR #3" },
            { teeth = 11, parentId = 3, dirDeg = -36, label = "GEAR #4" },
            { teeth = 15, parentId = 4, dirDeg = 34,  label = "GEAR #5" },
            { teeth = 12, parentId = 5, dirDeg = -38, label = "GEAR #6" },
            { teeth = 14, parentId = 6, dirDeg = 32,  label = "GEAR #7" },
            { teeth = 16, parentId = 7, dirDeg = -22, label = "OUTPUT #8" }
        }
    }
}

-- Build the active gear combination from specs, computing exact meshing centers, ratios, and tooth phase offsets
local function loadCombination(index)
    comboIndex = index
    local combo = COMBINATIONS[comboIndex]
    activeComboName = combo.name
    activeComboDesc = combo.desc
    activeGears = {}

    for i, spec in ipairs(combo.specs) do
        local pitchR = spec.teeth * PITCH_FACTOR
        local outerR = pitchR + TOOTH_ADDENDUM
        local rootR = pitchR - TOOTH_DEDENDUM

        local gear = {
            id = i,
            teeth = spec.teeth,
            pitchR = pitchR,
            outerR = outerR,
            rootR = rootR,
            label = spec.label or string.format("G%d", i),
            compound = spec.compound or false,
            parentId = spec.parentId,
            x = spec.x or 200,
            y = spec.y or 120,
            ratio = 1.0,       -- Angular speed multiplier relative to Gear 1
            phaseOffset = 0.0, -- Initial tooth alignment angle in degrees
            angle = 0.0
        }

        if not spec.parentId then
            -- Root drive gear
            gear.ratio = 1.0
            gear.phaseOffset = 0.0
        else
            local parent = activeGears[spec.parentId]
            if spec.compound then
                -- Mounted on the exact same axle as parent: shares X, Y, and angular velocity
                gear.x = parent.x
                gear.y = parent.y
                gear.ratio = parent.ratio
                gear.phaseOffset = parent.phaseOffset
            else
                -- Meshes externally with parent along angle dirDeg
                local dirRad = math.rad(spec.dirDeg or 0)
                local centerDist = parent.pitchR + gear.pitchR + 0.8
                gear.x = parent.x + math.cos(dirRad) * centerDist
                gear.y = parent.y + math.sin(dirRad) * centerDist

                -- External gear mesh reverses direction and scales by N_parent / N_child
                gear.ratio = -parent.ratio * (parent.teeth / gear.teeth)

                -- Calculate exact phase offset so a tooth of parent meshes with a valley of child at contact point
                local contactAngleParent = spec.dirDeg or 0
                local contactAngleChild = contactAngleParent + 180.0
                local toothPitchChild = 360.0 / gear.teeth
                -- When driveAngle = 0, parent is at parent.phaseOffset.
                -- At contact point, parent's tooth phase is (contactAngleParent - parent.phaseOffset) * parent.teeth
                local parentRelativeAngle = contactAngleParent - parent.phaseOffset
                gear.phaseOffset = contactAngleChild + (parentRelativeAngle * (parent.teeth / gear.teeth)) + (toothPitchChild * 0.5)
            end
        end

        activeGears[i] = gear
    end

    if inspectedGearIdx > #activeGears then
        inspectedGearIdx = #activeGears
    end
end

-- Draw a single mechanical gear with trapezoidal involute-style teeth, spokes/holes, axle keyway, and rotation marker
local function drawGear(gear, isInspected)
    local cx = gear.x
    local cy = gear.y
    local N = gear.teeth
    local pitchR = gear.pitchR
    local outerR = gear.outerR
    local rootR = gear.rootR
    local currentAngle = gear.phaseOffset + driveAngle * gear.ratio

    local style = WHEEL_STYLES[styleIndex]
    local isBlueprint = (style == "Blueprint")
    local fgColor = isBlueprint and gfx.kColorWhite or gfx.kColorBlack
    local bgColor = isBlueprint and gfx.kColorBlack or gfx.kColorWhite

    -- Build the gear perimeter polygon (N teeth around 360 degrees)
    local polyCoords = {}
    local stepRad = (math.pi * 2) / N
    local baseRad = math.rad(currentAngle)

    -- Angular fractions of a single tooth pitch:
    -- [-0.36.. -0.18] root to tip rise, [-0.18.. +0.18] outer tooth tip, [+0.18.. +0.36] tip to root fall, [+0.36.. +0.64] root valley
    for i = 0, N - 1 do
        local centerA = baseRad + i * stepRad
        local a1 = centerA - stepRad * 0.34
        local a2 = centerA - stepRad * 0.17
        local a3 = centerA + stepRad * 0.17
        local a4 = centerA + stepRad * 0.34

        polyCoords[#polyCoords + 1] = cx + math.cos(a1) * rootR
        polyCoords[#polyCoords + 1] = cy + math.sin(a1) * rootR

        polyCoords[#polyCoords + 1] = cx + math.cos(a2) * outerR
        polyCoords[#polyCoords + 1] = cy + math.sin(a2) * outerR

        polyCoords[#polyCoords + 1] = cx + math.cos(a3) * outerR
        polyCoords[#polyCoords + 1] = cy + math.sin(a3) * outerR

        polyCoords[#polyCoords + 1] = cx + math.cos(a4) * rootR
        polyCoords[#polyCoords + 1] = cy + math.sin(a4) * rootR
    end

    local poly = geom.polygon.new(table.unpack(polyCoords))
    poly:close()

    -- Fill gear body so overlapping compound gears occlude the layer beneath them cleanly
    if not isBlueprint then
        gfx.setColor(bgColor)
        gfx.fillPolygon(poly)
    end

    gfx.setColor(fgColor)
    gfx.setLineWidth(isInspected and 2 or 1)
    gfx.drawPolygon(poly)

    -- Inner rim circle below the teeth roots
    local rimR = math.max(5, rootR - 3)
    gfx.setLineWidth(1)
    gfx.drawCircleAtPoint(cx, cy, rimR)

    -- Pitch circle dashed reference in Blueprint mode or when inspected
    if isBlueprint or isInspected then
        gfx.drawCircleAtPoint(cx, cy, pitchR)
    end

    -- Interior wheel styling (Spoked, Drilled holes, or Solid with timing line)
    if style == "Spoked" and rimR >= 14 then
        local numSpokes = (N >= 20) and 6 or 4
        gfx.setLineWidth(2)
        for s = 0, numSpokes - 1 do
            local sa = baseRad + s * ((math.pi * 2) / numSpokes)
            gfx.drawLine(
                cx + math.cos(sa) * 5,
                cy + math.sin(sa) * 5,
                cx + math.cos(sa) * (rimR - 1),
                cy + math.sin(sa) * (rimR - 1)
            )
        end
        gfx.setLineWidth(1)
    elseif style == "Drilled" and rimR >= 14 then
        local numHoles = (N >= 20) and 6 or 4
        local holeDist = (rimR + 5) * 0.52
        local holeR = math.max(2, math.floor((rimR - 6) * 0.25))
        for h = 0, numHoles - 1 do
            local ha = baseRad + h * ((math.pi * 2) / numHoles)
            local hx = cx + math.cos(ha) * holeDist
            local hy = cy + math.sin(ha) * holeDist
            gfx.drawCircleAtPoint(hx, hy, holeR)
        end
    else
        -- Timing indicator line on smaller gears or Solid/Blueprint mode
        local tx = cx + math.cos(baseRad) * (rimR - 1)
        local ty = cy + math.sin(baseRad) * (rimR - 1)
        gfx.setLineWidth(2)
        gfx.drawLine(cx, cy, tx, ty)
        gfx.setLineWidth(1)
    end

    -- Prominent timing dot near the rim so the player can visually track RPM & phase
    local dotDist = math.max(4, rimR - 4)
    local dotX = cx + math.cos(baseRad) * dotDist
    local dotY = cy + math.sin(baseRad) * dotDist
    gfx.fillCircleAtPoint(dotX, dotY, 2)

    -- Center hub & axle bore
    gfx.setColor(bgColor)
    gfx.fillCircleAtPoint(cx, cy, 5)
    gfx.setColor(fgColor)
    gfx.drawCircleAtPoint(cx, cy, 5)
    gfx.fillCircleAtPoint(cx, cy, 2)

    -- Draw rotation velocity vector arrow & tooth count tag if enabled
    if showVectors then
        local dirSign = (driveVel * gear.ratio >= 0) and 1 or -1
        if math.abs(driveVel) > 1.0 then
            local arcA = math.rad(-90)
            local arrowX = cx + math.cos(arcA) * (rimR * 0.65)
            local arrowY = cy + math.sin(arcA) * (rimR * 0.65)
            gfx.fillTriangle(
                arrowX + dirSign * 4, arrowY,
                arrowX - dirSign * 2, arrowY - 3,
                arrowX - dirSign * 2, arrowY + 3
            )
        end
    end

    -- Highlight badge around the currently inspected gear (selected with Up/Down)
    if isInspected then
        local tagText = string.format("%dT", gear.teeth)
        local tw = gfx.getTextSize(tagText) + 6
        local tx = cx - tw / 2
        local ty = cy - outerR - 16
        if ty < 22 then
            ty = cy + outerR + 3
        end
        gfx.setColor(bgColor)
        gfx.fillRoundRect(tx, ty, tw, 14, 3)
        gfx.setColor(fgColor)
        gfx.drawRoundRect(tx, ty, tw, 14, 3)
        if isBlueprint then
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end
        gfx.drawText(tagText, tx + 3, ty)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

-- Draw connecting chassis plate mounts between axles
local function drawChassisMountings()
    local style = WHEEL_STYLES[styleIndex]
    local isBlueprint = (style == "Blueprint")
    gfx.setColor(isBlueprint and gfx.kColorWhite or gfx.kColorBlack)
    gfx.setLineWidth(1)

    -- Subtle dashed/thin truss lines linking parent-child axles
    for _, g in ipairs(activeGears) do
        if g.parentId and not g.compound then
            local p = activeGears[g.parentId]
            gfx.setDitherPattern(0.65, gfx.image.kDitherTypeBayer4x4)
            gfx.drawLine(p.x, p.y, g.x, g.y)
            gfx.setColor(isBlueprint and gfx.kColorWhite or gfx.kColorBlack)
        end
    end
end

-- Draw Top and Bottom HUD Bars
local function drawHUD()
    -- Top Bar: Combination Title & Active Gear Telemetry
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_W, 20)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    gfx.drawLine(0, 20, SCREEN_W, 20)

    local g = activeGears[inspectedGearIdx] or activeGears[1]
    local gearRPM = (driveVel * g.ratio) / 6.0 -- 360 deg/sec = 60 RPM -> deg/sec / 6 = RPM
    local dirStr = ""
    if math.abs(gearRPM) > 0.2 then
        dirStr = (gearRPM > 0) and " CW" or " CCW"
    end

    local ratioAbs = math.abs(g.ratio)
    local ratioStr = (ratioAbs >= 1.0) and string.format("%.2fx", ratioAbs) or string.format("1:%.2f", 1.0 / ratioAbs)

    local topText = string.format("*%s*  |  %s (%dT): %s  %d RPM%s",
        activeComboName, g.label, g.teeth, ratioStr, math.floor(math.abs(gearRPM) + 0.5), dirStr)
    gfx.drawText(topText, 5, 2)

    -- Bottom Bar: Controls & Description
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, SCREEN_H - 18, SCREEN_W, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, SCREEN_H - 18, SCREEN_W, SCREEN_H - 18)

    local motorLabel = autoMotor and "A:Motor[ON]" or "A:Motor[OFF]"
    local botText = string.format("L/R: Gear Combo (%d/%d)   Crank: Spin   %s   U/D: Inspect   B: Style",
        comboIndex, #COMBINATIONS, motorLabel)
    gfx.drawText(botText, 5, SCREEN_H - 15)
end

local function setupMenu()
    local menu = playdate.getSystemMenu()
    menu:removeAllMenuItems()

    menu:addOptionsMenuItem("Style", WHEEL_STYLES, WHEEL_STYLES[styleIndex], function(selected)
        for i, name in ipairs(WHEEL_STYLES) do
            if name == selected then
                styleIndex = i
                break
            end
        end
    end)

    menu:addCheckmarkMenuItem("Click Sound", soundEnabled, function(val)
        soundEnabled = val
    end)

    menu:addOptionsMenuItem("Motor RPM", { "Normal", "Slow", "Fast", "Reverse" }, "Normal", function(selected)
        if selected == "Slow" then
            motorSpeed = 36.0
        elseif selected == "Fast" then
            motorSpeed = 140.0
        elseif selected == "Reverse" then
            motorSpeed = -75.0
        else
            motorSpeed = 75.0
        end
    end)
end

local function init()
    loadCombination(1)
    setupMenu()
end

init()

function playdate.update()
    local dt = 1.0 / 30.0

    -- 1. Left and Right buttons select different Gear Combinations!
    if playdate.buttonJustPressed(playdate.kButtonRight) then
        local nextIdx = comboIndex + 1
        if nextIdx > #COMBINATIONS then nextIdx = 1 end
        inspectedGearIdx = 1
        loadCombination(nextIdx)
        sfxShift:playNote(440, 0.18, 0.04)
    elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
        local prevIdx = comboIndex - 1
        if prevIdx < 1 then prevIdx = #COMBINATIONS end
        inspectedGearIdx = 1
        loadCombination(prevIdx)
        sfxShift:playNote(370, 0.18, 0.04)
    end

    -- 2. Up and Down buttons select which gear in the train to inspect on the HUD
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        inspectedGearIdx = inspectedGearIdx + 1
        if inspectedGearIdx > #activeGears then inspectedGearIdx = 1 end
        sfxShift:playNote(520, 0.12, 0.02)
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        inspectedGearIdx = inspectedGearIdx - 1
        if inspectedGearIdx < 1 then inspectedGearIdx = #activeGears end
        sfxShift:playNote(480, 0.12, 0.02)
    end

    -- 3. A button toggles the Auto-Drive Motor ON/OFF
    if playdate.buttonJustPressed(playdate.kButtonA) then
        autoMotor = not autoMotor
        sfxShift:playNote(autoMotor and 587.33 or 293.66, 0.2, 0.05)
    end

    -- 4. B button cycles through Gear Wheel Visual Styles (Spoked, Drilled, Blueprint, Solid)
    if playdate.buttonJustPressed(playdate.kButtonB) then
        styleIndex = styleIndex + 1
        if styleIndex > #WHEEL_STYLES then styleIndex = 1 end
        sfxShift:playNote(330, 0.15, 0.03)
    end

    -- 5. Crank spins the gears together with smooth flywheel momentum
    local crankChange, acceleratedChange = playdate.getCrankChange()
    if math.abs(crankChange) > 0.02 then
        -- Direct crank rotation + velocity injection
        driveAngle = (driveAngle + crankChange) % 36000
        driveVel = acceleratedChange * 30.0
    else
        if autoMotor then
            driveVel = driveVel + (motorSpeed - driveVel) * 0.15
        else
            -- Flywheel coasting decay when hand-cranking stops
            driveVel = driveVel * 0.92
            if math.abs(driveVel) < 0.4 then
                driveVel = 0.0
            end
        end
        driveAngle = (driveAngle + driveVel * dt) % 36000
    end

    -- 6. Mechanical tooth-click sound proportional to drive gear tooth passage
    if soundEnabled and math.abs(driveVel) > 2.0 then
        local driveTeeth = activeGears[1].teeth
        local toothAngle = 360.0 / driveTeeth
        tickAccumulator = tickAccumulator + math.abs(driveVel) * dt
        if tickAccumulator >= toothAngle then
            tickAccumulator = tickAccumulator % toothAngle
            local pitch = 160 + math.min(420, math.abs(driveVel) * 0.75)
            sfxTick:playNote(pitch, 0.10, 0.012)
        end
    end

    -- 7. Render Frame
    local isBlueprint = (WHEEL_STYLES[styleIndex] == "Blueprint")
    gfx.clear(isBlueprint and gfx.kColorBlack or gfx.kColorWhite)

    drawChassisMountings()

    for i, gear in ipairs(activeGears) do
        drawGear(gear, i == inspectedGearIdx)
    end

    drawHUD()
    playdate.timer.updateTimers()
end
