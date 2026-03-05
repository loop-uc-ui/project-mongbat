# Reimplement SkillsWindow as Mongbat Mod

## Overview

Replace the default `SkillsWindow` with a Mongbat mod (`mongbat-skills-window`). Displays all character skills with current values, caps, lock states (up/down/locked), and a skills tracker.

**Complexity:** Medium
**Priority:** Tier 2
**Branch:** `mod/skills-window`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (Labels, Buttons) in a simple scrollable list. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua (main) | `Source/SkillsWindow.lua` |
| Lua (info) | `Source/SkillsInfo.lua` |
| Lua (tracker) | `Source/SkillsTracker.lua` |
| XML | `Source/SkillsWindow.xml`, `Source/SkillsInfo.xml`, `Source/SkillsTracker.xml` |

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.SkillsCSV` | Loaded via CSV | Skill definitions: name TIDs, IDs |
| `WindowData.SkillDynamicData` | Per-skill by server ID | Current value, cap, lock state |
| `WindowData.PlayerSkillCaps` | Global | Total skill point cap |

## Key Interactions

- **Skill list** — scrollable list of all skills with values
- **Lock state toggle** — click arrow to cycle up/down/locked per skill
- **Use skill** — double-click or button to activate a skill
- **Skill info** — click for detailed skill description popup
- **Skills tracker** — floating mini-window showing selected skills
- **Sort** — alphabetical, by value, by category
- **Real-time updates** — skill values change as you train
- **Skill group** — SOD (Skill on Display) toggle
- **Total skill points** — running total shown

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdateSkillDynamicData` — needs `DataEvent(WindowData.SkillDynamicData, "OnUpdateSkillDynamicData")`

### Missing Data Wrappers
- `Data.SkillDynamicData(serverId)` — new wrapper exposing skill value, cap, lock state
- `Data.SkillsCSV()` — wrapper or direct access to skill definitions
- `Data.PlayerSkillCaps()` — wrapper for total cap data

### Missing DefaultComponents
- `DefaultSkillsWindowComponent` — wrapping `SkillsWindow` global
- May also want `DefaultSkillsTrackerComponent` for the tracker sub-window

### Missing API Wrappers
- `Api.Skill.SetLockState(serverId, lockState)` — wrapping `SkillLockRequest` or equivalent engine function
- `Api.Skill.UseSkill(serverId)` — wrapping whatever engine function activates a skill

## Mod Structure

```
src/mods/mongbat-skills-window/
    MongbatSkillsWindow.mod
    MongbatSkillsWindowMod.lua
```

## Acceptance Criteria

- [ ] Default SkillsWindow is fully suppressed
- [ ] All skills display with correct names, values, and caps
- [ ] Lock state (up/down/locked) toggling works
- [ ] Skill values update in real-time during training
- [ ] Double-click activates skill
- [ ] Skill info popup shows description
- [ ] Total skill points displayed
- [ ] Scrollable skill list
- [ ] Clean shutdown restores default window
- [ ] All engine calls go through Mongbat context wrappers
