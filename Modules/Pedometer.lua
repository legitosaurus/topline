local _, Topline = ...
local sqrt, max, floor = math.sqrt, math.max, math.floor

local function ResetPosition(self)
    self.x, self.y, self.instance, self.time, self.speed = nil, nil, nil, nil, nil
end

local function Display(self, available)
    if not available then return "Moved today: N/A" end
    local history, day = Topline:GetTravelRecord()
    if not history or not day then return "Moved today: N/A" end
    local yards = floor(history.days[day] or 0)
    if self.shownYards ~= yards then
        self.shownYards = yards
        local digits = string.format("%.0f", yards)
        digits = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        self.label = "Moved today: " .. digits .. " yd"
    end
    return self.label
end

Topline:RegisterModule("Pedometer", {
    order = 60,
    tooltip = function(self, tip)
        tip:AddLine("Character travel", 1, 0.82, 0)
        local history, today = Topline:GetTravelRecord()
        if not history or not today then tip:AddLine("Travel history unavailable."); return end
        Topline:TooltipRow(tip, "Today", Topline:Number(history.days[today] or 0) .. " yd")
        Topline:TooltipRow(tip, "This session", Topline:Number(self.total or 0) .. " yd")
        Topline:TooltipRow(tip, "All recorded travel", Topline:Number(history.totalYards) .. " yd")
        local days = {}
        for day in pairs(history.days) do if day < today then days[#days + 1] = day end end
        table.sort(days, function(a, b) return a > b end)
        if #days > 0 then
            tip:AddLine(" ")
            tip:AddLine("Recent travel days", 1, 0.82, 0)
            for index = 1, math.min(7, #days) do
                Topline:TooltipRow(tip, days[index], Topline:Number(history.days[days[index]]) .. " yd")
            end
        end
        tip:AddLine("Days use local midnight. Includes mounted travel; excludes taxis and vehicles.", 0.65, 0.65, 0.65, true)
    end,
    interval = 0.25,
    events = { "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING", "PLAYER_LEAVING_WORLD" },
    update = function(self, event)
        self.total = self.total or 0
        if event == "PLAYER_LEAVING_WORLD" then
            self.loading = true
            ResetPosition(self)
            return Display(self, true)
        elseif event == "PLAYER_ENTERING_WORLD" or event == "INITIALIZE" then
            self.loading = false
            ResetPosition(self)
        end
        if self.loading or (UnitOnTaxi and UnitOnTaxi("player"))
            or (UnitInVehicle and UnitInVehicle("player")) then
            ResetPosition(self)
            return Display(self, true)
        end
        if not GetTime then return Display(self, false) end
        local now = GetTime()
        local speed = GetUnitSpeed and GetUnitSpeed("player")
        if type(speed) ~= "number" or speed < 0 then speed = nil end
        local x, y, _, instance
        if UnitPosition then x, y, _, instance = UnitPosition("player") end
        local hasPosition = type(x) == "number" and type(y) == "number"
            and type(instance) == "number"
        if not hasPosition then x, y, instance = nil, nil, nil end

        local elapsed = self.time and now - self.time
        if elapsed and elapsed > 0 and elapsed <= 2 then
            if hasPosition and self.x and self.instance == instance then
                local dx, dy = x - self.x, y - self.y
                local distance = sqrt(dx * dx + dy * dy)
                -- Reject teleports/blinks and sudden position corrections.
                local plausibleSpeed = max(speed or 100, self.speed or speed or 100)
                if distance <= plausibleSpeed * elapsed * 1.5 + 2 then
                    self.total = self.total + distance
                    Topline:RecordTravel(distance)
                end
            elseif not hasPosition and not self.x and speed and self.speed then
                -- Some instances do not expose UnitPosition. Estimate travel from
                -- actual movement speed (yards/sec), never normalized map coords.
                local distance = (speed + self.speed) * 0.5 * elapsed
                self.total = self.total + distance
                Topline:RecordTravel(distance)
            end
        end
        self.x, self.y, self.instance, self.time, self.speed = x, y, instance, now, speed
        return Display(self, hasPosition or speed ~= nil)
    end,
})
