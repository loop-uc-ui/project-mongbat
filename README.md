# Mongbat

Mongbat is a Lua framework and mod collection for the **Ultima Online:
Enhanced Client** UI. It provides a small declarative UI layer over the EC
window system, plus a set of replacement and quality-of-life mods built on top
of that layer.

The framework lives in `src/lib/`. Mods live in `src/mods/mongbat-<name>/`.

## What Mongbat Provides

- A declarative `M.Build(emit)` model for creating, updating, and destroying EC
  windows.
- Routed window events: engine events are delivered to the owning mod as
  `M.On<Event>(window, ...)`, where `window.key`, `window.name`, `window.id`,
  and `window.rootKey` describe the emitted window.
- Framework wrappers for EC globals through `Mongbat.Api`, `Mongbat.Data`,
  `Mongbat.UI`, `Mongbat.Utils`, `Mongbat.Constants`, and
  `Mongbat.Debugger`.
- Automatic `WindowData` registration for emitted windows, including ref-counted
  cleanup when windows leave the emitted set.
- Built-in support for draggable, snappable, and resizable declarative windows.
- A hard boundary that keeps direct EC globals out of mods.

## Repository Layout

```text
src/
  lib/
    Mongbat.lua                 Public bootstrap and mod registration
    Mongbat.mod                 Framework EC manifest
    Mongbat.xml                 Shared XML templates and textures
    api/                        Api wrappers around EC functions
    core/                       Utils, constants, debugger, internal setup
    systems/                    Build, router, registry, data, snap, resize
    ui/                         Declarative widget builders and default UI helpers
  mods/
    mongbat-<name>/             One EC mod per folder
      Mongbat<Name>.mod         Mod manifest
      Mongbat<Name>Mod.lua      Module table, Build, handlers, declaration
docs/                           Local EC/default-UI reference files
Fonts/                          Bundled font definitions
types/                          Lua language server stubs for EC globals
.github/skills/                 Detailed project workflows for agents/contributors
```

## Included Mods

| Mod | Purpose |
|---|---|
| `mongbat-main-menu` | Replaces `MainMenuWindow` with a Mongbat-styled vertical menu. |
| `mongbat-player-status` | Replaces the default status window with a resizable HP/mana/stamina panel. |
| `mongbat-map` | Replaces `MapWindow` with a resizable radar map, panning, wheel zoom, and coordinates. |
| `mongbat-object-handle` | Replaces object handles with declarative floating labels for mobiles and items. |
| `mongbat-paperdoll` | Replaces the player paperdoll with grid and figure modes. |
| `mongbat-debug` | Replaces the debug window with full and filtered log views. |
| `mongbat-distance-counter` | Shows cursor distance while targeting. |
| `mongbat-classic-vendor-search` | Forces vendor search gumps through the classic GenericGump path and recolors labels. |
| `mongbat-suppress-pet-training-gump` | Suppresses the pet training progress gump. |

## Framework Model

Mods do not create or destroy windows imperatively. Each frame, the framework
calls `M.OnUpdate(dt)` if present, then `M.Build(emit)`. The mod emits the set
of windows it wants to exist for that frame:

```lua
local UI = Mongbat.UI

local M = {}

function M.Build(emit)
    emit("panel", {
        template  = "MongbatWindow",
        draggable = true,
        widget    = UI.Window():setDimensions(220, 120),
    })

    emit("label", {
        template = "MongbatLabel",
        parent   = "panel",
        widget   = UI.Label()
            :setText("Hello")
            :setDimensions(180, 24)
            :setOffsetFromParent(20, 20),
    })
end

function M.OnLButtonUp(window, flags, x, y)
    if window.key == "label" then
        -- handle the click
    end
end

Mongbat.Mod {
    Name   = "MongbatExample",
    Path   = "/src/mods/mongbat-example",
    Module = M,
}
```

The Build system diffs the emitted set against the previous frame. New keys are
created, existing keys are re-applied, and missing keys are destroyed. Child
windows use `parent = "someKey"`, not engine names.

## Mod Boundary

Mods should only use the Mongbat public surface:

- `Mongbat.Api` for wrapped EC functions.
- `Mongbat.Data` for nil-safe `WindowData` accessors.
- `Mongbat.UI` for declarative widgets.
- `Mongbat.Utils.String`, `Mongbat.Utils.Table`, `Mongbat.Utils.Array`, and
  `Mongbat.Utils.Number` for common helpers.
- `Mongbat.Constants` for colors, layers, IDs, and other shared constants.
- `Mongbat.Debugger` for debug output.
- `Mongbat.UI.Defaults` for default-UI suppression and action overrides.

Direct EC globals such as `WindowData`, `SystemData`, `GenericGump`,
`GumpsParsing`, `ObjectHandleWindow`, `InterfaceCore`, `wstring`, `WindowGetId`,
and `Debug` belong in `src/lib/**`, not in mods. If a mod needs engine behavior
that is not wrapped yet, add the wrapper to the framework first.

## Developing

1. Edit files under `src/`.
2. Run diagnostics in VS Code. Changed mod files should have zero diagnostics.
3. Deploy to the EC UI folder with the `Deploy to EC` task.
4. Test in the Enhanced Client.
5. If the client fails at runtime, read the EC Lua log first and trace the
   earliest error.

Deployment copies `.lua`, `.xml`, `.mod`, and `.dds` files from `src/` to:

```text
C:\Program Files (x86)\Electronic Arts\Ultima Online Enhanced\UserInterface\project-mongbat
```

Text files should be written as UTF-8 without BOM. This matters because the EC
Lua runtime cannot parse a UTF-8 BOM at the start of Lua files.

## Default UI Reference

When wrapping new engine behavior or debugging client behavior, compare against
the default UI before inventing a mechanism.

- Source: <https://github.com/loop-uc-ui/enhanced-client-default>
- Docs: <https://loop-uc-ui.github.io/enhanced-client-default-docs/>
- Local mirror: [`docs/`](docs/)

The local `docs/` folder includes EC files that are not available in the public
default-UI repository, such as `InterfaceCore.txt`, `UO_GenericGump.txt`,
`UO_DefaultWindow.txt`, `UO_StandardDialog.txt`, `singelinetextentry.txt`, and
`Interface.xsd`.

## Contributor Notes

The detailed project workflows live under `.github/skills/`:

- [Mod authoring](.github/skills/mongbat-mod-authoring/SKILL.md)
- [Framework development](.github/skills/mongbat-framework-dev/SKILL.md)
- [Mod verification](.github/skills/mongbat-mod-verification/SKILL.md)
- [Runtime error recovery](.github/skills/mongbat-error-recovery/SKILL.md)
- [Default UI research](.github/skills/research-default-ui/SKILL.md)

Those files are more prescriptive than this README. The README is the overview;
the skills are the working checklists.
