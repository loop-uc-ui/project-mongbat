---@diagnostic disable: undefined-global
-- ========================================================================== --
-- _Mongbat.Systems.Router: Event dispatch + EventHandler table
-- ========================================================================== --
--
-- Owns the Mongbat.EventHandler table that XML templates and runtime
-- RegisterCoreEventHandler calls point at. Each handler looks up the
-- active window in the Registry and calls the matching method on its
-- owning mod's module table with a public window context.
--
-- OnLButtonDown/Up additionally orchestrate drag (Drag system) and
-- snap (Snap system). OnLiveResizeUp ends a live resize (Resize system).
--
-- Public surface: _Mongbat.Systems.Router
--   .EventHandler   table assigned to Mongbat.EventHandler at boot
--   .Dispatch(eventName, ...)  dispatch an event to the active window

local Systems = _Mongbat.Systems

---@class Router
local Router = {}
Systems.Router = Router

-- ----- Dispatch ------------------------------------------------------------

local function windowContext(entry)
    return {
        name       = entry.engineName,
        engineName = entry.engineName,
        key        = entry.key,
        id         = entry.id,
        rootKey    = entry.rootKey,
    }
end

--- Looks up the active window in the Registry and invokes the owning
--- mod's matching event function with `(window, ...)`. No-op when the
--- window isn't registered or the module doesn't implement the event.
---
--- When `Mongbat.Debugger.SetVerbose(true)` is set, logs every dispatch
--- attempt — both routed calls and silent no-ops (window not registered,
--- or registered but module lacks the handler). Useful for diagnosing
--- "why didn't my handler fire?" without sprinkling prints into mods.
---@param eventName string
local function dispatchActive(eventName, ...)
    local name  = SystemData.ActiveWindow.name
    local entry = Systems.Registry.Get(name)
    local verbose = Mongbat.Debugger.IsVerbose()
    if not entry then
        if verbose then
            Mongbat.Debugger.Print("[Mongbat] " .. eventName .. " -> "
                .. tostring(name) .. " (no registry entry)")
        end
        return
    end
    local fn = entry.module[eventName]
    if fn then
        if verbose then
            Mongbat.Debugger.Print("[Mongbat] " .. eventName .. " -> "
                .. name .. " (" .. entry.key .. ")")
        end
        fn(windowContext(entry), ...)
    elseif verbose then
        Mongbat.Debugger.Print("[Mongbat] " .. eventName .. " -> "
            .. name .. " (" .. entry.key .. ") — no handler")
    end
end

Router.Dispatch = dispatchActive

-- ----- EventHandler table --------------------------------------------------

---@class EventHandler
local EventHandler = {}
Router.EventHandler = EventHandler

EventHandler.OnInitialize    = function() dispatchActive("OnInitialize") end
EventHandler.OnShutdown      = function() dispatchActive("OnShutdown") end
EventHandler.OnShown         = function() dispatchActive("OnShown") end
EventHandler.OnHidden        = function() dispatchActive("OnHidden") end

-- OnLButtonDown/Up orchestrate drag + snap using the sub-systems.
-- Drag owns the active-drag state; Snap owns the snap preview.

EventHandler.OnLButtonDown = function(flags, x, y)
    local name  = SystemData.ActiveWindow.name
    local entry = Systems.Registry.Get(name)
    if entry then
        local mp    = Mongbat.Data.MousePosition()
        local mover = entry.draggableRoot
        if mover then
            if Mongbat.Data.IsShift(flags) then
                Systems.Snap.Detach(mover)
            end
            Mongbat.Api.Window.SetMoving(mover, true)
            local moverEntry = Systems.Registry.Get(mover)
            if moverEntry and moverEntry.snappable then
                Systems.Snap.BeginDrag(mover)
            end
        end
        Systems.Drag.Begin({
            engineName = entry.engineName,
            key        = entry.key,
            window     = windowContext(entry),
            module     = entry.module,
            mover      = mover,
            mx         = mp.x,
            my         = mp.y,
        })
    else
        Systems.Drag.Clear()
    end
    dispatchActive("OnLButtonDown", flags, x, y)
end

EventHandler.OnLButtonUp = function(flags, x, y)
    local drag = Systems.Drag.GetActive()
    Systems.Drag.Clear()
    if drag then
        if drag.mover then Mongbat.Api.Window.SetMoving(drag.mover, false) end
        Systems.Snap.Commit()
        local mp = Mongbat.Data.MousePosition()
        if mp.x ~= drag.mx or mp.y ~= drag.my then
            return  -- mouse moved: window was dragged, suppress click
        end
        -- Mouse did not move: dispatch Up to the original down-window.
        -- This handles the case where LButtonUp fires on a child window
        -- rather than the window that received LButtonDown.
        local fn = drag.module["OnLButtonUp"]
        if fn then fn(drag.window, flags, x, y) end
        return
    end
    dispatchActive("OnLButtonUp", flags, x, y)
end

EventHandler.OnRButtonUp = function(flags, x, y)
    local name  = SystemData.ActiveWindow.name
    local entry = Systems.Registry.Get(name)
    if not entry then return end
    -- Mod-level override takes full control.
    if entry.module["OnRButtonUp"] then
        dispatchActive("OnRButtonUp", flags, x, y)
        return
    end
    -- Default: dismiss the chain-root subtree containing this window.
    -- Dismiss auto-clears when the mod stops re-emitting the root, so
    -- this is non-permanent and safe to apply uniformly.
    local ref = Systems.Build.GetRoot(name)
    if ref then
        Systems.Build.Dismiss(ref.modName, ref.rootKey)
    end
end
EventHandler.OnRButtonDown   = function(flags, x, y) dispatchActive("OnRButtonDown",   flags, x, y) end
EventHandler.OnLButtonDblClk = function(flags, x, y) dispatchActive("OnLButtonDblClk", flags, x, y) end
EventHandler.OnMouseOver     = function() dispatchActive("OnMouseOver") end
EventHandler.OnMouseOverEnd  = function() dispatchActive("OnMouseOverEnd") end
EventHandler.OnMouseWheel    = function(x, y, delta) dispatchActive("OnMouseWheel", x, y, delta) end
EventHandler.OnSlide         = function(value) dispatchActive("OnSlide", value) end
EventHandler.OnSelChanged    = function(...) dispatchActive("OnSelChanged", ...) end
EventHandler.OnEditBoxChanged   = function() dispatchActive("OnEditBoxChanged") end
EventHandler.OnEditBoxKeyEscape = function() dispatchActive("OnEditBoxKeyEscape") end
EventHandler.OnEditBoxKeyReturn = function() dispatchActive("OnEditBoxKeyReturn") end
EventHandler.OnEditBoxKeyTab    = function() dispatchActive("OnEditBoxKeyTab") end

-- Ends a live resize drag regardless of where the cursor is when released.
EventHandler.OnLiveResizeUp = function() Systems.Resize.End() end
