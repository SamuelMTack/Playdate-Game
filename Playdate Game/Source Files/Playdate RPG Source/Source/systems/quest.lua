Quest = {}

Quest.TYPES = {
    KILL = 1,
    VISIT = 2
}

Quest.activeQuests = {}
-- Example Quest Data Structure
-- { id="q1", type=KILL, target="Pixel Monster", count=3, current=0, desc="Hunt 3 Monsters", reward=1 }

function Quest.addQuest(id, qType, target, count, desc, reward)
    table.insert(Quest.activeQuests, {
        id = id,
        type = qType,
        target = target,
        required = count,
        current = 0,
        desc = desc,
        reward = reward,
        completed = false
    })
    print("New Quest: " .. desc)
end

function Quest.updateProgress(qType, target, amount)
    for _, q in ipairs(Quest.activeQuests) do
        if not q.completed and q.type == qType and q.target == target then
            q.current = q.current + amount
            print("Quest Progress: " .. q.desc .. " (" .. q.current .. "/" .. q.required .. ")")
            
            if q.current >= q.required then
                q.completed = true
                print("QUEST COMPLETED: " .. q.desc)
                -- Give Reward
                -- Assumes Inventory is Global now via previous edit
                if Inventory then Inventory.addModifier(q.reward or 1) end
            end
        end
    end
end

-- Initialize with a starter quest
Quest.addQuest("starter_kill", Quest.TYPES.KILL, "Pixel Monster", 3, "Slay 3 Pixel Monsters", 2)

function Quest.assignFromLocation(locationName)
    -- Check if we already have a quest from here or similar
    -- Simplified: Random quest generation
    local rnd = math.random(1, 100)
    local id = "loc_q_" .. math.random(1000, 9999)
    
    if locationName == "Castle" then
        Quest.addQuest(id, Quest.TYPES.KILL, "Pixel Monster", 5, "King's Order: Slay 5 Beasts", 3)
        return "King's Order: Slay 5 Beasts"
    elseif locationName == "Village" then
        Quest.addQuest(id, Quest.TYPES.VISIT, "Cave", 1, "Villager: Scout the Cave", 1)
        return "Villager: Scout the Cave"
    end
    return nil
end
