

Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = function (context)
        local original = context.Components.Defaults.StatusWindow
        local statusWindow = original:getName()

        local function PlayerName(playerId)
            return context.Components.Label {
                Name = statusWindow .. "PlayerNameLabel",
                Id = playerId,
                OnUpdatePlayerStatus = function (self, playerStatus)
                    self:setId(playerStatus:getId())
                end,
                OnUpdateMobileStatus = function (self, mobileStatus)
                    self:setText(mobileStatus:getName())
                end
            }
        end

        ---@param name string
        ---@param onInitialize fun(self: StatusBar)
        ---@param onUpdatePlayerStatus fun(self: StatusBar, playerStatus: PlayerStatusWrapper)
        ---@param onUpdateHealthBarColor fun(self: StatusBar, playerStatus: HealthBarColorWrapper)?
        local function StatusBar(name, onInitialize, onUpdatePlayerStatus, onUpdateHealthBarColor)
            return context.Components.StatusBar {
                Name = statusWindow .. name,
                OnInitialize = onInitialize,
                OnUpdatePlayerStatus = onUpdatePlayerStatus,
                OnUpdateHealthBarColor = onUpdateHealthBarColor
            }
        end

        local function HealthStatusBar()
            return StatusBar(
                "HealthBar",
                function (self)
                    self:setColor(context.Constants.Colors.Red)
                end,
                function (self, playerStatus)
                    self:setId(playerStatus:getId())
                    self:setCurrentValue(playerStatus:getCurrentHealth())
                    self:setMaxValue(playerStatus:getMaxHealth())
                end,
                function (self, healthBarColor)
                    self:setColor(healthBarColor:getVisualStateColor())
                end
            )
        end

        local function ManaStatusBar()
            return StatusBar(
                "ManaBar",
                function (self)
                    self:setColor(context.Constants.Colors.Blue)
                end,
                function (self, playerStatus)
                    self:setCurrentValue(playerStatus:getCurrentMana())
                    self:setMaxValue(playerStatus:getMaxMana())
                end
            )
        end

        local function StaminaStatusBar()
            return StatusBar(
                "StaminaBar",
                function (self)
                    self:setColor(context.Constants.Colors.YellowDark)
                end,
                function (self, playerStatus)
                    self:setCurrentValue(playerStatus:getCurrentStamina())
                    self:setMaxValue(playerStatus:getMaxStamina())
                end
            )
        end

        local function Window()
            return context.Components.Window {
                Name = statusWindow,
                OnInitialize = function (self)
                    self:setDimensions(300, 150)
                    self:setChildren {
                        PlayerName(context.Data.PlayerStatus():getId()),
                        HealthStatusBar(),
                        ManaStatusBar(),
                        StaminaStatusBar()
                    }
                end,
                OnRButtonUp = function () end,
                OnUpdatePlayerStatus = function (self, playerStatus)
                    local frame = self:getFrame()
                    if playerStatus:isInWarMode() then
                        frame:setColor(context.Constants.Colors.Notoriety[6])
                    else
                        frame:setColor(context.Constants.Colors.Notoriety[1])
                    end
                end
            }
        end

        context.Components.Defaults.WarShield:asComponent():setShowing(false)
        original:getDefault().UpdateLatency = function () end
        original:asComponent():destroy()
        Window():create(true)
    end,
    OnShutdown = function (context)
        context.Api.Window.DestroyWindow("StatusWindow")
        context.Components.Defaults.StatusWindow:asComponent():create(true)
        context.Components.Defaults.WarShield:asComponent():setShowing(true)
    end
}