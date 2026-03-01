# Mongbat

**Extensible Modding Framework for Ultima Online's Enhanced Client**

Mongbat is a Lua wrapper framework that provides an object-oriented abstraction layer over the [Ultima Online Enhanced Client](https://uo.com/) (UO EC) UI system. It lets mod developers create, replace, or extend UI windows with less boilerplate, better isolation, and a consistent API.

## Features

- **Component System** — Builder-pattern factories for windows, buttons, labels, status bars, images, text inputs, and more.
- **DefaultComponent Replacement** — Transparently intercept and replace vanilla UI windows while preserving the ability to restore originals.
- **Event Abstraction** — Unified wrappers for the engine's three event tiers: `DataEvents`, `SystemEvents`, and `CoreEvents`.
- **Api Namespace** — Organized sub-tables wrapping raw engine globals (`WindowSetShowing`, `CreateWindowFromTemplate`, etc.) with safety checks.
- **Data Wrappers** — Typed accessors for `WindowData.*` tables (player stats, health bars, mobile info, etc.).
- **Utilities** — `Array`, `Table`, and `String` helper libraries (map, filter, reduce, merge, deepCopy, split, etc.).
- **Constants** — Enumerations for anchor points, window layers, events, colors, textures, button states, and more.

## Project Structure

```
src/
  lib/
    Mongbat.lua          # Framework core
    Mongbat.xml          # XML templates for all component types
    Mongbat.mod          # .mod descriptor
    MongbatTextures.dds  # Shared texture atlas
  mods/
    mongbat-*/                 # Individual mods that replace or extend default UI windows
docs/                    # Local reference docs (XSD, UI notes)
Fonts/                   # Font definitions
```

## Quick Start

### Creating a Mod

1. Create a folder under `src/mods/` (e.g., `mongbat-my-mod/`).
2. Add a `.mod` XML file declaring your mod and its dependency on Mongbat:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:noNamespaceSchemaLocation="../../Interface.xsd">
     <UiMod name="MongbatMyMod" version="1.0" date="2025">
       <Author name="You" />
       <Description text="My first Mongbat mod." />
       <Dependencies>
         <Dependency name="Mongbat" />
       </Dependencies>
       <Files>
         <File name="MongbatMyMod.lua" />
       </Files>
     </UiMod>
   </ModuleFile>
   ```
3. Write your Lua entry point:
   ```lua
   Mongbat.Mod {
       Name = "MongbatMyMod",
       OnInitialize = function(ctx)
           local window = ctx.Components.Window {
               Name = "MongbatMyModWindow",
               Title = L"My Mod",
               OnInitialize = function(self)
                   self:setDimensions(300, 200)
                   self:addAnchor("center", "Root", "center", 0, 0)
               end,
           }:create(true)
       end,
       OnShutdown = function(ctx)
           -- cleanup happens automatically for tracked views
       end,
   }
   ```

### Context Object

Every mod receives a **context object** (`ctx`) with:

| Field | Description |
|---|---|
| `ctx.Api` | Wrapped engine API functions (e.g., `ctx.Api.Window.SetShowing(name, bool)`) |
| `ctx.Data` | Typed data wrappers (e.g., `ctx.Data.PlayerStatus.CurrentHealth`) |
| `ctx.Utils` | Array/Table/String utility libraries |
| `ctx.Constants` | Enumerations (events, anchor points, layers, colors, etc.) |
| `ctx.Components` | Factory functions for UI elements (Window, Button, Label, etc.) |

### Builder Pattern

Components use a fluent builder pattern — methods return `self` for chaining:

```lua
ctx.Components.StatusBar {
    Name = "MyHealthBar",
}:setDimensions(200, 20)
 :setForegroundTint(200, 50, 50)
 :setCurrentValue(75)
 :setMaximumValue(100)
 :create(true)
```

## Class Hierarchy

```
Component                  -- Base: name, type, xml-template support
  └─ EventReceiver         -- Adds event handler registration/dispatch
       └─ View             -- Dimensions, anchors, alpha, tint, input handling
            ├─ Window      -- Top-level container (layer, movable, popable, resizable)
            ├─ Button      -- Pressable button with text and textures
            ├─ Label       -- Text display (font, color, alignment)
            ├─ StatusBar   -- Progress bar (current/max values, tints)
            ├─ CircleImage -- Circular texture
            ├─ DynamicImage-- Runtime-assigned texture with coordinates
            ├─ EditTextBox -- Text input field
            ├─ LogDisplay  -- Multi-line scrolling text area
            └─ Gump        -- Server-sent generic gump wrapper
```

## Environment

- **Lua 5.0/5.1** (exact version unconfirmed) — no `goto`, no `require()`, no `io`/`os`/`debug` libraries. Metatables are available.
- **`wstring` type** — the engine adds wide strings. Use `L"text"` literals, `towstring()`, `StringToWString()`.
- **Global namespace** — all engine functions and default UI scripts populate `_G`.
- **XML + Lua** — windows are defined via XML templates and instantiated/controlled from Lua.

## Debugging

The `.env` file in the repository root defines environment variables for development. Key variable:

- `loglocation` — Path to the UO Enhanced Client's `lua.log` file. This log captures `[Function]`, `[Error]`, `[Debug]`, and `[System]` entries from the Lua/XML interface system. **The log is written on logout/shutdown**, not in real time — you must exit the client to see the latest entries.

## External References

| Resource | URL | Description |
|---|---|---|
| Default UI Source | https://github.com/loop-uc-ui/enhanced-client-default | Authoritative Lua + XML source for every vanilla UI window. Files in `Source/`. |
| Default UI Docs | https://loop-uc-ui.github.io/enhanced-client-default-docs/ | EA Mythic's official API reference (outdated but still useful for engine functions). |
| Ultima Online | https://uo.com/ | Official game site — lore, aesthetics, community. |

## License

See repository for license details.

