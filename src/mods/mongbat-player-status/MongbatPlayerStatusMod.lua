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
            OnUpdateMobile = function(self, mobile)
                self:setId(mobile:getPlayerId())
                local name = mobile:getName()
                if name then
                    self:setText(name)
                end
            end
        }
    end

    ---@param onUpdateMobile fun(self: StatusBar, mobile: MobileDataComposite)
    ---@param label LabelModel
    local function StatusBar(onUpdateMobile, label)
        return Components.StatusBar(
            {
                OnUpdateMobile = onUpdateMobile
            },
            label
        )
    end

    local function HealthStatusBar()
        return StatusBar(
            function(self, mobile)
                self:setId(mobile:getPlayerId())
                self:setCurrentValue(mobile:getCurrentHealth())
                self:setMaxValue(mobile:getMaxHealth())
                local hbColor = mobile:getVisualStateColor()
                if hbColor then
                    self:setColor(hbColor)
                    self._colorSet = true
                end
                if not self._colorSet then
                    self:setColor(Constants.Colors.HealhBar[1])
                    self._colorSet = true
                end
            end,
            {
                OnUpdateMobile = function(self, mobile)
                    self:setText(
                        string.format(
                            "%d / %d",
                            mobile:getCurrentHealth(),
                            mobile:getMaxHealth()
                        )
                    )
                end
            }
        )
    end

    local function ManaStatusBar()
        return StatusBar(
            function(self, mobile)
                self:setColor(Constants.Colors.Blue)
                self:setCurrentValue(mobile:getCurrentMana())
                self:setMaxValue(mobile:getMaxMana())
            end,
            {
                OnUpdateMobile = function(self, mobile)
                    self:setText(
                        string.format(
                            "%d / %d",
                            mobile:getCurrentMana(),
                            mobile:getMaxMana()
                        )
                    )
                end
            }
        )
    end

    local function StaminaStatusBar()
        return StatusBar(
            function(self, mobile)
                self:setColor(Constants.Colors.YellowDark)
                self:setCurrentValue(mobile:getCurrentStamina())
                self:setMaxValue(mobile:getMaxStamina())
            end,
            {
                OnUpdateMobile = function(self, mobile)
                    self:setText(
                        string.format(
                            "%d / %d",
                            mobile:getCurrentStamina(),
                            mobile:getMaxStamina()
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
            OnUpdateMobile = function(self, mobile)
                local frame = self:getFrame()
                self:setId(mobile:getPlayerId())
                if mobile:isInWarMode() then
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
