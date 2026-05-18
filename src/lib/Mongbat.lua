---@diagnostic disable: undefined-global
-- ========================================================================== --
-- Mongbat — core coordinator
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
--
-- This file is the public surface (Mongbat.*) and the mod lifecycle
-- coordinator (Core.*). It does not contain logic that belongs in a subsystem.

local Core = {}

-- Loaded mod modules in registration order.
-- Array of { name: string, module: ModModule }
---@type { name: string, module: ModModule }[]
local LoadedMods = {}

-- ----- Mod lifecycle -------------------------------------------------------

--- Registers and loads a mod. Appends to the per-frame fan-out list
--- and calls `module.OnLoad()` if defined.
---@param modName string
---@param module ModModule
function Core.LoadMod(modName, module)
    LoadedMods[#LoadedMods + 1] = { name = modName, module = module }
    if module.OnLoad then module.OnLoad() end
end

--- Unloads a mod by name. Calls `module.OnUnload()`, tears down Build
--- windows, and removes the mod from the per-frame fan-out list.
---@param modName string
function Core.UnloadMod(modName)
    for i = #LoadedMods, 1, -1 do
        if LoadedMods[i].name == modName then
            local m = LoadedMods[i].module
            if m.OnUnload then m.OnUnload() end
            _Mongbat.Systems.Build.TeardownMod(modName)
            table.remove(LoadedMods, i)
            return
        end
    end
end

--- Returns the registry entry for a window, or nil.
---@param name string
---@return WindowEntry?
function Core.GetWindow(name)
    return _Mongbat.Systems.Registry.Get(name)
end

--- Per-frame fan-out: OnUpdate -> Resize.Tick -> Snap.Tick -> Build.RunMod.
---@param dt number Elapsed time since the last frame (seconds).
function Core.PerFrame(dt)
    Mongbat.Utils.Array.ForEach(LoadedMods, function(entry)
        local fn = entry.module.OnUpdate
        if fn then fn(dt) end
    end)
    _Mongbat.Systems.Resize.Tick()
    _Mongbat.Systems.Snap.Tick()
    Mongbat.Utils.Array.ForEach(LoadedMods, function(entry)
        _Mongbat.Systems.Build.RunMod(entry.name, entry.module)
    end)
end


-- ========================================================================== --
-- Mod
-- ========================================================================== --

--- The mod module table. All fields are optional; implement only what you need.
--- Lifecycle methods (OnLoad/OnUnload/OnUpdate) receive no window arguments.
--- Per-window event handlers always receive (name: string, key: string, ...) first.
---@class ModModule
---@field OnLoad           (fun())?                                                              Called once when the mod is loaded.
---@field OnUnload         (fun())?                                                              Called once when the mod is unloaded.
---@field OnUpdate         (fun(dt: number))?                                                    Called every frame, once per mod.
---@field Build            (fun(emit: fun(key: string, spec: table)))?                           Declarative window emission. Called every frame; emit each window the mod wants. Lib diffs vs prior frame.
---@field OnInitialize     (fun(name: string, key: string))?                                     Engine window created.
---@field OnShown          (fun(name: string, key: string))?                                     Window became visible.
---@field OnHidden         (fun(name: string, key: string))?                                     Window became hidden.
---@field OnShutdown       (fun(name: string, key: string))?                                     Window is being destroyed.
---@field OnLButtonUp      (fun(name: string, key: string, flags: number, x: number, y: number))? Left mouse button released.
---@field OnLButtonDown    (fun(name: string, key: string, flags: number, x: number, y: number))? Left mouse button pressed.
---@field OnRButtonUp      (fun(name: string, key: string, flags: number, x: number, y: number))? Right mouse button released.
---@field OnRButtonDown    (fun(name: string, key: string, flags: number, x: number, y: number))? Right mouse button pressed.
---@field OnLButtonDblClk  (fun(name: string, key: string, flags: number, x: number, y: number))? Left mouse double-click.
---@field OnMouseOver      (fun(name: string, key: string))?                                     Cursor entered window.
---@field OnMouseOverEnd   (fun(name: string, key: string))?                                     Cursor left window.
---@field OnMouseWheel     (fun(name: string, key: string, x: number, y: number, delta: number))? Scroll wheel moved.
---@field OnEditBoxChanged    (fun(name: string, key: string))?                                  Edit box text changed.
---@field OnEditBoxKeyEscape  (fun(name: string, key: string))?                                  Escape pressed in edit box.
---@field OnEditBoxKeyReturn  (fun(name: string, key: string))?                                  Return pressed in edit box.
---@field OnEditBoxKeyTab     (fun(name: string, key: string))?                                  Tab pressed in edit box.

---@class Mod
---@field Name string Name of the mod
---@field Path string Path to the mod resources
---@field Files string[]? list of files to load
---@field Module ModModule The mod's module table (event handlers + state)
local Mod = {}
Mod.__index = Mod

---@class ModModel
---@field Name string Name of the mod
---@field Path string Path to the mod resources
---@field Files string[]? list of files to load
---@field Module ModModule The mod's module table.

---@param model ModModel
---@return Mod
function Mod:new(model)
    local mod = setmetatable({}, self)
    mod.Name   = model.Name
    mod.Path   = model.Path
    mod.Files  = model.Files or {}
    mod.Module = model.Module or {}
    return mod
end

--- Persists the enabled state of the mod to Interface storage.
---@param isEnabled boolean Whether the mod is enabled.
function Mod:setEnabled(isEnabled)
    Mongbat.Api.Interface.SaveBoolean("Mongbat.Mods." .. self.Name .. ".Enabled", isEnabled)
end

--- Returns the persisted enabled state of the mod from Interface storage.
---@return boolean? The enabled state, or nil if not yet set.
function Mod:isEnabled()
    return Mongbat.Api.Interface.LoadBoolean("Mongbat.Mods." .. self.Name .. ".Enabled", true)
end

--- Loads all resource files declared in `self.Files` for this mod, resolving
--- both the shipped path and the installed Interface path.
function Mod:loadResources()
    Mongbat.Utils.Array.ForEach(
        self.Files,
        function(file)
            Mongbat.Api.Mod.LoadResources(
                "Data/Interface/Default/project-mongbat" .. self.Path,
                SystemData.Directories.Interface .. "/" .. SystemData.Settings.Interface.customUiName .. self.Path,
                file
            )
        end
    )
end


-- ========================================================================== --
-- Mongbat public surface
-- ========================================================================== --

-- Mongbat = {} is declared in MongbatInternal.lua, which loads before this
-- file. Sub-modules populate Mongbat.Api, .Utils, .Constants, .Data.

---@type table<string, Mod>
local Mods = {}

Mongbat.ModManager = {}

---@param model ModModel
---@return Mod
function Mongbat.Mod(model)
    local mod = Mod:new(model)
    Mods[model.Name] = mod
    if mod:isEnabled() == nil then
        mod:setEnabled(true)
    end
    -- ModManager entries are called by each consumer mod's .mod manifest
    -- <OnInitialize>/<OnShutdown>, which fire after the mod's .lua file is loaded.
    Mongbat.ModManager[model.Name] = {
        OnInitialize = function()
            if mod:isEnabled() == false then return end
            mod:loadResources()
            Core.LoadMod(mod.Name, mod.Module)
        end,
        OnShutdown = function()
            Core.UnloadMod(mod.Name)
        end,
    }
    return mod
end

-- Window registry / event router.
Mongbat.GetWindow = Core.GetWindow

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
    Core.PerFrame(timePassed)
end

function _Mongbat.OnShutdown()
    Mongbat.Utils.Table.ForEach(Mods, function(_, m)
        Core.UnloadMod(m.Name)
    end)
end