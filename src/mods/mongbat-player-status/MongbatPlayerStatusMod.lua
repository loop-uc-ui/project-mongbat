local NAME = "MongbatPlayerStatusWindow"

local Api = Mongbat.Api
local Constants = Mongbat.Constants
local Components = Mongbat.Components
local Defaults = Components.Defaults

---@param self StatusBar
---@param windowData WindowDataWrapper
---@param current integer
---@param max integer
local function setBarValues(self, windowData, current, max)
    local id = windowData:playerStatus():getId()
    self:setId(id)
    self:setCurrentValue(current)
    self:setMaxValue(max)
end

---@param self Label
---@param windowData WindowDataWrapper
---@param fmt string
---@param current integer
---@param max integer
local function setBarLabel(self, windowData, fmt, current, max)
    self:setText(string.format(fmt, current, max))
end

local function PlayerName()
    return Components.Label {
        OnUpdate = function(self, _, windowData)
            local id = windowData:playerStatus():getId()
            self:setId(id)
            local mobileStatus = windowData:mobileStatus(id)
            if mobileStatus and mobileStatus:getData() then
                self:setText(mobileStatus:getName())
            end
        end
    }
end

local function HealthStatusBar()
    local bar = Components.StatusBar {
        OnUpdate = function(self, _, windowData)
            local playerStatus = windowData:playerStatus()
            setBarValues(self, windowData, playerStatus:getCurrentHealth(), playerStatus:getMaxHealth())
            local healthBarColor = windowData:healthBarColor(playerStatus:getId())
            if healthBarColor and healthBarColor:getData() then
                self:setForegroundTint(healthBarColor:getVisualStateColor())
            else
                self:setForegroundTint(Constants.Colors.HealhBar[1])
            end
        end
    }
    local label = Components.Label {
        OnUpdate = function(self, _, windowData)
            local playerStatus = windowData:playerStatus()
            setBarLabel(self, windowData, "%d / %d", playerStatus:getCurrentHealth(), playerStatus:getMaxHealth())
        end
    }
    label:setLayer(Constants.WindowLayers.Secondary)
    bar:addChild(label)
    return bar
end

local function ManaStatusBar()
    local bar = Components.StatusBar {
        OnUpdate = function(self, _, windowData)
            local playerStatus = windowData:playerStatus()
            setBarValues(self, windowData, playerStatus:getCurrentMana(), playerStatus:getMaxMana())
            self:setForegroundTint(Constants.Colors.Blue)
        end
    }
    local label = Components.Label {
        OnUpdate = function(self, _, windowData)
            local playerStatus = windowData:playerStatus()
            setBarLabel(self, windowData, "%d / %d", playerStatus:getCurrentMana(), playerStatus:getMaxMana())
        end
    }
    label:setLayer(Constants.WindowLayers.Secondary)
    bar:addChild(label)
    return bar
end

local function StaminaStatusBar()
    local bar = Components.StatusBar {
        OnUpdate = function(self, _, windowData)
            local playerStatus = windowData:playerStatus()
            setBarValues(self, windowData, playerStatus:getCurrentStamina(), playerStatus:getMaxStamina())
            self:setForegroundTint(Constants.Colors.YellowDark)
        end
    }
    local label = Components.Label {
        OnUpdate = function(self, _, windowData)
            local playerStatus = windowData:playerStatus()
            setBarLabel(self, windowData, "%d / %d", playerStatus:getCurrentStamina(), playerStatus:getMaxStamina())
        end
    }
    label:setLayer(Constants.WindowLayers.Secondary)
    bar:addChild(label)
    return bar
end

local function OnInitialize()
    Defaults.StatusWindow:setShowing(false)
    Defaults.WarShield:setShowing(false)

    local window = Components.Window {
        Name = NAME,
        OnInitialize = function(self)
            self:setDimensions(200, 150)
            self:addChildren(
                { PlayerName(), HealthStatusBar(), ManaStatusBar(), StaminaStatusBar() },
                { offsetX = 8, offsetY = 8, spacing = 4 }
            )
        end,
        OnUpdate = function(self, _, windowData)
            local playerStatus = windowData:playerStatus()
            self:setId(playerStatus:getId())
            if playerStatus:isInWarMode() then
                self:setColor(Constants.Colors.Notoriety[6])
            else
                self:setColor(Constants.Colors.Notoriety[1])
            end
        end
    }

    window:onLButtonDblClk(function(self)
        Api.UserAction.UseItem(self:getId())
    end)

    window:onLButtonUp(function(self)
        if Mongbat.Data.Drag():isDraggingItem() then
            Api.Drag.DragToObject(self:getId())
        else
            Api.Target.LeftClick(self:getId())
        end
    end)

    window:onRButtonUp(function(self)
        self:setShowing(false)
    end)

    window:create(true)
end

local function OnShutdown()
    Api.Window.Destroy(NAME)
    Defaults.StatusWindow:setShowing(true)
    Defaults.WarShield:setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
