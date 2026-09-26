local _, Topline = ...
local hiddenItems
local labels = {
    Zone = "Zone / coordinates", Experience = "XP / time to level", Gold = "Money",
    Bags = "Bag space", Durability = "Durability", Pedometer = "Distance moved",
    Performance = "FPS / latency", Mail = "Mail (when waiting)", Clock = "Clock",
}

function Topline:ItemLabel(module)
    return labels[module.name] or module.name
end

function Topline:InitializeSettings()
    if type(ToplineSettingsDB) ~= "table" then ToplineSettingsDB = {} end
    if type(ToplineSettingsDB.hiddenItems) ~= "table" then ToplineSettingsDB.hiddenItems = {} end
    hiddenItems = ToplineSettingsDB.hiddenItems
    self:ApplyItemOrder()
end

function Topline:ApplyItemOrder()
    local sides = type(ToplineSettingsDB.itemSides) == "table" and ToplineSettingsDB.itemSides or {}
    for _, item in ipairs(self.modules) do
        local side = sides[item.name]
        item.side = (side == "left" or side == "right") and side or item.defaultSide
    end
    local ranks, nextRank = {}, 0
    if type(ToplineSettingsDB.itemOrder) == "table" then
        for _, name in ipairs(ToplineSettingsDB.itemOrder) do
            if type(name) == "string" and self:GetModule(name) and not ranks[name] then
                nextRank = nextRank + 1
                ranks[name] = nextRank
            end
        end
    end
    table.sort(self.modules, function(a, b)
        local aRight, bRight = a.side == "right", b.side == "right"
        if aRight ~= bRight then return not aRight end
        local ar, br = ranks[a.name], ranks[b.name]
        if ar and br then return ar < br end
        if ar or br then return ar ~= nil end
        return a.order < b.order
    end)
end

function Topline:ItemNeighbor(module, direction)
    for index, item in ipairs(self.modules) do
        if item == module then
            local other = index + direction
            local neighbor = self.modules[other]
            if neighbor and (neighbor.side == "right") == (item.side == "right") then return index, other end
        end
    end
end

function Topline:MoveItem(module, direction)
    if direction ~= -1 and direction ~= 1 then return end
    local index, other = self:ItemNeighbor(module, direction)
    if not index then return end
    self.modules[index], self.modules[other] = self.modules[other], self.modules[index]
    self:SaveItemOrder()
    self:HideInfoTooltip()
    self:RequestRender()
end

function Topline:SaveItemOrder()
    local order = {}
    for position, item in ipairs(self.modules) do order[position] = item.name end
    ToplineSettingsDB.itemOrder = order
end

function Topline:MoveItemToGroup(module, side)
    if side ~= "left" and side ~= "right" then return end
    if module.side == side then return end
    for index, item in ipairs(self.modules) do
        if item == module then
            table.remove(self.modules, index)
            table.insert(self.modules, module)
            if type(ToplineSettingsDB.itemSides) ~= "table" then ToplineSettingsDB.itemSides = {} end
            ToplineSettingsDB.itemSides[module.name] = side ~= module.defaultSide and side or nil
            -- Sort by group after saving: the moved item lands last in its new group.
            self:SaveItemOrder()
            self:ApplyItemOrder()
            break
        end
    end
    self:HideInfoTooltip()
    self:RequestRender()
end

function Topline:RestoreItemOrder()
    ToplineSettingsDB.itemOrder = nil
    ToplineSettingsDB.itemSides = nil
    self:ApplyItemOrder()
    self:HideInfoTooltip()
    self:RequestRender()
end

function Topline:IsItemEnabled(module)
    return not hiddenItems or hiddenItems[module.name] ~= true
end

function Topline:SetItemEnabled(module, enabled)
    hiddenItems[module.name] = not enabled or nil
    self:RequestRender()
end

function Topline:RestoreItemDefaults()
    for name in pairs(hiddenItems) do hiddenItems[name] = nil end
    self:RequestRender()
end

function Topline:OpenBarMenu(module)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    self:HideInfoTooltip()
    -- Own menus on the bar so hiding the item under the cursor does not close it.
    MenuUtil.CreateContextMenu(self.bar, function(_, root)
        if module and module.menu then module:menu(root) else root:CreateTitle("Topline") end
        local items = root:CreateButton("Show/hide items")
        for _, item in ipairs(self.modules) do
            items:CreateCheckbox(labels[item.name] or item.name,
                function() return self:IsItemEnabled(item) end,
                function() self:SetItemEnabled(item, not self:IsItemEnabled(item)) end)
        end
        items:CreateDivider()
        items:CreateButton("Restore defaults", function() self:RestoreItemDefaults() end)
        local ordering = root:CreateButton("Reorder items")
        local previousSide
        for _, item in ipairs(self.modules) do
            local side = item.side == "right" and "Right side" or "Left side"
            if previousSide ~= side then ordering:CreateTitle(side); previousSide = side end
            local entry = ordering:CreateButton(labels[item.name] or item.name)
            if self:ItemNeighbor(item, -1) then
                entry:CreateButton("Move left", function() self:MoveItem(item, -1) end)
            end
            if self:ItemNeighbor(item, 1) then
                entry:CreateButton("Move right", function() self:MoveItem(item, 1) end)
            end
            entry:CreateDivider()
            local destination = item.side == "right" and "left" or "right"
            entry:CreateButton("Move to " .. destination .. " group", function()
                self:MoveItemToGroup(item, destination)
            end)
        end
        ordering:CreateDivider()
        ordering:CreateButton("Restore default order", function() self:RestoreItemOrder() end)
    end)
end
