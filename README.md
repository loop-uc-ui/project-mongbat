# Mongbat

An extensible framework for modding Ultima Online Enhanced Client's UI.

## Writing a Mod

A mod is a Lua file that calls `Mongbat.Mod` with a table containing the mod's name, path, and lifecycle callbacks.

```lua
Mongbat.Mod {
    Name = "MongbatPlayerStatus",
    Path = "/src/mods/mongbat-player-status",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
```

### Example: Player Status

The Player Status mod replaces the default status window with a custom one. It demonstrates the core pattern: disable a default component, build a tree of Mongbat components, bind them to engine data events, and clean up on shutdown.

```lua
local Api = Mongbat.Api
local Data = Mongbat.Data
local Constants = Mongbat.Constants
local Components = Mongbat.Components

local function OnInitialize()
    -- Hide and disable the default status window
    local original = Components.Defaults.StatusWindow
    original:asComponent().showing = false
    original:disable()

    -- Build a Scaffold (draggable, framed window) with children
    local window = Components.Scaffold {
        Name = "MongbatPlayerStatusWindow",
        OnInitialize = function(self)
            self.dimensions = { 200, 150 }
            self.children = {
                Components.Label {
                    OnInitialize = function(self)
                        self.bindings = self:bindingsBuilder(function(bind)
                            bind:onMobileName(function(mobileName)
                                self.text = mobileName.name
                            end)
                        end)
                    end
                },
                Components.StatusBar(
                    {
                        OnInitialize = function(self)
                            self.bindings = self:bindingsBuilder(function(bind)
                                bind:onPlayerStatus(function(ps)
                                    self.currentValue = ps.currentHealth
                                    self.maxValue = ps.maxHealth
                                end)
                            end)
                        end
                    },
                    { OnInitialize = function(self) self:centerText() end }
                ),
            }
        end,
    }

    window:create(true)
end

local function OnShutdown()
    Api.Window.Destroy("MongbatPlayerStatusWindow")
    Components.Defaults.StatusWindow:restore()
end
```

## Namespaces

All namespaces are accessed through the global `Mongbat` table.

| Namespace | Purpose |
|---|---|
| `Mongbat.Components` | UI component constructors (`Scaffold`, `Window`, `Label`, `Button`, `StatusBar`, `ScrollWindow`, etc.) and access to default UI wrappers via `Components.Defaults`. |
| `Mongbat.Api` | Direct engine API calls organized by domain (`Api.Window`, `Api.Label`, `Api.DynamicImage`, `Api.Event`, etc.). |
| `Mongbat.Data` | Data accessors that wrap engine `WindowData` into typed objects (`Data.PlayerStatus()`, `Data.MobileName(id)`, `Data.ShopData()`, etc.). |
| `Mongbat.Constants` | Enumerations and fixed values: colors, core/data/system event names, broadcast IDs, text alignment, notoriety colors. |
| `Mongbat.Utils` | Utility helpers for arrays, strings, and tables (`Utils.Array`, `Utils.String`, `Utils.Table`). |
