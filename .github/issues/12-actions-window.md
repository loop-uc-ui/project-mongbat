# Reimplement ActionsWindow as Mongbat Mod

## Overview

Replace the default `ActionsWindow` with a Mongbat mod (`mongbat-actions-window`). The actions window is a browseable catalog of all available player actions (spells, skills, equipment sets, speech commands, virtues, targeting modes, pet commands, mounts, crafting tools) that can be dragged onto hotbars.

**Complexity:** Medium
**Priority:** Tier 4
**Branch:** `mod/actions-window`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (Labels, DynamicImages, Buttons) in a scrollable grid or list. Focus on **functionality over visual parity** — the goal is a clean, minimal action browser, not a pixel-perfect clone. Category navigation can be simple prev/next buttons or a dropdown.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/ActionsWindow.lua` |
| XML | `Source/ActionsWindow.xml` |
| Lua (edit) | `Source/ActionEditWindow.lua` |

Fetch all files completely before writing any code.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| None | — | Pure UI catalog; reads `SystemData.UserAction.*` types and `GetIconData()` |

## Key Interactions

- **Left/right arrows** → navigate action categories (24+ groups)
- **Left click on action** → begin drag to assign to hotbar (`DragSlotSetActionMouseClickData`)
- **Ctrl+click** → spawn a new hotbar with the action pre-assigned
- **Mouse over** → show action name/description tooltip
- **Scroll** → browse actions within a category

## Framework Gaps to Address

### Missing DefaultComponents
- `ActionsWindow` — needs to be added to Mongbat.lua (distinct from existing `Actions` component which wraps the Actions global table of action definitions)

### Missing API Wrappers
- `Api.Action` — wrap `GetIconData()`, `SystemData.UserAction.*` type constants, action category enumeration
- `Api.Drag.SetActionMouseClickData` — may need to verify this exists in current `Api.Drag`

### Notes
- The `Actions` DefaultComponent already exists but wraps the `Actions` global (action definitions/functions), not `ActionsWindow` (the UI)
- No WindowData registration needed — this is a pure UI that reads static action catalogs
- Action edit dialogs (ActionEditText, ActionEditSlider, etc.) are secondary — skip initially

## Mod Structure

```
src/mods/mongbat-actions-window/
    MongbatActionsWindow.mod
    MongbatActionsWindowMod.lua
```

## Acceptance Criteria

- [ ] Default ActionsWindow is fully suppressed
- [ ] All action categories are browseable
- [ ] Actions display with icon and name
- [ ] Left-click + drag assigns action to hotbar
- [ ] Mouse over shows tooltip
- [ ] Category navigation works (prev/next or dropdown)
- [ ] Clean shutdown restores default window
- [ ] All engine calls go through Mongbat context wrappers
