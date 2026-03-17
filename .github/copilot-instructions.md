# Mongbat

Mongbat is a Lua framework for modifying Ultima Online's Enhanced Client UI. It wraps the default UI engine with a component-based architecture using metatables for inheritance.

## Principles

- Make all changes with the broader framework in mind. A change to a component, utility, or pattern may affect every mod that uses it.
- Do not make assumptions about engine behavior. When uncertain about how the Enhanced Client engine works, ask the user before proceeding.
- The engine runs an older Lua (5.1-era). There is no `require` — all files are loaded via XML manifests. Metatables are used for class inheritance.
- Wstrings use the `L""` literal syntax provided by the engine. Plain Lua strings and wstrings are not interchangeable.

## Structure

- `src/lib/Mongbat.lua` — The framework: components, API wrappers, event dispatch, utilities.
- `src/mods/` — Each subfolder is a self-contained mod with a `.mod` manifest, an XML file, and a Lua entry point.
- `types/` — LuaLS type annotations for engine globals.
- `docs/` — Reference material from the default UI.

## Namespaces

All accessed via the global `Mongbat` table:

- `Components` — UI constructors (`Scaffold`, `Window`, `Label`, `Button`, `StatusBar`, `ScrollWindow`, etc.) and `Components.Defaults` for wrapping built-in windows.
- `Api` — Direct engine API calls (`Api.Window`, `Api.Label`, `Api.DynamicImage`, `Api.Event`, etc.).
- `Data` — Typed data accessors wrapping engine `WindowData` (`Data.PlayerStatus()`, `Data.MobileName(id)`, etc.).
- `Constants` — Enumerations: colors, event names, broadcast IDs, notoriety colors.
- `Utils` — Helpers: `Utils.Array`, `Utils.String`, `Utils.Table`.
