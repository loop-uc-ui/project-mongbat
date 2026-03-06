local NAME = "MongbatResizeWindow"
local MIN_SIZE = 200

---
--- Calculates viewport percentages from the window's current position and size,
--- then pushes them to the engine renderer.
---@param context Context
---@param window Window
local function sendViewportData(context, window)
    local x, y = window:getOffsetFromParent()
    local dimens = window:getDimensions()
    local scale = context.Api.InterfaceCore.GetScale()
    local screen = context.Data.ScreenResolution()

    local sizeX = (dimens.x * scale) / screen.x
    local sizeY = (dimens.y * scale) / screen.y
    local posX = (x * scale) / screen.x
    local posY = (y * scale) / screen.y

    context.Api.Viewport.Update(sizeX, sizeY, posX, posY)
end

---
--- Reads viewport settings from SystemData and repositions/resizes the window to
--- match. Called on initialisation and whenever VIEWPORT_CHANGED fires.
---@param context Context
---@param window Window
local function syncWindowFromViewport(context, window)
    local resolution = context.Data.Resolution()

    if not resolution:isViewportEnabled() then
        window:setShowing(false)
        return
    end

    window:setShowing(true)

    local scaleFactor = context.Api.InterfaceCore.GetScaleFactor()
    local screen = context.Data.ScreenResolution()

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
    OnInitialize = function(context)
        local defaultResizeWindow = context.Components.Defaults.ResizeWindow
        defaultResizeWindow:asComponent():setShowing(false)
        defaultResizeWindow:disable()

        local locked = context.Api.Interface.LoadBoolean("MongbatResizeWindowLocked", false)

        local function LockButton(onInit)
            return context.Components.Label {
                OnInitialize = onInit,
                OnLButtonUp = function(self)
                    locked = not locked
                    context.Api.Interface.SaveBoolean("MongbatResizeWindowLocked", locked)
                    local parent = self:getParent()
                    context.Api.Window.SetMovable(parent, not locked)
                    if locked then
                        self:setText(L"[locked]")
                    else
                        self:setText(L"[unlocked]")
                    end
                end,
            }
        end

        local window
        window = context.Components.Window {
            Name = NAME,
            MinWidth = MIN_SIZE,
            MinHeight = MIN_SIZE,
            OnRButtonUp = function() end,
            OnInitialize = function(self)
                context.Api.Window.RestorePosition(NAME, true)
                syncWindowFromViewport(context, self)
                self:setMovable(not locked)

                local lockLabel = LockButton(function(btn)
                    btn:setDimensions(60, 14)
                    btn:setLayer():overlay()
                    if locked then
                        btn:setText(L"[locked]")
                    else
                        btn:setText(L"[unlocked]")
                    end
                end)

                self:setChildren { lockLabel }
            end,
            OnLayout = function(self, children, child, index)
                if index == 1 then
                    child:addAnchor("bottomleft", self:getName(), "bottomleft", 4, -4)
                end
            end,
            OnUpdate = function(self)
                if self:isMoving() then
                    sendViewportData(context, self)
                end
            end,
            OnDimensionsChanged = function(self, width, height)
                sendViewportData(context, self)
            end,
            OnViewportChanged = function(self)
                syncWindowFromViewport(context, self)
            end,
        }

        window:create(true)
    end,

    OnShutdown = function(context)
        context.Api.Window.Destroy(NAME)

        local defaultResizeWindow = context.Components.Defaults.ResizeWindow
        defaultResizeWindow:restore()
        defaultResizeWindow:asComponent():setShowing(true)
    end,
}
