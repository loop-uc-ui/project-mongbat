---
name: architecture
description: 'Mongbat framework architecture overview. USE WHEN: understanding how mods are structured, how XML templates relate to Lua components, how events flow from engine to bindings, or how the component hierarchy works.'
---

# Architecture

## Mod Lifecycle

A mod is registered by calling `Mongbat.Mod` at the file scope. The engine's `.mod` XML manifest declares the Lua file and wires `OnInitialize`/`OnShutdown` to `Mongbat.ModManager.<Name>`.

```
.mod XML  →  engine loads Lua  →  Mongbat.Mod { Name, OnInitialize, OnShutdown }
                                        ↓
                              ModManager registers lifecycle hooks
                                        ↓
                              engine calls OnInitialize / OnShutdown
```

In `OnInitialize`, a mod typically:
1. Disables a default UI component (`Components.Defaults.X:disable()`)
2. Builds a component tree (`Components.Scaffold`, `Components.Label`, etc.)
3. Calls `:create(true)` on the root to instantiate it

In `OnShutdown`, a mod destroys its windows and calls `:restore()` on any disabled defaults.

## XML and Components

Mongbat's XML file (`Mongbat.xml`) defines reusable **templates** — the raw engine elements (windows, buttons, status bars, images). Lua components reference templates by name via the `Template` field in their model table:

```lua
Components.Button { Template = "MongbatButton18" }
```

When a component is created, the framework calls `Api.Window.CreateFromTemplate` to instantiate the XML template, then runs the component's `OnInitialize` callback to set properties and bindings.

Mods can also define their own XML templates in mod-specific XML files listed in their `.mod` manifest.

## Event Flow

Events flow from the engine through a single dispatch layer:

```
Engine fires event on a window
    → Mongbat.EventHandler.OnXxx (global Lua function)
        → looks up View in Cache[Active.window()]
        → calls _bindings.OnXxx on that View
        → if unhandled, propagates up _parentWindow chain (for input events)
```

### Binding Registration

Components declare bindings via `bindingsBuilder`:

```lua
self.bindings = self:bindingsBuilder(function(bind)
    bind:onPlayerStatus(function(playerStatus)
        self.currentValue = playerStatus.currentHealth
    end)
end)
```

Each binding call produces a `BindingSpec` with a `name`, `fn`, and `kind` (`"core"`, `"data"`, or `"system"`). When assigned to `self.bindings`, the framework calls `registerBindings` which:
- Stores the callback in `_bindings[name]`
- Calls the appropriate engine registration (`RegisterCoreEventHandler` or `RegisterEventHandler`)
- Points the engine handler to `Mongbat.EventHandler.<Name>`

### Binding Kinds

| Kind | Engine Call | Example |
|------|-----------|---------|
| `core` | `RegisterCoreEventHandler` | OnLButtonDown, OnShutdown, OnUpdate |
| `data` | `RegisterEventHandler` + entity data | onPlayerStatus, onMobileName, onContainerWindow |
| `system` | `RegisterEventHandler` | System-level broadcasts |

### Example: Player Status Data Flow

```
Engine updates PlayerStatus WindowData
    → fires registered event on the window
    → EventHandler.OnUpdatePlayerStatus()
        → reads Data.PlayerStatus() 
        → calls _bindings.OnUpdatePlayerStatus(data)
            → mod callback updates StatusBar values
```

## Component Hierarchy

```
Component (base: name only)
    └─ View (bindings, properties, dimensions, create/destroy)
        ├─ Window (children, layout)
        │   ├─ Scaffold (frame, background, dragging, snapping, resizing)
        │   │   ├─ DockableWindow (position persistence)
        │   │   └─ Gump (generic gump wrapping)
        │   ├─ ScrollWindow (scrollable child container)
        │   └─ ActionButtonGroup (grid of action buttons)
        ├─ Label, Button, StatusBar, DynamicImage, EditTextBox, etc.
        └─ DefaultComponent (wraps a stock UI global table)
```

Inheritance uses metatables (`setmetatable(Window, { __index = View })`). Properties are declared in `_ownProperties` tables and merged at load time so child classes inherit parent properties.
