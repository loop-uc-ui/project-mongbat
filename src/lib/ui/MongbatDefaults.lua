---@diagnostic disable: undefined-global
-- ========================================================================== --
-- Mongbat.UI.Defaults: Default-UI module suppression + action override
-- ========================================================================== --
--
-- The default UI exposes per-window logic as global module tables matching
-- the window name (e.g. `MapWindow`, `ObjectHandleWindow`, `PaperdollWindow`).
-- When a mod hijacks a default window or lifecycle, those module callbacks
-- still fire on engine events and reach for child windows that no longer
-- exist, spraying anchor errors into the log.
--
-- `Mongbat.UI.Defaults.Suppress(moduleName, fnName?)`
--   Replaces functions on the named default-UI module with no-ops. With a
--   `fnName` only that entry is suppressed; otherwise every function on
--   the module is. `MongbatBuild` calls this automatically with the engine
--   window name for any spec emitted with `replacesDefault = true` -- the
--   default-UI module global is assumed to share that name (the convention
--   the default UI follows).
--
-- `Mongbat.UI.Defaults.OverrideAction(name, fn)`
--   Replaces an entry in the default UI's `Actions` table (the
--   script-callback target hotbar buttons trigger, e.g.
--   `Actions.ToggleMapWindow`). Mods call this from `M.OnLoad` to retake
--   control of a trigger that would otherwise reopen the destroyed default
--   window.

local Defaults = {}

local noop = function() end

--- Suppresses default-UI module callbacks by replacing them with no-ops.
--- Safe to call repeatedly. If `fnName` is omitted, every function on the
--- module is suppressed.
---@param moduleName string  Name of the default-UI module global (e.g. "MapWindow").
---@param fnName    string? Optional single function to suppress.
function Defaults.Suppress(moduleName, fnName)
    local mod = _G[moduleName]
    if type(mod) ~= "table" then return end
    if fnName then
        if type(mod[fnName]) == "function" then mod[fnName] = noop end
        return
    end
    for k, v in pairs(mod) do
        if type(v) == "function" then mod[k] = noop end
    end
end

--- Replaces `Actions[name]` with `fn`. The default UI's hotbar buttons
--- invoke `Actions.<Name>()` via `callback=L"script Actions.<Name>()"`;
--- this is the hook point for re-routing those triggers to a mod.
---@param name string
---@param fn fun()
function Defaults.OverrideAction(name, fn)
    if type(Actions) ~= "table" then return end
    Actions[name] = fn
end

Mongbat.UI.Defaults = Defaults
