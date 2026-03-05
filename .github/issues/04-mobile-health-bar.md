# Reimplement MobileHealthBar as Mongbat Mod

## Overview

Replace the default `MobileHealthBar` system with a Mongbat mod (`mongbat-mobile-health-bar`). Mobile health bars are dynamically created/destroyed floating bars that attach to other players, NPCs, and monsters when they enter interaction range.

**Complexity:** Medium-High
**Priority:** Tier 2
**Branch:** `mod/mobile-health-bar`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame for each health bar instance. Use plain Mongbat components (Labels, StatusBars) with clean layout. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua (main) | `Source/MobileHealthBar.lua` |
| Lua (party) | `Source/PartyHealthBar.lua` |
| Lua (manager) | `Source/HealthBarManager.lua` |
| XML | `Source/MobileHealthBar.xml`, `Source/PartyHealthBar.xml` |

Fetch ALL of these files. The health bar system is split across multiple files with a central manager.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.MobileName` | Per-mobile ID | Name and notoriety for each bar |
| `WindowData.MobileStatus` | Per-mobile ID | Health/mana/stam values |
| `WindowData.HealthBarColor` | Per-mobile ID | Bar tint based on notoriety/status |
| `WindowData.PartyMember` | Static array [1..10] | Party member IDs |

## Key Interactions

- **Dynamically created** when a mobile enters range or is targeted
- **Dynamically destroyed** when mobile leaves range
- **Left click** → target that mobile
- **Right click** → context menu
- **Drag** health bar → reposition (detach from world object)
- Health bar color changes based on notoriety (ally=green, enemy=red, etc.)
- **Party health bars** — special variant that persists for party members
- Attach-to-world-object positioning

## Framework Gaps to Address

### Missing DataEvents
- None — `OnUpdateMobileName`, `OnUpdateMobileStatus`, `OnUpdateHealthBarColor` all exist

### Missing Data Wrappers
- `Data.PartyMember(index)` — new wrapper for `WindowData.PartyMember[i]`

### Missing DefaultComponents
- `DefaultMobileHealthBarComponent` — wrapping `MobileHealthBar` global
- `DefaultPartyHealthBarComponent` — wrapping `PartyHealthBar` global
- **Note:** `DefaultHealthBarManagerComponent` already exists

### Missing API Wrappers
- None critical — `Api.Window.AttachToWorldObject` and `DetachFromWorldObject` already exist

### Architecture Notes

This is a **multi-instance component system** — many health bars exist simultaneously, each bound to a different mobile ID. The mod needs to manage a pool of Mongbat Window instances. The `Components.Defaults.HealthBarManager` already exists and handles the dispatch logic — study how the default `HealthBarManager.lua` routes creation requests.

## Mod Structure

```
src/mods/mongbat-mobile-health-bar/
    MongbatMobileHealthBar.mod
    MongbatMobileHealthBarMod.lua
```

## Acceptance Criteria

- [ ] Default MobileHealthBar and PartyHealthBar are fully suppressed
- [ ] Health bars appear on mobiles in range
- [ ] Health bars show name with notoriety color
- [ ] Health values update in real-time
- [ ] Bar color reflects notoriety/poison/mortal status
- [ ] Left click targets the mobile
- [ ] Right click opens context menu
- [ ] Drag detaches bar from world and makes it free-floating
- [ ] Party health bars persist for party members
- [ ] Clean shutdown restores default health bar system
- [ ] All engine calls go through Mongbat context wrappers
