---@type Window
local window
local scale = 1.0
local x = 0
local y = 0

Mongbat.Mod {
    Name = "MongbatMap",
    Path = "/src/mods/mongbat-map",
    OnInitialize = function(context)
        local mapWindow = context.Components.Defaults.MapWindow
        mapWindow:asComponent():setShowing(false)
        mapWindow:disable()

        local mapCommon = context.Components.Defaults.MapCommon
        mapCommon:disable()

        local function Map()
            return context.Components.DynamicImage {
                OnInitialize = function(self)
                    local dimen = 1100
                    self:setDimensions(dimen, dimen)
                    context.Api.Radar.SetWindowSize(dimen, dimen, true, true)
                end,
                OnUpdateRadar = function (self, data)
                    scale = data.TexScale
                    self:setTextureScale(data.TexScale)
                    x = data.TexCoordX
                    y = data.TexCoordY
                    self:setTexture("radar_texture", data.TexCoordX, data.TexCoordY)
                end,
                OnMouseWheel = function(self, _, _, delta)
                    context.Api.Radar.SetZoom(delta)
                end
            }
        end

        local function Window()
            return context.Components.Window {
                Name = "MongbatMapWindow",
                OnInitialize = function(self)
                    self:setDimensions(400, 400)
                    self:setChildren { Map() }
                end,
                OnLayout = function(_, _, child, _)
                    child:anchorToParentCenter(0, 0)
                end
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
    end
}
