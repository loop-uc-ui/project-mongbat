---@diagnostic disable: undefined-global
-- ========================================================================== --
-- _Mongbat.Systems.Snap: Edge-proximity window snap system
-- ========================================================================== --
--
-- Snappable windows register themselves as targets. While a registered
-- window is being dragged, each frame Tick() computes the closest edge
-- pair between the mover and every other registered window. Within
-- SNAP_THRESHOLD screen pixels a ghost preview appears at the snap
-- landing position. On LButtonUp, Commit() anchors the mover to Root at
-- the snap position, links it to the target, and cleans up state.
--
-- Public surface: _Mongbat.Systems.Snap
--   .Register(engineName)    add to snappable set
--   .Unregister(engineName)  remove from snappable set
--   .Detach(engineName)      remove this window from any snapped group
--   .BeginDrag(moverName)    start tracking snap/group drag for this mover
--   .TickGroup()             per-frame movement for snapped group followers
--   .AdjustForResize(name)   keep snapped neighbors attached after resize
--   .Tick()                  per-frame edge detection + preview
--   .Commit()                anchor mover if snapped; destroy preview; clear state
--   .Cancel()                destroy preview; clear state without anchoring

local Systems = _Mongbat.Systems
local Number = Mongbat.Utils.Number

--- Active snap tracking state.
---@class SnapState
---@field mover string    Engine name of the window being dragged.
---@field snapped boolean Whether a snap position was found this frame.
---@field snapX number?  Root-relative x of the snap landing position (logical coords).
---@field snapY number?  Root-relative y of the snap landing position (logical coords).
---@field snapTarget string? Engine name of the target window being snapped to.
---@field snapMoverEdge string? Edge on the mover used for the pending snap.
---@field snapTargetEdge string? Edge on the target used for the pending snap.
---@field startMx number Mouse x (screen pixels) when the drag began.
---@field startMy number Mouse y (screen pixels) when the drag began.
---@field startX number Mover x (screen pixels) when the drag began.
---@field startY number Mover y (screen pixels) when the drag began.
---@field group table<string, { x: number, y: number }>? Snapped followers and their start positions.

---@class Snap
local Snap = {}
Systems.Snap = Snap

--- Set of engine names currently registered as snap targets.
---@type table<string, true>
local SnappableWindows = {}

--- Undirected snapped-window graph. Each edge stores the snapped edge pair
--- from this window's perspective, e.g. right -> left.
---@type table<string, table<string, { edge: string, otherEdge: string }>>
local SnapLinks = {}

local SNAP_THRESHOLD = 20
local SNAP_PREVIEW   = "MongbatSnapPreviewGhost"  -- singleton ghost window
local SNAP_LINKS_KEY = "Mongbat.Snap.Links"
-- Snap detection is suppressed until the mouse has moved this many screen
-- pixels from the drag start. Prevents immediate snapping when windows
-- happen to be adjacent at their default positions (e.g. first launch).
local DRAG_DEAD_ZONE = 8

---@type SnapState?
local _activeSnap = nil

local _linksLoaded = false

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

local function encodeLinks()
    local records = {}
    for a, links in pairs(SnapLinks) do
        for b, link in pairs(links) do
            if a < b then
                records[#records + 1] = table.concat({ a, b, link.edge, link.otherEdge }, "|")
            end
        end
    end
    return table.concat(records, ";")
end

local function saveLinks()
    Mongbat.Api.Interface.SaveString(SNAP_LINKS_KEY, encodeLinks())
end

local function connect(a, b, aEdge, bEdge, skipSave)
    if not a or not b or a == b then return end
    SnapLinks[a] = SnapLinks[a] or {}
    SnapLinks[b] = SnapLinks[b] or {}
    SnapLinks[a][b] = { edge = aEdge, otherEdge = bEdge }
    SnapLinks[b][a] = { edge = bEdge, otherEdge = aEdge }
    if not skipSave then saveLinks() end
end

local function ensureLinksLoaded()
    if _linksLoaded then return end
    _linksLoaded = true

    local stored = Mongbat.Api.Interface.LoadString(SNAP_LINKS_KEY, "") or ""
    for a, b, aEdge, bEdge in string.gmatch(stored, "([^|;]+)|([^|;]+)|([^|;]+)|([^|;]+)") do
        connect(a, b, aEdge, bEdge, true)
    end
end

local function disconnectAll(name)
    local links = SnapLinks[name]
    if links then
        for other in pairs(links) do
            if SnapLinks[other] then SnapLinks[other][name] = nil end
        end
    end
    SnapLinks[name] = nil
end

local function collectGroup(root)
    local group = {}
    local seen = { [root] = true }
    local queue = { root }
    local index = 1
    while queue[index] do
        local current = queue[index]
        index = index + 1
        local links = SnapLinks[current]
        if links then
            for other in pairs(links) do
                if not seen[other] then
                    seen[other] = true
                    if SnappableWindows[other]
                        and Mongbat.Api.Window.DoesExist(other)
                        and Mongbat.Api.Window.IsShowing(other)
                    then
                        local x, y = Mongbat.Api.Window.GetPosition(other)
                        group[other] = { x = x, y = y }
                        queue[#queue + 1] = other
                    end
                end
            end
        end
    end
    return group
end

local function isInActiveGroup(name)
    return _activeSnap and _activeSnap.group and _activeSnap.group[name] ~= nil
end

local function moveGroupTo(snap, moverX, moverY)
    if not snap or not snap.group then return end

    local dx = moverX - snap.startX
    local dy = moverY - snap.startY
    if dx == 0 and dy == 0 then return end

    local scale = Mongbat.Api.InterfaceCore.GetScale()
    for name, start in pairs(snap.group) do
        if Mongbat.Api.Window.DoesExist(name) then
            Mongbat.Api.Window.ClearAnchors(name)
            Mongbat.Api.Window.AddAnchor(
                name,
                "topleft",
                "Root",
                "topleft",
                Number.Round((start.x + dx) / scale),
                Number.Round((start.y + dy) / scale)
            )
        end
    end
end

local function edgePosition(name, edge)
    local x, y = Mongbat.Api.Window.GetPosition(name)
    local dims = Mongbat.Api.Window.GetDimensions(name)
    if edge == "left" then return x, y end
    if edge == "right" then return x + dims.x, y end
    if edge == "top" then return x, y end
    if edge == "bottom" then return x, y + dims.y end
    return x, y
end

local function translateWindow(name, dx, dy)
    if dx == 0 and dy == 0 then return end
    if not Mongbat.Api.Window.DoesExist(name) then return end
    local x, y = Mongbat.Api.Window.GetPosition(name)
    local scale = Mongbat.Api.InterfaceCore.GetScale()
    Mongbat.Api.Window.ClearAnchors(name)
    Mongbat.Api.Window.AddAnchor(
        name,
        "topleft",
        "Root",
        "topleft",
        Number.Round((x + dx) / scale),
        Number.Round((y + dy) / scale)
    )
end

local function translateBranch(root, blocked, dx, dy, moved)
    if moved[root] then return end
    moved[root] = true
    translateWindow(root, dx, dy)

    local links = SnapLinks[root]
    if not links then return end
    for other in pairs(links) do
        if other ~= blocked then
            translateBranch(other, root, dx, dy, moved)
        end
    end
end

--- Adds `engineName` to the set of snap targets.
---@param engineName string
function Snap.Register(engineName)
    ensureLinksLoaded()
    SnappableWindows[engineName] = true
end

--- Removes `engineName` from the set of snap targets.
---@param engineName string
function Snap.Unregister(engineName)
    SnappableWindows[engineName] = nil
end

--- Removes `engineName` from its snapped group without unregistering it.
---@param engineName string
function Snap.Detach(engineName)
    ensureLinksLoaded()
    disconnectAll(engineName)
    saveLinks()
end

--- Begins snap tracking for a drag on `moverName`.
---@param moverName string
function Snap.BeginDrag(moverName)
    ensureLinksLoaded()
    local mp = Mongbat.Data.MousePosition()
    local x, y = Mongbat.Api.Window.GetPosition(moverName)
    _activeSnap = {
        mover      = moverName,
        snapped    = false,
        snapX      = nil,
        snapY      = nil,
        snapTarget = nil,
        snapMoverEdge = nil,
        snapTargetEdge = nil,
        startMx    = mp.x,
        startMy    = mp.y,
        startX     = x,
        startY     = y,
        group      = collectGroup(moverName),
    } --[[@as SnapState]]
end

--- Moves windows snapped to the active mover so the component behaves as one unit.
function Snap.TickGroup()
    if not _activeSnap or not _activeSnap.group then return end
    local mover = _activeSnap.mover
    if not Mongbat.Api.Window.DoesExist(mover) or not Mongbat.Api.Window.IsMoving(mover) then return end

    local x, y = Mongbat.Api.Window.GetPosition(mover)
    moveGroupTo(_activeSnap, x, y)
end

--- Repositions snapped neighbors after `name` changes dimensions.
---@param name string
function Snap.AdjustForResize(name)
    ensureLinksLoaded()
    local links = SnapLinks[name]
    if not links then return end
    if not Mongbat.Api.Window.DoesExist(name) then return end

    local moved = { [name] = true }
    for other, link in pairs(links) do
        if Mongbat.Api.Window.DoesExist(other) and Mongbat.Api.Window.IsShowing(other) then
            local sourceX, sourceY = edgePosition(name, link.edge)
            local otherX, otherY = edgePosition(other, link.otherEdge)
            local dx, dy = 0, 0
            if link.edge == "left" or link.edge == "right" then
                dx = sourceX - otherX
            else
                dy = sourceY - otherY
            end
            translateBranch(other, name, dx, dy, moved)
        end
    end
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
    local bestTarget = nil
    local bestMoverEdge, bestTargetEdge = nil, nil

    for targetName in pairs(SnappableWindows) do
        if targetName ~= mover
            and not isInActiveGroup(targetName)
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
                    bestX = Number.Round((tx + tw) / scale)
                    bestY = Number.Round(my / scale)
                    bestTarget = targetName
                    bestMoverEdge = "left"
                    bestTargetEdge = "right"
                end
            end

            -- Right of mover near left of target.
            if overlapV then
                local d = math.abs((mx + mw) - tx)
                if d < bestDist then
                    bestDist = d
                    bestX = Number.Round((tx - mw) / scale)
                    bestY = Number.Round(my / scale)
                    bestTarget = targetName
                    bestMoverEdge = "right"
                    bestTargetEdge = "left"
                end
            end

            -- Top of mover near bottom of target.
            if overlapH then
                local d = math.abs(my - (ty + th))
                if d < bestDist then
                    bestDist = d
                    bestX = Number.Round(mx / scale)
                    bestY = Number.Round((ty + th) / scale)
                    bestTarget = targetName
                    bestMoverEdge = "top"
                    bestTargetEdge = "bottom"
                end
            end

            -- Bottom of mover near top of target.
            if overlapH then
                local d = math.abs((my + mh) - ty)
                if d < bestDist then
                    bestDist = d
                    bestX = Number.Round(mx / scale)
                    bestY = Number.Round((ty - mh) / scale)
                    bestTarget = targetName
                    bestMoverEdge = "bottom"
                    bestTargetEdge = "top"
                end
            end
        end
    end

    if bestDist <= SNAP_THRESHOLD and bestX then
        showPreview(mover, bestX, bestY)
        _activeSnap.snapped = true
        _activeSnap.snapX   = bestX
        _activeSnap.snapY   = bestY
        _activeSnap.snapTarget = bestTarget
        _activeSnap.snapMoverEdge = bestMoverEdge
        _activeSnap.snapTargetEdge = bestTargetEdge
    else
        hidePreview()
        _activeSnap.snapped    = false
        _activeSnap.snapX      = nil
        _activeSnap.snapY      = nil
        _activeSnap.snapTarget = nil
        _activeSnap.snapMoverEdge = nil
        _activeSnap.snapTargetEdge = nil
    end
end

--- Commits the snap (if snapped) and clears state. Called on LButtonUp.
--- Anchors the mover to Root at the snap position when snapped.
function Snap.Commit()
    ensureLinksLoaded()
    local snap = _activeSnap
    _activeSnap = nil
    destroyPreview()
    if snap and snap.snapped
        and snap.snapX ~= nil
        and snap.snapY ~= nil
        and Mongbat.Api.Window.DoesExist(snap.mover)
    then
        local scale = Mongbat.Api.InterfaceCore.GetScale()
        moveGroupTo(snap, snap.snapX * scale, snap.snapY * scale)
        Mongbat.Api.Window.ClearAnchors(snap.mover)
        Mongbat.Api.Window.AddAnchor(snap.mover, "topleft", "Root", "topleft", snap.snapX, snap.snapY)
        if snap.snapTarget
            and snap.snapMoverEdge
            and snap.snapTargetEdge
            and Mongbat.Api.Window.DoesExist(snap.snapTarget)
        then
            connect(snap.mover, snap.snapTarget, snap.snapMoverEdge, snap.snapTargetEdge)
        end
    end
end

--- Cancels snap tracking without committing. Destroys preview and clears state.
function Snap.Cancel()
    _activeSnap = nil
    destroyPreview()
end
