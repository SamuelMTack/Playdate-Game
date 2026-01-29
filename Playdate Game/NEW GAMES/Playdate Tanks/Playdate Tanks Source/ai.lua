
AI = {}

function AI.turn(tank, targetTank)
    -- Simple AI: Aim at the target
    -- Calculate angle to target
    local dx = targetTank.x - tank.x
    local dy = targetTank.y - tank.y -- Note: Y is flipped in rendering but math works if consistent
    
    -- Heuristic: Power is roughly distance / 4
    local dist = math.abs(dx)
    local targetPower = math.min(100, math.max(10, dist / 4))
    
    -- Heuristic: Angle
    local targetAngle = 45
    if dx < 0 then targetAngle = 135 end
    
    -- Add some randomness (error)
    local error = math.random(-5, 5)
    
    tank.angle = targetAngle + (math.random() * 4 - 2)
    tank.power = targetPower + error
    
    return true -- Ready to fire
end
