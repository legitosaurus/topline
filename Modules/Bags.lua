local _, Topline = ...
-- Explicitly exclude the separate reagent bag, keyring, and every bank index.
local indexes = Enum and Enum.BagIndex or {}
local bags = {
    indexes.Backpack or 0, indexes.Bag_1 or 1, indexes.Bag_2 or 2,
    indexes.Bag_3 or 3, indexes.Bag_4 or 4,
}

local function Warning(text, free)
    if free == 0 then return "|cffd98279" .. text .. "|r" end
    if free <= 5 then return "|cffd6b369" .. text .. "|r" end
    return text
end

local function ReadBag(bagID)
    local slots = C_Container.GetContainerNumSlots(bagID)
    if type(slots) ~= "number" or slots < 0 then return end
    if slots == 0 then return 0, 0 end
    local free = C_Container.GetContainerNumFreeSlots(bagID)
    if type(free) ~= "number" or free < 0 or free > slots then return end
    return slots, free
end

Topline:RegisterModule("Bags", {
    order = 40,
    tooltip = function(self, tip)
        tip:AddLine("Inventory bags", 1, 0.82, 0)
        if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumFreeSlots) then
            tip:AddLine("Bag information unavailable."); return
        end
        local total, freeTotal = 0, 0
        for _, bagID in ipairs(bags) do
            local slots, free = ReadBag(bagID)
            if not slots then tip:AddLine("Bag information unavailable."); return end
            total, freeTotal = total + slots, freeTotal + free
        end
        Topline:TooltipRow(tip, "Free slots", total > 0 and Warning(tostring(freeTotal), freeTotal) or "N/A")
        Topline:TooltipRow(tip, "Used / total slots", string.format("%d / %d", total - freeTotal, total))
        if total > 0 and freeTotal <= 5 then
            tip:AddLine(Warning(freeTotal == 0 and "Bags are full." or "Bag space is running low.", freeTotal))
        end
        tip:AddLine(" ")
        for index, bagID in ipairs(bags) do
            local slots, free = ReadBag(bagID)
            if slots and slots > 0 then
                local detail = string.format("%d free - %d / %d used", free, slots - free, slots)
                Topline:TooltipRow(tip, index == 1 and "Backpack" or "Bag " .. (index - 1), Warning(detail, free))
            end
        end
        tip:AddLine("Normal inventory bags only. Specialty slots may restrict items.", 0.65, 0.65, 0.65, true)
    end,
    events = { "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED" },
    update = function()
        if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumFreeSlots) then
            return "Bags: N/A"
        end
        local used, total = 0, 0
        for _, bagID in ipairs(bags) do
            local slots, free = ReadBag(bagID)
            if not slots then return "Bags: N/A" end
            total, used = total + slots, used + slots - free
        end
        local text = string.format("Bags: %d/%d", used, total)
        return total > 0 and Warning(text, total - used) or text
    end,
})
