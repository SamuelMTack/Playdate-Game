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

local MARBLE_R <const> = 8
local MARBLE_DIAM <const> = 16
local FIRE_SPEED <const> = 340.0

-- Sound Synthesizers
local sfxFire = snd.synth.new(snd.kWaveTriangle)
sfxFire:setVolume(0.24)
sfxFire:setADSR(0.003, 0.06, 0.0, 0.04)

local sfxPop = snd.synth.new(snd.kWaveSine)
sfxPop:setVolume(0.28)
sfxPop:setADSR(0.004, 0.12, 0.05, 0.10)

local sfxClack = snd.synth.new(snd.kWaveSquare)
sfxClack:setVolume(0.18)
sfxClack:setADSR(0.002, 0.04, 0.0, 0.02)

-- Game States: "PLAYING", "STAGE_CLEAR", "GAME_OVER"
local state = "PLAYING"
local score = 0
local highScore = 0
local level = 1
local comboCount = 0

-- Zumba meter (fills as you pop marbles; when full, tunnel stops spawning new marbles)
local stageGoalPoints = 1000
local stageEarnedPoints = 0
local zumbaAchieved = false

-- Turret / Idol state
local turret = {
    x = 200,
    y = 128,
    angle = -90,        -- Degrees
    currentBall = 1,
    nextBall = 2,
    recoil = 0.0
}

-- Track arc-length table: samples[{ x, y, dist }] and totalTrackLength
local trackSamples = {}
local totalTrackLength = 0
local trackBackdrop = gfx.image.new(SCREEN_W, SCREEN_H, gfx.kColorWhite)

-- Rolling chain of marbles: each entry = { type = 1..4, dist = arcLengthAlongTrack }
-- Ordered from tail (smallest dist, near spawn) to head (largest dist, closest to skull)
local chain = {}

-- Fired projectile balls
local bullets = {}

-- Popping particle bursts & floating score popups
local particles = {}
local popups = {}

-- Pushback timer after a match (briefly reverses chain motion like classic Zuma)
local reversePushTimer = 0.0

-- Number of distinct marble types active on current level (4 on early levels, 5 on level 3+)
local numActiveTypes = 4

-- Build a smooth parameterized track with uniform arc-length lookup table
local function buildTrackForLevel(lvl)
    trackSamples = {}
    local rawPoints = {}
    local layout = ((lvl - 1) % 3) + 1

    if layout == 1 then
        -- Layout 1: Classic Temple Oval Spiral around center turret (200, 128)
        turret.x = 200
        turret.y = 128
        local steps = 340
        for i = 0, steps do
            local u = i / steps
            -- Angle winds 1.65 full turns clockwise from top-left outer entrance to inner skull pit
            local theta = -math.pi * 0.85 + u * (math.pi * 2 * 1.58)
            local rx = 182 - u * 114
            local ry = 98 - u * 56
            local px = 200 + math.cos(theta) * rx
            local py = 128 + math.sin(theta) * ry
            px = math.max(16, math.min(SCREEN_W - 16, px))
            py = math.max(30, math.min(SCREEN_H - 14, py))
            rawPoints[#rawPoints + 1] = { x = px, y = py }
        end

    elseif layout == 2 then
        -- Layout 2: Serpent S-Curve Winding around an offset turret
        turret.x = 200
        turret.y = 132
        local steps = 340
        for i = 0, steps do
            local u = i / steps
            local theta = -math.pi + u * (math.pi * 2 * 1.48)
            local wobble = math.sin(u * math.pi * 6) * 8 * (1.0 - u * 0.5)
            local rx = (180 - u * 110) + wobble
            local ry = (96 - u * 54) + wobble * 0.6
            local px = 200 + math.cos(theta) * rx
            local py = 130 + math.sin(theta) * ry
            px = math.max(16, math.min(SCREEN_W - 16, px))
            py = math.max(30, math.min(SCREEN_H - 14, py))
            rawPoints[#rawPoints + 1] = { x = px, y = py }
        end

    else
        -- Layout 3: Counter-Clockwise Shrine Spiral
        turret.x = 200
        turret.y = 126
        local steps = 340
        for i = 0, steps do
            local u = i / steps
            local theta = -math.pi * 0.15 - u * (math.pi * 2 * 1.58)
            local rx = 182 - u * 114
            local ry = 98 - u * 56
            local px = 200 + math.cos(theta) * rx
            local py = 126 + math.sin(theta) * ry
            px = math.max(16, math.min(SCREEN_W - 16, px))
            py = math.max(30, math.min(SCREEN_H - 14, py))
            rawPoints[#rawPoints + 1] = { x = px, y = py }
        end
    end

    -- Compute cumulative arc-length distances
    local cumDist = 0.0
    trackSamples[1] = { x = rawPoints[1].x, y = rawPoints[1].y, dist = 0.0 }
    for i = 2, #rawPoints do
        local dx = rawPoints[i].x - rawPoints[i - 1].x
        local dy = rawPoints[i].y - rawPoints[i - 1].y
        local segLen = math.sqrt(dx * dx + dy * dy)
        if segLen > 0.5 then
            cumDist = cumDist + segLen
            trackSamples[#trackSamples + 1] = {
                x = rawPoints[i].x,
                y = rawPoints[i].y,
                dist = cumDist
            }
        end
    end
    totalTrackLength = cumDist

    -- Pre-render the stone track groove and Skull Pit onto trackBackdrop image for fast 30fps drawing
    trackBackdrop:clear(gfx.kColorWhite)
    gfx.pushContext(trackBackdrop)

    -- Draw outer stone track border
    gfx.setColor(gfx.kColorBlack)
    for i = 1, #trackSamples, 2 do
        local p = trackSamples[i]
        gfx.fillCircleAtPoint(p.x, p.y, 10)
    end
    -- Carve inner white groove channel
    gfx.setColor(gfx.kColorWhite)
    for i = 1, #trackSamples, 2 do
        local p = trackSamples[i]
        gfx.fillCircleAtPoint(p.x, p.y, 8)
    end
    -- Center dotted track guide rail
    gfx.setColor(gfx.kColorBlack)
    for i = 1, #trackSamples, 6 do
        local p = trackSamples[i]
        gfx.fillCircleAtPoint(p.x, p.y, 1)
    end

    -- Entry Tunnel Arch at track start
    local startPt = trackSamples[1]
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(startPt.x, startPt.y, 12)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawCircleAtPoint(startPt.x, startPt.y, 10)

    -- Skull Pit at track end
    local endPt = trackSamples[#trackSamples]
    local sx = endPt.x
    local sy = endPt.y
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(sx, sy, 15)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawCircleAtPoint(sx, sy, 15)
    -- Skull eyes & teeth
    gfx.fillCircleAtPoint(sx - 5, sy - 3, 3)
    gfx.fillCircleAtPoint(sx + 5, sy - 3, 3)
    gfx.fillTriangle(sx, sy, sx - 2, sy + 4, sx + 2, sy + 4)
    gfx.setLineWidth(1)
    gfx.drawLine(sx - 6, sy + 8, sx + 6, sy + 8)
    for tx = -4, 4, 4 do
        gfx.drawLine(sx + tx, sy + 6, sx + tx, sy + 11)
    end

    gfx.popContext()
end

-- Evaluate (x, y) coordinates at a given arc-length distance along the track
local function getTrackPointAtDist(d)
    if d <= 0 then
        return trackSamples[1].x, trackSamples[1].y
    elseif d >= totalTrackLength then
        local last = trackSamples[#trackSamples]
        return last.x, last.y
    end

    -- Binary search in trackSamples
    local low = 1
    local high = #trackSamples
    while low < high - 1 do
        local mid = math.floor((low + high) / 2)
        if trackSamples[mid].dist <= d then
            low = mid
        else
            high = mid
        end
    end

    local s1 = trackSamples[low]
    local s2 = trackSamples[high]
    local span = s2.dist - s1.dist
    local t = (span > 0.0001) and ((d - s1.dist) / span) or 0.0
    return s1.x + (s2.x - s1.x) * t, s1.y + (s2.y - s1.y) * t
end

-- Choose a valid marble type (when marbles exist on track, pick from types currently on track)
local function pickShooterMarbleType()
    if #chain == 0 then
        return math.random(1, numActiveTypes)
    end
    local present = {}
    local list = {}
    for _, m in ipairs(chain) do
        if not present[m.type] then
            present[m.type] = true
            list[#list + 1] = m.type
        end
    end
    if #list == 0 then
        return math.random(1, numActiveTypes)
    end
    return list[math.random(1, #list)]
end

-- Spawn a new marble at the start of the track (avoiding automatic 3-in-a-row on spawn)
local function spawnTailMarble(initialDist)
    local t = math.random(1, numActiveTypes)
    if #chain >= 2 and chain[1].type == t and chain[2].type == t then
        t = (t % numActiveTypes) + 1
    end
    table.insert(chain, 1, {
        type = t,
        dist = initialDist or 0.0
    })
end

-- Start or advance to a level
local function startLevel(lvl, resetScore)
    level = lvl
    if resetScore then
        score = 0
    end
    state = "PLAYING"
    comboCount = 0
    stageEarnedPoints = 0
    stageGoalPoints = 800 + (level - 1) * 350
    zumbaAchieved = false
    reversePushTimer = 0.0
    numActiveTypes = (level >= 3) and 5 or 4

    chain = {}
    bullets = {}
    particles = {}
    popups = {}

    buildTrackForLevel(level)

    -- Populate an initial wave of 18 marbles rolling out from the tunnel
    local initialCount = 18 + math.min(10, (level - 1) * 2)
    for i = 1, initialCount do
        spawnTailMarble(0)
        -- Space existing marbles forward by MARBLE_DIAM
        for j = 2, #chain do
            chain[j].dist = chain[j].dist + MARBLE_DIAM
        end
    end

    turret.currentBall = pickShooterMarbleType()
    turret.nextBall = pickShooterMarbleType()
end

-- Spawn explosion particles and floating score popup at (px, py)
local function addExplosion(px, py, text)
    for _ = 1, 7 do
        local ang = math.random() * math.pi * 2
        local spd = math.random(35, 110)
        table.insert(particles, {
            x = px,
            y = py,
            vx = math.cos(ang) * spd,
            vy = math.sin(ang) * spd,
            life = 0.35
        })
    end
    if text then
        table.insert(popups, {
            x = px,
            y = py - 6,
            text = text,
            life = 0.75
        })
    end
end

-- Check around chain[centerIdx] for 3 or more matching marbles and pop them!
local function checkAndPopMatchAt(centerIdx)
    if centerIdx < 1 or centerIdx > #chain then return false end

    local targetType = chain[centerIdx].type
    local leftIdx = centerIdx
    local rightIdx = centerIdx

    -- Only count contiguous marbles that are physically touching (within MARBLE_DIAM + 3.5 px)
    while leftIdx > 1 and chain[leftIdx - 1].type == targetType and (chain[leftIdx].dist - chain[leftIdx - 1].dist) <= (MARBLE_DIAM + 3.5) do
        leftIdx = leftIdx - 1
    end
    while rightIdx < #chain and chain[rightIdx + 1].type == targetType and (chain[rightIdx + 1].dist - chain[rightIdx].dist) <= (MARBLE_DIAM + 3.5) do
        rightIdx = rightIdx + 1
    end

    local matchCount = rightIdx - leftIdx + 1
    if matchCount >= 3 then
        comboCount = comboCount + 1
        local pts = matchCount * 50 * comboCount
        score = score + pts
        if score > highScore then
            highScore = score
        end

        if not zumbaAchieved then
            stageEarnedPoints = stageEarnedPoints + pts
            if stageEarnedPoints >= stageGoalPoints then
                stageEarnedPoints = stageGoalPoints
                zumbaAchieved = true
                sfxPop:playNote(783.99, 0.3, 0.22)
            end
        end

        -- Trigger particle burst at the center of the matched group
        local midIdx = math.floor((leftIdx + rightIdx) / 2)
        local mx, my = getTrackPointAtDist(chain[midIdx].dist)
        local label = (comboCount > 1) and string.format("+%d (%dx!)", pts, comboCount) or string.format("+%d", pts)
        addExplosion(mx, my, label)

        -- Remove matched marbles from rightIdx down to leftIdx
        for idx = rightIdx, leftIdx, -1 do
            table.remove(chain, idx)
        end

        -- Brief backward push on the chain to reward the player
        reversePushTimer = 0.45 + math.min(0.45, comboCount * 0.15)
        sfxPop:playNote(440 + math.min(440, comboCount * 110), 0.28, 0.12)

        -- Ensure shooter holds valid marble colors still remaining on the board
        if #chain > 0 then
            turret.currentBall = pickShooterMarbleType()
        else
            -- Track completely cleared! Stage Clear!
            state = "STAGE_CLEAR"
            sfxPop:playNote(880, 0.3, 0.25)
        end
        return true
    else
        comboCount = 0
        return false
    end
end

-- Insert a fired ball of ballType into the chain adjacent to hitIdx
local function insertBallIntoChain(hitIdx, ballType, bx, by)
    -- Determine whether the bullet landed slightly ahead of or behind chain[hitIdx]
    local hitDist = chain[hitIdx].dist
    local aheadX, aheadY = getTrackPointAtDist(hitDist + 4)
    local behindX, behindY = getTrackPointAtDist(hitDist - 4)

    local dAhead = (bx - aheadX) ^ 2 + (by - aheadY) ^ 2
    local dBehind = (bx - behindX) ^ 2 + (by - behindY) ^ 2

    local insertIdx = hitIdx
    local insertDist = hitDist

    if dAhead < dBehind then
        -- Insert right in front of hitIdx (at hitIdx + 1)
        insertIdx = hitIdx + 1
        insertDist = hitDist + MARBLE_DIAM
    else
        -- Insert right behind hitIdx (at hitIdx), pushing hitIdx and forward contiguous marbles ahead
        insertIdx = hitIdx
        insertDist = hitDist
    end

    table.insert(chain, insertIdx, {
        type = ballType,
        dist = insertDist
    })

    -- Push any overlapping marbles ahead of insertIdx forward by MARBLE_DIAM
    for i = insertIdx + 1, #chain do
        local minAllowed = chain[i - 1].dist + MARBLE_DIAM
        if chain[i].dist < minAllowed then
            chain[i].dist = minAllowed
        else
            break
        end
    end

    sfxClack:playNote(300, 0.18, 0.04)

    -- Check if this insertion formed a 3+ match!
    checkAndPopMatchAt(insertIdx)
end

-- Update rolling chain physics, magnetic gap closing, and skull pit detection
local function updateChain(dt)
    if state ~= "PLAYING" then return end

    -- Spawn new marbles at the tunnel mouth until ZUMBA! meter is filled
    if not zumbaAchieved then
        if #chain == 0 or chain[1].dist >= MARBLE_DIAM then
            local tailDist = (#chain > 0) and (chain[1].dist - MARBLE_DIAM) or 0.0
            spawnTailMarble(math.max(0.0, tailDist))
        end
    elseif #chain == 0 then
        state = "STAGE_CLEAR"
        return
    end

    -- Base rolling speed (faster near the start to fill the board, then steady pace)
    local baseSpeed = 20.0 + (level - 1) * 3.5
    if #chain > 0 and chain[#chain].dist < totalTrackLength * 0.28 then
        baseSpeed = baseSpeed * 2.2
    end

    if reversePushTimer > 0 then
        reversePushTimer = reversePushTimer - dt
        baseSpeed = -42.0
    end

    -- 1. Push the tail segment forward from the rear
    if #chain > 0 then
        chain[1].dist = math.max(0.0, chain[1].dist + baseSpeed * dt)
    end

    -- 2. Resolve collisions and magnetic attractions between consecutive segments
    local i = 2
    while i <= #chain do
        local prev = chain[i - 1]
        local curr = chain[i]
        local gap = curr.dist - prev.dist

        if gap < MARBLE_DIAM then
            -- Rear marble pushes forward marble ahead
            curr.dist = prev.dist + MARBLE_DIAM
            i = i + 1
        elseif gap > MARBLE_DIAM + 1.0 then
            -- There is an open gap in the chain!
            -- If the two marbles bordering the gap are the SAME color, magnetically pull the front group backward!
            if prev.type == curr.type then
                local pullAmount = 145.0 * dt
                local shift = math.min(gap - MARBLE_DIAM, pullAmount)
                -- Pull curr and all contiguous marbles attached ahead of curr backward
                for k = i, #chain do
                    if k == i or (chain[k].dist - chain[k - 1].dist) <= (MARBLE_DIAM + 2.0) then
                        chain[k].dist = chain[k].dist - shift
                    else
                        break
                    end
                end

                -- If the magnetic gap just closed, check for a chain-reaction match!
                if (chain[i].dist - chain[i - 1].dist) <= (MARBLE_DIAM + 1.5) then
                    sfxClack:playNote(380, 0.2, 0.04)
                    if checkAndPopMatchAt(i) then
                        return
                    end
                end
            elseif baseSpeed < 0 then
                -- During reverse pushback, pull front segments gently too
                curr.dist = math.max(prev.dist + MARBLE_DIAM, curr.dist + baseSpeed * dt)
            end
            i = i + 1
        else
            i = i + 1
        end
    end

    -- 3. Check if the lead marble reached the Skull Pit!
    if #chain > 0 and chain[#chain].dist >= totalTrackLength - 4 then
        state = "GAME_OVER"
        sfxClack:playNote(130, 0.28, 0.25)
    end
end

-- Fire a marble from the center turret when A is pressed
local function fireBall()
    local rad = math.rad(turret.angle)
    local cosA = math.cos(rad)
    local sinA = math.sin(rad)

    table.insert(bullets, {
        x = turret.x + cosA * 18,
        y = turret.y + sinA * 18,
        vx = cosA * FIRE_SPEED,
        vy = sinA * FIRE_SPEED,
        type = turret.currentBall
    })

    turret.currentBall = turret.nextBall
    turret.nextBall = pickShooterMarbleType()
    turret.recoil = 5.0
    comboCount = 0

    sfxFire:playNote(360, 0.22, 0.05)
end

-- Update flying bullets and check collisions with the rolling marble chain
local function updateBullets(dt)
    local bIdx = 1
    while bIdx <= #bullets do
        local b = bullets[bIdx]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt

        -- Remove if bullet exits the screen
        if b.x < -16 or b.x > SCREEN_W + 16 or b.y < 14 or b.y > SCREEN_H + 16 then
            table.remove(bullets, bIdx)
        else
            -- Check collision against every marble in the chain
            local hitIdx = nil
            local bestDistSq = (MARBLE_DIAM - 1) ^ 2

            for i, m in ipairs(chain) do
                local mx, my = getTrackPointAtDist(m.dist)
                local dx = b.x - mx
                local dy = b.y - my
                local dSq = dx * dx + dy * dy
                if dSq <= bestDistSq then
                    bestDistSq = dSq
                    hitIdx = i
                end
            end

            if hitIdx then
                local firedType = b.type
                local bx, by = b.x, b.y
                table.remove(bullets, bIdx)
                insertBallIntoChain(hitIdx, firedType, bx, by)
            else
                bIdx = bIdx + 1
            end
        end
    end
end

-- Update particles and score popups
local function updateEffects(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            i = i + 1
        end
    end

    local j = 1
    while j <= #popups do
        local pop = popups[j]
        pop.life = pop.life - dt
        if pop.life <= 0 then
            table.remove(popups, j)
        else
            pop.y = pop.y - 18 * dt
            j = j + 1
        end
    end

    if turret.recoil > 0 then
        turret.recoil = math.max(0, turret.recoil - 28 * dt)
    end
end

-- Draw a single 1-bit patterned marble at (x, y) so all 5 marble types are unmistakable
local function drawMarble(x, y, mType, radius)
    local r = radius or MARBLE_R

    if mType == 1 then
        -- Type 1: Solid Obsidian Black with white specular highlight dot
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(x, y, r)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(x - 2, y - 2, 2)

    elseif mType == 2 then
        -- Type 2: Pearl Open Double Ring
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(x, y, r)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawCircleAtPoint(x, y, r)
        gfx.setLineWidth(1)
        gfx.drawCircleAtPoint(x, y, math.max(2, r - 4))

    elseif mType == 3 then
        -- Type 3: Bold Plus / Cross Emblem
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(x, y, r)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)
        gfx.drawCircleAtPoint(x, y, r)
        gfx.setLineWidth(2)
        gfx.drawLine(x - r + 3, y, x + r - 3, y)
        gfx.drawLine(x, y - r + 3, x, y + r - 3)
        gfx.setLineWidth(1)

    elseif mType == 4 then
        -- Type 4: Banded / Striped Sphere
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(x, y, r)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)
        gfx.drawCircleAtPoint(x, y, r)
        gfx.drawLine(x - r + 2, y - 3, x + r - 2, y - 3)
        gfx.drawLine(x - r + 1, y,     x + r - 1, y)
        gfx.drawLine(x - r + 2, y + 3, x + r - 2, y + 3)

    else
        -- Type 5: Solid Diamond Core Sphere
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(x, y, r)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(x, y, r)
        gfx.fillPolygon(x, y - 4, x + 4, y, x, y + 4, x - 4, y)
    end
end

-- Draw the center Stone Frog / Idol Turret, aiming sight line, active ball, and next ball preview
local function drawTurret()
    local rad = math.rad(turret.angle)
    local cosA = math.cos(rad)
    local sinA = math.sin(rad)
    local perpX = -sinA
    local perpY = cosA

    local tx = turret.x - cosA * turret.recoil
    local ty = turret.y - sinA * turret.recoil

    -- Dotted Aiming Laser Sight Line
    if state == "PLAYING" then
        gfx.setColor(gfx.kColorBlack)
        for step = 28, 88, 12 do
            local gx = turret.x + cosA * step
            local gy = turret.y + sinA * step
            gfx.fillCircleAtPoint(gx, gy, 1)
        end
    end

    -- Stone pedestal base ring
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(tx, ty, 20)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawCircleAtPoint(tx, ty, 20)
    gfx.setLineWidth(1)
    gfx.drawCircleAtPoint(tx, ty, 16)

    -- Frog / Idol eyes on either side of the turret head
    local eyeDist = 11
    local eyeFwd = 4
    local e1x = tx + cosA * eyeFwd + perpX * eyeDist
    local e1y = ty + sinA * eyeFwd + perpY * eyeDist
    local e2x = tx + cosA * eyeFwd - perpX * eyeDist
    local e2y = ty + sinA * eyeFwd - perpY * eyeDist
    gfx.fillCircleAtPoint(e1x, e1y, 4)
    gfx.fillCircleAtPoint(e2x, e2y, 4)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(e1x + cosA, e1y + sinA, 1)
    gfx.fillCircleAtPoint(e2x + cosA, e2y + sinA, 1)

    -- Next Ball preview gem mounted on the back of the idol
    local backX = tx - cosA * 10
    local backY = ty - sinA * 10
    drawMarble(backX, backY, turret.nextBall, 5)

    -- Active Ball held in the idol's front mouth ready to fire
    local mouthX = tx + cosA * 12
    local mouthY = ty + sinA * 12
    drawMarble(mouthX, mouthY, turret.currentBall, MARBLE_R)
end

-- Draw Top Score & ZUMBA! Progress Bar + End-of-Stage / Game Over Banners
local function drawHUD()
    -- Top Bar
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_W, 20)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    gfx.drawLine(0, 20, SCREEN_W, 20)

    local hdr = string.format("*ZUMBA CLASSIC*  Lv:%d  Score:%d", level, score)
    gfx.drawText(hdr, 6, 2)

    -- ZUMBA! Progress Meter on the top right
    local meterX = 278
    local meterY = 4
    local meterW = 114
    local meterH = 12
    gfx.drawRect(meterX, meterY, meterW, meterH)
    local fillRatio = math.min(1.0, stageEarnedPoints / stageGoalPoints)
    local fillW = math.floor(fillRatio * (meterW - 4))
    gfx.fillRect(meterX + 2, meterY + 2, fillW, meterH - 4)

    if zumbaAchieved then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(222, 2, 54, 16)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawText("*ZUMBA!*", 224, 2)
    else
        gfx.drawText("METER:", 230, 2)
    end

    -- Floating score popups
    for _, pop in ipairs(popups) do
        gfx.drawText("*" .. pop.text .. "*", pop.x - 14, pop.y)
    end

    -- Stage Clear or Game Over Modal Box
    if state == "STAGE_CLEAR" or state == "GAME_OVER" then
        local boxW = 264
        local boxH = 68
        local boxX = (SCREEN_W - boxW) / 2
        local boxY = (SCREEN_H - boxH) / 2

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(boxX, boxY, boxW, boxH, 6)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(boxX, boxY, boxW, boxH, 6)
        gfx.setLineWidth(1)

        if state == "STAGE_CLEAR" then
            gfx.drawTextAligned(string.format("*TEMPLE %d CLEARED!*", level), SCREEN_W / 2, boxY + 10, kTextAlignment.center)
            gfx.drawTextAligned(string.format("Score: %d   |   Best: %d", score, highScore), SCREEN_W / 2, boxY + 29, kTextAlignment.center)
            gfx.drawTextAligned("Press A for Next Temple", SCREEN_W / 2, boxY + 47, kTextAlignment.center)
        else
            gfx.drawTextAligned("*SKULL PIT REACHED - GAME OVER*", SCREEN_W / 2, boxY + 10, kTextAlignment.center)
            gfx.drawTextAligned(string.format("Final Score: %d   |   Best: %d", score, highScore), SCREEN_W / 2, boxY + 29, kTextAlignment.center)
            gfx.drawTextAligned("Press A to Play Again", SCREEN_W / 2, boxY + 47, kTextAlignment.center)
        end
    end
end

local function setupMenu()
    local menu = playdate.getSystemMenu()
    menu:removeAllMenuItems()

    menu:addMenuItem("Next Temple", function()
        startLevel(level + 1, false)
    end)

    menu:addMenuItem("Restart Game", function()
        startLevel(1, true)
    end)
end

local function init()
    math.randomseed(playdate.getSecondsSinceEpoch())
    setupMenu()
    startLevel(1, true)
end

init()

function playdate.update()
    local dt = 1.0 / 30.0

    if state == "PLAYING" then
        -- 1. Crank aims the center turret (supports both absolute crank position and delta turning)
        local crankChange = playdate.getCrankChange()
        if math.abs(crankChange) > 0.05 then
            turret.angle = (turret.angle + crankChange) % 360
        end

        -- Also allow Left / Right D-Pad to rotate the turret if the crank is docked
        if playdate.buttonIsPressed(playdate.kButtonLeft) then
            turret.angle = (turret.angle - 5.5) % 360
        elseif playdate.buttonIsPressed(playdate.kButtonRight) then
            turret.angle = (turret.angle + 5.5) % 360
        end

        -- 2. A Button fires the active ball!
        if playdate.buttonJustPressed(playdate.kButtonA) then
            fireBall()
        end

        -- 3. B Button swaps the active ball with the next ball on the idol's back!
        if playdate.buttonJustPressed(playdate.kButtonB) then
            local tmp = turret.currentBall
            turret.currentBall = turret.nextBall
            turret.nextBall = tmp
            sfxClack:playNote(480, 0.15, 0.03)
        end

        updateChain(dt)
        updateBullets(dt)
        updateEffects(dt)

    elseif state == "STAGE_CLEAR" then
        updateEffects(dt)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startLevel(level + 1, false)
        end

    elseif state == "GAME_OVER" then
        updateEffects(dt)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startLevel(1, true)
        end
    end

    -- Render frame
    gfx.clear(gfx.kColorWhite)
    trackBackdrop:draw(0, 0)

    -- Draw all marbles in the rolling chain
    for _, m in ipairs(chain) do
        local mx, my = getTrackPointAtDist(m.dist)
        drawMarble(mx, my, m.type, MARBLE_R)
    end

    -- Draw flying projectile balls
    for _, b in ipairs(bullets) do
        drawMarble(b.x, b.y, b.type, MARBLE_R)
    end

    -- Draw explosion particles
    gfx.setColor(gfx.kColorBlack)
    for _, p in ipairs(particles) do
        gfx.fillCircleAtPoint(p.x, p.y, 2)
    end

    drawTurret()
    drawHUD()

    playdate.timer.updateTimers()
end
