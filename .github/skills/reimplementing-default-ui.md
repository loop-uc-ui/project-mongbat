# Skill: Reimplementing a Default UI Window

This is a **step-by-step procedure** for replacing any default UI window with a Mongbat mod. Follow every step in order. Do not skip steps or start coding before the research phase is complete. The paperdoll reimplementation taught us that skipping research causes cascading bugs.

## Phase 1: Research the Default Implementation

**Goal:** Build a complete mental model of the window BEFORE writing any code.

### Step 1.1 — Fetch Both Lua AND XML

Use `github_repo` on `loop-uc-ui/enhanced-client-default` to retrieve:
- `<WindowName>.lua` — the full Lua file
- `<WindowName>.xml` — the full XML file

Read both completely. The XML defines structure, templates, and creation-time attributes. The Lua defines behavior, data registration, and lifecycle.

### Step 1.2 — Map the Data Model

From the Lua file, extract:
- **Which `WindowData.*` tables** the window uses (search for `RegisterWindowData` calls).
- **How many data entries** exist (e.g., paperdoll has 19 `BlankSlot` entries, not the `ArmorSlots=12` constant that only counts visible buttons). Look at the actual indexed data arrays, not named constants.
- **What fields** each data entry has (search for how the code reads from `WindowData.*[id]`).
- **When data is registered** — at Initialize time? On demand? Per-entity?

**Anti-pattern learned:** We hardcoded `NUM_SLOTS = 12` because we looked at `ArmorSlots` instead of counting the actual `BlankSlot[1]` through `BlankSlot[19]` array. Always count the real data entries.

### Step 1.3 — Map the Full Lifecycle

Trace how the window gets created, shown, and destroyed:

1. **What triggers creation?** Search the default UI repo for all call sites that create or show this window. Common patterns:
   - `CreateWindowFromTemplate(name, template, "Root")` in an Initialize function
   - Engine-triggered creation via `UserAction*` calls (e.g., `UserActionUseItem` triggers the engine to create `"PaperdollWindow"..id` from the XML template AND call `PaperdollWindow.Initialize()`)
   - `Interface.Toggle*Window()` functions

2. **What periodic checks exist?** Search the `Interface.lua` file for `*Check` functions related to this window (e.g., `Interface.PaperdollCheck`). These run in the main update loop and will **re-create** the default window if certain state flags are true.

3. **What global state flags** track the window? (e.g., `Interface.PaperdollOpen`, `Interface.StatusWindowOpen`). These must be managed.

4. **What does Shutdown do?** What cleanup happens when the default window is destroyed?

**Anti-pattern learned:** We called `UserActionUseItem(playerId, true)` thinking it would "request paperdoll data" — but it actually triggers the engine to create the default XML window. We didn't know this because we didn't trace all creation paths. Additionally, we didn't discover `Interface.PaperdollCheck` which kept re-creating the default window every frame.

### Step 1.4 — Map Interactions

For each user interaction the default window supports:
- **Mouse handlers** — What engine functions are called on click, double-click, right-click, drag, drop?
- **Tooltips** — How does `ItemProperties.SetActiveItem` get called? What fields are required?
- **Context menus** — What calls `RequestContextMenu`?
- **Drag & drop** — What `DragSlot*` functions are used? What source types?
- **Targeting** — Does the window handle `WindowData.Cursor.target` for targeting mode?

### Step 1.5 — Map Data-to-Display Logic

Find the function(s) that translate raw data into visual state:
- What helper functions exist? (e.g., `EquipmentData.UpdateItemIcon` for paperdoll items)
- What texture/shader/hue calls are made?
- Are there shared utility functions in the default UI that our mod can reuse? (These are global functions that remain available even when we replace the window.)

## Phase 2: Check Framework Support

For each `WindowData.*` type the window needs, check if `Mongbat.lua` already has:

| What | Where to search | What to add if missing |
|---|---|---|
| DataEvent constant | `Constants.DataEvents.OnUpdate*` | `DataEvent(WindowData.*, "OnUpdate*")` |
| Data wrapper class | `Data.*()` factory function | Wrapper with `:getData()`, `:getId()`, plus typed accessors |
| EventHandler dispatcher | `EventHandler.OnUpdate*` | `withActiveView` dispatch function |
| View lifecycle method | `View:onUpdate*()` | Method that calls `model.OnUpdate*` with wrapper |
| Initial data call | `View:onInitialize` pcall block | Add `self:onUpdate*()` call |
| Type annotations | `WindowModel`, `LabelModel`, etc. | `OnUpdate*` field on all model types |
| DefaultComponent | `Components.Defaults.*` | New `Default*Component` class + proxy + instantiation |

## Phase 3: Implement the Mod

### Step 3.1 — Suppression Strategy

Disabling the DefaultComponent proxy **only makes Lua functions no-ops**. The engine's C++ layer can still create the XML window. A complete suppression strategy requires ALL of:

1. `paperdollDefault:disable()` — no-op the Lua Initialize/Shutdown
2. Set relevant `Interface.*Open` flags to `false` — prevent periodic recreation checks
3. Destroy any already-existing engine window: `if DoesWindowNameExist(defaultName) then DestroyWindow(defaultName) end`
4. Do NOT call engine actions that trigger default window creation (e.g., `UserActionUseItem` for paperdoll, `UserActionOpenPaperdoll`, etc.)

**Anti-pattern learned:** We relied solely on `disable()` and didn't know about `Interface.PaperdollCheck`. The proxy disabled `Initialize` but the engine still created the XML window. The check function then kept re-opening it.

### Step 3.2 — Data Registration

Mongbat's `View:setId(entityId)` automatically calls `RegisterWindowData(dataType, entityId)` for each DataEvent in the model. This is how you subscribe to entity-specific data. You do NOT need to call any engine action to "request" data — `setId` does it.

For data types that are registered once globally (PlayerStatus, Radar, PlayerLocation), the framework handles this at startup. For entity-specific types (Paperdoll, MobileName, MobileStatus, HealthBarColor), `setId()` handles it.

### Step 3.3 — Window Construction Pattern

```lua
local function OnInitialize(context)
    -- 1. Disable default
    local default = context.Components.Defaults.<WindowName>
    default:disable()

    -- 2. Suppress periodic recreation
    Interface.<WindowName>Open = false  -- if applicable

    -- 3. Destroy existing default window
    local defaultName = "<WindowName>" .. id  -- or just "<WindowName>" if not per-entity
    if DoesWindowNameExist(defaultName) then
        DestroyWindow(defaultName)
    end

    -- 4. Build replacement
    -- ... create Components, children, layout ...

    -- 5. Create window with setId for data binding
    context.Components.Window {
        Name = NAME,
        OnInitialize = function(self)
            self:setId(entityId)  -- triggers RegisterWindowData for all DataEvents in model
            self:setChildren(children)
        end,
        OnUpdate<DataType> = function(self, wrapper)
            -- update display from data
        end,
    }:create(true)
end

local function OnShutdown(context)
    -- 1. Destroy replacement
    context.Api.Window.Destroy(NAME)

    -- 2. Restore periodic recreation flag
    Interface.<WindowName>Open = true  -- if applicable

    -- 3. Restore default
    local default = context.Components.Defaults.<WindowName>
    default:restore()
end
```

### Step 3.4 — Interaction Handlers

Copy interaction patterns directly from the default UI Lua, translating raw engine calls to Mongbat model keys:

| Default UI pattern | Mongbat model key |
|---|---|
| `WindowRegisterCoreEventHandler(name, "OnLButtonDblClk", ...)` | `OnLButtonDblClk = function(self) ... end` |
| `RegisterEventHandler(SystemData.Events.L_BUTTON_DOWN_PROCESSED, ...)` | `OnLButtonDown = function(self, flags) ... end` |
| Inside handlers: `DragSlot*`, `RequestContextMenu`, `UserActionUseItem`, `ItemProperties.SetActiveItem`, `HandleSingleLeftClkTarget` | Same engine globals — call them directly in the handler body |

## Phase 4: Shutdown Symmetry

Every action in `OnInitialize` must have a reverse in `OnShutdown`:

| OnInitialize | OnShutdown |
|---|---|
| `default:disable()` | `default:restore()` |
| `Interface.XOpen = false` | `Interface.XOpen = true` |
| `DestroyWindow(defaultName)` | *(engine will recreate on restore)* |
| `Window():create(true)` | `Api.Window.Destroy(NAME)` |

## Post-Implementation Checklist

- [ ] Default window is fully suppressed (no ghost window appearing)
- [ ] All data entries are accounted for (count from actual data arrays, not named constants)
- [ ] All interaction types work (click, double-click, right-click, drag, drop, tooltip, context menu, targeting)
- [ ] `OnShutdown` cleanly reverses everything `OnInitialize` did
- [ ] No calls to engine functions that trigger default window creation
- [ ] Data binding works via `setId()`, not manual engine action calls
