local _, Topline = ...
local slotNames = { "Head", "Neck", "Shoulders", "Shirt", "Chest", "Waist", "Legs", "Feet",
    "Wrists", "Hands", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2", "Back", "Main hand", "Off hand", "Ranged", "Tabard" }

local function Warning(text, percent)
    if percent < 10 then return "|cffd98279" .. text .. "|r" end
    if percent < 30 then return "|cffd6b369" .. text .. "|r" end
    return text
end

Topline:RegisterModule("Durability", {
    order = 50,
    tooltip = function(self, tip)
        tip:AddLine("Equipped durability", 1, 0.82, 0)
        Topline:TooltipRow(tip, "Overall", self.text)
        if not GetInventoryItemDurability then return end
        local damaged, broken, lowest = 0, 0, 100
        for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
            local current, maximum = GetInventoryItemDurability(slot)
            if type(current) == "number" and type(maximum) == "number" and maximum > 0 then
                current = math.max(0, math.min(current, maximum))
                local percent = current / maximum * 100
                if current < maximum then damaged = damaged + 1 end
                if current == 0 then broken = broken + 1 end
                lowest = math.min(lowest, percent)
                local status = current == 0 and " - broken" or current < maximum and " - damaged" or ""
                local name = GetInventoryItemLink and GetInventoryItemLink("player", slot)
                Topline:TooltipRow(tip, name or slotNames[slot] or "Slot " .. slot,
                    Warning(string.format("%d / %d (%d%%)%s", current, maximum, math.floor(percent + 0.5), status), percent))
            end
        end
        tip:AddLine(" ")
        Topline:TooltipRow(tip, "Items needing repair", Warning(tostring(damaged), lowest))
        Topline:TooltipRow(tip, "Broken items", broken > 0 and "|cffd98279" .. broken .. "|r" or "0")
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
        local percent = current / maximum * 100
        return Warning(string.format("Durability: %d%%", math.floor(percent + 0.5)), percent)
    end,
})
