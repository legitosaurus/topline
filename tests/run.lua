-- Offline Lua 5.1 harness. Run from the Topline directory: lua tests/run.lua
-- Never loaded by the addon TOC. No WoW process or external framework needed.
local checks = 0
local function equal(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, (message or "Mismatch") .. ": expected "
        .. tostring(expected) .. ", got " .. tostring(actual))
end

local function NewSession(options)
    options = options or {}
    local state = {
        now = 0, xp = 900, cap = 1000, level = 10, maxLevel = 60,
        money = 31984757, zone = "Shattrath City", subzone = "Terrace of Light",
        x = 0.57, y = 0.30, map = 1, scale = 0.8,
        slots = { [0] = 16, 16, 16, 16, 16, 32 },
        free = { [0] = 2, 0, 0, 0, 0, 32 },
        durability = { [1] = { 50, 100 }, [5] = { 25, 25 } },
        frames = {}, timers = {}, tickers = {}, bagCalls = {}, messages = {},
        worldX = 100, worldY = 100, instance = 1, speed = 0,
        callbacks = {},
        wallTime = 1789862400, -- Deterministic test calendar; independent of host timezone.
    }
    local env = setmetatable({}, { __index = _G })
    env._G = env
    local Frame = {}
    for _, method in ipairs({ "SetAllPoints", "SetColorTexture", "SetTexCoord", "SetTexture", "SetGradient", "SetJustifyH", "SetJustifyV",
        "SetWordWrap", "SetNonSpaceWrap", "SetTextColor", "SetShadowColor", "SetShadowOffset" }) do
        Frame[method] = function() end
    end
    function Frame:EnableMouseMotion(value) self.mouseMotion = value end
    function Frame:SetClampedToScreen(value) self.clamped = value end
    function Frame:SetOwner(owner) self.owner = owner end
    function Frame:ClearLines() self.lines = {} end
    function Frame:AddLine(text) self.lines[#self.lines + 1] = { text } end
    function Frame:AddDoubleLine(left, right) self.lines[#self.lines + 1] = { left, right } end
    function Frame:Show() self.shown = true end
    function Frame:Hide()
        local wasShown = self.shown
        self.shown = false
        if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function Frame:SetPoint(...)
        local point = { ... }
        for index, previous in ipairs(self.points) do
            if previous[1] == point[1] then self.points[index] = point; return end
        end
        self.points[#self.points + 1] = point
    end
    function Frame:GetNumPoints() return #self.points end
    function Frame:SetVertexColor(...) self.vertexColor = { ... } end
    function Frame:SetWidth(value) self.width = value end
    function Frame:SetTexture(path, horizontal, vertical)
        self.texture, self.horizontalWrap, self.verticalWrap = path, horizontal, vertical
        return true
    end
    function Frame:SetTexCoord(...) self.texCoords = { ... } end
    function Frame:GetPoint(index) return unpack(self.points[index]) end
    function Frame:ClearAllPoints() self.points = {} end
    function Frame:SetHeight(value) self.height = value end
    function Frame:SetFrameStrata(value) self.strata = value end
    function Frame:EnableMouse(value) self.mouse = value end
    function Frame:SetScript(name, callback) self.scripts[name] = callback end
    function Frame:RegisterEvent(event) self.events[event] = true end
    function Frame:GetEffectiveScale() return self.scale or state.scale end
    function Frame:SetScale(value) self.scale = value end
    function Frame:GetTop()
        if self == env.UIParent then return 1080 end
        local point = self.points[1]
        if not point or type(point[2]) ~= "table" then return nil end
        local relative = point[2]
        local top = point[3]:find("BOTTOM") and relative:GetBottom() or relative:GetTop()
        return top * relative:GetEffectiveScale() / self:GetEffectiveScale() + point[5]
    end
    function Frame:GetBottom() return self:GetTop() - (self.height or 20) end
    function Frame:HookScript(name, callback)
        local previous = self.scripts[name]
        self.scripts[name] = function(...)
            if previous then previous(...) end
            callback(...)
        end
    end
    function Frame:GetWidth() return self.width or state.width or 1920 end
    function Frame:SetFont(path, size) self.font, self.fontSize = path, size end
    function Frame:GetFont() return "Fonts\\FRIZQT__.TTF", self.fontSize or 12, "" end
    function Frame:SetText(text) self.text = text end
    function Frame:GetUnboundedStringWidth()
        local plain = self.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        return #plain * self.fontSize * 0.5
    end
    local function Object()
        return setmetatable({ points = {}, scripts = {}, events = {} }, { __index = Frame })
    end
    Frame.CreateTexture = Object
    Frame.CreateFontString = Object
    env.UIParent = Object()
    env.CreateFrame = function(_, name, parent)
        local object = Object()
        object.name, object.parent = name, parent
        state.frames[#state.frames + 1] = object
        return object
    end
    env.C_Timer = {
        After = function(_, callback) state.timers[#state.timers + 1] = callback end,
        NewTicker = function(interval, callback)
            local ticker = { interval = interval, callback = callback, Cancel = function(self) self.cancelled = true end }
            state.tickers[#state.tickers + 1] = ticker
            return ticker
        end,
    }
    env.GetFramerate = function() return state.fps or 144 end
    env.GetNetStats = function() return 0, 0, state.homeLatency or 24, state.worldLatency or 32 end
    env.GetTime = function() return state.now end
    env.GetServerTime = function() return state.wallTime + math.floor(state.now) end
    env.date = function(format, timestamp) return os.date("!" .. format, timestamp or state.wallTime + math.floor(state.now)) end
    env.COMBATLOG_XPGAIN_FIRSTPERSON = "%s dies, you gain %d experience."
    env.COMBATLOG_XPGAIN_FIRSTPERSON_GROUP = "%s dies, you gain %d experience. (+%d group bonus)"
    env.COMBATLOG_XPGAIN_FIRSTPERSON_QUEST = "Quest %s rewards %d experience."
    env.GetXPExhaustion = function() return 500 end
    env.GetGameTime = function() return 18, 30 end
    env.UnitXP = function() return state.xp end
    env.UnitXPMax = function() return state.cap end
    env.UnitLevel = function() return state.level end
    env.UnitPosition = function() return state.worldX, state.worldY, 0, state.instance end
    env.GetUnitSpeed = function() return state.speed end
    env.UnitOnTaxi = function() return state.taxi end
    env.UnitInVehicle = function() return state.vehicle end
    env.InCombatLockdown = function() return state.combat end
    env.EditModeManagerFrame = { IsEditModeActive = function() return state.editing end }
    env.EventRegistry = { RegisterCallback = function(_, name, callback) state.callbacks[name] = callback end }
    env.hooksecurefunc = function(object, method, callback)
        local original = object[method]
        object[method] = function(...)
            original(...)
            callback(...)
        end
    end
    for _, name in ipairs({ "BuffFrame", "MinimapCluster", "PlayerFrame", "TargetFrame" }) do
        env[name] = Object()
        env[name]:SetPoint("TOPRIGHT", env.UIParent, "TOPRIGHT", -20, name == "TargetFrame" and -100 or -5)
    end
    env.DebuffFrame = Object()
    env.DebuffFrame:SetPoint("TOPRIGHT", env.BuffFrame, "BOTTOMRIGHT", 0, -5)
    env.GetMaxPlayerLevel = function() return state.maxLevel end
    env.GetMoney = function() return state.money end
    env.GetZoneText = function() return state.zone end
    env.GetSubZoneText = function() return state.subzone end
    env.C_Map = {
        GetBestMapForUnit = function() return state.map end,
        GetPlayerMapPosition = function()
            if state.x then return { x = state.x, y = state.y } end
        end,
    }
    env.Enum = { BagIndex = { Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5 } }
    env.C_Container = {
        GetContainerNumSlots = function(id)
            state.bagCalls[id] = true
            return state.slots[id]
        end,
        GetContainerNumFreeSlots = function(id) return state.free[id], 0 end,
    }
    env.GetInventoryItemDurability = function(slot)
        local item = state.durability[slot]
        if item then return unpack(item) end
    end
    env.print = function(message) state.messages[#state.messages + 1] = message end
    for name, value in pairs(options) do env[name] = value end
    local addon = {}
    for line in io.lines("Topline.toc") do
        if line:match("%.lua$") then
            local chunk = assert(loadfile((line:gsub("\\", "/"))))
            setfenv(chunk, env)("Topline", addon)
        end
    end
    local function Drain()
        local iterations = 0
        while #state.timers > 0 do
            iterations = iterations + 1
            assert(iterations < 20, "Runaway deferred callbacks")
            local pending = state.timers
            state.timers = {}
            for _, callback in ipairs(pending) do callback() end
        end
    end
    function state:event(event, ...)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] then frame.scripts.OnEvent(frame, event, ...) end
        end
    end
    function state:refresh(event, ...)
        self:event(event, ...)
        Drain()
    end
    function state:tick(seconds)
        self.now = self.now + seconds
        for _, ticker in ipairs(self.tickers) do if not ticker.cancelled then ticker.callback() end end
        Drain()
    end
    state.drain = Drain
    state:refresh("PLAYER_LOGIN")
    local modules = {}
    for _, module in ipairs(addon.modules) do modules[module.name] = module end
    return state, addon, modules, env
end

local state, addon, modules = NewSession()
equal(#addon.modules, 8, "Eight requested providers load")
equal(addon.modules[1].name, "Zone")
equal(addon.modules[5].name, "Durability")
equal(addon.bar.parent ~= nil, true)
equal(addon.bar.height, 20)
equal(addon.background.horizontalWrap, "REPEAT", "Repeat the material instead of stretching it")
equal(addon.background.texCoords[2], 12, "Preserve the texture aspect ratio at 1920 UI units")
equal(addon.bar.points[1][1], "TOPLEFT")
equal(addon.bar.points[2][1], "TOPRIGHT")
equal(addon.bar.mouse, false)
equal(addon.bottom.height, 3, "Bronze rail retains a readable height")
for _, frame in ipairs(state.frames) do equal(frame.scripts.OnUpdate, nil) end
equal(#state.tickers, 5, "Coordinates, XP, travel, performance, and clock use tickers")
equal(modules.Zone.text, "Zone: Shattrath City - Terrace of Light (57, 30)")
equal(modules.Experience.text, "XP/hr: N/A, Time to Level: N/A")
equal(modules.Gold.text, "|cffe6c5663,198g|r |cffbfc5cd47s|r |cffcf956a57c|r")
equal(modules.Bags.text, "Bags: 78/80")
equal(state.bagCalls[5], nil, "Exclude reagent bag")
equal(modules.Durability.text, "Durability: 60%", "Weight durability by item maximum")

state.xp = 950
state:refresh("PLAYER_XP_UPDATE", "player")
equal(modules.Experience.gained, 50)
equal(modules.Experience.text, "XP/hr: N/A, Time to Level: N/A", "Warmup")
state:tick(60)
equal(modules.Experience.text, "XP/hr: 3.0k, Time to Level: 1m")
state:event("PLAYER_LEVEL_UP", 11)
state.drain()
equal(modules.Experience.gained, 50, "Do not sample stale level-up APIs")
state.level, state.xp, state.cap = 11, 100, 1200
state:refresh("PLAYER_XP_UPDATE", "player")
equal(modules.Experience.gained, 200, "Count XP crossing a level")
state:refresh("PLAYER_XP_UPDATE", "player")
state:refresh("PLAYER_ENTERING_WORLD")
equal(modules.Experience.gained, 200, "Duplicate events/zoning do not reset or double count")
equal(modules.Experience.startXP, 900)
equal(modules.Experience.startedAt, 0)
state.xp = 200
state:refresh("PLAYER_XP_UPDATE", "pet")
equal(modules.Experience.gained, 200, "Ignore non-player XP events")

state.money = 0
state:refresh("PLAYER_MONEY")
equal(modules.Gold.text, "|cffe6c5660g|r |cffbfc5cd0s|r |cffcf956a0c|r")
state.free[0] = 0
state:refresh("BAG_UPDATE_DELAYED")
equal(modules.Bags.text, "Bags: 80/80")
state.slots[4], state.free[4] = 0, 0
state:refresh("PLAYER_EQUIPMENT_CHANGED")
equal(modules.Bags.text, "Bags: 64/64", "Removed bag")
state.durability[1][1] = 100
state:refresh("UPDATE_INVENTORY_DURABILITY")
equal(modules.Durability.text, "Durability: 100%", "Repair event")
state.durability = {}
state:refresh("MERCHANT_CLOSED")
equal(modules.Durability.text, "Durability: N/A")
state.x, state.y = 0.574, 0.306
state:tick(0.5)
equal(modules.Zone.text, "Zone: Shattrath City - Terrace of Light (57, 31)")
state.map = nil
state:tick(0.5)
equal(modules.Zone.text, "Zone: Shattrath City - Terrace of Light", "Missing position")
state.zone, state.subzone = "Stormwind City", "Stormwind City"
state:refresh("ZONE_CHANGED_NEW_AREA")
equal(modules.Zone.text, "Zone: Stormwind City", "No duplicate zone")
state.scale = 1.25
state:refresh("UI_SCALE_CHANGED")
equal(addon.bottom.height, 3)
state.width = 800
state:refresh("DISPLAY_SIZE_CHANGED")
equal(addon.text.fontSize >= 10 and addon.text.fontSize <= 12, true)

-- XP wrap arriving before UnitLevel catches up.
state, addon, modules = NewSession()
state.xp = 100
state:refresh("PLAYER_XP_UPDATE", "player")
equal(modules.Experience.gained, 0)
state.level, state.cap = 11, 1200
state:refresh("PLAYER_LEVEL_UP", 11)
equal(modules.Experience.gained, 200)
-- Reversed event order: fresh XP/level data before PLAYER_LEVEL_UP.
state, addon, modules = NewSession()
state.xp, state.level, state.cap = 100, 11, 1200
state:refresh("PLAYER_XP_UPDATE", "player")
state:refresh("PLAYER_LEVEL_UP", 11)
equal(modules.Experience.gained, 200)
state.xp, state.level, state.cap = 25, 12, 1400
state:refresh("PLAYER_LEVEL_UP", 12)
equal(modules.Experience.gained, 1325, "Consecutive levels with different XP caps")
state.level, state.xp, state.cap = 60, 0, 0
state:refresh("PLAYER_LEVEL_UP", 60)
equal(modules.Experience.text, "XP: Max level")

state, addon, modules = NewSession()
state:tick(3600)
equal(modules.Experience.text, "XP/hr: N/A, Time to Level: N/A", "No XP gained")
state.level, state.xp = 15, 10
state:refresh("PLAYER_LEVEL_UP", 15)
equal(modules.Experience.text, "XP/hr: N/A, Time to Level: N/A", "No invented XP after boost")
equal(modules.Experience.gained, 0)

state, addon, modules = NewSession({ C_Map = false, C_Container = false,
    UnitXP = false, GetMoney = false, GetInventoryItemDurability = false })
equal(modules.Zone.text, "Zone: Shattrath City - Terrace of Light")
equal(modules.Experience.text, "XP/hr: N/A, Time to Level: N/A")
equal(modules.Gold.text, "Gold: N/A")
equal(modules.Bags.text, "Bags: N/A")
equal(modules.Durability.text, "Durability: N/A")
equal(#state.messages, 0, "Missing optional APIs do not throw")

state, addon, modules = NewSession({ GetMoney = function() error("API changed") end })
equal(modules.Gold.text, "Gold: N/A")
equal(modules.Bags.text, "Bags: 78/80", "Other providers survive errors")
state:refresh("PLAYER_MONEY")
equal(#state.messages, 1, "Report provider failure only once")

local env
state, addon, modules, env = NewSession()
local mapAPI = env.C_Map.GetBestMapForUnit
env.C_Map.GetBestMapForUnit = function() error("Temporary map failure") end
state:tick(0.5)
equal(modules.Zone.text, "Zone: N/A")
env.C_Map.GetBestMapForUnit = mapAPI
state:tick(0.5)
equal(modules.Zone.text, "Zone: Shattrath City - Terrace of Light (57, 30)", "Recover without movement")
state.x, state.y = 0, 0
state:tick(0.5)
equal(modules.Zone.text, "Zone: Shattrath City - Terrace of Light", "Omit sentinel coordinates")
state.x, state.y = 0, 0.5
state:tick(0.5)
equal(modules.Zone.text, "Zone: Shattrath City - Terrace of Light (0, 50)", "Valid map edge")

-- Session pedometer: horizontal world distance, including mounted movement.
state, addon, modules = NewSession()
equal(modules.Pedometer.text, "Moved today: 0 yd")
state.speed = 20
state:refresh("PLAYER_STARTED_MOVING")
state.worldX, state.worldY = 103, 104
state:tick(0.25)
equal(modules.Pedometer.total, 5, "3-4-5 world-space segment")
equal(modules.Pedometer.text, "Moved today: 5 yd")
state.speed = 0
state:refresh("PLAYER_STOPPED_MOVING")
state:tick(0.25)
equal(modules.Pedometer.total, 5, "Standing still adds no distance")
state.worldX = 10000
state:tick(0.25)
equal(modules.Pedometer.total, 5, "Teleport rejected")
state.instance, state.worldX = 2, 0
state:tick(0.25)
equal(modules.Pedometer.total, 5, "Instance changes do not join coordinate spaces")
state:refresh("PLAYER_LEAVING_WORLD")
state.speed, state.worldX = 100, 500
state:tick(0.25)
equal(modules.Pedometer.total, 5, "Loading screen skipped")
state:refresh("PLAYER_ENTERING_WORLD")
equal(modules.Pedometer.total, 5, "Zoning preserves session total")
state.taxi, state.worldX = true, 525
state:tick(0.25)
equal(modules.Pedometer.total, 5, "Taxi ignored")
state.taxi, state.vehicle, state.worldX = false, true, 550
state:tick(0.25)
equal(modules.Pedometer.total, 5, "Vehicle ignored")
state.vehicle, state.worldX, state.speed = false, 575, 20
state:tick(0.25)
equal(modules.Pedometer.total, 5, "First position after transport is a new baseline")
state.worldX = 580
state:tick(0.25)
equal(modules.Pedometer.total, 10, "Resume ordinary travel")
state.worldX = 680
state:tick(5)
equal(modules.Pedometer.total, 10, "Long sampling gap skipped")
state, addon, modules = NewSession({ UnitPosition = false })
state.speed = 8
state:refresh("PLAYER_STARTED_MOVING")
state:tick(0.25)
equal(modules.Pedometer.total, 2, "Speed fallback in areas without world positions")
state:tick(0.25)
equal(modules.Pedometer.text, "Moved today: 4 yd")
state, addon, modules = NewSession({ UnitPosition = false, GetUnitSpeed = false })
equal(modules.Pedometer.text, "Moved today: N/A", "Unavailable travel APIs")

-- Default UI clearance uses geometry, not repeated subtraction from saved offsets.
state, addon, modules, env = NewSession()
local function near(actual, expected, message)
    equal(math.abs(actual - expected) < 0.0001, true, message)
end
near(select(5, env.BuffFrame:GetPoint(1)), -22, "Buffs clear the bar and two-unit gap")
near(select(5, env.MinimapCluster:GetPoint(1)), -22, "Minimap clears the bar")
near(select(5, env.PlayerFrame:GetPoint(1)), -22, "Top player frame clears the bar")
equal(select(5, env.TargetFrame:GetPoint(1)), -100, "Already clear frames untouched")
equal(select(2, env.DebuffFrame:GetPoint(1)), env.BuffFrame, "Keep relative anchors")
equal(select(5, env.DebuffFrame:GetPoint(1)), -5, "Dependent frames follow without double shift")
state:refresh("PLAYER_ENTERING_WORLD")
state:refresh("DISPLAY_SIZE_CHANGED")
near(select(5, env.BuffFrame:GetPoint(1)), -22, "Repeated layout events never drift")
env.BuffFrame:SetPoint("TOPRIGHT", env.UIParent, "TOPRIGHT", -20, -5)
state.drain()
near(select(5, env.BuffFrame:GetPoint(1)), -22, "Repair Blizzard re-anchor")
state.combat = true
env.BuffFrame:SetPoint("TOPRIGHT", env.UIParent, "TOPRIGHT", -20, -5)
state.drain()
equal(select(5, env.BuffFrame:GetPoint(1)), -5, "Never move protected frames in combat")
state.combat = false
state:refresh("PLAYER_REGEN_ENABLED")
near(select(5, env.BuffFrame:GetPoint(1)), -22, "Deferred layout after combat")
state.editing = true
env.BuffFrame:SetPoint("TOPRIGHT", env.UIParent, "TOPRIGHT", -20, -5)
state.drain()
equal(select(5, env.BuffFrame:GetPoint(1)), -5, "Do not fight Edit Mode")
state.editing = false
state.callbacks["EditMode.Exit"]()
state.drain()
near(select(5, env.BuffFrame:GetPoint(1)), -22, "Reapply when leaving Edit Mode")
env.BuffFrame:SetPoint("TOPRIGHT", env.UIParent, "TOPRIGHT", -20, -150)
state.drain()
equal(select(5, env.BuffFrame:GetPoint(1)), -150, "Preserve custom positions below strip")
env.BuffFrame:SetScale(1.6)
env.BuffFrame:SetPoint("TOPRIGHT", env.UIParent, "TOPRIGHT", -20, 0)
state.drain()
near(select(5, env.BuffFrame:GetPoint(1)), -11, "Account for independent frame scale")
env.BuffFrame:SetPoint("TOPLEFT", env.UIParent, "TOPLEFT", 20, -11)
env.BuffFrame:SetPoint("TOPRIGHT", env.UIParent, "TOPRIGHT", -20, 0)
state.drain()
equal(env.BuffFrame:GetNumPoints(), 2, "Keep all anchors")
near(select(5, env.BuffFrame:GetPoint(1)), -11, "Multi-anchor translation")
near(select(5, env.BuffFrame:GetPoint(2)), -22, "Multi-anchor frame is not stretched")

-- SavedVariables reload, character isolation, and local-calendar daily history.
local function CopySaved(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do copy[key] = CopySaved(child) end
    return copy
end
state, addon, modules, env = NewSession()
local history, firstDay = addon:GetTravelRecord()
equal(env.ToplineCharDB.version, 1)
equal(history.totalYards, 0)
equal(next(history.days), nil, "No history entries for idle days")
state.speed, state.worldX = 5, 101.25
state:tick(0.25)
equal(history.days[firstDay], 1.25, "Keep fractional daily yards")
equal(history.totalYards, 1.25)
equal(modules.Pedometer.text, "Moved today: 1 yd")
local savedA = CopySaved(env.ToplineCharDB)
state, addon, modules, env = NewSession({ ToplineCharDB = savedA })
history = addon:GetTravelRecord()
equal(modules.Pedometer.text, "Moved today: 1 yd", "Same-day reload restores distance")
equal(modules.Pedometer.total, 0, "Reload starts a fresh position baseline")
state:refresh("PLAYER_ENTERING_WORLD")
equal(history.totalYards, 1.25, "World entry does not double count saved distance")
state.speed, state.worldX = 3, 100.75
state:tick(0.25)
equal(history.days[firstDay], 2, "Accumulate multiple sessions on one day")
equal(history.totalYards, 2)
state:refresh("PLAYER_LOGOUT")
equal(history.totalYards, 2, "No logout accumulator adds distance twice")
-- Cross midnight while standing still; history changes days without movement.
state.wallTime = state.wallTime + 86400
state:tick(0.75)
equal(modules.Pedometer.text, "Moved today: 0 yd", "Live midnight reset")
local _, secondDay = addon:GetTravelRecord()
equal(firstDay ~= secondDay, true)
equal(history.days[firstDay], 2, "Yesterday retained")
equal(history.totalYards, 2, "Lifetime total survives midnight")
state.worldX = 101.25
state:tick(0.25)
equal(history.days[secondDay], 0.5)
equal(history.totalYards, 2.5)
local savedAcrossDays = CopySaved(env.ToplineCharDB)
state, addon, modules, env = NewSession()
equal(modules.Pedometer.text, "Moved today: 0 yd", "Different character starts independently")
equal(env.ToplineCharDB.pedometer.totalYards, 0)
equal(savedAcrossDays.pedometer.totalYards, 2.5, "Other character's data is untouched")
state, addon, modules, env = NewSession({ ToplineCharDB = savedAcrossDays })
state.wallTime = state.wallTime + 4 * 86400
state:refresh("PLAYER_ENTERING_WORLD")
equal(modules.Pedometer.text, "Moved today: 0 yd", "Return after offline days")
equal(env.ToplineCharDB.pedometer.days[firstDay], 2)
equal(env.ToplineCharDB.pedometer.days[secondDay], 0.5)
equal(env.ToplineCharDB.pedometer.totalYards, 2.5)

state, addon, modules, env = NewSession({ ToplineCharDB = { version = 1, pedometer = {
    days = { [firstDay] = 12.5, bad = 1, [secondDay] = -1 }, totalYards = "bad",
} } })
equal(env.ToplineCharDB.pedometer.totalYards, 12.5, "Recover total from valid history")
equal(env.ToplineCharDB.pedometer.days[firstDay], 12.5, "Keep valid history during repair")
equal(env.ToplineCharDB.pedometer.days.bad, nil)
equal(env.ToplineCharDB.pedometer.days[secondDay], nil)
state, addon, modules, env = NewSession({ ToplineCharDB = "invalid" })
equal(env.ToplineCharDB.pedometer.totalYards, 0, "Malformed storage starts cleanly")
local future = { version = 2, pedometer = { totalYards = 123 } }
state, addon, modules, env = NewSession({ ToplineCharDB = future })
equal(modules.Pedometer.text, "Moved today: N/A")
equal(future.version, 2, "Preserve unsupported future schema")
equal(future.pedometer.totalYards, 123)
state, addon, modules, env = NewSession({ date = false })
equal(modules.Pedometer.text, "Moved today: N/A", "Missing calendar API is safe")
equal(#state.messages, 0)
local tocFile = assert(io.open("Topline.toc"))
local toc = tocFile:read("*a")
tocFile:close()
equal(toc:find("## SavedVariablesPerCharacter: ToplineCharDB", 1, true) ~= nil, true,
    "WoW persists data per character")
state, addon, modules, env = NewSession()
equal(addon.background.vertexColor[1], 1, "Artwork is not darkened by the fallback tint")
equal(addon.bottom.texCoords[3], 0.91, "Show the complete bottom metal rail")
equal(addon.topEdge.texCoords[4], 0.085, "Show the top metal rail separately")
equal(modules.Clock.text, "Local 12:00 AM", "Local clock at midnight")
equal(addon.rightText.text:sub(-#modules.Clock.text), modules.Clock.text, "Clock remains last in the right group")
equal(addon.rightText.text:sub(1, #modules.Performance.text), modules.Performance.text, "Performance precedes clock")
equal(addon.text.text:find("Local", 1, true), nil, "Clock is not duplicated in the left group")
equal(addon.text.width + addon.rightText.width + 44 <= addon.bar:GetWidth(), true,
    "Reserve clock width and separation")
state:tick(60)
equal(modules.Clock.text, "Local 12:01 AM", "Clock updates without second-by-second rendering")
state.width = 800
state:refresh("DISPLAY_SIZE_CHANGED")
equal(addon.text.width + addon.rightText.width + 44 <= addon.bar:GetWidth(), true,
    "Narrow layout keeps right-side space reserved")
state, addon, modules = NewSession({ date = false })
equal(modules.Clock.text, "Local: N/A", "Missing clock API degrades gracefully")
-- Model the actual beta failure: native CVars survive, SavedVariables do not.
local nativeValues, nativeWrites = {}, 0
local function ReloadOptions(guid, saved)
    return {
        UnitGUID = function() return guid end,
        GetBuildInfo = function() return "1.60.1", "69977", "", 16001 end,
        ToplineCharDB = saved,
        C_CVar = {
            GetCVar = function(key) return nativeValues[key] end,
            RegisterCVar = function(key, value)
                if nativeValues[key] == nil then nativeValues[key] = value end
            end,
            SetCVar = function(key, value)
                nativeWrites = nativeWrites + 1
                nativeValues[key] = value
            end,
        },
    }
end
state, addon, modules, env = NewSession(ReloadOptions("Player-70-ABC123"))
local _, cacheDay = addon:GetTravelRecord()
local initialWrites = nativeWrites
state.worldX, state.speed = 101.25, 5
state:tick(0.25)
equal(nativeWrites, initialWrites, "Cache serialization is throttled during movement")
state:refresh("PLAYER_LOGOUT")
equal(nativeWrites, initialWrites + 1, "Logout/reload flushes the latest fractional distance")
state, addon, modules, env = NewSession(ReloadOptions("Player-70-ABC123"))
equal(env.ToplineCharDB.pedometer.totalYards, 1.25, "Recover when the client drops all SavedVariables")
equal(modules.Pedometer.text, "Moved today: 1 yd")
state.worldX, state.speed = 100.75, 3
state:tick(0.25)
state:refresh("PLAYER_LOGOUT")
state, addon, modules, env = NewSession(ReloadOptions("Player-70-ABC123"))
equal(env.ToplineCharDB.pedometer.totalYards, 2, "Repeated broken reloads continue accumulating")
state:refresh("PLAYER_LOGOUT")
state, addon, modules, env = NewSession(ReloadOptions("Player-70-ABC123"))
equal(env.ToplineCharDB.pedometer.totalYards, 2, "Restoring the same checkpoint never double counts")
state, addon, modules, env = NewSession(ReloadOptions("Player-70-DEF456"))
equal(env.ToplineCharDB.pedometer.totalYards, 0, "The native cache is isolated by character GUID")
state, addon, modules, env = NewSession(ReloadOptions("Player-70-ABC123", {
    version = 1, pedometer = { totalYards = 100, days = { [cacheDay] = 100 } },
}))
equal(env.ToplineCharDB.pedometer.totalYards, 100, "Older cache cannot roll back newer disk history")
state.wallTime = state.wallTime + 86400
state:tick(0.25)
state.speed, state.worldX = 4, 101
state:tick(0.25)
state:refresh("PLAYER_LOGOUT")
state, addon, modules, env = NewSession(ReloadOptions("Player-70-ABC123"))
equal(env.ToplineCharDB.pedometer.days[cacheDay], 100, "Cached daily history survives midnight")
equal(env.ToplineCharDB.pedometer.totalYards, 101, "Cache preserves the lifetime total")
nativeValues.ToplineTravel_Player_70_ABC123 = "1|999|2026-09-23=123|invalid"
state, addon, modules, env = NewSession(ReloadOptions("Player-70-ABC123"))
equal(env.ToplineCharDB.pedometer.totalYards, 0, "Malformed cache is rejected atomically")
equal(next(env.ToplineCharDB.pedometer.days), nil)
nativeValues = {}
state, addon, modules, env = NewSession(ReloadOptions("Player-70-ABC123"))
equal(env.ToplineCharDB.pedometer.totalYards, 0, "Cold start still requires the disk loader")
local brokenCacheOptions = ReloadOptions("Player-70-ABC123")
brokenCacheOptions.C_CVar.SetCVar = function(key, value) nativeValues[key] = value:sub(1, 2) end
state, addon, modules, env = NewSession(brokenCacheOptions)
equal(#state.messages, 1, "Warn if native storage silently truncates data")
state:refresh("PLAYER_LOGOUT")
equal(#state.messages, 1, "Cache failures do not spam chat")
equal(modules.Bags.text, "Bags: 78/80", "Native cache failure does not break other providers")
-- Hover lifecycle, live data, kill parsing, and independent provider failures.
state, addon, modules, env = NewSession()
local function Row(label)
    for _, line in ipairs(addon.infoTooltip.lines) do
        if line[1] == label then return line[2] end
    end
end
local function Hover(name)
    local region = modules[name].hoverFrame
    region.scripts.OnEnter(region)
end
for name, module in pairs(modules) do
    equal(module.hoverFrame.mouse, name == "Experience", name .. " click handling")
    equal(module.hoverFrame.mouseMotion, true)
    Hover(name)
    equal(addon.infoTooltip.shown, true)
    equal(addon.infoTooltip.lines[2][1] ~= "Details currently unavailable.", true, name .. " tooltip renders")
end
Hover("Experience")
equal(Row("Kills to level (last kill)"), "Unknown")
equal(Row("XP gains to level (last gain)"), "Unknown")
equal(Row("Rested XP available"), "500")
equal(Row("XP/hour this session"), "N/A")
state:refresh("CHAT_MSG_COMBAT_XP_GAIN", "Unit 9000 dies, you gain 25 experience. (+5 group bonus)")
equal(modules.Experience.lastKillXP, 25, "Digits in creature names are not XP")
equal(modules.Experience.gained, 0, "Kill chat never double counts XP")
state.xp = 925
state:refresh("PLAYER_XP_UPDATE", "player")
state:tick(60)
equal(Row("Time played this session"), "1m 0s")
equal(Row("Kills to level (last kill)"), "3")
equal(Row("XP gains to level (last gain)"), "3")
equal(Row("XP/hour this session"), "1,500")
equal(Row("Time to level (session rate)"), "3m 0s")
state:refresh("CHAT_MSG_COMBAT_XP_GAIN", "Quest Example rewards 500 experience.")
equal(modules.Experience.lastKillXP, 25, "Quest messages do not become kills")
state.xp, state.level, state.cap = 25, 11, 1200
state:refresh("PLAYER_XP_UPDATE", "player")
addon:RefreshInfoTooltip()
equal(Row("Last XP gain"), "100", "XP award across level boundary")
equal(Row("XP gains to level (last gain)"), "12", "Round remaining gains up")
local ticker = addon.tooltipTicker
modules.Experience.hoverFrame.scripts.OnLeave()
equal(addon.infoTooltip.shown, false)
equal(ticker.cancelled, true, "Stop tooltip polling on leave")
equal(addon.tooltipTicker, nil)
Hover("Clock")
equal(Row("Realm time"), "18:30")
equal(select(1, addon.infoTooltip:GetPoint(1)), "TOPRIGHT", "Right tooltip expands inward")
Hover("Pedometer")
equal(Row("All recorded travel"), "0 yd")
equal(next(env.ToplineCharDB.pedometer.days), nil, "Hover does not create history")
Hover("Durability")
equal(Row("Slot 1"), "50 / 100 (50%)")
Hover("Bags")
equal(Row("Backpack"), "14 / 16 (2 free)")
modules.Bags.tooltip = function() error("broken provider") end
addon:RefreshInfoTooltip()
equal(addon.infoTooltip.lines[2][1], "Details currently unavailable.")
Hover("Zone")
equal(Row("Zone"), "Shattrath City", "Next tooltip survives provider error")
state.width = 500
state:refresh("DISPLAY_SIZE_CHANGED")
equal(modules.Pedometer.hoverFrame.shown, false, "Clipped text has no stray hover region")
equal(modules.Clock.hoverFrame.shown, true)
equal(modules.Experience.hoverFrame.width <= addon.text.width, true)
state, addon, modules = NewSession({ COMBATLOG_XPGAIN_FIRSTPERSON = "%2$d XP from %1$s." })
equal(modules.Experience.ParseKillXP("42 XP from Unit 9000."), 42, "Localized positional placeholders")
state, addon, modules = NewSession({ UnitXP = false, GetXPExhaustion = false })
Hover("Experience")
equal(addon.infoTooltip.lines[6][1], "XP information unavailable.")
state, addon, modules = NewSession()
state.level, state.cap = 60, 0
Hover("Experience")
equal(addon.infoTooltip.lines[6][1], "Maximum level reached.")
-- Lua 5.1 has no secret values. An opaque sentinel plus an overridden type()
-- models the key failure: a value can report "number" yet reject arithmetic.
local secret = setmetatable({}, {
    __lt = function() error("secret comparison") end,
    __le = function() error("secret comparison") end,
    __sub = function() error("secret arithmetic") end,
})
local function SecretOptions(accessOnly)
    return {
        type = function(value) if rawequal(value, secret) then return "number" end return type(value) end,
        issecretvalue = not accessOnly and function(value) return rawequal(value, secret) end or false,
        canaccessvalue = function(value) return not rawequal(value, secret) end,
    }
end
for _, field in ipairs({ "speed", "worldX", "worldY", "instance", "taxi", "vehicle" }) do
    state, addon, modules, env = NewSession(SecretOptions(field == "speed"))
    state.speed, state.worldX = 8, 102
    state:tick(0.25)
    local prior = state[field]
    state[field] = secret
    state:tick(0.25)
    equal(#state.messages, 0, field .. " restriction produces no provider error")
    equal(modules.Pedometer.total, 2, "Keep earned distance")
    equal(modules.Pedometer.text, "Moved today: 2 yd")
    equal(modules.Pedometer.time, nil, "Clear sampling baseline")
    equal(env.ToplineCharDB.pedometer.totalYards, 2, "Never save restricted data")
    state[field] = prior
    state.worldX = 104
    state:tick(0.25)
    equal(modules.Pedometer.total, 2, "Do not connect positions across restricted gap")
    state.worldX = 106
    state:tick(0.25)
    equal(modules.Pedometer.total, 4, "Resume on ordinary samples")
end
state, addon, modules, env = NewSession(SecretOptions())
env.UnitPosition = false
state.speed = secret
state:tick(0.25)
equal(#state.messages, 0, "Restricted speed cannot enter the fallback estimator")
equal(modules.Pedometer.total, 0)
state.speed = 8
state:tick(0.25)
state:tick(0.25)
equal(modules.Pedometer.total, 2, "Speed fallback resumes after restriction")
-- Right-click opens a menu; only choosing Reset session mutates XP tracking.
state, addon, modules, env = NewSession()
env.MenuUtil = { CreateContextMenu = function(owner, generator)
    state.menuOwner = owner
    state.menu = {}
    generator(owner, {
        CreateTitle = function(_, text) state.menu.title = text end,
        CreateButton = function(_, text, callback) state.menu.label, state.menu.reset = text, callback end,
    })
end }
state.xp = 950
state:refresh("PLAYER_XP_UPDATE", "player")
state:refresh("CHAT_MSG_COMBAT_XP_GAIN", "Wolf dies, you gain 50 experience.")
state:tick(120)
addon:RecordTravel(123)
local xpRegion = modules.Experience.hoverFrame
xpRegion.scripts.OnMouseUp(xpRegion, "LeftButton")
equal(state.menu, nil, "Left click does not open reset menu")
Hover("Experience")
local hoverTicker = addon.tooltipTicker
xpRegion.scripts.OnMouseUp(xpRegion, "RightButton")
equal(state.menuOwner, xpRegion)
equal(state.menu.label, "Reset session")
equal(hoverTicker.cancelled, true)
equal(modules.Experience.gained, 50, "Opening or dismissing menu does not reset")
state.menu.reset()
state.drain()
equal(modules.Experience.gained, 0)
equal(modules.Experience.startedAt, 120)
equal(modules.Experience.startXP, 950)
equal(modules.Experience.lastGain, nil)
equal(modules.Experience.lastKillXP, nil)
equal(modules.Experience.text, "XP/hr: N/A, Time to Level: N/A")
equal(env.ToplineCharDB.pedometer.totalYards, 123, "XP reset preserves travel history")
state.xp = 975
state:refresh("PLAYER_XP_UPDATE", "player")
state:tick(60)
equal(modules.Experience.gained, 25)
equal(modules.Experience.text, "XP/hr: 1.5k, Time to Level: 1m")
-- Reset while a level-up sample is pending: stale APIs cannot become baseline.
state:event("PLAYER_LEVEL_UP", 11)
state.menu.reset()
equal(modules.Experience.text, "XP/hr: N/A, Time to Level: N/A")
state.level, state.xp, state.cap = 11, 20, 1200
state.drain()
equal(modules.Experience.startXP, 20)
equal(modules.Experience.gained, 0)
state.xp = 30
state:refresh("PLAYER_XP_UPDATE", "player")
equal(modules.Experience.gained, 10)
modules.Experience.incomplete = true
state.menu.reset()
equal(modules.Experience.incomplete, nil, "Reset recovers incomplete sessions")
env.UnitXP = false
state.menu.reset()
equal(modules.Experience.text, "XP/hr: N/A, Time to Level: N/A", "Unavailable APIs remain safe")
env.MenuUtil = false
xpRegion.scripts.OnMouseUp(xpRegion, "RightButton")
equal(#state.messages, 0)
-- Performance uses a low-frequency ticker and preserves independently usable values.
state, addon, modules, env = NewSession()
equal(modules.Performance.interval, 2)
equal(modules.Performance.text, "|cffc7c7c7144 FPS|r  |cff666b73|||r  |cffc7c7c732 ms|r")
Hover("Performance")
equal(Row("Home latency"), "24 ms")
equal(Row("World latency"), "32 ms")
state.fps, state.homeLatency, state.worldLatency = 45, 200, 50
state:tick(2)
equal(modules.Performance.text, "|cffd6b36945 FPS|r  |cff666b73|||r  |cffd6b369200 ms|r")
equal(Row("Frame rate"), "45.0 FPS", "Hovered details follow samples")
state.fps, state.worldLatency = 20, 400
state:tick(2)
equal(modules.Performance.text, "|cffd9827920 FPS|r  |cff666b73|||r  |cffd98279400 ms|r")
state.fps, state.homeLatency, state.worldLatency = 60, 0, 0
state:tick(2)
equal(modules.Performance.text, "|cffc7c7c760 FPS|r  |cff666b73|||r  |cffc7c7c70 ms|r", "Zero latency is valid")
env.GetFramerate = false
state:tick(2)
equal(modules.Performance.fps, nil)
equal(modules.Performance.world, 0, "Missing FPS does not hide latency")
env.GetFramerate = function() return 120 end
env.GetNetStats = function() error("Unavailable") end
state:tick(2)
equal(modules.Performance.fps, 120)
equal(modules.Performance.home, nil)
equal(#state.messages, 0, "Temporary API errors do not spam chat")
env.GetNetStats = function() return 0, 0, -1, 50 end
state:tick(2)
equal(modules.Performance.home, nil)
equal(modules.Performance.world, 50)
env.issecretvalue = function(value) return rawequal(value, secret) end
env.GetFramerate = function() return secret end
env.GetNetStats = function() return 0, 0, secret, 70 end
state:tick(2)
equal(modules.Performance.fps, nil)
equal(modules.Performance.home, nil)
equal(modules.Performance.world, 70)
equal(#state.messages, 0, "Restricted metrics are never compared or formatted")
env.issecretvalue = false
env.GetFramerate = function() return 30 end
env.GetNetStats = function() return 0, 0, 150, 150 end
state:tick(2)
equal(modules.Performance.text, "|cffd6b36930 FPS|r  |cff666b73|||r  |cffd6b369150 ms|r", "Warning boundaries")
env.GetNetStats = function() return 0, 0, 300, 300 end
state:tick(2)
equal(modules.Performance.text:find("|cffd98279300 ms|r", 1, true) ~= nil, true, "Critical latency boundary")
env.GetFramerate = function() return 0/0 end
env.GetNetStats = function() return 0, 0, math.huge, -1 end
state:tick(2)
equal(modules.Performance.fps, nil)
equal(modules.Performance.home, nil)
equal(modules.Performance.world, nil)
state, addon, modules = NewSession({ GetFramerate = false, GetNetStats = false })
equal(modules.Performance.text, "|cffc7c7c7N/A FPS|r  |cff666b73|||r  |cffc7c7c7N/A ms|r")
print("Topline: " .. checks .. " offline checks passed (" .. _VERSION .. ").")
