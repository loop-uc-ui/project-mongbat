---
description: "Scaffold a new Mongbat mod with the current declarative router pattern (module-table M, M.Build(emit), routed lifecycle/event methods, Mongbat.Mod{} declaration, .mod manifest)."
argument-hint: "Mod name in PascalCase (e.g. CombatTimer) and a one-line purpose"
agent: "agent"
---

# New Mongbat Mod

Scaffold a new mod under `src/mods/mongbat-<kebab-name>/`. The user will
provide a PascalCase name and a one-line purpose; ask if they didn't.

## Required Reading First

Read these to anchor on the current pattern (do not skip):
- [.github/copilot-instructions.md](../copilot-instructions.md) — the hard rule and mod shape
- [src/mods/mongbat-distance-counter/MongbatDistanceCounterMod.lua](../../src/mods/mongbat-distance-counter/MongbatDistanceCounterMod.lua) — canonical single-window Build example
- [src/mods/mongbat-debug/MongbatDebugMod.lua](../../src/mods/mongbat-debug/MongbatDebugMod.lua) — stateful conditional showing + handlers
- A neighbor `*.mod` manifest, e.g.
  [src/mods/mongbat-distance-counter/MongbatDistanceCounter.mod](../../src/mods/mongbat-distance-counter/MongbatDistanceCounter.mod)

## Procedure

1. **Derive names.** PascalCase `<Name>` → folder `mongbat-<kebab>`, lua
   file `Mongbat<Name>Mod.lua`, manifest `Mongbat<Name>.mod`, mod-id
   `Mongbat<Name>`.
2. **Create the folder** `src/mods/mongbat-<kebab>/`.
3. **Create the `.mod` manifest** by copying a neighbor's manifest and
   renaming references. If the mod needs templates, also create
   `Mongbat<Name>.xml`.
4. **Create the lua file.** Use the module-table skeleton (see below).
   Decide:
   - Does it call `Api.Window.Destroy` to own a default-UI window's name?
   - Does it need `M.Build(emit)` windows, or is it a hook-only mod?
   - Does it need `M.OnUpdate(dt)`? (true per-frame engine-side work only — animations,
     radar panning, mouse polling)
   - Does it need any windows at all? (suppression / chain-helper-only mods don't)
5. **Reference only `Mongbat.{Api,Data,Utils,Constants,Debugger,UI,GetWindow,Mod}`.**
   If you find yourself wanting `WindowData`, `GenericGump`, `wstring`,
   `ObjectHandleWindow`, `Debug`, etc., **stop** and run `/wrap-engine-global` first.
6. **Verify.** Run `get_errors` on the new file; expect zero diagnostics.

## Skeleton

```lua
-- <One-paragraph purpose: what it does, what it owns/replaces, the update
-- strategy. Match the comment style of mongbat-distance-counter.>

local Api       = Mongbat.Api
local Data      = Mongbat.Data
local UI        = Mongbat.UI
local Utils     = Mongbat.Utils
local Constants = Mongbat.Constants

local M = {}
local state = { ... }

function M.OnLoad()
    -- Api.Window.Destroy("DefaultUiWindowName")  -- optional; omit if not replacing a default window
end

function M.Build(emit)
  emit("panel", {
    template = "MongbatWindow",
    widget   = UI.Window()
      :setDimensions(200, 100),
  })

  emit("label", {
    template = "MongbatLabel",
    parent   = "panel",
    widget   = UI.Label()
      :setText("Hello")
      :onlyOnCreate()
        :clearAnchors()
        :addAnchor("topleft", "panel", "topleft", 8, 8),
  })
end

-- function M.OnUpdate(dt)            -- per-frame; only define if needed
-- function M.OnLButtonUp(window)      -- routed mouse events arrive with window.key / window.id

Mongbat.Mod {
    Name   = "Mongbat<Name>",
    Path   = "/src/mods/mongbat-<kebab>",
    Module = M,
}
```

## Anti-patterns to Avoid

- Direct engine globals (`WindowData`, `wstring`, ...). Add wrappers first.
- `L"..."` wstring literals — `L` is undefined. Use `Utils.String.ToWString("...")`.
- Imperative window creation from mods — windows go through `M.Build(emit)`.
- `M.OnUpdate(dt)` for engine-data polling — read `Mongbat.Data` inline in `M.Build`.
- Re-using a window `name` across mods — names are registry keys.
- Creating/destroying Build-owned windows in `M.OnLoad` / `M.OnUnload`.
- `---@diagnostic disable: undefined-global` — boundary violation marker.
