-- Object handles: floating name labels pinned to world objects (mobiles +
-- items in view). The engine''s default UI calls
-- ObjectHandleWindow.CreateObjectHandles() when it wants the set refreshed
-- and DestroyObjectHandles() when it wants them gone. We chain via
-- Api.ObjectHandle so both our state and the default UI''s bookkeeping run.
--
-- Pattern: Mongbat is a router. Each handle is its own pair of windows
-- (frame + label) attached to the world object. We diff against the
-- previous set on every refresh and create / destroy windows accordingly.

local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Utils     = Mongbat.Utils
local Constants = Mongbat.Constants

local LABEL_H       = 32
local CHAR_W        = 12
local FRAME_PADDING = 16

local M = {}

-- [id] = { frame = "...", label = "...", isMobile = bool, name = "..." }
local owned = {}

local function frameName(id) return "MongbatObjectHandle"      .. id end
local function labelName(id) return "MongbatObjectHandleLabel" .. id end

local function destroyHandle(id)
    local entry = owned[id]
    if not entry then return end
    Mongbat.DestroyWindow(entry.label)
    Mongbat.DestroyWindow(entry.frame)
    owned[id] = nil
end

local function destroyAll()
    Utils.Table.ForEach(owned, function(id) destroyHandle(id) end)
end

local function createHandle(h)
    local color   = Constants.Colors.Notoriety[h.notoriety]
    local width   = #h.name * CHAR_W + FRAME_PADDING
    local frame   = frameName(h.id)
    local label   = labelName(h.id)

    Mongbat.CreateWindow {
        name = frame, template = "MongbatWindow",
        module = M, key = tostring(h.id),
    }
    Api.Window.SetDimensions(frame, width, LABEL_H)
    Api.Window.SetId(frame, h.id)
    Api.Window.AttachToWorldObject(h.id, frame)
    Api.Window.SetAlpha(frame, 0.7)
    Api.Window.SetLayer(frame, Constants.WindowLayers.Background)
    Api.Window.SetMovable(frame, false)
    if h.isMobile and color then
        Api.Window.SetColor(frame, color)
    end

    Mongbat.CreateWindow {
        name = label, template = "MongbatLabel",
        parent = frame, module = M, key = "label" .. h.id,
    }
    Api.Window.SetDimensions(label, #h.name * CHAR_W, LABEL_H)
    Api.Window.SetId(label, h.id)
    Api.Window.ClearAnchors(label)
    Api.Window.AddAnchor(label, "center", "parent", "center", 0, 0)
    Api.Label.SetText(label, h.name)
    if color then Api.Label.SetTextColor(label, color) end
    Api.Label.SetTextAlignment(label, Constants.TextAlignment.Center)

    owned[h.id] = { frame = frame, label = label, isMobile = h.isMobile, name = h.name }
end

local function refresh()
    local handles = Data.ObjectHandles():getHandles()
    local seen    = {}

    Utils.Table.ForEach(handles, function(_, h)
        seen[h.id] = true
        local entry = owned[h.id]
        if entry and entry.name == h.name then
            -- unchanged; nothing to do
        else
            if entry then destroyHandle(h.id) end
            createHandle(h)
        end
    end)

    Utils.Table.ForEach(owned, function(id)
        if not seen[id] then destroyHandle(id) end
    end)
end

function M.OnLoad()
    -- The engine''s ObjectHandleWindow module owns the lifecycle signal.
    Api.ObjectHandle.OnCreate(function() refresh() end)
    Api.ObjectHandle.OnDestroy(function() destroyAll() end)
end

function M.OnUnload()
    destroyAll()
end

-- ---- Routed click handlers ------------------------------------------

local function idFromKey(key)
    if type(key) ~= "string" then return nil end
    local s = key:match("^(%d+)$")
    return s and tonumber(s) or nil
end

function M.OnMouseOver(name, key)
    if idFromKey(key) then
        Api.Window.SetAlpha(name, 1.0)
        Api.Window.SetLayer(name, Constants.WindowLayers.Default)
    end
end

function M.OnMouseOverEnd(name, key)
    if idFromKey(key) then
        Api.Window.SetAlpha(name, 0.7)
        Api.Window.SetLayer(name, Constants.WindowLayers.Background)
    end
end

function M.OnLButtonDblClk(_name, key)
    local id = idFromKey(key)
    if id then Api.UserAction.UseItem(id) end
end

function M.OnLButtonDown(_name, key)
    local id = idFromKey(key)
    if not id then return end
    local entry = owned[id]
    if entry and entry.isMobile then
        Api.HealthBar.BeginDrag(id)
    end
end

function M.OnLButtonUp(_name, key)
    local id = idFromKey(key)
    if not id then return end
    if Data.Drag():isDraggingItem() then
        Api.Drag.DragToObject(id)
    else
        Api.Target.LeftClick(id)
    end
end

Mongbat.Mod {
    Name   = "MongbatObjectHandle",
    Path   = "/src/mods/mongbat-object-handle",
    Module = M,
}
