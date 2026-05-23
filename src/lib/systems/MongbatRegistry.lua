---@diagnostic disable: undefined-global
-- ========================================================================== --
-- _Mongbat.Systems.Registry: Window registry + routable-event attachment
-- ========================================================================== --
--
-- Owns the canonical name -> WindowEntry map and the per-window
-- RegisterCoreEventHandler wiring. No other system writes to Windows
-- directly; all mutations go through Registry.Set / Registry.Remove.
--
-- Public surface: _Mongbat.Systems.Registry
--   .Get(name)                      WindowEntry or nil
--   .Set(name, entry)               store an entry
--   .Remove(name)                   delete an entry
--   .AttachEvents(name)             register all RoutableEvents on a window
--   .GetDraggableRoot(parentEngine) resolve draggable root from parent entry

local Systems = _Mongbat.Systems

--- Registry entry for a window managed by Mongbat.
---@class WindowEntry
---@field module ModModule      The owning mod's module table.
---@field key string            The key within the owning mod (passed to event handlers).
---@field id number?            WindowData id registered for this window.
---@field engineName string     Engine name of this window.
---@field rootKey string?       Root emit key for this window's emitted subtree.
---@field draggableRoot string? Engine name of the root window to call SetMoving on.
---@field snappable boolean?    Whether this window participates in edge-snap.
---@field savePosition boolean? Whether screen position is saved/restored.

--- Public window context passed to routed mod handlers.
---@class RoutedWindow
---@field name string           Engine name of this window.
---@field engineName string     Engine name of this window.
---@field key string            The key within the owning mod.
---@field id number?            WindowData id registered for this window.
---@field rootKey string?       Root emit key for this window's emitted subtree.

---@class Registry
local Registry = {}
Systems.Registry = Registry

--- name -> WindowEntry
---@type table<string, WindowEntry>
local Windows = {}

--- Routable engine events. Attached to each registered window at creation
--- time so the router can dispatch them by active-window lookup.
--- OnInitialize is absent: it cannot be runtime-registered (window doesn't
--- exist yet); Mongbat XML templates declare it directly.
local RoutableEvents = {
    "OnShown", "OnHidden", "OnShutdown",
    "OnLButtonUp", "OnLButtonDown",
    "OnRButtonUp", "OnRButtonDown",
    "OnLButtonDblClk",
    "OnMouseOver", "OnMouseOverEnd", "OnMouseWheel",
    "OnEditBoxChanged", "OnEditBoxKeyEscape",
    "OnEditBoxKeyReturn", "OnEditBoxKeyTab",
}

--- Returns the registry entry for `name`, or nil.
---@param name string
---@return WindowEntry?
function Registry.Get(name)
    return Windows[name]
end

--- Stores `entry` under `name`.
---@param name string
---@param entry WindowEntry
function Registry.Set(name, entry)
    Windows[name] = entry
end

--- Removes the entry for `name`.
---@param name string
function Registry.Remove(name)
    Windows[name] = nil
end

--- Registers all RoutableEvents on `name` so the router can dispatch them.
---@param name string
function Registry.AttachEvents(name)
    Mongbat.Utils.Array.ForEach(RoutableEvents, function(event)
        Mongbat.Api.Window.RegisterCoreEventHandler(name, event, "Mongbat.EventHandler." .. event)
    end)
end

--- Returns the draggableRoot that a new child window should inherit from its
--- parent. Pass the parent's engine name; returns nil when parent is "Root"
--- or the parent has no draggableRoot.
---@param parentEngine string
---@return string?
function Registry.GetDraggableRoot(parentEngine)
    if not parentEngine or parentEngine == "Root" then return nil end
    local parentEntry = Windows[parentEngine]
    return parentEntry and parentEntry.draggableRoot or nil
end
