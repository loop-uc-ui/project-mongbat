

Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = function (context)
        local original = context.Components.Defaults.StatusWindow
        local statusWindow = original:getName()

        ---@param name string
        ---@param onUpdatePlayerStatus fun(self: StatusBar, playerStatus: PlayerStatusWrapper)
        local function StatusBar(name, onUpdatePlayerStatus)
            return context.Components.StatusBar(statusWindow .. name)
                :onUpdatePlayerStatus(onUpdatePlayerStatus)
                :build()
        end

        local function HealthStatusBar()
            return StatusBar("HealthBar", function (self, playerStatus)
                self:setCurrentValue(playerStatus:getCurrentHealth())
                self:setMaxValue(playerStatus:getMaxHealth())
            end)
        end

        local function ManaStatusBar()
            return StatusBar("ManaBar", function (self, playerStatus)
                self:setCurrentValue(playerStatus:getCurrentMana())
                self:setMaxValue(playerStatus:getMaxMana())
            end)
        end

        local function StaminaStatusBar()
            return StatusBar("StaminaBar", function (self, playerStatus)
                self:setCurrentValue(playerStatus:getCurrentStamina())
                self:setMaxValue(playerStatus:getMaxStamina())
            end)
        end

        local function Window()
            return context.Components.Window(statusWindow)
                :onInitialize(function (self)
                    self:setDimensions(300, 150)
                    self:setChildren {
                        HealthStatusBar(),
                        ManaStatusBar(),
                        StaminaStatusBar()
                    }
                end)
                :onRButtonUp(function () end)
                :build()
        end

        original:getDefault().UpdateLatency = function () end
        original:asComponent():destroy()
        Window():create(true)
    end
}