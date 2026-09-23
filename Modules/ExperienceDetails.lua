local _, Topline = ...
local module = Topline:GetModule("Experience")
local patterns

local function Escape(text)
    return (text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

-- Named kill messages take mob name as argument 1 and awarded XP as argument 2.
-- Compile localized format strings, including positional placeholders. Never
-- take the first number in chat: creature names can themselves contain digits.
local function KillPattern(format)
    local parts, cursor, argument, captured = { "^" }, 1, 0, false
    while true do
        local first, last, position, kind = format:find("%%(%d*%$?)([sd])", cursor)
        if not first then break end
        parts[#parts + 1] = Escape(format:sub(cursor, first - 1))
        argument = argument + 1
        local index = tonumber(position:match("%d+")) or argument
        if index == 2 and kind == "d" then
            parts[#parts + 1] = "(%d+)"
            captured = true
        else
            parts[#parts + 1] = kind == "d" and "%d+" or ".-"
        end
        cursor = last + 1
    end
    parts[#parts + 1] = Escape(format:sub(cursor)) .. "$"
    if captured then return table.concat(parts) end
end

function module.ParseKillXP(message)
    if issecretvalue and issecretvalue(message) then return end
    if type(message) ~= "string" then return end
    if not patterns then
        patterns = {}
        for name, format in pairs(_G) do
            if type(name) == "string" and name:match("^COMBATLOG_XPGAIN_")
                and not name:find("UNNAMED", 1, true) and not name:find("QUEST", 1, true)
                and type(format) == "string" then
                local pattern = KillPattern(format)
                if pattern then patterns[#patterns + 1] = pattern end
            end
        end
    end
    for _, pattern in ipairs(patterns) do
        local xp = tonumber(message:match(pattern))
        if xp and xp > 0 then return xp end
    end
end

function module:tooltip(tip)
    tip:AddLine("XP Info", 1, 0.82, 0)
    local now = GetTime and GetTime()
    local elapsed = now and self.startedAt and math.max(0, now - self.startedAt)
    Topline:TooltipRow(tip, "Time played this session", Topline:Duration(elapsed))
    Topline:TooltipRow(tip, "XP gained this session", self.incomplete and "Unknown" or Topline:Number(self.gained))
    tip:AddLine(" ")
    local xp = UnitXP and UnitXP("player")
    local cap = UnitXPMax and UnitXPMax("player")
    local level = UnitLevel and UnitLevel("player")
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel()
    if type(level) == "number" and type(maxLevel) == "number" and maxLevel > 0 and level >= maxLevel then
        tip:AddLine("Maximum level reached.", 0.9, 0.9, 0.9)
        return
    end
    if type(xp) ~= "number" or type(cap) ~= "number" or cap <= 0 then
        tip:AddLine("XP information unavailable.", 0.9, 0.9, 0.9)
        return
    end
    local remaining = math.max(0, cap - xp)
    Topline:TooltipRow(tip, "XP required this level", Topline:Number(cap))
    Topline:TooltipRow(tip, "XP gained this level", string.format("%s (%.1f%%)", Topline:Number(xp), xp / cap * 100))
    Topline:TooltipRow(tip, "XP needed to level", string.format("%s (%.1f%%)", Topline:Number(remaining), remaining / cap * 100))
    local rested = GetXPExhaustion and GetXPExhaustion()
    Topline:TooltipRow(tip, "Rested XP available", GetXPExhaustion and Topline:Number(rested or 0) or "N/A")
    tip:AddLine(" ")
    Topline:TooltipRow(tip, "Last kill XP", Topline:Number(self.lastKillXP))
    Topline:TooltipRow(tip, "Kills to level (last kill)", self.lastKillXP and Topline:Number(math.ceil(remaining / self.lastKillXP)) or "Unknown")
    Topline:TooltipRow(tip, "Last XP gain", Topline:Number(self.lastGain))
    Topline:TooltipRow(tip, "XP gains to level (last gain)", self.lastGain and Topline:Number(math.ceil(remaining / self.lastGain)) or "Unknown")
    tip:AddLine(" ")
    local rate = elapsed and elapsed >= 60 and self.gained and self.gained > 0
        and not self.incomplete and self.gained * 3600 / elapsed
    Topline:TooltipRow(tip, "XP/hour this session", rate and Topline:Number(rate) or "N/A")
    Topline:TooltipRow(tip, "Time to level (session rate)", rate and Topline:Duration(remaining / rate * 3600) or "N/A")
    tip:AddLine("Estimates assume similar rewards. Simultaneous XP awards may combine.", 0.65, 0.65, 0.65, true)
    if self.incomplete then
        tip:AddLine("Session XP is incomplete after an unobserved level jump.", 0.65, 0.65, 0.65, true)
    elseif not rate then tip:AddLine("Rate needs 60 seconds and positive session XP. Reload starts a new XP session.", 0.65, 0.65, 0.65, true) end
end
