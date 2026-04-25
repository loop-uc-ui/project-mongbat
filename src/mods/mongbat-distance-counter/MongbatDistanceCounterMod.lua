-- Distance counter overlay: shows the Chebyshev tile distance from the player
-- to the cursor while a target cursor is active.
--
-- Pattern: Mongbat is a router. This mod owns one Label window. Per-frame
-- M.OnUpdate recomputes screen position + text from live engine state and
-- pushes them to the engine via thin Api setters.

local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Constants = Mongbat.Constants

local NAME = "MongbatDistanceCounterLabel"

-- Pixels per tile in the 2:1 isometric projection at default camera zoom.
local PIXELS_PER_TILE = 64

local CURSOR_OFFSET_X = 16
local CURSOR_OFFSET_Y = -16

local M = {}

--- 2:1 isometric pixel metric -> Chebyshev tile distance.
local function isoMetric(dx, dy)
    return math.max(math.abs(dx + 2 * dy), math.abs(2 * dy - dx))
end

--- Returns offsetX, offsetY, text — or nil if the overlay should be hidden.
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

function M.OnLoad()
    Mongbat.CreateWindow {
        name     = NAME,
        template = "MongbatLabel",
        module   = M,
        showing  = false,
    }
    Api.Window.SetHandleInput(NAME, false)
    Api.Window.SetLayer(NAME, Constants.WindowLayers.Overlay)
    Api.Window.SetDimensions(NAME, 60, 20)
end

function M.OnUnload()
    Mongbat.DestroyWindow(NAME)
end

function M.OnUpdate(_dt)
    local x, y, text = compute()
    if not x or not y or not text then
        Api.Window.SetShowing(NAME, false)
        return
    end
    Api.Window.SetOffsetFromParent(NAME, x, y)
    Api.Label.SetText(NAME, text)
    Api.Window.SetShowing(NAME, true)
end

Mongbat.Mod {
    Name   = "MongbatDistanceCounter",
    Path   = "/src/mods/mongbat-distance-counter",
    Module = M,
}
