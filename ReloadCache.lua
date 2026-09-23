local _, Topline = ...
local cacheKey, cacheGet, cacheSet
local nextSave = 0

local function Distance(value)
    local number = tonumber(value)
    if number and number >= 0 and number < math.huge then return number end
end

local function CacheAPI()
    if cacheKey then return cacheKey, cacheGet, cacheSet end
    if not GetBuildInfo or not UnitGUID then return end
    local build = select(4, GetBuildInfo())
    if type(build) ~= "number" or build < 16000 or build >= 20000 then return end
    local guid = UnitGUID("player")
    if type(guid) ~= "string" or not guid:match("^Player%-%d+%-%x+$") then return end
    local register = C_CVar and C_CVar.RegisterCVar or RegisterCVar
    local get = C_CVar and C_CVar.GetCVar or GetCVar
    local set = C_CVar and C_CVar.SetCVar or SetCVar
    if not (register and get and set) then return end
    local key = "ToplineTravel_" .. guid:gsub("%-", "_")
    local ok, value = pcall(get, key)
    if not ok or value == nil then
        if not pcall(register, key, "") then return end
    end
    cacheKey, cacheGet, cacheSet = key, get, set
    return cacheKey, cacheGet, cacheSet
end

function Topline:RestoreReloadCache(history)
    local key, get = CacheAPI()
    if not key then return end
    local ok, encoded = pcall(get, key)
    if not ok or type(encoded) ~= "string" or #encoded > 131072 then return end
    local total, body = encoded:match("^1|([^|]+)|(.*)$")
    total = Distance(total)
    if not total then return end
    local restored = {}
    for row in body:gmatch("[^|]+") do
        local day, value = row:match("^(%d%d%d%d%-%d%d%-%d%d)=([^=]+)$")
        value = Distance(value)
        if not day or not value then return end
        restored[day] = value
    end
    -- Cumulative snapshots overlap: merge maxima rather than adding sessions
    -- twice. Never replace newer disk history with an older reload checkpoint.
    for day, value in pairs(restored) do
        history.days[day] = math.max(history.days[day] or 0, value)
    end
    local sum = 0
    for _, value in pairs(history.days) do sum = sum + value end
    history.totalYards = math.max(history.totalYards, total, sum)
end

function Topline:SaveReloadCache(force)
    local history = self.travelHistory
    if not history then return end
    local now = GetTime and GetTime() or 0
    if not force and now < nextSave then return end
    nextSave = now + 5
    local key, get, set = CacheAPI()
    if not key then return end
    local parts = { "1", string.format("%.17g", history.totalYards) }
    for day, value in pairs(history.days) do
        parts[#parts + 1] = day .. "=" .. string.format("%.17g", value)
    end
    local encoded = table.concat(parts, "|")
    if #parts == 2 then encoded = encoded .. "|" end
    local ok = false
    if #encoded <= 131072 then
        ok = pcall(set, key, encoded)
        if ok then
            local readOK, actual = pcall(get, key)
            ok = readOK and actual == encoded
        end
    end
    if not ok and not self.reloadCacheWarned then
        self.reloadCacheWarned = true
        print("Topline: reload backup unavailable; distance currently relies on WoW SavedVariables.")
    end
end

-- Custom CVars survive UI reload/relog in the same running client, but NOT a
-- full game restart. SavedVariables remain the durable storage mechanism.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function() Topline:SaveReloadCache(true) end)
