local gfx = playdate.graphics

Particles = {}
local activeParticles = {}

function Particles.reset()
    activeParticles = {}
end

function Particles.spawn(x, y, type)
    if #activeParticles > 50 then return end -- Limit count
    
    local p = {
        x = x,
        y = y,
        type = type,
        life = 1.0, -- 0.0 to 1.0
        vx = 0,
        vy = 0,
        size = 0
    }
    
    if type == "bubble" then
        p.vx = math.random(-10, 10) / 10.0
        p.vy = -math.random(10, 30) / 10.0
        p.size = math.random(2, 4)
        p.decay = 0.02
    elseif type == "explosion" then
        p.angle = math.random() * math.pi * 2
        local speed = math.random(20, 50) / 10.0
        p.vx = math.cos(p.angle) * speed
        p.vy = math.sin(p.angle) * speed
        p.size = math.random(3, 6)
        p.decay = 0.05
    elseif type == "sparkle" then
        p.vx = math.random(-5, 5) / 10.0
        p.vy = math.random(-5, 5) / 10.0
        p.size = 2
        p.decay = 0.03
    end
    
    table.insert(activeParticles, p)
end

function Particles.update()
    for i = #activeParticles, 1, -1 do
        local p = activeParticles[i]
        p.x += p.vx
        p.y += p.vy
        p.life -= p.decay
        
        if p.type == "bubble" then
            p.vx += math.random(-1, 1) * 0.1 -- Jitter
        end
        
        if p.life <= 0 then
            table.remove(activeParticles, i)
        end
    end
end

function Particles.draw()
    gfx.setColor(gfx.kColorBlack) -- Inverted depending on bg? Let's check main.
    -- Assuming white background mostly, so black particles.
    -- Actually main clears to white.
    
    for _, p in ipairs(activeParticles) do
        if p.type == "bubble" then
            local r = p.size * p.life
            gfx.drawEllipseInRect(p.x - r, p.y - r, r*2, r*2)
        elseif p.type == "explosion" then
            -- Dithered circle or pattern?
            if p.life > 0.5 then
                local r = p.size * p.life
                gfx.fillEllipseInRect(p.x - r, p.y - r, r*2, r*2)
            else
                local r = p.size * p.life
                gfx.drawEllipseInRect(p.x - r, p.y - r, r*2, r*2)
            end
        elseif p.type == "sparkle" then
             local s = p.size * (math.sin(playdate.getCurrentTimeMilliseconds()/50)+2)
             gfx.drawLine(p.x - s, p.y, p.x + s, p.y)
             gfx.drawLine(p.x, p.y - s, p.x, p.y + s)
        end
    end
end
