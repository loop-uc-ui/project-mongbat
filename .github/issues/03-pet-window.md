# Reimplement PetWindow as Mongbat Mod

## Overview

Replace the default `PetWindow` with a Mongbat mod (`mongbat-pet-window`). Displays a list of controlled pets with their names, health bars, and pet command buttons.

**Complexity:** Low-Medium
**Priority:** Tier 1
**Branch:** `mod/pet-window`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (Labels, StatusBars, Buttons) with clean layout. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/PetWindow.lua` |
| XML | `Source/PetWindow.xml` |

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.Pets` | `RegisterWindowData(WindowData.Pets.Type, 0)` | Pet list: IDs, names, health |
| `WindowData.MobileName` | Per-pet by mobile ID | Pet names with notoriety |
| `WindowData.MobileStatus` | Per-pet by mobile ID | Pet health values |
| `WindowData.HealthBarColor` | Per-pet by mobile ID | Pet health bar color |

## Key Interactions

- **Health bars** per pet — real-time updates
- **Click on pet** → select that pet as target
- **Show/hide** toggle between expanded and minimized views
- **Lock button** — prevent repositioning
- Pet list updates when pets come in/out of range
- Transfer commands to pets

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdatePets` — needs `DataEvent(WindowData.Pets, "OnUpdatePets")`

### Missing Data Wrappers
- `Data.Pets()` — new wrapper exposing pet list with IDs, providing iteration over pet entries

### Missing DefaultComponents
- `DefaultPetWindowComponent` — wrapping the `PetWindow` global

### Missing API Wrappers
- None identified — existing Api.StatusBar, Api.Label, Api.Window should suffice

## Mod Structure

```
src/mods/mongbat-pet-window/
    MongbatPetWindow.mod
    MongbatPetWindowMod.lua
```

## Acceptance Criteria

- [ ] Default PetWindow is fully suppressed
- [ ] All controlled pets display with names and health bars
- [ ] Health bars update in real-time
- [ ] Click on pet entry targets that pet
- [ ] Pet list updates dynamically as pets enter/leave range
- [ ] Compact/expanded view toggle
- [ ] Clean shutdown restores default window
- [ ] All engine calls go through Mongbat context wrappers
