---@diagnostic disable: undefined-global
-- ========================================================================== --
-- _Mongbat.Systems.Mods: Mod class + lifecycle bookkeeping
-- ========================================================================== --
--
-- Owns the Mod class (enabled-state persistence, resource loading) and the
-- per-frame fan-out across loaded mods (OnUpdate -> tick subsystems ->
-- Build.RunMod).
--
-- Public surface: _Mongbat.Systems.Mods
--   .Mod                          Mod class (factory: Mods.Mod:new(model))
--   .Load(modName, module)        register + call module.OnLoad
--   .Unload(modName)              call module.OnUnload + Build.TeardownMod
--   .UnloadAll()                  unload every loaded mod
--   .PerFrame(dt)                 per-frame fan-out
--   .Loaded                       array { name, module } in registration order
--   .ForEachRegistered(fn)        iterate every Mongbat.Mod{...} registration

local Systems = _Mongbat.Systems

---@class Mods
local Mods = {}
Systems.Mods = Mods

-- Loaded mod modules in registration order.
-- Array of { name: string, module: ModModule }
---@type { name: string, module: ModModule }[]
local LoadedMods = {}
Mods.Loaded = LoadedMods

-- All Mongbat.Mod{...} registrations, keyed by mod name. Includes mods
-- that are disabled (and therefore not in LoadedMods).
---@type table<string, Mod>
local Registered = {}

-- ----- Mod class -----------------------------------------------------------

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
Mods.Mod = Mod

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
    Registered[mod.Name] = mod
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

-- ----- Lifecycle -----------------------------------------------------------

--- Registers and loads a mod. Appends to the per-frame fan-out list
--- and calls `module.OnLoad()` if defined.
---@param modName string
---@param module ModModule
function Mods.Load(modName, module)
    LoadedMods[#LoadedMods + 1] = { name = modName, module = module }
    if module.OnLoad then module.OnLoad() end
end

--- Unloads a mod by name. Calls `module.OnUnload()`, tears down Build
--- windows, and removes the mod from the per-frame fan-out list.
---@param modName string
function Mods.Unload(modName)
    for i = #LoadedMods, 1, -1 do
        if LoadedMods[i].name == modName then
            local m = LoadedMods[i].module
            if m.OnUnload then m.OnUnload() end
            Systems.Build.TeardownMod(modName)
            table.remove(LoadedMods, i)
            return
        end
    end
end

--- Unloads every currently-loaded mod. Called on framework shutdown.
function Mods.UnloadAll()
    Mongbat.Utils.Table.ForEach(Registered, function(_, m)
        Mods.Unload(m.Name)
    end)
end

--- Per-frame fan-out: OnUpdate -> Resize.Tick -> Snap.Tick -> Build.RunMod.
---@param dt number Elapsed time since the last frame (seconds).
function Mods.PerFrame(dt)
    Mongbat.Utils.Array.ForEach(LoadedMods, function(entry)
        local fn = entry.module.OnUpdate
        if fn then fn(dt) end
    end)
    Systems.Resize.Tick()
    Systems.Snap.Tick()
    Mongbat.Utils.Array.ForEach(LoadedMods, function(entry)
        Systems.Build.RunMod(entry.name, entry.module)
    end)
end
