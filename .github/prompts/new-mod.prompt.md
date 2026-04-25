---
description: "Scaffold a new Mongbat mod with the router pattern (module-table M with lifecycle methods, Mongbat.CreateWindow registration, Mongbat.Mod{} declaration, .mod manifest)."
argument-hint: "Mod name in PascalCase (e.g. CombatTimer) and a one-line purpose"
agent: "agent"
---

# New Mongbat Mod

Scaffold a new mod under `src/mods/mongbat-<kebab-name>/`. The user will
provide a PascalCase name and a one-line purpose; ask if they didn't.

## Required Reading First

Read these to anchor on the current pattern (do not skip):
- [.github/copilot-instructions.md](../copilot-instructions.md) — the hard rule and mod shape
- [src/mods/mongbat-distance-counter/MongbatDistanceCounterMod.lua](../../src/mods/mongbat-distance-counter/MongbatDistanceCounterMod.lua) — canonical single-window example
- [src/mods/mongbat-debug/MongbatDebugMod.lua](../../src/mods/mongbat-debug/MongbatDebugMod.lua) — stateful with bindings + handlers
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
   - Does it need `bindings`? (reacting to engine data — preferred over polling)
   - Does it need `M.OnUpdate(dt)`? (true per-frame work only — animations,
     mouse polling)
   - Does it need any windows at all? (suppression / chain-helper-only mods don't)
5. **Reference only `Mongbat.{Api,Data,Utils,Constants,Debugger,CreateWindow,RegisterWindow,DestroyWindow,UnregisterWindow,GetWindow,Mod}`.**
   If you find yourself wanting `WindowData`, `GenericGump`, `wstring`,
   `ObjectHandleWindow`, `Debug`, etc., **stop** and run `/wrap-engine-global` first.
6. **Verify.** Run `get_errors` on the new file; expect zero diagnostics.

## Skeleton

```lua
-- <One-paragraph purpose: what it does, what it owns/replaces, the update
-- strategy. Match the comment style of mongbat-distance-counter.>

local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Utils     = Mongbat.Utils
local Constants = Mongbat.Constants

local NAME = "Mongbat<Name>Window"

local M = {}
local state = { ... }

function M.OnLoad()
    -- Api.Window.Destroy("DefaultUiWindowName")  -- optional; omit if not replacing a default window
    Mongbat.CreateWindow {
        name     = NAME,
        template = "MongbatWindow",
        module   = M,
        key      = "panel",
        -- bindings = { "PlayerStatus" },   -- optional
    }
    Api.Window.SetDimensions(NAME, 200, 100)
end

function M.OnUnload()
    Mongbat.DestroyWindow(NAME)
end

-- function M.OnUpdate(dt)            -- per-frame; only define if needed
-- function M.OnLButtonUp(_name, key) -- routed mouse events arrive with key
-- function M.OnUpdatePlayerStatus(_name, _key, data)  -- one per binding key

Mongbat.Mod {
    Name   = "Mongbat<Name>",
    Path   = "/src/mods/mongbat-<kebab>",
    Module = M,
}
```

## Anti-patterns to Avoid

- Direct engine globals (`WindowData`, `wstring`, ...). Add wrappers first.
- `L"..."` wstring literals — `L` is undefined. Use `Utils.String.ToWString("...")`.
- `M.OnUpdate(dt)` for engine-data polling — use `bindings` + `M.OnUpdate<Key>`.
- Re-using a window `name` across mods — names are registry keys.
- Forgetting `Mongbat.DestroyWindow(NAME)` in `M.OnUnload`.
- `---@diagnostic disable: undefined-global` — boundary violation marker.
