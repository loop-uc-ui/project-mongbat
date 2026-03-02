---@type Window
local window

local WINDOW_SIZE = 400
local MARGIN = 8

Mongbat.Mod {
    Name = "MongbatMap",
    Path = "/src/mods/mongbat-map",
    OnInitialize = function(context)
        local mapWindow = context.Components.Defaults.MapWindow
        mapWindow:asComponent():setShowing(false)
        mapWindow:disable()

        local mapCommon = context.Components.Defaults.MapCommon
        mapCommon:disable()

        -- Zoom state (mirrors MapCommon.ZoomLevel)
        local zoom = {
            current = 0,
            min = -2.0,
            max = 0.0,
            step = 0.50,
        }

        --- Applies a zoom delta, clamped to [min, max].
        --- Mirrors MapCommon.AdjustZoom from the default UI.
        local function adjustZoom(delta)
            local step = zoom.step
            if zoom.current < 0.0 then
                step = 0.2
            end
            zoom.current = zoom.current + (delta * step)
            if zoom.current > zoom.max then
                zoom.current = zoom.max
            end
            if zoom.current < zoom.min then
                zoom.current = zoom.min
            end
            context.Api.Radar.SetZoom(zoom.current)
        end

        --- Queries the engine for zoom boundaries and applies an initial zoom.
        --- Mirrors MapCommon.UpdateZoomValues + initial AdjustZoom.
        local function initializeZoom()
            local facet = context.Api.Radar.GetFacet()
            local area = context.Api.Radar.GetArea()
            local maxZoom = context.Api.Radar.GetMaxZoom(facet, area)
            if maxZoom and maxZoom > 0 then
                zoom.max = maxZoom
                zoom.step = maxZoom / 5
            else
                zoom.max = 0.0
                zoom.step = 0.50
            end
            zoom.min = -2.0

            local savedZoom = context.Api.Radar.GetCurrentZoom()
            if savedZoom ~= 0 then
                zoom.current = savedZoom
                adjustZoom(0)
            else
                adjustZoom(-20)
            end
        end

        local function Map()
            return context.Components.DynamicImage {
                OnInitialize = function(self)
                    self:setDimensions(WINDOW_SIZE, WINDOW_SIZE)

                    -- Activate the radar (mirrors MapWindow.ActivateMap)
                    context.Api.Radar.SetWindowSize(WINDOW_SIZE, WINDOW_SIZE, true, true)
                    context.Api.Radar.SetRotation(0)
                    context.Api.Radar.SetWindowOffset(0, 0)
                    context.Api.Radar.SetCenterOnPlayer(true)
                    initializeZoom()
                end,
                OnUpdateRadar = function(self, data)
                    self:setTexture("radar_texture", data.TexCoordX, data.TexCoordY)
                    self:setTextureScale(data.TexScale)
                end,
                OnMouseWheel = function(self, _, _, delta)
                    adjustZoom(-delta)
                end,
                OnLButtonDown = function(self)
                    context.Api.Radar.SetCenterOnPlayer(false)
                    -- Cancel the engine's native window drag so panning the map
                    -- doesn't also move the parent window.
                    context.Api.Window.SetMoving(self:getParent(), false)
                end,
                OnMouseDrag = function(self, flags, deltaX, deltaY)
                    local Radar = context.Api.Radar
                    local facet = Radar.GetFacet()
                    local area = Radar.GetArea()
                    local mapCenterX, mapCenterY = Radar.GetCenter()
                    local winCenterX, winCenterY =
                        Radar.TranslateWorldPositionToRadarPosition(mapCenterX, mapCenterY)

                    local offsetX = winCenterX - deltaX
                    local offsetY = winCenterY - deltaY
                    local newCenterX, newCenterY =
                        Radar.TranslateRadarPositionToWorldPosition(offsetX, offsetY, false)

                    Radar.CenterOnLocation(newCenterX, newCenterY, facet, area, false)
                end,
            }
        end

        local function Window()
            return context.Components.Window {
                Name = "MongbatMapWindow",
                OnInitialize = function(self)
                    self:setDimensions(WINDOW_SIZE + MARGIN * 2, WINDOW_SIZE + MARGIN * 2)
                    self:setChildren { Map() }
                end,
                OnLayout = function(_, _, child, _)
                    child:anchorToParentCenter(0, 0)
                end,
            }
        end

        window = Window()
        window:create(true)
    end,

    OnShutdown = function(context)
        if window ~= nil then
            window:destroy()
        end

        local mapCommon = context.Components.Defaults.MapCommon
        mapCommon:restore()

        local mapWindow = context.Components.Defaults.MapWindow
        mapWindow:restore()
        mapWindow:asComponent():setShowing(true)
    end,
}
