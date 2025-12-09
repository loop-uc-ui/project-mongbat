--[[
    Reactive Player Status Window

    Demonstrates the declarative reactive UI system.
    Uses component callbacks (onUpdatePlayerStatus) instead of global event handlers
    to properly integrate with the game's event throttling.
]]

local NAME = "MongbatPlayerStatusReactiveWindow"

local ModuleState = {
    app = nil
}

---@param context Context
local function OnInitialize(context)
    local Reactive = context.Reactive
    local Colors = context.Constants.Colors
    local Api = context.Api
    local Data = context.Data

    -- Hide the default status window
    local original = context.Components.Defaults.StatusWindow
    original:asComponent():setShowing(false)
    original:disable()

    -- Create reactive state
    local state = Reactive.State {
        id = 0,
        name = "Player",
        health = 100,
        maxHealth = 100,
        mana = 50,
        maxMana = 50,
        stamina = 75,
        maxStamina = 75,
        isInWarMode = false,
        healthBarColor = Colors.Red  -- Can change based on visual state (poison, etc.)
    }

    -- Pure component function - uses component callbacks for events
    local function PlayerStatusUI(s)
        -- Determine frame color based on war mode
        local frameColor = s.isInWarMode
            and Colors.Notoriety[6]  -- Red for war mode
            or Colors.Notoriety[1]   -- Blue for peace mode

        return Reactive.Window {
            name = NAME,
            width = 200,
            height = 150,
            frameColor = frameColor,
            onRightClick = function() end,
            -- Click to target
            onPress = function(self)
                if Data.Drag():isDraggingItem() then
                    Api.Drag.DragToObject(s.id)
                else
                    Api.Target.LeftClick(s.id)
                end
            end,
            -- Double-click to use (paperdoll)
            onDoubleClick = function(self)
                Api.UserAction.UseItem(s.id)
            end,
            -- Update state from component callbacks
            onUpdatePlayerStatus = function(self, playerStatus)
                state({
                    id = playerStatus:getId(),
                    health = playerStatus:getCurrentHealth(),
                    maxHealth = playerStatus:getMaxHealth(),
                    mana = playerStatus:getCurrentMana(),
                    maxMana = playerStatus:getMaxMana(),
                    stamina = playerStatus:getCurrentStamina(),
                    maxStamina = playerStatus:getMaxStamina(),
                    isInWarMode = playerStatus:isInWarMode()
                })
            end,
            onUpdateMobileStatus = function(self, mobileStatus)
                state.name = mobileStatus:getName()
            end,
            onUpdateHealthBarColor = function(self, healthBarColor)
                state.healthBarColor = healthBarColor:getVisualStateColor()
            end,
            children = {
                Reactive.Label {
                    key = "name",
                    text = s.name
                },
                Reactive.StatusBar {
                    key = "health",
                    value = s.health,
                    maxValue = s.maxHealth,
                    foregroundColor = s.healthBarColor,
                    labelText = string.format("%d / %d", s.health, s.maxHealth)
                },
                Reactive.StatusBar {
                    key = "mana",
                    value = s.mana,
                    maxValue = s.maxMana,
                    foregroundColor = Colors.Blue,
                    labelText = string.format("%d / %d", s.mana, s.maxMana)
                },
                Reactive.StatusBar {
                    key = "stamina",
                    value = s.stamina,
                    maxValue = s.maxStamina,
                    foregroundColor = Colors.YellowDark,
                    labelText = string.format("%d / %d", s.stamina, s.maxStamina)
                }
            }
        }
    end

    -- Create and mount the reactive app
    ModuleState.app = Reactive.App(PlayerStatusUI, state, NAME):mount()
end

---@param context Context
local function OnShutdown(context)
    if ModuleState.app then
        ModuleState.app:unmount()
        ModuleState.app = nil
    end

    local original = context.Components.Defaults.StatusWindow
    original:restore()
    original:asComponent():setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatPlayerStatusReactive",
    Path = "/src/mods/mongbat-player-status-reactive",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
