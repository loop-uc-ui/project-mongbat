local NAME = "MongbatPlayerStatusWindow"

---@param context Context
local function OnInitialize(context)
    local original = context.Components.Defaults.StatusWindow
    original:asComponent():setShowing(false)
    original:disable()

    local function PlayerName()
        return context.Components.Label {
            OnUpdatePlayerStatus = function(self, playerStatus)
                self:setId(playerStatus:getId())
            end,
            OnUpdateMobileStatus = function(self, mobileStatus)
                self:setText(mobileStatus:getName())
            end
        }
    end

    ---@param onUpdatePlayerStatus fun(self: StatusBar, playerStatus: PlayerStatusWrapper)
    ---@param onUpdateHealthBarColor? fun(self: StatusBar, healthBarColor: HealthBarColorWrapper)
    local function StatusBar(onUpdatePlayerStatus, onUpdateHealthBarColor)
        return context.Components.StatusBar {
            OnUpdatePlayerStatus = onUpdatePlayerStatus,
            OnUpdateHealthBarColor = onUpdateHealthBarColor
        }
    end

    local function HealthStatusBar()
        return StatusBar(
            function(self, playerStatus)
                self:setId(playerStatus:getId())
                self:setCurrentValue(playerStatus:getCurrentHealth())
                self:setMaxValue(playerStatus:getMaxHealth())
            end,
            function(self, healthBarColor)
                self:setColor(healthBarColor:getVisualStateColor())
            end
        )
    end

    local function ManaStatusBar()
        return StatusBar(
            function(self, playerStatus)
                self:setColor(context.Constants.Colors.Blue)
                self:setCurrentValue(playerStatus:getCurrentMana())
                self:setMaxValue(playerStatus:getMaxMana())
            end
        )
    end

    local function StaminaStatusBar()
        return StatusBar(
            function(self, playerStatus)
                self:setColor(context.Constants.Colors.YellowDark)
                self:setCurrentValue(playerStatus:getCurrentStamina())
                self:setMaxValue(playerStatus:getMaxStamina())
            end
        )
    end

    local function Window()
        return context.Components.Window {
            Name = NAME,
            OnInitialize = function(self)
                self:setDimensions(200, 150)
                self:setChildren {
                    PlayerName(),
                    HealthStatusBar(),
                    ManaStatusBar(),
                    StaminaStatusBar()
                }
            end,
            OnRButtonUp = function() end,
            OnUpdatePlayerStatus = function(self, playerStatus)
                local frame = self:getFrame()
                self:setId(playerStatus:getId())
                if playerStatus:isInWarMode() then
                    frame:setColor(context.Constants.Colors.Notoriety[6])
                else
                    frame:setColor(context.Constants.Colors.Notoriety[1])
                end
            end,
            OnLButtonDblClk = function(self)
                context.Api.UserAction.UseItem(self:getId())
            end,
            OnLButtonUp = function(self)
                if context.Data.Drag():isDraggingItem() then
                    context.Api.Drag.DragToObject(self:getId())
                else
                    context.Api.Target.LeftClick(self:getId())
                end
            end
        }
    end

    Window():create(true)
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.DestroyWindow(NAME)
    local original = context.Components.Defaults.StatusWindow
    original:restore()
    original:asComponent():setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}

