-- Distance counter overlay: shows the Chebyshev tile distance from the player
-- to the cursor while a target cursor is active.
--
-- Pattern: declarative. M.Build(emit) emits the label window only when a
-- target cursor is up and the cursor is over the viewport. When inactive,
-- nothing is emitted and the lib destroys any prior window.

local UI        = Mongbat.UI
local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Constants = Mongbat.Constants

-- Pixels per tile in the 2:1 isometric projection at default camera zoom.
local PIXELS_PER_TILE = 64

local CURSOR_OFFSET_X = 16
local CURSOR_OFFSET_Y = -16

local M = {}

--- 2:1 isometric pixel metric -> Chebyshev tile distance.
local function isoMetric(dx, dy)
    return math.max(math.abs(dx + 2 * dy), math.abs(2 * dy - dx))
end

--- Returns offsetX, offsetY, text -- or nil if the overlay should be hidden.
local function compute()
    if not Data.Cursor():isTarget() then return nil end

    local scaleFactor = Api.InterfaceCore.GetScaleFactor()

    local vpX, vpY = Api.Window.GetPosition("ResizeWindow")
    local vpDims   = Api.Window.GetDimensions("ResizeWindow")
    local vpW      = vpDims.x * scaleFactor
    local vpH      = vpDims.y * scaleFactor

    local pos = Data.MousePosition()
    local mx, my = pos.x, pos.y
    if mx < vpX or mx > vpX + vpW or my < vpY or my > vpY + vpH then
        return nil
    end

    local dx = mx - (vpX + vpW / 2)
    local dy = my - (vpY + vpH / 2)
    local distance = math.floor(isoMetric(dx, dy) / PIXELS_PER_TILE)

    return mx + CURSOR_OFFSET_X, my + CURSOR_OFFSET_Y, tostring(distance)
end

function M.Build(emit)
    local x, y, text = compute()
    if not x or not y or not text then return end
    emit("label", {
        template = "MongbatLabel",
        widget   = UI.Label()
            :setText(text)
            :setDimensions(60, 20)
            :setOffsetFromParent(x, y)
            :setHandleInput(false)
            :setLayer(Constants.WindowLayers.Overlay),
    })
end

Mongbat.Mod {
    Name   = "MongbatDistanceCounter",
    Path   = "/src/mods/mongbat-distance-counter",
    Module = M,
}