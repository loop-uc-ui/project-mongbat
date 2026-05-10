-- Object handles: floating name labels pinned to world objects (mobiles +
-- items in view). The engine populates WindowData.ObjectHandles on its
-- own schedule; we read it every frame and emit one frame+label pair per
-- handle. The lib's Build subsystem auto-creates/destroys windows as
-- handles enter/leave the set.
--
-- Pattern: declarative. Dynamic per-id windows are the canonical Build
-- use case -- no manual diff, no OnCreate/OnDestroy hooks.

local UI        = Mongbat.UI
local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Utils     = Mongbat.Utils
local Constants = Mongbat.Constants

local LABEL_H       = 32
local CHAR_W        = 12
local FRAME_PADDING = 16

local M = {}

-- Cached metadata for click handlers; updated every Build pass.
local metaById = {}

local function frameKey(id) return "frame:" .. id end
local function labelKey(id) return "label:" .. id end

local function idFromKey(key)
    if type(key) ~= "string" then return nil end
    local s = key:match("^[a-z]+:(%d+)$")
    return s and tonumber(s) or nil
end

function M.OnLoad()
    Api.ObjectHandle.SuppressDefault()
end

function M.Build(emit)
    local handles = Data.ObjectHandles():getHandles()
    local seen = {}

    Utils.Table.ForEach(handles, function(_, h)
        seen[h.id] = true
        metaById[h.id] = { isMobile = h.isMobile, name = h.name }

        local color = Constants.Colors.Notoriety[h.notoriety]
        local width = #h.name * CHAR_W + FRAME_PADDING

        local frame = UI.Window()
            :setDimensions(width, LABEL_H)
            :setId(h.id)
            :attachToWorldObject(h.id)
            :setAlpha(0.7)
            :setLayer(Constants.WindowLayers.Background)
            :setMovable(false)
        if h.isMobile and color then frame:setColor(color) end

        emit(frameKey(h.id), {
            template = "MongbatWindow",
            id       = h.id,
            widget   = frame,
        })

        local label = UI.Label()
            :setDimensions(#h.name * CHAR_W, LABEL_H)
            :setId(h.id)
            :clearAnchors()
            :addAnchor("center", "parent", "center", 0, 0)
            :setText(h.name)
            :setTextAlignment(Constants.TextAlignment.Center)
        if color then label:setTextColor(color) end

        emit(labelKey(h.id), {
            template = "MongbatLabel",
            parent   = frameKey(h.id),
            id       = h.id,
            widget   = label,
        })
    end)

    -- Drop stale metadata for handles that left the set.
    Utils.Table.ForEach(metaById, function(id)
        if not seen[id] then metaById[id] = nil end
    end)
end

-- ---- Routed click handlers ------------------------------------------

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
    local entry = metaById[id]
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
