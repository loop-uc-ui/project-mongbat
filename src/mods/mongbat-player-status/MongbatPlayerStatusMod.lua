

local NAME = "StatusWindow"

---@param context Context
---@param name string
---@param onUpdatePlayerStatus fun(self: StatusBar, playerStatus: PlayerStatusWrapper)
local function StatusBar(context, name, onUpdatePlayerStatus)
    return context.Components.StatusBar {
        Name = NAME .. name,
        ---@param self StatusBar
        OnInitialize = function (self)
            self:setDimensions(300, 24)
        end,
        OnUpdatePlayerStatus = onUpdatePlayerStatus
    }
end

local function HealthStatusBar(context)
    return StatusBar(context, "HealthBar", function (self, playerStatus)
        self:setCurrentValue(playerStatus:getCurrentHealth())
        self:setMaxValue(playerStatus:getMaxHealth())
    end)
end

local function ManaStatusBar(context)
    return StatusBar(context, "ManaBar", function (self, playerStatus)
        self:setCurrentValue(playerStatus:getCurrentMana())
        self:setMaxValue(playerStatus:getMaxMana())
    end)
end

local function StaminaStatusBar(context)
    return StatusBar(context, "StaminaBar", function (self, playerStatus)
        self:setCurrentValue(playerStatus:getCurrentStamina())
        self:setMaxValue(playerStatus:getMaxStamina())
    end)
end

---@param context Context
local function Window(context)
    return context.Components.Window {
        Name = NAME,
        PersistPosition = true,
        ---@param self Window
        OnInitialize = function (self)
            self:setDimensions(300, 150)
            self:setChildren {
                HealthStatusBar(context),
                ManaStatusBar(context),
                StaminaStatusBar(context)
            }
        end,
        OnRButtonUp = function (_)
        end
    }
end

MongbatPlayerStatusMod = Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = function (context)
        local original = context.Components.Defaults.StatusWindow
        original:getDefault().UpdateLatency = function () end
        original:asComponent():destroy()
        Window(context):create(true)
    end
}