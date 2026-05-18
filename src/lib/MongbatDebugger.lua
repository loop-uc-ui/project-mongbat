---@diagnostic disable: undefined-global
---@class Debugger
local Debugger = {}

-- ========================================================================== --
-- Debugger - Debug wrappers
-- ========================================================================== --

---
--- Prints text to the chat log.
---@param text any
function Debugger.PrintToChat(text)
    Debug.PrintToChat(text)
end

---
--- Prints text to the debug console (UiLog + DebugPrint channels).
---@param text any
function Debugger.PrintToDebugConsole(text)
    Debug.PrintToDebugConsole(text)
end

---
--- Prints text to the debug console. If text is a table, dumps it recursively.
---@param text any
function Debugger.Print(text)
    Debug.Print(text)
end

---
--- Recursively dumps a value to the debug console.
---@param name string Label prefix for output lines.
---@param value any The value to dump.
---@param memo table|nil Cycle-detection memo table (pass nil on first call).
function Debugger.DumpToConsole(name, value, memo)
    Debug.DumpToConsole(name, value, memo)
end

---
--- Alias for DumpToConsole.
---@param name string Label prefix for output lines.
---@param value any The value to dump.
---@param memo table|nil Cycle-detection memo table (pass nil on first call).
function Debugger.Dump(name, value, memo)
    Debug.Dump(name, value, memo)
end

-- ========================================================================== --
-- Debugger - Verbose mode
-- ========================================================================== --
-- Controls framework-internal diagnostic output (e.g. Router dispatch
-- traces). Defaults off; opt in with Mongbat.Debugger.SetVerbose(true)
-- when chasing a "why didn't my handler fire?" problem.

local verbose = false

--- Returns true when verbose framework-internal logging is enabled.
---@return boolean
function Debugger.IsVerbose() return verbose end

--- Enables or disables verbose framework-internal logging.
---@param enabled boolean
function Debugger.SetVerbose(enabled) verbose = enabled and true or false end

Mongbat.Debugger = Debugger
