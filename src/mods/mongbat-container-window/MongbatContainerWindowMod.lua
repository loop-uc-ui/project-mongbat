-- ========================================================================== --
-- MongbatContainerWindowMod
-- Replaces the default ContainerWindow with a clean Mongbat grid UI.
-- Uses the DefaultComponent proxy (disable/restore) to intercept
-- ContainerWindow lifecycle without manual function save/restore.
-- ========================================================================== --

local COLUMNS            = 5
local SLOT_SIZE          = 50
local COUNT_LABEL_HEIGHT = 14
local PADDING            = 4
local MARGIN             = 8
local HEADER_HEIGHT      = 22
local FALLBACK_MAX_SLOTS = 125

local Api        = Mongbat.Api
local Data       = Mongbat.Data
local Components = Mongbat.Components
local Constants  = Mongbat.Constants
local Utils      = Mongbat.Utils

-- Tracks open container windows: containerId -> { windowName, maxSlots }
---@type table<integer, { windowName: string, maxSlots: integer }>
local openContainers = {}

local function OnInitialize()
    local containerDefault = Components.Defaults.ContainerWindow

    --- Returns the Mongbat window name for a given container ID.
    ---@param containerId integer
    ---@return string
    local function windowName(containerId)
        return "MongbatContainerWindow_" .. containerId
    end

    --- Returns the objectId of the item at the given gridIndex in a container,
    --- or 0 if the cell is empty.
    ---@param containerId integer
    ---@param gridIndex integer
    ---@return integer
    local function findItemAtGrid(containerId, gridIndex)
        local item = Utils.Array.Find(Data.ContainerWindow(containerId):getItems(), function(item)
            return item.gridIndex == gridIndex
        end)
        return item and item.objectId or 0
    end

    --- Updates a single slot's icon DynamicImage and quantity Label.
    --- Clears both when objectId is 0 or ObjectInfo is not yet available.
    ---@param winName string
    ---@param gridIndex integer
    ---@param objectId integer
    local function updateSlot(winName, gridIndex, objectId)
        local iconName  = winName .. "Slot"  .. gridIndex
        local countName = winName .. "Count" .. gridIndex

        local iconExists  = Api.Window.DoesExist(iconName)
        local countExists = Api.Window.DoesExist(countName)

        if objectId == 0 then
            if iconExists  then Api.DynamicImage.SetTexture(iconName, "", 0, 0) end
            if countExists then Api.Label.SetText(countName, "") end
            return
        end

        local objectInfo = Data.ObjectInfo(objectId)
        if objectInfo:exists() then
            if iconExists  then Api.Equipment.UpdateItemIcon(iconName, objectInfo) end
            if countExists then
                local qty = objectInfo:getQuantity()
                Api.Label.SetText(countName, qty > 1 and towstring(qty) or "")
            end
        else
            if iconExists  then Api.DynamicImage.SetTexture(iconName, "", 0, 0) end
            if countExists then Api.Label.SetText(countName, "") end
        end
    end

    --- Repopulates all slots in a Mongbat container window from the given data.
    --- Clears every slot first, then fills occupied grid positions.
    ---@param winName string  The Mongbat window name.
    ---@param maxSlots integer  Total number of slots the window was created with.
    ---@param containerData ContainerWindowDataWrapper
    local function updateAllSlots(winName, maxSlots, containerData)
        for i = 1, maxSlots do
            updateSlot(winName, i, 0)
        end
        Utils.Array.ForEach(containerData:getItems(), function(item)
            if item and item.gridIndex and item.gridIndex >= 1 and item.gridIndex <= maxSlots then
                updateSlot(winName, item.gridIndex, item.objectId)
            end
        end)
        local titleName = winName .. "Title"
        if Api.Window.DoesExist(titleName) then
            Api.Label.SetText(titleName, containerData:getContainerName())
        end
    end

    --- Builds the Mongbat container window: slot DynamicImages, count Labels, title Label.
    ---@param containerId integer
    ---@param maxSlots integer
    local function createContainerWindow(containerId, maxSlots)
        local winName = windowName(containerId)
        local cols    = COLUMNS
        local rows    = math.ceil(maxSlots / cols)
        local gridW   = cols * SLOT_SIZE + (cols - 1) * PADDING
        local gridH   = rows * SLOT_SIZE + (rows - 1) * PADDING
        local winW    = gridW + MARGIN * 2 + 16
        local winH    = HEADER_HEIGHT + PADDING + gridH + MARGIN * 2 + 16

        -- Slot icon DynamicImages
        local slotViews = {}
        for i = 1, maxSlots do
            local gridIndex = i
            slotViews[i] = Components.DynamicImage {
                Name = winName .. "Slot" .. i,
                OnInitialize = function(self)
                    self:setDimensions(SLOT_SIZE, SLOT_SIZE)
                end,
                OnLButtonDown = function(self)
                    local objectId = findItemAtGrid(containerId, gridIndex)
                    if objectId == 0 then return end
                    if Data.Cursor():isTarget() then
                        Api.Target.LeftClick(objectId)
                        return
                    end
                    Api.Drag.SetObjectMouseClickData(objectId, Constants.DragSource.Object())
                end,
                OnLButtonUp = function(self)
                    if Data.Drag():isDraggingItem() then
                        local existingId = findItemAtGrid(containerId, gridIndex)
                        if existingId ~= 0 then
                            Api.Drag.DropOnObjectAtIndex(existingId, gridIndex)
                        else
                            Api.Drag.DropOnContainer(containerId, gridIndex)
                        end
                    end
                end,
                OnLButtonDblClk = function(self)
                    local objectId = findItemAtGrid(containerId, gridIndex)
                    if objectId ~= 0 then
                        Api.UserAction.UseItem(objectId, false)
                    end
                end,
                OnRButtonDown = function(self)
                    local objectId = findItemAtGrid(containerId, gridIndex)
                    if objectId ~= 0 then
                        Api.ContextMenu.RequestMenu(objectId)
                    end
                end,
                OnMouseOver = function(self)
                    local objectId = findItemAtGrid(containerId, gridIndex)
                    if objectId ~= 0 then
                        Api.ItemProperties.SetActiveItem({
                            windowName = winName,
                            itemId     = objectId,
                            itemType   = Constants.ItemPropertyType.Item,
                            detail     = Constants.ItemPropertyDetail.Long
                        })
                    end
                end,
                OnMouseOverEnd = function(self)
                    Api.ItemProperties.ClearMouseOverItem()
                end
            }
        end

        -- Slot quantity Labels
        local countLabels = {}
        for i = 1, maxSlots do
            countLabels[i] = Components.Label {
                Name = winName .. "Count" .. i,
                OnInitialize = function(self)
                    self:setDimensions(SLOT_SIZE, COUNT_LABEL_HEIGHT)
                    self:setLayer():overlay()
                end
            }
        end

        -- Container name title Label
        local titleLabel = Components.Label {
            Name = winName .. "Title",
            OnInitialize = function(self)
                self:setDimensions(winW - MARGIN * 2 - 16, HEADER_HEIGHT)
                self:centerText()
            end
        }

        -- Build children: slot icons, then count labels, then title
        local children = {}
        for i = 1, maxSlots do
            children[i] = slotViews[i]
        end
        for i = 1, maxSlots do
            children[maxSlots + i] = countLabels[i]
        end
        children[2 * maxSlots + 1] = titleLabel

        -- Grid layout: icons at cell topleft, count labels at cell bottomleft,
        -- title at topleft of the window.
        ---@param window Window
        ---@param _ any
        ---@param child View
        ---@param index integer
        local function GridLayout(window, _, child, index)
            if index == 2 * maxSlots + 1 then
                child:clearAnchors()
                child:addAnchor("topleft", window:getName(), "topleft", MARGIN, MARGIN)
                return
            end
            local gridIndex = index <= maxSlots and index or index - maxSlots
            local col = (gridIndex - 1) % cols
            local row = math.floor((gridIndex - 1) / cols)
            local x   = MARGIN + col * (SLOT_SIZE + PADDING)
            local y   = MARGIN + HEADER_HEIGHT + PADDING + row * (SLOT_SIZE + PADDING)
            child:clearAnchors()
            if index <= maxSlots then
                child:addAnchor("topleft",    window:getName(), "topleft", x, y)
            else
                child:addAnchor("bottomleft", window:getName(), "topleft", x, y + SLOT_SIZE)
            end
        end

        Components.Window {
            Name     = winName,
            OnLayout = GridLayout,
            OnInitialize = function(self)
                self:setDimensions(winW, winH)
                self:setChildren(children)
            end,
            OnLButtonUp = function(self)
                if Data.Drag():isDraggingItem() then
                    Api.Drag.DropOnContainer(containerId, 0)
                end
            end,
            -- Suppress right-click close: container lifetime is server-controlled
            -- via ContainerWindow.Shutdown, not player-initiated right-click.
            OnRButtonUp = function(self) end
        }:create(true)

        openContainers[containerId] = { windowName = winName, maxSlots = maxSlots }

        -- Do an initial slot fill in case container data is already available.
        local containerData = Data.ContainerWindow(containerId)
        if containerData:getNumItems() > 0 then
            updateAllSlots(winName, maxSlots, containerData)
        end
    end

    -- -------------------------------------------------------------------------
    -- disable() must be called BEFORE setting overrides.  Overrides stored in
    -- _overrides always execute regardless of disabled state, so our custom
    -- Initialize/Shutdown/MiniModelUpdate/HandleUpdateObjectEvent all fire
    -- correctly.  restore() in OnShutdown clears them and re-enables originals.
    -- -------------------------------------------------------------------------
    containerDefault:disable()

    -- Override Initialize: suppress the default window and create ours.
    -- The engine sets SystemData.DynamicWindowId and SystemData.ActiveContainer
    -- before calling Initialize, so GetDynamicWindowId / GetActiveContainerNumSlots
    -- return valid values here.  RegisterData registers on the active default
    -- window (ContainerWindow_<id>) so MiniModelUpdate and HandleUpdateObjectEvent
    -- fire correctly on subsequent container updates.
    containerDefault:getDefault().Initialize = function()
        local id       = Api.Window.GetDynamicWindowId()
        local maxSlots = Api.Window.GetActiveContainerNumSlots()
        if not maxSlots or maxSlots <= 0 then
            maxSlots = FALLBACK_MAX_SLOTS
        end

        local defaultWin = "ContainerWindow_" .. id

        -- Register ContainerWindow data on the default window so MiniModelUpdate fires.
        Api.Window.RegisterData(Constants.DataEvents.OnUpdateContainerWindow.getType(), id)

        -- Assign the container ID to the default window so Shutdown can retrieve it.
        Api.Window.SetId(defaultWin, id)

        -- Make the default window invisible and non-interactive.  Keep it "showing"
        -- so Actions.ToggleInventoryWindow correctly detects the backpack as open and
        -- destroys it on the next toggle, triggering our Shutdown override.
        Api.Window.SetAlpha(defaultWin, 0)
        Api.Window.SetHandleInput(defaultWin, false)
        Api.Window.SetDimensions(defaultWin, 1, 1)

        -- Enable auto-destroy when the player presses Escape or a close button.
        Api.Interface.SetDestroyWindowOnClose(defaultWin, true)

        -- Keep ContainerWindow.OpenContainers in sync for cascade management.
        containerDefault:getDefault().OpenContainers[id] = {
            open = true, cascading = false, slotsWide = 0, slotsHigh = 0,
            dirty = 0, windowHeight = 0, windowWidth = 0, forceListView = 0
        }

        createContainerWindow(id, maxSlots)
    end

    -- Override Shutdown: destroy our window and clean up.
    containerDefault:getDefault().Shutdown = function()
        local defaultWin = Api.Window.GetActiveWindowName()
        local id = Api.Window.GetId(defaultWin)
        -- Fallback: extract from the window name if SetId was not called.
        if not id or id == 0 then
            id = tonumber(string.match(defaultWin, "%d+") or 0)
        end

        Api.Gump.OnCloseContainer(id)

        local state = openContainers[id]
        if state then
            Api.Window.Destroy(state.windowName)
        end
        openContainers[id] = nil
        containerDefault:getDefault().OpenContainers[id] = nil

        Api.Window.UnregisterData(Constants.DataEvents.OnUpdateContainerWindow.getType(), id)
    end

    -- Override MiniModelUpdate: relay container content updates to our window.
    -- Also registers ObjectInfo for each item so HandleUpdateObjectEvent fires
    -- when individual item icon data becomes available.
    containerDefault:getDefault().MiniModelUpdate = function()
        local instanceId = Api.Window.GetUpdateInstanceId()
        local state      = openContainers[instanceId]
        if not state then return end

        local containerData = Data.ContainerWindow(instanceId)

        -- Register ObjectInfo for each item in the container.
        Utils.Array.ForEach(containerData:getItems(), function(item)
            Api.Window.RegisterData(
                Constants.DataEvents.OnUpdateObjectInfo.getType(),
                item.objectId
            )
        end)

        updateAllSlots(state.windowName, state.maxSlots, containerData)
    end

    -- Override HandleUpdateObjectEvent: relay per-item icon updates to our slots.
    containerDefault:getDefault().HandleUpdateObjectEvent = function()
        local objectId   = Api.Window.GetUpdateInstanceId()
        local objectInfo = Data.ObjectInfo(objectId)
        if not objectInfo:exists() then return end

        local containerId = objectInfo:getContainerId()
        if containerId == 0 then return end

        local state = openContainers[containerId]
        if not state then return end

        local found = Utils.Array.Find(Data.ContainerWindow(containerId):getItems(), function(item)
            return item.objectId == objectId
        end)
        if found then
            updateSlot(state.windowName, found.gridIndex, objectId)
        end
    end
end

local function OnShutdown()
    local containerDefault = Components.Defaults.ContainerWindow

    -- Destroy all open Mongbat container windows and clear state.
    Utils.Table.ForEach(openContainers, function(id, state)
        Api.Window.Destroy(state.windowName)
        containerDefault:getDefault().OpenContainers[id] = nil
    end)
    openContainers = {}

    -- restore() clears all _overrides (Initialize/Shutdown/MiniModelUpdate/
    -- HandleUpdateObjectEvent hooks) and re-enables the original functions.
    containerDefault:restore()
end

Mongbat.Mod {
    Name         = "MongbatContainerWindow",
    Path         = "/src/mods/mongbat-container-window",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown
}
