local COLUMNS = 5
local SLOT_SIZE = 50
local COUNT_LABEL_HEIGHT = 14
local PADDING = 4
local MARGIN = 8
local HEADER_HEIGHT = 22
local FALLBACK_MAX_SLOTS = 125

-- Tracks open container windows: containerId -> { windowName }
local openContainers = {}

-- Original ContainerWindow functions saved before overriding, restored on shutdown.
local savedFunctions = {}

---@param context Context
local function OnInitialize(context)
    local Api = context.Api
    local Data = context.Data
    local Constants = context.Constants
    local Components = context.Components

    local containerDefault = Components.Defaults.ContainerWindow

    -- Save the original functions exactly once so they can be restored in OnShutdown.
    -- Guard against double-save if the mod is reloaded without an intervening shutdown.
    if not savedFunctions.Initialize then
        savedFunctions.Initialize             = containerDefault:getDefault().Initialize
        savedFunctions.Shutdown               = containerDefault:getDefault().Shutdown
        savedFunctions.HandleUpdateObjectEvent = containerDefault:getDefault().HandleUpdateObjectEvent
        savedFunctions.MiniModelUpdate        = containerDefault:getDefault().MiniModelUpdate
    end

    --- Returns the Mongbat window name for a given container ID.
    ---@param containerId number
    ---@return string
    local function windowName(containerId)
        return "MongbatContainerWindow_" .. containerId
    end

    --- Returns the objectId of the item at the given gridIndex in a container,
    --- or 0 if the cell is empty.
    ---@param containerId number
    ---@param gridIndex number
    ---@return number
    local function findItemAtGrid(containerId, gridIndex)
        local items = Data.ContainerWindow(containerId):getItems()
        for i = 1, #items do
            if items[i].gridIndex == gridIndex then
                return items[i].objectId
            end
        end
        return 0
    end

    --- Updates a single slot's icon DynamicImage and quantity Label.
    --- Clears both if objectId is 0 or ObjectInfo is not yet available.
    ---@param winName string
    ---@param gridIndex number
    ---@param objectId number
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
        if objectInfo and objectInfo.iconName and objectInfo.iconName ~= "" then
            objectInfo.id = objectId
            if iconExists then Api.Equipment.UpdateItemIcon(iconName, objectInfo) end
            if countExists then
                if objectInfo.quantity and objectInfo.quantity > 1 then
                    Api.Label.SetText(countName, towstring(objectInfo.quantity))
                else
                    Api.Label.SetText(countName, "")
                end
            end
        else
            if iconExists  then Api.DynamicImage.SetTexture(iconName, "", 0, 0) end
            if countExists then Api.Label.SetText(countName, "") end
            -- Register ObjectInfo so HandleUpdateObjectEvent fills the slot once data arrives.
            Api.Window.RegisterData(Constants.DataEvents.OnUpdateObjectInfo.getType(), objectId)
        end
    end

    --- Builds the Mongbat container window: slot DynamicImages, count Labels, title Label.
    ---@param containerId number
    ---@param maxSlots number
    local function createContainerWindow(containerId, maxSlots)
        local winName = windowName(containerId)
        local cols    = COLUMNS
        local rows    = math.ceil(maxSlots / cols)
        local gridW   = cols * SLOT_SIZE + (cols - 1) * PADDING
        local gridH   = rows * SLOT_SIZE + (rows - 1) * PADDING
        local winW    = gridW + MARGIN * 2 + 16
        local winH    = HEADER_HEIGHT + PADDING + gridH + MARGIN * 2 + 16

        -- Slot icon DynamicImages (indices 1..maxSlots in children)
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

        -- Slot quantity Labels (indices maxSlots+1..2*maxSlots in children)
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

        -- Container name title label (index 2*maxSlots+1 in children)
        local titleLabel = Components.Label {
            Name = winName .. "Title",
            OnInitialize = function(self)
                self:setDimensions(winW - MARGIN * 2 - 16, HEADER_HEIGHT)
                self:centerText()
            end
        }

        -- Build children array: slot icons, then count labels, then title
        local children = {}
        for i = 1, maxSlots do
            children[i] = slotViews[i]
        end
        for i = 1, maxSlots do
            children[maxSlots + i] = countLabels[i]
        end
        children[2 * maxSlots + 1] = titleLabel

        -- Grid layout: icons at cell topleft, count labels at cell bottomleft, title at topleft of window.
        local function GridLayout(window, _, child, index)
            if index == 2 * maxSlots + 1 then
                child:clearAnchors()
                child:addAnchor("topleft", window:getName(), "topleft", MARGIN, MARGIN)
                return
            end
            local gridIndex = index <= maxSlots and index or index - maxSlots
            local col = (gridIndex - 1) % cols
            local row = math.floor((gridIndex - 1) / cols)
            local x = MARGIN + col * (SLOT_SIZE + PADDING)
            local y = MARGIN + HEADER_HEIGHT + PADDING + row * (SLOT_SIZE + PADDING)
            child:clearAnchors()
            if index <= maxSlots then
                child:addAnchor("topleft",    window:getName(), "topleft", x, y)
            else
                child:addAnchor("bottomleft", window:getName(), "topleft", x, y + SLOT_SIZE)
            end
        end

        -- Repopulates all slots from a ContainerWindowData wrapper.
        local function updateAllSlots(containerData)
            for i = 1, maxSlots do
                updateSlot(winName, i, 0)
            end
            local numItems = containerData:getNumItems()
            for i = 1, numItems do
                local item = containerData:getItem(i)
                if item and item.gridIndex and item.gridIndex >= 1 and item.gridIndex <= maxSlots then
                    updateSlot(winName, item.gridIndex, item.objectId)
                end
            end
            titleLabel:setText(containerData:getContainerName())
        end

        Components.Window {
            Name     = winName,
            OnLayout = GridLayout,
            OnInitialize = function(self)
                self:setDimensions(winW, winH)
                self:setChildren(children)
            end,
            OnUpdateContainerWindow = function(self, containerData)
                updateAllSlots(containerData)
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

        openContainers[containerId] = { windowName = winName }
    end

    -- Override ContainerWindow.Initialize: suppress the default window and create ours.
    containerDefault:getDefault().Initialize = function()
        local id      = Data.DynamicWindowId()
        local maxSlots = Data.ActiveContainerNumSlots()
        if not maxSlots or maxSlots <= 0 then
            maxSlots = FALLBACK_MAX_SLOTS
        end

        local defaultWin = "ContainerWindow_" .. id

        -- Assign the container ID to the default window so ContainerWindow.Shutdown
        -- (our override) can retrieve it via Api.Window.GetId.
        Api.Window.SetId(defaultWin, id)

        -- Make the default window invisible and non-interactive.  We keep it
        -- "showing" (WindowGetShowing == true) so Actions.ToggleInventoryWindow
        -- correctly detects the backpack as open and destroys it on the next toggle,
        -- which triggers our Shutdown override.
        Api.Window.SetAlpha(defaultWin, 0)
        Api.Window.SetHandleInput(defaultWin, false)
        Api.Window.SetDimensions(defaultWin, 1, 1)

        -- Enable auto-destroy when the player presses Escape or a close button.
        Api.Interface.SetDestroyWindowOnClose(defaultWin, true)

        -- Register the ObjectInfo event on the default window so
        -- HandleUpdateObjectEvent fires when item icons become available.
        Api.Window.RegisterEventHandler(
            defaultWin,
            Constants.DataEvents.OnUpdateObjectInfo.getEvent(),
            "ContainerWindow.HandleUpdateObjectEvent"
        )

        -- Keep ContainerWindow.OpenContainers in sync so game code that inspects
        -- this table (e.g. cascade management) sees the container as open.
        -- Use the same field names as the default UI to avoid nil-access errors.
        containerDefault:getDefault().OpenContainers[id] = {
            open = true, cascading = false, slotsWide = 0, slotsHigh = 0,
            dirty = 0, windowHeight = 0, windowWidth = 0, forceListView = 0
        }

        -- Create the Mongbat window; its setId call registers ContainerWindow data.
        createContainerWindow(id, maxSlots)
    end

    -- Override ContainerWindow.Shutdown: destroy our window and clean up.
    containerDefault:getDefault().Shutdown = function()
        local defaultWin = Data.ActiveWindowName()
        local id = Api.Window.GetId(defaultWin)
        -- Fallback: extract from the window name if SetId was not called yet.
        if not id or id == 0 then
            id = tonumber(string.match(defaultWin, "%d+") or 0)
        end

        Api.Gump.OnCloseContainer(id)

        local state = openContainers[id]
        if state and Api.Window.DoesExist(state.windowName) then
            Api.Window.Destroy(state.windowName)
        end
        openContainers[id] = nil
        containerDefault:getDefault().OpenContainers[id] = nil

        Api.Window.UnregisterData(Constants.DataEvents.OnUpdateContainerWindow.getType(), id)
    end

    -- Override HandleUpdateObjectEvent: refresh an individual slot when ObjectInfo arrives.
    containerDefault:getDefault().HandleUpdateObjectEvent = function()
        local objectId   = Data.UpdateInstanceId()
        local objectInfo = Data.ObjectInfo(objectId)
        if not objectInfo then return end

        local containerId = objectInfo.containerId
        if not containerId or containerId == 0 then return end

        local state = openContainers[containerId]
        if not state then return end

        local items = Data.ContainerWindow(containerId):getItems()
        for i = 1, #items do
            if items[i].objectId == objectId then
                updateSlot(state.windowName, items[i].gridIndex, objectId)
                break
            end
        end
    end

    -- Suppress MiniModelUpdate: the DataEvent framework handles all container refreshes.
    containerDefault:getDefault().MiniModelUpdate = function() end
end

---@param context Context
local function OnShutdown(context)
    local containerDefault    = context.Components.Defaults.ContainerWindow
    local containerDataType   = context.Constants.DataEvents.OnUpdateContainerWindow.getType()

    -- Destroy all open Mongbat container windows and unregister their data.
    for id, state in pairs(openContainers) do
        if context.Api.Window.DoesExist(state.windowName) then
            context.Api.Window.Destroy(state.windowName)
        end
        context.Api.Window.UnregisterData(containerDataType, id)
        containerDefault:getDefault().OpenContainers[id] = nil
    end
    openContainers = {}

    -- Restore the original ContainerWindow functions so the default UI resumes normally.
    if savedFunctions.Initialize then
        containerDefault:getDefault().Initialize              = savedFunctions.Initialize
        containerDefault:getDefault().Shutdown                = savedFunctions.Shutdown
        containerDefault:getDefault().HandleUpdateObjectEvent = savedFunctions.HandleUpdateObjectEvent
        containerDefault:getDefault().MiniModelUpdate         = savedFunctions.MiniModelUpdate
        savedFunctions = {}
    end
end

Mongbat.Mod {
    Name         = "MongbatContainerWindow",
    Path         = "/src/mods/mongbat-container-window",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown
}
