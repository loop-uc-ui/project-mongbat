local NAME = "MongbatActionsWindow"
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants
local Utils = Mongbat.Utils

-- Layout constants
local WINDOW_WIDTH    = 340
local WINDOW_HEIGHT   = 520
local FILTER_H        = 24
local HEADER_H        = 28
local NAV_H           = 28
local ICON_SIZE       = 32
local PADDING         = 8
local ITEMS_PER_PAGE  = 8
local BUTTON_SPACING  = 2   -- horizontal gap between adjacent buttons/labels
local ROW_SPACING     = 4   -- vertical gap between item rows
local ICON_LABEL_GAP  = 4   -- horizontal gap between icon and label in a row

-- Children array index constants (for OnLayout)
local IDX_FILTER      = 1
local IDX_PREV_CAT    = 2
local IDX_CAT_LABEL   = 3
local IDX_NEXT_CAT    = 4
local IDX_PREV_PAGE   = 5
local IDX_PAGE_LABEL  = 6
local IDX_NEXT_PAGE   = 7
local IDX_ITEMS_START = 8   -- icon[1]=8, label[1]=9, icon[2]=10, label[2]=11, ...

---
--- Returns true if this action index uses a zero-based actionId for drag/tooltip
--- (i.e., the index itself is not significant as an action ID).
---@param index integer
---@return boolean
local function isSimpleIndex(index)
    return index < 4000 and index ~= 50 and index ~= 53 and index ~= 54
end

---
--- Gets the display name wstring for an action data entry.
---@param actionData table  Entry from ActionsWindow.ActionData
---@return wstring
local function getActionName(actionData)
    if actionData.nameTid then
        return Api.String.GetStringFromTid(actionData.nameTid)
    elseif actionData.nameString then
        return actionData.nameString
    end
    return L""
end

---
--- Gets the display description wstring for an action data entry.
---@param actionData table  Entry from ActionsWindow.ActionData
---@return wstring
local function getActionDesc(actionData)
    if actionData.detailTid then
        return Api.String.GetStringFromTid(actionData.detailTid)
    elseif actionData.detailString then
        return actionData.detailString
    end
    return L""
end

local function OnInitialize()
    -- Suppress the default ActionsWindow
    local actionsWindowDefault = Components.Defaults.ActionsWindow
    actionsWindowDefault:disable()

    -- InitActionData populates ActionData and Groups on the proxy (which still
    -- forwards reads/writes to the original table).
    local rawDefault = actionsWindowDefault:getDefault()
    rawDefault.InitActionData()
    local actionData = rawDefault.ActionData
    local groups     = rawDefault.Groups

    -- -----------------------------------------------------------------------
    -- Build a flat list of visible actions for each group
    -- -----------------------------------------------------------------------
    ---@type table[][]   groupItems[groupIndex] = array of { index, data, name } entries
    local groupItems = Utils.Array.MapToArray(groups, function(group)
        local items = {}
        if group and group.index then
            Utils.Table.ForEach(group.index, function(_, idx)
                local ad = actionData[idx]
                if ad and ad.inActionWindow == true then
                    Utils.Array.Add(items, {
                        index = idx,
                        data  = ad,
                        name  = getActionName(ad),
                    })
                end
            end)
        end
        return items
    end)

    -- -----------------------------------------------------------------------
    -- State (scoped to OnInitialize; closures capture these)
    -- -----------------------------------------------------------------------
    local currentGroup    = 1
    local currentPage     = 1
    local filterText      = L""     -- current search text (empty = no filter)
    ---@type table[]  flat filtered list when a search is active, nil otherwise
    local filteredItems   = nil

    local iconSlots  = {}   -- DynamicImage views  [1..ITEMS_PER_PAGE]
    local labelSlots = {}   -- Label views          [1..ITEMS_PER_PAGE]
    local slotData   = {}   -- current { index, data } for each slot, or nil

    -- Forward-declared refs set after creation
    local categoryLabel
    local pageLabel
    local prevPageBtn
    local nextPageBtn
    local prevCatBtn
    local nextCatBtn

    -- -----------------------------------------------------------------------
    -- Helpers
    -- -----------------------------------------------------------------------

    --- Returns the active item list: filteredItems when a search is active,
    --- otherwise the current group's items.
    ---@return table[]
    local function activeItems()
        if filteredItems ~= nil then
            return filteredItems
        end
        return groupItems[currentGroup] or {}
    end

    ---@return integer
    local function totalPages()
        local items = activeItems()
        if #items == 0 then return 1 end
        return math.ceil(#items / ITEMS_PER_PAGE)
    end

    --- Rebuilds filteredItems from filterText across all groups.
    local function applyFilter()
        if wstring.len(filterText) == 0 then
            filteredItems = nil
            return
        end
        local lower = wstring.lower(filterText)
        filteredItems = Utils.Array.Filter(
            Utils.Array.Concat(groupItems),
            function(item)
                return wstring.find(wstring.lower(item.name), lower) ~= nil
            end
        )
    end

    --- Refreshes all visible item slots to reflect currentGroup + currentPage
    --- (or filteredItems when a search is active).
    local function refreshSlots()
        local items  = activeItems()
        local total  = totalPages()
        local offset = (currentPage - 1) * ITEMS_PER_PAGE
        local isFiltering = filteredItems ~= nil

        -- Update category label (show "Search Results" when filtering)
        if categoryLabel then
            if isFiltering then
                categoryLabel:setText(L"Search Results")
            else
                local grp     = groups[currentGroup]
                local catName = L""
                if grp then
                    if grp.nameTid and grp.nameTid ~= 0 then
                        catName = Api.String.GetStringFromTid(grp.nameTid)
                    elseif grp.nameString then
                        catName = grp.nameString
                    end
                end
                categoryLabel:setText(catName)
            end
        end

        -- Hide category navigation buttons while filtering
        if prevCatBtn then prevCatBtn:setShowing(not isFiltering) end
        if nextCatBtn then nextCatBtn:setShowing(not isFiltering) end

        -- Update page label
        if pageLabel then
            pageLabel:setText(towstring(currentPage) .. L" / " .. towstring(total))
        end

        -- Show/hide page navigation
        if prevPageBtn then prevPageBtn:setShowing(currentPage > 1) end
        if nextPageBtn then nextPageBtn:setShowing(currentPage < total) end

        -- Populate slots
        for i = 1, ITEMS_PER_PAGE do
            local item  = items[offset + i]
            local iconV  = iconSlots[i]
            local labelV = labelSlots[i]
            if iconV and labelV then
                if item then
                    slotData[i] = item
                    local texture, x, y = Api.Icon.GetIconData(item.data.iconId)
                    iconV:setTexture(texture, x, y)
                    labelV:setText(item.name)
                    iconV:setShowing(true)
                    labelV:setShowing(true)
                else
                    slotData[i] = nil
                    iconV:setShowing(false)
                    labelV:setShowing(false)
                end
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- Per-slot component factories
    -- -----------------------------------------------------------------------

    ---@param slotIndex integer  1-based slot index in the visible page
    ---@return DynamicImage
    local function ActionIcon(slotIndex)
        return Components.DynamicImage {
            OnInitialize = function(self)
                self:setDimensions(ICON_SIZE, ICON_SIZE)
                self:setShowing(false)
            end,
            OnLButtonDown = function(self, flags)
                local item = slotData[slotIndex]
                if not item then return end
                local ad  = item.data
                local idx = item.index

                local actionId = 0
                if not isSimpleIndex(idx) then
                    actionId = idx
                end
                if ad.type == Constants.UserAction.TypeInvokeVirtue() then
                    actionId = ad.invokeId or 0
                end

                Api.Drag.SetActionMouseClickData(ad.type, actionId, ad.iconId)
            end,
            OnMouseOver = function(self)
                local item = slotData[slotIndex]
                if not item then return end
                local ad  = item.data
                local idx = item.index

                local name = getActionName(ad)
                local desc = getActionDesc(ad)

                local itemId = idx
                if ad.type == Constants.UserAction.TypeInvokeVirtue() then
                    itemId = ad.invokeId or idx
                end

                local iType
                if isSimpleIndex(idx) then
                    iType = Constants.ItemPropertyType.Action
                else
                    iType = Constants.ItemPropertyType.WStringData
                    itemId = idx
                end

                Api.ItemProperties.SetActiveItem({
                    windowName = NAME,
                    itemId     = itemId,
                    actionType = ad.type,
                    detail     = Constants.ItemPropertyDetail.Long,
                    itemType   = iType,
                    title      = name,
                    body       = desc,
                })
            end,
            OnMouseOverEnd = function(self)
                Api.ItemProperties.ClearMouseOverItem()
            end,
        }
    end

    ---@return Label
    local function ActionLabel()
        return Components.Label {
            OnInitialize = function(self)
                self:setDimensions(WINDOW_WIDTH - ICON_SIZE - PADDING * 3, ICON_SIZE)
                self:setShowing(false)
            end,
        }
    end

    -- -----------------------------------------------------------------------
    -- Create all item slots up-front
    -- -----------------------------------------------------------------------
    for i = 1, ITEMS_PER_PAGE do
        iconSlots[i]  = ActionIcon(i)
        labelSlots[i] = ActionLabel()
    end

    -- -----------------------------------------------------------------------
    -- Search/filter input
    -- -----------------------------------------------------------------------
    local filterInput = Components.FilterInput {
        OnInitialize = function(self)
            self:setDimensions(WINDOW_WIDTH - PADDING * 2, FILTER_H)
        end,
        OnTextChanged = function(self, text)
            filterText   = text
            currentPage  = 1
            applyFilter()
            refreshSlots()
        end,
        OnKeyEscape = function(self)
            self:clear()
            filterText   = L""
            currentPage  = 1
            applyFilter()
            refreshSlots()
        end,
    }

    -- -----------------------------------------------------------------------
    -- Category navigation buttons
    -- -----------------------------------------------------------------------
    prevCatBtn = Components.Button {
        OnInitialize = function(self)
            self:setText(L"<")
            self:setDimensions(28, HEADER_H)
        end,
        OnLButtonUp = function(self)
            currentGroup = currentGroup - 1
            if currentGroup < 1 then currentGroup = #groups end
            currentPage = 1
            refreshSlots()
        end,
    }

    categoryLabel = Components.Label {
        OnInitialize = function(self)
            self:setDimensions(WINDOW_WIDTH - 28 * 2 - PADDING * 2, HEADER_H)
            self:centerText()
        end,
    }

    nextCatBtn = Components.Button {
        OnInitialize = function(self)
            self:setText(L">")
            self:setDimensions(28, HEADER_H)
        end,
        OnLButtonUp = function(self)
            currentGroup = currentGroup + 1
            if currentGroup > #groups then currentGroup = 1 end
            currentPage = 1
            refreshSlots()
        end,
    }

    -- -----------------------------------------------------------------------
    -- Page navigation (shown only when a group spans multiple pages)
    -- -----------------------------------------------------------------------
    prevPageBtn = Components.Button {
        OnInitialize = function(self)
            self:setText(L"<< Prev")
            self:setDimensions(64, NAV_H)
            self:setShowing(false)
        end,
        OnLButtonUp = function(self)
            currentPage = currentPage - 1
            if currentPage < 1 then currentPage = 1 end
            refreshSlots()
        end,
    }

    pageLabel = Components.Label {
        OnInitialize = function(self)
            self:setDimensions(WINDOW_WIDTH - 64 * 2 - PADDING * 2, NAV_H)
            self:centerText()
        end,
    }

    nextPageBtn = Components.Button {
        OnInitialize = function(self)
            self:setText(L"Next >>")
            self:setDimensions(64, NAV_H)
            self:setShowing(false)
        end,
        OnLButtonUp = function(self)
            local total = totalPages()
            currentPage = currentPage + 1
            if currentPage > total then currentPage = total end
            refreshSlots()
        end,
    }

    -- -----------------------------------------------------------------------
    -- Main window layout
    --
    -- Children array (in order):
    --   [1]  filterInput
    --   [2]  prevCatBtn
    --   [3]  categoryLabel
    --   [4]  nextCatBtn
    --   [5]  prevPageBtn
    --   [6]  pageLabel
    --   [7]  nextPageBtn
    --   [8]  iconSlots[1],  [9]  labelSlots[1]
    --   [10] iconSlots[2],  [11] labelSlots[2]
    --   ...
    -- -----------------------------------------------------------------------
    local function Layout(window, children, child, index)
        local wName = window:getName()
        local pad   = PADDING

        if index == IDX_FILTER then
            -- Search filter input â€“ top, full width
            child:addAnchor("topleft", wName, "topleft", pad, pad)
            child:setDimensions(WINDOW_WIDTH - pad * 2, FILTER_H)

        elseif index == IDX_PREV_CAT then
            -- Category prev button â€“ below filter, left
            child:addAnchor("topleft", children[IDX_FILTER]:getName(), "bottomleft", 0, BUTTON_SPACING)
            child:setDimensions(28, HEADER_H)

        elseif index == IDX_CAT_LABEL then
            -- Category label â€“ to the right of prev button
            child:addAnchor("topleft", children[IDX_PREV_CAT]:getName(), "topright", BUTTON_SPACING, 0)
            child:setDimensions(WINDOW_WIDTH - 28 * 2 - pad * 2, HEADER_H)

        elseif index == IDX_NEXT_CAT then
            -- Category next button â€“ to the right of category label
            child:addAnchor("topleft", children[IDX_CAT_LABEL]:getName(), "topright", BUTTON_SPACING, 0)
            child:setDimensions(28, HEADER_H)

        elseif index == IDX_PREV_PAGE then
            -- Page prev button â€“ bottom-left of window
            child:addAnchor("bottomleft", wName, "bottomleft", pad, -pad)
            child:setDimensions(64, NAV_H)

        elseif index == IDX_PAGE_LABEL then
            -- Page label â€“ to the right of prev-page button
            child:addAnchor("bottomleft", children[IDX_PREV_PAGE]:getName(), "bottomright", BUTTON_SPACING, 0)
            child:setDimensions(WINDOW_WIDTH - 64 * 2 - pad * 2, NAV_H)

        elseif index == IDX_NEXT_PAGE then
            -- Page next button â€“ to the right of page label
            child:addAnchor("bottomleft", children[IDX_PAGE_LABEL]:getName(), "bottomright", BUTTON_SPACING, 0)
            child:setDimensions(64, NAV_H)

        else
            -- Item slots start at IDX_ITEMS_START.
            -- Pairs: icon at even offsets, label at odd offsets (0-based).
            --   offset 0 = icon[1], offset 1 = label[1]
            --   offset 2 = icon[2], offset 3 = label[2]  ...
            local offset  = index - IDX_ITEMS_START       -- 0-based
            local slotIdx = math.floor(offset / 2) + 1    -- which slot (1..ITEMS_PER_PAGE)
            local isIcon  = (math.mod(offset, 2) == 0)

            if isIcon then
                if slotIdx == 1 then
                    -- First icon anchors below the header row
                    child:addAnchor("topleft", children[IDX_PREV_CAT]:getName(), "bottomleft", pad, ROW_SPACING)
                else
                    -- Subsequent icons anchor below the previous icon
                    local prevIconIdx = IDX_ITEMS_START + (slotIdx - 2) * 2
                    child:addAnchor("topleft", children[prevIconIdx]:getName(), "bottomleft", 0, ROW_SPACING)
                end
                child:setDimensions(ICON_SIZE, ICON_SIZE)
            else
                -- Label anchors to the right of the icon in the same row
                local iconIdx = index - 1
                child:addAnchor("topleft", children[iconIdx]:getName(), "topright", ICON_LABEL_GAP, 0)
                child:setDimensions(WINDOW_WIDTH - ICON_SIZE - pad * 3, ICON_SIZE)
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- Assemble children list and create the main window
    -- -----------------------------------------------------------------------
    local windowChildren = {
        filterInput,
        prevCatBtn, categoryLabel, nextCatBtn,
        prevPageBtn, pageLabel, nextPageBtn,
    }
    for i = 1, ITEMS_PER_PAGE do
        Utils.Array.Add(windowChildren, iconSlots[i])
        Utils.Array.Add(windowChildren, labelSlots[i])
    end

    Components.Window {
        Name = NAME,
        OnLayout = Layout,
        OnInitialize = function(self)
            self:setDimensions(WINDOW_WIDTH, WINDOW_HEIGHT)
            self:addAnchor("center", "Root", "center", 0, 0)
            self:setChildren(windowChildren)
        end,
        OnShown = function(self)
            refreshSlots()
        end,
    }:create(true)

    -- create() fires OnInitialize synchronously; all children now exist.
    refreshSlots()
end

local function OnShutdown()
    Api.Window.Destroy(NAME)
    Components.Defaults.ActionsWindow:restore()
end

Mongbat.Mod {
    Name = "MongbatActionsWindow",
    Path = "/src/mods/mongbat-actions-window",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
