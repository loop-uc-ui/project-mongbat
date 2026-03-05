# Reimplement PartyHealthBar as Mongbat Mod

## Overview

Replace the default `PartyHealthBar` system with a Mongbat mod (`mongbat-party-health-bar`). Party health bars are dynamically created floating bars for each party member showing name, health/mana/stamina, and optional portrait.

**Complexity:** Medium-High
**Priority:** Tier 4
**Branch:** `mod/party-health-bar`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame for each health bar instance. Use plain Mongbat components (Labels, StatusBars) with clean layout. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone. Skip portrait rendering initially — name + bars is sufficient.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/PartyHealthBar.lua` |
| XML | `Source/PartyHealthBar.xml` |
| Lua (manager) | `Source/HealthBarManager.lua` |

Fetch all files completely before writing any code.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.MobileStatus` | Per-entity via member ID | Health/mana/stamina values |
| `WindowData.MobileName` | Per-entity via member ID | Name + notoriety |
| `WindowData.HealthBarColor` | Per-entity via member ID | Poison/curse visual state |
| `WindowData.PartyMember` | `RegisterWindowData(WindowData.PartyMember.Type, 0)` | Party roster updates |

## Key Interactions

- **Left click** on bar → target that party member
- **Right click** → context menu on member
- **Drop item** onto bar → use item on member
- **Close button** → destroy individual bar
- **Drag** → reposition (snap-aware)
- Dynamic creation/destruction as party membership changes

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdatePartyMember` — needs DataEvent for `WindowData.PartyMember`

### Missing Data Wrappers
- `Data.PartyMember()` — wrap `WindowData.PartyMember` (party roster, member IDs)

### Missing DefaultComponents
- `PartyHealthBar` — needs to be added to Mongbat.lua

### Notes
- `HealthBarManager` DefaultComponent already exists — it manages both MobileHealthBar and PartyHealthBar
- Party bars are dynamically instanced (`PartyHealthBar_1` through `PartyHealthBar_10`)
- Must coordinate with HealthBarManager for party roster changes

## Mod Structure

```
src/mods/mongbat-party-health-bar/
    MongbatPartyHealthBar.mod
    MongbatPartyHealthBarMod.lua
```

## Acceptance Criteria

- [ ] Default PartyHealthBar is fully suppressed
- [ ] Party member bars appear/disappear dynamically with roster changes
- [ ] Name shows with notoriety color
- [ ] Health, mana, and stamina bars update in real-time
- [ ] Health bar color reflects poison/curse state
- [ ] Left-click targets the member
- [ ] Right-click opens context menu
- [ ] Bars are individually draggable
- [ ] Clean shutdown restores default window
- [ ] All engine calls go through Mongbat context wrappers
