## Overview

Mongbat is a Lua wrapper framework for modding the default UI of the **Ultima Online Enhanced Client** (UO EC). The UO EC is a C++ game client that exposes a Lua + XML interface system allowing full customization of the player-facing UI. The exact Lua version is unconfirmed but is believed to be **Lua 5.0 or 5.1** based on available language features. Mongbat provides an extensible, object-oriented abstraction on top of this raw interface, enabling mod developers to create, replace, or extend UI windows with less boilerplate and better isolation between mods.

The framework lives in a single file -- `src/lib/Mongbat.lua` -- plus companion XML templates (`Mongbat.xml`), textures, and a `.mod` descriptor. Individual mods live under `src/mods/<mod-name>/` and each contain their own `.mod` file and entry-point Lua script.

---

## Key External Resources -- USE THESE ACTIVELY

When answering questions about Mongbat, **always cross-reference** the two primary external sources described below. They document the raw engine API and default Lua scripts that Mongbat wraps. Use the `github_repo` and `fetch_webpage` tools to retrieve live content from these sources when needed.

### Default UI Source Code (GitHub)

> **Repository**: https://github.com/loop-uc-ui/enhanced-client-default
>
> This is the **authoritative reference** for how the UO EC UI works. It is 100% Lua + XML.

**When to consult it:**
- To understand the vanilla implementation of any window that Mongbat wraps or replaces.
- To look up engine-provided global functions, `WindowData.*` tables, or `SystemData.*` tables that Mongbat's `Api` namespace delegates to.
- To verify event IDs, callback signatures, or data-table structures.
- To find code patterns for features Mongbat does not yet cover.
- **To compare both the Lua AND the XML** for any component being replicated in a Mongbat mod.

**How to use with tools:**
```
github_repo query on "loop-uc-ui/enhanced-client-default" -- e.g.:
  "StatusWindow Initialize Shutdown RegisterWindowData PlayerStatus"
```
This returns relevant code snippets with file paths and line numbers. Search for both `<WindowName>.lua` and `<WindowName>.xml` files.

### Default UI Documentation (EA Mythic)

> **Docs site**: https://loop-uc-ui.github.io/enhanced-client-default-docs/
>
> The official (but **outdated**) EA Mythic documentation for the UO EC interface system. Still the best reference for **engine-level** API function signatures, XML attributes, and system concepts.

**Warning**: The Lua code examples in the docs may not match the current default UI source. Always cross-reference the repository above for the latest implementations.

**Key documentation pages:**

| Page | URL | Covers |
|---|---|---|
| Introduction | `files3/Introduction-txt.html` | High-level overview of the UI system. |
| Getting Started | `files3/GettingStarted-txt.html` | How local UI mods work: the `UserInterface/` folder, multiple UI sets. |
| Window Creation Basics | `files3/WindowCreationBasics-txt.html` | XML + Lua skeleton for creating windows. |
| Anchoring | `files3/Anchoring-txt.html` | `<Anchor>` XML, anchor API functions. |
| Interface System (API) | `files/Source/MythicInterface-cpp.html` | Core engine functions: `CreateWindow`, `CreateWindowFromTemplate`, `RegisterEventHandler`, `BroadcastEvent`, `RegisterWindowData`, `StringToWString`, etc. Also `SystemData.*` variables and events. |
| Window (API) | `files/Source/Window-cpp.html` | Per-window functions: `WindowSetShowing`, `WindowSetDimensions`, `WindowSetId`, `WindowRegisterEventHandler`, `WindowRegisterCoreEventHandler`, etc. Also `Window.AnimationType.*` and `Window.Layers.*`. |

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

The UO EC embeds a **sandboxed Lua** runtime (believed to be **5.0 or 5.1**). Understanding these constraints is critical:

- **No `require` / `module`** -- all scripts are loaded via XML `<Script>` tags or `.mod` dependency ordering.
- **No `io`, `os`, `debug` libraries** -- the sandbox removes these entirely.
- **`wstring` type** -- the engine adds a wide-string type. Literal syntax: `L"text"`. Many engine functions expect/return `wstring`. Use `StringToWString()` / `WStringToString()` and `towstring()` / `tostring()` for conversion.
- **No `goto`** -- not available in the runtime.
- **`math.mod` not `math.fmod`** -- use `math.mod()` (the Lua 5.0 name).
- **Limited pattern matching** -- Lua patterns, not regex. No alternation (`|`), no `\d`, no lookahead.
- **Metatables** -- Mongbat makes heavy use of `__index`, `__newindex`, `__call`, and `__tostring` metamethods for its class system.
- **`local function` ordering** -- A `local function` must be **defined before** its first call site in the file. Lua resolves `local` bindings at parse time; calling a local function before its definition results in a "nil value" error at runtime. When adding new local functions to `Mongbat.lua`, always verify the definition appears above all call sites.
- **Global namespace** -- all default UI scripts and engine functions populate the global table. Mongbat captures references and modifies originals in-place (via its `DefaultComponent` system).

---

## Framework Architecture

This section describes **stable architectural decisions** -- the mental models needed to reason about any mod or framework change. The codebase evolves; for current method signatures, field names, and API surface, always read `Mongbat.lua` directly.

### Single-File Core

The entire framework is in `src/lib/Mongbat.lua`. It contains class definitions, namespace assemblies, and the event dispatch system. To find anything in the framework:
- **Class definitions** -- search for the class constructor pattern or `local <ClassName>`
- **Namespace contents** (`Api`, `Utils`, `Constants`, `Data`) -- search for the namespace name
- **Event registration logic** -- search for `onInitialize` or `registerEventHandler`
- **Cache and dispatchers** -- search for `Cache` or `withActiveView`

### The Component Model

Mongbat uses a **model table → class instance → engine window** pattern:

1. The mod passes a **model table** (plain Lua table) to a factory function (e.g., `Components.Window { Name = "...", ... }`).
2. The factory creates a class instance that wraps the model and provides builder methods.
3. Calling `:create(show)` calls `CreateWindowFromTemplate` to instantiate the engine window.

**Builder pattern**: All setter methods return `self` for chaining.

**Event handlers as model keys**: If the model table contains a key matching a known event name (e.g., `OnUpdatePlayerStatus`, `OnLButtonDown`, `OnMouseOver`), Mongbat automatically registers the appropriate engine event handler during initialization. You do NOT call raw engine registration functions in mod code.

The class hierarchy is:
```
Component → EventReceiver → View → [Window, Button, Label, StatusBar, DynamicImage, ...]
```

Each level adds capabilities. `View` is the workhorse -- every visible UI element is a `View`. Consult `Mongbat.lua` for the full current set of component types, their model keys, and their methods.

### Names and IDs

Every View has a **name** (`string`) and an **id** (`number`). These serve different purposes:

- **Name** -- The engine's unique identifier for the window. Used in all `Window*()` API calls and for event registration. Names **must** be globally unique. If not provided in the model, Mongbat generates a random string.
- **Id** -- A numeric tag set via `WindowSetId`. IDs are **not** required to be unique. They bind entity-specific data. For example, to receive `OnUpdateMobileName` for a particular mobile, set the view's ID to that mobile's ID.

When `View:setId(id)` is called, Mongbat automatically calls `RegisterWindowData(dataType, id)` for each DataEvent in the model. This is the mechanism for entity-specific data binding.

### Child-Centric Event Dispatch

**This is the single most important architectural concept in Mongbat.**

The default UI registers events on **parent windows** (e.g., `StatusWindow` registers all events and dispatches to its children manually). Mongbat inverts this: **each child component registers its own events under its own unique window name and receives them directly.** The parent Window is a container/layout manager, not an event hub.

This means:
- DataEvent handlers (e.g., `OnUpdatePlayerStatus`) belong on the **child** that displays the data, not on the parent Window.
- Entity-specific data binding is done by calling `setId(entityId)` on the **child** that needs the data.
- The parent Window does NOT intercept or re-dispatch DataEvents to its children.

**The dispatch chain:**
1. Engine sets `SystemData.ActiveWindow.name` to the window name from `WindowRegisterEventHandler`.
2. Engine calls the callback string (e.g., `Mongbat.EventHandler.OnUpdatePlayerStatus()`).
3. The dispatcher looks up `Cache[SystemData.ActiveWindow.name]` to find the View instance.
4. If found, calls the View's handler, which invokes the model's callback.

If the Cache lookup fails, the event is silently dropped. All factory-created components are automatically added to Cache.

**Data registration vs event registration -- two separate engine concepts:**

| Concept | Engine Function | What it does |
|---|---|---|
| Data registration | `RegisterWindowData(dataType, id)` | Populates a `WindowData.*` table. Takes a data type + numeric ID. Does NOT take a window name. |
| Event registration | `WindowRegisterEventHandler(windowName, eventId, callback)` | Routes the event callback. The window name determines `SystemData.ActiveWindow.name` during the callback. |

Some data types (PlayerStatus, Radar, PlayerLocation) are registered **once at framework level** with `id = 0`. Others (MobileName, HealthBarColor, MobileStatus) are registered per-view using the view's numeric ID.

**Event propagation:** Some CoreEvents (mouse clicks, mouse-over) propagate from children to their parent Window. DataEvents and most SystemEvents do NOT propagate -- they dispatch only to the specific view that registered them. Consult `Mongbat.lua` (search for the Window component's child-wrapping logic) for the current propagation list.

### Event Dispatch Taxonomy

Mongbat uses **three distinct dispatch mechanisms**. Knowing which mechanism an event uses is critical for debugging:

| Mechanism | How it works | Examples |
|---|---|---|
| **CoreEvents** | Registered per-window via `WindowRegisterCoreEventHandler`. The engine fires the callback only on the specific window that registered it. Requires the window name. | `OnUpdate`, `OnMouseWheel`, `OnMouseOver`, `OnMouseOverEnd`, `OnShown`, `OnHidden`, `OnRButtonDown`, `OnRButtonUp`, `OnLButtonDown`, `OnLButtonUp`, `OnLButtonDblClk` |
| **SystemEvents** | Registered globally via `RegisterEventHandler`. The engine broadcasts to all listeners. The framework uses `SystemData.MouseOverWindow.name` to find the target view. | Not currently used by the framework for click events. Constants like `L_BUTTON_DOWN_PROCESSED` / `L_BUTTON_UP_PROCESSED` exist for mods that need global listeners. |
| **Synthesized** | Not engine-dispatched. The framework polls state each frame and invokes the handler directly. | `OnMouseDrag` (synthesized via `UPDATE_PROCESSED` tick + `SystemData.MousePosition` polling) |

**Why this matters:**
- `OnLButtonDown` and `OnLButtonUp` are registered as **CoreEvents** on every view. The engine fires them on the specific window the mouse is over. If a child has no click handler, the event bubbles to its parent Window via `_parentWindow`.
- Registering `OnLButtonDown` as a CoreEvent **suppresses** the engine's built-in `movable="true"` auto-movement. The framework compensates by calling `WindowSetMoving(name, true)` in `Window:onLButtonDown` and `WindowSetMoving(name, false)` in `Window:onLButtonUp`, mirroring the default UI pattern (e.g., `StatusWindow.OnLButtonDown` / `StatusWindow.OnLButtonUp`).
- If framework-level logic needs to run **every frame regardless of which views exist**, it must use `UPDATE_PROCESSED` (system event), not `OnUpdate` (CoreEvent). CoreEvents only fire on windows that explicitly registered them.
- `Constants.CoreEvents`, `Constants.SystemEvents`, and `Constants.DataEvents` control what `View:onInitialize` registers. An event must appear in **exactly one** of these tables (or none, if synthesized). Placing an event in the wrong table causes silent registration of a callback string that doesn't exist, or registration of a callback that the engine will never invoke.

### The Two-Layer Model: XML and Lua

The engine has a strict split between **creation-time** (XML) and **runtime** (Lua):

- **XML templates** define element types, structure, and certain attributes that have **no Lua setter**.
- **Lua** controls runtime behavior: dimensions, visibility, alpha, tint, event handlers, etc.

When a component misbehaves despite correct Lua code, the problem is almost always a **missing XML attribute**. The engine's C++ layer reads some attributes only at template-instantiation time. To discover which attributes exist for a given element type, **fetch the default UI's XML definition** for the equivalent component from the GitHub repo and compare attributes.

Mongbat centralizes XML templates in `Mongbat.xml` (minimal templates that rely on Lua for configuration). When a mod needs an XML attribute not in the standard template, it must define a **custom template** in its own `.xml` file and set the `Template` key in the component model.

**The `MongbatWindow` template is a `<MaskWindow>`**, which clips children to its bounds.

### DefaultComponent Replacement

Mongbat can **replace** default UI windows by modifying their global Lua tables in-place:
1. A `DefaultComponent` wraps the original global table (e.g., `StatusWindow`) by reference.
2. `disable()` saves all functions on the original table and replaces them with no-ops, neutralizing the default window's behavior.
3. `restore()` puts the saved functions back and wipes any overrides the mod wrote.
4. The mod creates its own Window that takes over the visual role.

There is no proxy or global replacement -- `disable()` and `restore()` mutate the original table directly. The engine continues to call through the same table object.

Mods access default components via `Components.Defaults.<name>`. See existing mods for the pattern: disable the original in `OnInitialize`, restore it in `OnShutdown`.

### Mod Lifecycle

1. `.mod` XML declares the mod, its script, and dependency on `Mongbat`.
2. The Lua script destructures framework namespaces from the `Mongbat` global at file scope: `local Api = Mongbat.Api`, `local Components = Mongbat.Components`, etc.
3. The script calls `Mongbat.Mod { Name = "...", OnInitialize = ..., OnShutdown = ..., ... }`.
4. `OnInitialize()` -- create windows, register handlers, disable defaults.
5. `OnShutdown()` -- destroy windows, restore defaults.
6. `OnUpdate(deltaTime)` -- per-frame logic (optional).

---

## How to Navigate the Codebase

### Finding What a Mongbat Method Does

Read `Mongbat.lua`. Search for the method name. Most methods are thin wrappers around engine globals -- the method body will show you exactly which engine function it calls and what transformations it applies.

### Finding What a Default Window Does

Use `github_repo` on `loop-uc-ui/enhanced-client-default`. **Always search for both the Lua AND XML files** for any window you're investigating. The XML defines structure and creation-time attributes; the Lua defines behavior. Missing either half leads to incomplete understanding.

### Finding Engine API Signatures

Use `fetch_webpage` on the docs site. The Interface System page (`files/Source/MythicInterface-cpp.html`) covers core engine functions. The Window page (`files/Source/Window-cpp.html`) covers per-window functions.

### Finding Available Events, Constants, Data Wrappers

These are all defined in `Mongbat.lua` in their respective namespace sections. Search for `Constants.DataEvents`, `Constants.SystemEvents`, `Constants.CoreEvents`, or the namespace you need. The actual event IDs map to `SystemData.Events.*` engine globals.

### Understanding How a Mod Works

Read the mod's Lua file. Then compare it to the default UI window it replaces (search the default UI repo for both Lua and XML). The mod's `OnInitialize` creates a Mongbat Window with children; the default UI's `Initialize` function does the equivalent with raw engine calls. Map between the two to understand the translation.

---

## Skills

Detailed procedural skills live in `.github/skills/`. **Read the relevant skill file before starting the task.**

| Skill | File | When to use |
|---|---|---|
| Reimplementing a Default UI Window | `.github/skills/reimplementing-default-ui.md` | Replacing any default UI window with a Mongbat mod. Covers research, suppression, data binding, interactions, and shutdown symmetry. |
| Code Review | `.github/skills/code-review.md` | Reviewing a Mongbat mod PR. Checklist covering engine global violations, event system usage, DefaultComponent suppression, shutdown symmetry, variable scoping, wstring, framework absorption, component model, Lua compatibility, type annotations, acceptance criteria, and code quality. |
| Bugfixing | `.github/skills/bugfixing.md` | Diagnosing and fixing ANY bug in the framework or mods. **Mandatory procedure** — read this BEFORE making any code changes when debugging. Covers error reading, code tracing, root cause identification, fix planning, anti-pattern avoidance, and escalation rules. |

---

## Guidelines for Responses

### 0. Consult the Project README

**Before writing or debugging any Mongbat mod code, read the README.md in the repository root.** It contains the project overview, class hierarchy, and namespace documentation.

### 0.1 Read the Engine Log When Debugging

The `.env` file in the repo root contains `loglocation`, which points to the UO EC's `lua.log`. **When the user reports a bug or something isn't working, read this log file first** to check for errors before making code changes.

The log contains `[Error]`, `[Function]`, `[Debug]`, and `[System]` entries. **`[Error]` entries are the most useful.** The log is flushed on client logout/shutdown, not in real time.

Common error patterns:
- `Unable to load '<path>.xml'` -- XML file path wrong or file doesn't exist.
- `Unable to create window: <name>, from template <template>` -- XML template wasn't loaded.
- `Window <name> does not exist` -- Cascade from failed window creation.
- `Script Call failed - No Lua State` -- Benign; occurs during shutdown.

### 1. Consult the Default UI Source

**Search the default UI repository first** using `github_repo` on `loop-uc-ui/enhanced-client-default`. The repo contains real, working code for every window in the game.

- Comparing a mod to its default UI counterpart is the fastest way to find bugs.
- Engine functions not yet wrapped by Mongbat's `Api` can be found in the default UI source.
- **Always fetch both Lua AND XML** for any window being investigated.

### 2. Consult the Documentation

Use `fetch_webpage` on the docs site pages (listed in External Resources above) for:
- Engine API function signatures and parameter types.
- XML attribute definitions for window elements.
- Conceptual explanations (anchoring, window lifecycle).

The docs are outdated. If a doc example contradicts the repo code, the repo is correct.

### 3. Code Compatibility

- **Lua 5.0/5.1 only** -- no `goto`, no `require`, no modern libraries.
- **Use `wstring` correctly** -- UI text is almost always `wstring`. Use `L"literal"`, `towstring(number)`, `StringToWString(str)`.
- **Builder pattern** -- show fluent chaining: `Components.Window{...}:setDimensions(w,h):create(true)`.
- **Use Mongbat's event system** -- place event handler keys in model tables. Do not call raw engine registration functions in mods.

#### 3.1 All Engine References Go Through Mongbat Namespaces

Mod code must **never** call raw engine globals directly. Every reference to a global that originates from the Default UI or the engine runtime must be accessed through one of the Mongbat namespaces (`Api`, `Data`, `Utils`, `Constants`, `Components`), destructured from `Mongbat` at the top of the mod file. If the framework lacks a wrapper for a needed engine concept, **add it to `Mongbat.lua` first**, then use the wrapper in the mod.

The table below describes what belongs in each namespace. There is some nuance at the boundaries, but these rules hold for the vast majority of cases:

| Namespace | What belongs here | Engine-side examples |
|---|---|---|
| **`Data`** | All **data reads** -- any reference to `SystemData.*`, `WindowData.*`, or other engine data tables. If the mod needs to read a value the engine populates, it goes through `Data`. | `SystemData.Settings.*`, `WindowData.PlayerStatus.*`, `SystemData.ActiveWindow.name`, `WindowData.ContainerWindow.*`, `SystemData.Hotbar.*` |
| **`Api`** | Most **global functions** -- engine functions that perform actions, set state, or query the engine. Any function the engine exposes as a global callable. | `WindowSetShowing`, `DestroyWindow`, `CreateWindowFromTemplate`, `DynamicImageSetTexture`, `RegisterWindowData`, `StringToWString`, `GetStringFromTid`, `HandleSingleLeftClkTarget`, `UserActionUseItem`, `RequestContextMenu`, `BroadcastEvent` |
| **`Constants`** | **Enumerations and static values** -- numeric IDs, event IDs, type codes, flag values. Anything that is a fixed constant, not a function or mutable data. | `SystemData.Events.*`, `SystemData.DragSource.SOURCETYPE_*`, `Window.Layers.*`, `Window.AnimationType.*`, TID constants |
| **`Components`** | **UI element factories** and **DefaultComponents**. All windows and their associated global Lua tables (e.g., `StatusWindow`, `PetWindow`, `Shopkeeper`, `HotbarSystem`) are wrapped as DefaultComponents. | `StatusWindow`, `PetWindow`, `ContainerWindow`, `HotbarSystem`, `Shopkeeper`, `TradeWindow`, `ChatWindow` |
| **`Utils`** | **Utility operations on primitives and tables** -- iteration, formatting, string manipulation, math helpers, table copying, etc. If the operation is a general-purpose transformation with no engine-specific semantics, it belongs in `Utils`. | Table iteration helpers, string formatting, number formatting, table merging/copying |

**Key principles:**
- **`Data` owns all data.** If you're reading `SystemData.*` or `WindowData.*`, it must go through `Data`. No exceptions.
- **`Components.Defaults` owns all default windows.** Every default UI window's global table (`StatusWindow`, `Shopkeeper`, etc.) is a DefaultComponent. Mods access them via `Components.Defaults.<name>` and use `disable()` / `restore()`.
- **`Api` owns all actions.** If you're calling a global function to make something happen (create, destroy, set, register, broadcast), it goes through `Api`.
- **`Utils` owns generic operations.** Iterating a table, formatting a string for display, clamping a number -- these go through `Utils`. If the operation has no broader relevance beyond one mod's internal logic (e.g., a private helper that computes a mod-specific layout), it can remain local to the mod.
- **`Constants` owns fixed values.** Event IDs, type enums, layer constants -- anything that is a static lookup value rather than a function or mutable state. This includes **data dictionaries** -- static lookup tables that multiple mods may reference (e.g., spell school definitions, skill info arrays, bug type enumerations). If a dataset is hardcoded, immutable, and useful across mods, it belongs in `Constants` as a structured table rather than being duplicated in each mod.

**Bad** -- raw engine globals in mod code:
```lua
if DoesWindowNameExist(name) then DestroyWindow(name) end
local data = WindowData.Paperdoll[playerId]
DragSlotSetObjectMouseClickData(slot.slotId, SystemData.DragSource.SOURCETYPE_PAPERDOLL)
ItemProperties.SetActiveItem(itemData)
local formatted = string.format("%d / %d", current, max)
for i, v in pairs(WindowData.SkillDynamicData) do ... end
for i = 1, #someArray do doSomething(someArray[i]) end
local name = GetStringFromTid(1079170)
```

**Good** -- everything through Mongbat namespaces:
```lua
if Api.Window.DoesExist(name) then Api.Window.Destroy(name) end
local paperdoll = Data.Paperdoll(playerId)
local slot = paperdoll:getSlot(slotIndex)
Api.Drag.SetObjectMouseClickData(slot.slotId, Constants.DragSource.Paperdoll())
Api.ItemProperties.SetActiveItem(itemData)
local formatted = towstring(current) .. L" / " .. towstring(max)
Utils.Table.ForEach(Data.SkillDynamicData(), function(i, v) ... end)
Utils.Table.ForEach(someArray, function(i, value) doSomething(value) end)
local name = Api.String.GetStringFromTid(1079170)
```

**Note on iteration:** Mod code should **never** use raw `for i = 1, #tbl`, `for k, v in pairs(tbl)`, or `for i, v in ipairs(tbl)` loops. Always use `Utils.Table.ForEach(tbl, function(k, v) ... end)`. This ensures nil-safety (the function is a no-op if the table is nil) and keeps iteration patterns consistent across all mods.

#### 3.2 Variable Scoping

**Store file-scope mutable variables sparingly.** File-scope mutable state creates hidden coupling and makes lifecycle management error-prone. Follow these rules:

1. **Declare variables as locally as possible.** Runtime state (view references, entity IDs, flags) should be `local` inside `OnInitialize`. Closures in model tables and nested functions capture them naturally.
2. **Prefer passing values through function parameters** over sharing upvalues between distant functions.
3. **File-scope constants are fine.** Immutable values like `local NAME = "MyMod"` or `local MAX_SLOTS = 10` defined above the mod registration are acceptable -- they never change and have no lifecycle concerns.
4. **File-scope mutable state is a last resort.** Only use it when a value truly must survive across both `OnInitialize` and `OnShutdown` and cannot be plumbed through function parameters.

**Bad** -- file-scope mutable state that only `OnInitialize` uses:
```lua
local playerId = 0
local slotViews = {}

local function OnInitialize()
    playerId = Data.PlayerStatus():getId()
    -- slotViews used in closures below...
end

local function OnShutdown()
    slotViews = {}
    playerId = 0
end
```

**Good** -- state scoped inside `OnInitialize`, passed where needed:
```lua
local NAME = "MyModWindow"  -- file-scope constant is fine

local function OnInitialize()
    local playerId = Data.PlayerStatus():getId()
    local slotViews = {}
    -- closures capture these locals; OnShutdown doesn't need them
end

local function OnShutdown()
    Api.Window.Destroy(NAME)
end
```

#### 3.3 Framework Absorption of Repetitive Logic

When a pattern appears at multiple call sites in mod code, **fold it into the framework** rather than duplicating it across mods. The framework should handle boilerplate so mods stay concise and declarative.

**Push guard clauses into framework functions.** If mod code repeatedly null-checks before calling an `Api` function, the null check belongs inside the `Api` function itself. Mods should not need to defensively validate state that the framework can validate once.

**Bad** -- guard logic repeated at every call site:
```lua
if Api.Window.DoesExist(name) then Api.Window.Destroy(name) end
```

**Good** -- `Api.Window.Destroy` handles the existence check internally:
```lua
Api.Window.Destroy(name)  -- no-op if window doesn't exist
```

**Add convenience functions when patterns repeat.** If multiple mods toggle a window's visibility, add a `toggle` method to the relevant domain rather than inlining the if/else at each call site. The framework function encapsulates existence checks, visibility queries, and state transitions in one place.

**Do not duplicate checks the framework already performs.** If a framework method internally validates its arguments, performs type coercion, or handles nil gracefully, do not add the same check at the call site. Read the framework method's implementation to know what it already handles.

#### 3.3.1 Extending Components

When a mod needs a UI concept that the framework does not yet provide, **add it as a Component** rather than building it ad-hoc in the mod. If the default UI uses a concept (e.g., checkboxes, sliders, text input fields), it is likely needed across multiple mods and belongs in the framework.

**Composite components are encouraged.** Many UI concepts are naturally a pairing of simpler elements. For example, a checkbox is rarely useful without an adjacent label — so the framework's Checkbox component should include a built-in label, similar to how `StatusBar` bundles a bar graphic with its own text overlay. Design components to represent the *usage pattern*, not just the raw engine element.

**When to add a new Component:**
- The default UI uses the concept and multiple mods will need it.
- The mod is building the concept manually from lower-level primitives (Labels + Buttons + click handlers to simulate a checkbox).
- The composite reduces boilerplate: mods should express *intent* (`Components.Checkbox { Label = L"Show Tips", ... }`) not *mechanism*.

**When NOT to add a new Component:**
- The concept is truly unique to one mod with no foreseeable reuse.
- The concept is so simple that a single existing component covers it (a Label with a click handler is not a "ClickableLabel" component).

#### 3.3.2 Extending Utils

When a mod needs a general-purpose operation on primitives or data structures, **add it to `Utils`** if it will be broadly useful across mods. The framework should provide utilities that keep mod code focused on UI logic, not data plumbing.

**Add utilities for primitives the framework doesn't yet cover.** If several mods need to clamp numbers, round values, or do string splitting, those belong in `Utils.Math` or `Utils.String` rather than being reimplemented locally in each mod.

**Conform to tables and arrays.** The framework consolidates Lua's more complex data structures (linked lists, sets, queues, etc.) into two fundamental shapes: **tables** (key-value maps) and **arrays** (integer-indexed sequences). When working with complex data, transform it into one of these two shapes rather than introducing novel structures. Utils should operate on tables and arrays, not on custom data types.

**When to add a new utility:**
- The operation applies to a general data type (table, array, string, number) with no engine-specific semantics.
- Multiple mods need it, or a single mod uses it in many places.
- The operation makes mod code clearer by replacing an inline loop or conditional block with a named function.

**When NOT to add a new utility:**
- The operation is specific to one mod's domain logic (e.g., computing a mod-specific layout offset).
- The operation is a trivial one-liner that reads clearly inline.

#### 3.4 Type Annotations

Use Lua annotations and comments to define types on functions and variables where the IDE would otherwise have trouble inferring them. This is especially important for:

- **Function signatures** -- annotate parameters and return types.
- **Table structures** -- annotate complex table shapes (model tables, data wrappers).
- **Closure captures** -- when a variable's type is non-obvious due to metatable proxies or dynamic assignment.

```lua
--- @param playerId number The entity ID of the player
--- @return table playerStatus The wrapped PlayerStatus data object
local function getPlayerInfo(playerId)
    return Data.PlayerStatus(playerId)
end
```

**Use `@type` to help the language server wherever it cannot infer the correct type.** The UO EC Lua environment contains custom types (e.g., `wstring`) and polymorphic framework functions that return union types. The language server often cannot narrow these automatically. Add inline `---@type` annotations proactively rather than waiting for errors.

**When to annotate:**
- **Variables initialized to a narrow type but later assigned a wider one.** If a variable starts as `""` but will receive a `string|wstring` from a polymorphic function, annotate the declaration:
  ```lua
  local itemName = "" ---@type string|wstring
  ```
- **Return values from polymorphic functions.** When a framework function returns `string|wstring` but the consuming code needs one specific type, annotate the declaration to narrow:
  ```lua
  local name = Utils.String.Replace(raw, "^%d+ ", "") ---@type wstring
  ```
- **Engine data that the language server has no type information for.** Tables from `WindowData.*` or callback parameters often lack type info. Annotate locals that receive them:
  ```lua
  local data = WindowData.ContainerWindow[id] ---@type ContainerWindowData
  ```
- **Metatable-proxied objects.** The framework's Data wrappers and Component classes use metatables heavily. The language server cannot trace through `__index` chains. Annotate when the inferred type is wrong or `unknown`.

**Keep `types/Engine.lua` up to date.** Custom engine types (`wstring`, `Event`, `Type`, etc.) are declared in `types/Engine.lua` and loaded via `.luarc.json`. When adding a new engine type or data structure that the language server doesn't know about, add its `@class` definition there rather than scattering `@type any` annotations across mod code.

#### 3.5 Unused Parameters

**Name unused function parameters `_`.** When a callback signature requires parameters that the function body does not reference, replace each unused parameter name with `_`. This signals intent ("deliberately ignored") and silences lint warnings.

```lua
-- Good: unused self and children params are _
OnLayout = function(win, _, child, idx) ... end
OnShutdown = function(_) ... end

-- Bad: named params that are never read
OnLayout = function(win, children, child, idx) ... end
OnShutdown = function(self) ... end
```

Multiple consecutive unused parameters can all be `_` -- Lua allows repeated `_` in a parameter list. Only rename parameters that are truly unused in the function body.

#### 3.6 Lazy Window Creation

**Prefer creating windows when they are needed, not at mod initialization.** Favor outright creation and destruction over hiding and showing. If a window is not visible, it should usually not exist.

- **Create on demand, destroy when done.** When a user opens their inventory, create the container window. When they close it, destroy it. Do not pre-create it in `OnInitialize` and toggle visibility.
- **Destruction over hiding.** Destroying a window fully releases its engine resources, event registrations, and data bindings. Hiding leaves all of that alive but invisible — wasteful and a source of stale-state bugs.
- **Exceptions for always-present windows.** Top-level windows with broad, persistent relevance — the map, player paperdoll, player status bar, player backpack — may be created in `OnInitialize` because they are visible most or all of the time.
- **When destruction is impractical**, hiding is acceptable. Some windows have expensive setup (complex data registration, engine-side state) where the cost of recreation outweighs the cost of keeping them hidden. Use judgment, but default to create/destroy.

### 4. Debugging Methodology

When something doesn't work, follow this sequence -- **do not skip steps:**

1. **Read `lua.log`** (path from `.env`). Look for `[Error]` entries. Many problems are XML load failures or missing templates that cascade into "window does not exist" errors.
2. **Fetch the default UI's XML AND Lua** for the equivalent component from the GitHub repo.
3. **Compare attribute-by-attribute.** If the default UI's XML has attributes not in the Mongbat template, that's likely the problem.
4. **Compare call-by-call.** If the default UI calls engine functions differently, that's likely the problem.
5. **If the component updates but incorrectly**, events ARE dispatching -- the problem is in how the engine interprets the data (XML attributes, API arguments, dimensions).
6. **If you cannot determine the root cause after steps 1-5**, ask the user what they observe rather than guessing.

### 5. Game Aesthetics

Ultima Online has a **fantasy medieval** theme. UI should use ornate borders, classic fonts, earthy/gold palettes. Prioritize readability and immersion over modern UI patterns.

### 6. General Rules

- **Do not add debug print statements.** Research the root cause in the default UI source (both Lua AND XML). Debug prints are noise that do not solve problems.
- **Do not develop theories -- verify facts.** Read the default UI's XML and Lua; compare attribute-by-attribute, call-by-call. The answer is almost always a concrete difference between what the default UI does and what the mod does.
- **Ask the user when uncertain.** If there are multiple plausible root causes, describe what you've found, present the options, and ask which matches their observation. Do not silently pursue a theory across multiple edits.
- **Consult XML, not just Lua.** Many engine behaviors are configured via XML attributes with no Lua setter. Always check template XML when a component misbehaves.
- **Validate against the default UI repo or docs** when unsure about any engine behavior.
- If information is unavailable, suggest checking the repositories or UO modding communities.

### 7. Anti-Patterns

The following mistakes waste effort. **Never repeat them.**

#### 7.1 Blaming Event Dispatch When the Problem is Visual

If a component updates at all (even incorrectly), events ARE dispatching. The problem is XML attributes or engine API arguments. Read the default UI's XML definition.

#### 7.2 Adding Debug Prints Instead of Researching

Do not add `Debug.Print` and ask the user to test. Trace the code, read the default UI, compare to working mods.

#### 7.3 Ignoring XML Templates

When Lua looks correct but a component misbehaves, fetch the default UI's XML file. Many behaviors are XML-only. If the Mongbat template is missing an attribute, create a custom template in the mod's `.xml` file.

#### 7.4 Iterating on a Broken Theory

After one failed fix, stop and reassess. Go back to first principles: what does the default UI do (both Lua AND XML)? What does our code do? What is the concrete difference?

#### 7.5 Misplacing Events in Constants Tables

The `Constants.CoreEvents`, `Constants.SystemEvents`, and `Constants.DataEvents` tables drive automatic registration in `View:onInitialize`. `OnLButtonDown` and `OnLButtonUp` are CoreEvents — they are registered on every view and dispatched via `withActiveView`. Events handled through a different mechanism (e.g., `OnMouseDrag` via synthesis) must **not** appear in `Constants.CoreEvents`. Leaving a synthesized event there causes the framework to register a CoreEvent callback string (e.g., `Mongbat.EventHandler.OnMouseDrag`) that doesn't exist as a function, producing a runtime error when the engine tries to call it.
