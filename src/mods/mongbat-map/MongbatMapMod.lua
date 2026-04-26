-- Radar map: hijacks the default UI''s MapWindow so this mod owns
-- presentation. Engine still runs its MapCommon module — those callbacks
-- short-circuit harmlessly when MapWindow no longer exists.
--
-- Pattern: Mongbat is a router. The mod owns three windows (outer panel,
-- DynamicImage radar, coords label). Mod-level M.OnUpdate(dt) pushes the
-- per-frame texture coords + label text + pan delta + size-poll. Routed
-- engine events (M.OnLButtonDown / OnLButtonUp / OnLButtonDblClk /
-- OnMouseWheel / OnMouseOverEnd) carry (name, key, ...).

local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Utils     = Mongbat.Utils
local Constants = Mongbat.Constants

local NAME       = "MapWindow"
local MAP_NAME   = "MongbatMapRadar"
local LABEL_NAME = "MongbatMapCoords"

local WINDOW_SIZE = 400
local MARGIN      = 8
local LABEL_H     = 16
local CONTENT     = WINDOW_SIZE

local M = {}

local state = {
    centerOnPlayer = true,
    isPanning      = false,
    lastMouseX     = 0,
    lastMouseY     = 0,
    radarW         = 0,
    radarH         = 0,
    zoom = {
        current = 0,
        min     = -2.0,
        max     = 0.0,
        step    = 0.50,
    },
}

local function adjustZoom(delta)
    local z = state.zoom
    local step = z.current < 0.0 and 0.2 or z.step
    z.current = math.max(z.min, math.min(z.max, z.current + delta * step))
    Api.Radar.SetZoom(z.current)
end

local function initializeZoom()
    local facet   = Api.Radar.GetFacet()
    local area    = Api.Radar.GetArea()
    local maxZoom = Api.Radar.GetMaxZoom(facet, area)
    local z = state.zoom
    if maxZoom and maxZoom > 0 then
        z.max  = maxZoom
        z.step = maxZoom / 5
    else
        z.max  = 0.0
        z.step = 0.50
    end
    z.min = -2.0
    local saved = Api.Radar.GetCurrentZoom()
    if saved ~= 0 then
        z.current = saved
        adjustZoom(0)
    else
        adjustZoom(-20)
    end
end

local function applyRadarSize(w, h)
    if w == state.radarW and h == state.radarH then return end
    state.radarW, state.radarH = w, h
    local Radar = Api.Radar
    local savedX, savedY = Radar.GetCenter()
    local facet = Radar.GetFacet()
    local area  = Radar.GetArea()
    Radar.SetWindowSize(w, h, true, true)
    if not state.centerOnPlayer then
        Radar.CenterOnLocation(savedX, savedY, facet, area, false)
    end
end

local function formatLocationText()
    local x, y
    if state.centerOnPlayer then
        local loc = Data.PlayerLocation()
        x, y = loc:getX(), loc:getY()
    else
        x, y = Api.Radar.GetCenter()
    end
    local facet     = Api.Radar.GetFacet()
    local facetTid  = Api.Radar.GetFacetLabel(facet)
    local facetName = Utils.String.FromWString(Api.String.GetStringFromTid(facetTid))
    return Utils.String.Format("%d, %d - %s", x, y, facetName)
end

function M.OnLoad()
    Api.Window.Destroy("MapWindow")
    Mongbat.CreateWindow {
        name = NAME, template = "MongbatWindow",
        module = M, key = "panel",
    }
    Api.Window.SetDimensions(NAME, CONTENT + MARGIN * 2, CONTENT + MARGIN * 2)

    Mongbat.CreateWindow {
        name = MAP_NAME, template = "MongbatDynamicImage",
        parent = NAME, module = M, key = "map",
    }
    Api.Window.SetDimensions(MAP_NAME, CONTENT, CONTENT)
    Api.Window.ClearAnchors(MAP_NAME)
    Api.Window.AddAnchor(MAP_NAME, "topleft",     "parent", "topleft",      MARGIN,  MARGIN)
    Api.Window.AddAnchor(MAP_NAME, "bottomright", "parent", "bottomright", -MARGIN, -MARGIN)

    Mongbat.CreateWindow {
        name = LABEL_NAME, template = "MongbatLabelSmall",
        parent = NAME, module = M, key = "coords",
    }
    Api.Window.SetDimensions(LABEL_NAME, CONTENT, LABEL_H)
    Api.Window.SetLayer(LABEL_NAME, Constants.WindowLayers.Overlay)
    Api.Window.ClearAnchors(LABEL_NAME)
    Api.Window.AddAnchor(LABEL_NAME, "bottomleft", "parent", "bottomleft", MARGIN, -MARGIN)

    applyRadarSize(CONTENT, CONTENT)
    Api.Radar.SetRotation(0)
    Api.Radar.SetWindowOffset(0, 0)
    Api.Radar.SetCenterOnPlayer(true)
    initializeZoom()
end

function M.OnUnload()
    Mongbat.DestroyWindow(LABEL_NAME)
    Mongbat.DestroyWindow(MAP_NAME)
    Mongbat.DestroyWindow(NAME)
end

function M.OnUpdate(_dt)
    if not Api.Window.DoesExist(MAP_NAME) then return end

    -- Resize-poll: outer window is movable+resizable; mirror to radar.
    local dims = Api.Window.GetDimensions(MAP_NAME)
    applyRadarSize(dims.x, dims.y)

    -- Update texture from current radar state.
    local radar = Data.Radar()
    Api.DynamicImage.SetTexture(MAP_NAME, "radar_texture",
        radar:getTexCoordX(), radar:getTexCoordY())
    Api.DynamicImage.SetTextureScale(MAP_NAME, radar:getTexScale())

    Api.Label.SetText(LABEL_NAME, formatLocationText())

    -- Pan delta.
    if state.isPanning then
        local pos = Data.MousePosition()
        local dx = pos.x - state.lastMouseX
        local dy = pos.y - state.lastMouseY
        state.lastMouseX, state.lastMouseY = pos.x, pos.y
        if dx ~= 0 or dy ~= 0 then
            local Radar = Api.Radar
            local facet = Radar.GetFacet()
            local area  = Radar.GetArea()
            local mx, my = Radar.GetCenter()
            local wx, wy = Radar.TranslateWorldPositionToRadarPosition(mx, my)
            local nx, ny = Radar.TranslateRadarPositionToWorldPosition(wx - dx, wy - dy, false)
            Radar.CenterOnLocation(nx, ny, facet, area, false)
        end
    end
end

-- ---- Routed events --------------------------------------------------

function M.OnMouseWheel(_name, key, _x, _y, delta)
    if key == "map" then adjustZoom(-delta) end
end

function M.OnLButtonDown(name, key, flags)
    if key ~= "map" then return end
    if not Data.IsShift(flags) then return end
    state.isPanning      = true
    state.centerOnPlayer = false
    local pos = Data.MousePosition()
    state.lastMouseX, state.lastMouseY = pos.x, pos.y
    Api.Radar.SetCenterOnPlayer(false)
    Api.Window.SetMoving(Api.Window.GetParent(name), false)
end

function M.OnLButtonUp(_name, key)
    if key == "map" then state.isPanning = false end
end

function M.OnMouseOverEnd(_name, key)
    if key == "map" then state.isPanning = false end
end

function M.OnLButtonDblClk(_name, key)
    if key ~= "map" then return end
    state.isPanning      = false
    state.centerOnPlayer = true
    Api.Radar.SetCenterOnPlayer(true)
end

function M.OnRButtonUp(_name, key)
    if key == "panel" or key == "map" then
        M.OnUnload()
    end
end

Mongbat.Mod {
    Name   = "MongbatMap",
    Path   = "/src/mods/mongbat-map",
    Module = M,
}
