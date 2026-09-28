local _, Topline = ...
local slotNames = { "Head", "Neck", "Shoulders", "Shirt", "Chest", "Waist", "Legs", "Feet",
    "Wrists", "Hands", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2", "Back", "Main hand", "Off hand", "Ranged", "Tabard" }

local function Warning(text, percent)
    if percent < 10 then return "|cffd98279" .. text .. "|r" end
    if percent < 30 then return "|cffd6b369" .. text .. "|r" end
    return text
end

local function Accessible(value)
    return not (issecretvalue and issecretvalue(value))
        and not (canaccessvalue and not canaccessvalue(value))
end

local function ValidNumber(value)
    return Accessible(value) and type(value) == "number"
        and value >= 0 and value < math.huge
end

local function Read(api)
    if type(api) ~= "function" then return nil end
    local ok, value = pcall(api)
    if ok and Accessible(value) then return value end
end

local function Money(value)
    return string.format("|cffe6c566%sg|r |cffbfc5cd%ds|r |cffcf956a%dc|r",
        Topline:Number(math.floor(value / 10000)), math.floor(value / 100) % 100, value % 100)
end

local function RepairTooltip(self, tip)
    tip:AddLine(" ")
    if not self.merchantOpen then
        Topline:TooltipRow(tip, "Repair all cost", "Visit a repair vendor")
        return
    end
    local canRepair = Read(CanMerchantRepair)
    if canRepair ~= true then
        Topline:TooltipRow(tip, "Repair all cost", canRepair == false and "Vendor cannot repair" or "N/A")
        return
    end
    -- Read the current vendor quote on hover; never retain prices after closing.
    local cost = Read(GetRepairAllCost)
    if not ValidNumber(cost) then
        Topline:TooltipRow(tip, "Repair all cost", "N/A")
        return
    end
    Topline:TooltipRow(tip, "Repair all cost", Money(cost))
    local money = Read(GetMoney)
    local affordable = "N/A"
    if ValidNumber(money) then
        affordable = money >= cost and "Yes" or "|cffd98279No|r - short " .. Money(cost - money)
    end
    Topline:TooltipRow(tip, "Affordable with carried gold", affordable)
    tip:AddLine("Vendor repair-all quote includes equipped and carried gear. Repair manually at the vendor.", 0.65, 0.65, 0.65, true)
end

Topline:RegisterModule("Durability", {
    order = 50,
    tooltip = function(self, tip)
        tip:AddLine("Equipped durability", 1, 0.82, 0)
        Topline:TooltipRow(tip, "Overall", self.text)
        if not GetInventoryItemDurability then
            Topline:TooltipRow(tip, "Lowest item", "N/A")
            RepairTooltip(self, tip)
            return
        end
        local damaged, broken, lowest = 0, 0, 100
        local lowestName
        for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
            local current, maximum = GetInventoryItemDurability(slot)
            if ValidNumber(current) and ValidNumber(maximum) and maximum > 0 then
                current = math.max(0, math.min(current, maximum))
                local percent = current / maximum * 100
                if current < maximum then damaged = damaged + 1 end
                if current == 0 then broken = broken + 1 end
                local status = current == 0 and " - broken" or current < maximum and " - damaged" or ""
                local name = GetInventoryItemLink and GetInventoryItemLink("player", slot)
                if not Accessible(name) then name = nil end
                name = name or slotNames[slot] or "Slot " .. slot
                if not lowestName or percent < lowest then lowest, lowestName = percent, name end
                Topline:TooltipRow(tip, name,
                    Warning(string.format("%d / %d (%d%%)%s", current, maximum, math.floor(percent + 0.5), status), percent))
            end
        end
        tip:AddLine(" ")
        Topline:TooltipRow(tip, "Lowest item", lowestName and lowestName .. " - "
            .. Warning(string.format("%d%%", math.floor(lowest + 0.5)), lowest) or "N/A")
        Topline:TooltipRow(tip, "Items needing repair", Warning(tostring(damaged), lowest))
        Topline:TooltipRow(tip, "Broken items", broken > 0 and "|cffd98279" .. broken .. "|r" or "0")
        tip:AddLine("Overall percentage uses total current / maximum durability.", 0.65, 0.65, 0.65, true)
        RepairTooltip(self, tip)
    end,
    events = { "UPDATE_INVENTORY_DURABILITY", "PLAYER_EQUIPMENT_CHANGED", "MERCHANT_SHOW",
        "MERCHANT_CLOSED", "PLAYER_LEAVING_WORLD" },
    update = function(self, event)
        if event == "MERCHANT_SHOW" then self.merchantOpen = true
        elseif event == "MERCHANT_CLOSED" or event == "PLAYER_LEAVING_WORLD"
            or event == "PLAYER_ENTERING_WORLD" or event == "INITIALIZE" then self.merchantOpen = false end
        if not GetInventoryItemDurability then return "Durability: N/A" end
        local current, maximum = 0, 0
        for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
            local value, cap = GetInventoryItemDurability(slot)
            if ValidNumber(value) and ValidNumber(cap) and cap > 0 then
                current = current + math.max(0, math.min(value, cap))
                maximum = maximum + cap
            end
        end
        if maximum == 0 then return "Durability: N/A" end
        local percent = current / maximum * 100
        return Warning(string.format("Durability: %d%%", math.floor(percent + 0.5)), percent)
    end,
})
