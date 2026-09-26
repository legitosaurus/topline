local _, Topline = ...
local measure

function Topline:Number(value)
    if type(value) ~= "number" then return "N/A" end
    local digits = string.format("%.0f", math.floor(value))
    return (digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

function Topline:Duration(seconds)
    if type(seconds) ~= "number" or seconds < 0 then return "N/A" end
    seconds = math.floor(seconds)
    local hours, minutes = math.floor(seconds / 3600), math.floor(seconds / 60) % 60
    if hours >= 24 then return string.format("%dd %dh %dm", math.floor(hours / 24), hours % 24, minutes) end
    if hours > 0 then return string.format("%dh %dm %ds", hours, minutes, seconds % 60) end
    return string.format("%dm %ds", minutes, seconds % 60)
end

function Topline:TooltipRow(tip, label, value)
    tip:AddDoubleLine(label, tostring(value or "N/A"), 0.95, 0.77, 0.35, 0.9, 0.9, 0.9)
end

function Topline:HideInfoTooltip()
    self.hoveredModule = nil
    if self.tooltipTicker then self.tooltipTicker:Cancel(); self.tooltipTicker = nil end
    if self.infoTooltip then self.infoTooltip:Hide() end
end

function Topline:RefreshInfoTooltip()
    local module = self.hoveredModule
    if not module then return end
    local tip = self.infoTooltip
    tip:ClearLines()
    local ok = pcall(module.tooltip, module, tip)
    if not ok then
        tip:ClearLines()
        tip:AddLine(module.name, 1, 0.82, 0)
        tip:AddLine("Details currently unavailable.", 0.85, 0.85, 0.85)
    end
    tip:Show()
end

function Topline:ShowInfoTooltip(module)
    self:HideInfoTooltip()
    if not module.tooltip then return end
    if not self.infoTooltip then
        self.infoTooltip = CreateFrame("GameTooltip", "ToplineInfoTooltip", UIParent, "GameTooltipTemplate")
        self.infoTooltip:SetClampedToScreen(true)
    end
    self.hoveredModule = module
    local tip = self.infoTooltip
    tip:SetOwner(module.hoverFrame, "ANCHOR_NONE")
    tip:ClearAllPoints()
    local point = module.side == "right" and "RIGHT" or "LEFT"
    tip:SetPoint("TOP" .. point, module.hoverFrame, "BOTTOM" .. point, 0, -4)
    self:RefreshInfoTooltip()
    if C_Timer and C_Timer.NewTicker then
        self.tooltipTicker = C_Timer.NewTicker(1, function() self:RefreshInfoTooltip() end)
    end
end

-- Keep the continuous text layout; transparent motion-only regions follow the
-- measured text, including its font size and clipping in a narrow window.
function Topline:LayoutHoverRegions(separator, leftWidth, rightWidth)
    if not measure then
        measure = self.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        measure:Hide()
    end
    local leftOffset, rightOffset = 0, 0
    for _, module in ipairs(self.modules) do
        local right = module.side == "right"
        local font = right and self.rightText or self.text
        measure:SetFont(font:GetFont())
        measure:SetText(module.text)
        local width = measure:GetUnboundedStringWidth()
        measure:SetText(separator)
        local gap = measure:GetUnboundedStringWidth()
        local offset = right and rightOffset or leftOffset
        local limit = right and rightWidth or leftWidth
        local visible = math.min(width, limit - offset)
        if module.tooltip then
            if not module.hoverFrame then
                local region = CreateFrame("Frame", nil, self.bar)
                module.hoverFrame = region
                region:EnableMouse(false)
                if region.EnableMouseMotion then region:EnableMouseMotion(true) else region:EnableMouse(true) end
                if module.menu then
                    region:EnableMouse(true)
                    region:SetScript("OnMouseUp", function(owner, button)
                        if button ~= "RightButton" or not (MenuUtil and MenuUtil.CreateContextMenu) then return end
                        self:HideInfoTooltip()
                        MenuUtil.CreateContextMenu(owner, function(_, root) module:menu(root) end)
                    end)
                end
                region:SetScript("OnEnter", function() self:ShowInfoTooltip(module) end)
                region:SetScript("OnLeave", function()
                    if self.hoveredModule == module then self:HideInfoTooltip() end
                end)
                region:SetScript("OnHide", function()
                    if self.hoveredModule == module then self:HideInfoTooltip() end
                end)
            end
            local region = module.hoverFrame
            if visible > 0 then
                local x = right and self.bar:GetWidth() - 10 - rightWidth + offset or 10 + offset
                region:ClearAllPoints()
                region:SetPoint("TOPLEFT", self.bar, "TOPLEFT", x, 0)
                region:SetWidth(visible)
                region:SetHeight(20)
                region:Show()
            else
                region:Hide()
            end
        end
        if right then rightOffset = offset + width + gap else leftOffset = offset + width + gap end
    end
end
