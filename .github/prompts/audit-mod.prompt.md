---
description: "Audit a mod (or all mods) for direct references to engine globals (WindowData, GenericGump, GumpsParsing, ObjectHandleWindow, wstring, etc.) and propose Mongbat wrappers."
argument-hint: "Path to a mod file or src/mods to audit all mods"
agent: "agent"
---

# Audit a Mod for Engine-Global References

Mods must reference only `Mongbat.{Api,Data,Utils,Constants,Debugger,CreateWindow,RegisterWindow,DestroyWindow,UnregisterWindow,GetWindow,Mod}`.
This prompt finds violations and proposes fixes.

## Procedure

1. **Run `grep_search`** with this regex against the target path
   (default: `src/mods/**`):

   ```
   \b(WindowData|SystemData|GenericGump|GumpsParsing|ObjectHandleWindow|MapCommon|MapWindow|HealthBarManager|InterfaceCore|HotbarSystem|ItemProperties|EquipmentData|wstring|WindowGetId|TextLogClear|StringToWString|WStringToString|Debug)\b
   ```

   `Debug.*` calls should be migrated to `Mongbat.Debugger.*`.

   Treat matches inside string literals, comments, or `---@class` /
   `---@field` annotations as **non-violations** (those are legal references
   to the engine type system).

2. **Also run** this regex to find raw table-iteration patterns that should
   use `Utils.Array.*` / `Utils.Table.*`:

   ```
   \bin\s+(ipairs|pairs)\b
   ```

   Numeric `for i = 1, N do` loops over engine-counted ranges (e.g.
   `Api.TextLog.GetNumEntries`, paperdoll slots) are NOT violations — only
   `ipairs` / `pairs` and `for i = 1, #t` over a table are.

3. **Also flag** any `---@diagnostic disable: undefined-global` directive in
   a mod file — that is a boundary-leak marker.

4. **For each true violation**, propose one of:
   - **Use existing wrapper** (preferred). Common swaps:
     - `WindowData.PlayerStatus` → `Data.PlayerStatus():get*()`
     - `WindowData.MobileStatus[id]` → `Data.MobileStatus(id):getName()/getNotoriety()`
     - `WindowData.MobileName[id]` → `Data.MobileName(id):getName()`
     - `WindowData.HealthBarColor[id]` → `Data.HealthBarColor(id):getVisualStateColor()`
     - `WindowData.ObjectHandle` → `Data.ObjectHandles():getHandles()`
     - `WindowData.Radar` → `Data.Radar():getTexCoordX/Y/Scale()`
     - `WindowData.Paperdoll[id]` → `Data.Paperdoll(id):getSlot(i)/getNumSlots()`
     - `wstring.len/lower/find` → `Utils.String.Len/Lower/Find` (works on
       both `string` and `wstring`)
     - `SystemData.ActiveWindow.name` → `Api.Window.GetActiveName()`
     - `WindowGetId(name)` → `Api.Window.GetId(name)`
     - `GenericGump.LastGumpLabels` → `Api.GenericGump.GetLastLabels()`
     - `GenericGump.OnShown = fn` → `Api.GenericGump.OnShown(fn)` (chains)
     - `GumpsParsing.GumpMaps[id].name = ...` → `Api.GumpsParsing.SetGumpName(id, name)`
     - `GumpsParsing.MainParsingCheck` chain → `Api.GumpsParsing.OnParsingCheck(fn)`
     - `ObjectHandleWindow.OnBeginDragHealthBar(id)` → `Api.HealthBar.BeginDrag(id)`
     - `ObjectHandleWindow.CreateObjectHandles = fn` → `Api.ObjectHandle.OnCreate(fn)`
     - `ObjectHandleWindow.DestroyObjectHandles = fn` → `Api.ObjectHandle.OnDestroy(fn)`
     - `for _, item in ipairs(arr) do ... end` → `Utils.Array.ForEach(arr, function(item, i) ... end)`
     - `for k, v in pairs(t) do ... end` → `Utils.Table.ForEach(t, function(k, v) ... end)`
     - `for i = 1, #arr do local item = arr[i]; ... end` → `Utils.Array.ForEach(arr, function(item, i) ... end)`
     - Building a child array with a loop → `Utils.Array.MapToArray(arr, function(item) return ... end)`
     - Filtering an array → `Utils.Array.Filter(arr, function(item) return ... end)`
     - First-match search → `Utils.Array.Find(arr, ...)` / `Utils.Table.Find(t, ...)`
   - **Add a new wrapper.** If no existing wrapper covers the use, run
     `/wrap-engine-global` for that global first, then come back.

5. **Apply the fixes** with `multi_replace_string_in_file`. Remove the
   `---@diagnostic disable` directive after the file is clean.

6. **Verify.** Run `get_errors` on each modified mod file → expect zero
   diagnostics. Re-run the grep_search to confirm zero true violations
   remain.

## Output Format

For each mod with violations, report:

```
<mod path>: <N> violation(s)
  L<line>: <snippet>  →  <proposed fix>
  L<line>: <snippet>  →  <proposed fix>
```

Then ask the user whether to apply the fixes.
