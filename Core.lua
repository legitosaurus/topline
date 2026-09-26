local _, Topline = ...

Topline.modules = {}
local byName, listeners = {}, {}
local frame = CreateFrame("Frame")
local started, renderPending = false, false

function Topline:GetModule(name)
    return byName[name]
end

function Topline:RegisterModule(name, module)
    assert(not started and not byName[name], "Topline: duplicate or late module registration")
    module.name = name
    module.defaultSide = module.side == "right" and "right" or "left"
    module.text = name .. ": N/A"
    byName[name] = module
    self.modules[#self.modules + 1] = module
end

-- Share one deferred layout pass when several values change together.
function Topline:RequestRender()
    if renderPending then return end
    if not (C_Timer and C_Timer.After) then
        self:RenderBar()
        return
    end
    renderPending = true
    C_Timer.After(0, function()
        renderPending = false
        self:RenderBar()
    end)
end

function Topline:RefreshModule(module, event, ...)
    local ok, value = pcall(module.update, module, event, ...)
    if not ok then
        -- A missing/broken API in one provider must not stop the other items.
        if not module.warned then
            module.warned = true
            print("Topline: " .. module.name .. " unavailable: " .. tostring(value))
        end
        value = module.name .. ": N/A"
    end
    if type(value) == "string" and value ~= module.text then
        module.text = value
        self:RequestRender()
    end
end

local function Start()
    if started then return end
    started = true
    table.sort(Topline.modules, function(a, b) return a.order < b.order end)
    Topline:InitializeSettings()
    Topline:CreateBar()
    Topline:InitializeLayout()
    for _, module in ipairs(Topline.modules) do
        for _, event in ipairs(module.events or {}) do
            if not listeners[event] then
                listeners[event] = {}
                -- Unknown optional events should not prevent addon startup.
                pcall(frame.RegisterEvent, frame, event)
            end
            local list = listeners[event]
            list[#list + 1] = module
        end
        Topline:RefreshModule(module, "INITIALIZE")
        if module.interval and C_Timer and C_Timer.NewTicker then
            module.ticker = C_Timer.NewTicker(module.interval, function()
                Topline:RefreshModule(module, "TICK")
            end)
        end
    end
    Topline:RenderBar()
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        Start()
    elseif started then
        if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
            Topline:UpdateBarScale()
        elseif event == "PLAYER_ENTERING_WORLD" then
            for _, module in ipairs(Topline.modules) do
                Topline:RefreshModule(module, event, ...)
            end
        else
            local list = listeners[event]
            if list then
                for _, module in ipairs(list) do
                    Topline:RefreshModule(module, event, ...)
                end
            end
        end
    end
end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UI_SCALE_CHANGED")
frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
