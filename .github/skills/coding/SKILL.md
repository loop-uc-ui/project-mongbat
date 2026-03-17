---
name: coding
description: 'Coding conventions for Mongbat mods. USE WHEN: writing new mod code, reviewing code style, adding type annotations, or choosing between raw Lua and framework utilities.'
---

# Coding

## Use the Framework

All mod code goes through `Mongbat` and its namespaces. Do not call engine globals directly — use `Api`, `Data`, `Components`, `Constants`, and `Utils`.

```lua
-- Wrong
WindowSetShowing("MyWindow", true)

-- Right
Api.Window.SetShowing("MyWindow", true)
```

## Use Utils for Primitives and Tables

Prefer `Mongbat.Utils` over raw Lua table/string operations. Use `Utils.Array`, `Utils.String`, and `Utils.Table` — read the source in `Mongbat.lua` to see what's available.

## Type Annotations

Add `---@type`, `---@param`, `---@return`, and `---@class` annotations wherever the IDE cannot infer the type — especially for:
- Variables assigned from engine data or `Data.*()` calls
- Callback parameters in bindings
- Tables with known structure
- Forward-declared locals

```lua
---@type wstring
local titleText = L"Shop"

---@param playerStatus PlayerStatusWrapper
local function onUpdate(playerStatus) end
```

Do not annotate what the IDE already understands (simple locals, literal assignments, standard returns).

## Lua Style

- Local everything. No unscoped globals.
- Use `local function` for helpers. Use closures for state.
- Prefer early returns over deep nesting.
- One concern per function. Keep functions short.
- Name booleans as questions: `isSelling`, `hasItems`.
- Name callbacks by what they respond to: `onPlayerStatus`, `onShutdown`.
- Constants in `UPPER_SNAKE_CASE` as file-scope locals.
- No trailing whitespace. Indent with tabs or spaces per `.editorconfig`.
