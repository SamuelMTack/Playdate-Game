import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics
local snd <const> = playdate.sound

local SCREEN_W <const> = 400
local SCREEN_H <const> = 240
local GROUND_Y <const> = 205
local BOWMAN_X <const> = 60
local BOWMAN_Y <const> = GROUND_Y

-- Physics constants (pixels and seconds at 30fps)
local GRAVITY <const> = 380.0
local MIN_SPEED <const> = 220.0
local MAX_SPEED <const> = 860.0
local PIXELS_PER_METER <const> = 10.0 -- 10 px = 1m, so 400px screen is 40m wide

-- Synthesizers for sound effects
local sfxBow = snd.synth.new(snd.kWaveTriangle)
sfxBow:setVolume(0.25)
sfxBow:setADSR(0.005, 0.08, 0.0, 0.05)

local sfxHit = snd.synth.new(snd.kWaveSine)
sfxHit:setVolume(0.3)
sfxHit:setADSR(0.005, 0.15, 0.1, 0.15)

local sfxNoise = snd.synth.new(snd.kWaveNoise)
sfxNoise:setVolume(0.18)
sfxNoise:setADSR(0.005, 0.06, 0.0, 0.04)

-- Game States: "AIMING", "FLYING", "RESULT"
local state = "AIMING"

-- Bow & Power Charge Meter state
local aimAngle = 45.0          -- Degrees (5 to 85)
local powerCharge = 50.0       -- 0 to 100
local powerDir = 1             -- 1 = rising, -1 = falling
local powerSpeed = 85.0        -- Charge meter speed (% per second)
local lockedPower = nil        -- Power locked when A is pressed

-- Target & World state
local targetX = 850            -- Always off-screen (> 450 px)
local targetY = GROUND_Y - 26  -- Center of the target stand
local targetRadius = 22        -- Radius of the target board
local windSpeed = 0.0          -- Optional wind acceleration
local windEnabled = false

-- Camera state
local camX = 0
local camY = 0
local manualPanX = 0

-- Arrow state
local arrow = {
    x = BOWMAN_X,
    y = BOWMAN_Y - 24,
    vx = 0,
    vy = 0,
    angle = -45,
    trail = {},
    active = false
}

-- Previous stuck arrows & last shot info
local stuckArrows = {}
local lastShot = nil -- { angle = ..., power = ..., distDiff = ... }

-- Score & Progression
local score = 0
local highScore = 0
local streak = 0
local roundNum = 1
local shotsThisTarget = 0
local resultTimer = 0
local resultHeadline = ""
local resultSubtext = ""
local targetHitSuccess = false

-- Decorative background clouds / hills (seeded deterministically per target)
local sceneryMarks = {}

local function generateScenery()
    sceneryMarks = {}
    for x = 100, 2600, 90 do
        table.insert(sceneryMarks, {
            x = x + math.random(-25, 25),
            treeH = math.random(14, 30),
            cloudX = x + math.random(-40, 40),
            cloudY = math.random(35, 95),
            cloudW = math.random(28, 56)
        })
    end
end

local function spawnNewTarget(resetRound)
    if resetRound then
        roundNum = 1
        score = 0
        streak = 0
        lastShot = nil
    end
    shotsThisTarget = 0
    stuckArrows = {}

    -- Target spawns well off-screen (between 550px and 1750px, scaling slightly with round)
    local minDist = 520 + math.min(400, (roundNum - 1) * 60)
    local maxDist = math.min(1850, minDist + 450)
    targetX = math.random(minDist, maxDist)
    targetY = GROUND_Y - 26

    if windEnabled then
        windSpeed = math.random(-45, 45)
    else
        windSpeed = 0
    end

    generateScenery()
end

local function resetForNextShot()
    state = "AIMING"
    lockedPower = nil
    manualPanX = 0
    arrow.x = BOWMAN_X + 6
    arrow.y = BOWMAN_Y - 24
    arrow.trail = {}
    arrow.active = false
end

local function fireArrow()
    lockedPower = powerCharge
    state = "FLYING"
    shotsThisTarget = shotsThisTarget + 1

    local rad = math.rad(aimAngle)
    local speed = MIN_SPEED + (lockedPower / 100.0) * (MAX_SPEED - MIN_SPEED)

    -- Bow pivot is at (BOWMAN_X, BOWMAN_Y - 24)
    arrow.x = BOWMAN_X + math.cos(rad) * 18
    arrow.y = (BOWMAN_Y - 24) - math.sin(rad) * 18
    arrow.vx = math.cos(rad) * speed
    arrow.vy = -math.sin(rad) * speed
    arrow.angle = -aimAngle
    arrow.trail = { { x = arrow.x, y = arrow.y } }
    arrow.active = true

    -- Launch sound effect
    sfxBow:playNote(320, 0.25, 0.08)
    sfxNoise:playNote(500, 0.15, 0.05)
end

-- Check if line segment (x1,y1)->(x2,y2) intersects the target board at targetX
local function checkTargetHit(x1, y1, x2, y2)
    -- Target face is a vertical board at x = targetX, centered at targetY with radius targetRadius
    if (x1 <= targetX and x2 >= targetX) or (x1 >= targetX and x2 <= targetX) then
        local dx = x2 - x1
        local t = 0
        if math.abs(dx) > 0.0001 then
            t = (targetX - x1) / dx
        end
        local hitY = y1 + t * (y2 - y1)
        local distFromCenter = math.abs(hitY - targetY)
        if distFromCenter <= targetRadius then
            return true, targetX, hitY, distFromCenter
        end
    end
    return false, nil, nil, nil
end

local function finishShot(hitTarget, hitX, hitY, bullseyeOffset)
    state = "RESULT"
    resultTimer = 0
    arrow.x = hitX
    arrow.y = hitY

    -- Save arrow into stuckArrows list
    table.insert(stuckArrows, {
        x = arrow.x,
        y = arrow.y,
        angle = arrow.angle
    })

    local diffPixels = hitX - targetX
    local diffMeters = math.floor(math.abs(diffPixels) / PIXELS_PER_METER + 0.5)

    lastShot = {
        angle = aimAngle,
        power = lockedPower,
        diffPixels = diffPixels
    }

    if hitTarget then
        targetHitSuccess = true
        streak = streak + 1
        local pts = 25
        local ringName = "OUTER RING!"
        if bullseyeOffset <= 5 then
            pts = 100
            ringName = "BULLSEYE!!"
            sfxHit:playNote(587.33, 0.3, 0.15)
        elseif bullseyeOffset <= 13 then
            pts = 50
            ringName = "INNER RING!"
            sfxHit:playNote(440.0, 0.25, 0.12)
        else
            sfxHit:playNote(349.23, 0.25, 0.10)
        end

        -- First-shot accuracy bonus
        if shotsThisTarget == 1 then
            pts = pts + 25
        end

        score = score + pts
        if score > highScore then
            highScore = score
        end

        resultHeadline = string.format("%s (+%d PTS)", ringName, pts)
        resultSubtext = "Press A for Next Target"
    else
        targetHitSuccess = false
        streak = 0
        sfxNoise:playNote(180, 0.2, 0.06)

        if diffPixels < 0 then
            resultHeadline = string.format("SHORT BY %dm!", math.max(1, diffMeters))
        else
            resultHeadline = string.format("LONG BY %dm!", math.max(1, diffMeters))
        end
        resultSubtext = "Press A to Shoot Again  |  B: View Target"
    end
end

local function updatePhysics(dt)
    if state ~= "FLYING" then return end

    local prevX = arrow.x
    local prevY = arrow.y

    arrow.vx = arrow.vx + windSpeed * dt
    arrow.vy = arrow.vy + GRAVITY * dt
    arrow.x = arrow.x + arrow.vx * dt
    arrow.y = arrow.y + arrow.vy * dt
    arrow.angle = math.deg(math.atan(arrow.vy, arrow.vx))

    -- Record flight trail dots
    local lastTrail = arrow.trail[#arrow.trail]
    if not lastTrail or math.abs(arrow.x - lastTrail.x) > 12 or math.abs(arrow.y - lastTrail.y) > 12 then
        table.insert(arrow.trail, { x = arrow.x, y = arrow.y })
    end

    -- 1. Check collision with target board
    local hit, hx, hy, offset = checkTargetHit(prevX, prevY, arrow.x, arrow.y)
    if hit then
        finishShot(true, hx, hy, offset)
        return
    end

    -- 2. Check collision with ground
    if arrow.y >= GROUND_Y then
        local dy = arrow.y - prevY
        local t = 1.0
        if math.abs(dy) > 0.0001 then
            t = (GROUND_Y - prevY) / dy
        end
        local gx = prevX + t * (arrow.x - prevX)
        finishShot(false, gx, GROUND_Y, 0)
        return
    end
end

local function updateCamera()
    local targetCamX = 0
    local targetCamY = 0

    if state == "AIMING" then
        if playdate.buttonIsPressed(playdate.kButtonB) then
            -- Holding B peeks straight at the off-screen target
            targetCamX = targetX - SCREEN_W * 0.65
        else
            targetCamX = manualPanX
        end
        targetCamY = 0
    elseif state == "FLYING" then
        targetCamX = math.max(0, arrow.x - SCREEN_W * 0.38)
        targetCamY = math.min(0, math.max(-220, arrow.y - SCREEN_H * 0.45))
    elseif state == "RESULT" then
        if playdate.buttonIsPressed(playdate.kButtonB) then
            targetCamX = targetX - SCREEN_W * 0.6
        else
            targetCamX = math.max(0, arrow.x - SCREEN_W * 0.5)
        end
        targetCamY = 0
    end

    camX = camX + (targetCamX - camX) * 0.18
    camY = camY + (targetCamY - camY) * 0.18
end

-- Draw the Bowman on the left side of the world
local function drawBowman()
    local bx = BOWMAN_X - camX
    local by = BOWMAN_Y - camY
    if bx < -60 or bx > SCREEN_W + 60 then return end

    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)

    -- Legs & stance
    gfx.drawLine(bx - 7, by, bx, by - 16)
    gfx.drawLine(bx + 7, by, bx, by - 16)
    -- Torso
    gfx.drawLine(bx, by - 16, bx, by - 32)
    -- Head & Robin Hood cap
    gfx.fillCircleAtPoint(bx, by - 38, 5)
    gfx.drawLine(bx - 6, by - 41, bx + 5, by - 43)
    gfx.drawLine(bx - 8, by - 44, bx - 3, by - 42)

    -- Bow pivot at shoulder
    local px = bx + 2
    local py = by - 25
    local rad = math.rad(aimAngle)
    local dirX = math.cos(rad)
    local dirY = -math.sin(rad)
    local perpX = -dirY
    local perpY = dirX

    -- Draw bow limb arc
    local bowCenterX = px + dirX * 12
    local bowCenterY = py + dirY * 12
    local topTipX = bowCenterX + perpX * 16 - dirX * 5
    local topTipY = bowCenterY + perpY * 16 - dirY * 5
    local botTipX = bowCenterX - perpX * 16 - dirX * 5
    local botTipY = bowCenterY - perpY * 16 - dirY * 5
    local midBowX = bowCenterX + dirX * 6
    local midBowY = bowCenterY + dirY * 6

    gfx.setLineWidth(2)
    gfx.drawLine(topTipX, topTipY, midBowX, midBowY)
    gfx.drawLine(midBowX, midBowY, botTipX, botTipY)

    -- Bowstring pulled back by current powerCharge when aiming
    local pullAmount = (state == "AIMING") and ((powerCharge / 100.0) * 11) or 0
    local stringMidX = bowCenterX - dirX * (4 + pullAmount)
    local stringMidY = bowCenterY - dirY * (4 + pullAmount)

    gfx.setLineWidth(1)
    gfx.drawLine(topTipX, topTipY, stringMidX, stringMidY)
    gfx.drawLine(botTipX, botTipY, stringMidX, stringMidY)

    -- Draw arrow nocked in bow while aiming
    if state == "AIMING" then
        local arrowTipX = stringMidX + dirX * 24
        local arrowTipY = stringMidY + dirY * 24
        gfx.setLineWidth(2)
        gfx.drawLine(stringMidX, stringMidY, arrowTipX, arrowTipY)
        -- Aiming guide dotted line
        gfx.setLineWidth(1)
        for step = 1, 5 do
            local gx = arrowTipX + dirX * (step * 10)
            local gy = arrowTipY + dirY * (step * 10)
            gfx.fillCircleAtPoint(gx, gy, 1)
        end
    end
end

-- Draw an arrow at world coordinates (ax, ay) with rotation angleDeg
local function drawArrowObject(ax, ay, angleDeg)
    local sx = ax - camX
    local sy = ay - camY
    if sx < -40 or sx > SCREEN_W + 40 or sy < -40 or sy > SCREEN_H + 40 then return end

    local rad = math.rad(angleDeg)
    local cosA = math.cos(rad)
    local sinA = math.sin(rad)

    local tailX = sx - cosA * 18
    local tailY = sy - sinA * 18

    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawLine(tailX, tailY, sx, sy)

    -- Arrowhead
    local perpX = -sinA
    local perpY = cosA
    gfx.fillTriangle(
        sx + cosA * 3, sy + sinA * 3,
        sx - cosA * 5 + perpX * 3, sy - sinA * 5 + perpY * 3,
        sx - cosA * 5 - perpX * 3, sy - sinA * 5 - perpY * 3
    )

    -- Fletching feathers
    gfx.setLineWidth(1)
    gfx.drawLine(tailX, tailY, tailX - cosA * 3 + perpX * 3, tailY - sinA * 3 + perpY * 3)
    gfx.drawLine(tailX, tailY, tailX - cosA * 3 - perpX * 3, tailY - sinA * 3 - perpY * 3)
end

-- Draw the distant Target board and stand
local function drawTarget()
    local tx = targetX - camX
    local ty = targetY - camY
    local gy = GROUND_Y - camY

    if tx < -50 or tx > SCREEN_W + 50 then return end

    gfx.setColor(gfx.kColorBlack)
    -- Wooden tripod stand
    gfx.setLineWidth(2)
    gfx.drawLine(tx, ty, tx - 12, gy)
    gfx.drawLine(tx, ty, tx + 14, gy)

    -- Target rings (side-angled bullseye board)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillEllipseInRect(tx - 7, ty - targetRadius, 14, targetRadius * 2)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawEllipseInRect(tx - 7, ty - targetRadius, 14, targetRadius * 2)

    -- Inner ring
    gfx.setLineWidth(1)
    gfx.drawEllipseInRect(tx - 4, ty - 13, 8, 26)

    -- Bullseye center
    gfx.fillEllipseInRect(tx - 2, ty - 5, 5, 10)

    -- Flag on top of target
    gfx.drawLine(tx, ty - targetRadius, tx, ty - targetRadius - 14)
    local flagDir = (windSpeed < 0) and -10 or 10
    gfx.fillTriangle(
        tx, ty - targetRadius - 14,
        tx + flagDir, ty - targetRadius - 10,
        tx, ty - targetRadius - 6
    )
end

-- Draw scrolling terrain, distance posts, trees, and clouds
local function drawWorld()
    local gy = GROUND_Y - camY

    -- Background clouds & trees
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    for _, item in ipairs(sceneryMarks) do
        local cx = item.cloudX - camX * 0.5 -- Parallax clouds
        local cy = item.cloudY - camY * 0.3
        if cx > -60 and cx < SCREEN_W + 60 then
            gfx.drawRoundRect(cx, cy, item.cloudW, 12, 6)
        end

        local tx = item.x - camX
        if tx > -20 and tx < SCREEN_W + 20 and math.abs(item.x - targetX) > 35 and math.abs(item.x - BOWMAN_X) > 40 then
            -- Small pine tree silhouette
            gfx.drawLine(tx, gy, tx, gy - item.treeH)
            gfx.drawLine(tx - 5, gy - 5, tx, gy - item.treeH)
            gfx.drawLine(tx + 5, gy - 5, tx, gy - item.treeH)
        end
    end

    -- Ground line and turf hash marks
    gfx.setLineWidth(2)
    gfx.drawLine(0, gy, SCREEN_W, gy)
    gfx.setLineWidth(1)

    -- Distance markers every 10m (100 pixels) from BOWMAN_X
    local firstMeterIdx = math.max(0, math.floor((camX - BOWMAN_X) / 100))
    local lastMeterIdx = math.floor((camX + SCREEN_W - BOWMAN_X) / 100) + 1

    for m = firstMeterIdx, lastMeterIdx do
        local worldX = BOWMAN_X + m * 100
        local sx = worldX - camX
        gfx.drawLine(sx, gy, sx, gy + 6)
        if m > 0 then
            gfx.drawText(string.format("%dm", m * 10), sx - 12, gy + 8)
        end
    end
end

-- Draw HUD: Top status bar, Power Charge Meter, Angle & Off-screen Target Indicator
local function drawHUD()
    -- Top Bar
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_W, 20)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    gfx.drawLine(0, 20, SCREEN_W, 20)

    local targetDistMeters = math.floor((targetX - BOWMAN_X) / PIXELS_PER_METER + 0.5)
    local topText = string.format("*BOW MAN*  Score: %d  |  Target: %dm  |  Angle: %d°", score, targetDistMeters, math.floor(aimAngle + 0.5))
    gfx.drawText(topText, 6, 3)

    -- Power Charge Meter on left side of screen
    local meterX = 12
    local meterY = 34
    local meterW = 16
    local meterH = 110

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(meterX - 2, meterY - 2, meterW + 4, meterH + 22)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(meterX, meterY, meterW, meterH)

    -- Fill level based on current powerCharge
    local fillH = math.floor((powerCharge / 100.0) * (meterH - 4))
    gfx.fillRect(meterX + 2, meterY + meterH - 2 - fillH, meterW - 4, fillH)

    -- Marker for previous shot's power level so player can calibrate
    if lastShot and lastShot.power then
        local lastY = meterY + meterH - 2 - math.floor((lastShot.power / 100.0) * (meterH - 4))
        gfx.drawLine(meterX - 4, lastY, meterX + meterW + 4, lastY)
        gfx.fillTriangle(meterX + meterW + 5, lastY, meterX + meterW + 9, lastY - 3, meterX + meterW + 9, lastY + 3)
    end

    -- Power percentage readout
    gfx.drawText(string.format("%d%%", math.floor(powerCharge + 0.5)), meterX - 2, meterY + meterH + 3)

    -- Off-screen Target Indicator badge on the right edge when target is off-screen
    local targetScreenX = targetX - camX
    if targetScreenX > SCREEN_W - 10 then
        local badgeW = 92
        local badgeH = 26
        local badgeX = SCREEN_W - badgeW - 6
        local badgeY = 30

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(badgeX, badgeY, badgeW, badgeH, 4)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(badgeX, badgeY, badgeW, badgeH, 4)
        gfx.drawText(string.format("TARGET %dm >", targetDistMeters), badgeX + 6, badgeY + 5)
    end

    -- Last shot reference box
    if lastShot and state == "AIMING" then
        local refX = 36
        local refY = 32
        local diffM = math.floor(math.abs(lastShot.diffPixels) / PIXELS_PER_METER + 0.5)
        local dirWord = (lastShot.diffPixels < 0) and "Short" or "Long"
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(refX, refY, 210, 22, 4)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(refX, refY, 210, 22, 4)
        gfx.drawText(string.format("Last: %d° @ %d%% (%s %dm)", math.floor(lastShot.angle + 0.5), math.floor(lastShot.power + 0.5), dirWord, diffM), refX + 6, refY + 3)
    end

    -- Wind badge if wind is enabled
    if windEnabled then
        local windText = (windSpeed == 0) and "Wind: Calm" or string.format("Wind: %s %d", (windSpeed > 0 and "-->" or "<--"), math.abs(math.floor(windSpeed / 3)))
        gfx.drawText(windText, 270, 34)
    end

    -- Result Banner Popup
    if state == "RESULT" then
        local boxW = 290
        local boxH = 54
        local boxX = (SCREEN_W - boxW) / 2
        local boxY = 64

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(boxX, boxY, boxW, boxH, 6)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(boxX, boxY, boxW, boxH, 6)
        gfx.setLineWidth(1)

        gfx.drawTextAligned("*" .. resultHeadline .. "*", SCREEN_W / 2, boxY + 8, kTextAlignment.center)
        gfx.drawTextAligned(resultSubtext, SCREEN_W / 2, boxY + 30, kTextAlignment.center)
    end

    -- Bottom Controls Helper Bar during AIMING
    if state == "AIMING" then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, SCREEN_H - 16, SCREEN_W, 16)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(0, SCREEN_H - 16, SCREEN_W, SCREEN_H - 16)
        gfx.drawText("Crank: Aim Angle   A: Stop Power & Shoot   Hold B: Peek Target", 6, SCREEN_H - 14)
    end
end

local function setupMenu()
    local menu = playdate.getSystemMenu()
    menu:removeAllMenuItems()

    menu:addMenuItem("New Target", function()
        spawnNewTarget(false)
        resetForNextShot()
    end)

    menu:addCheckmarkMenuItem("Wind Mode", windEnabled, function(val)
        windEnabled = val
        if windEnabled then
            windSpeed = math.random(-45, 45)
        else
            windSpeed = 0
        end
    end)

    menu:addOptionsMenuItem("Meter Spd", { "Normal", "Fast", "Slow" }, "Normal", function(selected)
        if selected == "Fast" then
            powerSpeed = 135.0
        elseif selected == "Slow" then
            powerSpeed = 55.0
        else
            powerSpeed = 85.0
        end
    end)

    menu:addMenuItem("Reset Score", function()
        spawnNewTarget(true)
        resetForNextShot()
    end)
end

local function init()
    math.randomseed(playdate.getSecondsSinceEpoch())
    setupMenu()
    spawnNewTarget(true)
    resetForNextShot()
end

init()

function playdate.update()
    local dt = 1.0 / 30.0

    if state == "AIMING" then
        -- 1. Crank aims the bow angle (5° to 85°)
        local crankChange = playdate.getCrankChange()
        if math.abs(crankChange) > 0.05 then
            aimAngle = math.max(5.0, math.min(85.0, aimAngle + crankChange * 0.35))
        end

        -- Allow Up/Down D-pad as secondary fine aim adjustment
        if playdate.buttonIsPressed(playdate.kButtonUp) then
            aimAngle = math.min(85.0, aimAngle + 0.6)
        elseif playdate.buttonIsPressed(playdate.kButtonDown) then
            aimAngle = math.max(5.0, aimAngle - 0.6)
        end

        -- Allow Left/Right D-pad to pan camera toward the distant target
        if playdate.buttonIsPressed(playdate.kButtonRight) then
            manualPanX = math.min(targetX - 180, manualPanX + 14)
        elseif playdate.buttonIsPressed(playdate.kButtonLeft) then
            manualPanX = math.max(0, manualPanX - 14)
        end

        -- 2. Oscillate the Power Charge Meter continuously
        powerCharge = powerCharge + powerDir * powerSpeed * dt
        if powerCharge >= 100.0 then
            powerCharge = 100.0
            powerDir = -1
        elseif powerCharge <= 5.0 then
            powerCharge = 5.0
            powerDir = 1
        end

        -- 3. Pressing A stops the Power Charge Meter and launches the arrow!
        if playdate.buttonJustPressed(playdate.kButtonA) then
            fireArrow()
        end

    elseif state == "FLYING" then
        updatePhysics(dt)

    elseif state == "RESULT" then
        resultTimer = resultTimer + dt
        if playdate.buttonJustPressed(playdate.kButtonA) then
            if targetHitSuccess then
                roundNum = roundNum + 1
                spawnNewTarget(false)
            end
            resetForNextShot()
        end
    end

    updateCamera()

    -- Render frame
    gfx.clear(gfx.kColorWhite)
    drawWorld()
    drawTarget()
    drawBowman()

    -- Draw flight trail dots
    gfx.setColor(gfx.kColorBlack)
    for _, pt in ipairs(arrow.trail) do
        local sx = pt.x - camX
        local sy = pt.y - camY
        if sx >= 0 and sx <= SCREEN_W and sy >= 0 and sy <= SCREEN_H then
            gfx.fillCircleAtPoint(sx, sy, 1)
        end
    end

    -- Draw previous stuck arrows on this target
    for _, sa in ipairs(stuckArrows) do
        drawArrowObject(sa.x, sa.y, sa.angle)
    end

    -- Draw currently flying arrow
    if state == "FLYING" and arrow.active then
        drawArrowObject(arrow.x, arrow.y, arrow.angle)
    end

    drawHUD()
    playdate.timer.updateTimers()
end
