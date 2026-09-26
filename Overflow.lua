local _, Topline = ...

function Topline:OpenOverflowMenu(side)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    self:HideInfoTooltip()
    MenuUtil.CreateContextMenu(self.bar, function(_, root)
        root:CreateTitle("More items")
        for _, module in ipairs(self.modules) do
            if module.overflowSide == side and self:IsItemEnabled(module) and module.text ~= "" then
                local entry = root:CreateButton(self:ItemLabel(module))
                entry:SetTooltip(function(tip)
                    local ok = module.tooltip and pcall(module.tooltip, module, tip)
                    if not ok then tip:AddLine(module.text, 0.9, 0.9, 0.9, true) end
                end)
                if module.menu then module:menu(entry); entry:CreateDivider() end
                entry:CreateButton("Hide item", function() self:SetItemEnabled(module, false) end)
                local destination = module.side == "right" and "left" or "right"
                entry:CreateButton("Move to " .. destination .. " group", function()
                    self:MoveItemToGroup(module, destination)
                end)
            end
        end
    end)
end

function Topline:PrepareOverflow(side, width, natural, origin)
    self.overflowButtons = self.overflowButtons or {}
    local button = self.overflowButtons[side]
    local reserve = natural > width and width > 0 and math.min(24, width) or 0
    if reserve == 0 then
        if button then button:Hide() end
        return width, 0
    end
    if not button then
        button = CreateFrame("Frame", nil, self.bar)
        self.overflowButtons[side] = button
        button:EnableMouse(true)
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetAllPoints()
        label:SetFont(self.fontPath, 12, "")
        label:SetTextColor(0.90, 0.80, 0.58)
        label:SetText("...")
        label:SetWordWrap(false)
        button:SetScript("OnMouseUp", function(_, mouseButton)
            if mouseButton == "LeftButton" or mouseButton == "RightButton" then self:OpenOverflowMenu(side) end
        end)
    end
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", self.bar, "TOPLEFT", origin + width - reserve, 0)
    button:SetWidth(reserve)
    button:SetHeight(20)
    button:Show()
    return width - reserve, reserve
end
