---
name: mongbat-error-recovery
description: "Use when Mongbat fails at runtime: Lua error log, mod not loading, window not appearing, routed event not firing, resize/snap/layout behaving unexpectedly, or a previous agent fix made things worse. Starts with exact error-log tracing and default-UI comparison before changing code."
---

# Mongbat Error Recovery

## When to Use

- The EC Lua log reports an error after a Mongbat change.
- A mod no longer loads, or every mod fails after a framework edit.
- A window is missing, hidden unexpectedly, clipped, not receiving events, or not resizing/moving correctly.
- A previous fix failed or made the behavior worse.
- You are tempted to add timing guards, broadcasts, fallback dispatch, or other new mechanisms to explain engine behavior.

## Recovery Rules

1. **Read the error log first.** Do not start with a theory. If the log path is configured in `.env`, inspect that file; otherwise ask the user for the current EC Lua log location.
2. **Trace the exact code path.** Follow the failing function call line by line through the wrapper, subsystem, mod, and default-UI callback involved.
3. **After one failed fix, stop.** Re-read the log and re-trace the path before attempting a second fix.
4. **Prefer removal over invention.** If a helper, callback, or cache layer is causing the problem, ask whether it needs to exist at all.
5. **Match default UI before inventing.** Use `research-default-ui` whenever the behavior depends on EC engine semantics.

## First Checks

1. Confirm which file changed most recently and whether the working tree is dirty.
2. Run `get_errors` on the changed mod files. Mod diagnostics must be zero.
3. If a framework file changed, check diagnostics but treat pre-existing engine-global warnings in lib files as expected unless the count or location changed.
4. Search the changed mod for forbidden globals: `WindowData`, `SystemData`, `GenericGump`, `GumpsParsing`, `ObjectHandleWindow`, `InterfaceCore`, `HotbarSystem`, `ItemProperties`, `EquipmentData`, `wstring`, `WindowGetId`, `Debug`.
5. Confirm deployment completed successfully and the EC client loaded the updated file.

## Error Catalogue

### `unexpected symbol near ''`` on line 1`

Likely UTF-8 BOM in a Lua file, usually `Mongbat.lua` or a generated framework file.

Checklist:
- Verify the file is UTF-8 without BOM.
- Use `deploy.ps1`, which writes text files with `UTF8Encoding($false)`.
- Do not fix by changing Lua code; fix file encoding.

### `attempt to index global 'Mongbat' (a nil value)`

Often a cascade after the framework failed to parse or initialize.

Checklist:
- Find the earliest log error, not the final cascade.
- Check `Mongbat.mod` dependency order and the first Lua parse error.
- Verify `Mongbat.lua` loaded before consumer mods.

### Window Missing or Parent Error

Likely an emit-order or parent-key issue.

Checklist:
- In `M.Build(emit)`, parent keys must be emitted before children.
- `parent = "panel"` means sibling emit key `panel`, not the engine name.
- Root windows omit `parent`.
- Read the `Mongbat.Build` error message; it lists known keys.

### Routed Handler Not Firing

Checklist:
- Confirm the engine template has the event wired to `Mongbat.EventHandler.<Event>`.
- Confirm the window exists in `Systems.Registry` and was emitted through `M.Build`.
- Enable `Mongbat.Debugger.SetVerbose(true)` temporarily to log routed hits, missing registry entries, and missing handlers.
- Handler names must be exact and use the routed window context: `M.OnLButtonUp(window, ...)`, `M.OnMouseOver(window)`, etc.

### Resize, Snap, or Layout Drift

Checklist:
- Check whether `WindowSetDimensions` is growing around a non-topleft anchor.
- Compare with default UI resize behavior before adding layout workarounds.
- Confirm `clearAnchors()` and `addAnchor()` run in the same apply phase when an anchor changes each frame.
- For labels inside `MaskWindow` parents, distinguish text clipping from parent-window movement.

### Default UI Callback Conflict

Checklist:
- If replacing a default window, use `replacesDefault = true` or destroy/suppress in `OnLoad` as documented.
- If reacting without ownership, use chain helpers such as `Api.GenericGump.OnShown` or `Api.GumpsParsing.OnParsingCheck`.
- Do not overwrite default-UI globals from a mod; add or use `Mongbat.UI.Defaults` helpers.

## Default-UI Comparison Checklist

When behavior depends on the EC engine:

1. Identify the exact default-UI module that owns the behavior.
2. Fetch or read the relevant source using `research-default-ui`.
3. Compare call order, arguments, anchors, data registration, and shutdown cleanup.
4. Implement the smallest Mongbat change that matches the default-UI pattern.
5. Remove speculative code introduced during failed attempts.

## Verification Output

End with:

- Earliest log error or confirmation that no log error was available.
- Root cause traced to a file/function.
- Minimal fix applied or clear blocker.
- Diagnostics result.
- Deployment/log verification status.
