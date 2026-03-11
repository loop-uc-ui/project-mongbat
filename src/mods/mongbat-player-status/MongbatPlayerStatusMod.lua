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
            OnRenderData = function(self, state)
                self:setId(state.mobile:getPlayerId())
                local name = state.mobile:getName()
                if name then
                    self:setText(name)
                end
            end
        }
    end

    ---@param onRenderData fun(self: StatusBar, state: ViewState)
    ---@param label LabelModel
    local function StatusBar(onRenderData, label)
        return Components.StatusBar(
            {
                OnRenderData = onRenderData
            },
            label
        )
    end

    local function HealthStatusBar()
        return StatusBar(
            function(self, state)
                self:setId(state.mobile:getPlayerId())
                self:setCurrentValue(state.mobile:getCurrentHealth())
                self:setMaxValue(state.mobile:getMaxHealth())
                local hbColor = state.mobile:getVisualStateColor()
                if hbColor then
                    self:setColor(hbColor)
                    self._colorSet = true
                elseif not self._colorSet then
                    self:setColor(Constants.Colors.HealhBar[1])
                    self._colorSet = true
                end
            end,
            {
                OnRenderData = function(self, state)
                    self:setText(
                        string.format(
                            "%d / %d",
                            state.mobile:getCurrentHealth(),
                            state.mobile:getMaxHealth()
                        )
                    )
                end
            }
        )
    end

    local function ManaStatusBar()
        return StatusBar(
            function(self, state)
                self:setColor(Constants.Colors.Blue)
                self:setCurrentValue(state.mobile:getCurrentMana())
                self:setMaxValue(state.mobile:getMaxMana())
            end,
            {
                OnRenderData = function(self, state)
                    self:setText(
                        string.format(
                            "%d / %d",
                            state.mobile:getCurrentMana(),
                            state.mobile:getMaxMana()
                        )
                    )
                end
            }
        )
    end

    local function StaminaStatusBar()
        return StatusBar(
            function(self, state)
                self:setColor(Constants.Colors.YellowDark)
                self:setCurrentValue(state.mobile:getCurrentStamina())
                self:setMaxValue(state.mobile:getMaxStamina())
            end,
            {
                OnRenderData = function(self, state)
                    self:setText(
                        string.format(
                            "%d / %d",
                            state.mobile:getCurrentStamina(),
                            state.mobile:getMaxStamina()
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
            OnRenderData = function(self, state)
                local frame = self:getFrame()
                self:setId(state.mobile:getPlayerId())
                if state.mobile:isInWarMode() then
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
