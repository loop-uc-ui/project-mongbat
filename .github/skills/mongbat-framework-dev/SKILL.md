---
name: mongbat-framework-dev
description: "Use when editing Mongbat framework code in src/lib: adding Api wrappers, Data accessors, UI widget operations, Build/Router/Registry/Snap/Resize behavior, default-UI suppression helpers, or framework refactors. Distinguishes lib-side work from mod authoring and requires default-UI research for engine semantics."
---

# Mongbat Framework Development

## When to Use

- Adding or changing `Mongbat.Api`, `Mongbat.Data`, `Mongbat.UI`, `Mongbat.Constants`, `Mongbat.Debugger`, or `Mongbat.UI.Defaults`.
- Editing framework systems under `src/lib/systems/` such as Build, Router, Registry, DataReg, Snap, Resize, Drag, or Mods.
- Moving wrappers, splitting framework files, or changing module manifests.
- Fixing framework behavior that affects more than one mod.

Do **not** use this for ordinary mod work in `src/mods/**`; use `mongbat-mod-authoring` instead.

## Boundary Model

- Engine globals belong only in framework code under `src/lib/**`.
- Mods consume engine behavior through `Mongbat.Api`, `Mongbat.Data`, `Mongbat.UI`, `Mongbat.Constants`, `Mongbat.Debugger`, and `Mongbat.UI.Defaults`.
- If a mod needs an engine global, add or extend the wrapper first, then update the mod.
- Never move raw `WindowData`, `SystemData`, `wstring`, `Debug`, or default-UI module references into `src/mods/**`.

## Framework Map

| Area | Files |
|---|---|
| Bootstrap/public surface | `src/lib/Mongbat.lua`, `src/lib/Mongbat.mod` |
| Api wrappers | `src/lib/api/MongbatApi.lua` bootstrap plus `MongbatApiWidgets/Input/World/System/DefaultUI.lua`, loaded by `src/lib/api/MongbatApi.mod` |
| Data wrappers | `src/lib/api/MongbatData.lua`, `src/lib/api/MongbatData.mod` |
| UI builders/defaults | `src/lib/ui/MongbatUI.lua`, `src/lib/ui/MongbatDefaults.lua`, `src/lib/ui/MongbatUI.mod` |
| Core helpers | `src/lib/core/MongbatUtils.lua`, `MongbatConstants.lua`, `MongbatDebugger.lua`, `MongbatInternal.lua` |
| Runtime systems | `src/lib/systems/MongbatBuild.lua`, `MongbatRouter.lua`, `MongbatRegistry.lua`, `MongbatDataReg.lua`, `MongbatSnap.lua`, `MongbatResize.lua`, `MongbatDrag.lua`, `MongbatMods.lua` |
| Templates/assets | `src/lib/Mongbat.xml`, `*.dds` |

## Adding an `Api.*` Wrapper

1. Search the split `src/lib/api/MongbatApi*.lua` files for a nearby wrapper namespace.
2. Check default-UI usage with `research-default-ui` to confirm function name, argument order, and lifecycle.
3. Add the wrapper to the appropriate namespace. Keep it thin unless nil-safety is necessary to avoid EC crashes.
4. Add Lua annotations for parameters and return values.
5. Update mods to call the wrapper, not the engine global.
6. Run `get_errors` on changed lib and mod files.

## Adding a `Data.*` Wrapper

1. Identify the `WindowData.<Key>` table and whether it is singleton or id-indexed.
2. Confirm registration requirements in default UI or docs.
3. Add nil-safe getters. Missing data should return a stable default, not crash.
4. Ensure `DataReg` knows how to register/unregister the data type if emitted windows need it.
5. Use method-call style in mods: `Data.MobileName(id):getName()`.

## Changing Build/Router Behavior

Before editing `MongbatBuild.lua` or `MongbatRouter.lua`:

- Read the top-of-file contract and the registry flow.
- Preserve routed handler shape: `M.On<Event>(window, ...)`, where `window` exposes `name`, `engineName`, `key`, `id`, and `rootKey`.
- Preserve sibling-key resolution and parent-before-child emit order.
- Keep `M.Build(emit)` declarative; do not reintroduce imperative create/destroy helpers for mods.
- If a behavior differs from default UI, document why.

## Default-UI Research Requirement

Use `research-default-ui` before changing framework behavior involving:

- Window creation, destruction, anchors, movement, resize, save/restore position.
- `WindowData` registration or unregister timing.
- Default-UI module callbacks and action overrides.
- Gump parsing, object handles, paperdoll, map/radar, or status windows.

Record what default UI does in the commit summary or final response.

## Verification

- Run `get_errors` on every changed framework file and every changed mod file.
- Framework files may have expected engine-global diagnostics; do not claim success solely from zero diagnostics unless it is actually zero.
- For mod files, diagnostics must be zero.
- Deploy when runtime behavior changed.
- If the change affects event routing, temporarily enable `Mongbat.Debugger.SetVerbose(true)` while testing.

## Anti-Patterns

- Adding a broadcast or fallback dispatch path before proving the registered route failed.
- Hiding a boundary leak with `---@diagnostic disable: undefined-global` in a mod.
- Making a large refactor while a runtime bug is still unexplained.
- Rewriting default-UI lifecycle from memory instead of reading the source.
- Leaving generated or stale framework copies that can drift from canonical files.
