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
local MAX_PARTICLES <const> = 180

-- Soft noise synthesizer for smoke hiss and vortex wind
local sfxPuff = snd.synth.new(snd.kWaveNoise)
sfxPuff:setVolume(0.14)
sfxPuff:setADSR(0.01, 0.12, 0.05, 0.18)

local sfxSwirl = snd.synth.new(snd.kWaveSine)
sfxSwirl:setVolume(0.10)
sfxSwirl:setADSR(0.02, 0.08, 0.0, 0.06)

-- Crank Vortex Center (moved by Left, Right, Up, Down)
local vortex = {
    x = SCREEN_W / 2,
    y = SCREEN_H / 2,
    spinAngle = 0.0,
    angularVel = 0.0,   -- Driven by the Crank
    radius = 135.0,     -- Influence radius of the whirlpool
    moveSpeed = 160.0   -- Pixels per second when moving with D-Pad
}

-- Smoke particles pool
local particles = {}

-- Visual & Simulation settings
local STYLES <const> = { "Dither Cloud", "Dark Plume", "Night Mist", "Swirl Wisps" }
local styleIndex = 1
local showHUD = true
local autoEmbers = false
local simTime = 0.0

-- Spawn a single smoke particle at (sx, sy) with initial velocity
local function spawnParticle(sx, sy, vx, vy, sizeScale)
    -- If pool is full, recycle the oldest particle
    if #particles >= MAX_PARTICLES then
        table.remove(particles, 1)
    end

    local startR = math.random(5, 10) * (sizeScale or 1.0)
    local maxR = startR + math.random(12, 24) * (sizeScale or 1.0)

    table.insert(particles, {
        x = sx,
        y = sy,
        prevX = sx,
        prevY = sy,
        vx = vx,
        vy = vy,
        r = startR,
        maxR = maxR,
        age = 0.0,
        life = math.random(32, 65) / 10.0, -- 3.2 to 6.5 seconds
        seed = math.random() * 100.0
    })
end

-- Disperse random smoke from the bottom of the screen (triggered by A or B buttons)
local function disperseRandomBottomSmoke(mode, count)
    if mode == "WIDE" then
        -- A Button: Disperse smoke across random spots along the entire bottom edge
        local numClusters = math.random(2, 4)
        local perCluster = math.max(2, math.floor(count / numClusters))
        for _ = 1, numClusters do
            local baseX = math.random(24, SCREEN_W - 24)
            for _ = 1, perCluster do
                local sx = baseX + math.random(-22, 22)
                local sy = SCREEN_H - math.random(2, 14)
                local vx = (math.random() - 0.5) * 65
                local vy = -math.random(35, 95)
                spawnParticle(sx, sy, vx, vy, 1.0)
            end
        end
    else
        -- B Button: Disperse a dense billowing plume from a random bottom vent
        local ventX = math.random(35, SCREEN_W - 35)
        for _ = 1, count do
            local sx = ventX + math.random(-16, 16)
            local sy = SCREEN_H - math.random(2, 12)
            local spreadAngle = math.rad(-90 + math.random(-38, 38))
            local speed = math.random(45, 115)
            local vx = math.cos(spreadAngle) * speed
            local vy = math.sin(spreadAngle) * speed
            spawnParticle(sx, sy, vx, vy, 1.15)
        end
    end
end

-- Update D-Pad movement of the Crank Center and Crank spinning/whirling
local function updateControls(dt)
    -- 1. Left, Right, Up, Down moves the crank center for spinning and whirling
    local dx = 0
    local dy = 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        dx = dx - 1
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        dx = dx + 1
    end
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        dy = dy - 1
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then
        dy = dy + 1
    end

    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.7071
        dy = dy * 0.7071
    end

    local minY = showHUD and 22 or 8
    local maxY = showHUD and (SCREEN_H - 22) or (SCREEN_H - 8)
    vortex.x = math.max(12, math.min(SCREEN_W - 12, vortex.x + dx * vortex.moveSpeed * dt))
    vortex.y = math.max(minY, math.min(maxY, vortex.y + dy * vortex.moveSpeed * dt))

    -- 2. A and B buttons randomly disperse smoke from the bottom
    if playdate.buttonJustPressed(playdate.kButtonA) then
        disperseRandomBottomSmoke("WIDE", 18)
        sfxPuff:playNote(180 + math.random(-30, 40), 0.15, 0.12)
    elseif playdate.buttonIsPressed(playdate.kButtonA) then
        disperseRandomBottomSmoke("WIDE", 4)
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        disperseRandomBottomSmoke("PLUME", 20)
        sfxPuff:playNote(130 + math.random(-20, 30), 0.18, 0.14)
    elseif playdate.buttonIsPressed(playdate.kButtonB) then
        disperseRandomBottomSmoke("PLUME", 4)
    end

    -- Optional gentle ambient bottom smoke if toggled in menu
    if autoEmbers and math.random() < 0.35 then
        disperseRandomBottomSmoke("WIDE", 2)
    end

    -- 3. Crank spins and whirls the smoke around the crank center
    local crankChange, acceleratedChange = playdate.getCrankChange()
    if math.abs(crankChange) > 0.05 then
        -- Feed crank rotation into vortex angular velocity
        vortex.angularVel = vortex.angularVel * 0.65 + acceleratedChange * 1.45
        vortex.angularVel = math.max(-95.0, math.min(95.0, vortex.angularVel))

        if math.random() < 0.25 then
            local pitch = 220 + math.min(350, math.abs(vortex.angularVel) * 4)
            sfxSwirl:playNote(pitch, 0.07, 0.03)
        end
    else
        -- Smooth fluid inertia decay when crank stops
        vortex.angularVel = vortex.angularVel * 0.91
        if math.abs(vortex.angularVel) < 0.15 then
            vortex.angularVel = 0.0
        end
    end

    vortex.spinAngle = (vortex.spinAngle + vortex.angularVel * 0.8) % 360
end

-- Update fluid dynamics, buoyancy, turbulence, and crank vortex whirling for all smoke puffs
local function updateSmokePhysics(dt)
    local vxCenter = vortex.x
    local vyCenter = vortex.y
    local swirlStrength = vortex.angularVel
    local hasSwirl = math.abs(swirlStrength) > 0.2

    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.age = p.age + dt

        if p.age >= p.life or p.y < -35 or p.x < -35 or p.x > SCREEN_W + 35 then
            table.remove(particles, i)
        else
            p.prevX = p.x
            p.prevY = p.y

            -- 1. Natural upward thermal buoyancy (smoke rises from the bottom)
            local buoyancy = -28.0
            p.vy = p.vy + buoyancy * dt

            -- 2. Curl-like organic turbulence wave so rising smoke billows naturally
            local wavePhase = simTime * 2.4 + p.seed + p.y * 0.035
            p.vx = p.vx + math.sin(wavePhase) * 34.0 * dt
            p.vy = p.vy + math.cos(wavePhase * 0.8) * 12.0 * dt

            -- 3. Crank Vortex Whirlpool Force around (vortex.x, vortex.y)
            if hasSwirl then
                local rx = p.x - vxCenter
                local ry = p.y - vyCenter
                local distSq = rx * rx + ry * ry
                local dist = math.sqrt(distSq)

                if dist < 240.0 and dist > 0.5 then
                    -- Normalized tangential unit vector (-ry/dist, rx/dist) for clockwise rotation
                    local tx = -ry / dist
                    local ty = rx / dist
                    -- Radial unit vector (rx/dist, ry/dist)
                    local nx = rx / dist
                    local ny = ry / dist

                    -- Falloff curve: strongest near vortex core, reaching wide across the cloud
                    local influence = math.exp(-dist / vortex.radius)
                    local tangentialAccel = swirlStrength * 22.0 * influence

                    -- Apply tangential whirling acceleration
                    p.vx = p.vx + tx * tangentialAccel * dt
                    p.vy = p.vy + ty * tangentialAccel * dt

                    -- Pull outer smoke inward toward vortex core while churning inner core
                    local radialPull = (dist > 34.0) and (- math.abs(swirlStrength) * 5.5 * influence) or (math.abs(swirlStrength) * 3.0 * influence)
                    p.vx = p.vx + nx * radialPull * dt
                    p.vy = p.vy + ny * radialPull * dt
                end
            end

            -- 4. Air drag / fluid damping
            p.vx = p.vx * 0.965
            p.vy = p.vy * 0.965

            -- 5. Integrate position
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt

            -- Soft bounce off left/right screen edges and ceiling so whirled smoke stays visible longer
            if p.x < 8 then
                p.x = 8
                p.vx = math.abs(p.vx) * 0.5
            elseif p.x > SCREEN_W - 8 then
                p.x = SCREEN_W - 8
                p.vx = -math.abs(p.vx) * 0.5
            end
            if p.y > SCREEN_H - 4 then
                p.y = SCREEN_H - 4
                p.vy = -math.abs(p.vy) * 0.6
            end

            -- Expand puff radius as it rises and ages
            local lifeRatio = p.age / p.life
            p.r = p.r + (p.maxR - p.r) * (dt * 1.4)

            i = i + 1
        end
    end
end

-- Draw all smoke particles in the selected 1-bit visual style
local function drawSmoke()
    local style = STYLES[styleIndex]
    local isNight = (style == "Night Mist")
    local fgColor = isNight and gfx.kColorWhite or gfx.kColorBlack

    gfx.setColor(fgColor)

    for _, p in ipairs(particles) do
        local lifeRatio = p.age / p.life
        local r = math.floor(p.r)

        if style == "Dither Cloud" or style == "Night Mist" then
            -- Smooth dither fade-out as smoke expands and dissipates
            local alpha = 1.0 - (lifeRatio * lifeRatio) * 0.88
            gfx.setColor(fgColor)
            gfx.setDitherPattern(1.0 - alpha, gfx.image.kDitherTypeBayer8x8)
            gfx.fillCircleAtPoint(p.x, p.y, r)

        elseif style == "Dark Plume" then
            -- Bold graphic smoke rings & solid billowing cores
            gfx.setColor(gfx.kColorBlack)
            if lifeRatio < 0.45 then
                gfx.fillCircleAtPoint(p.x, p.y, r)
            elseif lifeRatio < 0.78 then
                gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer4x4)
                gfx.fillCircleAtPoint(p.x, p.y, r)
                gfx.setColor(gfx.kColorBlack)
                gfx.drawCircleAtPoint(p.x, p.y, r)
            else
                gfx.drawCircleAtPoint(p.x, p.y, r)
            end

        elseif style == "Swirl Wisps" then
            -- Streamline smoke wisps showing velocity & curl
            gfx.setColor(gfx.kColorBlack)
            local tailX = p.x - p.vx * 0.14
            local tailY = p.y - p.vy * 0.14
            gfx.setLineWidth(math.max(1, math.floor((1.0 - lifeRatio) * 4)))
            gfx.drawLine(tailX, tailY, p.x, p.y)
            gfx.setLineWidth(1)
            gfx.drawCircleAtPoint(p.x, p.y, math.max(2, math.floor(r * 0.65)))
        end
    end

    -- Reset pattern to solid color
    gfx.setColor(fgColor)
end

-- Draw the movable Crank Vortex Center reticle and animated swirl blades
local function drawVortexCenter()
    local style = STYLES[styleIndex]
    local isNight = (style == "Night Mist")
    local fgColor = isNight and gfx.kColorWhite or gfx.kColorBlack
    local bgColor = isNight and gfx.kColorBlack or gfx.kColorWhite

    local cx = vortex.x
    local cy = vortex.y
    local spinMag = math.abs(vortex.angularVel)

    -- White/Black halo outline for visibility over dense smoke
    gfx.setColor(bgColor)
    gfx.fillCircleAtPoint(cx, cy, 4)

    gfx.setColor(fgColor)
    gfx.setLineWidth(1)

    -- Center crosshair ticks (movable with D-Pad)
    gfx.drawCircleAtPoint(cx, cy, 7)
    gfx.drawLine(cx - 11, cy, cx - 4, cy)
    gfx.drawLine(cx + 4, cy, cx + 11, cy)
    gfx.drawLine(cx, cy - 11, cx, cy - 4)
    gfx.drawLine(cx, cy + 4, cx, cy + 11)

    -- Animated whirlpool arms around the Crank Center when the crank is spinning
    local numArms = 3
    local armRadius = 14 + math.min(28, spinMag * 0.45)
    for a = 0, numArms - 1 do
        local baseDeg = vortex.spinAngle + a * (360 / numArms)
        local dir = (vortex.angularVel >= 0) and 1 or -1
        local r1 = math.rad(baseDeg)
        local r2 = math.rad(baseDeg + dir * 45)
        local x1 = cx + math.cos(r1) * 11
        local y1 = cy + math.sin(r1) * 11
        local x2 = cx + math.cos(r2) * armRadius
        local y2 = cy + math.sin(r2) * armRadius
        gfx.drawLine(x1, y1, x2, y2)
        gfx.fillCircleAtPoint(x2, y2, 2)
    end
end

-- Draw top and bottom HUD bars
local function drawHUD()
    if not showHUD then return end

    -- Top Status Bar
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, SCREEN_W, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, 18, SCREEN_W, 18)

    local hdr = string.format("*SMOKE SIM*  |  Puffs: %d  |  Center: (%d,%d)", #particles, math.floor(vortex.x), math.floor(vortex.y))
    gfx.drawText(hdr, 6, 2)

    -- Bottom Controls Bar
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, SCREEN_H - 18, SCREEN_W, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, SCREEN_H - 18, SCREEN_W, SCREEN_H - 18)

    gfx.drawText("A/B: Disperse Smoke   Crank: Spin/Whirl   D-Pad: Move Center", 6, SCREEN_H - 15)
end

local function setupMenu()
    local menu = playdate.getSystemMenu()
    menu:removeAllMenuItems()

    menu:addOptionsMenuItem("Style", STYLES, STYLES[styleIndex], function(selected)
        for i, name in ipairs(STYLES) do
            if name == selected then
                styleIndex = i
                break
            end
        end
    end)

    menu:addCheckmarkMenuItem("Auto Smoke", autoEmbers, function(val)
        autoEmbers = val
    end)

    menu:addCheckmarkMenuItem("Show HUD", showHUD, function(val)
        showHUD = val
    end)

    menu:addMenuItem("Clear Smoke", function()
        particles = {}
    end)
end

local function init()
    math.randomseed(playdate.getSecondsSinceEpoch())
    setupMenu()
    -- Disperse an initial welcoming burst of smoke from the bottom
    disperseRandomBottomSmoke("WIDE", 22)
end

init()

function playdate.update()
    local dt = 1.0 / 30.0
    simTime = simTime + dt

    updateControls(dt)
    updateSmokePhysics(dt)

    local isNight = (STYLES[styleIndex] == "Night Mist")
    gfx.clear(isNight and gfx.kColorBlack or gfx.kColorWhite)

    drawSmoke()
    drawVortexCenter()
    drawHUD()

    playdate.timer.updateTimers()
end
