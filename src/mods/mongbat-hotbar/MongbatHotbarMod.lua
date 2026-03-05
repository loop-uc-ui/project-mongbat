local SLOT_SIZE = 50
local DEFAULT_SLOTS = 12
local MAX_HOTBAR_ID = 24

---@param context Context
local function OnInitialize(context)
    local Api = context.Api
    local Data = context.Data
    local Components = context.Components

    -- Suppress the default Hotbar Lua global so its XML callbacks become no-ops.
    local hotbarDefault = Components.Defaults.Hotbar
    hotbarDefault:disable()

    -- Destroy any already-running default hotbar windows (Hotbar1, Hotbar2, …).
    -- They were created at startup from hotbar.xml before our mod loaded.
    for id = 1, MAX_HOTBAR_ID do
        local defaultName = "Hotbar" .. id
        if Api.Window.DoesExist(defaultName) then
            for slot = 1, DEFAULT_SLOTS do
                local elem = defaultName .. "Button" .. slot
                if Api.Window.DoesExist(elem) then
                    Api.Hotbar.ClearAction(elem, id, slot, false)
                end
            end
            Api.Window.Destroy(defaultName)
        end
    end

    -- hotbarWindows tracks the live Window instances keyed by hotbar ID so
    -- that the context-menu "close" handler can nil them out cleanly.
    local hotbarWindows = {}

    -- Forward-declare so the closure inside createHotbarWindow can reference it.
    local createHotbarWindow

    -- ------------------------------------------------------------------ --
    -- Helpers
    -- ------------------------------------------------------------------ --

    local function getNumSlots(hotbarId)
        return Api.Interface.LoadNumber("MongbatHotbar" .. hotbarId .. "Slots", DEFAULT_SLOTS)
    end

    local function isVertical(hotbarId)
        return Api.Interface.LoadBoolean("MongbatHotbar" .. hotbarId .. "Vertical", false)
    end

    local function setVertical(hotbarId, value)
        Api.Interface.SaveBoolean("MongbatHotbar" .. hotbarId .. "Vertical", value)
    end

    -- ------------------------------------------------------------------ --
    -- Context-menu callback
    -- ------------------------------------------------------------------ --

    local function handleContextMenu(returnCode, param)
        local hotbarId = param.hotbarId
        local hotbarName = "MongbatHotbar" .. hotbarId

        if returnCode == "lock" then
            Api.Hotbar.SetLocked(hotbarId, not Api.Hotbar.IsLocked(hotbarId))

        elseif returnCode == "orientation" then
            local vertical = not isVertical(hotbarId)
            setVertical(hotbarId, vertical)
            -- Recreate the window so the new layout takes effect.
            -- Slot OnShutdown callbacks handle HotbarSystem un-registration.
            if Api.Window.DoesExist(hotbarName) then
                Api.Window.Destroy(hotbarName)
                hotbarWindows[hotbarId] = nil
            end
            createHotbarWindow(hotbarId)

        elseif returnCode == "new" then
            local newId = Api.Hotbar.SpawnNew(nil, DEFAULT_SLOTS)
            if newId then
                createHotbarWindow(newId)
            end

        elseif returnCode == "clear" and param.slotIndex ~= nil then
            local slotName = hotbarName .. "Button" .. param.slotIndex
            Api.Hotbar.ClearAction(slotName, hotbarId, param.slotIndex, true)

        elseif returnCode == "close" then
            if Api.Window.DoesExist(hotbarName) then
                -- Slot OnShutdown callbacks handle HotbarSystem un-registration.
                Api.Window.Destroy(hotbarName)
                hotbarWindows[hotbarId] = nil
            end
        end
    end

    -- ------------------------------------------------------------------ --
    -- Show the right-click context menu for a given hotbar / slot.
    -- slotIndex may be nil when the user right-clicked on the frame itself.
    -- ------------------------------------------------------------------ --

    local function showContextMenu(hotbarId, slotIndex)
        local param = { hotbarId = hotbarId, slotIndex = slotIndex }

        if Api.Hotbar.IsLocked(hotbarId) then
            Api.ContextMenu.CreateItem(HotbarSystem.TID_UNLOCK_HOTBAR, 0, "lock", param)
        else
            Api.ContextMenu.CreateItem(HotbarSystem.TID_LOCK_HOTBAR, 0, "lock", param)
        end

        if isVertical(hotbarId) then
            Api.ContextMenu.CreateItemWithString(L"Horizontal", 0, "orientation", param, false)
        else
            Api.ContextMenu.CreateItemWithString(L"Vertical", 0, "orientation", param, false)
        end

        Api.ContextMenu.CreateItem(HotbarSystem.TID_NEW_HOTBAR, 0, "new", param)

        if slotIndex ~= nil and Api.Hotbar.HasItem(hotbarId, slotIndex) then
            Api.ContextMenu.CreateItem(HotbarSystem.TID_CLEAR_ITEM, 0, "clear", param)
        end

        Api.ContextMenu.CreateItemWithString(L"Close", 0, "close", param, false)

        Api.ContextMenu.Activate(handleContextMenu)
    end

    -- ------------------------------------------------------------------ --
    -- Create a single hotbar window for a given hotbar ID.
    -- ------------------------------------------------------------------ --

    createHotbarWindow = function(hotbarId)
        local hotbarName = "MongbatHotbar" .. hotbarId
        local numSlots = getNumSlots(hotbarId)
        local vertical = isVertical(hotbarId)

        -- Per-hotbar click tracking (which slot the user pressed down on).
        local currentUseSlot = 0

        -- ---------------------------------------------------------------- --
        -- Build slot DynamicImages
        -- ---------------------------------------------------------------- --

        local function makeSlot(slotIndex)
            local slotName = hotbarName .. "Button" .. slotIndex
            return Components.DynamicImage {
                Name = slotName,
                OnInitialize = function(self)
                    self:setDimensions(SLOT_SIZE, SLOT_SIZE)
                    -- Link this window to the engine's hotbar action data so
                    -- HotbarSystem.Update can drive icon/cooldown rendering.
                    Api.Hotbar.RegisterAction(slotName, hotbarId, slotIndex)
                end,
                OnShutdown = function(self)
                    Api.Hotbar.ClearAction(slotName, hotbarId, slotIndex, true)
                end,
                OnLButtonDown = function(self, flags)
                    if Api.Hotbar.HasItem(hotbarId, slotIndex) then
                        if not Api.Hotbar.IsLocked(hotbarId) then
                            -- Allow the player to drag this action to another slot.
                            Api.Drag.SetExistingActionMouseClickData(hotbarId, slotIndex, 0)
                        end
                        currentUseSlot = slotIndex
                    end
                end,
                OnLButtonUp = function(self)
                    if Data.Drag():isDragging() then
                        -- An action (or item) was dragged onto this slot.
                        local dropped = Api.Drag.DropAction(hotbarId, slotIndex, 0)
                        if dropped then
                            -- Refresh the engine registration so the new icon shows.
                            Api.Hotbar.ClearAction(slotName, hotbarId, slotIndex, true)
                            Api.Hotbar.RegisterAction(slotName, hotbarId, slotIndex)
                        end
                    elseif currentUseSlot == slotIndex then
                        Api.Hotbar.ExecuteItem(hotbarId, slotIndex)
                    end
                    currentUseSlot = 0
                end,
                OnRButtonDown = function(self)
                    showContextMenu(hotbarId, slotIndex)
                end,
            }
        end

        local slots = {}
        for i = 1, numSlots do
            slots[i] = makeSlot(i)
        end

        -- ---------------------------------------------------------------- --
        -- Layout: horizontal row or vertical column of slots.
        -- ---------------------------------------------------------------- --

        local function hotbarLayout(win, children, child, index)
            if index == 1 then
                child:addAnchor("topleft", win:getName(), "topleft", 0, 0)
            elseif vertical then
                child:addAnchor("topleft", children[index - 1]:getName(), "bottomleft", 0, 0)
            else
                child:addAnchor("topleft", children[index - 1]:getName(), "topright", 0, 0)
            end
            child:setDimensions(SLOT_SIZE, SLOT_SIZE)
        end

        -- ---------------------------------------------------------------- --
        -- Hotbar window
        -- ---------------------------------------------------------------- --

        local window = Components.Window {
            Name = hotbarName,
            Resizable = false,
            OnLayout = hotbarLayout,
            OnInitialize = function(self)
                if vertical then
                    self:setDimensions(SLOT_SIZE, SLOT_SIZE * numSlots)
                else
                    self:setDimensions(SLOT_SIZE * numSlots, SLOT_SIZE)
                end
                self:setChildren(slots)
            end,
            OnRButtonUp = function(self, flags, x, y)
                showContextMenu(hotbarId, nil)
            end,
        }:create(true)

        hotbarWindows[hotbarId] = window
        return window
    end

    -- ------------------------------------------------------------------ --
    -- Bootstrap: create a Mongbat window for every engine hotbar that
    -- already exists (populated by the C++ HotbarSystem at login).
    -- ------------------------------------------------------------------ --

    for id = 1, MAX_HOTBAR_ID do
        if SystemData.Hotbar[id] ~= nil then
            createHotbarWindow(id)
        end
    end
end

---@param context Context
local function OnShutdown(context)
    local Api = context.Api
    local Components = context.Components

    -- Destroy all Mongbat hotbar windows.  Slot OnShutdown callbacks handle
    -- HotbarSystem.ClearActionIcon for each registered slot.
    for id = 1, MAX_HOTBAR_ID do
        local hotbarName = "MongbatHotbar" .. id
        if Api.Window.DoesExist(hotbarName) then
            Api.Window.Destroy(hotbarName)
        end
    end

    -- Restore the Hotbar Lua global so the default UI works if the mod is
    -- unloaded without a full client restart.
    Components.Defaults.Hotbar:restore()
end

Mongbat.Mod {
    Name = "MongbatHotbar",
    Path = "/src/mods/mongbat-hotbar",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
