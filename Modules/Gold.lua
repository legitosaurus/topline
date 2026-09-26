local _, Topline = ...

local function GroupDigits(value)
    local text = string.format("%.0f", value)
    return (text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function FormatMoney(money)
    if money == nil then return "N/A" end
    local gold = math.floor(money / 10000)
    local silver = math.floor(money / 100) % 100
    local copper = money % 100
    return string.format("|cffe6c566%sg|r |cffbfc5cd%ds|r |cffcf956a%dc|r",
        GroupDigits(gold), silver, copper)
end

Topline:RegisterModule("Gold", {
    order = 30,
    events = { "PLAYER_MONEY" },
    menu = function(self, root)
        root:CreateTitle("Money session")
        root:CreateButton("Reset session", function()
            Topline:RefreshModule(self, "RESET_SESSION")
            if Topline.hoveredModule == self then Topline:RefreshInfoTooltip() end
        end)
    end,
    tooltip = function(self, tip)
        tip:AddLine("Money", 1, 0.82, 0)
        tip:AddLine("Right-click money to reset this session.", 0.65, 0.65, 0.65)
        Topline:TooltipRow(tip, "Current character", self.text)
        tip:AddLine(" ")
        Topline:TooltipRow(tip, "Gained this session", FormatMoney(self.gained))
        Topline:TooltipRow(tip, "Spent this session", FormatMoney(self.spent))
        local net = self.gained and self.gained - self.spent
        local netText = "N/A"
        if net then
            netText = (net > 0 and "+" or net < 0 and "-" or "") .. FormatMoney(math.abs(net))
        end
        Topline:TooltipRow(tip, "Net change", netText)
        tip:AddLine("Carried money; bank and other characters are excluded.", 0.65, 0.65, 0.65, true)
        tip:AddLine("Tracks observed balance changes, including transfers. Login or /reload starts a new session.", 0.65, 0.65, 0.65, true)
    end,
    update = function(self, event)
        if event == "RESET_SESSION" then
            self.gained, self.spent, self.lastMoney = 0, 0, nil
            -- If money is temporarily unreadable, the next valid balance is
            -- the baseline; never carry a pre-reset delta into the new session.
        end
        local money = GetMoney and GetMoney()
        if (issecretvalue and issecretvalue(money))
            or (canaccessvalue and not canaccessvalue(money)) then return "Gold: N/A" end
        if type(money) ~= "number" or money < 0 or money ~= money or money == math.huge then return "Gold: N/A" end
        if self.lastMoney == nil then
            self.gained, self.spent = 0, 0
        else
            local change = money - self.lastMoney
            if change > 0 then self.gained = self.gained + change
            elseif change < 0 then self.spent = self.spent - change end
        end
        self.lastMoney = money
        return FormatMoney(money)
    end,
})
