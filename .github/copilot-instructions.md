# Project Guidelines — Mongbat

Mongbat is a Lua framework + mod collection for the **Ultima Online: Enhanced
Client** UI. The framework lives in `src/lib/Mongbat.lua`; mods live in
`src/mods/mongbat-<name>/`. See [README.md](../README.md) for full
orientation.

## The Hard Rule (read this first)

**Mods must never reference engine globals directly.** All engine surface
area lives only in `src/lib/Mongbat.lua`, exposed through:

- `Mongbat.Api` — wraps engine functions (`Api.Window.*`, `Api.Label.*`, ...)
- `Mongbat.Data` — wraps `WindowData.*` with nil-safe typed accessors
- `Mongbat.Utils` — `Utils.String/Table/Array` (string utils dispatch on
  `string|wstring`)
- `Mongbat.Constants` — `Constants.Colors`, `WindowLayers`, `GumpIds`, etc.
- `Mongbat.Debugger` — wraps `Debug.*` (`Print`, `PrintToChat`,
  `PrintToDebugConsole`, `Dump`, `DumpToConsole`)
- `Mongbat.CreateWindow` / `RegisterWindow` / `DestroyWindow` /
  `UnregisterWindow` / `GetWindow` — window registry helpers.

Default-UI module lifecycle entry points (e.g.
`ObjectHandleWindow.CreateObjectHandles`, `GenericGump.OnShown`,
`GumpsParsing.MainParsingCheck`) are exposed as `Api.<Module>.On<Event>`
chain helpers — they preserve prior subscribers and the default-UI''s own
handler so multiple consumers compose.

Forbidden in `src/mods/**`: `WindowData`, `SystemData`, `GenericGump`,
`GumpsParsing`, `ObjectHandleWindow`, `InterfaceCore`, `HotbarSystem`,
`ItemProperties`, `EquipmentData`, `wstring`, `WindowGetId`, `Debug`, etc.

If you need something the lib doesn''t expose, **add the wrapper to the lib
first**, then consume it. Never silence the boundary with
`---@diagnostic disable: undefined-global` in a mod — that flag means the
boundary leaked.

## Architecture: Router + Module

Mongbat is a **router**. The lib maintains a `name -> { module, key }`
registry. When the engine fires an event on a window, the lib looks up the
window''s owning mod and calls the matching method on that mod''s module
table:

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

## Mod Shape (one-liner)

A mod is a Lua module table `M` plus a `Mongbat.Mod{...}` declaration. It
implements only the lifecycle methods it needs (`OnLoad`, `OnUnload`,
`OnUpdate(dt)`, `On<Event>(name, key, ...)`, `OnUpdate<DataKey>(name, key, data)`).
Windows are registered via `Mongbat.CreateWindow{ name, template, module=M, key?, parent?, bindings? }`.

**For the full mod-authoring workflow** (skeleton, lifecycle method
reference, `CreateWindow` options, data wrapper reference, iteration
helpers, `Api.Window.Destroy` vs chain helpers, anti-patterns), read
[.github/skills/mongbat-mod-authoring/SKILL.md](skills/mongbat-mod-authoring/SKILL.md).
Canonical example mods are linked there too.

## Workflow Rules

1. **Distinct windows need unique names; routed events arrive with `key`.**
   Pass `key = "..."` to `Mongbat.CreateWindow` and dispatch on it inside
   `M.On*` methods. The lib uses `name` itself as the default key.
2. **`Bindings` over `OnUpdate`.** Pass `bindings = { "PlayerStatus" }` to
   `Mongbat.CreateWindow` and implement `M.OnUpdatePlayerStatus`. Use
   mod-level `M.OnUpdate(dt)` only for true per-frame work (animations,
   mouse-position polling, things the engine doesn''t notify about).
3. **`Api.Window.Destroy` to own a default-UI window''s name.** Call
   `Api.Window.Destroy("DefaultWindowName")` at the top of `M.OnLoad()`
   before creating your replacement. Use `Api.<Module>.On<Event>` chain
   helpers to react to default-UI module lifecycle entry points (e.g.
   `Api.ObjectHandle.OnCreate`, `Api.GenericGump.OnShown`,
   `Api.GumpsParsing.OnParsingCheck`).
4. **Wrapper-first.** When a mod needs an engine global, stop and add the
   wrapper to `src/lib/Mongbat.lua` before continuing.
5. **Verify with `get_errors`.** After any mod edit, mod files must have
   **zero** diagnostics. Lib pre-existing engine-global / `wstring`
   warnings are expected and out of scope.
6. **No raw `ipairs` / `pairs` / `for i = 1, #t` in mods.** Use
   `Utils.Array.*` for arrays and `Utils.Table.*` for hash tables. Numeric
   `for i = 1, N` over an engine-supplied count (e.g. `GetNumEntries`,
   paperdoll slots) is fine.

## Default-UI Ground Truth

When wrapping a new engine global or debugging unexpected engine behaviour,
consult upstream first — never invent a mechanism the default UI doesn''t use.

- Source: <https://github.com/loop-uc-ui/enhanced-client-default>
- Docs:   <https://loop-uc-ui.github.io/enhanced-client-default-docs/>
- Local mirror of frequently-referenced files: [`docs/`](../docs/).

## UTF-8 BOM Gotcha

VS Code or external tools may silently add a UTF-8 BOM (`EF BB BF`) to
`Mongbat.lua`. The EC Lua runtime cannot parse it — the error is
`unexpected symbol near ''`` on line 1, which cascades to every mod failing
with `attempt to index global ''Mongbat'' (a nil value)`. Save as **UTF-8**
(not "with BOM").

## Slash Commands

- `/new-mod` — scaffold a new mod
- `/wrap-engine-global` — add a Mongbat wrapper for an engine global
- `/audit-mod` — find direct engine-global references in a mod
- `/mongbat-mod-authoring` — full mod-authoring workflow skill
- `/research-default-ui` — look up how the default UI handles something (fetch source, check lifecycle, verify globals)
