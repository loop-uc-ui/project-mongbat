local COLUMNS = 5
local SLOT_SIZE = 50
local PADDING = 4
local MARGIN = 8
local HEADER_HEIGHT = 22
local FALLBACK_MAX_SLOTS = 125

-- Tracks open container windows: containerId -> { windowName }
local openContainers = {}

---@param context Context
local function OnInitialize(context)
    local Api = context.Api
    local Data = context.Data
    local Constants = context.Constants
    local Components = context.Components

    local containerDefault = Components.Defaults.ContainerWindow

    --- Returns the window name for a given container ID.
    ---@param containerId number
    ---@return string
    local function windowName(containerId)
        return "MongbatContainerWindow_" .. containerId
    end

    --- Searches ContainedItems for the objectId at a given gridIndex.
    --- Returns 0 if no item is found at that position.
    ---@param containerId number
    ---@param gridIndex number
    ---@return number objectId or 0
    local function findItemAtGrid(containerId, gridIndex)
        local d = Data.ContainerWindow(containerId):getData()
        if not d or not d.ContainedItems then return 0 end
        for i = 1, (d.numItems or 0) do
            local item = d.ContainedItems[i]
            if item and item.gridIndex == gridIndex then
                return item.objectId
            end
        end
        return 0
    end

    --- Updates a single slot's DynamicImage from ObjectInfo.
    --- Clears the icon if objectId is 0 or ObjectInfo is absent.
    ---@param winName string
    ---@param gridIndex number
    ---@param objectId number
    local function updateSlotIcon(winName, gridIndex, objectId)
        local iconName = winName .. "Slot" .. gridIndex
        if not Api.Window.DoesExist(iconName) then return end

        if objectId == 0 then
            Api.DynamicImage.SetTexture(iconName, "", 0, 0)
            return
        end

        local objectInfo = Data.ObjectInfo(objectId)
        if objectInfo and objectInfo.iconName and objectInfo.iconName ~= "" then
            objectInfo.id = objectId
            Api.Equipment.UpdateItemIcon(iconName, objectInfo)
        else
            Api.DynamicImage.SetTexture(iconName, "", 0, 0)
            -- Register ObjectInfo so HandleUpdateObjectEvent can fill it in later
            Api.Window.RegisterData(Constants.DataEvents.OnUpdateObjectInfo.getType(), objectId)
        end
    end

    --- Creates slot DynamicImages and the Mongbat container window.
    ---@param containerId number
    ---@param maxSlots number
    local function createContainerWindow(containerId, maxSlots)
        local winName = windowName(containerId)
        local cols = COLUMNS
        local rows = math.ceil(maxSlots / cols)
        local gridW = cols * SLOT_SIZE + (cols - 1) * PADDING
        local gridH = rows * SLOT_SIZE + (rows - 1) * PADDING
        local winW = gridW + MARGIN * 2 + 16
        local winH = HEADER_HEIGHT + PADDING + gridH + MARGIN * 2 + 16

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
                            itemId = objectId,
                            itemType = Constants.ItemPropertyType.Item,
                            detail = Constants.ItemPropertyDetail.Long
                        })
                    end
                end,
                OnMouseOverEnd = function(self)
                    Api.ItemProperties.ClearMouseOverItem()
                end
            }
        end

        local titleLabel = Components.Label {
            Name = winName .. "Title",
            OnInitialize = function(self)
                self:setDimensions(winW - MARGIN * 2 - 16, HEADER_HEIGHT)
                self:centerText()
            end
        }

        local children = {}
        for i = 1, maxSlots do
            children[i] = slotViews[i]
        end
        children[maxSlots + 1] = titleLabel

        local function GridLayout(window, _, child, index)
            if index == maxSlots + 1 then
                child:clearAnchors()
                child:addAnchor("topleft", window:getName(), "topleft", MARGIN, MARGIN)
                return
            end
            local gi = index
            local col = (gi - 1) % cols
            local row = math.floor((gi - 1) / cols)
            local x = MARGIN + col * (SLOT_SIZE + PADDING)
            local y = MARGIN + HEADER_HEIGHT + PADDING + row * (SLOT_SIZE + PADDING)
            child:clearAnchors()
            child:addAnchor("topleft", window:getName(), "topleft", x, y)
        end

        local function updateAllSlots(containerData)
            for i = 1, maxSlots do
                updateSlotIcon(winName, i, 0)
            end
            local numItems = containerData:getNumItems()
            for i = 1, numItems do
                local item = containerData:getItem(i)
                if item and item.gridIndex and item.gridIndex >= 1 and item.gridIndex <= maxSlots then
                    updateSlotIcon(winName, item.gridIndex, item.objectId)
                end
            end
            titleLabel:setText(containerData:getContainerName())
        end

        Components.Window {
            Name = winName,
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
            -- Prevent right-click from closing the container window; the server
            -- controls container lifetime via ContainerWindow.Shutdown.
            OnRButtonUp = function(self) end
        }:create(true)

        openContainers[containerId] = { windowName = winName }
    end

    -- Override ContainerWindow.Initialize: hide the default window and create our own.
    containerDefault:getDefault().Initialize = function()
        local id = SystemData.DynamicWindowId
        local maxSlots = SystemData.ActiveContainer.NumSlots
        if not maxSlots or maxSlots <= 0 then
            maxSlots = FALLBACK_MAX_SLOTS
        end

        -- Hide the engine-created default window
        local defaultWin = "ContainerWindow_" .. id
        Api.Window.SetShowing(defaultWin, false)

        -- Register the ObjectInfo event on the default window so
        -- HandleUpdateObjectEvent fires when item icons become available
        Api.Window.RegisterEventHandler(
            defaultWin,
            Constants.DataEvents.OnUpdateObjectInfo.getEvent(),
            "ContainerWindow.HandleUpdateObjectEvent"
        )

        -- Create our Mongbat container window (setId registers ContainerWindow data)
        createContainerWindow(id, maxSlots)
    end

    -- Override ContainerWindow.Shutdown: destroy our window and notify the gump system.
    containerDefault:getDefault().Shutdown = function()
        local defaultWin = SystemData.ActiveWindow.name
        local id = Api.Window.GetId(defaultWin)

        Api.Gump.OnCloseContainer(id)

        local state = openContainers[id]
        if state and Api.Window.DoesExist(state.windowName) then
            Api.Window.Destroy(state.windowName)
        end
        openContainers[id] = nil

        Api.Window.UnregisterData(Constants.DataEvents.OnUpdateContainerWindow.getType(), id)
    end

    -- Override HandleUpdateObjectEvent: update a single slot icon when ObjectInfo arrives.
    containerDefault:getDefault().HandleUpdateObjectEvent = function()
        local objectId = Data.UpdateInstanceId()
        local objectInfo = Data.ObjectInfo(objectId)
        if not objectInfo then return end

        local containerId = objectInfo.containerId
        if not containerId or containerId == 0 then return end

        local state = openContainers[containerId]
        if not state then return end

        local d = Data.ContainerWindow(containerId):getData()
        if not d or not d.ContainedItems then return end

        for i = 1, (d.numItems or 0) do
            local item = d.ContainedItems[i]
            if item and item.objectId == objectId then
                updateSlotIcon(state.windowName, item.gridIndex, objectId)
                break
            end
        end
    end

    -- Suppress MiniModelUpdate: our DataEvent framework handles container updates.
    containerDefault:getDefault().MiniModelUpdate = function() end
end

---@param context Context
local function OnShutdown(context)
    local containerDataType = context.Constants.DataEvents.OnUpdateContainerWindow.getType()
    for id, state in pairs(openContainers) do
        if context.Api.Window.DoesExist(state.windowName) then
            context.Api.Window.Destroy(state.windowName)
        end
        context.Api.Window.UnregisterData(containerDataType, id)
    end
    openContainers = {}
end

Mongbat.Mod {
    Name = "MongbatContainerWindow",
    Path = "/src/mods/mongbat-container-window",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
