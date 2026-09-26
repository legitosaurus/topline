local _, Topline = ...
local pieces, rightPieces = {}, {}
local separator = "  |cff666b73" .. "||" .. "|r  "
local material = "Interface\\AddOns\\Topline\\Media\\StatusStrip.tga"

local function SetMaterial(texture, r, g, b)
    if texture:SetTexture(material, "REPEAT", "CLAMP") then
        -- SetColorTexture/fallback fills must not tint the subsequently loaded art.
        texture:SetVertexColor(1, 1, 1, 1)
    else
        texture:SetColorTexture(r, g, b, 1)
    end
end

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
    SetMaterial(background, 0.075, 0.07, 0.06)
    self.background = background

    local top = bar:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    SetMaterial(top, 0.55, 0.40, 0.19)
    self.topEdge = top

    local bottom = bar:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    SetMaterial(bottom, 0.55, 0.40, 0.19)
    self.bottom = bottom

    local shadow = bar:CreateTexture(nil, "BACKGROUND")
    shadow:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0)
    shadow:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    shadow:SetColorTexture(0, 0, 0, 0.45)
    self.edgeShadow = shadow

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", 10, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(false)
    text:SetNonSpaceWrap(false)
    text:SetTextColor(0.84, 0.86, 0.89)
    text:SetShadowColor(0, 0, 0, 0.75)
    text:SetShadowOffset(1, -1)
    self.text = text
    self.fontPath = select(1, text:GetFont()) or STANDARD_TEXT_FONT

    local right = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    right:SetPoint("RIGHT", -10, 0)
    right:SetJustifyH("RIGHT")
    right:SetJustifyV("MIDDLE")
    right:SetWordWrap(false)
    right:SetNonSpaceWrap(false)
    right:SetTextColor(0.90, 0.80, 0.58)
    right:SetShadowColor(0, 0, 0, 0.9)
    right:SetShadowOffset(1, -1)
    right:SetFont(self.fontPath, 12, "")
    self.rightText = right
    bar:SetScript("OnSizeChanged", function()
        self:UpdateBarTexture()
        self:RequestRender()
    end)
    self:UpdateBarScale()
end

function Topline:UpdateBarTexture()
    if not self.background then return end
    local repeats = math.max(1, self.bar:GetWidth()) / 160
    -- Sample leather and metal separately so the border survives the thin bar.
    self.background:SetTexCoord(0, repeats, 0.10, 0.90)
    self.topEdge:SetTexCoord(0, repeats, 0, 0.085)
    self.bottom:SetTexCoord(0, repeats, 0.91, 1)
end

function Topline:UpdateBarScale()
    if not self.bar then return end
    -- Keep the metal rails visible and the outside shadow one physical pixel.
    local scale = self.bar:GetEffectiveScale()
    local pixel = 1 / math.max(scale, 0.01)
    self.topEdge:SetHeight(math.max(2, pixel))
    self.bottom:SetHeight(math.max(3, pixel))
    self.edgeShadow:SetHeight(pixel)
    self:UpdateBarTexture()
    self:RequestRender()
    if self.RequestLayout then self:RequestLayout() end
end

function Topline:RenderBar()
    if not self.text then return end
    local leftCount, rightCount = 0, 0
    for _, module in ipairs(self.modules) do
        if module.text ~= "" then
            if module.side == "right" then
                rightCount = rightCount + 1
                rightPieces[rightCount] = module.text
            else
                leftCount = leftCount + 1
                pieces[leftCount] = module.text
            end
        end
    end
    self.rightText:SetText(table.concat(rightPieces, separator, 1, rightCount))
    local rightWidth = self.rightText:GetUnboundedStringWidth()
    self.rightText:SetWidth(rightWidth)
    self.text:SetFont(self.fontPath, 12, "")
    self.text:SetText(table.concat(pieces, separator, 1, leftCount))
    local available = self.bar:GetWidth() - 20 - (rightCount > 0 and rightWidth + 24 or 0)
    self.text:SetWidth(math.max(1, available))
    local width = self.text:GetUnboundedStringWidth()
    if available > 0 and width > available then
        -- Preserve a single readable line on small windows/high UI scales.
        self.text:SetFont(self.fontPath, math.max(10, 12 * available / width), "")
    end
    self:LayoutHoverRegions(separator, math.max(0, available), rightWidth)
end
