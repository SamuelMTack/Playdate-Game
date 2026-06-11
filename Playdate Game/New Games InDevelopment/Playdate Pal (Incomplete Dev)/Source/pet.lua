local pd = playdate
local gfx = pd.graphics

Pet = {}
Pet.__index = Pet

function Pet.new()
    local self = setmetatable({}, Pet)
    
    -- Default/Initial State
    self.stats = {
        hunger = 100,     -- 0 = Starving, 100 = Full
        energy = 100,     -- 0 = Exhausted, 100 = Energetic
        happiness = 100,  -- 0 = Depressed, 100 = Happy
        hygiene = 100     -- 0 = Filthy, 100 = Clean
    }
    
    self.isSleeping = false
    self.hasPoop = false
    
    self.lastLogin = pd.getSecondsSinceEpoch()
    
    self.timestamp = pd.getSecondsSinceEpoch() -- Current session tracker
    
    return self
end

function Pet:loadData()
    local data = pd.datastore.read()
    if data then
        self.stats = data.stats or self.stats
        self.isSleeping = data.isSleeping or false
        self.hasPoop = data.hasPoop or false
        self.lastLogin = data.lastLogin or pd.getSecondsSinceEpoch()
        
        -- Calculate Time Skip
        local now = pd.getSecondsSinceEpoch()
        local delta = now - self.lastLogin
        
        if delta > 0 then
            self:processTimeSkip(delta)
        end
    else
        print("No save data found. Starting fresh.")
    end
end

function Pet:saveData()
    local data = {
        stats = self.stats,
        isSleeping = self.isSleeping,
        hasPoop = self.hasPoop,
        lastLogin = pd.getSecondsSinceEpoch()
    }
    pd.datastore.write(data)
    print("Game Saved.")
end

function Pet:processTimeSkip(seconds)
    print("Processing Time Skip: " .. seconds .. " seconds")
    
    -- Decay Rates per hour (3600s)
    -- Hunger: -10/hr
    -- Energy: -5/hr (if awake), +10/hr (if asleep)
    -- Happiness: -5/hr
    
    local hours = seconds / 3600
    
    self.stats.hunger = math.max(0, self.stats.hunger - (10 * hours))
    self.stats.happiness = math.max(0, self.stats.happiness - (5 * hours))
    
    if self.isSleeping then
        self.stats.energy = math.min(100, self.stats.energy + (10 * hours))
        -- Wake up if fully rested?
        if self.stats.energy >= 100 then
            self.isSleeping = false
        end
    else
        self.stats.energy = math.max(0, self.stats.energy - (5 * hours))
        -- Fall asleep if exhausted?
        if self.stats.energy <= 0 then
            self.isSleeping = true
        end
    end
    
    -- Poop logic: Chance to poop over time
    if not self.hasPoop and hours > 2 then
        self.hasPoop = true
        -- Determine Hygiene loss
        self.stats.hygiene = math.max(0, self.stats.hygiene - (20 * (hours - 2)))
    end
end

function Pet:update(dt)
    -- Realtime Decay (slower than offline potentially, or strictly time based)
    -- Let's just tick every second roughly
    -- dt is usually very small (0.033s)
    
    -- Accumulate time? rely on system time diff for robustness
    local now = pd.getSecondsSinceEpoch()
    local diff = now - self.timestamp
    
    if diff >= 1 then
        self.timestamp = now
        -- 1 Second update
        -- Decay very slowly
        -- 1/3600 * rate
        
        if not self.isSleeping then
            self.stats.hunger = math.max(0, self.stats.hunger - (10/3600))
            self.stats.energy = math.max(0, self.stats.energy - (5/3600))
            self.stats.happiness = math.max(0, self.stats.happiness - (5/3600))
        else
            self.stats.energy = math.min(100, self.stats.energy + (100/3600)) -- Sleep is fast recovery
        end
        
        if self.hasPoop then
            self.stats.hygiene = math.max(0, self.stats.hygiene - (50/3600))
        end
    end
end

-- Actions
function Pet:feed()
    if self.isSleeping then return end
    self.stats.hunger = math.min(100, self.stats.hunger + 20)
    -- Chance to poop immediately if full?
end

function Pet:play()
    if self.isSleeping then return end
    self.stats.happiness = math.min(100, self.stats.happiness + 15)
    self.stats.energy = math.max(0, self.stats.energy - 10)
end

function Pet:clean()
    if self.hasPoop then
        self.hasPoop = false
        self.stats.hygiene = 100
        self.stats.happiness = math.min(100, self.stats.happiness + 5)
    end
end

function Pet:toggleSleep()
    self.isSleeping = not self.isSleeping
end

function Pet:draw()
    local x, y = 200, 120
    
    -- Draw Poop
    if self.hasPoop then
        gfx.fillRect(x + 30, y + 20, 10, 10) -- Box Poop
    end
    
    -- Draw Pet
    if self.isSleeping then
        gfx.drawText("Zzz...", x + 20, y - 20)
        -- Sleeping Sprite (Eyes closed)
        gfx.fillCircleAtPoint(x, y, 20)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(x-10, y, x-5, y) -- Closed Eye L
        gfx.drawLine(x+5, y, x+10, y) -- Closed Eye R
    else
        -- Awake Sprite
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(x, y, 20)
        gfx.setColor(gfx.kColorWhite)
        
        if self.stats.happiness < 40 then
             -- Sad Face
             gfx.fillCircleAtPoint(x-7, y-5, 2) -- Eye
             gfx.fillCircleAtPoint(x+7, y-5, 2) -- Eye
             gfx.drawLine(x-5, y+10, x+5, y+10) -- Flat mouth
        else
             -- Happy Face
             gfx.fillCircleAtPoint(x-7, y-5, 3) -- Eye
             gfx.fillCircleAtPoint(x+7, y-5, 3) -- Eye
             gfx.drawArc(x, y, 10, 45, 135) -- Smile
        end
    end
    
    gfx.setColor(gfx.kColorBlack)
end
