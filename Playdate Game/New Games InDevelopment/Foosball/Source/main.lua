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

-- Pitch boundaries (centered on screen, with scoreboard panels on the left & right sides)
local PITCH_LEFT <const> = 80
local PITCH_RIGHT <const> = 320
local PITCH_TOP <const> = 14
local PITCH_BOTTOM <const> = 226
local PITCH_W <const> = PITCH_RIGHT - PITCH_LEFT
local PITCH_H <const> = PITCH_BOTTOM - PITCH_TOP
local PITCH_MID_X <const> = (PITCH_LEFT + PITCH_RIGHT) / 2
local PITCH_MID_Y <const> = (PITCH_TOP + PITCH_BOTTOM) / 2

local GOAL_W <const> = 84
local GOAL_LEFT <const> = PITCH_MID_X - GOAL_W / 2
local GOAL_RIGHT <const> = PITCH_MID_X + GOAL_W / 2

-- Sound synthesizers
local sfxKick = snd.synth.new(snd.kWaveTriangle)
sfxKick:setVolume(0.28)
sfxKick:setADSR(0.003, 0.06, 0.0, 0.04)

local sfxWall = snd.synth.new(snd.kWaveSine)
sfxWall:setVolume(0.18)
sfxWall:setADSR(0.002, 0.04, 0.0, 0.02)

local sfxWhistle = snd.synth.new(snd.kWaveSquare)
sfxWhistle:setVolume(0.22)
sfxWhistle:setADSR(0.01, 0.18, 0.1, 0.12)

-- Game State: "READY_TO_SERVE", "PLAYING", "GOAL_SCORED", "MATCH_OVER"
local state = "READY_TO_SERVE"
local playerScore = 0
local cpuScore = 0
local winningScore = 5
local lastScorer = "NONE"
local stateTimer = 0
local statusMessage = "PRESS A TO LAUNCH BALL"

-- Player & CPU paddle spin state
local playerSpinAngle = 0.0     -- Degrees (0..360)
local playerSpinVel = 0.0       -- Degrees per frame from Crank
local cpuSpinAngle = 0.0
local cpuSpinVel = 0.0
local aiDifficulty = 1.0        -- 0.7 (Easy), 1.0 (Normal), 1.35 (Pro)

-- Ball state
local ball = {
    x = PITCH_MID_X,
    y = PITCH_MID_Y,
    vx = 0,
    vy = 0,
    radius = 6,
    active = false,
    stuckTimer = 0
}

-- Foosball Rods (horizontal rods running Left-to-Right across the pitch)
-- Player defends the BOTTOM goal and shoots UP toward the TOP goal.
-- CPU defends the TOP goal and shoots DOWN toward the BOTTOM goal.
local rods = {}

local function createRods()
    rods = {
        -- CPU Goalie (Top)
        {
            isPlayer = false,
            y = PITCH_TOP + 20,
            count = 1,
            spacing = 0,
            offset = 0,
            maxOffset = 46,
            paddleW = 14
        },
        -- CPU Defenders
        {
            isPlayer = false,
            y = PITCH_TOP + 50,
            count = 2,
            spacing = 86,
            offset = 0,
            maxOffset = 58,
            paddleW = 13
        },
        -- Player Strikers (Attacking Top Goal)
        {
            isPlayer = true,
            y = PITCH_TOP + 82,
            count = 3,
            spacing = 68,
            offset = 0,
            maxOffset = 36,
            paddleW = 13
        },
        -- CPU Midfielders
        {
            isPlayer = false,
            y = PITCH_MID_Y + 6,
            count = 3,
            spacing = 68,
            offset = 0,
            maxOffset = 36,
            paddleW = 13
        },
        -- Player Defenders
        {
            isPlayer = true,
            y = PITCH_BOTTOM - 52,
            count = 2,
            spacing = 86,
            offset = 0,
            maxOffset = 58,
            paddleW = 13
        },
        -- Player Goalie (Bottom)
        {
            isPlayer = true,
            y = PITCH_BOTTOM - 20,
            count = 1,
            spacing = 0,
            offset = 0,
            maxOffset = 46,
            paddleW = 15
        }
    }
end

-- Return the X positions of each foosball figure/paddle on a given rod
local function getRodPlayerPositions(rod)
    local positions = {}
    local totalSpan = (rod.count - 1) * rod.spacing
    local startX = PITCH_MID_X - totalSpan / 2 + rod.offset
    for i = 0, rod.count - 1 do
        positions[#positions + 1] = startX + i * rod.spacing
    end
    return positions
end

-- Launch / Serve the ball from the center chute when A is pressed
local function launchBall()
    state = "PLAYING"
    ball.active = true
    ball.x = PITCH_LEFT + 18
    ball.y = PITCH_MID_Y
    -- Serve toward center with slight random vertical angle
    ball.vx = math.random(120, 165)
    ball.vy = (math.random(0, 1) == 1 and 1 or -1) * math.random(45, 95)
    ball.stuckTimer = 0
    sfxWhistle:playNote(523.25, 0.22, 0.12)
end

local function resetMatch()
    playerScore = 0
    cpuScore = 0
    state = "READY_TO_SERVE"
    statusMessage = "PRESS A TO LAUNCH BALL"
    ball.active = false
    ball.x = PITCH_MID_X
    ball.y = PITCH_MID_Y
    ball.vx = 0
    ball.vy = 0
    createRods()
end

-- Handle sliding Player rods with Left / Right buttons and spinning paddles with the Crank
local function updatePlayerInput(dt)
    local slideSpeed = 165.0 * dt
    local slideDelta = 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        slideDelta = -slideSpeed
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        slideDelta = slideSpeed
    end

    if slideDelta ~= 0 then
        for _, rod in ipairs(rods) do
            if rod.isPlayer then
                rod.offset = math.max(-rod.maxOffset, math.min(rod.maxOffset, rod.offset + slideDelta))
            end
        end
    end

    -- Crank spins the Foosball paddles!
    local crankChange, acceleratedChange = playdate.getCrankChange()
    if math.abs(crankChange) > 0.01 then
        playerSpinVel = acceleratedChange
        playerSpinAngle = (playerSpinAngle + acceleratedChange) % 360
    else
        -- Damped spin coasting when you let go of a fast crank spin
        playerSpinVel = playerSpinVel * 0.82
        if math.abs(playerSpinVel) < 0.2 then
            playerSpinVel = 0
        end
        playerSpinAngle = (playerSpinAngle + playerSpinVel) % 360
    end

    -- Also allow Up/Down D-pad to swing paddles if the user isn't touching the crank
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        playerSpinVel = 16
        playerSpinAngle = (playerSpinAngle + 16) % 360
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        playerSpinVel = -16
        playerSpinAngle = (playerSpinAngle - 16) % 360
    end
end

-- Update CPU rods sliding and paddle spinning
local function updateCPU(dt)
    if state ~= "PLAYING" then return end

    local cpuSlideSpeed = 115.0 * aiDifficulty * dt

    for _, rod in ipairs(rods) do
        if not rod.isPlayer then
            -- Find closest figure on this rod to the ball's X position
            local positions = getRodPlayerPositions(rod)
            local bestDiff = 9999
            for _, px in ipairs(positions) do
                local diff = ball.x - px
                if math.abs(diff) < math.abs(bestDiff) then
                    bestDiff = diff
                end
            end

            if math.abs(bestDiff) > 4 then
                local move = (bestDiff > 0 and 1 or -1) * math.min(math.abs(bestDiff), cpuSlideSpeed)
                rod.offset = math.max(-rod.maxOffset, math.min(rod.maxOffset, rod.offset + move))
            end

            -- If ball is close to a CPU rod, CPU spins its paddles to kick downward
            if math.abs(ball.y - rod.y) < 18 then
                cpuSpinVel = -18 * aiDifficulty
            end
        end
    end

    cpuSpinVel = cpuSpinVel * 0.85
    if math.abs(cpuSpinVel) < 1.5 then
        -- Gently return CPU paddles toward neutral vertical stance (0 degrees)
        local diff = (0 - cpuSpinAngle)
        if diff < -180 then diff = diff + 360 end
        if diff > 180 then diff = diff - 360 end
        cpuSpinAngle = (cpuSpinAngle + diff * 0.15) % 360
    else
        cpuSpinAngle = (cpuSpinAngle + cpuSpinVel) % 360
    end
end

-- Check and resolve collisions between the ball and all foosball paddles
local function checkPaddleCollisions()
    for _, rod in ipairs(rods) do
        local spinAngle = rod.isPlayer and playerSpinAngle or cpuSpinAngle
        local spinVel = rod.isPlayer and playerSpinVel or cpuSpinVel
        local rad = math.rad(spinAngle)

        -- Paddle swing offset: sin(rad) swings the foot up/down around the rod (-14 to +14 px)
        -- cos(rad) represents how low into the pitch the paddle foot reaches (1 = straight down, -1 = upside down above the ball!)
        local swingY = -math.sin(rad) * 13
        local reachIntoTable = math.cos(rad)

        -- When the paddle is raised high overhead (reachIntoTable < -0.35) and not spinning fast, the ball can roll underneath!
        local paddleActive = (reachIntoTable >= -0.35) or (math.abs(spinVel) > 6.0)

        if paddleActive then
            local paddleY = rod.y + swingY
            local dy = ball.y - paddleY

            if math.abs(dy) <= (ball.radius + 5) then
                local positions = getRodPlayerPositions(rod)
                local halfW = rod.paddleW / 2 + ball.radius

                for _, px in ipairs(positions) do
                    local dx = ball.x - px
                    if math.abs(dx) <= halfW then
                        -- Collision with foosball paddle!
                        local kickPower = spinVel * 11.5

                        if math.abs(spinVel) > 3.5 then
                            -- Active spinning kick! Positive crank spin kicks UP toward CPU goal; negative kicks DOWN
                            ball.vy = -kickPower
                            -- Add directional angle based on which edge of the paddle foot struck the ball
                            ball.vx = ball.vx * 0.6 + (dx / halfW) * 145 + math.random(-20, 20)
                            sfxKick:playNote(340 + math.min(200, math.abs(spinVel) * 6), 0.3, 0.06)
                        else
                            -- Stationary or slow paddle block / bounce
                            if dy < 0 then
                                ball.y = paddleY - (ball.radius + 5)
                                ball.vy = -math.abs(ball.vy) * 0.85 - 25
                            else
                                ball.y = paddleY + (ball.radius + 5)
                                ball.vy = math.abs(ball.vy) * 0.85 + 25
                            end
                            ball.vx = ball.vx + (dx / halfW) * 85
                            sfxWall:playNote(240, 0.2, 0.04)
                        end

                        -- Push ball slightly clear of the paddle to prevent double-hit in the same frame
                        if ball.vy < 0 then
                            ball.y = math.min(ball.y, paddleY - ball.radius - 4)
                        else
                            ball.y = math.max(ball.y, paddleY + ball.radius + 4)
                        end

                        -- Clamp maximum ball speed so physics stays crisp
                        local maxSpd = 340
                        local spd = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
                        if spd > maxSpd then
                            ball.vx = (ball.vx / spd) * maxSpd
                            ball.vy = (ball.vy / spd) * maxSpd
                        end
                        return
                    end
                end
            end
        end
    end
end

local function onGoalScored(scorer)
    state = "GOAL_SCORED"
    stateTimer = 0
    ball.active = false
    lastScorer = scorer

    if scorer == "PLAYER" then
        playerScore = playerScore + 1
        statusMessage = "GOAL!! YOU SCORED!"
        sfxWhistle:playNote(659.25, 0.28, 0.2)
    else
        cpuScore = cpuScore + 1
        statusMessage = "CPU SCORED!"
        sfxWhistle:playNote(293.66, 0.28, 0.2)
    end

    if playerScore >= winningScore or cpuScore >= winningScore then
        state = "MATCH_OVER"
        if playerScore >= winningScore then
            statusMessage = "YOU WIN THE MATCH!"
        else
            statusMessage = "CPU WINS THE MATCH!"
        end
    end
end

local function updateBall(dt)
    if state ~= "PLAYING" or not ball.active then return end

    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Slight table friction so ball doesn't stay at maximum velocity forever, but keeps moving
    ball.vx = ball.vx * 0.996
    ball.vy = ball.vy * 0.996

    -- Angled table corners (classic foosball ramped corners so the ball never gets trapped in corners)
    local cornerSize = 22
    if ball.x < PITCH_LEFT + cornerSize and (ball.y < PITCH_TOP + cornerSize or ball.y > PITCH_BOTTOM - cornerSize) then
        ball.vx = ball.vx + 180 * dt
    elseif ball.x > PITCH_RIGHT - cornerSize and (ball.y < PITCH_TOP + cornerSize or ball.y > PITCH_BOTTOM - cornerSize) then
        ball.vx = ball.vx - 180 * dt
    end

    -- Left and Right side wall bounces
    if ball.x - ball.radius < PITCH_LEFT then
        ball.x = PITCH_LEFT + ball.radius
        ball.vx = math.abs(ball.vx) * 0.92
        sfxWall:playNote(190, 0.15, 0.03)
    elseif ball.x + ball.radius > PITCH_RIGHT then
        ball.x = PITCH_RIGHT - ball.radius
        ball.vx = -math.abs(ball.vx) * 0.92
        sfxWall:playNote(190, 0.15, 0.03)
    end

    -- Top wall & Top Goal (CPU Goal -> Player scores!)
    if ball.y - ball.radius < PITCH_TOP then
        if ball.x >= GOAL_LEFT and ball.x <= GOAL_RIGHT then
            onGoalScored("PLAYER")
            return
        else
            ball.y = PITCH_TOP + ball.radius
            ball.vy = math.abs(ball.vy) * 0.92
            sfxWall:playNote(210, 0.15, 0.03)
        end
    end

    -- Bottom wall & Bottom Goal (Player Goal -> CPU scores!)
    if ball.y + ball.radius > PITCH_BOTTOM then
        if ball.x >= GOAL_LEFT and ball.x <= GOAL_RIGHT then
            onGoalScored("CPU")
            return
        else
            ball.y = PITCH_BOTTOM - ball.radius
            ball.vy = -math.abs(ball.vy) * 0.92
            sfxWall:playNote(210, 0.15, 0.03)
        end
    end

    -- Check collisions against all foosball rods/paddles
    checkPaddleCollisions()

    -- Prevent dead-ball stalls: if ball slows to near stop out of reach, gently nudge it toward center
    local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
    if speed < 24 then
        ball.stuckTimer = ball.stuckTimer + dt
        if ball.stuckTimer > 1.2 then
            ball.vx = (PITCH_MID_X - ball.x) * 0.8 + math.random(-50, 50)
            ball.vy = (math.random(0, 1) == 1 and 1 or -1) * 75
            ball.stuckTimer = 0
        end
    else
        ball.stuckTimer = 0
    end
end

-- Draw the Foosball Table, Goals, Center Circle, and Corner Ramps
local function drawTable()
    gfx.setColor(gfx.kColorBlack)

    -- Outer table border
    gfx.setLineWidth(3)
    gfx.drawRect(PITCH_LEFT, PITCH_TOP, PITCH_W, PITCH_H)

    -- Top Goal Box (CPU Goal)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(GOAL_LEFT + 2, 2, GOAL_W - 4, PITCH_TOP + 2)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawRect(GOAL_LEFT, 2, GOAL_W, PITCH_TOP - 1)
    -- Penalty box top
    gfx.setLineWidth(1)
    gfx.drawRect(PITCH_MID_X - 56, PITCH_TOP, 112, 28)

    -- Bottom Goal Box (Player Goal)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(GOAL_LEFT + 2, PITCH_BOTTOM - 2, GOAL_W - 4, SCREEN_H - PITCH_BOTTOM)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawRect(GOAL_LEFT, PITCH_BOTTOM - 1, GOAL_W, SCREEN_H - PITCH_BOTTOM - 1)
    -- Penalty box bottom
    gfx.setLineWidth(1)
    gfx.drawRect(PITCH_MID_X - 56, PITCH_BOTTOM - 28, 112, 28)

    -- Corner ramps
    local c = 18
    gfx.drawLine(PITCH_LEFT, PITCH_TOP + c, PITCH_LEFT + c, PITCH_TOP)
    gfx.drawLine(PITCH_RIGHT - c, PITCH_TOP, PITCH_RIGHT, PITCH_TOP + c)
    gfx.drawLine(PITCH_LEFT, PITCH_BOTTOM - c, PITCH_LEFT + c, PITCH_BOTTOM)
    gfx.drawLine(PITCH_RIGHT - c, PITCH_BOTTOM, PITCH_RIGHT, PITCH_BOTTOM - c)

    -- Midfield line & center circle
    gfx.drawLine(PITCH_LEFT, PITCH_MID_Y, PITCH_RIGHT, PITCH_MID_Y)
    gfx.drawCircleAtPoint(PITCH_MID_X, PITCH_MID_Y, 24)
    gfx.fillCircleAtPoint(PITCH_MID_X, PITCH_MID_Y, 3)

    -- Side ball serve chute hole on the left wall
    gfx.fillCircleAtPoint(PITCH_LEFT, PITCH_MID_Y, 5)
end

-- Draw all 6 Foosball Rods and spinning Paddles/Players
local function drawRodsAndPaddles()
    for _, rod in ipairs(rods) do
        local y = rod.y
        local spinAngle = rod.isPlayer and playerSpinAngle or cpuSpinAngle
        local rad = math.rad(spinAngle)
        local swingY = -math.sin(rad) * 13

        -- Metal rod spanning across the table, with external handle on Player/CPU side
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawLine(PITCH_LEFT - 12, y, PITCH_RIGHT + 12, y)

        -- Wooden handle on the right side for Player rods, left side for CPU rods
        if rod.isPlayer then
            gfx.fillRoundRect(PITCH_RIGHT + 10, y - 4, 16, 8, 2)
        else
            gfx.fillRoundRect(PITCH_LEFT - 26, y - 4, 16, 8, 2)
        end

        -- Rubber bumpers on the rod ends
        local positions = getRodPlayerPositions(rod)
        for _, px in ipairs(positions) do
            local hw = rod.paddleW / 2

            -- Draw the spinning paddle blade / foot extending from the rod by swingY
            local footY = y + swingY
            local topY = math.min(y, footY)
            local boxH = math.max(4, math.abs(swingY) + 4)

            if rod.isPlayer then
                -- Player figures: solid black jersey with white trim & paddle foot
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(px - hw - 1, topY - 1, rod.paddleW + 2, boxH + 2)
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(px - hw, topY, rod.paddleW, boxH)
                -- Player head/shoulders mounted on the rod axis
                gfx.setColor(gfx.kColorWhite)
                gfx.fillCircleAtPoint(px, y, 5)
                gfx.setColor(gfx.kColorBlack)
                gfx.drawCircleAtPoint(px, y, 5)
                gfx.fillCircleAtPoint(px, y, 2)
            else
                -- CPU figures: white/striped jersey with black outline
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(px - hw, topY, rod.paddleW, boxH)
                gfx.setColor(gfx.kColorBlack)
                gfx.drawRect(px - hw, topY, rod.paddleW, boxH)
                gfx.drawLine(px, topY, px, topY + boxH)
                -- CPU head mounted on the rod axis
                gfx.fillCircleAtPoint(px, y, 5)
                gfx.setColor(gfx.kColorWhite)
                gfx.fillCircleAtPoint(px, y, 2)
            end
        end
    end
end

-- Draw the Foosball
local function drawBall()
    if not ball.active and state ~= "READY_TO_SERVE" then return end

    local bx = ball.active and ball.x or (PITCH_LEFT + 14)
    local by = ball.active and ball.y or PITCH_MID_Y

    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(bx, by, ball.radius)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawCircleAtPoint(bx, by, ball.radius)
    -- Classic soccer ball center pentagon dot
    gfx.fillCircleAtPoint(bx, by, 2)
end

-- Draw Side Panels (Scoreboard, Crank Paddle Angle Indicator, and Controls)
local function drawSidePanels()
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)

    -- Left Sidebar: Title & Scoreboard
    gfx.drawText("*FOOSBALL*", 4, 8)
    gfx.drawLine(4, 26, 68, 26)

    gfx.drawText("CPU", 6, 34)
    gfx.drawText(string.format("*%d*", cpuScore), 48, 34)

    gfx.drawText("YOU", 6, 56)
    gfx.drawText(string.format("*%d*", playerScore), 48, 56)

    gfx.drawLine(4, 76, 68, 76)
    gfx.drawText(string.format("First to %d", winningScore), 4, 82)

    -- Left Bottom: Quick Controls Guide
    gfx.drawText("*CONTROLS*", 4, 132)
    gfx.drawText("L/R: Slide", 4, 150)
    gfx.drawText("Crank: Spin", 4, 166)
    gfx.drawText("A: Launch", 4, 182)
    gfx.drawText("B: Nudge", 4, 198)

    -- Right Sidebar: Live 3D Paddle Spin Gauge
    local gaugeX = 362
    local gaugeY = 70
    local gaugeR = 24
    gfx.drawTextAligned("*PADDLE*", gaugeX, 16, kTextAlignment.center)
    gfx.drawTextAligned("*SPIN*", gaugeX, 30, kTextAlignment.center)

    gfx.drawCircleAtPoint(gaugeX, gaugeY, gaugeR)
    -- Draw paddle angle needle inside gauge
    local rad = math.rad(playerSpinAngle)
    local tipX = gaugeX + math.cos(rad) * (gaugeR - 3)
    local tipY = gaugeY - math.sin(rad) * (gaugeR - 3)
    gfx.setLineWidth(3)
    gfx.drawLine(gaugeX, gaugeY, tipX, tipY)
    gfx.fillCircleAtPoint(gaugeX, gaugeY, 3)
    gfx.setLineWidth(1)

    -- Slide Position Bar on Right Sidebar
    gfx.drawTextAligned("ROD SLIDE", gaugeX, 120, kTextAlignment.center)
    local barX = 336
    local barY = 140
    local barW = 52
    gfx.drawRect(barX, barY, barW, 10)
    -- Use the 3-bar striker rod offset to display relative slide position
    local strikerRod = rods[3]
    local normSlide = (strikerRod.offset + strikerRod.maxOffset) / (2 * strikerRod.maxOffset)
    local knobX = barX + 2 + math.floor(normSlide * (barW - 12))
    gfx.fillRect(knobX, barY + 2, 8, 6)

    -- Center Banner Popup when waiting to serve, after a goal, or match over
    if state ~= "PLAYING" then
        local boxW = 216
        local boxH = 54
        local boxX = PITCH_MID_X - boxW / 2
        local boxY = PITCH_MID_Y - boxH / 2

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(boxX, boxY, boxW, boxH, 6)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(2)
        gfx.drawRoundRect(boxX, boxY, boxW, boxH, 6)
        gfx.setLineWidth(1)

        gfx.drawTextAligned("*" .. statusMessage .. "*", PITCH_MID_X, boxY + 9, kTextAlignment.center)
        if state == "MATCH_OVER" then
            gfx.drawTextAligned("Press A for New Match", PITCH_MID_X, boxY + 30, kTextAlignment.center)
        else
            gfx.drawTextAligned("Press A to Launch Ball", PITCH_MID_X, boxY + 30, kTextAlignment.center)
        end
    end
end

local function setupMenu()
    local menu = playdate.getSystemMenu()
    menu:removeAllMenuItems()

    menu:addOptionsMenuItem("CPU Skill", { "Normal", "Easy", "Pro" }, "Normal", function(selected)
        if selected == "Easy" then
            aiDifficulty = 0.7
        elseif selected == "Pro" then
            aiDifficulty = 1.35
        else
            aiDifficulty = 1.0
        end
    end)

    menu:addOptionsMenuItem("Play To", { "5", "3", "7", "10" }, "5", function(selected)
        winningScore = tonumber(selected) or 5
    end)

    menu:addMenuItem("Reset Match", function()
        resetMatch()
    end)
end

local function init()
    math.randomseed(playdate.getSecondsSinceEpoch())
    createRods()
    setupMenu()
    resetMatch()
end

init()

function playdate.update()
    local dt = 1.0 / 30.0

    -- Always allow sliding the players Left/Right and spinning the paddles with the Crank
    updatePlayerInput(dt)

    if state == "READY_TO_SERVE" or state == "GOAL_SCORED" then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            launchBall()
        end
    elseif state == "MATCH_OVER" then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            resetMatch()
            launchBall()
        end
    elseif state == "PLAYING" then
        -- Pressing A while playing re-serves if ball ever slows down or launches a fresh ball if requested
        if playdate.buttonJustPressed(playdate.kButtonA) and not ball.active then
            launchBall()
        end
        -- Pressing B nudges the table slightly if the ball is moving slowly
        if playdate.buttonJustPressed(playdate.kButtonB) then
            ball.vy = ball.vy + (ball.vy >= 0 and 65 or -65)
            ball.vx = ball.vx + math.random(-55, 55)
            sfxWall:playNote(150, 0.2, 0.05)
        end

        updateCPU(dt)
        updateBall(dt)
    end

    -- Render frame
    gfx.clear(gfx.kColorWhite)
    drawTable()
    drawBall()
    drawRodsAndPaddles()
    drawSidePanels()

    playdate.timer.updateTimers()
end
