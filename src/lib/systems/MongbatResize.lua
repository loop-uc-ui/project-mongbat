---@diagnostic disable: undefined-global
-- ========================================================================== --
-- _Mongbat.Systems.Resize: Live-resize grip system
-- ========================================================================== --
--
-- Mods opt a window into bottom-right grip resize by passing
--   spec.resizable = { minW, minH, state }
-- on its emit call. This module auto-creates a child grip window from the
-- MongbatResizeGrip template. On grip LButtonDown it captures the starting
-- cursor position and panel dimensions. Each Tick() call thereafter it
-- applies the cursor delta as a new window size and writes it into
-- state.w / state.h so the mod's Build can re-apply child dimensions.
--
-- This module fully owns the grip's lifecycle: EnsureGrip creates the
-- engine window AND registers it with Systems.Registry (so events route
-- to GripModule). Teardown reverses both. Callers (Build) just need to
-- call EnsureGrip / Teardown — they don't need to know GripModule exists.
--
-- Public surface: _Mongbat.Systems.Resize
--   .GripModule               module table for grip Windows registry entries
--   .GripNameFor(panelName)   canonical grip engine name
--   .EnsureGrip(panelName)    create + register grip window (idempotent)
--   .SetConfig(panelName, cfg) update resize config for a panel
--   .IsConfigured(panelName)  true when a resize config exists for the panel
--   .Teardown(panelName)      unregister + destroy grip, clear config + live state
--   .EnsureGlobalUpHandler()  install the one-time global LButtonUp handler
--   .Tick()                   per-frame size update while dragging
--   .End()                    end a live resize drag (called from OnLiveResizeUp)

local Systems = _Mongbat.Systems
local Number = Mongbat.Utils.Number

--- Per-panel resize configuration stored by Mongbat.lua via SetConfig.
---@class ResizeConfig
---@field minW number              Minimum allowed width.
---@field minH number              Minimum allowed height.
---@field state { w: number?, h: number? } Shared state written each frame; mod reads this in Build.
---@field onResize fun(width: number, height: number)? Called after live resize writes state and applies panel dimensions.

--- Live resize drag state (nil when not resizing).
---@class LiveResizeState
---@field window string   Engine name of the panel being resized.
---@field startMx number  Cursor x at drag start.
---@field startMy number  Cursor y at drag start.
---@field startW number   Panel width at drag start.
---@field startH number   Panel height at drag start.

---@class Resize
local Resize = {}
Systems.Resize = Resize

-- panelEngineName -> ResizeConfig
---@type table<string, ResizeConfig>
local ResizableConfig = {}

---@type LiveResizeState?
local LiveResize = nil

local globalUpInstalled = false

-- ----- Grip module ---------------------------------------------------------
-- This table is used as the `module` field in the Windows registry for grip
-- windows. Mongbat.lua's event router will call GripModule.OnLButtonDown
-- when the user presses the grip.

---@class GripModule : ModModule
local GripModule = {}
Resize.GripModule = GripModule

---@param window RoutedWindow
function GripModule.OnLButtonDown(window)
    local panelEngineName = window.key
    local cfg = ResizableConfig[panelEngineName]
    if not cfg then return end
    if not Mongbat.Api.Window.DoesExist(panelEngineName) then return end
    local dims = Mongbat.Api.Window.GetDimensions(panelEngineName)
    -- Pin the panel to its current top-left so SetDimensions grows the
    -- bottom-right only. Without this, a window with an implicit center
    -- (or non-topleft) anchor grows symmetrically, shifting visible
    -- children up-left as the panel expands.
    local px, py = Mongbat.Api.Window.GetPosition(panelEngineName)
    Mongbat.Api.Window.ClearAnchors(panelEngineName)
    Mongbat.Api.Window.AddAnchor(panelEngineName, "topleft", "Root", "topleft", px, py)
    local mp   = Mongbat.Data.MousePosition()
    LiveResize = {
        window  = panelEngineName,
        startMx = mp.x,
        startMy = mp.y,
        startW  = dims.x,
        startH  = dims.y,
    } --[[@as LiveResizeState]]
end

-- ----- Helpers -------------------------------------------------------------

--- Returns the canonical grip engine name for a panel.
---@param panelEngineName string
---@return string
function Resize.GripNameFor(panelEngineName)
    return panelEngineName .. "ResizeGrip"
end

-- Force-relayout the FullResizeImage backgrounds the MongbatWindow template
-- instantiates as $parentBackground and $parentFrame. Clearing and re-adding
-- their parent-anchored corners makes the engine recompute geometry from the
-- new parent dimensions.
local function reflowMongbatWindowChildren(panelEngineName)
    local bg    = panelEngineName .. "Background"
    local frame = panelEngineName .. "Frame"
    if Mongbat.Api.Window.DoesExist(bg) then
        Mongbat.Api.Window.ClearAnchors(bg)
        Mongbat.Api.Window.AddAnchor(bg, "topleft",     panelEngineName, "topleft",     0, 0)
        Mongbat.Api.Window.AddAnchor(bg, "bottomright", panelEngineName, "bottomright", 0, 0)
    end
    if Mongbat.Api.Window.DoesExist(frame) and Mongbat.Api.Window.DoesExist(bg) then
        Mongbat.Api.Window.ClearAnchors(frame)
        Mongbat.Api.Window.AddAnchor(frame, "topleft",     bg, "topleft",     0, 0)
        Mongbat.Api.Window.AddAnchor(frame, "bottomright", bg, "bottomright", 0, 0)
    end
end

-- ----- Public API ----------------------------------------------------------

--- Creates and fully registers the grip window for `panelEngineName` if it
--- does not already exist. Self-registers with Systems.Registry and attaches
--- routable events so engine input dispatches to GripModule. Also installs
--- the global LButtonUp handler on first use. Idempotent: safe to call every
--- frame; only does work on first call per panel.
---@param panelEngineName string
function Resize.EnsureGrip(panelEngineName)
    if not Mongbat.Api.Window.DoesExist(panelEngineName) then return end
    local gripName = Resize.GripNameFor(panelEngineName)
    if Mongbat.Api.Window.DoesExist(gripName) then return end
    Mongbat.Api.Window.CreateFromTemplate(gripName, "MongbatResizeGrip", panelEngineName, true)
    Mongbat.Api.Window.ClearAnchors(gripName)
    Mongbat.Api.Window.AddAnchor(gripName, "bottomright", panelEngineName, "bottomright", 0, 0)
    local Registry = Systems.Registry
    Registry.Set(gripName, {
        module     = GripModule,
        key        = panelEngineName,
        id         = 0,
        engineName = gripName,
    })
    Registry.AttachEvents(gripName)
    Resize.EnsureGlobalUpHandler()
end

--- Updates (or sets) the resize config for a panel. Must be called before EnsureGrip.
---@param panelEngineName string
---@param cfg ResizeConfig
function Resize.SetConfig(panelEngineName, cfg)
    ResizableConfig[panelEngineName] = cfg
end

--- Returns true when a resize config exists for `panelEngineName`.
---@param panelEngineName string
---@return boolean
function Resize.IsConfigured(panelEngineName)
    return ResizableConfig[panelEngineName] ~= nil
end

--- Unregisters and destroys the grip window, clears the resize config, and
--- ends any live resize for `panelEngineName`. Idempotent: safe to call when
--- no grip exists (returns early when never configured).
---@param panelEngineName string
function Resize.Teardown(panelEngineName)
    if not ResizableConfig[panelEngineName] then return end
    local gripName = Resize.GripNameFor(panelEngineName)
    Systems.Registry.Remove(gripName)
    if Mongbat.Api.Window.DoesExist(gripName) then
        Mongbat.Api.Window.Destroy(gripName)
    end
    ResizableConfig[panelEngineName] = nil
    if LiveResize and LiveResize.window == panelEngineName then
        LiveResize = nil
    end
end

--- Installs the global LButtonUpProcessed event handler that ends a live resize
--- regardless of where the cursor is when released. Safe to call multiple times.
function Resize.EnsureGlobalUpHandler()
    if globalUpInstalled then return end
    globalUpInstalled = true
    Mongbat.Api.Event.RegisterEventHandler(
        Mongbat.Constants.SystemEvents.OnLButtonUpProcessed.getEvent(),
        "Mongbat.EventHandler.OnLiveResizeUp"
    )
end

--- Per-frame size update while a live resize drag is active. Called from Mods.PerFrame.
function Resize.Tick()
    if not LiveResize then return end
    if not Mongbat.Api.Window.DoesExist(LiveResize.window) then
        LiveResize = nil
        return
    end
    local cfg = ResizableConfig[LiveResize.window]
    if not cfg then
        LiveResize = nil
        return
    end
    local mp   = Mongbat.Data.MousePosition()
    local newW = Number.AtLeast(LiveResize.startW + (mp.x - LiveResize.startMx), cfg.minW)
    local newH = Number.AtLeast(LiveResize.startH + (mp.y - LiveResize.startMy), cfg.minH)
    if cfg.state.w ~= newW or cfg.state.h ~= newH then
        if not Mongbat.Api.Window.DoesExist(LiveResize.window) then
            LiveResize = nil
            return
        end
        cfg.state.w = newW
        cfg.state.h = newH
        Mongbat.Api.Window.SetDimensions(LiveResize.window, newW, newH)
        reflowMongbatWindowChildren(LiveResize.window)
        if cfg.onResize then cfg.onResize(newW, newH) end
    end
end

--- Ends the active live resize drag. Called from Core.EventHandler.OnLiveResizeUp.
function Resize.End()
    LiveResize = nil
end
