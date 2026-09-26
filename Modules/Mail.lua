local _, Topline = ...
local label = "|TInterface\\Icons\\INV_Letter_15:14:14:0:0|t Mail"

local function IsRestricted(value)
    return (issecretvalue and issecretvalue(value))
        or (canaccessvalue and not canaccessvalue(value))
end

Topline:RegisterModule("Mail", {
    order = 95,
    side = "right",
    events = { "UPDATE_PENDING_MAIL", "MAIL_INBOX_UPDATE", "MAIL_CLOSED" },
    update = function()
        if not HasNewMail then return "" end
        local ok, waiting = pcall(HasNewMail)
        if not ok or IsRestricted(waiting) then return "" end
        return waiting and label or ""
    end,
    tooltip = function(self, tip)
        tip:AddLine("Mail waiting", 1, 0.82, 0)
        tip:AddLine("Visit a mailbox to read your mail.", 0.9, 0.9, 0.9)
        if not GetLatestThreeSenders then return end
        local ok, first, second, third = pcall(GetLatestThreeSenders)
        if not ok then return end
        local heading = false
        local function AddSender(sender)
            if IsRestricted(sender) or type(sender) ~= "string" or sender == "" then return end
            if not heading then
                tip:AddLine(" ")
                tip:AddLine("Recent senders", 1, 0.82, 0)
                heading = true
            end
            -- Sender names are text, never tooltip texture/link markup.
            tip:AddLine((sender:gsub("|", "||")), 0.9, 0.9, 0.9)
        end
        AddSender(first)
        AddSender(second)
        AddSender(third)
    end,
})
