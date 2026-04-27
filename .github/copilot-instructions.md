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
- `Mongbat.UI` — declarative widget builders (Window, Label, Button,
  DynamicImage, EditBox, TextLog) used inside `M.Build(emit)`
- `Mongbat.GetWindow(engineName)` — registry lookup (rarely needed)

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

## Architecture: Declarative Build + Router

Mongbat is a **declarative reconciler + router**. Each frame the lib calls
`M.OnUpdate(dt)` then `M.Build(emit)` on every loaded mod. The mod calls
`emit(key, spec)` once per window it wants this frame. The lib diffs the
emitted set against the prior frame: new keys → create + register,
existing keys → re-apply widget ops, missing keys → destroy.

When the engine fires an event on a window, the lib looks up the window's
owning mod and calls the matching method on that mod's module table:

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

Mods own all state. The lib holds no closures.

## Mod Shape (one-liner)

A mod is a Lua module table `M` plus a `Mongbat.Mod{...}` declaration. It
implements `M.Build(emit)` for windows and any lifecycle / event methods
it needs (`OnLoad`, `OnUnload`, `OnUpdate(dt)`, `On<Event>(name, key, ...)`).
Windows are emitted declaratively via `emit(key, { template, widget, parent?, name?, id?, showing?, replacesDefault? })`.

**For the full mod-authoring workflow** (skeleton, `M.Build` reference,
spec fields, `Mongbat.UI` widget reference, data wrapper reference,
iteration helpers, `Api.Window.Destroy` vs chain helpers, anti-patterns),
read [.github/skills/mongbat-mod-authoring/SKILL.md](skills/mongbat-mod-authoring/SKILL.md).
Canonical example mods are linked there too.

## Workflow Rules

1. **Windows go through `M.Build(emit)`.** Don't call any imperative
   create/destroy helper from a mod — they no longer exist. Conditional
   emission is the way to show/hide: skip a key in a frame and the lib
   destroys it; re-emit later to recreate. Cheap.
2. **Distinct windows need distinct keys; routed events arrive with `key`.**
   The default engine name is `<modName>_<key>` (sanitized). Override
   `name=` only when hijacking a fixed default-UI name (e.g.
   `"MainMenuWindow"`, `"MapWindow"`); pair with `replacesDefault = true`.
3. **Read engine data inline inside `M.Build`.** `Data.PlayerStatus():getCurrentHealth()`
   etc. — the lib auto-registers every WindowData type for every emitted
   window's id, so it populates each frame with no per-key opt-in. For
   per-mobile data (`MobileName`, `MobileStatus`, `HealthBarColor`,
   `Paperdoll`), pass `id = mobileId` in the spec so
   `Mongbat.Data.MobileName(mobileId):getName()` resolves. The lib
   ref-counts each `(dataKey, id)` pair and unregisters when the last
   window using that id is destroyed. Use mod-level `M.OnUpdate(dt)` only
   for engine-side mutations that aren't expressible as widget setters
   (e.g. radar pan / drag deltas).
4. **`Api.Window.Destroy` to own a default-UI window's name.** Call
   `Api.Window.Destroy("DefaultWindowName")` at the top of `M.OnLoad()`,
   then emit your replacement under the same `name` with
   `replacesDefault = true`. Use `Api.<Module>.On<Event>` chain helpers
   (`Api.ObjectHandle.OnCreate`, `Api.GenericGump.OnShown`,
   `Api.GumpsParsing.OnParsingCheck`) when you only need to react to
   default-UI lifecycle without owning a window.
5. **Wrapper-first.** When a mod needs an engine global, stop and add the
   wrapper to `src/lib/Mongbat.lua` before continuing.
6. **Verify with `get_errors`.** After any mod edit, mod files must have
   **zero** diagnostics. Lib pre-existing engine-global / `wstring`
   warnings are expected and out of scope.
7. **No raw `ipairs` / `pairs` / `for i = 1, #t` in mods.** Use
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
