local DEFAULT_SLOTS = 12
local SLOT_SIZE = 50
local MAX_HOTBAR_ID = 24

-- Saved across OnInitialize / OnShutdown so the original engine function can
-- be restored when the mod is unloaded.
local origHandleUpdateActionItem = nil

---@param context Context
local function OnInitialize(context)
    local Api = context.Api
    local Data = context.Data
    local Components = context.Components

    -- Disable the Hotbar Lua-callback proxy so that XML-triggered
    -- Hotbar.Initialize / Hotbar.ItemLButtonDown / etc. become no-ops.
    Components.Defaults.Hotbar:disable()

    -- hotbarWindows[id] = Window instance; used to gate the UPDATE_ACTION_ITEM handler.
    local hotbarWindows = {}

    -- Forward-declared so closures inside createHotbarWindow can reference it.
    local createHotbarWindow

    -- ------------------------------------------------------------------ --
    -- Persistence helpers
    -- ------------------------------------------------------------------ --

    local function getNumSlots(hotbarId)
        return Api.Interface.LoadNumber("MongbatHotbar" .. hotbarId .. "Slots", DEFAULT_SLOTS)
    end

    local function setNumSlots(hotbarId, count)
        Api.Interface.SaveNumber("MongbatHotbar" .. hotbarId .. "Slots", count)
    end

    local function isVertical(hotbarId)
        return Api.Interface.LoadBoolean("MongbatHotbar" .. hotbarId .. "Vertical", false)
    end

    local function setVertical(hotbarId, value)
        Api.Interface.SaveBoolean("MongbatHotbar" .. hotbarId .. "Vertical", value)
    end

    -- ------------------------------------------------------------------ --
    -- Destroy the XML-created default Hotbar{id} window (and its slot
    -- children) so our slot names do not collide with theirs.
    -- ------------------------------------------------------------------ --

    local function destroyDefaultWindow(hotbarId)
        local defaultName = "Hotbar" .. hotbarId
        if Api.Window.DoesExist(defaultName) then
            -- Unregister the default slots from HotbarSystem before destruction.
            for slot = 1, DEFAULT_SLOTS do
                local elem = defaultName .. "Button" .. slot
                if Api.Window.DoesExist(elem) then
                    Api.Hotbar.ClearAction(elem, hotbarId, slot, true)
                end
            end
            Api.Window.Destroy(defaultName)
        end
    end

    -- ------------------------------------------------------------------ --
    -- Override HotbarSystem.HandleUpdateActionItem.
    --
    -- The default implementation calls Hotbar.ClearHotbarItem / SetHotbarItem
    -- which are no-ops because we disabled the Hotbar proxy.  We replace it
    -- with our own refresh logic via the DefaultHotbarSystemComponent proxy.
    -- The engine's UPDATE_ACTION_ITEM root handler ("HotbarSystem.HandleUpdateActionItem")
    -- continues to fire and now invokes our replacement.
    -- ------------------------------------------------------------------ --

    local hsDefault = Components.Defaults.HotbarSystem:getDefault()
    origHandleUpdateActionItem = hsDefault.HandleUpdateActionItem

    hsDefault.HandleUpdateActionItem = function()
        local actionItem = Data.UpdateActionItem()
        local hotbarId = actionItem:getHotbarId()
        local itemIndex = actionItem:getItemIndex()
        if hotbarId == nil or itemIndex == nil then return end
        -- Only refresh slots belonging to our own hotbar windows.
        if hotbarWindows[hotbarId] == nil then return end
        local slotName = "Hotbar" .. hotbarId .. "Button" .. itemIndex
        if Api.Window.DoesExist(slotName) then
            Api.Hotbar.ClearAction(slotName, hotbarId, itemIndex, true)
            Api.Hotbar.RegisterAction(slotName, hotbarId, itemIndex)
        end
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
            setVertical(hotbarId, not isVertical(hotbarId))
            -- Slot OnShutdown callbacks handle HotbarSystem un-registration.
            if Api.Window.DoesExist(hotbarName) then
                Api.Window.Destroy(hotbarName)
                hotbarWindows[hotbarId] = nil
            end
            createHotbarWindow(hotbarId)

        elseif returnCode == "slots" then
            local count = param.count
            setNumSlots(hotbarId, count)
            if Api.Window.DoesExist(hotbarName) then
                Api.Window.Destroy(hotbarName)
                hotbarWindows[hotbarId] = nil
            end
            createHotbarWindow(hotbarId)

        elseif returnCode == "new" then
            -- SpawnNew registers the hotbar in the engine and creates a default
            -- Hotbar{id} XML window via CreateWindowFromTemplate.  We destroy
            -- that window immediately so our Hotbar{id}Button{n} children do
            -- not collide with the XML-created ones.
            local newId = Api.Hotbar.SpawnNew(nil, DEFAULT_SLOTS)
            if newId then
                destroyDefaultWindow(newId)
                createHotbarWindow(newId)
            end

        elseif returnCode == "clear" and param.slotIndex ~= nil then
            local slotName = "Hotbar" .. hotbarId .. "Button" .. param.slotIndex
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
    -- Right-click context menu.
    -- slotIndex is nil when the user right-clicked the hotbar frame directly.
    -- ------------------------------------------------------------------ --

    local function showContextMenu(hotbarId, slotIndex)
        local param = { hotbarId = hotbarId, slotIndex = slotIndex }

        if Api.Hotbar.IsLocked(hotbarId) then
            Api.ContextMenu.CreateItem(Constants.HotbarSystem.TID_UNLOCK_HOTBAR, 0, "lock", param)
        else
            Api.ContextMenu.CreateItem(Constants.HotbarSystem.TID_LOCK_HOTBAR, 0, "lock", param)
        end

        if isVertical(hotbarId) then
            Api.ContextMenu.CreateItemWithString(L"Horizontal", 0, "orientation", param, false)
        else
            Api.ContextMenu.CreateItemWithString(L"Vertical", 0, "orientation", param, false)
        end

        -- Slot-count sub-menu: offer 6 / 8 / 10 / 12 presets; mark current.
        local currentCount = getNumSlots(hotbarId)
        for _, count in ipairs({ 6, 8, 10, 12 }) do
            local label = towstring(count) .. L" Slots"
            Api.ContextMenu.CreateItemWithString(label, 0, "slots",
                { hotbarId = hotbarId, count = count }, count == currentCount)
        end

        Api.ContextMenu.CreateItem(Constants.HotbarSystem.TID_NEW_HOTBAR, 0, "new", param)

        if slotIndex ~= nil and Api.Hotbar.HasItem(hotbarId, slotIndex) then
            Api.ContextMenu.CreateItem(Constants.HotbarSystem.TID_CLEAR_ITEM, 0, "clear", param)
        end

        Api.ContextMenu.CreateItemWithString(L"Close", 0, "close", param, false)

        Api.ContextMenu.Activate(handleContextMenu)
    end

    -- ------------------------------------------------------------------ --
    -- Create a single hotbar window for a given hotbar ID.
    -- Precondition: the default Hotbar{id} XML window has been destroyed
    -- (or never existed) so its child slot names are free to reuse.
    -- ------------------------------------------------------------------ --

    createHotbarWindow = function(hotbarId)
        local hotbarName = "MongbatHotbar" .. hotbarId
        local numSlots = getNumSlots(hotbarId)
        local vertical = isVertical(hotbarId)

        -- Per-hotbar tracking: which slot the player pressed LButton on.
        local currentUseSlot = 0

        -- ---------------------------------------------------------------- --
        -- Slot buttons — one per action slot.
        --
        -- Naming: Hotbar{id}Button{slot} matches the pattern that
        --   HotbarSystem.Update parses when iterating SpecialActions, and that
        --   HotbarSystem.UpdateActionButton expects for sub-window names such
        --   as $parentSquareIcon, $parentOverlay, and $parentHotkey.
        --
        -- Template: MongbatHotbarSlot (inherits ActionButtonDef) provides all
        --   those sub-windows so the engine can display icons and cooldowns.
        -- ---------------------------------------------------------------- --

        local function makeSlot(slotIndex)
            local slotName = "Hotbar" .. hotbarId .. "Button" .. slotIndex
            return Components.Button {
                Name = slotName,
                Template = "MongbatHotbarSlot",
                Resizable = false,
                OnInitialize = function(self)
                    self:setDimensions(SLOT_SIZE, SLOT_SIZE)
                    -- Register with HotbarSystem so it can drive icon display
                    -- and cooldown animation via UpdateActionButton.
                    Api.Hotbar.RegisterAction(slotName, hotbarId, slotIndex)
                end,
                OnShutdown = function(self)
                    Api.Hotbar.ClearAction(slotName, hotbarId, slotIndex, true)
                end,
                OnLButtonDown = function(self, flags)
                    if Api.Hotbar.HasItem(hotbarId, slotIndex) then
                        if not Api.Hotbar.IsLocked(hotbarId) then
                            -- Initiate an engine drag of the existing action so
                            -- the player can move it to another slot or bar.
                            Api.Drag.SetExistingActionMouseClickData(hotbarId, slotIndex, 0)
                        end
                        currentUseSlot = slotIndex
                    end
                end,
                OnLButtonUp = function(self)
                    if Data.Drag():isDragging() then
                        -- Drop a dragged action/item onto this slot.
                        local dropped = Api.Drag.DropAction(hotbarId, slotIndex, 0)
                        if dropped then
                            -- Refresh registration so the new icon is displayed.
                            Api.Hotbar.ClearAction(slotName, hotbarId, slotIndex, true)
                            Api.Hotbar.RegisterAction(slotName, hotbarId, slotIndex)
                        end
                    elseif currentUseSlot == slotIndex then
                        Api.Hotbar.ExecuteItem(hotbarId, slotIndex)
                    end
                    currentUseSlot = 0
                end,
                -- OnRButtonDown does NOT propagate to the parent Window, so
                -- only fires when this specific slot is right-clicked.
                -- This prevents a double context-menu that would occur when
                -- using OnRButtonUp, which propagates automatically through
                -- Mongbat's child-to-parent event wrappers.
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
        -- Layout: tightly-packed horizontal row or vertical column of slots.
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
        -- Container window
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
            -- OnRButtonDown on the container fires only for direct right-clicks
            -- on the frame (does NOT propagate from slot children).
            OnRButtonDown = function(self)
                showContextMenu(hotbarId, nil)
            end,
            -- Override OnRButtonUp with a no-op to prevent two problems:
            --   1. The default Window behavior of destroying when parent root.
            --   2. A second context-menu firing when a slot child's OnRButtonUp
            --      propagates up to the parent through Mongbat's child wrappers.
            OnRButtonUp = function(self) end,
        }:create(true)

        hotbarWindows[hotbarId] = window
        return window
    end

    -- ------------------------------------------------------------------ --
    -- Bootstrap: for each engine-registered hotbar, destroy the default
    -- Hotbar{id} XML window (created by HotbarSystem.Initialize before our
    -- mod ran) and replace it with our MongbatHotbar{id} window.
    -- ------------------------------------------------------------------ --

    for _, id in pairs(Data.Hotbar():getHotbarIds()) do
        destroyDefaultWindow(id)
        createHotbarWindow(id)
    end
end

---@param context Context
local function OnShutdown(context)
    local Api = context.Api
    local Components = context.Components

    -- Restore HotbarSystem.HandleUpdateActionItem to the original engine
    -- function so the default UI works correctly after mod unload.
    local hsDefault = Components.Defaults.HotbarSystem:getDefault()
    hsDefault.HandleUpdateActionItem = origHandleUpdateActionItem
    origHandleUpdateActionItem = nil

    -- Destroy all Mongbat hotbar windows.
    -- Each slot's OnShutdown callback calls Api.Hotbar.ClearAction to
    -- unregister from HotbarSystem before the window is removed.
    for id = 1, MAX_HOTBAR_ID do
        local hotbarName = "MongbatHotbar" .. id
        if Api.Window.DoesExist(hotbarName) then
            Api.Window.Destroy(hotbarName)
        end
    end

    -- Restore the Hotbar Lua-callback proxy so the default UI works if
    -- the mod is unloaded without a full client restart.
    Components.Defaults.Hotbar:restore()
end

Mongbat.Mod {
    Name = "MongbatHotbar",
    Path = "/src/mods/mongbat-hotbar",
    Files = {
        "MongbatHotbar.xml",
    },
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
