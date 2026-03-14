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
            OnInitialize = function(self)
                self.bindings = self:bindingsBuilder(function(bind)
                    bind:onPlayerStatus(function(playerStatus)
                        self.id = playerStatus.id
                    end)
                    :onMobileName(function(mobileName)
                        self.text = mobileName.name
                    end)
                end)
            end
        }
    end

    ---@param onPlayerStatus fun(self: StatusBar, playerStatus: PlayerStatusWrapper)
    ---@param onHealthBarColor? fun(self: StatusBar, healthBarColor: HealthBarColorWrapper)
    ---@param label LabelModel
    local function StatusBar(onPlayerStatus, onHealthBarColor, label)
        return Components.StatusBar(
            {
                OnInitialize = function(self)
                    self.bindings = self:bindingsBuilder(function(bind)
                        bind:onPlayerStatus(function(playerStatus)
                            onPlayerStatus(self, playerStatus)
                        end)
                        if onHealthBarColor then
                            bind:onHealthBarColor(function(healthBarColor)
                                onHealthBarColor(self, healthBarColor)
                            end)
                        end
                    end)
                end
            },
            label
        )
    end

    local function HealthStatusBar()
        return StatusBar(
            function(self, playerStatus)
                self.id = playerStatus.id
                self.currentValue = playerStatus.currentHealth
                self.maxValue = playerStatus.maxHealth
                if not self._colorSet then
                    self.color = Constants.Colors.HealhBar[1]
                    self._colorSet = true
                end
            end,
            function(self, healthBarColor)
                self.color = healthBarColor.visualStateColor
                self._colorSet = true
            end,
            {
                OnInitialize = function(self)
                    self.bindings = self:bindingsBuilder(function(bind)
                        bind:onPlayerStatus(function(playerStatus)
                            self.text =
                                string.format(
                                    "%d / %d",
                                    playerStatus.currentHealth,
                                    playerStatus.maxHealth
                                )
                        end)
                    end)
                end
            }
        )
    end

    local function ManaStatusBar()
        return StatusBar(
            function(self, playerStatus)
                self.color = Constants.Colors.Blue
                self.currentValue = playerStatus.currentMana
                self.maxValue = playerStatus.maxMana
            end,
            nil,
            {
                OnInitialize = function(self)
                    self.bindings = self:bindingsBuilder(function(bind)
                        bind:onPlayerStatus(function(playerStatus)
                            self.text =
                                string.format(
                                    "%d / %d",
                                    playerStatus.currentMana,
                                    playerStatus.maxMana
                                )
                        end)
                    end)
                end
            }
        )
    end

    local function StaminaStatusBar()
        return StatusBar(
            function(self, playerStatus)
                self.color = Constants.Colors.YellowDark
                self.currentValue = playerStatus.currentStamina
                self.maxValue = playerStatus.maxStamina
            end,
            nil,
            {
                OnInitialize = function(self)
                    self.bindings = self:bindingsBuilder(function(bind)
                        bind:onPlayerStatus(function(playerStatus)
                            self.text =
                                string.format(
                                    "%d / %d",
                                    playerStatus.currentStamina,
                                    playerStatus.maxStamina
                                )
                        end)
                    end)
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
                self.bindings = self:bindingsBuilder(function(bind)
                    bind:onPlayerStatus(function(playerStatus)
                        local frame = self.frame
                        self.id = playerStatus.id
                        if playerStatus.inWarMode then
                            frame.color = Constants.Colors.Notoriety[6]
                        else
                            frame.color = Constants.Colors.Notoriety[1]
                        end
                    end)
                    :onRButtonUp(function() end)
                    :onLButtonDblClk(function()
                        Api.UserAction.UseItem(self.id)
                    end)
                    :onLButtonUp(function()
                        if Data.Drag().draggingItem then
                            Api.Drag.DragToObject(self.id)
                        else
                            Api.Target.LeftClick(self.id)
                        end
                    end)
                end)
            end,
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
