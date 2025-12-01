Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = function(context)
        local original = context.Components.Defaults.StatusWindow
        local statusWindow = original:getName()

        local function PlayerName()
            return context.Components.Label {
                Name = statusWindow .. "PlayerNameLabel",
                OnUpdate = function(self)
                    self:setId(context.Data.PlayerStatus():getId())
                    self:setText(context.Data.MobileStatus(self:getId()):getName())
                end
            }
        end

        ---@param name string
        ---@param onUpdatePlayerStatus fun(self: StatusBar, playerStatus: PlayerStatusWrapper)
        local function StatusBar(name, onUpdatePlayerStatus, onUpdateHealthBarColor)
            return context.Components.StatusBar {
                Name = statusWindow .. name,
                OnUpdate = onUpdatePlayerStatus,
            }
        end

        local function HealthStatusBar()
            return StatusBar(
                "HealthBar",
                function(self)
                    local playerStatus = context.Data.PlayerStatus()
                    self:setCurrentValue(playerStatus:getCurrentHealth())
                    self:setMaxValue(playerStatus:getMaxHealth())
                    self:setColor(context.Data.HealthBarColor(playerStatus:getId()):getVisualStateColor())
                end
            )
        end

        local function ManaStatusBar()
            return StatusBar(
                "ManaBar",
                function(self)
                    self:setColor(context.Constants.Colors.Blue)
                    self:setCurrentValue(context.Data.PlayerStatus():getCurrentMana())
                    self:setMaxValue(context.Data.PlayerStatus():getMaxMana())
                end
            )
        end

        local function StaminaStatusBar()
            return StatusBar(
                "StaminaBar",
                function(self)
                    self:setColor(context.Constants.Colors.YellowDark)
                    self:setCurrentValue(context.Data.PlayerStatus():getCurrentStamina())
                    self:setMaxValue(context.Data.PlayerStatus():getMaxStamina())
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
                OnUpdate = function(self)
                    local playerStatus = context.Data.PlayerStatus()
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
