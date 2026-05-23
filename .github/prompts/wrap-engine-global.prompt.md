---
description: "Add a Mongbat-side wrapper for an engine global (WindowData.*, GenericGump, GumpsParsing, ObjectHandleWindow, wstring, etc.) so a mod can stop referencing the global directly."
argument-hint: "Engine global to wrap, and (optionally) the mod that needs it"
agent: "agent"
---

# Wrap an Engine Global

A mod needs something the framework doesn't expose. Add the wrapper to
`src/lib/**` first, then update the consuming mod. **Never** weaken
the boundary by referencing the global from the mod.

## Required Reading First

- [.github/copilot-instructions.md](../copilot-instructions.md) — the hard rule
- [.github/skills/mongbat-framework-dev/SKILL.md](../skills/mongbat-framework-dev/SKILL.md) — framework-side workflow
- `src/lib/api/MongbatApi*.lua` and `src/lib/api/MongbatData.lua` — search for an existing wrapper that resembles what
  you're adding (use that as the structural template)
- **Upstream default UI** — confirm the engine signature, default-UI usage,
  and any chaining contract before designing the wrapper:
  - Source: <https://github.com/loop-uc-ui/enhanced-client-default>
  - Docs:   <https://loop-uc-ui.github.io/enhanced-client-default-docs/>
  - Offline mirror: [`docs/`](../../docs/) (`InterfaceCore.txt`,
    `UO_GenericGump.txt`, `UO_DefaultWindow.txt`, `UO_StandardDialog.txt`,
    `singelinetextentry.txt`, `Interface.xsd`)

## Categorize the Global

| Engine surface | Wrapper namespace | Pattern |
|---|---|---|
| Engine functions (`WindowSetShowing`, `TextLogClear`, ...) | `Api.<Module>` | Thin pass-through with type annotations |
| `WindowData.<X>` tables | `Data.<X>` | Wrapper class with `:getData()` + typed nil-safe accessors |
| Default-UI module tables (`GenericGump`, `GumpsParsing`, ...) | `Api.<Module>` | Pass-through; chaining helpers for `OnX` callbacks |
| Default-UI lifecycle hooks (`ObjectHandleWindow.CreateObjectHandles`) | `Api.<Module>.On<Event>` | Chain helper that preserves prior subscribers + default-UI handler |
| `wstring`, `string` libraries | `Utils.String.*` | Type-dispatch on `string\|wstring` |
| Constants (`SystemData.Events.*`, gump ids, ...) | `Constants.<Group>` | Static table or accessor function |

## Procedure

1. **Find a structural template.** Pick an existing wrapper of the same
   category (e.g. for a new `Data.<X>`, model it on `Data.HealthBarColor`).
2. **Add the wrapper** in the matching framework file, usually one of the
  split `src/lib/api/MongbatApi*.lua` domain files for engine functions or
  `src/lib/api/MongbatData.lua` for `WindowData.*` accessors.
   - Make accessors **nil-safe**: handle missing `WindowData.<X>` and
     missing per-id entries.
   - For chain helpers (`OnShown`, `MainParsingCheck`, ...) preserve the
     previous handler so multiple subscribers compose.
   - For composite wrappers like `Data.WindowData()`, add the new accessor
     to `WindowDataWrapper` too.
3. **Add `---@class` / `---@field` annotations** when wrapping a `WindowData`
   table. Mirror the annotation style of neighbouring wrappers.
4. **Update the consuming mod** to use the new wrapper. Remove any
   `---@diagnostic disable: undefined-global` directive if present.
5. **Verify.** Run `get_errors` on:
   - The mod file → expect zero diagnostics.
   - The changed lib file → expect no NEW errors (existing engine-global
     warnings are by design and out of scope).
6. **Audit other mods** with `grep_search` for the same global; if they also
   reference it, migrate them too.

## Patterns

### Data wrapper (mirrors `Data.HealthBarColor`)

```lua
---@class WindowData.<X>
---@field <Field> <type>

---@class <X>Wrapper
---@field _id integer
local <X> = {}
<X>.__index = <X>

function <X>:new(id) return setmetatable({ _id = id }, self) end

---@return WindowData.<X>?
function <X>:getData()
    return WindowData.<X> and WindowData.<X>[self._id]
end

function <X>:get<Field>()
    local d = self:getData()
    return d and d.<Field>
end

function Data.<X>(id) return <X>:new(id) end
```

### Chain helper (mirrors `Api.GumpsParsing.OnParsingCheck`)

```lua
function Api.<Module>.<Hook>(fn)
    local previous = <Module>.<Method> or function() end
    <Module>.<Method> = function(...)
        previous(...)
        fn(...)
    end
end
```

### Lifecycle hook (mirrors `Api.ObjectHandle.OnCreate`)

```lua
function Api.<Module>.On<Event>(fn)
    if not <Module> then return end
    local previous = <Module>.<Method> or function() end
    <Module>.<Method> = function(...)
        previous(...)
        fn(...)
    end
end
```

Naming convention: any wrapper that **chains** a default-UI module method
is named `On<Event>` (no `Hook` verb) and lives on the relevant
`Api.<Module>` namespace. There is no separate `Mongbat.Hooks` bucket — a
lifecycle hook is just an Api wrapper whose body chains instead of calling
through.

## Anti-patterns

- Adding the wrapper as a one-shot in the mod (defeats the boundary).
- Skipping nil-safety because "the data is always there" — the engine fires
  events before all data tables exist.
- Naming the wrapper after the engine global (`Api.WindowData`) — pick the
  domain concept (`Data.PlayerStatus`, `Api.HealthBar`, ...).
- Forgetting to chain — overwriting `<Module>.<Method>` directly clobbers
  both the default UI and any other Mongbat subscriber.
