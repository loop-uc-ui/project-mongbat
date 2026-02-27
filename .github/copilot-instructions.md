## Overview

Mongbat is a Lua wrapper framework for modding the default UI of the **Ultima Online Enhanced Client** (UO EC). The UO EC is a C++ game client that exposes a Lua + XML interface system allowing full customization of the player-facing UI. The exact Lua version is unconfirmed but is believed to be **Lua 5.0 or 5.1** based on available language features. Mongbat provides an extensible, object-oriented abstraction on top of this raw interface, enabling mod developers to create, replace, or extend UI windows with less boilerplate and better isolation between mods.

The framework lives in a single file -- `src/lib/Mongbat.lua` -- plus companion XML templates (`Mongbat.xml`), textures, and a `.mod` descriptor. Individual mods live under `src/mods/<mod-name>/` and each contain their own `.mod` file and entry-point Lua script.

---

## Key External Resources -- USE THESE ACTIVELY

When answering questions about Mongbat, **always cross-reference** the two primary external sources described below. They document the raw engine API and default Lua scripts that Mongbat wraps. Use the `github_repo` and `fetch_webpage` tools to retrieve live content from these sources when needed.

### Default UI Source Code (GitHub)

> **Repository**: https://github.com/loop-uc-ui/enhanced-client-default
>
> This is the **authoritative reference** for how the UO EC UI works. It is 100% Lua + XML. All files live under the `Source/` directory.

**When to consult it:**
- To understand the vanilla implementation of any window that Mongbat wraps or replaces (e.g., `StatusWindow`, `MainMenuWindow`, `ObjectHandleWindow`, `MapWindow`).
- To look up engine-provided global functions, `WindowData.*` tables, or `SystemData.*` tables that Mongbat's `Api` namespace delegates to.
- To verify event IDs, callback signatures, or data-table structures.
- To find code patterns for features Mongbat does not yet cover.

**Key files to know about** (all under `Source/` in the repo):

| File | Purpose |
|---|---|
| `Interface.lua` / `Interface.xml` | Entry point. `CreateWindows`, `InitializeWindows`, `CreateOverrides`, `RegisterEvents`, `Shutdown`, `Update` -- the lifecycle of the whole UI. |
| `StatusWindow.lua` | Player health/mana/stamina bars. Uses `WindowData.PlayerStatus`, `RegisterWindowData`, `WindowRegisterEventHandler`. |
| `MainMenuWindow.lua` | Main menu toggle buttons (paperdoll, inventory, map, etc.). |
| `ObjectHandle.lua` / `ObjectHandleWindow.lua` | Floating name/health labels above in-world objects. |
| `MapCommon.lua` / `MapWindow.lua` | Radar/minimap. |
| `GenericGump.lua` / `GGManager.lua` / `GumpsParsing.lua` | Server-sent generic gumps (dialogs). |
| `Actions.lua` | `ToggleMainMenu`, `ToggleWarMode`, `ToggleMapWindow`, etc. -- action entry points. |
| `VendorSearch.lua` | Vendor search UI. |
| `HealthBarManager.lua` / `MobileHealthBar.lua` / `PartyHealthBar.lua` | Health bar creation and management for mobiles. |
| `TargetWindow.lua` | Current-target display. |
| `HotbarSystem.lua` | Hotbar actions and stat display. |
| `UO_DefaultWindow.lua` | Reusable dialog template (OK/Cancel). |

Mongbat mods in `src/mods/` replace or extend many of these default windows. Check the actual mod files to see which default components each mod targets.

**How to use with tools:**
```
github_repo query on "loop-uc-ui/enhanced-client-default" -- e.g.:
  "StatusWindow Initialize Shutdown RegisterWindowData PlayerStatus"
```
This returns relevant code snippets with file paths and line numbers.

### Default UI Documentation (EA Mythic)

> **Docs site**: https://loop-uc-ui.github.io/enhanced-client-default-docs/
>
> The official (but **outdated**) EA Mythic documentation for the UO EC interface system. Still the best reference for **engine-level** API functions, XML attributes, and system concepts.

**Warning**: The Lua code examples in the docs may not match the current default UI source. Always cross-reference the repository above for the latest implementations.

**Key documentation pages:**

| Page | URL | Covers |
|---|---|---|
| Introduction | `files3/Introduction-txt.html` | High-level overview of the UI system. |
| Getting Started | `files3/GettingStarted-txt.html` | How local UI mods work: the `UserInterface/` folder, Multiple UI Sets, `Interface.lua`/`Interface.xml` as entry points. |
| Window Creation Basics | `files3/WindowCreationBasics-txt.html` | XML + Lua skeleton for creating windows: `<Window>` definition, `OnInitialize` handler, `CreateWindow()`. |
| Anchoring | `files3/Anchoring-txt.html` | `<Anchor>` XML, `WindowClearAnchors()`, `WindowAddAnchor()`. |
| Expandable List Box | `files3/ExpandableListBox-txt.html` | Complex list widget pattern. |
| Interface System (API) | `files/Source/MythicInterface-cpp.html` | Core functions: `CreateWindow()`, `CreateWindowFromTemplate()`, `DestroyWindow()`, `RegisterEventHandler()`, `BroadcastEvent()`, `LoadResources()`, `RegisterWindowSet()`, `StringToWString()`, `WStringToString()`, `ScaleInterface()`, `BuildTableFromCSV()`, `GetIconData()`, `LoadStringTable()`, etc. Also defines `SystemData.*` variables and events. |
| Window (API) | `files/Source/Window-cpp.html` | Base `<Window>` XML attributes (`name`, `layer`, `movable`, `popable`, `handleinput`, `id`, `inherits`, etc.). Window functions: `WindowSetShowing()`, `WindowGetShowing()`, `WindowSetDimensions()`, `WindowGetDimensions()`, `WindowSetAlpha()`, `WindowSetTintColor()`, `WindowSetOffsetFromParent()`, `WindowGetScreenPosition()`, `WindowSetScale()`, `WindowSetParent()`, `WindowRegisterEventHandler()`, `WindowRegisterCoreEventHandler()`, `WindowStartAlphaAnimation()`, `DoesWindowExist()`, `WindowSetMovable()`, `WindowResizeOnChildren()` -- and many more. Also `Window.AnimationType.*` and `Window.Layers.*` constants. |

**How to use with tools:**
```
fetch_webpage with relevant docs URL and a search query.
```

### Game Website

> **URL**: https://uo.com/
>
> Official Ultima Online site. Use for game context, lore (fantasy medieval), aesthetics, and community resources.

---

## Lua Environment Constraints

The UO EC embeds a **sandboxed Lua** runtime (believed to be **5.0 or 5.1** -- the exact version is unconfirmed). Understanding these constraints is critical when writing or reviewing Mongbat code:

- **No `require` / `module`** -- all scripts are loaded via XML `<Script>` tags or `.mod` dependency ordering. There is no `require()` function.
- **No `io`, `os`, `debug` libraries** -- the sandbox removes these entirely (unless debug is explicitly enabled via `SetLoadLuaDebugLibrary(true)`).
- **`wstring` type** -- the engine adds a wide-string type. Literal syntax: `L"text"`. Many engine functions expect or return `wstring` values. Use `StringToWString()` / `WStringToString()` and `towstring()` / `tostring()` for conversion.
- **No `goto`** -- the runtime does not have `goto` or labels (added in Lua 5.2).
- **`math.mod` not `math.fmod`** -- use `math.mod()` (the Lua 5.0 name; it may also be available as `math.fmod`).
- **Limited pattern matching** -- Lua patterns, not regex. No alternation (`|`), no `\d`, no lookahead.
- **Metatables** -- Mongbat makes heavy use of `__index`, `__newindex`, `__call`, and `__tostring` metamethods for its class system and proxy pattern.
- **Global namespace** -- all default UI scripts and engine functions populate the global table. Mongbat captures references and sometimes overrides globals (via its `DefaultComponent` system).

---

## Mongbat Framework Architecture

### Single-File Core

The entire framework is in `src/lib/Mongbat.lua`. It is structured as a series of class definitions followed by namespace assemblies, loaded as a single script.

### Class Hierarchy

```
Component                  -- Base: name, type, xml-template support
  +-- EventReceiver        -- Adds event handler registration/dispatch
       +-- View            -- Adds dimension, anchor, alpha, tint, input handling; wraps a live window-name
            |-- Window     -- Top-level container: layer, movable, popable, close button, resizable
            |-- Button     -- Pressable button with text, textures, disabled state
            |-- Gump       -- Server-sent generic gump wrapper with element builder methods
            |-- Label      -- Text display: font, color, alignment, maxWidth, scaling
            |-- StatusBar  -- Progress bar: currentValue/maximumValue, foreground/background textures
            |-- CircleImage-- Circular texture (used for portraits/radar)
            |-- DynamicImage-- Runtime-assigned texture with slice coordinates
            |-- EditTextBox-- Text input field: history, maxChars
            +-- LogDisplay -- Multi-line scrolling text area
```

Each class uses builder-pattern methods (returning `self`) so mods can chain configuration:
```lua
Components.Window {
    Name = "MyWindow",
    Title = L"My Window",
    OnInitialize = function(self) ... end,
}:setDimensions(400, 300):setLayer("secondary"):create(true)
```

### The `View` Base

`View` is the workhorse class. Every visible UI element is a `View`. Key capabilities:
- **Window-name tracking** -- `view.Name` maps to the engine's `windowName` string used in all `Window*()` API calls.
- **Anchoring** -- `view:addAnchor(point, relativeTo, relativePoint, x, y)`, `view:clearAnchors()`.
- **Dimensions** -- `view:setDimensions(w, h)`, `view:getDimensions()`.
- **Visibility** -- `view:setShowing(bool)`, `view:getShowing()`.
- **Alpha / Tint** -- `view:setAlpha(a)`, `view:setTintColor(r,g,b)`.
- **Id** -- `view:setId(n)`, `view:getId()` -- mirrors `WindowSetId`/`WindowGetId`.
- **Event handlers** -- inherited from `EventReceiver`: `view:addEventHandler(eventId, callback)`, `view:addCoreEventHandler(eventName, callback)`.
- **Children** -- `view:addChild(childView)` (engine child-window relationship).

### Components (Factory Functions)

Mods create UI elements through `Components.*` factory functions available on their context object:

| Factory | Creates | Key config fields |
|---|---|---|
| `Components.Window{...}` | `Window` | `Name`, `Title`, `OnInitialize`, `OnShutdown`, `OnUpdate`, `Movable`, `Popable`, `Layer`, `CloseButton`, `Resizable` |
| `Components.Button{...}` | `Button` | `Name`, `Text`, `OnLButtonUp`, `OnLButtonDown`, `Disabled` |
| `Components.Label{...}` | `Label` | `Name`, `Text`, `Font`, `Color`, `MaxWidth`, `TextAlignment` |
| `Components.StatusBar{...}` | `StatusBar` | `Name`, `CurrentValue`, `MaximumValue`, `ForegroundTint`, `BackgroundTint` |
| `Components.CircleImage{...}` | `CircleImage` | `Name`, `Radius` |
| `Components.DynamicImage{...}` | `DynamicImage` | `Name`, `Texture`, `TextureCoords` |
| `Components.EditTextBox{...}` | `EditTextBox` | `Name`, `MaxChars`, `OnTextChanged` |
| `Components.LogDisplay{...}` | `LogDisplay` | `Name`, `MaxLines` |
| `Components.Gump{...}` | `Gump` | `Name`, `GumpId`, gump element builder methods |

### Api Namespace

The `Api` namespace wraps raw engine globals into organized sub-tables. Mods access it via their context object (`ctx.Api`). Sub-namespaces are organized by domain (e.g., `Api.Window`, `Api.Button`, `Api.Label`, `Api.Event`, `Api.String`, `Api.DynamicImage`, etc.). Consult `Mongbat.lua` for the full current list.

For example, `Api.Window.SetShowing(name, bool)` wraps the engine's `WindowSetShowing(name, bool)`. This indirection allows Mongbat to add safety checks and maintain compatibility if engine functions change.

### Utils Namespace

Utility functions organized by type:

- **`Utils.Array`** -- functional helpers for sequential tables (e.g., `map`, `filter`, `reduce`, `find`, `contains`, `forEach`).
- **`Utils.Table`** -- dictionary/table operations (e.g., `keys`, `values`, `merge`, `deepCopy`).
- **`Utils.String`** -- string helpers (e.g., `startsWith`, `endsWith`, `trim`, `split`).

Consult `Mongbat.lua` for the full current set of utility functions.

### Constants Namespace

Enumerations and magic values, organized into sub-tables:

- **Event-related** -- `Constants.Broadcasts`, `Constants.DataEvents`, `Constants.SystemEvents`, `Constants.CoreEvents`.
- **Layout-related** -- `Constants.AnchorPoints`, `Constants.WindowLayers`.
- **UI-related** -- `Constants.ButtonStates`, `Constants.Textures`, `Constants.Colors`, `Constants.TextAlignment`, `Constants.ButtonFlags`, etc.
- **Game-related** -- `Constants.GumpIds`, `Constants.TargetType`, `Constants.DragSource`, etc.

Consult `Mongbat.lua` for the full current set of constants and their values.

### Data Wrappers

The `Data` namespace provides typed wrappers for the engine's `WindowData.*` tables (e.g., `Data.PlayerStatus`, `Data.HealthBarColor`, `Data.MobileName`, etc.). Example usage in a mod:
```lua
local hp = ctx.Data.PlayerStatus.CurrentHealth
local maxHp = ctx.Data.PlayerStatus.MaxHealth
```

These wrap the engine pattern of `RegisterWindowData(windowName, dataType)` then reading from `WindowData[dataType][windowName]`. Consult `Mongbat.lua` for the full current set of data wrappers.

### DefaultComponent System

Mongbat can **replace** default UI windows by intercepting their global Lua tables. The `DefaultComponent` proxy system:
1. Captures the original global (e.g., `StatusWindow`) before the mod loads.
2. Replaces it with a proxy table whose `Initialize`/`Shutdown` methods are no-ops or redirects.
3. Provides `disable()` and `restore()` methods to safely toggle the replacement.
4. The mod's own `Window` component takes over the visual role.

Default components correspond to the vanilla window globals (e.g., `StatusWindow`, `MainMenuWindow`, `MapWindow`, `ObjectHandleWindow`, `GenericGump`, etc.). Consult `Mongbat.lua` for the full current set.

### Mod Lifecycle

1. **`.mod` XML file** declares the mod name, Lua script, and dependencies (always depends on `Mongbat`).
2. The Lua script calls `Mongbat.Mod({ ... })` to register the mod.
3. Mongbat provides a **context object** (`ctx`) to each mod with: `Api`, `Data`, `Utils`, `Constants`, `Components`, and mod-specific fields.
4. Lifecycle callbacks: `OnInitialize(ctx)`, `OnShutdown(ctx)`, `OnUpdate(ctx, deltaTime)`.
5. During `OnInitialize`, the mod creates windows/views, registers event handlers, and optionally disables default UI components.
6. During `OnShutdown`, views are destroyed and default components restored.

Example mod skeleton:
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

### Event System

Mongbat provides three event tiers, mirroring the engine:

1. **DataEvents** -- tied to `WindowData` changes. Registered via `WindowRegisterEventHandler(windowName, eventId, callback)`. See `Constants.DataEvents` for the current list. Used for player stats, health bar colors, mobile names/statuses, object handles.
2. **SystemEvents** -- engine system events like `UPDATE_PROCESSED`, button-processed events. Registered via `RegisterEventHandler(eventId, callback)` (no window context) or `WindowRegisterEventHandler(windowName, eventId, callback)`.
3. **CoreEvents** -- string-named per-window events: `"OnInitialize"`, `"OnShutdown"`, `"OnMouseOver"`, `"OnLButtonDown"`, `"OnRButtonDown"`, `"OnLButtonUp"`, `"OnRButtonUp"`, `"OnUpdate"`, `"OnMouseOverEnd"`, etc. Registered via `WindowRegisterCoreEventHandler(windowName, eventName, callback)`.

Mongbat wraps all three through its `EventReceiver` class and provides dispatcher functions (`withActiveView`, `withMouseOverView`) that look up the `View` instance from the engine's `SystemData.ActiveWindow.name` / `SystemData.MouseOverWindow.name` before invoking callbacks.

### XML Templates

`Mongbat.xml` defines base XML templates for each component type (e.g., `MongbatWindow`, `MongbatButton`, `MongbatLabel`, etc.). These use the engine's `inherits` attribute and `$parent` name substitution.

When `Components.Window{...}:create()` is called, it internally calls `CreateWindowFromTemplate(name, "MongbatWindow", parent)` -- the engine function documented in the docs.

---

## Engine API Quick Reference

These are the **raw engine globals** that Mongbat wraps. When debugging or extending the framework, you may need to reference them directly. Full documentation is in the docs site linked above.

### Window Creation & Destruction
- `CreateWindow(windowName, show)` -- creates from XML definition
- `CreateWindowFromTemplate(windowName, templateName, parent)` -- creates a named instance from template
- `CreateWindowFromTemplateShow(windowName, templateName, parent, show)` -- same but controls visibility
- `DestroyWindow(windowName)` -- destroys window and all children

### Window Properties
- `WindowSetShowing(name, bool)` / `WindowGetShowing(name)`
- `WindowSetDimensions(name, w, h)` / `WindowGetDimensions(name)`
- `WindowSetAlpha(name, a)` / `WindowGetAlpha(name)`
- `WindowSetTintColor(name, r, g, b)` / `WindowGetTintColor(name)`
- `WindowSetFontAlpha(name, a)` / `WindowGetFontAlpha(name)`
- `WindowSetScale(name, s)` / `WindowGetScale(name)`
- `WindowSetMovable(name, bool)` / `WindowGetMovable(name)`
- `WindowSetPopable(name, bool)` / `WindowGetPopable(name)`
- `WindowSetHandleInput(name, bool)` / `WindowGetHandleInput(name)`
- `WindowSetLayer(name, layer)` / `WindowGetLayer(name)`
- `WindowSetId(name, id)` / `WindowGetId(name)`
- `WindowSetParent(name, parentName)` / `WindowGetParent(name)`
- `WindowSetOffsetFromParent(name, x, y)` / `WindowGetOffsetFromParent(name)`
- `WindowGetScreenPosition(name)`
- `DoesWindowExist(name)`

### Anchoring
- `WindowClearAnchors(name)`
- `WindowAddAnchor(name, point, relativeTo, relativePoint, xOff, yOff)`
- `WindowGetAnchorCount(name)` / `WindowGetAnchor(name, anchorId)`
- `WindowForceProcessAnchors(name)`

### Events
- `WindowRegisterEventHandler(windowName, eventId, callbackString)` -- per-window event
- `WindowUnregisterEventHandler(windowName, eventId)` -- remove per-window event
- `WindowRegisterCoreEventHandler(windowName, eventName, callbackString)` -- per-window core event
- `WindowUnregisterCoreEventHandler(windowName, eventName)` -- remove core event
- `RegisterEventHandler(eventId, callbackString)` -- generic (no window context)
- `UnregisterEventHandler(eventId, callbackString)` -- remove generic
- `BroadcastEvent(eventId)` -- trigger an event

### Animations
- `WindowStartAlphaAnimation(name, animType, startA, endA, duration, setStartBeforeDelay, delay, numLoop)`
- `WindowStopAlphaAnimation(name)`
- `WindowStartPositionAnimation(name, animType, startX, startY, endX, endY, duration, setStartBeforeDelay, delay, numLoop)`
- `WindowStopPositionAnimation(name)`
- `WindowStartScaleAnimation(name, animType, startS, endS, duration, setStartBeforeDelay, delay, numLoop)`
- `WindowStopScaleAnimation(name)`

### Data & Strings
- `RegisterWindowData(windowName, dataType)` / `UnregisterWindowData(windowName, dataType)`
- `StringToWString(s)` / `WStringToString(ws)`
- `LoadStringTable(name, dir, file, cacheDir, enumRoot)` / `GetStringFromTable(name, id)`
- `GetScreenResolution()` -- returns xRes, yRes
- `BuildTableFromCSV(path, tableName)`

### System Variables (populated by engine)
- `SystemData.ActiveWindow.name` -- window name for current callback
- `SystemData.MouseOverWindow.name` -- window under cursor
- `SystemData.MousePosition.x` / `.y`
- `SystemData.Events.*` -- event ID enum table
- `SystemData.ButtonFlags.SHIFT` / `.CONTROL` / `.ALT`
- `SystemData.UpdateProcessed.Time` -- delta time for update events
- `WindowData.*` -- data tables populated after `RegisterWindowData`

---

## Guidelines for Responses

### 1. Consult the Default UI Source (Primary Reference)

**This is the most important guideline.** When answering questions about how something works in the UO EC UI -- whether the user is asking about Mongbat or raw modding -- **search the default UI repository first** using `github_repo` on `loop-uc-ui/enhanced-client-default`. The repo contains the real, working code for every window in the game.

- If the user asks "how does the health bar work?", search for `StatusWindow` in the repo and show the actual patterns used.
- If the user asks about a Mongbat mod, compare the mod's code to its default UI counterpart for context.
- If the user needs to use an engine function not yet wrapped by Mongbat's `Api`, find its usage in the default UI source.

### 2. Consult the Documentation (Secondary Reference)

Use `fetch_webpage` on the docs site pages listed above to get:
- **Function signatures** and parameter types for engine API functions.
- **XML attribute definitions** for window elements.
- **Conceptual explanations** (anchoring, window creation lifecycle, events).

Always note that the docs are outdated relative to the repo. If a doc example contradicts the repo code, the repo is correct.

### 3. Function Usage and API Guidance

- **Reference both layers**: When explaining a Mongbat function (e.g., `view:setDimensions(w, h)`), explain what engine call it wraps (`WindowSetDimensions(name, w, h)`), and link to both the Mongbat source in `Mongbat.lua` and the relevant docs page.
- **Provide compatible Lua code**: All snippets must be compatible with the engine's Lua runtime (5.0/5.1). Use `L"..."` for wide strings. No `goto`, no `require()`.
- **Use `wstring` correctly**: UI text is almost always `wstring`. Use `L"literal"` in code, `towstring(number)` for conversion, `StringToWString(str)` for runtime conversion.
- **Builder pattern**: Show the fluent chaining style: `Components.Window{...}:setDimensions(w,h):create(true)`.

### 4. Default UI Patterns to Know

The default UI follows consistent patterns that Mongbat wraps. When explaining these, reference the actual source:

**Window lifecycle (vanilla):**
```lua
-- In SomeWindow.lua:
SomeWindow = {}  -- global table

function SomeWindow.Initialize()
    -- register data, register events, set up children
    RegisterWindowData(SomeWindow.Name, WindowData.SomeType.Type)
    WindowRegisterEventHandler(SomeWindow.Name, WindowData.SomeType.Event, "SomeWindow.OnUpdate")
end

function SomeWindow.Shutdown()
    UnregisterWindowData(SomeWindow.Name, WindowData.SomeType.Type)
end

function SomeWindow.OnUpdate()
    local data = WindowData.SomeType[SomeWindow.Name]
    -- update UI from data
end
```

**Mongbat equivalent:**
```lua
Mongbat.Mod {
    Name = "MongbatSomeMod",
    DefaultComponents = { "SomeWindow" },
    OnInitialize = function(ctx)
        local window = ctx.Components.Window {
            Name = "MongbatSomeWindow",
            OnInitialize = function(self)
                -- register via ctx.Api and ctx.Data wrappers
            end,
        }:create(true)
    end,
}
```

### 5. Game Theme and Aesthetics

- Ultima Online has a **fantasy medieval** theme -- knights, magic, dragons, guilds.
- UI should use **ornate borders**, classic fonts, earthy/gold color palettes.
- Designs should prioritize **readability** and **immersion** -- avoid jarring modern UI patterns.
- Reference https://uo.com/ for visual inspiration.

### 6. General Rules

- **Lua 5.0/5.1 only** -- no `goto`, no modern libraries, no `require`.
- **All engine globals are uppercase-prefixed** functions (e.g., `WindowSetShowing`, `CreateWindow`, `RegisterEventHandler`).
- **Mongbat wraps them** in PascalCase under `Api.*` sub-namespaces.
- **Always validate assumptions** against the default UI repo or docs when unsure.
- **Back up UI files** before testing -- bad Lua can crash the client's UI layer.
- If information is unavailable, suggest checking the repositories or UO modding communities.
