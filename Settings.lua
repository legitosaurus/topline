local _, Topline = ...
local hiddenItems
local labels = {
    Zone = "Zone / coordinates", Experience = "XP / time to level", Gold = "Money",
    Bags = "Bag space", Durability = "Durability", Pedometer = "Distance moved",
    Performance = "FPS / latency", Mail = "Mail (when waiting)", Clock = "Clock",
}

function Topline:InitializeSettings()
    if type(ToplineSettingsDB) ~= "table" then ToplineSettingsDB = {} end
    if type(ToplineSettingsDB.hiddenItems) ~= "table" then ToplineSettingsDB.hiddenItems = {} end
    hiddenItems = ToplineSettingsDB.hiddenItems
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
    end)
end
