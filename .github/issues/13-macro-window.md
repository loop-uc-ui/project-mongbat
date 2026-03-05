# Reimplement MacroWindow as Mongbat Mod

## Overview

Replace the default `MacroWindow` with a Mongbat mod (`mongbat-macro-window`). The macro window lists all player-defined macros with icon, name, and key binding, and allows creating, editing, destroying, and assigning keybinds to macros.

**Complexity:** Medium
**Priority:** Tier 4
**Branch:** `mod/macro-window`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (Labels, DynamicImages, Buttons) in a scrollable list. Focus on **functionality over visual parity** — the goal is a clean, minimal macro manager, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/MacroWindow.lua` |
| XML | `Source/MacroWindow.xml` |
| Lua (editor) | `Source/MacroEditWindow.lua` |
| Lua (icon picker) | `Source/MacroPickerWindow.lua` |

Fetch all files completely before writing any code.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| None | — | Macro data accessed via engine functions: `MacroSystemGetNumMacros()`, `UserActionMacroGetName()`, `UserActionMacroGetBinding()` |

## Key Interactions

- **"Create" button** → add a new macro (opens MacroEditWindow + ActionsWindow)
- **Left click on macro** → drag to place on hotbar
- **Ctrl+click** → spawn a new hotbar with the macro
- **Right click on macro** → context menu: Edit, Assign Key, Destroy
- **Key binding** → records keyboard shortcut via `BroadcastEvent(INTERFACE_RECORD_KEY)`, handles conflicts
- **Scroll** → browse macro list

## Framework Gaps to Address

### Missing DefaultComponents
- `MacroWindow` — needs to be added to Mongbat.lua

### Missing API Wrappers
- `Api.Macro` — wrap `MacroSystemAddMacroItem()`, `MacroSystemGetNumMacros()`, `MacroSystemDestroyMacroItem()`, `UserActionMacroGetName()`, `UserActionMacroGetBinding()`, `UserActionGetId()`, `UserActionGetIconId()`

### Missing Event Support
- `INTERFACE_KEY_RECORDED` — system event for key binding recording completion
- `INTERFACE_KEY_CANCEL_RECORD` — system event for key binding recording cancellation

### Notes
- MacroEditWindow and MacroPickerWindow are supporting dialogs — implement as simple sub-windows or skip initially
- Macros are dragged as `TYPE_MACRO_REFERENCE` onto hotbars
- Key binding assignment includes conflict detection with existing bindings

## Mod Structure

```
src/mods/mongbat-macro-window/
    MongbatMacroWindow.mod
    MongbatMacroWindowMod.lua
```

## Acceptance Criteria

- [ ] Default MacroWindow is fully suppressed
- [ ] Macro list displays all macros with icon, name, and key binding
- [ ] Create button adds a new macro
- [ ] Right-click context menu with Edit, Assign Key, Destroy
- [ ] Macros can be dragged to hotbars
- [ ] Key binding recording works with conflict detection
- [ ] Scroll through macro list
- [ ] Clean shutdown restores default window
- [ ] All engine calls go through Mongbat context wrappers
