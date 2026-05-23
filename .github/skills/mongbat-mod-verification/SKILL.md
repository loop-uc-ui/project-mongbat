---
name: mongbat-mod-verification
description: "Use after changing any Mongbat mod in src/mods: verify diagnostics, boundary compliance, declarative Build usage, routed handlers, default-UI ownership patterns, deployment, and EC Lua log status before considering the mod change complete."
---

# Mongbat Mod Verification

## When to Use

- After editing or creating any file under `src/mods/**`.
- Before deploying a changed mod to EC.
- Before declaring a mod migration or refactor complete.
- When a mod works in the editor but fails in the client.

## Static Verification

1. Run `get_errors` on every changed mod Lua file. Result must be zero diagnostics.
2. Search changed mod files for forbidden globals:
   - `WindowData`, `SystemData`, `GenericGump`, `GumpsParsing`, `ObjectHandleWindow`
   - `InterfaceCore`, `HotbarSystem`, `ItemProperties`, `EquipmentData`
   - `wstring`, `WindowGetId`, `Debug`
3. Confirm no mod file adds `---@diagnostic disable: undefined-global`.
4. Confirm raw iteration follows the project rule:
   - `Utils.Array.*` for arrays.
   - `Utils.Table.*` for hash tables.
   - Numeric `for i = 1, N` only for engine-supplied counts.

## Declarative Build Verification

- Windows are emitted from `M.Build(emit)`, not imperatively created by the mod.
- Each emitted window has a distinct key.
- Parent windows are emitted before child windows.
- Routed handlers accept `(window, ...)` and branch on `window.key` or use `window.id`.
- Engine data is read inline in `M.Build` unless the work is truly engine-side mutation for `M.OnUpdate(dt)`.
- Conditional visibility uses either conditional emission or `showing = ...` intentionally:
  - Conditional emission destroys/recreates the subtree.
  - `showing = ...` keeps the window alive and toggles visibility.

## Default-UI Ownership Verification

- If the mod owns a fixed default-UI name, it destroys/suppresses the default behavior in `OnLoad` or uses `replacesDefault = true`.
- If the mod only reacts to default UI, it uses chain helpers such as `Api.GenericGump.OnShown` or `Api.GumpsParsing.OnParsingCheck`.
- If the mod overrides an action, it uses `Mongbat.UI.Defaults.OverrideAction`.
- If new engine surface is needed, the wrapper was added to `src/lib/**` first.

## Runtime Verification

1. Deploy with the `Deploy to EC` task or `deploy.ps1`.
2. Confirm deployment exits successfully.
3. Inspect the EC Lua log when a runtime issue is suspected.
4. Verify the affected window appears, updates, and handles expected events.
5. For routing issues, temporarily enable `Mongbat.Debugger.SetVerbose(true)`.

## Result Format

Report:

- `Diagnostics:` pass/fail and files checked.
- `Boundary:` pass/fail and any forbidden terms found.
- `Build pattern:` pass/fail for emits, parents, handlers.
- `Runtime:` deployed/not deployed; log checked/not checked.
- `Residual risk:` anything not verified in-client.
