local _, Topline = ...

local function GroupDigits(value)
    local text = string.format("%.0f", value)
    return (text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

Topline:RegisterModule("Gold", {
    order = 30,
    events = { "PLAYER_MONEY" },
    tooltip = function(self, tip)
        tip:AddLine("Money", 1, 0.82, 0)
        Topline:TooltipRow(tip, "Current character", self.text)
        tip:AddLine("Carried money; bank and other characters are excluded.", 0.65, 0.65, 0.65, true)
    end,
    update = function()
        local money = GetMoney and GetMoney()
        if type(money) ~= "number" or money < 0 then return "Gold: N/A" end
        local gold = math.floor(money / 10000)
        local silver = math.floor(money / 100) % 100
        local copper = money % 100
        return string.format("|cffe6c566%sg|r |cffbfc5cd%ds|r |cffcf956a%dc|r",
            GroupDigits(gold), silver, copper)
    end,
})
