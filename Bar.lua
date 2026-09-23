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
    background:SetColorTexture(0.035, 0.04, 0.05, 0.94)

    local bottom = bar:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetColorTexture(0.55, 0.59, 0.65, 0.22)
    self.bottom = bottom

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
    -- Inherit UIParent scale for the strip/font; keep the bottom rule one pixel.
    local scale = self.bar:GetEffectiveScale()
    self.bottom:SetHeight(1 / math.max(scale, 0.01))
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
