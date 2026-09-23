local _, Topline = ...
local unavailable = "XP/hr: N/A, Time to Level: N/A"
local warmupSeconds = 60

local function FormatRate(rate)
    if rate >= 1000000 then return string.format("%.1fm", rate / 1000000) end
    if rate >= 1000 then return string.format("%.1fk", rate / 1000) end
    return string.format("%.0f", rate)
end

local function FormatDuration(seconds)
    local minutes = math.max(1, math.ceil(seconds / 60))
    if minutes >= 1440 then
        return string.format("%dd %dh", math.floor(minutes / 1440), math.floor(minutes / 60) % 24)
    elseif minutes >= 60 then
        return string.format("%dh %dm", math.floor(minutes / 60), minutes % 60)
    end
    return string.format("%dm", minutes)
end

local function DeferSample(self)
    if self.samplePending or not (C_Timer and C_Timer.After) then return end
    self.samplePending = true
    C_Timer.After(0, function()
        self.samplePending = false
        Topline:RefreshModule(self, "SAMPLE")
    end)
end

Topline:RegisterModule("Experience", {
    order = 20,
    events = { "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP" },
    interval = 5,
    update = function(self, event, unitOrLevel)
        if event == "PLAYER_XP_UPDATE" then
            if unitOrLevel and unitOrLevel ~= "player" then return end
            DeferSample(self)
            return
        elseif event == "PLAYER_LEVEL_UP" then
            if type(unitOrLevel) == "number" then
                self.pendingLevel = math.max(self.pendingLevel or 0, unitOrLevel)
            end
            -- UnitLevel/UnitXP may still describe the previous level in this event.
            DeferSample(self)
            return
        end

        if not (UnitXP and UnitXPMax and UnitLevel and GetTime) then return unavailable end
        local xp, cap, level = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
        local now = GetTime()
        if type(xp) ~= "number" or type(cap) ~= "number" or type(level) ~= "number"
            or xp < 0 or cap < 0 or level < 1 then
            return unavailable
        end
        if self.pendingLevel and level < self.pendingLevel then return end
        self.pendingLevel = nil

        if not self.startedAt then
            self.startedAt, self.startXP, self.startLevel = now, xp, level
            self.gained = 0
            self.lastXP, self.lastCap, self.lastLevel = xp, cap, level
        else
            local delta
            if level == self.lastLevel then
                -- A wrapped XP value can arrive before the new level is visible.
                if xp < self.lastXP then return end
                delta = xp - self.lastXP
            elseif level == self.lastLevel + 1 and self.lastCap > 0 then
                delta = self.lastCap - self.lastXP + xp
            else
                -- A boost/multi-level jump has unknown intermediate XP caps. Do
                -- not invent earned XP or silently reset the session's counters.
                self.incomplete = true
                delta = 0
            end
            self.gained = self.gained + math.max(0, delta)
            self.lastXP, self.lastCap, self.lastLevel = xp, cap, level
        end

        local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel()
        if type(maxLevel) == "number" and maxLevel > 0 and level >= maxLevel then
            return "XP: Max level"
        end
        if cap <= 0 or xp >= cap or self.incomplete then return unavailable end
        local elapsed = now - self.startedAt
        if elapsed < warmupSeconds or self.gained <= 0 then return unavailable end
        local rate = self.gained * 3600 / elapsed
        return "XP/hr: " .. FormatRate(rate) .. ", Time to Level: "
            .. FormatDuration((cap - xp) * elapsed / self.gained)
    end,
})
