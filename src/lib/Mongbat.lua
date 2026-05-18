---@diagnostic disable: undefined-global
-- ========================================================================== --
-- Mongbat — public surface + bootstrap
-- ========================================================================== --
--
-- All heavy subsystems live in _Mongbat.Systems.* (loaded via MongbatSystems.mod):
--   DataReg   — WindowData ref-counting
--   Registry  — name -> WindowEntry map + event attachment
--   Router    — EventHandler table + dispatchActive
--   Build     — declarative Build reconciler
--   Snap      — edge-snap
--   Resize    — live resize grip
--   Drag      — drag state
--   Mods      — Mod class + lifecycle bookkeeping + per-frame fan-out
--
-- This file owns only the public Mongbat.* surface (`Mongbat.Mod` factory,
-- `Mongbat.ModManager`, `Mongbat.GetWindow`, `Mongbat.EventHandler`) and
-- the engine-entry-point glue (`_Mongbat.OnInitialize/OnUpdate/OnShutdown`).

-- Mongbat = {} is declared in MongbatInternal.lua, which loads before this
-- file. Sub-modules populate Mongbat.Api, .Utils, .Constants, .Data.

local ModsSystem = _Mongbat.Systems.Mods

Mongbat.ModManager = {}

--- Registers a mod for deferred loading. Two-phase contract:
---
---   Phase 1 (NOW, during this call): the mod's .lua file has already been
---     executed by its .mod manifest, so the module table exists. We build
---     a `ModManager[name]` entry exposing `OnInitialize` / `OnShutdown`
---     stubs the manifest will call. The mod is registered but not yet
---     "loaded" — no resources fetched, no OnLoad fired.
---
---   Phase 2 (LATER, when the manifest's <OnInitialize> fires): the engine
---     calls `Mongbat.ModManager[name].OnInitialize`, which checks the
---     persisted enabled flag, loads XML/font/texture resources, and
---     finally invokes the mod's `Module.OnLoad`. From this point the mod
---     participates in the per-frame Build fan-out.
---
--- The split exists because every consumer mod's .mod manifest depends on
--- the framework's .mod, so all `Mongbat.Mod{...}` calls happen during
--- Lua file evaluation — before the engine fires per-manifest OnInitialize
--- callbacks. Letting the manifest drive the second phase ensures resource
--- loading and OnLoad happen at the correct lifecycle moment for each mod.
---@param model ModModel
---@return Mod
function Mongbat.Mod(model)
    local mod = ModsSystem.Mod:new(model)
    if mod:isEnabled() == nil then
        mod:setEnabled(true)
    end
    Mongbat.ModManager[model.Name] = {
        OnInitialize = function()
            if mod:isEnabled() == false then return end
            mod:loadResources()
            ModsSystem.Load(mod.Name, mod.Module)
        end,
        OnShutdown = function()
            ModsSystem.Unload(mod.Name)
        end,
    }
    return mod
end

--- Returns the registry entry for a window, or nil.
---@param name string
---@return WindowEntry?
function Mongbat.GetWindow(name)
    return _Mongbat.Systems.Registry.Get(name)
end

-- Global handler table referenced by XML templates and runtime
-- WindowRegisterCoreEventHandler calls. Must be assigned to Mongbat
-- (not just the Router) so the engine can look it up by string name.
Mongbat.EventHandler = _Mongbat.Systems.Router.EventHandler

-- ----- Lib bootstrap -------------------------------------------------------

-- _Mongbat is initialized in MongbatInternal.lua.
function _Mongbat.OnInitialize()
    -- Load the lib's own XML templates.
    -- Consumer mods are loaded individually via Mongbat.ModManager.<Name>.OnInitialize,
    -- which fires from each mod's own .mod manifest after its .lua file is loaded.
    LoadResources(
        "Data/Interface/Default/project-mongbat/src/lib",
        SystemData.Directories.Interface .. "/" ..
            SystemData.Settings.Interface.customUiName .. "/src/lib",
        "Mongbat.xml"
    )
end

function _Mongbat.OnUpdate(timePassed)
    _Mongbat.Systems.Mods.PerFrame(timePassed)
end

function _Mongbat.OnShutdown()
    _Mongbat.Systems.Mods.UnloadAll()
end
