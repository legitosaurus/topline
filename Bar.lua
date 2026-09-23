local _, Topline = ...
local pieces = {}
local separator = "  |cff666b73" .. "||" .. "|r  "

function Topline:CreateBar()
    local bar = CreateFrame("Frame", "ToplineBar", UIParent)
    self.bar = bar
    bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
    bar:SetHeight(20)
    bar:SetFrameStrata("HIGH")
    bar:EnableMouse(false)

    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.075, 0.07, 0.06, 0.98)
    -- Warm charcoal bevel, with a solid fallback for missing gradient helpers.
    if background.SetGradient and CreateColor then
        background:SetTexture("Interface\\Buttons\\WHITE8X8")
        background:SetGradient("VERTICAL",
            CreateColor(0.025, 0.028, 0.034, 0.98),
            CreateColor(0.13, 0.115, 0.085, 0.98))
    end

    local top = bar:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetColorTexture(0.66, 0.51, 0.27, 0.65)
    self.topEdge = top

    local bottom = bar:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetColorTexture(0.55, 0.40, 0.19, 0.9)
    self.bottom = bottom

    local inner = bar:CreateTexture(nil, "BORDER")
    inner:SetColorTexture(0.85, 0.68, 0.38, 0.16)
    self.innerEdge = inner

    local shadow = bar:CreateTexture(nil, "BACKGROUND")
    shadow:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0)
    shadow:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    shadow:SetColorTexture(0, 0, 0, 0.45)
    self.edgeShadow = shadow

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", 10, 0)
    text:SetPoint("RIGHT", -10, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(false)
    text:SetNonSpaceWrap(false)
    text:SetTextColor(0.84, 0.86, 0.89)
    text:SetShadowColor(0, 0, 0, 0.75)
    text:SetShadowOffset(1, -1)
    self.text = text
    self.fontPath = select(1, text:GetFont()) or STANDARD_TEXT_FONT
    bar:SetScript("OnSizeChanged", function() self:RequestRender() end)
    self:UpdateBarScale()
end

function Topline:UpdateBarScale()
    if not self.bar then return end
    -- Inherit UIParent scale for the strip/font; keep the trim at one pixel.
    local scale = self.bar:GetEffectiveScale()
    local pixel = 1 / math.max(scale, 0.01)
    self.bottom:SetHeight(pixel)
    self.topEdge:SetHeight(pixel)
    self.innerEdge:SetHeight(pixel)
    self.innerEdge:SetPoint("BOTTOMLEFT", self.bar, "BOTTOMLEFT", 0, pixel)
    self.innerEdge:SetPoint("BOTTOMRIGHT", self.bar, "BOTTOMRIGHT", 0, pixel)
    self.edgeShadow:SetHeight(pixel)
    self:RequestRender()
    if self.RequestLayout then self:RequestLayout() end
end

function Topline:RenderBar()
    if not self.text then return end
    for index, module in ipairs(self.modules) do
        pieces[index] = module.text
    end
    self.text:SetFont(self.fontPath, 12, "")
    self.text:SetText(table.concat(pieces, separator))
    local available = self.bar:GetWidth() - 20
    local width = self.text:GetUnboundedStringWidth()
    if available > 0 and width > available then
        -- Preserve a single readable line on small windows/high UI scales.
        self.text:SetFont(self.fontPath, math.max(10, 12 * available / width), "")
    end
end
