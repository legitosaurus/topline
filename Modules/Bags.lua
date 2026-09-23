local _, Topline = ...
-- Explicitly exclude the separate reagent bag, keyring, and every bank index.
local indexes = Enum and Enum.BagIndex or {}
local bags = {
    indexes.Backpack or 0, indexes.Bag_1 or 1, indexes.Bag_2 or 2,
    indexes.Bag_3 or 3, indexes.Bag_4 or 4,
}

Topline:RegisterModule("Bags", {
    order = 40,
    events = { "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED" },
    update = function()
        if not (C_Container and C_Container.GetContainerNumSlots
            and C_Container.GetContainerNumFreeSlots) then
            return "Bags: N/A"
        end
        local used, total = 0, 0
        for _, bagID in ipairs(bags) do
            local slots = C_Container.GetContainerNumSlots(bagID)
            if type(slots) ~= "number" or slots < 0 then return "Bags: N/A" end
            if slots > 0 then
                local free = C_Container.GetContainerNumFreeSlots(bagID)
                if type(free) ~= "number" or free < 0 or free > slots then
                    return "Bags: N/A"
                end
                total = total + slots
                used = used + slots - free
            end
        end
        return string.format("Bags: %d/%d", used, total)
    end,
})
