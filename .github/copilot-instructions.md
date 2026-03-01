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
- **Metatables** -- Mongbat makes heavy use of `__index`, `__newindex`, `__call`, and `__tostring` metamethods for its class system and proxy pattern.
- **Global namespace** -- all default UI scripts and engine functions populate the global table. Mongbat captures references and sometimes overrides globals (via its `DefaultComponent` system).

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

1. The mod passes a **model table** (plain Lua table) to a factory function (e.g., `ctx.Components.Window { Name = "...", ... }`).
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

### The Two-Layer Model: XML and Lua

The engine has a strict split between **creation-time** (XML) and **runtime** (Lua):

- **XML templates** define element types, structure, and certain attributes that have **no Lua setter**.
- **Lua** controls runtime behavior: dimensions, visibility, alpha, tint, event handlers, etc.

When a component misbehaves despite correct Lua code, the problem is almost always a **missing XML attribute**. The engine's C++ layer reads some attributes only at template-instantiation time. To discover which attributes exist for a given element type, **fetch the default UI's XML definition** for the equivalent component from the GitHub repo and compare attributes.

Mongbat centralizes XML templates in `Mongbat.xml` (minimal templates that rely on Lua for configuration). When a mod needs an XML attribute not in the standard template, it must define a **custom template** in its own `.xml` file and set the `Template` key in the component model.

**The `MongbatWindow` template is a `<MaskWindow>`**, which clips children to its bounds.

### DefaultComponent Replacement

Mongbat can **replace** default UI windows by intercepting their global Lua tables:
1. Captures the original global (e.g., `StatusWindow`) before the mod loads.
2. Replaces it with a proxy whose lifecycle methods are no-ops.
3. Provides `disable()` / `restore()` methods to toggle the replacement.
4. The mod creates its own Window that takes over the visual role.

Mods access default components via `ctx.Components.Defaults.<name>`. See existing mods for the pattern: disable the original in `OnInitialize`, restore it in `OnShutdown`.

### Mod Lifecycle

1. `.mod` XML declares the mod, its script, and dependency on `Mongbat`.
2. The Lua script calls `Mongbat.Mod { Name = "...", OnInitialize = ..., OnShutdown = ..., ... }`.
3. Mongbat provides a **context object** (`ctx`) with: `Api`, `Data`, `Utils`, `Constants`, `Components`.
4. `OnInitialize(ctx)` -- create windows, register handlers, disable defaults.
5. `OnShutdown(ctx)` -- destroy windows, restore defaults.
6. `OnUpdate(ctx, deltaTime)` -- per-frame logic (optional).

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

## Guidelines for Responses

### 0. Consult the Project README

**Before writing or debugging any Mongbat mod code, read the README.md in the repository root.** It contains the project overview, class hierarchy, and context object documentation.

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
