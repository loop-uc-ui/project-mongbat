local NAME = "MongbatMapFindWindow"
local SCROLL_NAME = NAME .. "Scroll"
local SCROLL_CHILD = SCROLL_NAME .. "ScrollChild"
local ITEM_PREFIX = SCROLL_CHILD .. "Item"

local PADDING = 8
local SEARCH_H = 28
local TOTAL_H = 18
local ITEM_H = 22

local Api = Mongbat.Api
local Data = Mongbat.Data
local Constants = Mongbat.Constants
local Components = Mongbat.Components
local Utils = Mongbat.Utils

--- Returns the display name for a facet index.
---@param map number Facet index (0=Felucca, 1=Trammel, etc.)
---@return string
local function getFacetName(map)
    local names = {
        [0] = "Felucca",
        [1] = "Trammel",
        [2] = "Ilshenar",
        [3] = "Malas",
        [4] = "Tokuno",
        [5] = "Ter Mur",
    }
    return names[map] or "Unknown"
end

local function OnInitialize()
    local mapFind = Components.Defaults.MapFind
    mapFind:disable()

    --- Currently stored search results.
    ---@type table[]
    local items = {}
    --- Label views for the current result rows.
    ---@type Label[]
    local itemViews = {}
    local totalItems = 0

    --- Destroys all current result row views and resets state.
    local function clearItemList()
        Utils.Array.ForEach(items, function(_, i)
            Api.Window.Destroy(ITEM_PREFIX .. i)
        end)
        items = {}
        itemViews = {}
        totalItems = 0
    end

    --- Creates a single result row label at position i.
    ---@param i number Row index (1-based).
    ---@param itemData table Waypoint data table.
    ---@return Label
    local function createItemRow(i, itemData)
        local mapName = getFacetName(itemData.Map)
        local displayText = L"[" .. towstring(mapName) .. L"] " .. towstring(tostring(itemData.Name))

        local row = Components.Label {
            Name = ITEM_PREFIX .. i,
            OnInitialize = function(self)
                self:setText(displayText)
                self:setDimensions(250, ITEM_H)
            end,
            OnLButtonUp = function(self)
                local x = tonumber(itemData.x)
                local y = tonumber(itemData.y)
                if x and y then
                    Api.Map.CenterOnLocation(x, y, itemData.Map)
                    Components.Defaults.MapWindow:getDefault().CenterOnPlayer = false
                    Api.Radar.SetCenterOnPlayer(false)
                end
            end,
            OnMouseOver = function(self)
                local desc = getFacetName(itemData.Map)
                    .. " x: " .. tostring(itemData.x)
                    .. " y: " .. tostring(itemData.y)
                    .. " z: " .. tostring(itemData.z)
                Api.ItemProperties.SetActiveItem({
                    windowName = self:getName(),
                    itemId     = i,
                    itemType   = Constants.ItemPropertyType.WStringData,
                    title      = towstring(tostring(itemData.Name)),
                    body       = towstring(desc),
                })
            end,
            OnMouseOverEnd = function(self)
                Api.ItemProperties.ClearMouseOverItem()
            end,
        }

        row:create(false)
        row:setParent(SCROLL_CHILD)
        row:onInitialize()
        row:clearAnchors()

        if i == 1 then
            row:addAnchor("topleft", SCROLL_CHILD, "topleft", 0, 0)
        else
            row:addAnchor("topleft", ITEM_PREFIX .. (i - 1), "bottomleft", 0, 0)
        end
        row:addAnchor("topright", SCROLL_NAME, "topright", -20, 0)

        return row
    end

    --- Counts the display total label text.
    ---@param count number
    ---@return wstring
    local function makeTotalText(count)
        if count == 0 then
            return L""
        end
        return towstring(count) .. L" result(s)"
    end

    ---@type Label
    local totalLabel

    --- Runs the search: filters built-in and user waypoints by lowercase name match,
    --- then populates the result list.
    ---@param text wstring The search text entered by the player.
    local function searchText(text)
        clearItemList()

        if not text or text == L"" then
            if totalLabel then
                totalLabel:setText(L"")
            end
            Api.ScrollWindow.UpdateScrollRect(SCROLL_NAME)
            return
        end

        local textStr = Utils.String.Lower(text)

        -- Search built-in waypoints across all facets.
        local waypointsData = Data.Waypoints()
        if waypointsData and waypointsData.Facet then
            Utils.Table.ForEach(waypointsData.Facet, function(map, array)
                Utils.Array.ForEach(array, function(waypoint, idx)
                    if Utils.String.Find(Utils.String.Lower(tostring(waypoint.Name)), textStr) then
                        if Api.Waypoint.GetInfoAt(idx, map) ~= nil then
                            local wp = Utils.Table.Copy(waypoint)
                            wp.Map = map
                            Utils.Array.Add(items, wp)
                        end
                    end
                end)
            end)
        end

        -- Search user-created waypoints (type 15 = custom).
        local waypointList = Data.WaypointList()
        local wpCount = waypointList:getCount()
        local lowerText = Utils.String.Lower(text)
        for waypointId = 1, wpCount do
            local wtype, _, wname, wfacet, wx, wy, wz = Api.Waypoint.GetInfo(waypointId)
            if wtype == 15 then
                local mapCommon = Components.Defaults.MapCommon:getDefault()
                local data = mapCommon.GetWPDataFromString(wname, wtype, wfacet)
                if data then
                    local wp = {
                        x    = wx,
                        y    = wy,
                        z    = wz,
                        type = data.type,
                        Name = tostring(data.name),
                        Map  = data.facet,
                    }
                    if Utils.String.Find(Utils.String.Lower(wname), lowerText) then
                        Utils.Array.Add(items, wp)
                    end
                end
            end
        end

        -- Build result rows.
        totalItems = #items
        Utils.Array.ForEach(items, function(itemData, i)
            itemViews[i] = createItemRow(i, itemData)
        end)

        -- Update total label and scroll rect.
        if totalLabel then
            totalLabel:setText(makeTotalText(totalItems))
        end
        Api.ScrollWindow.UpdateScrollRect(SCROLL_NAME)
    end

    --- Clears results and resets the search box text.
    local filterInput

    local function reset()
        clearItemList()
        if totalLabel then
            totalLabel:setText(L"")
        end
        if filterInput then
            filterInput:clear()
        end
        Api.ScrollWindow.UpdateScrollRect(SCROLL_NAME)
    end

    -- Build the total-count label.
    totalLabel = Components.Label {
        Name = NAME .. "TotalLabel",
        OnInitialize = function(self)
            self:setDimensions(200, TOTAL_H)
        end,
    }

    -- Build the search FilterInput.
    filterInput = Components.FilterInput {
        Name = NAME .. "SearchBox",
        OnInitialize = function(self)
            self:setDimensions(200, SEARCH_H)
        end,
        OnTextChanged = function(self, text)
            searchText(text)
        end,
        OnKeyEscape = function(self)
            reset()
        end,
    }

    -- Main window.
    Components.Window({
        Name = NAME,
        OnInitialize = function(self)
            self:setDimensions(320, 400)

            -- Place filter input at top.
            filterInput:create(false)
            filterInput:setParent(NAME)
            filterInput:onInitialize()
            filterInput:clearAnchors()
            filterInput:addAnchor("topleft", NAME, "topleft", PADDING, PADDING)
            filterInput:addAnchor("topright", NAME, "topright", -PADDING, PADDING)

            -- Place total label below filter input.
            totalLabel:create(false)
            totalLabel:setParent(NAME)
            totalLabel:onInitialize()
            totalLabel:clearAnchors()
            totalLabel:addAnchor(
                "topleft",
                NAME .. "SearchBox",
                "bottomleft",
                0,
                4
            )
            totalLabel:addAnchor(
                "topright",
                NAME .. "SearchBox",
                "bottomright",
                0,
                4
            )

            -- Create scroll window below total label.
            Api.Window.CreateFromTemplate(SCROLL_NAME, "MongbatScrollWindow", NAME, true)
            Api.Window.AddAnchor(SCROLL_NAME, "topleft", NAME .. "TotalLabel", "bottomleft", 0, 4)
            Api.Window.AddAnchor(SCROLL_NAME, "bottomright", NAME, "bottomright", -PADDING, -PADDING)
        end,
    }):create(true)
end

local function OnShutdown()
    Api.Window.Destroy(NAME)
    local mapFind = Components.Defaults.MapFind
    mapFind:restore()
end

Mongbat.Mod {
    Name = "MongbatMapFind",
    Path = "/src/mods/mongbat-map-find",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
