Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = function(context)
        local original = context.Components.Defaults.StatusWindow
        local statusWindow = original:getName()

        local function PlayerName()
            return context.Components.Label {
                Name = statusWindow .. "PlayerNameLabel",
                OnUpdatePlayerStatus = function(self, playerStatus)
                    self:setId(playerStatus:getId())
                end,
                OnUpdateMobileStatus = function(self, mobileStatus)
                    self:setText(mobileStatus:getName())
                end
            }
        end

        ---@param name string
        ---@param onUpdatePlayerStatus fun(self: StatusBar, playerStatus: PlayerStatusWrapper)
        ---@param onUpdateHealthBarColor? fun(self: StatusBar, healthBarColor: HealthBarColorWrapper)
        local function StatusBar(name, onUpdatePlayerStatus, onUpdateHealthBarColor)
            return context.Components.StatusBar {
                Name = statusWindow .. name,
                OnUpdatePlayerStatus = onUpdatePlayerStatus,
                OnUpdateHealthBarColor = onUpdateHealthBarColor
            }
        end

        local function HealthStatusBar()
            return StatusBar(
                "HealthBar",
                function(self, playerStatus)
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
                "ManaBar",
                function(self, playerStatus)
                    self:setColor(context.Constants.Colors.Blue)
                    self:setCurrentValue(playerStatus:getCurrentMana())
                    self:setMaxValue(playerStatus:getMaxMana())
                end
            )
        end

        local function StaminaStatusBar()
            return StatusBar(
                "StaminaBar",
                function(self, playerStatus)
                    self:setColor(context.Constants.Colors.YellowDark)
                    self:setCurrentValue(playerStatus:getCurrentStamina())
                    self:setMaxValue(playerStatus:getMaxStamina())
                end
            )
        end

        local function Window()
            return context.Components.Window {
                Name = statusWindow,
                OnInitialize = function(self)
                    self:setDimensions(300, 150)
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

        context.Components.Defaults.WarShield:asComponent():setShowing(false)
        original:getDefault().UpdateLatency = function() end
        original:asComponent():destroy()
        Window():create(true)
    end,
    OnShutdown = function(context)
        context.Api.Window.DestroyWindow("StatusWindow")
        context.Components.Defaults.StatusWindow:asComponent():create(true)
        context.Components.Defaults.WarShield:asComponent():setShowing(true)
    end
}
