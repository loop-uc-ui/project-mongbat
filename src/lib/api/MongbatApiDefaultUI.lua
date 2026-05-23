---@diagnostic disable: undefined-global
---@class Api
local Api = Mongbat.Api

-- ========================================================================== --
-- Api - Item Properties
-- ========================================================================== --

Api.ItemProperties = {}

---
--- Sets the active item for tooltip display.
---@param itemData { windowName: string, itemId: number, itemType: number, binding: string?, title: string?, body: string?, detail: number? } Item tooltip data.
function Api.ItemProperties.SetActiveItem(itemData)
    ItemProperties.SetActiveItem(itemData)
end

---
--- Clears the current mouse-over item tooltip.
function Api.ItemProperties.ClearMouseOverItem()
    ItemProperties.ClearMouseOverItem()
end


-- ========================================================================== --
-- Api - Equipment
-- ========================================================================== --

Api.Equipment = {}

---
--- Updates an item icon DynamicImage from equipment slot data.
---@param elementName string The DynamicImage window name.
---@param slotData PaperdollSlot The slot data from WindowData.Paperdoll.
function Api.Equipment.UpdateItemIcon(elementName, slotData)
    EquipmentData.UpdateItemIcon(elementName, slotData)
end


-- ========================================================================== --
-- Api - GenericGump
-- ========================================================================== --
--
-- Wraps the default UI's `GenericGump` global so mods never reference it.
-- `OnShown` chains so multiple subscribers compose without clobbering one
-- another or the default UI's own handler.

Api.GenericGump = {}

--- Chains a subscriber to `GenericGump.OnShown`. Preserves the existing
--- handler so multiple subscribers compose without clobbering each other.
---@param fn fun()
function Api.GenericGump.OnShown(fn)
    local previous = GenericGump.OnShown or function() end
    GenericGump.OnShown = function()
        previous()
        fn()
    end
end

--- Returns the label list populated by the last parsed generic gump.
---@return { windowName: string }[]
function Api.GenericGump.GetLastLabels()
    return GenericGump.LastGumpLabels or {}
end


-- ========================================================================== --
-- Api - GumpsParsing
-- ========================================================================== --
--
-- Wraps the default UI's `GumpsParsing` global. `SetGumpName` is used to
-- defeat specialised renderers by renaming their entry in `GumpMaps`.
-- `SuppressGump` chains the per-frame parsing pass and clears the named
-- gump from `ToShow` so the engine never displays it.

Api.GumpsParsing = {}

--- Returns the gump name for a given gump ID from `GumpsParsing.GumpMaps`,
--- or nil if no entry exists.
---@param id integer
---@return string?
function Api.GumpsParsing.GetGumpName(id)
    local entry = GumpsParsing.GumpMaps[id]
    return entry and entry.name
end

--- Sets the gump name for a given gump ID in `GumpsParsing.GumpMaps`.
--- Used to defeat specialised renderers by renaming their entry.
---@param id integer
---@param name string
function Api.GumpsParsing.SetGumpName(id, name)
    GumpsParsing.GumpMaps[id].name = name
end

--- Chains a subscriber to `GumpsParsing.MainParsingCheck`. Preserves the
--- existing handler so multiple subscribers compose.
---@param fn fun(timePassed: number)
function Api.GumpsParsing.OnParsingCheck(fn)
    local previous = GumpsParsing.MainParsingCheck
    GumpsParsing.MainParsingCheck = function(timePassed)
        previous(timePassed)
        fn(timePassed)
    end
end

--- Permanently suppresses a gump from being displayed. Chains into
--- `MainParsingCheck` and clears the gump from `ToShow` each frame.
---@param gumpId integer
function Api.GumpsParsing.SuppressGump(gumpId)
    Api.GumpsParsing.OnParsingCheck(function()
        GumpsParsing.ToShow[gumpId] = nil
    end)
end


-- ========================================================================== --
-- Api - HealthBar
-- ========================================================================== --
--
-- The default UI exposes the health-bar drag entry point on
-- `ObjectHandleWindow`. Mods see it as a HealthBar concern.

Api.HealthBar = {}

--- Begins a health bar drag for a mobile by delegating to
--- `ObjectHandleWindow.OnBeginDragHealthBar`.
---@param id integer
function Api.HealthBar.BeginDrag(id)
    if ObjectHandleWindow and ObjectHandleWindow.OnBeginDragHealthBar then
        ObjectHandleWindow.OnBeginDragHealthBar(id)
    end
end


-- ========================================================================== --
-- Api - ObjectHandle
-- ========================================================================== --
--
-- Wraps the default UI's `ObjectHandleWindow` lifecycle. `OnCreate` and
-- `OnDestroy` chain into the engine's create/destroy entry points so
-- multiple subscribers compose alongside the default UI's own handlers.

Api.ObjectHandle = {}

local function chainObjectHandleWindow(method, fn)
    if not ObjectHandleWindow then return end
    local previous = ObjectHandleWindow[method] or function(...) end
    ObjectHandleWindow[method] = function(...)
        previous(...)
        fn(...)
    end
end

--- Chains a subscriber to `ObjectHandleWindow.CreateObjectHandles`.
--- Called when the engine creates the object handle windows.
---@param fn fun()
function Api.ObjectHandle.OnCreate(fn)
    chainObjectHandleWindow("CreateObjectHandles", fn)
end

--- Chains a subscriber to `ObjectHandleWindow.DestroyObjectHandles`.
--- Called when the engine destroys the object handle windows.
---@param fn fun()
function Api.ObjectHandle.OnDestroy(fn)
    chainObjectHandleWindow("DestroyObjectHandles", fn)
end

