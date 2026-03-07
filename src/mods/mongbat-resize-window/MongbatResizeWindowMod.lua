local NAME = "MongbatResizeWindow"
local MIN_SIZE = 200
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components

---
--- Calculates viewport percentages from the window's current position and size,
--- then pushes them to the engine renderer.
---@param window Window
local function sendViewportData(window)
    local x, y = window:getOffsetFromParent()
    local dimens = window:getDimensions()
    local scale = Api.InterfaceCore.GetScale()
    local screen = Data.ScreenResolution()

    local sizeX = (dimens.x * scale) / screen.x
    local sizeY = (dimens.y * scale) / screen.y
    local posX = (x * scale) / screen.x
    local posY = (y * scale) / screen.y

    Api.Viewport.Update(sizeX, sizeY, posX, posY)
end

---
--- Reads viewport settings from SystemData and repositions/resizes the window to
--- match. Called on initialisation and whenever VIEWPORT_CHANGED fires.
---@param window Window
local function syncWindowFromViewport(window)
    local resolution = Data.Resolution()

    if not resolution:isViewportEnabled() then
        window:setShowing(false)
        return
    end

    window:setShowing(true)

    local scaleFactor = Api.InterfaceCore.GetScaleFactor()
    local screen = Data.ScreenResolution()

    local posX = resolution:getViewportPosX() * screen.x * scaleFactor
    local posY = resolution:getViewportPosY() * screen.y * scaleFactor

    window:clearAnchors()
    window:addAnchor("topleft", "Root", "topleft", posX, posY)

    local windowWidth = scaleFactor * resolution:getViewportSizeX() * screen.x
    local windowHeight = scaleFactor * resolution:getViewportSizeY() * screen.y

    window:setDimensions(windowWidth, windowHeight)
end

Mongbat.Mod {
    Name = "MongbatResizeWindow",
    Path = "/src/mods/mongbat-resize-window",
    OnInitialize = function()
        local defaultResizeWindow = Components.Defaults.ResizeWindow
        defaultResizeWindow:asComponent():setShowing(false)
        defaultResizeWindow:disable()

        local locked = Api.Interface.LoadBoolean("MongbatResizeWindowLocked", false)

        local lockLabel = Components.Label {
            OnInitialize = function(self)
                self:setDimensions(60, 14)
                self:setLayer():overlay()
                if locked then
                    self:setText(L"[locked]")
                else
                    self:setText(L"[unlocked]")
                end
            end,
            OnLButtonUp = function(self)
                locked = not locked
                Api.Interface.SaveBoolean("MongbatResizeWindowLocked", locked)
                local parent = self:getParent()
                Api.Window.SetMovable(parent, not locked)
                if locked then
                    self:setText(L"[locked]")
                else
                    self:setText(L"[unlocked]")
                end
            end,
        }

        local window = Components.Window {
            Name = NAME,
            MinWidth = MIN_SIZE,
            MinHeight = MIN_SIZE,
            OnRButtonUp = function() end,
            OnInitialize = function(self)
                syncWindowFromViewport(self)
                self:setMovable(not locked)
                self:setChildren { lockLabel }
            end,
            OnShown = function(self)
                syncWindowFromViewport(self)
            end,
            OnLayout = function(self, children, child, index)
                if index == 1 then
                    child:addAnchor("bottomleft", self:getName(), "bottomleft", 4, -4)
                end
            end,
            OnUpdate = function(self)
                if self:isMoving() then
                    sendViewportData(self)
                end
            end,
            OnDimensionsChanged = function(self, width, height)
                sendViewportData(self)
            end,
            OnViewportChanged = function(self)
                syncWindowFromViewport(self)
            end,
        }

        window:create(true)
    end,

    OnShutdown = function()
        Api.Window.Destroy(NAME)

        local defaultResizeWindow = Components.Defaults.ResizeWindow
        defaultResizeWindow:restore()
        defaultResizeWindow:asComponent():setShowing(true)
    end,
}
