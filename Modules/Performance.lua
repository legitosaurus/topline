local _, Topline = ...
local normal, warning, critical = "|cffc7c7c7", "|cffd6b369", "|cffd98279"

local function ReadableNumber(value)
    if issecretvalue and issecretvalue(value) then return end
    if canaccessvalue and not canaccessvalue(value) then return end
    if type(value) == "number" and value >= 0 and value < math.huge then return value end
end

local function Format(value, unit, color)
    if not value then return normal .. "N/A " .. unit .. "|r" end
    return color .. string.format("%d %s", math.floor(value + 0.5), unit) .. "|r"
end

Topline:RegisterModule("Performance", {
    order = 90,
    side = "right",
    interval = 2,
    update = function(self)
        -- Read independently so a missing/restricted API does not hide the other metric.
        local fps, home, world
        if GetFramerate then
            local ok, value = pcall(GetFramerate)
            if ok then fps = ReadableNumber(value) end
        end
        if GetNetStats then
            local ok, _, _, homeValue, worldValue = pcall(GetNetStats)
            if ok then home, world = ReadableNumber(homeValue), ReadableNumber(worldValue) end
        end
        self.fps, self.home, self.world = fps, home, world
        local latency = home and world and math.max(home, world) or home or world
        local fpsColor = fps and (fps < 30 and critical or fps < 60 and warning) or normal
        local latencyColor = latency and (latency >= 300 and critical or latency >= 150 and warning) or normal
        return Format(fps, "FPS", fpsColor) .. "  |cff666b73|||r  " .. Format(latency, "ms", latencyColor)
    end,
    tooltip = function(self, tip)
        tip:AddLine("Performance", 1, 0.82, 0)
        Topline:TooltipRow(tip, "Frame rate", self.fps and string.format("%.1f FPS", self.fps) or "N/A")
        Topline:TooltipRow(tip, "Home latency", self.home and string.format("%.0f ms", self.home) or "N/A")
        Topline:TooltipRow(tip, "World latency", self.world and string.format("%.0f ms", self.world) or "N/A")
        tip:AddLine("Bar latency shows the higher available value. Refreshes every 2 seconds.", 0.65, 0.65, 0.65, true)
        tip:AddLine("FPS: amber below 60, red below 30. Latency: amber at 150 ms, red at 300 ms.", 0.65, 0.65, 0.65, true)
    end,
})
