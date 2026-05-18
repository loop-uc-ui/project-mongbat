---@diagnostic disable: undefined-global
-- ========================================================================== --
-- _Mongbat.Systems.Snap: Edge-proximity window snap system
-- ========================================================================== --
--
-- Snappable windows register themselves as targets. While a registered
-- window is being dragged, each frame Tick() computes the closest edge
-- pair between the mover and every other registered window. Within
-- SNAP_THRESHOLD screen pixels a ghost preview appears at the snap
-- landing position. On LButtonUp, Commit() either anchors the mover to
-- Root at the snap position or just cleans up state.
--
-- Public surface: _Mongbat.Systems.Snap
--   .Register(engineName)    add to snappable set
--   .Unregister(engineName)  remove from snappable set
--   .BeginDrag(moverName)    start tracking snap for this mover
--   .Tick()                  per-frame edge detection + preview
--   .Commit()                anchor mover if snapped; destroy preview; clear state
--   .Cancel()                destroy preview; clear state without anchoring

local Systems = _Mongbat.Systems

--- Active snap tracking state.
---@class SnapState
---@field mover string    Engine name of the window being dragged.
---@field snapped boolean Whether a snap position was found this frame.
---@field snapX number?  Root-relative x of the snap landing position (logical coords).
---@field snapY number?  Root-relative y of the snap landing position (logical coords).
---@field startMx number Mouse x (screen pixels) when the drag began.
---@field startMy number Mouse y (screen pixels) when the drag began.

---@class Snap
local Snap = {}
Systems.Snap = Snap

--- Set of engine names currently registered as snap targets.
---@type table<string, true>
local SnappableWindows = {}

local SNAP_THRESHOLD = 20
local SNAP_PREVIEW   = "MongbatSnapPreviewGhost"  -- singleton ghost window
-- Snap detection is suppressed until the mouse has moved this many screen
-- pixels from the drag start. Prevents immediate snapping when windows
-- happen to be adjacent at their default positions (e.g. first launch).
local DRAG_DEAD_ZONE = 8

---@type SnapState?
local _activeSnap = nil

local function showPreview(mover, rx, ry)
    if not Mongbat.Api.Window.DoesExist(SNAP_PREVIEW) then
        Mongbat.Api.Window.CreateFromTemplate(SNAP_PREVIEW, "MongbatSnapPreview", "Root", false)
    end
    local dims = Mongbat.Api.Window.GetDimensions(mover)
    Mongbat.Api.Window.SetDimensions(SNAP_PREVIEW, dims.x, dims.y)
    Mongbat.Api.Window.ClearAnchors(SNAP_PREVIEW)
    Mongbat.Api.Window.AddAnchor(SNAP_PREVIEW, "topleft", "Root", "topleft", rx, ry)
    Mongbat.Api.Window.SetShowing(SNAP_PREVIEW, true)
end

local function hidePreview()
    if Mongbat.Api.Window.DoesExist(SNAP_PREVIEW) then
        Mongbat.Api.Window.SetShowing(SNAP_PREVIEW, false)
    end
end

local function destroyPreview()
    if Mongbat.Api.Window.DoesExist(SNAP_PREVIEW) then
        Mongbat.Api.Window.Destroy(SNAP_PREVIEW)
    end
end

--- Adds `engineName` to the set of snap targets.
---@param engineName string
function Snap.Register(engineName)
    SnappableWindows[engineName] = true
end

--- Removes `engineName` from the set of snap targets.
---@param engineName string
function Snap.Unregister(engineName)
    SnappableWindows[engineName] = nil
end

--- Begins snap tracking for a drag on `moverName`.
---@param moverName string
function Snap.BeginDrag(moverName)
    local mp = Mongbat.Data.MousePosition()
    _activeSnap = {
        mover   = moverName,
        snapped = false,
        snapX   = nil,
        snapY   = nil,
        startMx = mp.x,
        startMy = mp.y,
    } --[[@as SnapState]]
end

--- Per-frame edge detection. Called from Mods.PerFrame.
function Snap.Tick()
    if not _activeSnap then return end
    local mover = _activeSnap.mover
    if not Mongbat.Api.Window.DoesExist(mover) or not Mongbat.Api.Window.IsMoving(mover) then
        _activeSnap = nil
        destroyPreview()
        return
    end

    local scale  = Mongbat.Api.InterfaceCore.GetScale()
    local mx, my = Mongbat.Api.Window.GetPosition(mover)
    local mdims  = Mongbat.Api.Window.GetDimensions(mover)
    local mw, mh = mdims.x, mdims.y

    -- Dead-zone: suppress snap until mouse has moved meaningfully from drag start.
    local mp = Mongbat.Data.MousePosition()
    local dx = mp.x - _activeSnap.startMx
    local dy = mp.y - _activeSnap.startMy
    if dx * dx + dy * dy < DRAG_DEAD_ZONE * DRAG_DEAD_ZONE then
        hidePreview()
        return
    end

    local bestDist = SNAP_THRESHOLD + 1
    local bestX, bestY = nil, nil

    for targetName in pairs(SnappableWindows) do
        if targetName ~= mover
            and Mongbat.Api.Window.DoesExist(targetName)
            and Mongbat.Api.Window.IsShowing(targetName)
        then
            local tx, ty = Mongbat.Api.Window.GetPosition(targetName)
            local tdims  = Mongbat.Api.Window.GetDimensions(targetName)
            local tw, th = tdims.x, tdims.y

            local overlapV = my < ty + th and my + mh > ty
            local overlapH = mx < tx + tw and mx + mw > tx

            -- Left of mover near right of target.
            if overlapV then
                local d = math.abs(mx - (tx + tw))
                if d < bestDist then
                    bestDist = d
                    bestX = math.floor((tx + tw) / scale + 0.5)
                    bestY = math.floor(my / scale + 0.5)
                end
            end

            -- Right of mover near left of target.
            if overlapV then
                local d = math.abs((mx + mw) - tx)
                if d < bestDist then
                    bestDist = d
                    bestX = math.floor((tx - mw) / scale + 0.5)
                    bestY = math.floor(my / scale + 0.5)
                end
            end

            -- Top of mover near bottom of target.
            if overlapH then
                local d = math.abs(my - (ty + th))
                if d < bestDist then
                    bestDist = d
                    bestX = math.floor(mx / scale + 0.5)
                    bestY = math.floor((ty + th) / scale + 0.5)
                end
            end

            -- Bottom of mover near top of target.
            if overlapH then
                local d = math.abs((my + mh) - ty)
                if d < bestDist then
                    bestDist = d
                    bestX = math.floor(mx / scale + 0.5)
                    bestY = math.floor((ty - mh) / scale + 0.5)
                end
            end
        end
    end

    if bestDist <= SNAP_THRESHOLD and bestX then
        showPreview(mover, bestX, bestY)
        _activeSnap.snapped = true
        _activeSnap.snapX   = bestX
        _activeSnap.snapY   = bestY
    else
        hidePreview()
        _activeSnap.snapped = false
        _activeSnap.snapX   = nil
        _activeSnap.snapY   = nil
    end
end

--- Commits the snap (if snapped) and clears state. Called on LButtonUp.
--- Anchors the mover to Root at the snap position when snapped.
function Snap.Commit()
    local snap = _activeSnap
    _activeSnap = nil
    destroyPreview()
    if snap and snap.snapped then
        Mongbat.Api.Window.ClearAnchors(snap.mover)
        Mongbat.Api.Window.AddAnchor(snap.mover, "topleft", "Root", "topleft", snap.snapX, snap.snapY)
    end
end

--- Cancels snap tracking without committing. Destroys preview and clears state.
function Snap.Cancel()
    _activeSnap = nil
    destroyPreview()
end
