local NAME = "MongbatPlayerStatusWindow"

local Api = Mongbat.Api
local Data = Mongbat.Data
local Constants = Mongbat.Constants
local Components = Mongbat.Components

local function OnInitialize()
    local original = Components.Defaults.StatusWindow
    original:asComponent().showing = false
    original:disable()
    local warShield = Components.Defaults.WarShield
    warShield:asComponent().showing = false
    warShield:disable()

    local function PlayerName()
        return Components.Label {
            OnRenderData = function(self, state)
                self.id = state.mobile.playerId
                local name = state.mobile.name
                if name then
                    self.text = name
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
                self.id = state.mobile.playerId
                self.currentValue = state.mobile.currentHealth
                self.maxValue = state.mobile.maxHealth
                local hbColor = state.mobile.visualStateColor
                if hbColor then
                    self.color = hbColor
                    self._colorSet = true
                elseif not self._colorSet then
                    self.color = Constants.Colors.HealhBar[1]
                    self._colorSet = true
                end
            end,
            {
                OnRenderData = function(self, state)
                    self.text =
                        string.format(
                            "%d / %d",
                            state.mobile.currentHealth,
                            state.mobile.maxHealth
                        )
                end
            }
        )
    end

    local function ManaStatusBar()
        return StatusBar(
            function(self, state)
                self.color = Constants.Colors.Blue
                self.currentValue = state.mobile.currentMana
                self.maxValue = state.mobile.maxMana
            end,
            {
                OnRenderData = function(self, state)
                    self.text =
                        string.format(
                            "%d / %d",
                            state.mobile.currentMana,
                            state.mobile.maxMana
                        )
                end
            }
        )
    end

    local function StaminaStatusBar()
        return StatusBar(
            function(self, state)
                self.color = Constants.Colors.YellowDark
                self.currentValue = state.mobile.currentStamina
                self.maxValue = state.mobile.maxStamina
            end,
            {
                OnRenderData = function(self, state)
                    self.text =
                        string.format(
                            "%d / %d",
                            state.mobile.currentStamina,
                            state.mobile.maxStamina
                        )
                end
            }
        )
    end

    local function Window()
        return Components.Window {
            Name = NAME,
            OnInitialize = function(self)
                self.dimensions = {200, 150}
                self.children = {
                    PlayerName(),
                    HealthStatusBar(),
                    ManaStatusBar(),
                    StaminaStatusBar()
                }
            end,
            OnRButtonUp = function() end,
            OnRenderData = function(self, state)
                local frame = self.frame
                self.id = state.mobile.playerId
                if state.mobile.inWarMode then
                    frame.color = Constants.Colors.Notoriety[6]
                else
                    frame.color = Constants.Colors.Notoriety[1]
                end
            end,
            OnLButtonDblClk = function(self)
                Api.UserAction.UseItem(self.id)
            end,
            OnLButtonUp = function(self)
                if Data.Drag().draggingItem then
                    Api.Drag.DragToObject(self.id)
                else
                    Api.Target.LeftClick(self.id)
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
    original:asComponent().showing = true
    local warShield = Components.Defaults.WarShield
    warShield:restore()
    warShield:asComponent().showing = true
end

Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
