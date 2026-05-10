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
--   4. Provide a declarative window-emission subsystem: mods implement
--      M.Build(emit), the lib calls it every frame, diffs the emitted set
--      against the prior frame, and creates / updates / destroys engine
--      windows + WindowData registrations accordingly.
--
-- Mods are plain Lua module tables. A mod looks like:
--
--     local UI = Mongbat.UI
--     local M  = {}
--
--     function M.Build(emit)
--         emit("panel", {
--             template = "MongbatWindow",
--             widget   = UI.Window():setDimensions(200, 100),
--         })
--         emit("label", {
--             template = "MongbatLabel",
--             parent   = "panel",
--             widget   = UI.Label():setText("hi"):setOffsetFromParent(8, 8),
--         })
--     end
--
--     function M.OnLButtonUp(name, key, flags, x, y) ... end
--     function M.OnUpdate(dt) ... end          -- per-frame, per-mod
--     function M.OnLoad() end                  -- once at load
--     function M.OnUnload() end                -- once at unload
--
--     Mongbat.Mod { Name = "MongbatX", Path = "/src/mods/mongbat-x", Module = M }
--
-- The framework never holds closures, never bindings. Live engine data
-- (WindowData.*) is pulled by mods inline inside M.Build via Mongbat.Data.*.
-- The lib registers WindowData so the engine populates it. Click and
-- lifecycle events are still pushed via active-window dispatch.

local Core = {}

-- name -> { module = table, key = string, id = number? }
local Windows = {}

-- Forward declaration: defined later, needed by Core.UnloadMod.
local teardownBuild

-- Loaded mod modules in registration order. OnUpdate fan-out walks this.
local LoadedMods = {}    -- array of { name = string, module = table }

-- Ref-count of windows currently requesting each WindowData key. When the
-- count drops to zero we UnregisterWindowData so the engine stops populating
-- it. Mods read live data each frame from M.OnUpdateWindow.
local DataRegistered = {}    -- [dataKey] = number of windows currently registered

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

--- All WindowData types the lib auto-registers per window. Names not
--- present on the engine's `WindowData` table at registration time are
--- silently skipped (different EC builds expose different surfaces).
local DataTypes = {
    "PlayerStatus", "MobileName", "HealthBarColor", "MobileStatus",
    "Radar", "PlayerLocation", "Paperdoll", "ObjectHandle",
}

--- Asks the engine to populate every WindowData[type][id] for this window.
--- Ref-counted per (dataType, id) so the registration survives until the
--- last window using that id is destroyed. Mods read live data each frame
--- from M.OnUpdateWindow via Mongbat.Data.*.
local function attachAllData(id)
    Mongbat.Utils.Array.ForEach(DataTypes, function(name)
        local entry = WindowData[name]
        if not entry or entry.Type == nil then return end
        local refKey = name .. ":" .. tostring(id)
        if not DataRegistered[refKey] then
            DataRegistered[refKey] = 0
            Mongbat.Api.Window.RegisterData(entry.Type, id)
        end
        DataRegistered[refKey] = DataRegistered[refKey] + 1
    end)
end

--- Releases this window's data registrations. Calls UnregisterWindowData
--- when the last window for a given (dataType, id) pair is destroyed.
local function detachAllData(name)
    local entry = Windows[name]
    if not entry or entry.id == nil then return end
    local id = entry.id
    Mongbat.Utils.Array.ForEach(DataTypes, function(typeName)
        local refKey = typeName .. ":" .. tostring(id)
        local count = DataRegistered[refKey]
        if not count then return end
        count = count - 1
        if count <= 0 then
            DataRegistered[refKey] = nil
            local wd = WindowData[typeName]
            if wd and wd.Type ~= nil then
                Mongbat.Api.Window.UnregisterData(wd.Type, id)
            end
        else
            DataRegistered[refKey] = count
        end
    end)
end

--- Returns the registry entry for a window, or nil.
---@param name string The name of the window.
---@return { module: ModModule, key: string, id: number? }? The registry entry, or nil if the window is not registered.
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
            teardownBuild(modName)
            table.remove(LoadedMods, i)
            return
        end
    end
end


-- ----- Build factory (declarative window emission) ------------------------
--
-- Mods may implement M.Build(emit). The lib calls Build every frame; the
-- mod calls emit(key, spec) once per window it wants this frame. The lib
-- diffs the emitted set against the prior frame: new keys -> create +
-- register, existing keys -> re-apply widget ops, missing keys -> destroy.
--
-- spec = {
--   template        : string            -- engine template name (required)
--   widget          : MongbatUI widget  -- recorded ops, applied after create
--   parent          : string?           -- sibling key in this mod, or nil
--   name            : string?           -- override engine name (default-UI hijack)
--   id              : number?           -- WindowData id (default 0)
--   showing         : boolean?          -- initial visibility (default true)
--   replacesDefault : boolean?          -- destroy engine name once before first create
-- }
--
-- Engine name = spec.name or "<modName>_<key>" (sanitized).

-- [modName] = { [key] = { engineName, template, parent, id, spec } }
local BuildState = {}

local function sanitizeKey(key)
    return (tostring(key):gsub("[^%w_]", "_"))
end

local function defaultEngineName(modName, key)
    return modName .. "_" .. sanitizeKey(key)
end

-- ----- Live resize (declarative, opt-in via spec.resizable) ---------------
--
-- Mods opt a window into bottom-right grip resize by passing
--   spec.resizable = { minW, minH, state }
-- on its emit. The lib auto-creates a child grip window from the
-- MongbatResizeGrip template. On grip mousedown the lib captures the
-- starting cursor position + panel dimensions; each frame thereafter it
-- calls WindowSetDimensions on the panel using the cursor delta and
-- writes the new size into state.w / state.h. The mod's Build reads
-- those fields and re-applies setDimensions ops to its own children.
--
-- Empirical note: just calling WindowSetDimensions on a MaskWindow does
-- not reflow FullResizeImage children anchored to $parent until the
-- window is moved. So after each SetDimensions we clear+re-add anchors
-- on the panel's $parentBackground / $parentFrame to force a relayout.

-- panelEngineName -> { minW, minH, state }
local ResizableConfig = {}

-- nil when not actively resizing.
local LiveResize = nil

local function gripNameFor(panelEngineName)
    return panelEngineName .. "ResizeGrip"
end

local LiveResizeGripModule = {}

function LiveResizeGripModule.OnLButtonDown(_gripName, panelEngineName)
    local cfg = ResizableConfig[panelEngineName]
    if not cfg then return end
    if not Mongbat.Api.Window.DoesExist(panelEngineName) then return end
    local dims = Mongbat.Api.Window.GetDimensions(panelEngineName)
    local mp = Mongbat.Data.MousePosition()
    LiveResize = {
        window  = panelEngineName,
        startMx = mp.x,
        startMy = mp.y,
        startW  = dims.x,
        startH  = dims.y,
    }
end

local function endLiveResize()
    LiveResize = nil
end

local globalUpInstalled = false
local function ensureGlobalUpHandler()
    if globalUpInstalled then return end
    globalUpInstalled = true
    Mongbat.Api.Event.RegisterEventHandler(
        Mongbat.Constants.SystemEvents.OnLButtonUpProcessed.getEvent(),
        "Mongbat.EventHandler.OnLiveResizeUp"
    )
end

-- Force-relayout the FullResizeImage backgrounds the MongbatWindow
-- template instantiates as $parentBackground and $parentFrame. Clearing
-- and re-adding their parent-anchored corners makes the engine recompute
-- their geometry from the new parent dimensions.
local function reflowMongbatWindowChildren(panelEngineName)
    local bg    = panelEngineName .. "Background"
    local frame = panelEngineName .. "Frame"
    if Mongbat.Api.Window.DoesExist(bg) then
        Mongbat.Api.Window.ClearAnchors(bg)
        Mongbat.Api.Window.AddAnchor(bg, "topleft",     panelEngineName, "topleft",     0, 0)
        Mongbat.Api.Window.AddAnchor(bg, "bottomright", panelEngineName, "bottomright", 0, 0)
    end
    if Mongbat.Api.Window.DoesExist(frame) then
        Mongbat.Api.Window.ClearAnchors(frame)
        Mongbat.Api.Window.AddAnchor(frame, "topleft",     bg, "topleft",     0, 0)
        Mongbat.Api.Window.AddAnchor(frame, "bottomright", bg, "bottomright", 0, 0)
    end
end

local function tickLiveResize()
    if not LiveResize then return end
    if not Mongbat.Api.Window.DoesExist(LiveResize.window) then
        LiveResize = nil
        return
    end
    local cfg = ResizableConfig[LiveResize.window]
    if not cfg then return end
    local mp = Mongbat.Data.MousePosition()
    local newW = math.max(cfg.minW, LiveResize.startW + (mp.x - LiveResize.startMx))
    local newH = math.max(cfg.minH, LiveResize.startH + (mp.y - LiveResize.startMy))
    if cfg.state.w ~= newW or cfg.state.h ~= newH then
        cfg.state.w = newW
        cfg.state.h = newH
        Mongbat.Api.Window.SetDimensions(LiveResize.window, newW, newH)
        reflowMongbatWindowChildren(LiveResize.window)
    end
end

local function ensureGrip(panelEngineName)
    local gripName = gripNameFor(panelEngineName)
    if Mongbat.Api.Window.DoesExist(gripName) then return end
    Mongbat.Api.Window.CreateFromTemplate(gripName, "MongbatResizeGrip", panelEngineName, true)
    Mongbat.Api.Window.ClearAnchors(gripName)
    Mongbat.Api.Window.AddAnchor(gripName, "bottomright", panelEngineName, "bottomright", 0, 0)
    Windows[gripName] = { module = LiveResizeGripModule, key = panelEngineName, id = 0 }
    attachRoutableEvents(gripName)
end

local function teardownGrip(panelEngineName)
    local cfg = ResizableConfig[panelEngineName]
    if not cfg then return end
    local gripName = gripNameFor(panelEngineName)
    Windows[gripName] = nil
    if Mongbat.Api.Window.DoesExist(gripName) then
        Mongbat.Api.Window.Destroy(gripName)
    end
    ResizableConfig[panelEngineName] = nil
    if LiveResize and LiveResize.window == panelEngineName then
        LiveResize = nil
    end
end

--- Destroys an engine window emitted by a previous Build frame.
local function destroyBuiltEntry(entry)
    teardownGrip(entry.engineName)
    detachAllData(entry.engineName)
    if entry.savePosition and Mongbat.Api.Window.DoesExist(entry.engineName) then
        Mongbat.Api.Window.SavePosition(entry.engineName, true)
    end
    Windows[entry.engineName] = nil
    if Mongbat.Api.Window.DoesExist(entry.engineName) then
        Mongbat.Api.Window.Destroy(entry.engineName)
    end
end

--- Run one frame of M.Build for a single mod.
local function runBuild(modName, module)
    if not module.Build then return end
    local prev = BuildState[modName] or {}
    local current = {}
    local order = {}     -- emission order; parents must precede children
    BuildState[modName] = current

    -- Build a key -> engine-name lookup that includes both prior + this-frame
    -- entries so widget _apply can resolve sibling-key references.
    local function resolveKey(k)
        local e = current[k] or prev[k]
        return e and e.engineName or nil
    end

    local function emit(key, spec)
        if current[key] then
            error("Mongbat.Build [" .. modName .. "]: duplicate emit key '" .. tostring(key) .. "'")
        end
        local engineName = spec.name or defaultEngineName(modName, key)
        local id = spec.id or 0
        local parentKey = spec.parent
        local parentEngine
        if parentKey then
            parentEngine = resolveKey(parentKey)
            if not parentEngine then
                error("Mongbat.Build [" .. modName .. "]: unknown parent key '" .. tostring(parentKey)
                    .. "' for '" .. tostring(key) .. "'. Emit the parent first.")
            end
        else
            parentEngine = "Root"
        end
        -- `draggable = true` in spec makes this window the drag root; SetMoving
        -- will be called on it automatically when any descendant is pressed.
        -- Children inherit draggableRoot from their parent's Windows entry.
        local draggableRoot
        if spec.draggable then
            draggableRoot = engineName
        elseif parentEngine and parentEngine ~= "Root" then
            local parentWin = Windows[parentEngine]
            draggableRoot = parentWin and parentWin.draggableRoot or nil
        end
        -- `savePosition`: save/restore screen position via the engine's
        -- persistent WindowPositions store. Defaults to true for root-level
        -- windows (parentEngine == "Root"). Override with spec.savePosition.
        local savePosition
        if spec.savePosition ~= nil then
            savePosition = spec.savePosition
        else
            savePosition = (parentEngine == "Root")
        end
        local entry = {
            engineName   = engineName,
            template     = spec.template,
            parentKey    = parentKey,
            id           = id,
            widget       = spec.widget,
            savePosition = savePosition,
        }
        current[key] = entry
        order[#order + 1] = key

        local prevEntry = prev[key]
        if prevEntry and prevEntry.engineName == engineName and prevEntry.template == spec.template then
            -- Existing window: re-apply widget ops (createOnly ops are skipped;
            -- ops with unchanged primitive args are also skipped via cache).
            entry.cache = prevEntry.cache or {}
            if spec.widget then spec.widget:_apply(engineName, resolveKey, false, entry.cache) end
            -- Always keep draggableRoot current on the live registry entry.
            local winEntry = Windows[engineName]
            if winEntry then winEntry.draggableRoot = draggableRoot end
            if spec.resizable then
                local r = spec.resizable
                ResizableConfig[engineName] = { minW = r.minW, minH = r.minH, state = r.state }
                ensureGrip(engineName)
                ensureGlobalUpHandler()
            elseif ResizableConfig[engineName] then
                teardownGrip(engineName)
            end
            return
        end

        -- New (or template/name changed) — create from scratch.
        if prevEntry then
            destroyBuiltEntry(prevEntry)
        end
        if spec.replacesDefault and Mongbat.Api.Window.DoesExist(engineName) then
            Mongbat.Api.Window.Destroy(engineName)
        end
        Windows[engineName] = { module = module, key = key, id = id, draggableRoot = draggableRoot, savePosition = savePosition }
        Mongbat.Api.Window.CreateFromTemplate(engineName, spec.template, parentEngine,
            spec.showing ~= false)
        attachRoutableEvents(engineName)
        attachAllData(id)
        entry.cache = {}
        if spec.widget then spec.widget:_apply(engineName, resolveKey, true, entry.cache) end
        if savePosition then
            Mongbat.Api.Window.RestorePosition(engineName, false)
        end
        if spec.resizable then
            local r = spec.resizable
            ResizableConfig[engineName] = { minW = r.minW, minH = r.minH, state = r.state }
            ensureGrip(engineName)
            ensureGlobalUpHandler()
        elseif ResizableConfig[engineName] then
            teardownGrip(engineName)
        end
    end

    module.Build(emit)

    -- Destroy keys present last frame but not this frame.
    for key, prevEntry in pairs(prev) do
        if key ~= "_order" and not current[key] then
            destroyBuiltEntry(prevEntry)
        end
    end

    current._order = order
end

--- Tear down all windows emitted by this mod's Build (called from OnUnload).
teardownBuild = function(modName)
    local prev = BuildState[modName]
    if not prev then return end
    for key, entry in pairs(prev) do
        if key ~= "_order" then destroyBuiltEntry(entry) end
    end
    BuildState[modName] = nil
end

--- Per-frame fan-out. Mod-level M.OnUpdate(dt) runs first across all loaded
--- mods, then M.Build(emit) runs (declarative window emission). Build
--- diffs the emitted window set vs prior frame to create / update / destroy.
---@param dt number Elapsed time in seconds since the last frame.
function Core.PerFrame(dt)
    Mongbat.Utils.Array.ForEach(LoadedMods, function(entry)
        local fn = entry.module.OnUpdate
        if fn then fn(dt) end
    end)
    tickLiveResize()
    Mongbat.Utils.Array.ForEach(LoadedMods, function(entry)
        runBuild(entry.name, entry.module)
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
-- Track the Mongbat window entry that received LButtonDown so that:
--   (a) LButtonUp on a child window still routes back to the original window, and
--   (b) if the mouse moved (window was dragged), LButtonUp is suppressed.
-- Snapshots mouse position (absolute screen coords) which is reliable regardless
-- of whether SetMoving has committed the window position yet.
-- Only one mouse-button drag can be in progress at a time.
local _activeDrag = nil  -- { engineName, key, module, mover, mx, my } | nil

Core.EventHandler.OnLButtonDown = function(flags, x, y)
    local name = SystemData.ActiveWindow.name
    local entry = Windows[name]
    if entry then
        local mp = Mongbat.Data.MousePosition()
        local mover = entry.draggableRoot
        if mover then Mongbat.Api.Window.SetMoving(mover, true) end
        _activeDrag = { engineName = entry.engineName, key = entry.key, module = entry.module, mover = mover, mx = mp.x, my = mp.y }
    else
        _activeDrag = nil
    end
    dispatchActive("OnLButtonDown", flags, x, y)
end

Core.EventHandler.OnLButtonUp = function(flags, x, y)
    local drag = _activeDrag
    _activeDrag = nil
    if drag then
        if drag.mover then Mongbat.Api.Window.SetMoving(drag.mover, false) end
        local mp = Mongbat.Data.MousePosition()
        if mp.x ~= drag.mx or mp.y ~= drag.my then
            return  -- mouse moved: window was dragged, suppress click
        end
        -- Mouse did not move: dispatch Up to the original down-window.
        -- This handles the case where LButtonUp fires on a child window
        -- rather than the window that received LButtonDown.
        local fn = drag.module["OnLButtonUp"]
        if fn then fn(drag.engineName, drag.key, flags, x, y) end
        return
    end
    dispatchActive("OnLButtonUp", flags, x, y)
end
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

-- Persistent global L_BUTTON_UP_PROCESSED handler used to end a live
-- resize drag regardless of where the cursor is when released.
Core.EventHandler.OnLiveResizeUp     = function() endLiveResize() end


-- ========================================================================== --
-- Mod
-- ========================================================================== --

--- The mod module table. All fields are optional; implement only what you need.
--- Lifecycle methods (OnLoad/OnUnload/OnUpdate) receive no window arguments.
--- Per-window event handlers always receive (name: string, key: string, ...) first.
--- OnUpdateWindow runs every frame for each registered window owned by this mod.
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
Mongbat.GetWindow = Core.GetWindow

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
