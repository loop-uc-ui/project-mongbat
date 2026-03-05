# Reimplement SkillsTracker as Mongbat Mod

## Overview

Replace the default `SkillsTracker` with a Mongbat mod (`mongbat-skills-tracker`). The skills tracker is a floating overlay listing tracked skills with current values, updated in real-time as skills change.

**Complexity:** Low
**Priority:** Tier 4
**Branch:** `mod/skills-tracker`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (Labels) in a simple vertical list. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/SkillsTracker.lua` |
| XML | `Source/SkillsTrackerWindow.xml` |
| Related | `Source/SkillsWindow.lua` (toggle button, skill data registration) |

Fetch all files completely before writing any code.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.SkillDynamicData` | Inherited from SkillsWindow | Real/modified skill values and caps |
| `WindowData.SkillsCSV` | CSV data | Skill names, TIDs, server IDs |

## Key Interactions

- **Right click** → context menu: toggle "Show All My Skills" vs "Show Custom Skills Only"
- **Drag** → reposition window (saves position)
- **Auto-updates** → refreshes when any skill value changes
- **Toggled from SkillsWindow** → via tracker toggle button

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdateSkillDynamicData` — needs DataEvent for `WindowData.SkillDynamicData`

### Missing Data Wrappers
- `Data.SkillDynamicData(serverId)` — wrap `WindowData.SkillDynamicData[serverId]` (TempSkillValue, RealSkillValue, SkillCap)
- `Data.SkillsCSV(index)` — wrap `WindowData.SkillsCSV[index]` (Name, ServerId, TID)

### Missing DefaultComponents
- `SkillsTracker` — needs to be added to Mongbat.lua
- `SkillsWindow` — may also need to be added (it registers the skill data that SkillsTracker depends on)

### Notes
- SkillsTracker depends on SkillsWindow having registered all 58 skills via `RegisterWindowData(WindowData.SkillDynamicData.Type, serverId)`
- If `mongbat-skills-window` (Issue #7) is also implemented, coordinate data registration
- If SkillsWindow is NOT replaced, the tracker can still function since the default registers the data
- Two display modes: all skills with value > 0, or custom-selected skills only
- Shows "Remaining: X.X%" total skill points summary at the bottom

## Mod Structure

```
src/mods/mongbat-skills-tracker/
    MongbatSkillsTracker.mod
    MongbatSkillsTrackerMod.lua
```

## Acceptance Criteria

- [ ] Default SkillsTracker is fully suppressed
- [ ] Skills list displays with name and current value
- [ ] Real-time updates when skill values change
- [ ] Right-click context menu for display mode toggle
- [ ] "Remaining" total skill points shown
- [ ] Window position saves/restores
- [ ] Clean shutdown restores default window
- [ ] All engine calls go through Mongbat context wrappers
