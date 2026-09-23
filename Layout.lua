local _, Topline = ...
-- Check roots before their dependents, so attached frames follow naturally.
local frameNames = {
    "MinimapCluster", "PlayerFrame", "TargetFrame", "FocusFrame",
    "BuffFrame", "DebuffFrame", "ObjectiveTrackerFrame",
}
local hooked, warned = {}, {}
local pending, adjusting = false, false

local function InEditMode()
    return EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive
        and EditModeManagerFrame:IsEditModeActive()
end

local function ClearTopEdge(frame, ceiling)
    local top, scale = frame:GetTop(), frame:GetEffectiveScale()
    if not top or not scale or scale <= 0 then return end
    local overlap = top * scale - ceiling
    if overlap < 0.5 then return end
    -- Keep every anchor and its relative frame. This translates multi-anchor
    -- frames too, without stretching them or rewriting Edit Mode saved layouts.
    local points = {}
    for index = 1, frame:GetNumPoints() do
        points[index] = { frame:GetPoint(index) }
    end
    if #points == 0 then return end
    frame:ClearAllPoints()
    for _, point in ipairs(points) do
        frame:SetPoint(point[1], point[2], point[3], point[4], point[5] - overlap / scale)
    end
end

function Topline:ApplyLayout()
    if not self.bar or (InCombatLockdown and InCombatLockdown()) or InEditMode() then return end
    local bottom = self.bar:GetBottom()
    if not bottom then return end
    -- Compare physical coordinates; individual frames may have their own scale.
    local ceiling = (bottom - 2) * self.bar:GetEffectiveScale()
    adjusting = true
    for _, name in ipairs(frameNames) do
        local frame = _G[name]
        if frame then
            if not hooked[frame] and hooksecurefunc then
                hooked[frame] = true
                hooksecurefunc(frame, "SetPoint", function() self:RequestLayout() end)
                hooksecurefunc(frame, "SetScale", function() self:RequestLayout() end)
                frame:HookScript("OnShow", function() self:RequestLayout() end)
            end
            local ok, err = pcall(ClearTopEdge, frame, ceiling)
            if not ok and not warned[frame] then
                warned[frame] = true
                print("Topline: could not make room above " .. name .. ": " .. tostring(err))
            end
        end
    end
    adjusting = false
end

function Topline:RequestLayout()
    if adjusting or pending or not self.layoutEvents then return end
    if not (C_Timer and C_Timer.After) then return end
    pending = true
    C_Timer.After(0, function()
        pending = false
        self:ApplyLayout()
    end)
end

function Topline:InitializeLayout()
    local events = CreateFrame("Frame")
    self.layoutEvents = events
    events:SetScript("OnEvent", function() self:RequestLayout() end)
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
        "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "EDIT_MODE_LAYOUTS_UPDATED", "ADDON_LOADED" }) do
        pcall(events.RegisterEvent, events, event)
    end
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Exit", function() self:RequestLayout() end, self)
    end
    self:RequestLayout()
end
