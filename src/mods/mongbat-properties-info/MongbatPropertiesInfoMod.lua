local NAME         = "MongbatPropertiesInfoWindow"
local SCROLL_AREA  = NAME .. "ScrollArea"
local SCROLL_CHILD = SCROLL_AREA .. "ScrollChild"
local SCROLL_BAR   = SCROLL_AREA .. "Scrollbar"
local ROW_TEMPLATE = "MongbatPropRow"
local ROW_PREFIX   = SCROLL_CHILD .. "Row"

local ITEMPROPERTY_OFFSET = 5000
local ITEMPROPICON        = 3015
local INFO_TEXT_TID       = 1154921

-- Saved originals from PropertiesInfo – must survive across OnInitialize/OnShutdown.
local origToggle     = nil
local origInitialize = nil
local origShutdown   = nil
local origRestart    = nil
local origClose      = nil

--- Removes everything from a wstring at and after the first occurrence of `symbol`.
---@param currentString wstring
---@param symbol string
---@return wstring
local function removeAfterSymbol(currentString, symbol)
    local pos = wstring.find(currentString, towstring(symbol))
    if pos ~= nil then
        currentString = wstring.sub(currentString, 1, pos - 1)
    end
    return currentString
end

--- Resets the scroll window offset (clamped to the scrollbar maximum).
---@param Api table Mongbat Api namespace.
local function resetScroll(Api)
    Api.ScrollWindow.UpdateScrollRect(SCROLL_AREA)
    local offset    = Api.ScrollWindow.GetOffset(SCROLL_AREA)
    local maxOffset = Api.Scrollbar.GetMaxPosition(SCROLL_BAR)
    if offset > maxOffset then
        offset = maxOffset
    end
    Api.ScrollWindow.SetOffset(SCROLL_AREA, offset)
end

---@param context Context
local function OnInitialize(context)
    local Api        = context.Api
    local Data       = context.Data
    local Constants  = context.Constants
    local Components = context.Components

    -- Running count of rows currently in the scroll child.
    local totalRows = 0

    --- Destroys all property row windows currently inside the scroll child.
    local function clearRows()
        for i = totalRows, 1, -1 do
            Api.Window.Destroy(ROW_PREFIX .. i)
        end
        totalRows = 0
    end

    --- Creates and anchors a single property row inside the scroll child.
    ---@param index     integer  1-based row index (visual order in the list).
    ---@param propIndex integer  1-based index into PlayerItemPropCSV.
    ---@param isActive  boolean  Whether the property is currently active on the player.
    local function createRow(index, propIndex, isActive)
        local rowName      = ROW_PREFIX .. index
        local iconName     = rowName .. "Icon"
        local disabledName = rowName .. "Disabled"
        local nameName     = rowName .. "Name"

        Api.Window.CreateFromTemplate(rowName, ROW_TEMPLATE, SCROLL_CHILD, true)

        -- Stack rows: first anchors to scroll-child top; each subsequent row
        -- anchors its bottom to the previous row's top so they stack upward.
        Api.Window.ClearAnchors(rowName)
        if index == 1 then
            Api.Window.AddAnchor(rowName, "topleft",  SCROLL_CHILD, "topleft",  0, 5)
            Api.Window.AddAnchor(rowName, "topright", SCROLL_AREA,  "topright", -22, 0)
        else
            local prevRow = ROW_PREFIX .. (index - 1)
            Api.Window.AddAnchor(rowName, "bottomleft",  prevRow,     "topleft",  0, 0)
            Api.Window.AddAnchor(rowName, "bottomright", SCROLL_AREA, "topright", -22, 0)
        end

        -- Property name TID → strip any suffix after "~".
        local csv  = Data.PlayerItemPropCSV()
        local tid  = csv[propIndex].TID
        local name = removeAfterSymbol(Api.String.GetStringUppercaseFromTid(tid), "~")
        Api.Label.SetText(nameName, name)

        -- Icon texture.
        local iconTexture, x, y = Api.Icon.GetIconData(ITEMPROPICON)
        Api.DynamicImage.SetTexture(iconName, iconTexture, x, y)
        Api.DynamicImage.SetTextureScale(iconName, 0.68)

        -- Disabled overlay: visible for inactive properties.
        Api.Window.SetShowing(disabledName, not isActive)

        -- Dim the label for inactive properties.
        if isActive then
            Api.Label.SetTextColor(nameName, { r = 206, g = 217, b = 242 })
        else
            Api.Label.SetTextColor(nameName, { r = 120, g = 120, b = 120 })
        end

        -- Encode CSV index in the window ID so the mouse-over handler can
        -- look up the description TID without extra state.
        local itemPropId = propIndex + ITEMPROPERTY_OFFSET
        Api.Window.SetId(rowName,  itemPropId)
        Api.Window.SetId(iconName, itemPropId)
    end

    --- Populates the scroll child with all properties (active first, then inactive).
    ---@param activeProps table<number, number>? Map of active CSV indices (as returned by GetActiveProperties).
    local function populateRows(activeProps)
        clearRows()

        local csv     = Data.PlayerItemPropCSV()
        local numRows = Api.CSVUtilities.GetNumRows(csv)
        activeProps   = activeProps or {}

        local index = 1

        -- Active properties first.
        for propIndex = 1, numRows do
            if activeProps[propIndex] then
                if csv[propIndex].TID ~= 0 then
                    createRow(index, propIndex, true)
                    index = index + 1
                end
            end
        end

        -- Inactive properties below.
        for propIndex = 1, numRows do
            if not activeProps[propIndex] then
                if csv[propIndex].TID ~= 0 then
                    createRow(index, propIndex, false)
                    index = index + 1
                end
            end
        end

        totalRows = index - 1
        resetScroll(Api)
    end

    --- Populates the scroll child with only properties whose names contain `text`.
    ---@param text wstring Lower-cased search text.
    local function populateFiltered(text)
        clearRows()

        local csv     = Data.PlayerItemPropCSV()
        local numRows = Api.CSVUtilities.GetNumRows(csv)
        local index   = 1

        for propIndex = 1, numRows do
            local tid = csv[propIndex].TID
            if tid ~= 0 then
                local name = removeAfterSymbol(
                    Api.String.GetStringUppercaseFromTid(tid), "~")
                if wstring.find(wstring.lower(name), text) then
                    -- Show filtered results as active (highlighted).
                    createRow(index, propIndex, true)
                    index = index + 1
                end
            end
        end

        totalRows = index - 1
        resetScroll(Api)
    end

    -- ---------------------------------------------------------------------- --
    -- Mouse-over handler registered in Mongbat.EventHandler so the XML       --
    -- template's EventHandler callbacks can route here. The rows themselves  --
    -- are not Mongbat-component instances so they bypass the Cache lookup.   --
    -- ---------------------------------------------------------------------- --

    Mongbat.EventHandler.MongbatPropertiesInfoOnMouseOver = function()
        local windowName = Data.ActiveWindowName()
        local id         = Api.Window.GetId(windowName)
        if id == 0 then return end

        local propIndex = id - ITEMPROPERTY_OFFSET
        local csv       = Data.PlayerItemPropCSV()
        if not csv or not csv[propIndex] then return end

        -- Derive the Name label for the row from the window name, stripping an
        -- "Icon" suffix if the event fired on the icon child.
        local nameLabelBase = string.gsub(windowName, "Icon$", "")
        local nameLabel     = nameLabelBase .. "Name"
        local title         = Api.Label.GetText(nameLabel)

        local descTid = csv[propIndex].DescriptionTID
        local body    = Api.String.GetStringFromTid(descTid)

        local itemData = {
            windowName = windowName,
            itemId     = id,
            itemType   = Constants.ItemPropertyType.WStringData,
            title      = title,
            body       = body,
        }
        Api.ItemProperties.SetActiveItem(itemData)
    end

    Mongbat.EventHandler.MongbatPropertiesInfoOnMouseOverEnd = function()
        Api.ItemProperties.ClearMouseOverItem()
    end

    -- ---------------------------------------------------------------------- --
    -- Window lifecycle                                                        --
    -- ---------------------------------------------------------------------- --

    local searchInput = nil

    --- Lazily creates the Properties Info window.
    local function createWindow()
        searchInput = Components.FilterInput {
            OnTextChanged = function(self, text)
                if not Api.Window.DoesExist(NAME) then return end
                if wstring.len(text) == 0 then
                    populateRows(Api.ItemProperties.GetActiveProperties())
                else
                    populateFiltered(wstring.lower(text))
                end
            end,
            OnKeyEscape = function(self)
                self:clear()
                populateRows(Api.ItemProperties.GetActiveProperties())
            end,
        }

        local infoLabel = Components.Label {
            OnInitialize = function(self)
                self:setText(INFO_TEXT_TID)
                self:centerText()
            end,
        }

        Components.Window {
            Name      = NAME,
            Template  = "MongbatPropertiesInfoWindow",
            Resizable = true,
            OnInitialize = function(self)
                self:setDimensions(320, 500)
                self:setAlpha(0.90)
                self:setChildren { infoLabel, searchInput }
            end,
            OnLayout = function(window, children, child, index)
                local dimens  = window:getDimensions()
                local padding = 10
                local w       = dimens.x - (padding * 2)

                if index == 1 then
                    -- Info label at the top of the window.
                    child:clearAnchors()
                    child:addAnchor("topleft", window:getName(), "topleft", padding, padding)
                    child:setDimensions(w, 20)
                else
                    -- Search box directly below the info label.
                    child:clearAnchors()
                    child:addAnchor("topleft", children[1]:getName(), "bottomleft", 0, 4)
                    child:setDimensions(w, 24)
                end

                -- After the last header child, push the embedded scroll area down.
                if index == 2 then
                    local headerH    = padding + 20 + 4 + 24 + 6
                    local scrollArea = window:getName() .. "ScrollArea"
                    if Api.Window.DoesExist(scrollArea) then
                        Api.Window.ClearAnchors(scrollArea)
                        Api.Window.AddAnchor(scrollArea, "topleft",
                            window:getName(), "topleft", 5, headerH)
                        Api.Window.AddAnchor(scrollArea, "bottomright",
                            window:getName(), "bottomright", -5, -5)
                    end
                end
            end,
        }:create(false)
    end

    --- Opens the window, (lazily creating it if needed), then populates rows.
    local function openWindow()
        if not Api.Window.DoesExist(NAME) then
            createWindow()
        end
        Api.Window.SetShowing(NAME, true)
        if searchInput then
            searchInput:clear()
        end
        populateRows(Api.ItemProperties.GetActiveProperties())
    end

    --- Clears item tooltip state, destroys all rows, and destroys the window.
    local function closeWindow()
        Api.ItemProperties.ClearMouseOverItem()
        clearRows()
        Api.Window.Destroy(NAME)
    end

    --- Toggles the window open or closed.
    local function toggle()
        if Api.Window.DoesExist(NAME) and Api.Window.IsShowing(NAME) then
            closeWindow()
        else
            openWindow()
        end
    end

    -- ---------------------------------------------------------------------- --
    -- Override the PropertiesInfo global table so external callers (e.g.    --
    -- menu buttons) invoke our implementations.                              --
    -- ---------------------------------------------------------------------- --

    -- Suppress the default PropertiesInfoWindow if it already exists.
    if Api.Window.DoesExist("PropertiesInfoWindow") then
        Api.Window.Destroy("PropertiesInfoWindow")
    end

    local default  = Components.Defaults.PropertiesInfo:getDefault()
    origToggle     = default.Toggle
    origInitialize = default.Initialize
    origShutdown   = default.Shutdown
    origRestart    = default.Restart
    origClose      = default.Close

    default.Initialize = function() end
    default.Shutdown   = function() end
    default.Restart    = function()
        if Api.Window.DoesExist(NAME) then
            populateRows(Api.ItemProperties.GetActiveProperties())
        end
    end
    default.Close  = function() closeWindow() end
    default.Toggle = function() toggle() end
end

---@param context Context
local function OnShutdown(context)
    local Api        = context.Api
    local Components = context.Components

    -- Destroy the window and clean up event handlers.
    Api.Window.Destroy(NAME)
    Mongbat.EventHandler.MongbatPropertiesInfoOnMouseOver    = nil
    Mongbat.EventHandler.MongbatPropertiesInfoOnMouseOverEnd = nil

    -- Restore the original PropertiesInfo function overrides before
    -- handing the global back to the default UI.
    local default  = Components.Defaults.PropertiesInfo:getDefault()
    if origToggle     ~= nil then default.Toggle     = origToggle     end
    if origInitialize ~= nil then default.Initialize = origInitialize end
    if origShutdown   ~= nil then default.Shutdown   = origShutdown   end
    if origRestart    ~= nil then default.Restart    = origRestart    end
    if origClose      ~= nil then default.Close      = origClose      end

    origToggle     = nil
    origInitialize = nil
    origShutdown   = nil
    origRestart    = nil
    origClose      = nil

    Components.Defaults.PropertiesInfo:restoreGlobal()
end

Mongbat.Mod {
    Name         = "MongbatPropertiesInfo",
    Path         = "/src/mods/mongbat-properties-info",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown,
}
