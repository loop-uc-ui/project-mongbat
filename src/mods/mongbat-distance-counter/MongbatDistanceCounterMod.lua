local NAME = "MongbatDistanceCounterLabel"

----------------------------------------------------------------
-- Configuration
----------------------------------------------------------------

-- Pixels per tile in the 2:1 isometric projection at default camera zoom.
-- Adjust if your camera zoom differs from the default.
local PIXELS_PER_TILE = 64

-- Pixel offset from the cursor where the label is drawn
local CURSOR_OFFSET_X = 16
local CURSOR_OFFSET_Y = -16

----------------------------------------------------------------
-- Mod
----------------------------------------------------------------

local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components

Mongbat.Mod {
    Name = "MongbatDistanceCounter",
    Path = "/src/mods/mongbat-distance-counter",
    OnInitialize = function()

        --- 2:1 isometric pixel metric → Chebyshev tile distance.
        local function isoMetric(dx, dy)
            return math.max(math.abs(dx + 2 * dy), math.abs(2 * dy - dx))
        end

        local label = Components.Label {
            Name = NAME,
            OnInitialize = function(self)
                self.dimensions = {60, 20}
                self.handleInput = false
                self.layer = self:layerBuilder(function(l) return l:overlay() end)
                self.bindings = self:bindingsBuilder(function(bind)
                    bind:onUpdate(function()
                        if not Data.Cursor().target then
                            self.text = ""
                            return
                        end

                        local scaleFactor = Api.InterfaceCore.GetScaleFactor()

                        -- Viewport bounds (screen pixels)
                        local vpX, vpY = Api.Window.GetPosition("ResizeWindow")
                        local vpDims = Api.Window.GetDimensions("ResizeWindow")
                        local vpW = vpDims.x * scaleFactor
                        local vpH = vpDims.y * scaleFactor

                        -- Mouse position (screen pixels)
                        local pos = Data.MousePosition()
                        local mx = pos.x
                        local my = pos.y

                        -- If cursor is outside the game viewport, clear
                        if mx < vpX or mx > vpX + vpW or my < vpY or my > vpY + vpH then
                            self.text = ""
                            return
                        end

                        -- Pixel delta from viewport centre (player position) to cursor
                        local dx = mx - (vpX + vpW / 2)
                        local dy = my - (vpY + vpH / 2)

                        local distance = math.floor(isoMetric(dx, dy) / PIXELS_PER_TILE)

                        -- Position the label near the cursor
                        self.offsetFromParent = {
                            mx + CURSOR_OFFSET_X,
                            my + CURSOR_OFFSET_Y
                        }
                        self.text = tostring(distance)
                    end)
                end)
            end,
        }

        label:create(true)
        label:onInitialize()
    end,
    OnShutdown = function()
        Api.Window.Destroy(NAME)
    end
}
