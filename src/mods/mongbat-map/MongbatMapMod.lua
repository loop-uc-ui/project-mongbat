---@type Window
local window

local WINDOW_SIZE = 400
local MARGIN = 8

local Api = Mongbat.Api
local Data = Mongbat.Data
local Utils = Mongbat.Utils
local Components = Mongbat.Components

Mongbat.Mod {
    Name = "MongbatMap",
    Path = "/src/mods/mongbat-map",
    OnInitialize = function()
        local mapWindow = Components.Defaults.MapWindow
        mapWindow:asComponent().showing = false
        mapWindow:disable()

        local mapCommon = Components.Defaults.MapCommon
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
            Api.Radar.SetZoom(zoom.current)
        end

        --- Queries the engine for zoom boundaries and applies an initial zoom.
        --- Mirrors MapCommon.UpdateZoomValues + initial AdjustZoom.
        local function initializeZoom()
            local facet = Api.Radar.GetFacet()
            local area = Api.Radar.GetArea()
            local maxZoom = Api.Radar.GetMaxZoom(facet, area)
            if maxZoom and maxZoom > 0 then
                zoom.max = maxZoom
                zoom.step = maxZoom / 5
            else
                zoom.max = 0.0
                zoom.step = 0.50
            end
            zoom.min = -2.0

            local savedZoom = Api.Radar.GetCurrentZoom()
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
            local Radar = Api.Radar
            local x, y
            if centerOnPlayer then
                local loc = Data.PlayerLocation()
                x = loc.x
                y = loc.y
            else
                x, y = Radar.GetCenter()
            end
            local facet = Radar.GetFacet()
            local facetTid = Radar.GetFacetLabel(facet)
            local facetName = Utils.String.FromWString(
                Api.String.GetStringFromTid(facetTid)
            )
            return Utils.String.Format("%d, %d - %s", x, y, facetName)
        end

        -- Track last radar size to avoid redundant SetWindowSize calls
        local lastRadarW = 0
        local lastRadarH = 0

        local function updateRadarSize(w, h)
            if w == lastRadarW and h == lastRadarH then return end
            lastRadarW = w
            lastRadarH = h

            -- Save the current view center before resizing
            local Radar = Api.Radar
            local savedX, savedY = Radar.GetCenter()
            local facet = Radar.GetFacet()
            local area = Radar.GetArea()

            Radar.SetWindowSize(w, h, true, true)

            -- If the user had panned away, restore their view position
            if not centerOnPlayer then
                Radar.CenterOnLocation(savedX, savedY, facet, area, false)
            end
        end

        local function Map()
            return Components.DynamicImage {
                OnInitialize = function(self)
                    -- Activate the radar (mirrors MapWindow.ActivateMap)
                    local dims = self.dimensions
                    updateRadarSize(dims.x, dims.y)
                    Api.Radar.SetRotation(0)
                    Api.Radar.SetWindowOffset(0, 0)
                    Api.Radar.SetCenterOnPlayer(true)
                    initializeZoom()
                end,
                OnUpdateRadar = function(self, data)
                    self.texture = {"radar_texture", data.TexCoordX, data.TexCoordY}
                    self.textureScale = data.TexScale
                end,
                OnDimensionsChanged = function(self, width, height)
                    updateRadarSize(width, height)
                end,
                OnMouseWheel = function(self, _, _, delta)
                    adjustZoom(-delta)
                end,
                OnLButtonDown = function(self, flags)
                    if Data.IsShift(flags) then
                        isPanning = true
                        centerOnPlayer = false
                        local pos = Data.MousePosition()
                        lastMouseX = pos.x
                        lastMouseY = pos.y
                        Api.Radar.SetCenterOnPlayer(false)
                    end
                end,
                OnLButtonUp = function(self)
                    isPanning = false
                end,
                OnMouseOverEnd = function(self)
                    if isPanning then
                        isPanning = false
                    end
                end,
                OnLButtonDblClk = function(self)
                    isPanning = false
                    centerOnPlayer = true
                    Api.Radar.SetCenterOnPlayer(true)
                end,
                OnUpdate = function(self)
                    if not isPanning then return end

                    local pos = Data.MousePosition()
                    local mouseX = pos.x
                    local mouseY = pos.y
                    local deltaX = mouseX - lastMouseX
                    local deltaY = mouseY - lastMouseY
                    lastMouseX = mouseX
                    lastMouseY = mouseY

                    if deltaX == 0 and deltaY == 0 then return end

                    local Radar = Api.Radar
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
            return Components.Label {
                Template = "MongbatLabelSmall",
                OnInitialize = function(self)
                    self.dimensions = {WINDOW_SIZE, 16}
                    self.layer = self:layerBuilder(function(l) return l:overlay() end)
                    self.text = formatLocationText()
                end,
                OnUpdateRadar = function(self)
                    self.text = formatLocationText()
                end,
                OnUpdatePlayerLocation = function(self)
                    if centerOnPlayer then
                        self.text = formatLocationText()
                    end
                end,
            }
        end

        local function Window()
            return Components.Window {
                Name = "MongbatMapWindow",
                MinWidth = 100 + MARGIN * 2,
                MinHeight = 100 + MARGIN * 2,
                OnInitialize = function(self)
                    self.dimensions = {WINDOW_SIZE + MARGIN * 2, WINDOW_SIZE + MARGIN * 2}
                    self.children = { Map(), CoordsLabel() }
                end,
                OnLayout = function(self, children, child, index)
                    local dimens = self.dimensions
                    local contentW = dimens.x - MARGIN * 2
                    local contentH = dimens.y - MARGIN * 2

                    if index == 1 then
                        -- Map image: fill the window minus margins
                        child.dimensions = {contentW, contentH}
                        child.anchors = child:anchorBuilder(function(a)
                            return { a:toParentCenter(0, 0) }
                        end)
                    elseif index == 2 then
                        -- Coords/facet label: full width, bottom-left
                        child.dimensions = {contentW, 16}
                        child.anchors = child:anchorBuilder(function(a)
                            return { a:add("bottomleft", self.name, "bottomleft", MARGIN, -MARGIN) }
                        end)
                    end
                end,
            }
        end

        window = Window()
        window:create(true)
    end,

    OnShutdown = function()
        if window ~= nil then
            window:destroy()
        end

        local mapCommon = Components.Defaults.MapCommon
        mapCommon:restore()

        local mapWindow = Components.Defaults.MapWindow
        mapWindow:restore()
        mapWindow:asComponent().showing = true
    end,
}
