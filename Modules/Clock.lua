local _, Topline = ...

Topline:RegisterModule("Clock", {
    order = 100,
    side = "right",
    tooltip = function(self, tip)
        tip:AddLine("Time", 1, 0.82, 0)
        Topline:TooltipRow(tip, "Local date", date and date("%A, %B %d, %Y"))
        Topline:TooltipRow(tip, "Local time", date and date("%I:%M:%S %p"))
        local hours, minutes
        if GetGameTime then hours, minutes = GetGameTime() end
        Topline:TooltipRow(tip, "Realm time", type(hours) == "number" and type(minutes) == "number"
            and string.format("%02d:%02d", hours, minutes) or "N/A")
    end,
    interval = 10,
    update = function()
        if not date then return "Local: N/A" end
        return "Local " .. date("%I:%M %p"):gsub("^0", "")
    end,
})
