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

        -- Track whether the radar is centered on the player
        local centerOnPlayer = true
        -- Track whether Shift+drag panning is active
        local isPanning = false
        local lastMouseX = 0
        local lastMouseY = 0

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

        --- Returns the coordinate + facet display text.
        --- Shows player coords when centered on player, otherwise the map center.
        local function formatLocationText()
            local Radar = context.Api.Radar
            local x, y
            if centerOnPlayer then
                local loc = context.Data.PlayerLocation()
                x = loc:getX()
                y = loc:getY()
            else
                x, y = Radar.GetCenter()
            end
            local facet = Radar.GetFacet()
            local facetTid = Radar.GetFacetLabel(facet)
            local facetName = context.Utils.String.FromWString(
                context.Api.String.GetStringFromTid(facetTid)
            )
            return string.format("%d, %d - %s", x, y, facetName)
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
                OnLButtonDown = function(self, flags)
                    if flags == SystemData.ButtonFlags.SHIFT then
                        isPanning = true
                        centerOnPlayer = false
                        lastMouseX = SystemData.MousePosition.x
                        lastMouseY = SystemData.MousePosition.y
                        context.Api.Radar.SetCenterOnPlayer(false)
                        context.Api.Window.SetMoving(self:getParent(), false)
                    end
                end,
                OnLButtonUp = function(self)
                    isPanning = false
                end,
                OnLButtonDblClk = function(self)
                    isPanning = false
                    centerOnPlayer = true
                    context.Api.Radar.SetCenterOnPlayer(true)
                end,
                OnUpdate = function(self)
                    if not isPanning then return end

                    local mouseX = SystemData.MousePosition.x
                    local mouseY = SystemData.MousePosition.y
                    local deltaX = mouseX - lastMouseX
                    local deltaY = mouseY - lastMouseY
                    lastMouseX = mouseX
                    lastMouseY = mouseY

                    if deltaX == 0 and deltaY == 0 then return end

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

        --- Label in the lower-left corner showing coordinates and facet name.
        --- Displays player coords when centered on player, map center otherwise.
        local function CoordsLabel()
            return context.Components.Label {
                Template = "MongbatLabelSmall",
                OnInitialize = function(self)
                    self:setDimensions(WINDOW_SIZE, 16)
                    self:setLayer():overlay()
                    self:setText(formatLocationText())
                end,
                OnUpdateRadar = function(self)
                    self:setText(formatLocationText())
                end,
                OnUpdatePlayerLocation = function(self)
                    if centerOnPlayer then
                        self:setText(formatLocationText())
                    end
                end,
            }
        end

        local function Window()
            return context.Components.Window {
                Name = "MongbatMapWindow",
                OnInitialize = function(self)
                    self:setDimensions(WINDOW_SIZE + MARGIN * 2, WINDOW_SIZE + MARGIN * 2)
                    self:setChildren { Map(), CoordsLabel() }
                end,
                OnLayout = function(self, children, child, index)
                    if index == 1 then
                        -- Map image: centered
                        child:anchorToParentCenter(0, 0)
                    elseif index == 2 then
                        -- Coords/facet label: bottom-left corner
                        child:addAnchor("bottomleft", self:getName(), "bottomleft", MARGIN, -MARGIN)
                    end
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
