class('Fish').extends()

function Fish:init(level)
    self.level = level
    -- Weight is based on level
    self.weight = math.random(level * 2, level * 5) + (math.random() * 0.9)
    self.weight = math.floor(self.weight * 10) / 10 -- Round to 1 decimal
    
    self.strength = math.random(level, math.floor(level * 1.5))
    self.stamina = 100
    self.isPulling = false
    self.actionTimer = 0
end

function Fish:update()
    self.actionTimer = self.actionTimer - 1
    
    if self.actionTimer <= 0 then
        -- Switch state
        if self.isPulling then
            self.isPulling = false
            self.actionTimer = math.random(30, 90) -- Rest for 1-3 sec
        else
            self.isPulling = true
            self.actionTimer = math.random(30, 60) -- Pull for 1-2 sec
        end
    end
end
