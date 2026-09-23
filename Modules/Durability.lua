local _, Topline = ...

Topline:RegisterModule("Durability", {
    order = 50,
    events = { "UPDATE_INVENTORY_DURABILITY", "PLAYER_EQUIPMENT_CHANGED", "MERCHANT_CLOSED" },
    update = function()
        if not GetInventoryItemDurability then return "Durability: N/A" end
        local current, maximum = 0, 0
        for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
            local value, cap = GetInventoryItemDurability(slot)
            if type(value) == "number" and type(cap) == "number" and cap > 0 then
                current = current + math.max(0, math.min(value, cap))
                maximum = maximum + cap
            end
        end
        if maximum == 0 then return "Durability: N/A" end
        return string.format("Durability: %d%%", math.floor(current / maximum * 100 + 0.5))
    end,
})
