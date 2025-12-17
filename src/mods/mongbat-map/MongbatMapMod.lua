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
                    self:clearAnchors()
                    self:anchorToParentCenter(0, 0)
                    local dimen = 396
                    self:setDimensions(dimen, dimen)
                    context.Api.Radar.SetWindowSize(dimen, dimen, true, true)
                end,
                OnUpdateRadar = function (self, data)
                    self:setTextureScale(data.TexScale)
                    self:setTexture("radar_texture", data.TexCoordX, data.TexCoordY)
                end
            }
        end

        local function Window()
            return context.Components.Window {
                Name = "MongbatMapWindow",
                OnInitialize = function(self)
                    self:setDimensions(400, 400)
                    self:setChildren { Map() }
                end
            }
        end

        Window():create(true)
    end,

    OnShutdown = function(context)
        local mapCommon = context.Components.Defaults.MapCommon
        mapCommon:restore()

        local mapWindow = context.Components.Defaults.MapWindow
        mapWindow:restore()
        mapWindow:asComponent():setShowing(true)
    end
}
