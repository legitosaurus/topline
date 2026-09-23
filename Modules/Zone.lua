local _, Topline = ...
local floor = math.floor

Topline:RegisterModule("Zone", {
    order = 10,
    events = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" },
    interval = 0.5,
    update = function(self, event)
        if event ~= "TICK" or not self.label then
            local zone = GetZoneText and GetZoneText() or ""
            local subzone = GetSubZoneText and GetSubZoneText() or ""
            self.label = "Zone: " .. (zone ~= "" and zone or "Unknown")
            if subzone ~= "" and subzone ~= zone then
                self.label = self.label .. " - " .. subzone
            end
            self.changed = true
        end

        local x, y
        if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
            local mapID = C_Map.GetBestMapForUnit("player")
            local position = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
            if position then
                local px, py = position.x, position.y
                if type(px) == "number" and type(py) == "number"
                    and px >= 0 and px <= 1 and py >= 0 and py <= 1
                    and (px ~= 0 or py ~= 0) then
                    x, y = floor(px * 100 + 0.5), floor(py * 100 + 0.5)
                end
            end
        end
        if self.changed or x ~= self.x or y ~= self.y then
            self.changed, self.x, self.y = false, x, y
            self.cachedText = self.label .. (x and string.format(" (%d, %d)", x, y) or "")
        end
        return self.cachedText
    end,
})
