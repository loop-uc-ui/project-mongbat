---
name: mongbat-mod-authoring
description: "Use when creating, migrating, modifying, or refactoring a mod in src/mods/. Walks through the declarative Build-pattern authoring workflow: identify engine globals, add Mongbat wrappers FIRST, declare a module table M with M.Build(emit) for windows and lifecycle methods (OnLoad/OnUnload/OnUpdate/On<Event>), route engine events on (name, key), verify zero diagnostics in mod files. Covers mongbat mod authoring, mod scaffolding, mod migration, declarative window emission, M.Build, Mongbat.UI widgets, Mongbat.Mod declaration. DO NOT USE for src/lib/Mongbat.lua framework work — that's where engine globals legally live."
---

# Mongbat Mod Authoring

## When to Use

- Creating a new mod under `src/mods/mongbat-<name>/`
- Migrating an existing mod that still references engine globals directly
- Adding features (windows, lifecycle methods) to an existing mod
- Refactoring a mod to the declarative Build pattern

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
- `Mongbat.UI` — declarative widget builders (Window, Label, Button, DynamicImage, EditBox, TextLog)
- `Mongbat.GetWindow(engineName)` — registry lookup (rarely needed)
- `Mongbat.Mod {...}` — the mod declaration

Default-UI module lifecycle entry points are exposed as `Api.<Module>.On<Event>`
chain helpers (e.g. `Api.ObjectHandle.OnCreate`, `Api.GenericGump.OnShown`,
`Api.GumpsParsing.OnParsingCheck`).

**Forbidden in mods:** `WindowData`, `SystemData`, `GenericGump`,
`GumpsParsing`, `ObjectHandleWindow`, `InterfaceCore`, `HotbarSystem`,
`ItemProperties`, `EquipmentData`, `wstring`, `WindowGetId`, etc. If you
need them, the lib must wrap them first. Never use
`---@diagnostic disable: undefined-global` to silence the boundary in a mod.

## Architecture: Declarative Build + Router

Mongbat is a **declarative reconciler + router**. Each frame:

1. The lib calls `M.OnUpdate(dt)` on every loaded mod (mod-level work).
2. The lib calls `M.Build(emit)` on every loaded mod. The mod calls
   `emit(key, spec)` once per window it wants this frame.
3. The lib diffs the emitted set vs the prior frame: new keys are created,
   existing keys re-apply widget ops, missing keys are destroyed.

When the engine fires an event on a window, the lib looks up the window's
owning mod and calls the matching method on its module table:

```
engine event on window "MongbatX_panel"
        |
        v
Mongbat.EventHandler.<Event>  (wired in MongbatXxx XML templates)
        |
        v   (looks up SystemData.ActiveWindow.name in the registry)
        v
M.<Event>(name, key, ...)     (key = "panel", in the owning mod)
```

Mods own all state. The lib never holds closures, never pushes data events.

## Workflow

### 1. Anchor on Existing Patterns

Before writing anything, read at least one canonical mod that resembles
what you're building:

| Need | Read |
|---|---|
| Per-frame label, conditional emit | [mongbat-distance-counter](../../../src/mods/mongbat-distance-counter/MongbatDistanceCounterMod.lua) |
| EditBox + LogDisplay + filter state | [mongbat-debug](../../../src/mods/mongbat-debug/MongbatDebugMod.lua) |
| Replace a default window + button stack | [mongbat-main-menu](../../../src/mods/mongbat-main-menu/MongbatMainMenuMod.lua) |
| Composite live status bars | [mongbat-player-status](../../../src/mods/mongbat-player-status/MongbatPlayerStatusMod.lua) |
| Suppression-only, no windows | [mongbat-suppress-pet-training-gump](../../../src/mods/mongbat-suppress-pet-training-gump/MongbatSuppressPetTrainingGumpMod.lua) |
| Chain helpers, no windows | [mongbat-classic-vendor-search](../../../src/mods/mongbat-classic-vendor-search/MongbatClassicVendorSearchMod.lua) |
| Mode-swapping children | [mongbat-paperdoll](../../../src/mods/mongbat-paperdoll/MongbatPaperdollMod.lua) |
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
- Offline mirror: [`docs/`](../../../docs/).

### 3. Scaffold the Mod (or use `/new-mod`)

```
src/mods/mongbat-<kebab>/
├── Mongbat<Name>.mod         # EC mod manifest (copy from a neighbor)
├── Mongbat<Name>Mod.lua      # The mod
└── Mongbat<Name>.xml         # Optional: per-mod templates (rarely needed)
```

### 4. Write the Module Table

```lua
-- <One-paragraph purpose & what state drives Build.>

local UI        = Mongbat.UI
local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Utils     = Mongbat.Utils
local Constants = Mongbat.Constants

local M = {}
local state = { ... }   -- mod-owned; mutate freely

function M.Build(emit)
    -- Read live engine state inline; emit one window per key.
    local hp = Data.PlayerStatus():getCurrentHealth()

    emit("panel", {
        template = "MongbatWindow",
        widget   = UI.Window():setDimensions(200, 100),
    })

    emit("label", {
        template = "MongbatLabel",
        parent   = "panel",                -- sibling key, lib resolves
        widget   = UI.Label()
            :setText(tostring(hp))
            :setOffsetFromParent(8, 8),
    })
end

-- Routed engine events. The dispatcher always passes (name, key, ...).
function M.OnLButtonUp(_name, key)
    if key == "panel" then ... end
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
| `M.OnLoad()` | — | Once at startup. Use for engine-resource setup (TextLogs, default-UI suppression) and one-shot `Api.Window.Destroy("DefaultName")`. |
| `M.OnUnload()` | — | Once at teardown. The lib auto-destroys all Build-emitted windows; only undo OnLoad's side effects (TextLogs, default-UI flags). |
| `M.OnUpdate(dt)` | `dt` | Every frame, once per mod. Use for engine-side mutations not expressible as widget setters (radar pan, drag deltas). |
| `M.Build(emit)` | `emit` | Every frame, once per mod. Emit each window the mod wants this frame. Lib diffs vs prior frame. |
| `M.OnInitialize` | `(name, key)` | Engine fires when a window is created |
| `M.OnShown` / `M.OnHidden` / `M.OnShutdown` | `(name, key)` | Window visibility/destroy |
| `M.OnLButtonUp/Down`, `M.OnRButtonUp/Down`, `M.OnLButtonDblClk` | `(name, key, flags?, x?, y?)` | Mouse buttons |
| `M.OnMouseOver` / `M.OnMouseOverEnd` | `(name, key)` | Hover transitions |
| `M.OnMouseWheel` | `(name, key, x, y, delta)` | Scroll wheel |
| `M.OnEditBoxChanged/KeyEscape/KeyReturn/KeyTab` | `(name, key)` | Edit-box events |

Any method you don't define is simply not called.

### 5. `M.Build(emit)` and the spec table

```lua
emit(key, {
    template        = "MongbatWindow",  -- required; XML template name
    widget          = UI.Window()...,   -- optional; recorded ops applied after create
    parent          = "siblingKey",     -- optional; sibling key in this mod (or nil → Root)
    name            = "FixedEngineName",-- optional; override engine name (default-UI hijack)
    id              = mobileId,         -- optional; WindowData id (default 0)
    showing         = true,             -- optional; initial visibility (default true)
    replacesDefault = true,             -- optional; destroy engine name once before first create
})
```

- **`key`** is mod-local, used to dispatch routed events (`M.On*(name, key)`).
  Distinct windows in a mod need distinct keys.
- **Engine name** = `spec.name or "<modName>_<sanitized key>"`. The default
  is fine for new windows; use `name=` only when the default UI references
  the window by a fixed name (e.g. `"MainMenuWindow"`, `"MapWindow"`).
- **`parent = "siblingKey"`** references another emit key in the same mod;
  the lib resolves it to the engine name. Emit the parent first.
- **`id = mobileId`** registers per-mobile WindowData (`MobileName`,
  `MobileStatus`, `HealthBarColor`, `Paperdoll`) for that id so
  `Mongbat.Data.MobileName(mobileId):getName()` resolves. Ref-counted; the
  lib unregisters when the last window using that id is destroyed.
- **Conditional windows:** simply don't `emit()` a key in a frame and the
  lib destroys it. Re-emit later to recreate. Cheap.
- **Dynamic per-id windows** (e.g. one window per object handle): emit
  `"frame:" .. id` and `"label:" .. id` per item; the lib auto-creates
  new ids and auto-destroys ones that disappeared.

### 6. `Mongbat.UI` Widget Reference

Widgets are dual-mode:

- **Unbound** (`UI.Window()`) — records ops into a `_ops` list. Pass to
  `emit(...)` via `widget = UI.Window():setX(...):setY(...)`. The lib
  applies the recorded ops to the engine window after `CreateFromTemplate`.
- **Bound** (`UI.Window("ExistingEngineName")`) — pushes immediately.
  Useful in OnUpdate for one-off tweaks; rarely needed when Build owns the
  window.

Setters return `self` for chaining. Getters return the live engine value.

| Class | Common setters |
|---|---|
| `UI.Window()` | `setDimensions(w,h)`, `setPosition(x,y)`, `setOffsetFromParent(x,y)`, `setShowing(b)`, `show()`, `hide()`, `setColor(c)`, `setAlpha(a)`, `setLayer(l)`, `setId(id)`, `setMovable(b)`, `setHandleInput(b)`, `setScale(s)`, `clearAnchors()`, `addAnchor(point, target, relPoint, dx, dy)`, `setParent(target)`, `attachToWorldObject(objectId)`, `tap(fn)` |
| `UI.Label()` | (Window methods +) `setText(t)`, `setTextColor(c)`, `setTextAlignment(a)`, `setWordWrap(b)` |
| `UI.Button()` | (Window methods +) `setText(t)`, `setTextColor(r,g,b,a)`, `setDisabled(b)`, `setChecked(b)`, `setTexture(...)`, `setHighlight(b)`, `setStayDown(b)` |
| `UI.DynamicImage()` | (Window methods +) `setTexture(name, x, y)`, `setTextureScale(s)`, `setTextureDimensions(w,h)`, `setRotation(r)` |
| `UI.EditBox()` | (Window methods +) `setText(t)`, `clear()`, `selectAll()`, `setFont(name, lineSpacing)` |

**Sibling-key references in anchors / parent:**
`addAnchor("topleft", "panel", "topleft", 0, 0)` — `"panel"` is a sibling
emit key; the lib substitutes the engine name when applying. Use `"parent"`
as a special target to anchor to the immediate engine parent.

**Escape hatch — `:tap(fn)`** records `fn(engineName)` for non-setter Api
calls (e.g. `Api.LogDisplay.AddLog`, `Api.Equipment.UpdateItemIcon`).
Runs every frame the window is re-emitted.

### 7. Data Wrapper Reference

| Wrapper | Returns |
|---|---|
| `Data.PlayerStatus()` | `getId/getCurrentHealth/getMaxHealth/getCurrent/Max{Mana,Stamina}/isInWarMode/...` |
| `Data.MobileStatus(id)` | `getName/getNotoriety/getNotorietyColor` (nil-safe) |
| `Data.MobileName(id)` | `getName` (nil-safe) |
| `Data.HealthBarColor(id)` | `getVisualStateId/getVisualStateColor` (nil-safe) |
| `Data.Paperdoll(id)` | `getSlot(i)/getNumSlots` |
| `Data.PaperdollTexture(id)` | `getTextureName/getWidth/getHeight/...` |
| `Data.ObjectHandles()` | `getHandles/getHandle(id)` |
| `Data.Radar()` | `getTexCoordX/Y/getTexScale` |
| `Data.Cursor()` | `isTarget/...` |
| `Data.Drag()` | `isDraggingItem/...` |
| `Data.PlayerLocation()` | location accessors |
| `Data.MousePosition()` | `{ x, y }` |
| `Data.MouseOverWindow()` | the active mouse-over window name |
| `Data.Object(id)` | `isValid/...` |
| `Data.IsShift/IsControl/IsAlt(flags)` | flag predicates |

### 7a. Iteration Helpers (`Utils.Array` / `Utils.Table`)

**Never iterate a table or array in a mod with raw `ipairs` / `pairs` /
`for ... = ...` over `#t`.** Use the helpers — they are nil-safe, generic-typed,
and keep mod code declarative.

| Use case | Helper |
|---|---|
| Iterate an array (1..#a) | `Utils.Array.ForEach(a, function(item, i) end)` |
| Map array → array (skip nil returns) | `Utils.Array.MapToArray(a, function(item, i) return ... end)` |
| Filter an array | `Utils.Array.Filter(a, function(item, i) return ... end)` |
| Find first match in array | `Utils.Array.Find(a, function(item) return ... end)` |
| Iterate a hash table (pairs) | `Utils.Table.ForEach(t, function(k, v) end)` |
| Find first match in a table | `Utils.Table.Find(t, function(k, v) return ... end)` |
| Deep merge two tables | `Utils.Table.Merge(target, source)` |

**Numeric `for i = 1, N` loops over engine-counted ranges** (e.g. paperdoll
slots 1..NUM_SLOTS, `Api.TextLog.GetNumEntries(log)` 0..count-1) are fine.

### 8. `Api.Window.Destroy` vs `Api.<Module>.On<Event>`

- **`Api.Window.Destroy("WindowName")`** at the top of `M.OnLoad()` —
  destroys the named default-UI window so the mod can recreate it. Combine
  with `replacesDefault = true` in the spec when emitting under the same
  fixed `name`.
- **`Api.<Module>.On<Event>(fn)`** — chains into a default-UI module
  lifecycle entry point so multiple subscribers compose. Use when you need
  to react to default-UI state changes without hijacking a window.

### 9. Verify

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
- **Imperative `Mongbat.CreateWindow` / `DestroyWindow` in a mod.** Those
  helpers no longer exist. Express windows through `M.Build(emit)` and let
  the reconciler create / destroy as the emitted set changes.
- **Manual diff loops over dynamic windows.** Just emit the current set
  inside `M.Build` (e.g. one entry per object-handle id). The lib does the
  diff.
- **Pulling engine data inside `M.OnUpdate(dt)` for window setters.** Read
  it inside `M.Build(emit)` and feed it through `:setText(...)`/etc. on the
  widget. Reserve `M.OnUpdate(dt)` for engine-side mutations not
  expressible as widget setters (e.g. `Api.Radar.CenterOnLocation` panning).
- **Re-using a window `name` across mods.** Names are the registry key.
  The default `<modName>_<key>` already namespaces; only override `name=`
  for fixed default-UI hijacks.
- **Overwriting default-UI module functions directly** (e.g.
  `GenericGump.OnShown = fn`). Use the chain helpers (`Api.GenericGump.OnShown`,
  `Api.GumpsParsing.OnParsingCheck`, `Api.ObjectHandle.On*`) so multiple
  subscribers compose.
- **Raw `ipairs` / `pairs` / `for i = 1, #t` in a mod.** Use
  `Utils.Array.*` for arrays and `Utils.Table.*` for hash tables. Numeric
  `for i = 1, N` over an engine-supplied count is fine.