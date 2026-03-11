local NAME = "MongbatPlayerStatusWindow"

local Api = Mongbat.Api
local Data = Mongbat.Data
local Constants = Mongbat.Constants
local Components = Mongbat.Components

local function OnInitialize()
    local original = Components.Defaults.StatusWindow
    original:asComponent():setShowing(false)
    original:disable()
    local warShield = Components.Defaults.WarShield
    warShield:asComponent():setShowing(false)
    warShield:disable()

    local function PlayerName()
        return Components.Label {
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
    ---@param label LabelModel
    local function StatusBar(onUpdatePlayerStatus, onUpdateHealthBarColor, label)
        return Components.StatusBar(
            {
                OnUpdatePlayerStatus = onUpdatePlayerStatus,
                OnUpdateHealthBarColor = onUpdateHealthBarColor
            },
            label
        )
    end

    local function HealthStatusBar()
        return StatusBar(
            function(self, playerStatus)
                self:setId(playerStatus:getId())
                self:setCurrentValue(playerStatus:getCurrentHealth())
                self:setMaxValue(playerStatus:getMaxHealth())
                if not self._colorSet then
                    self:setColor(Constants.Colors.HealhBar[1])
                    self._colorSet = true
                end
            end,
            function(self, healthBarColor)
                self:setColor(healthBarColor:getVisualStateColor())
                self._colorSet = true
            end,
            {
                OnUpdatePlayerStatus = function(self, playerStatus)
                    self:setText(
                        string.format(
                            "%d / %d",
                            playerStatus:getCurrentHealth(),
                            playerStatus:getMaxHealth()
                        )
                    )
                end
            }
        )
    end

    local function ManaStatusBar()
        return StatusBar(
            function(self, playerStatus)
                self:setColor(Constants.Colors.Blue)
                self:setCurrentValue(playerStatus:getCurrentMana())
                self:setMaxValue(playerStatus:getMaxMana())
            end,
            nil,
            {
                OnUpdatePlayerStatus = function(self, playerStatus)
                    self:setText(
                        string.format(
                            "%d / %d",
                            playerStatus:getCurrentMana(),
                            playerStatus:getMaxMana()
                        )
                    )
                end
            }
        )
    end

    local function StaminaStatusBar()
        return StatusBar(
            function(self, playerStatus)
                self:setColor(Constants.Colors.YellowDark)
                self:setCurrentValue(playerStatus:getCurrentStamina())
                self:setMaxValue(playerStatus:getMaxStamina())
            end,
            nil,
            {
                OnUpdatePlayerStatus = function(self, playerStatus)
                    self:setText(
                        string.format(
                            "%d / %d",
                            playerStatus:getCurrentStamina(),
                            playerStatus:getMaxStamina()
                        )
                    )
                end
            }
        )
    end

    local function Window()
        return Components.Scaffold {
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
                    frame:setColor(Constants.Colors.Notoriety[6])
                else
                    frame:setColor(Constants.Colors.Notoriety[1])
                end
            end,
            OnLButtonDblClk = function(self)
                Api.UserAction.UseItem(self:getId())
            end,
            OnLButtonUp = function(self)
                if Data.Drag():isDraggingItem() then
                    Api.Drag.DragToObject(self:getId())
                else
                    Api.Target.LeftClick(self:getId())
                end
            end
        }
    end

    Window():create(true)
end

local function OnShutdown()
    Api.Window.Destroy(NAME)
    local original = Components.Defaults.StatusWindow
    original:restore()
    original:asComponent():setShowing(true)
    local warShield = Components.Defaults.WarShield
    warShield:restore()
    warShield:asComponent():setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}

