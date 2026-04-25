# Mongbat

A Lua framework and mod collection for the **Ultima Online: Enhanced Client**
UI. Mongbat is a thin **router**: each mod is a Lua module table `M` that
registers windows via `Mongbat.CreateWindow{...}` and implements lifecycle
methods (`OnLoad`, `OnUnload`, `OnUpdate`, `On<Event>(name, key, ...)`).
The framework dispatches engine events on a window to its owning mod and
otherwise stays out of the way — mods own all state in plain Lua tables.

## Repository Layout

```
src/
  lib/                          The framework
    Mongbat.lua                 Substrate, Api, Data, Utils, Constants,
                                CreateWindow/RegisterWindow/...,
                                Mod/ModManager, EventHandler dispatch
    Mongbat.xml                 Window templates referenced by CreateWindow
    Mongbat.mod                 EC mod manifest
    *.dds                       Texture atlases
  mods/                         One folder per mod
    mongbat-<name>/
      Mongbat<Name>Mod.lua      Module table M + Mongbat.Mod{...} declaration
      Mongbat<Name>.mod         EC mod manifest
      [Mongbat<Name>.xml]       Optional per-mod templates
docs/                           Reference XSD + dumped default-UI XML
types/Engine.lua                Lua-LS type stubs for engine globals
Fonts/                          Embedded font definitions
.github/                        CI, copilot instructions, prompts, skills
```

## Framework Design

Mongbat draws a clear boundary between the framework and mod code. Engine
globals (`WindowData`, `SystemData`, `GenericGump`, `GumpsParsing`,
`ObjectHandleWindow`, `InterfaceCore`, `wstring`, `EquipmentData`, etc.) are
wrapped inside `src/lib/Mongbat.lua` and exposed to mods through:

- `Mongbat.Api` — engine function wrappers (`Api.Window.*`, `Api.Label.*`, …)
- `Mongbat.Data` — nil-safe typed accessors over `WindowData.*`
- `Mongbat.Utils` — `Utils.String` / `Utils.Table` / `Utils.Array`
- `Mongbat.Constants` — colors, window layers, gump IDs
- `Mongbat.Debugger` — `Print`, `Dump`, `PrintToChat`, `PrintToDebugConsole`
- Window registry — `Mongbat.CreateWindow`, `RegisterWindow`, `DestroyWindow`,
  `UnregisterWindow`, `GetWindow`

Mods interact only through these namespaces. When something isn't yet
exposed, the pattern is to add a wrapper to the lib and consume it from
the mod.

## Anatomy of a Mod (sketch)

A mod is a Lua module table `M` plus a `Mongbat.Mod{...}` declaration:

```lua
local Api = Mongbat.Api
local M = {}

function M.OnLoad()
    Mongbat.CreateWindow {
        name     = "MongbatExampleWindow",
        template = "MongbatWindow",
        module   = M,
        bindings = { "PlayerStatus" },   -- optional WindowData subscriptions
    }
end

function M.OnUnload()
    Mongbat.DestroyWindow("MongbatExampleWindow")
end

function M.OnLButtonUp(name, key, flags, x, y) ... end
function M.OnUpdatePlayerStatus(name, key, data) ... end

Mongbat.Mod {
    Name   = "MongbatExample",
    Path   = "/src/mods/mongbat-example",
    Module = M,
}
```

The full mod-authoring workflow — lifecycle method reference,
`CreateWindow` options, every `Data.*` wrapper, iteration helpers, the
`Api.Window.Destroy` vs chain-helper distinction, anti-patterns, and
canonical example mods — lives in
[.github/skills/mongbat-mod-authoring/SKILL.md](.github/skills/mongbat-mod-authoring/SKILL.md).

### Notable Api Wrappers

- `Api.GenericGump.OnShown(fn)` / `Api.GenericGump.GetLastLabels()`
- `Api.GumpsParsing.SetGumpName(id, name)` / `SuppressGump(id)`
- `Api.HealthBar.BeginDrag(id)`
- `Api.Window.GetActiveName()`
- `Utils.String.Lower/Upper/Len/Find/IsEmpty` — type-dispatched on
  `string|wstring`, preserving input type.
- `Mongbat.Debugger.Print/Dump/PrintToChat/PrintToDebugConsole` — wraps
  `Debug.*` for ad-hoc debug output from both lib and mod code.

## Building & Deploying

The repo is the source of truth; the EC loads UI from a separate folder:

```
C:\Program Files (x86)\Electronic Arts\
  Ultima Online Enhanced\UserInterface\project-mongbat
```

Changes are **not live until copied there** (Program Files writes require
admin). Always verify the deployed file matches the repo before debugging.

## Type Checking

`types/Engine.lua` provides Lua Language Server stubs for engine globals,
configured by `.luarc.json`. **Mod files should produce zero diagnostics.**
Lib-side warnings about undefined engine globals are expected — the lib is
where those globals legally live.

## Default-UI Reference (Upstream Ground Truth)

The Enhanced Client default UI is the source of truth for how the engine
actually behaves. When wrapping a new engine global or debugging an
unexpected interaction, consult upstream **before** inventing a mechanism:

- **Source:** <https://github.com/loop-uc-ui/enhanced-client-default>
- **Docs:**   <https://loop-uc-ui.github.io/enhanced-client-default-docs/>

The [`docs/`](docs/) folder mirrors a few engine-level files extracted from
the EC binary (`InterfaceCore.txt`, `UO_GenericGump.txt`,
`UO_DefaultWindow.txt`, `UO_StandardDialog.txt`, `singelinetextentry.txt`,
`Interface.xsd`) — these are not in the upstream repo. The
[research-default-ui SKILL](.github/skills/research-default-ui/SKILL.md)
documents how to fetch source and look things up.
