---@diagnostic disable: undefined-global
-- ========================================================================== --
-- Substrate: Window Registry + Event Router
-- ========================================================================== --
--
-- Mongbat is a router. Mods own all state. The library's job is:
--
--   1. Maintain a registry of (window name) -> (mod module, key).
--   2. Provide global handler stubs (Mongbat.EventHandler.X) that XML
--      templates and runtime registrations point at.
--   3. When the engine fires an event, look up SystemData.ActiveWindow.name
--      in the registry and dispatch to the owning mod's module function:
--          M.<EventName>(name, key, ...)
--   4. Provide a single helper that creates a window, registers it, and
--      attaches all routable engine events + WindowData bindings.
--
-- Mods are plain Lua module tables. A mod looks like:
--
--     local M = {}
--     local state = {}
--
--     function M.OnLoad()
--         Mongbat.CreateWindow {
--             name     = "MongbatX",
--             template = "MongbatWindow",
--             module   = M,
--             key      = "main",
--             bindings = { "PlayerStatus" },
--         }
--     end
--
--     function M.OnInitialize(name, key) ... end
--     function M.OnLButtonUp(name, key, flags, x, y) ... end
--     function M.OnUpdatePlayerStatus(name, key, data) ... end
--     function M.OnUnload() end
--
--     Mongbat.Mod { Name = "MongbatX", Path = "/src/mods/mongbat-x", Module = M }
--
-- The framework never holds closures, never diffs descriptors, never
-- rebuilds anything per frame. The engine fires; we look up; we call.

local Core = {}

-- name -> { module = table, key = string }
local Windows = {}

-- Resizable windows config: [windowName] -> { minW, minH, onResizeEnd? }
local ResizableWindows = {}

-- Internal module shared by all auto-created MongbatResizeGrip children.
local ResizeGripModule = {}
function ResizeGripModule.OnLButtonDown(name, _key)
    -- Strip the "ResizeGrip" suffix to get the parent window name.
    local parentName = name:sub(1, -(#"ResizeGrip" + 1))
    local cfg = ResizableWindows[parentName]
    if not cfg then return end
    Mongbat.Api.Window.BeginResize(parentName, "topleft", cfg.minW, cfg.minH, false, cfg.onResizeEnd)
end

-- Loaded mod modules in registration order. OnUpdate fan-out walks this.
local LoadedMods = {}    -- array of { name = string, module = table }

-- Per-binding-key state. Each binding key gets one global per-window
-- handler name; the engine fires it on the active window only when that
-- window is registered for the binding.
local BindingsRegistered = {}    -- [dataKey] = number of windows currently subscribed

-- Routable per-window engine events. When a window is registered, we
-- attach `Mongbat.EventHandler.<event>` to each of these. The dispatcher
-- looks up the active window in the registry and calls
-- `module.<event>(name, key, ...)` if the module defines it.
--
-- OnInitialize is intentionally absent: it cannot be runtime-registered
-- because the window doesn't exist yet. Mongbat XML templates declare
-- it directly (see Mongbat.xml).
local RoutableEvents = {
    "OnShown", "OnHidden", "OnShutdown",
    "OnLButtonUp", "OnLButtonDown",
    "OnRButtonUp", "OnRButtonDown",
    "OnLButtonDblClk",
    "OnMouseOver", "OnMouseOverEnd", "OnMouseWheel",
    "OnEditBoxChanged", "OnEditBoxKeyEscape",
    "OnEditBoxKeyReturn", "OnEditBoxKeyTab",
}

-- ----- Dispatch ------------------------------------------------------------

--- Looks up the active window in the registry and invokes the owning
--- mod's matching event function with `(name, key, ...)`. No-op when the
--- window isn't registered or the module doesn't implement the event.
local function dispatchActive(eventName, ...)
    local name = SystemData.ActiveWindow.name
    local entry = Windows[name]
    if not entry then return end
    local fn = entry.module[eventName]
    if fn then
        Mongbat.Debugger.Print("[Mongbat] " .. eventName .. " -> " .. name .. " (" .. entry.key .. ")")
        fn(name, entry.key, ...)
    end
end

-- ----- Registration --------------------------------------------------------

local function attachRoutableEvents(name)
    Mongbat.Utils.Array.ForEach(RoutableEvents, function(event)
        Mongbat.Api.Window.RegisterCoreEventHandler(name, event, "Mongbat.EventHandler." .. event)
    end)
end

local function attachBinding(name, dataKey)
    local dataEvent = Mongbat.Constants.DataEvents["OnUpdate" .. dataKey]
    if not dataEvent then
        error("Mongbat: unknown binding key '" .. tostring(dataKey) ..
            "' (no Constants.DataEvents.OnUpdate" .. tostring(dataKey) .. ")")
    end
    -- One global dispatcher per binding key; lazy-installed on first subscriber.
    if not BindingsRegistered[dataKey] then
        BindingsRegistered[dataKey] = 0
        Mongbat.EventHandler["OnUpdate" .. dataKey] = function()
            dispatchActive("OnUpdate" .. dataKey, WindowData[dataKey])
        end
        Mongbat.Api.Window.RegisterData(dataEvent.getType(), 0)
    end
    BindingsRegistered[dataKey] = BindingsRegistered[dataKey] + 1
    -- Per-window event subscription so ActiveWindow is set when the engine
    -- fires. The engine pushes the event to each window that asked for it.
    Mongbat.Api.Window.RegisterEventHandler(name, dataEvent.getEvent(),
        "Mongbat.EventHandler.OnUpdate" .. dataKey)
    -- Prime the initial render: if data is already populated when the window
    -- registers (e.g. re-load while logged in), the engine won't fire a
    -- spontaneous event, so call the handler directly with the current data.
    local entry = Windows[name]
    if entry then
        local fn = entry.module["OnUpdate" .. dataKey]
        local data = WindowData[dataKey]
        if fn and data then
            fn(name, entry.key, data)
        end
    end
end

--- Unsubscribes a window's bindings. Calls UnregisterWindowData when the
--- last subscriber for a given key is removed.
local function detachBindings(name)
    local entry = Windows[name]
    if not entry or not entry.bindings then return end
    Mongbat.Utils.Array.ForEach(entry.bindings, function(dataKey)
        local count = BindingsRegistered[dataKey]
        if not count then return end
        count = count - 1
        if count <= 0 then
            BindingsRegistered[dataKey] = nil
            local dataEvent = Mongbat.Constants.DataEvents["OnUpdate" .. dataKey]
            if dataEvent then
                Mongbat.Api.Window.UnregisterData(dataEvent.getType(), 0)
            end
        else
            BindingsRegistered[dataKey] = count
        end
    end)
end

--- Adds a window to the registry without creating it. Use when the window
--- already exists by other means and you want it routed.
---@param opts { name: string, module: ModModule, key: string?, bindings: string[]? }
function Core.RegisterWindow(opts)
    local name   = opts.name
    local module = opts.module
    if not name   then error("Mongbat.RegisterWindow: name required") end
    if not module then error("Mongbat.RegisterWindow: module required") end
    Windows[name] = { module = module, key = opts.key or name, bindings = opts.bindings }
    attachRoutableEvents(name)
    if opts.bindings then
        Mongbat.Utils.Array.ForEach(opts.bindings, function(key) attachBinding(name, key) end)
    end
end

--- Creates a window from a template, registers it, attaches all routable
--- engine events, and (optionally) attaches WindowData bindings.
---
--- Registry insertion happens BEFORE Mongbat.Api.Window.CreateFromTemplate so the
--- engine's OnInitialize fires into a registry that already knows the
--- window. (OnInitialize is declared on Mongbat templates in XML.)
---
--- When `resizable = true` the lib creates a `MongbatResizeGrip` child anchored
--- to the bottom-right corner and wires it up automatically. Pass `minWidth` /
--- `minHeight` to clamp the resize, and an optional `onResizeEnd` callback for
--- post-resize layout work.
---@param opts { name: string, template: string, module: ModModule, key: string?, parent: string?, showing: boolean?, bindings: string[]?, resizable: boolean?, minWidth: number?, minHeight: number?, onResizeEnd: (fun(windowName: string))? }
function Core.CreateWindow(opts)
    local name = opts.name
    if not name        then error("Mongbat.CreateWindow: name required") end
    if not opts.template then error("Mongbat.CreateWindow: template required") end
    if not opts.module then error("Mongbat.CreateWindow: module required") end
    Windows[name] = { module = opts.module, key = opts.key or name, bindings = opts.bindings }
    Mongbat.Api.Window.CreateFromTemplate(name, opts.template, opts.parent or "Root",
        opts.showing ~= false)
    attachRoutableEvents(name)
    if opts.bindings then
        Mongbat.Utils.Array.ForEach(opts.bindings, function(key) attachBinding(name, key) end)
    end
    if opts.resizable then
        local minW    = opts.minWidth  or 0
        local minH    = opts.minHeight or 0
        ResizableWindows[name] = { minW = minW, minH = minH, onResizeEnd = opts.onResizeEnd }
        local gripName = name .. "ResizeGrip"
        Windows[gripName] = { module = ResizeGripModule, key = "grip" }
        Mongbat.Api.Window.CreateFromTemplate(gripName, "MongbatResizeGrip", name, true)
        attachRoutableEvents(gripName)
        Mongbat.Api.Window.ClearAnchors(gripName)
        Mongbat.Api.Window.AddAnchor(gripName, "bottomright", name, "bottomright", 0, 0)
    end
end

--- Removes a window from the registry and destroys it from the engine.
---@param name string The name of the window to destroy.
function Core.DestroyWindow(name)
    if ResizableWindows[name] then
        ResizableWindows[name] = nil
        Windows[name .. "ResizeGrip"] = nil
        -- The engine destroys child windows automatically when the parent is
        -- destroyed, so no explicit DestroyWindow call is needed for the grip.
    end
    detachBindings(name)
    Windows[name] = nil
    if Mongbat.Api.Window.DoesExist(name) then
        Mongbat.Api.Window.Destroy(name)
    end
end

--- Removes a window from the registry without destroying it. Use when the
--- engine destroyed the window for us (e.g. on shutdown).
---@param name string The name of the window to unregister.
function Core.UnregisterWindow(name)
    if ResizableWindows[name] then
        ResizableWindows[name] = nil
        Windows[name .. "ResizeGrip"] = nil
    end
    detachBindings(name)
    Windows[name] = nil
end

--- Returns the registry entry for a window, or nil.
---@param name string The name of the window.
---@return { module: ModModule, key: string, bindings: string[]? }? The registry entry, or nil if the window is not registered.
function Core.GetWindow(name)
    return Windows[name]
end

-- ----- Mod lifecycle -------------------------------------------------------

--- Registers and loads a mod. Appends the mod to the per-frame fan-out list
--- and calls `module.OnLoad()` if defined.
---@param modName string The name of the mod.
---@param module ModModule The mod's module table.
function Core.LoadMod(modName, module)
    LoadedMods[#LoadedMods + 1] = { name = modName, module = module }
    if module.OnLoad then module.OnLoad() end
end

--- Unloads a mod by name. Calls `module.OnUnload()` if defined and removes
--- the mod from the per-frame fan-out list.
---@param modName string The name of the mod to unload.
function Core.UnloadMod(modName)
    for i = #LoadedMods, 1, -1 do
        if LoadedMods[i].name == modName then
            local m = LoadedMods[i].module
            if m.OnUnload then m.OnUnload() end
            table.remove(LoadedMods, i)
            return
        end
    end
end

--- Per-frame fan-out. Every loaded mod that defines OnUpdate gets called
--- once with `(dt)`. Mods without OnUpdate pay nothing.
---@param dt number Elapsed time in seconds since the last frame.
function Core.PerFrame(dt)
    Mongbat.Utils.Array.ForEach(LoadedMods, function(entry)
        local fn = entry.module.OnUpdate
        if fn then fn(dt) end
    end)
end

-- ----- Global event handler table ------------------------------------------
--
-- Exported as `Mongbat.EventHandler` so XML templates and runtime
-- WindowRegisterCoreEventHandler calls can reference these by string name.
-- Each handler is a thin shim that forwards to dispatchActive.

Core.EventHandler = {}

Core.EventHandler.OnInitialize    = function() dispatchActive("OnInitialize") end
Core.EventHandler.OnShutdown      = function() dispatchActive("OnShutdown") end
Core.EventHandler.OnShown         = function() dispatchActive("OnShown") end
Core.EventHandler.OnHidden        = function() dispatchActive("OnHidden") end
Core.EventHandler.OnLButtonUp     = function(flags, x, y) dispatchActive("OnLButtonUp",     flags, x, y) end
Core.EventHandler.OnLButtonDown   = function(flags, x, y) dispatchActive("OnLButtonDown",   flags, x, y) end
Core.EventHandler.OnRButtonUp     = function(flags, x, y) dispatchActive("OnRButtonUp",     flags, x, y) end
Core.EventHandler.OnRButtonDown   = function(flags, x, y) dispatchActive("OnRButtonDown",   flags, x, y) end
Core.EventHandler.OnLButtonDblClk = function(flags, x, y) dispatchActive("OnLButtonDblClk", flags, x, y) end
Core.EventHandler.OnMouseOver     = function() dispatchActive("OnMouseOver") end
Core.EventHandler.OnMouseOverEnd  = function() dispatchActive("OnMouseOverEnd") end
Core.EventHandler.OnMouseWheel    = function(x, y, delta) dispatchActive("OnMouseWheel", x, y, delta) end
Core.EventHandler.OnSlide         = function(value) dispatchActive("OnSlide", value) end
Core.EventHandler.OnSelChanged    = function(...) dispatchActive("OnSelChanged", ...) end
Core.EventHandler.OnEditBoxChanged   = function() dispatchActive("OnEditBoxChanged") end
Core.EventHandler.OnEditBoxKeyEscape = function() dispatchActive("OnEditBoxKeyEscape") end
Core.EventHandler.OnEditBoxKeyReturn = function() dispatchActive("OnEditBoxKeyReturn") end
Core.EventHandler.OnEditBoxKeyTab    = function() dispatchActive("OnEditBoxKeyTab") end


-- ========================================================================== --
-- Mod
-- ========================================================================== --

--- The mod module table. All fields are optional; implement only what you need.
--- Lifecycle methods (OnLoad/OnUnload/OnUpdate) receive no window arguments.
--- Per-window event handlers always receive (name: string, key: string, ...) first.
--- WindowData binding handlers follow the pattern OnUpdate<DataKey>(name, key, data).
---@class ModModule
---@field OnLoad           (fun())?                                                              Called once when the mod is loaded.
---@field OnUnload         (fun())?                                                              Called once when the mod is unloaded.
---@field OnUpdate         (fun(dt: number))?                                                    Called every frame.
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
-- Mongbat
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
    -- <OnInitialize>/<OnShutdown>, which fire after the mod's .lua is loaded.
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
Mongbat.CreateWindow     = Core.CreateWindow
Mongbat.RegisterWindow   = Core.RegisterWindow
Mongbat.DestroyWindow    = Core.DestroyWindow
Mongbat.UnregisterWindow = Core.UnregisterWindow
Mongbat.GetWindow        = Core.GetWindow

-- Global handler table referenced by XML templates and runtime
-- WindowRegisterCoreEventHandler calls. Must be assigned to Mongbat
-- (not just Substrate) so the engine can look it up by string name.
Mongbat.EventHandler = Core.EventHandler

-- ----- Lib bootstrap -------------------------------------------------------
--
-- The Mongbat library itself is registered with the engine through
-- Mongbat.mod, which calls _Mongbat.OnInitialize / OnUpdate / OnShutdown.
-- We use those entry points to load XML, then load each consumer mod,
-- and dispatch per-frame OnUpdate to each loaded mod.

_Mongbat = {}

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
