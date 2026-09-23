local _, Topline = ...

Topline:RegisterModule("Clock", {
    order = 100,
    side = "right",
    interval = 10,
    update = function()
        if not date then return "Local: N/A" end
        return "Local " .. date("%I:%M %p"):gsub("^0", "")
    end,
})
