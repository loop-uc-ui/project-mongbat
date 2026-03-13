# Skill: Code Review for Mongbat Mods

This is a **checklist-driven procedure** for reviewing a Mongbat mod PR. Work through every section in order. For each check, note PASS or the specific violation. Report findings at the end with a verdict: **PASS** or **NEEDS WORK**.

---

## Before You Begin

1. **Read the issue** linked to the PR. Extract all acceptance criteria.
2. **Read the mod's Lua file** completely — do not skim.
3. **Read all changes to `Mongbat.lua`** in the PR to understand what framework wrappers were added.

---

## 1. No Raw Engine Globals (Section 3.1)

Scan the **mod file(s) only** (not `Mongbat.lua`) for any direct reference to engine globals. Every engine reference must go through the Mongbat namespaces (`Api`, `Data`, `Constants`, `Components`, `Utils`), destructured from `Mongbat` at the top of the mod file.

### 1.1 Data Tables

- [ ] No `SystemData.*` reads (e.g., `SystemData.Settings.*`, `SystemData.ActiveWindow.name`, `SystemData.Hotbar.*`). Use `Data.*` wrappers.
- [ ] No `WindowData.*` reads (e.g., `WindowData.PlayerStatus.*`, `WindowData.ContainerWindow.*`). Use `Data.*` wrappers.
- [ ] No `WindowData.*.Type` or `WindowData.*.Event` constants. Use `Constants.DataEvents.*`.

### 1.2 Global Functions

- [ ] No bare engine functions: `WindowSetShowing`, `DestroyWindow`, `CreateWindowFromTemplate`, `DoesWindowNameExist`, `WindowSetDimensions`, `DynamicImageSetTexture`, `RegisterWindowData`, `WindowRegisterEventHandler`, `WindowRegisterCoreEventHandler`, `BroadcastEvent`, etc. Use `Api.*`.
- [ ] No bare string functions: `StringToWString`, `WStringToString`, `GetStringFromTid`. Use `Api.String.*`.
- [ ] No bare action functions: `HandleSingleLeftClkTarget`, `UserActionUseItem`, `RequestContextMenu`. Use `Api.*`.
- [ ] No bare drag functions: `DragSlotSetObjectMouseClickData`, `DragSlotClearAll`, etc. Use `Api.Drag.*`.
- [ ] No bare `Interface.SaveNumber` / `Interface.LoadNumber` / `Interface.SaveBoolean` / `Interface.LoadBoolean`. Use `Api.Interface.*`.
- [ ] No bare `ItemProperties.*` calls. Use `Api.ItemProperties.*`.
- [ ] No bare `EquipmentData.*` calls. Use `Api.Equipment.*` or equivalent.

### 1.3 Default UI Globals

- [ ] No direct references to default UI window tables (`StatusWindow`, `PetWindow`, `HotbarSystem`, `Shopkeeper`, `ContainerWindow`, `TradeWindow`, `ChatWindow`, etc.) except through `Components.Defaults.<name>`.
- [ ] No TID constants accessed through default UI tables (e.g., `HotbarSystem.TID_LOCK_HOTBAR`). Use `Constants.*` or `Api.String.GetStringFromTid(tidNumber)`.

### 1.4 Constants and Enumerations

- [ ] No `SystemData.Events.*` references. Use `Constants.*`.
- [ ] No `SystemData.DragSource.SOURCETYPE_*` references. Use `Constants.DragSource.*`.
- [ ] No `Window.Layers.*` or `Window.AnimationType.*` references. Use `Constants.*`.

### 1.5 Global Table Pollution

- [ ] Mod does **not** create any global tables (e.g., `MyMod = MyMod or {}`). Mongbat dispatches events internally — mods never need global callback targets.
- [ ] Mod does **not** register manual event handlers with callback strings pointing to global tables.

---

## 2. Event System Usage (Architecture)

- [ ] Event handlers are declared as **model keys** in component tables (e.g., `OnUpdatePlayerStatus = function(self, data) ... end`), not via manual `WindowRegisterEventHandler` or `RegisterEventHandler` calls.
- [ ] DataEvents are registered by **calling `setId(entityId)` on the child component** that needs the data, not on the parent Window.
- [ ] Events are placed in the correct dispatch category — no CoreEvents that should be SystemEvents or vice versa.
- [ ] No manual `WindowRegisterCoreEventHandler` or `WindowRegisterEventHandler` calls in mod code. The framework handles registration from model keys.

---

## 3. DefaultComponent Suppression (Architecture)

If the mod replaces a default UI window:

- [ ] Default is obtained via `Components.Defaults.<name>`.
- [ ] `disable()` is called in `OnInitialize`.
- [ ] `restore()` is called in `OnShutdown`.
- [ ] If the default has periodic recreation checks (e.g., `Interface.*Open` flags), these are managed.
- [ ] Any existing default engine window is destroyed in `OnInitialize`.

If the mod does NOT replace a default (new feature mod):
- [ ] No DefaultComponent interaction needed — verify this is intentional.

---

## 4. Shutdown Symmetry (Lifecycle)

Every action in `OnInitialize` must have a corresponding reverse in `OnShutdown`:

- [ ] `default:disable()` ↔ `default:restore()`
- [ ] `Window():create()` ↔ `Api.Window.Destroy(name)`
- [ ] Any per-entity `RegisterWindowData` (via `setId`) is cleaned up — either by destroying the view or explicit unregistration.
- [ ] State flags set in `OnInitialize` are reset in `OnShutdown`.
- [ ] No resource leaks: all dynamically created views are tracked and destroyed.
- [ ] `OnShutdown` can run safely even if `OnInitialize` partially failed (destroy calls are no-ops on non-existent windows).

---

## 5. Variable Scoping (Section 3.2)

- [ ] **File-scope mutables are minimal.** Runtime state (view references, entity IDs, flags) should be `local` inside `OnInitialize`, not file-scope.
- [ ] **File-scope constants are acceptable.** `local NAME = "MyMod"` or `local MAX_SLOTS = 10` at file level is fine.
- [ ] **File-scope mutables that DO exist are justified** — they truly need to survive across both `OnInitialize` and `OnShutdown` and cannot be plumbed through closures.
- [ ] **No unnecessary upvalue sharing** — prefer passing values through function parameters over sharing across distant functions.

---

## 6. wstring Correctness (Lua Environment)

- [ ] UI-facing text uses wstring: `L"literal"`, `towstring(number)`, `Api.String.StringToWString(str)`.
- [ ] No `string.format(...)` for display text — use wstring concatenation (`towstring(n) .. L" / " .. towstring(m)`).
- [ ] `WStringToString` / `StringToWString` calls go through `Api.String.*`, not bare globals.
- [ ] TID lookups use `Api.String.GetStringFromTid(tid)`, not bare `GetStringFromTid(tid)`.

---

## 7. Framework Absorption (Section 3.3)

- [ ] **No redundant guard clauses** at call sites for things the framework handles internally (e.g., existence checks before destroy, nil checks the API already performs).
- [ ] **Repeated patterns across the mod** should be factored into helper functions — or into the framework if they'd apply to multiple mods.
- [ ] **Framework additions in this PR** (`Mongbat.lua` changes) are properly structured: Data wrappers return objects with typed accessors, Api functions handle nil/error cases internally, Constants are accessed through functions or named entries.
- [ ] **Operations that belong in `Utils` are routed through `Utils`** — raw iteration (`for` loops), string formatting, table manipulation, math helpers, and other general-purpose operations should use `Utils.*` per Section 3.1, not inline Lua primitives.

---

## 8. Component Model Usage (Architecture)

- [ ] UI elements are created via `Components.*` factories (Window, Label, Button, DynamicImage, StatusBar, etc.), not via raw `Api.Window.CreateFromTemplate` with manual setup.
- [ ] Builder pattern is used where applicable — fluent chaining (`:setDimensions():setColor():create()`).
- [ ] Children are set via the `.children` property or the `Children` model key, not manually reparented.
- [ ] Component types match their purpose — Labels for text, DynamicImages for icons, StatusBars for progress, etc.

---

## 9. Lua Compatibility (Environment)

- [ ] No `require`, `module`, `goto`, `io.*`, `os.*`, `debug.*`.
- [ ] Uses `math.mod()` not `math.fmod()`.
- [ ] Pattern matching uses Lua patterns, not regex syntax (no `|`, `\d`, lookahead).
- [ ] `local function` definitions appear **above** all call sites in the file.

---

## 10. Type Annotations (Section 3.4)

- [ ] Functions with non-obvious parameters have `--- @param` annotations.
- [ ] Functions with non-obvious return types have `--- @return` annotations.
- [ ] Complex table shapes (model tables, config objects) are documented with comments or annotations.

---

## 11. Acceptance Criteria (Issue-Specific)

For each acceptance criterion listed in the linked issue:

- [ ] **Criterion is implemented** — the feature exists in the code.
- [ ] **Criterion is functional** — the code path is reachable and correct (trace through to verify).
- [ ] **No criteria are missing** — every item in the issue checklist is addressed.

List each criterion individually and mark PASS/FAIL.

---

## 12. Code Quality

- [ ] **No debug print statements** (`Debug.Print`, `print`, etc.).
- [ ] **No commented-out code blocks** left from development iteration.
- [ ] **Consistent naming** — follows existing mod conventions for variable names, function names, window names.
- [ ] **Reasonable file length** — if the mod is excessively long, check whether logic should be factored into the framework.
- [ ] **`.mod` file is correct** — declares dependency on Mongbat, correct script path, correct mod name.

---

## Reporting

After completing all checks, produce a summary:

```
## Code Review — [PASS / NEEDS WORK]

### Violations
- (list each specific violation with the check number and what was found)

### Acceptance Criteria
| Criterion | Status |
|---|---|
| (from issue) | PASS / FAIL — (brief note) |

### Action Items
1. (numbered list of concrete changes required)

@copilot Please address these issues.
```

If the PR passes all checks, the summary is simply:

```
## Code Review — PASS

No violations found. All acceptance criteria met. Ready for merge pending manual testing.
```
