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
            OnUpdatePlayer = function(self, player)
                self:setId(player:getPlayerId())
                local name = player:getName()
                if name then
                    self:setText(name)
                end
            end
        }
    end

    ---@param onUpdatePlayer fun(self: StatusBar, player: PlayerDataComposite)
    ---@param label LabelModel
    local function StatusBar(onUpdatePlayer, label)
        return Components.StatusBar(
            {
                OnUpdatePlayer = onUpdatePlayer
            },
            label
        )
    end

    local function HealthStatusBar()
        return StatusBar(
            function(self, player)
                self:setId(player:getPlayerId())
                self:setCurrentValue(player:getCurrentHealth())
                self:setMaxValue(player:getMaxHealth())
                local hbColor = player:getVisualStateColor()
                if hbColor then
                    self:setColor(hbColor)
                    self._colorSet = true
                elseif not self._colorSet then
                    self:setColor(Constants.Colors.HealhBar[1])
                    self._colorSet = true
                end
            end,
            {
                OnUpdatePlayer = function(self, player)
                    self:setText(
                        string.format(
                            "%d / %d",
                            player:getCurrentHealth(),
                            player:getMaxHealth()
                        )
                    )
                end
            }
        )
    end

    local function ManaStatusBar()
        return StatusBar(
            function(self, player)
                self:setColor(Constants.Colors.Blue)
                self:setCurrentValue(player:getCurrentMana())
                self:setMaxValue(player:getMaxMana())
            end,
            {
                OnUpdatePlayer = function(self, player)
                    self:setText(
                        string.format(
                            "%d / %d",
                            player:getCurrentMana(),
                            player:getMaxMana()
                        )
                    )
                end
            }
        )
    end

    local function StaminaStatusBar()
        return StatusBar(
            function(self, player)
                self:setColor(Constants.Colors.YellowDark)
                self:setCurrentValue(player:getCurrentStamina())
                self:setMaxValue(player:getMaxStamina())
            end,
            {
                OnUpdatePlayer = function(self, player)
                    self:setText(
                        string.format(
                            "%d / %d",
                            player:getCurrentStamina(),
                            player:getMaxStamina()
                        )
                    )
                end
            }
        )
    end

    local function Window()
        return Components.Window {
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
            OnUpdatePlayer = function(self, player)
                local frame = self:getFrame()
                self:setId(player:getPlayerId())
                if player:isInWarMode() then
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
