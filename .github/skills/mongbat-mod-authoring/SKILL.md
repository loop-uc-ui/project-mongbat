---
name: mongbat-mod-authoring
description: "Use when creating, migrating, modifying, or refactoring a mod in src/mods/. Walks through the router-pattern authoring workflow: identify engine globals, add Mongbat wrappers FIRST, declare a module table M with lifecycle methods (OnLoad/OnUnload/OnUpdate/OnUpdateWindow/On<Event>), register windows via Mongbat.CreateWindow, route engine events on (name, key), verify zero diagnostics in mod files. Covers mongbat mod authoring, mod scaffolding, mod migration, router pattern, module-table model, Mongbat.Mod declaration, Mongbat.CreateWindow. DO NOT USE for src/lib/Mongbat.lua framework work — that's where engine globals legally live."
---

# Mongbat Mod Authoring

## When to Use

- Creating a new mod under `src/mods/mongbat-<name>/`
- Migrating an existing mod that still references engine globals directly
- Adding features (Bindings, lifecycle methods) to an existing mod
- Refactoring a mod to the router + module-table pattern

**Do NOT use** when editing `src/lib/Mongbat.lua` — the framework is the one
place engine globals are allowed. For that, use the `/wrap-engine-global`
prompt instead.

## The Boundary (non-negotiable)

Mods reference ONLY:

- `Mongbat.Api` — engine function wrappers
- `Mongbat.Data` — `WindowData.*` accessor wrappers (nil-safe)
- `Mongbat.Utils` — `Utils.String/Table/Array`
- `Mongbat.Constants` — `Colors`, `WindowLayers`, `GumpIds`, etc.
- `Mongbat.Debugger` — `Debug.*` wrappers (`Print`, `PrintToChat`, `Dump`, ...)
- `Mongbat.CreateWindow` / `RegisterWindow` / `DestroyWindow` /
  `UnregisterWindow` / `GetWindow` — window registry helpers
- `Mongbat.Mod {...}` — the mod declaration

Default-UI module lifecycle entry points are exposed as `Api.<Module>.On<Event>`
chain helpers (e.g. `Api.ObjectHandle.OnCreate`, `Api.GenericGump.OnShown`,
`Api.GumpsParsing.OnParsingCheck`).

**Forbidden in mods:** `WindowData`, `SystemData`, `GenericGump`,
`GumpsParsing`, `ObjectHandleWindow`, `InterfaceCore`, `HotbarSystem`,
`ItemProperties`, `EquipmentData`, `wstring`, `WindowGetId`, etc. If you
need them, the lib must wrap them first. Never use
`---@diagnostic disable: undefined-global` to silence the boundary in a mod.

## Architecture Recap

Mongbat is a **router**. The lib maintains a `name -> { module, key }`
registry. When the engine fires an event on a window, the lib looks up the
window's owning mod and calls the matching method on its module table:

```
engine event on window "X"
        |
        v
Mongbat.EventHandler.<Event>  (wired in MongbatXxx XML templates)
        |
        v   (looks up SystemData.ActiveWindow.name in the registry)
        v
M.<Event>(name, key, ...)     (runs in the owning mod)
```

Mods own all state. The lib never diffs descriptors, never re-renders, and
holds no closures.

## Workflow

### 1. Anchor on Existing Patterns

Before writing anything, read at least one canonical mod that resembles
what you're building:

| Need | Read |
|---|---|
| Per-frame label, no state | [mongbat-distance-counter](../../../src/mods/mongbat-distance-counter/MongbatDistanceCounterMod.lua) |
| EditBox + LogDisplay + filter state | [mongbat-debug](../../../src/mods/mongbat-debug/MongbatDebugMod.lua) |
| Replace a default window + button stack | [mongbat-main-menu](../../../src/mods/mongbat-main-menu/MongbatMainMenuMod.lua) |
| Bindings + composite status bars | [mongbat-player-status](../../../src/mods/mongbat-player-status/MongbatPlayerStatusMod.lua) |
| Suppression-only, no windows | [mongbat-suppress-pet-training-gump](../../../src/mods/mongbat-suppress-pet-training-gump/MongbatSuppressPetTrainingGumpMod.lua) |
| Chain helpers, no windows | [mongbat-classic-vendor-search](../../../src/mods/mongbat-classic-vendor-search/MongbatClassicVendorSearchMod.lua) |
| Equipment grid + figure mode | [mongbat-paperdoll](../../../src/mods/mongbat-paperdoll/MongbatPaperdollMod.lua) |
| Dynamic per-id windows | [mongbat-object-handle](../../../src/mods/mongbat-object-handle/MongbatObjectHandleMod.lua) |
| Per-frame OnUpdate(dt) drag/zoom | [mongbat-map](../../../src/mods/mongbat-map/MongbatMapMod.lua) |

Also read [.github/copilot-instructions.md](../../copilot-instructions.md).

### 2. Identify Engine Globals First

Sketch what engine surface the mod needs (data tables, default-UI module
calls, lifecycle hooks). For each:

1. Search `src/lib/Mongbat.lua` for an existing wrapper. If found, plan to
   use it.
2. If not, **stop and run `/wrap-engine-global` first**. Add the wrapper to
   the lib, then resume mod authoring.

When the engine surface is unclear, consult the upstream default UI as
ground truth before inventing a mechanism:

- Source: <https://github.com/loop-uc-ui/enhanced-client-default>
- Docs:   <https://loop-uc-ui.github.io/enhanced-client-default-docs/>
- Offline mirror: [`docs/`](../../../docs/) — `InterfaceCore.txt`,
  `UO_GenericGump.txt`, `UO_DefaultWindow.txt`, `UO_StandardDialog.txt`,
  `singelinetextentry.txt`, `Interface.xsd`.

### 3. Scaffold the Mod (or use `/new-mod`)

```
src/mods/mongbat-<kebab>/
├── Mongbat<Name>.mod         # EC mod manifest (copy from a neighbor)
├── Mongbat<Name>Mod.lua      # The mod
└── Mongbat<Name>.xml         # Optional: per-mod templates
```

### 4. Write the Module Table

```lua
-- <One-paragraph purpose & update strategy.>

local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Utils     = Mongbat.Utils
local Constants = Mongbat.Constants

local NAME = "Mongbat<Name>Window"

local M = {}
local state = { ... }   -- mod-owned; mutate freely

function M.OnLoad()
    Mongbat.CreateWindow {
        name     = NAME,
        template = "MongbatWindow",
        module   = M,
        key      = "panel",
        -- id     = mobileId,   -- pass for per-mobile data
    }
    Api.Window.SetDimensions(NAME, 200, 100)
end

function M.OnUnload()
    Mongbat.DestroyWindow(NAME)
end

-- Routed engine events. The dispatcher always passes (name, key, ...).
function M.OnLButtonUp(_name, key)
    if key == "panel" then ... end
end

-- Per-frame, per-window pull. The lib auto-registers every WindowData
-- type for the window's id, so Mongbat.Data.* resolves; just read it.
function M.OnUpdateWindow(_name, _key, _dt)
    local hp = Mongbat.Data.PlayerStatus():getCurrentHealth()
    Api.Label.SetText(NAME .. "Label", tostring(hp))
end

Mongbat.Mod {
    Name   = "Mongbat<Name>",
    Path   = "/src/mods/mongbat-<kebab>",
    Module = M,
}
```

#### Lifecycle method reference

| Method | Args | When |
|---|---|---|
| `M.OnLoad()` | — | Once at startup |
| `M.OnUnload()` | — | Once at teardown |
| `M.OnUpdate(dt)` | `dt` | Every frame, once per mod (cross-window or mod-level work) |
| `M.OnUpdateWindow(name, key, dt)` | `(name, key, dt)` | Every frame, once per registered window owned by this mod |
| `M.OnInitialize` | `(name, key)` | Engine fires when a window is created |
| `M.OnShown` / `M.OnHidden` / `M.OnShutdown` | `(name, key)` | Window visibility/destroy |
| `M.OnLButtonUp/Down`, `M.OnRButtonUp/Down`, `M.OnLButtonDblClk` | `(name, key, flags?, x?, y?)` | Mouse buttons |
| `M.OnMouseOver` / `M.OnMouseOverEnd` | `(name, key)` | Hover transitions |
| `M.OnMouseWheel` | `(name, key, x, y, delta)` | Scroll wheel |
| `M.OnEditBoxChanged/KeyEscape/KeyReturn/KeyTab` | `(name, key)` | Edit-box events |

Any method you don't define is simply not called.

### 5. `Mongbat.CreateWindow` Reference

```lua
Mongbat.CreateWindow {
    name     = "MongbatXWindow",  -- required; unique
    template = "MongbatWindow",   -- required; XML template name
    module   = M,                 -- required; the routing target
    key      = "panel",           -- optional; defaults to `name`
    parent   = "MongbatYWindow",  -- optional; parent window for child windows
    showing  = true,              -- optional; defaults to true
    id       = mobileId,          -- optional; defaults to 0. Used for per-mobile
                                  -- WindowData (MobileName, MobileStatus,
                                  -- HealthBarColor, Paperdoll). The lib
                                  -- auto-registers every WindowData type for
                                  -- this id; mods read it via Mongbat.Data.<Key>(id).
}
```

The lib ref-counts each `(dataKey, id)` pair and calls
`Api.Window.UnregisterData` when the last window using that id is destroyed.
Fetch the id (e.g. `Data.PlayerStatus():getId()`) before calling
`Mongbat.CreateWindow` so it can be passed in.

Distinct windows in a single mod need unique `name` values. Pass distinct
`key` values to dispatch on inside `M.On*` methods (e.g. `key = "slot1"`,
`key = "slot2"`).

### 6. Data Wrapper Reference

| Wrapper | Returns |
|---|---|
| `Data.PlayerStatus()` | `getId/getCurrentHealth/getMaxHealth/getCurrent/Max{Mana,Stamina}/isInWarMode/...` |
| `Data.MobileStatus(id)` | `getName/getNotoriety/getNotorietyColor` (nil-safe) |
| `Data.MobileName(id)` | `getName` (nil-safe) |
| `Data.HealthBarColor(id)` | `getVisualStateId/getVisualStateColor` (nil-safe) |
| `Data.Paperdoll(id)` | `getSlot(i)/getNumSlots` |
| `Data.PaperdollTexture(id)` | `getTextureName` |
| `Data.ObjectHandles()` | `getHandles/getHandle(id)` |
| `Data.Radar()` | `getTexCoordX/Y/getTexScale` |
| `Data.Cursor()` | `isTarget/...` |
| `Data.Drag()` | `isDraggingItem/...` |
| `Data.PlayerLocation()` | location accessors |
| `Data.MousePosition()` | `{ x, y }` |
| `Data.MouseOverWindow()` | the active mouse-over window name |
| `Data.Object(id)` | `isValid/...` |
| `Data.IsShift/IsControl/IsAlt(flags)` | flag predicates |

### 6a. Iteration Helpers (`Utils.Array` / `Utils.Table`)

**Never iterate a table or array in a mod with raw `ipairs` / `pairs` /
`for ... = ...` over `#t`.** Use the helpers — they are nil-safe, generic-typed,
and keep mod code declarative.

| Use case | Helper |
|---|---|
| Iterate an array (1..#a) | `Utils.Array.ForEach(a, function(item, i) end)` |
| Map array → array (skip nil returns) | `Utils.Array.MapToArray(a, function(item, i) return ... end)` |
| Filter an array | `Utils.Array.Filter(a, function(item, i) return ... end)` |
| Find first match in array | `Utils.Array.Find(a, function(item) return ... end)` |
| Index of match in array | `Utils.Array.IndexOf(a, function(item) return ... end)` |
| Append/insert | `Utils.Array.Add(a, item, pos?)` |
| Remove by index | `Utils.Array.Remove(a, i)` |
| Concat array-of-arrays | `Utils.Array.Concat({ a, b, c })` |
| Copy an array | `Utils.Array.Copy(a)` |
| Build a table from an array | `Utils.Array.MapToTable(a, getKey, getValue)` |
| Iterate a hash table (pairs) | `Utils.Table.ForEach(t, function(k, v) end)` |
| Find first match in a table | `Utils.Table.Find(t, function(k, v) return ... end)` |
| Deep merge two tables | `Utils.Table.Merge(target, source)` |

**Numeric `for i = 1, N` loops over engine-counted ranges** (e.g. paperdoll
slots 1..NUM_SLOTS, `Api.TextLog.GetNumEntries(log)` 0..count-1) are fine —
those are not table iterations. Use Utils helpers when the bound *is* a
table (`#t` or pairs).

### 7. `Api.Window.Destroy` vs `Api.<Module>.On<Event>`

- **`Api.Window.Destroy("WindowName")`** at the top of `M.OnLoad()` —
  destroys the named default-UI window(s) so the mod can recreate them
  under the same name. Use when your mod wholesale replaces a default
  window (e.g. `mongbat-main-menu`, `mongbat-map`, `mongbat-debug`).
- **`Api.<Module>.On<Event>(fn)`** — chains into a default-UI module
  lifecycle entry point so multiple subscribers compose. Use when you need
  to react to default-UI state changes (e.g. `Api.ObjectHandle.OnCreate`
  for object-handle lifecycle, `Api.GenericGump.OnShown` for gump-render
  reactions, `Api.GumpsParsing.OnParsingCheck` for per-frame parsing).

### 8. Verify

After every mod edit:

1. Run `get_errors` on the mod file → expect **zero** diagnostics.
2. Run `grep_search` for the engine-global blacklist on the mod file →
   expect zero matches outside string literals and `---@class`/`---@field`
   annotations.
3. If you added or modified a wrapper in `src/lib/Mongbat.lua`, expect lib
   pre-existing engine-global warnings to remain unchanged in count;
   anything NEW is a regression.

## Anti-Patterns

- **Direct engine globals in mods.** Always `Mongbat.*`. If the wrapper
  doesn't exist, add it to the lib first via `/wrap-engine-global`.
- **`---@diagnostic disable: undefined-global` in a mod.** Marker for a
  boundary leak. Delete it after migrating to wrappers.
- **`L"..."` wstring literals in a mod.** `L` is undefined. Use
  `Utils.String.ToWString("...")` instead. (`Api.Label.SetText` and
  `Api.Button.SetText` accept `string|wstring|number` directly.)
- **Pulling engine data in `M.OnUpdate(dt)` for window-specific UI.** Use
  `bindings` + `M.OnUpdateWindow(name, key, dt)` and read live state via
  `Mongbat.Data.*`. Reserve `M.OnUpdate(dt)` for cross-window or mod-level
  work (animations, mouse-position polling, drag deltas).
- **Re-using a window `name` across mods.** Names are the registry key.
  Distinct windows need distinct names; use `key` to disambiguate within a
  mod.
- **Forgetting `Mongbat.DestroyWindow(NAME)` in `M.OnUnload`.** Hot-reload
  will leak windows.
- **Overwriting default-UI module functions directly** (e.g.
  `GenericGump.OnShown = fn`). Use the chain helpers (`Api.GenericGump.OnShown`,
  `Api.GumpsParsing.OnParsingCheck`, `Api.ObjectHandle.On*`) so multiple
  subscribers compose.
- **Raw `ipairs` / `pairs` / `for i = 1, #t` in a mod.** Use
  `Utils.Array.*` for array iteration and `Utils.Table.*` for hash-table
  iteration. Numeric `for i = 1, N` over an engine-supplied count is fine.
