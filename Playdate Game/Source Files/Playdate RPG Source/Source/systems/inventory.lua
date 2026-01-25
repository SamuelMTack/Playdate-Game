Inventory = {}

-- Store counts of specific modifiers
Inventory.modifiers = {
    [1] = 0, -- Count of +1 items
    [2] = 0, -- Count of +2 items
    [3] = 0  -- Count of +3 items
}

Inventory.items = {}

function Inventory.addModifier(value)
    if value >= 1 and value <= 3 then
        Inventory.modifiers[value] = Inventory.modifiers[value] + 1
        print("Added +" .. value .. " Modifier (Total: " .. Inventory.modifiers[value] .. ")")
    end
end

function Inventory.useModifier(value)
    if Inventory.modifiers[value] > 0 then
        Inventory.modifiers[value] = Inventory.modifiers[value] - 1
        return value
    end
    return 0
end

function Inventory.addItem(itemName, count)
    count = count or 1
    if Inventory.items[itemName] then
        Inventory.items[itemName] = Inventory.items[itemName] + count
    else
        Inventory.items[itemName] = count
    end
    print("Added " .. count .. " " .. itemName)
end
