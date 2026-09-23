local _, Topline = ...

Topline:RegisterModule("Durability", {
    order = 50,
    tooltip = function(self, tip)
        tip:AddLine("Equipped durability", 1, 0.82, 0)
        Topline:TooltipRow(tip, "Overall", self.text)
        if not GetInventoryItemDurability then return end
        for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
            local current, maximum = GetInventoryItemDurability(slot)
            if type(current) == "number" and type(maximum) == "number" and maximum > 0 then
                local name = GetInventoryItemLink and GetInventoryItemLink("player", slot)
                Topline:TooltipRow(tip, name or "Slot " .. slot,
                    string.format("%d / %d (%d%%)", current, maximum, math.floor(current / maximum * 100 + 0.5)))
            end
        end
        tip:AddLine("Overall percentage uses total current / maximum durability.", 0.65, 0.65, 0.65, true)
    end,
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
