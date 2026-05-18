---@diagnostic disable: undefined-global
-- ========================================================================== --
-- _Mongbat.Systems.Drag: Mouse drag detection
-- ========================================================================== --
--
-- Tracks the Windows-registry entry that received LButtonDown so that:
--   (a) LButtonUp on a child window still routes back to the original window.
--   (b) If the mouse moved between Down and Up the click is suppressed.
--
-- Orchestration (SetMoving, Snap.BeginDrag) stays in Mongbat.lua's event
-- handlers. This module only owns the active-drag state.
--
-- Public surface: _Mongbat.Systems.Drag
--   .Begin(data)   start a drag from a Windows-registry-like data table
--   .Clear()       cancel / clear active drag
--   .GetActive()   returns the active DragState or nil
--   .IsActive()    returns true when a drag is in progress

local Systems = _Mongbat.Systems

--- Data recorded at LButtonDown time.
---@class DragState
---@field engineName string  Engine name of the window that received LButtonDown.
---@field key string         Mod key for the pressed window.
---@field module ModModule   Mod module owning the pressed window.
---@field mover string?      Engine name of the draggable root (nil if non-draggable).
---@field mx number          Mouse x at LButtonDown.
---@field my number          Mouse y at LButtonDown.

---@class Drag
local Drag = {}
Systems.Drag = Drag

---@type DragState?
local _activeDrag = nil

--- Records a drag starting from the given data table.
---@param data DragState
function Drag.Begin(data)
    _activeDrag = data
end

--- Clears the active drag state.
function Drag.Clear()
    _activeDrag = nil
end

--- Returns the active drag state, or nil when no drag is in progress.
---@return DragState?
function Drag.GetActive()
    return _activeDrag
end

--- Returns true when a drag is currently in progress.
---@return boolean
function Drag.IsActive()
    return _activeDrag ~= nil
end
