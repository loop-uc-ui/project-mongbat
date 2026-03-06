local NAME = "MongbatMapFindWindow"
local SCROLL_NAME = NAME .. "Scroll"
local SCROLL_CHILD = SCROLL_NAME .. "ScrollChild"
local ITEM_PREFIX = SCROLL_CHILD .. "Item"

local PADDING = 8
local SEARCH_H = 28
local TOTAL_H = 18
local ITEM_H = 22

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

---@param ctx Context
local function OnInitialize(ctx)
    local mapFind = ctx.Components.Defaults.MapFind
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
        ctx.Utils.Array.ForEach(items, function(_, i)
            ctx.Api.Window.Destroy(ITEM_PREFIX .. i)
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

        local row = ctx.Components.Label {
            Name = ITEM_PREFIX .. i,
            OnInitialize = function(self)
                self:setText(displayText)
                self:setDimensions(250, ITEM_H)
            end,
            OnLButtonUp = function(self)
                local x = tonumber(itemData.x)
                local y = tonumber(itemData.y)
                if x and y then
                    ctx.Api.Map.CenterOnLocation(x, y, itemData.Map)
                    ctx.Components.Defaults.MapWindow:getDefault().CenterOnPlayer = false
                    ctx.Api.Radar.SetCenterOnPlayer(false)
                end
            end,
            OnMouseOver = function(self)
                local desc = getFacetName(itemData.Map)
                    .. " x: " .. tostring(itemData.x)
                    .. " y: " .. tostring(itemData.y)
                    .. " z: " .. tostring(itemData.z)
                ctx.Api.ItemProperties.SetActiveItem({
                    windowName = self:getName(),
                    itemId     = i,
                    itemType   = ctx.Constants.ItemPropertyType.WStringData,
                    title      = towstring(tostring(itemData.Name)),
                    body       = towstring(desc),
                })
            end,
            OnMouseOverEnd = function(self)
                ctx.Api.ItemProperties.ClearMouseOverItem()
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
            ctx.Api.ScrollWindow.UpdateScrollRect(SCROLL_NAME)
            return
        end

        local textStr = string.lower(tostring(text))

        -- Search built-in waypoints across all facets.
        local waypointsData = ctx.Data.Waypoints()
        if waypointsData and waypointsData.Facet then
            ctx.Utils.Table.ForEach(waypointsData.Facet, function(map, array)
                ctx.Utils.Array.ForEach(array, function(waypoint, idx)
                    if string.find(string.lower(tostring(waypoint.Name)), textStr) then
                        if ctx.Api.Waypoint.GetInfoAt(idx, map) ~= nil then
                            local wp = ctx.Utils.Table.Copy(waypoint)
                            wp.Map = map
                            table.insert(items, wp)
                        end
                    end
                end)
            end)
        end

        -- Search user-created waypoints (type 15 = custom).
        local waypointList = ctx.Data.WaypointList()
        local wpCount = waypointList:getCount()
        local lowerText = wstring.lower(text)
        for waypointId = 1, wpCount do
            local wtype, _, wname, wfacet, wx, wy, wz = ctx.Api.Waypoint.GetInfo(waypointId)
            if wtype == 15 then
                local mapCommon = ctx.Components.Defaults.MapCommon:getDefault()
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
                    if wstring.find(wstring.lower(wname), lowerText) then
                        table.insert(items, wp)
                    end
                end
            end
        end

        -- Build result rows.
        totalItems = #items
        ctx.Utils.Array.ForEach(items, function(itemData, i)
            itemViews[i] = createItemRow(i, itemData)
        end)

        -- Update total label and scroll rect.
        if totalLabel then
            totalLabel:setText(makeTotalText(totalItems))
        end
        ctx.Api.ScrollWindow.UpdateScrollRect(SCROLL_NAME)
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
        ctx.Api.ScrollWindow.UpdateScrollRect(SCROLL_NAME)
    end

    -- Build the total-count label.
    totalLabel = ctx.Components.Label {
        Name = NAME .. "TotalLabel",
        OnInitialize = function(self)
            self:setDimensions(200, TOTAL_H)
        end,
    }

    -- Build the search FilterInput.
    filterInput = ctx.Components.FilterInput {
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
    ctx.Components.Window({
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
            ctx.Api.Window.CreateFromTemplate(SCROLL_NAME, "MongbatScrollWindow", NAME, true)
            ctx.Api.Window.AddAnchor(SCROLL_NAME, "topleft", NAME .. "TotalLabel", "bottomleft", 0, 4)
            ctx.Api.Window.AddAnchor(SCROLL_NAME, "bottomright", NAME, "bottomright", -PADDING, -PADDING)
        end,
    }):create(true)
end

---@param ctx Context
local function OnShutdown(ctx)
    ctx.Api.Window.Destroy(NAME)
    local mapFind = ctx.Components.Defaults.MapFind
    mapFind:restore()
end

Mongbat.Mod {
    Name = "MongbatMapFind",
    Path = "/src/mods/mongbat-map-find",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
