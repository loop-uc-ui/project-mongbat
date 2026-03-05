# Reimplement TargetWindow as Mongbat Mod

## Overview

Replace the default `TargetWindow` with a Mongbat mod (`mongbat-target-window`). The target window shows the currently selected target's name, health bar, and provides quick-action buttons.

**Complexity:** Low-Medium
**Priority:** Tier 1
**Branch:** `mod/target-window`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (Labels, StatusBars, DynamicImages, Buttons) with clean layout. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/TargetWindow.lua` |
| XML | `Source/TargetWindow.xml` |

Fetch both files completely before writing any code.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.CurrentTarget` | `RegisterWindowData(WindowData.CurrentTarget.Type, 0)` | Target ID, updates on target change |
| `WindowData.MobileName` | Per-entity via target ID | Target name + notoriety |
| `WindowData.MobileStatus` | Per-entity via target ID | Health values |
| `WindowData.HealthBarColor` | Per-entity via target ID | Health bar tint color |

## Key Interactions

- **Left click** on target health bar → re-target
- **Right click** → context menu on target
- **Lock/unlock** toggle button
- **Close button** → clear target
- Health bar updates in real-time

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdateCurrentTarget` — needs DataEvent for `WindowData.CurrentTarget`

### Missing Data Wrappers
- `Data.CurrentTarget()` — **exists** but verify it exposes `TargetId`

### Missing DefaultComponents
- `DefaultTargetWindowComponent` — needs to be added to Mongbat.lua

## Mod Structure

```
src/mods/mongbat-target-window/
    MongbatTargetWindow.mod
    MongbatTargetWindowMod.lua
```

## Acceptance Criteria

- [ ] Default TargetWindow is fully suppressed
- [ ] Target name shows with notoriety color
- [ ] Health bar updates in real-time with correct color
- [ ] Right-click opens context menu on target
- [ ] Left-click re-targets the mobile
- [ ] Window appears on target acquisition, hides on target clear
- [ ] Clean shutdown restores default window
- [ ] All engine calls go through Mongbat context wrappers
