local _, Topline = ...
local cachedSecond, cachedDay

local function ValidDistance(value)
    return type(value) == "number" and value >= 0 and value < math.huge
end

local function ValidDay(value)
    return type(value) == "string" and value:match("^%d%d%d%d%-%d%d%-%d%d$")
end

local function Today()
    if not date then return nil end
    local second = GetServerTime and GetServerTime() or (time and time())
    -- The date formatter uses the computer's local timezone. Server epoch time
    -- supplies a stable clock; cache formatting within each wall-clock second.
    if second and second == cachedSecond then return cachedDay end
    local day = date("%Y-%m-%d", second)
    if not ValidDay(day) then return nil end
    cachedSecond, cachedDay = second, day
    return day
end

function Topline:GetTravelRecord()
    -- First accessed at PLAYER_LOGIN, after WoW has loaded character variables.
    if not self.travelHistory then
        if type(ToplineCharDB) ~= "table" then ToplineCharDB = {} end
        -- Do not overwrite data from a newer schema if an older addon is loaded.
        if ToplineCharDB.version and ToplineCharDB.version ~= 1 then return nil end
        ToplineCharDB.version = 1
        if type(ToplineCharDB.pedometer) ~= "table" then ToplineCharDB.pedometer = {} end
        local history = ToplineCharDB.pedometer
        if type(history.days) ~= "table" then history.days = {} end
        local sum = 0
        for day, yards in pairs(history.days) do
            if ValidDay(day) and ValidDistance(yards) then
                sum = sum + yards
            else
                history.days[day] = nil
            end
        end
        if not ValidDistance(history.totalYards) or history.totalYards < sum then
            history.totalYards = sum
        end
        self.travelHistory = history
        self:RestoreReloadCache(history)
        self:SaveReloadCache(true)
    end
    return self.travelHistory, Today()
end

function Topline:RecordTravel(yards)
    if not ValidDistance(yards) or yards == 0 then return end
    local history, day = self:GetTravelRecord()
    if not history or not day then return end
    -- Keep fractional yards in storage; only round the rendered value. Update
    -- the live SavedVariables table as we go, without a logout-time accumulator.
    history.days[day] = (history.days[day] or 0) + yards
    history.totalYards = history.totalYards + yards
    self:SaveReloadCache(false)
end
