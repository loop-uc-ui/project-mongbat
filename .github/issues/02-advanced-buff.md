# Reimplement AdvancedBuff (Buff/Debuff Bar) as Mongbat Mod

## Overview

Replace the default `AdvancedBuff` system with a Mongbat mod (`mongbat-buff-bar`). Displays active buffs and debuffs as icon rows with durations, tooltips, and direction/layout options.

**Complexity:** Medium
**Priority:** Tier 1
**Branch:** `mod/buff-bar`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (Labels, DynamicImages) with clean layout. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua (main) | `Source/AdvancedBuff.lua` |
| Lua (helper) | `Source/BuffDebuff.lua` |
| XML | `Source/AdvancedBuff.xml` (and `Source/BuffDebuff.xml`) |

Fetch ALL of these files. `BuffDebuff.lua` handles data registration; `AdvancedBuff.lua` handles display.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.BuffDebuff` | `RegisterWindowData(WindowData.BuffDebuff.Type, 0)` | Buff/debuff list with icons, durations, descriptions |

## Key Interactions

- **Mouse over** buff icon → show tooltip with buff name, duration, description
- **Right click** → context menu to change layout direction (horizontal/vertical)
- **Lock/unlock** button — prevent repositioning
- Dynamic creation/destruction of buff icon windows as buffs change
- Separate "Good" (buffs) and "Evil" (debuffs) containers

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdateBuffDebuff` — needs `DataEvent(WindowData.BuffDebuff, "OnUpdateBuffDebuff")`

### Missing Data Wrappers
- `Data.BuffDebuff()` — new wrapper for `WindowData.BuffDebuff` data table, exposing buff list with icon IDs, durations, descriptions, and enabled state

### Missing DefaultComponents
- `DefaultBuffDebuffComponent` — wrapping the `BuffDebuff` global
- `DefaultAdvancedBuffComponent` — wrapping the `AdvancedBuff` global (may need both)

### Missing API Wrappers
- None identified — existing `Api.DynamicImage`, `Api.Label`, `Api.Window` should suffice

## Mod Structure

```
src/mods/mongbat-buff-bar/
    MongbatBuffBar.mod
    MongbatBuffBarMod.lua
```

## Acceptance Criteria

- [ ] Default AdvancedBuff and BuffDebuff are fully suppressed
- [ ] Buffs display as icons with proper textures
- [ ] Debuffs display separately from buffs
- [ ] Tooltips show buff name, duration, and description
- [ ] Icons appear/disappear dynamically as buffs change
- [ ] Duration countdown visible (timer label or cooldown overlay)
- [ ] Layout direction configurable (horizontal/vertical)
- [ ] Clean shutdown restores default buff system
- [ ] All engine calls go through Mongbat context wrappers
