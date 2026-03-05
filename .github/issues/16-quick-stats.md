# Reimplement QuickStats as Mongbat Mod

## Overview

Replace the default `QuickStats` system with a Mongbat mod (`mongbat-quick-stats`). QuickStats are user-created floating stat labels for individual player stats or item quantities, each independently customizable with colors, visibility toggles, and low-value warning blink.

**Complexity:** Medium
**Priority:** Tier 4
**Branch:** `mod/quick-stats`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame for each stat label. Use plain Mongbat components (Labels, DynamicImages) with clean layout. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone. Skip snap-grouping initially — individual draggable labels is sufficient.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/QuickStats.lua` |
| XML | (Template `QuickStatTemplate` — search in `Source/QuickStats.xml` or `Source/CharacterSheet.xml`) |
| Related | `Source/StatusWindow.lua` (CharacterSheet creates QuickStats via Ctrl+click) |

Fetch all files completely before writing any code.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.PlayerStatus` | Already registered globally | HP, mana, stamina, weight, damage, followers, etc. |
| `WindowData.PlayerStatsDataCSV` | CSV data | Stat metadata: name, TID, iconId |
| `WindowData.ObjectInfo` | Per object ID | For item quantity tracking mode |

## Key Interactions

- **Left click** → drag to reposition (if not locked)
- **Shift+click** → group-move snapped labels together
- **Right click** → context menu with:
  - Lock/unlock position
  - Toggle icon, frame, name, value cap display
  - Set warning threshold (blink on low values)
  - Change colors: background, frame, name text, value text
  - Destroy label
- **Created from** → CharacterSheet (Ctrl+click on stat) or Container windows (Ctrl+click on item)
- **Polling update** → refreshes on 1-second timer via OnUpdate

## Framework Gaps to Address

### Missing DefaultComponents
- `QuickStats` — needs to be added to Mongbat.lua

### Missing Data Wrappers
- `Data.PlayerStatsDataCSV(id)` — wrap `WindowData.PlayerStatsDataCSV[id]` (stat name, TID, icon info)

### Missing API Wrappers
- Color picker integration — may need `Api.ColorPicker` or similar for per-element color customization

### Notes
- Up to 100 labels (`QuickStats.Max`), each independently customizable
- Uses polling pattern (OnUpdate with 1-second refresh), not event-driven
- Persisted across sessions via `Interface.Save/Load` (position, colors, display options)
- Created on-demand from CharacterSheet or inventory — need to intercept creation triggers
- Snap-grouping is complex — defer to later iteration
- Each label tracks a specific stat attribute or item quantity

## Mod Structure

```
src/mods/mongbat-quick-stats/
    MongbatQuickStats.mod
    MongbatQuickStatsMod.lua
```

## Acceptance Criteria

- [ ] Default QuickStats is fully suppressed
- [ ] Individual stat labels can be created
- [ ] Labels display stat name and current value
- [ ] Real-time updates (polling-based)
- [ ] Right-click context menu for customization
- [ ] Lock/unlock position
- [ ] Low-value warning blink works
- [ ] Labels persist across sessions
- [ ] Clean shutdown restores default system
- [ ] All engine calls go through Mongbat context wrappers
