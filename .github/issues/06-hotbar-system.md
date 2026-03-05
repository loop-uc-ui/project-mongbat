# Reimplement HotbarSystem as Mongbat Mod

## Overview

Replace the default `HotbarSystem` (hotbar.lua) with a Mongbat mod (`mongbat-hotbar`). Hotbars are draggable action bars with configurable slot counts, orientation, and the ability to hold spells, items, macros, and custom actions.

**Complexity:** High
**Priority:** Tier 2
**Branch:** `mod/hotbar`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (DynamicImages, Buttons) in a simple bar layout. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/hotbar.lua` |
| XML | `Source/hotbar.xml` |
| Lua (cooldown) | `Source/Cooldown.lua` |
| XML (cooldown) | `Source/Cooldown.xml` |

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.Hotbar` | Per-hotbar | Slot data: action type, action ID, icon ID |
| `WindowData.PlayerStatsData` (CSV) | Loaded once | Stats data for stat-based slots |

## Key Interactions

- **Left click** slot → execute the action (cast spell, use item, trigger macro)
- **Drag to slot** → assign action (from spellbook, item, action list)
- **Drag from slot** → remove action
- **Right click** → context menu (lock, orientation, resize, close)
- **Cooldown overlay** — animated fill showing remaining cooldown time
- **Multiple hotbars** — up to 4+ player-configurable bars
- **Orientation** — horizontal or vertical
- **Slot count** — configurable per hotbar
- **Key bindings** — each slot can be bound to a keyboard shortcut
- Save/load hotbar configurations

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdateHotbar` — needs `DataEvent(WindowData.Hotbar, "OnUpdateHotbar")` (if applicable — hotbars may not use WindowData events in the traditional sense; study the default UI)

### Missing Data Wrappers
- Hotbar slot data may be managed entirely through Lua tables + `Interface.SaveNumber`/`LoadNumber` rather than WindowData. Study the default implementation carefully.

### Missing DefaultComponents
- `DefaultHotbarSystemComponent` — wrapping the `HotbarSystem` global (note: the global name may be `HotbarSystem` or just used within `hotbar.lua` — verify)

### Missing API Wrappers
- `Api.Drag.SetActionMouseClickData` — **already exists**
- `Api.Window.SetGameActionTrigger` — **already exists**
- `Api.Window.SetGameActionData` — **already exists**
- Macro system access may need wrappers (`MacroSystemGetNumMacroItems`, etc.)

### Architecture Notes

Hotbars are **highly stateful** — slot assignments persist across sessions via `Interface.SaveNumber`/`Interface.LoadNumber`. The implementation heavily uses `DragSlotSetActionMouseClickData` for the drag source system. Cooldown overlays use `Cooldown.lua` with frame-based animation.

This is a multi-instance system — multiple hotbar windows coexist. Each has independent orientation, size, and slot assignments.

## Mod Structure

```
src/mods/mongbat-hotbar/
    MongbatHotbar.mod
    MongbatHotbarMod.lua
```

## Acceptance Criteria

- [ ] Default hotbar system is fully suppressed
- [ ] Action slots display correct icons for assigned actions
- [ ] Left click executes the assigned action
- [ ] Drag and drop assigns/removes actions
- [ ] Cooldown overlays animate correctly
- [ ] Multiple hotbars can coexist
- [ ] Horizontal and vertical orientation
- [ ] Slot count is configurable
- [ ] Hotbar state persists across sessions
- [ ] Clean shutdown restores default hotbar system
- [ ] All engine calls go through Mongbat context wrappers
