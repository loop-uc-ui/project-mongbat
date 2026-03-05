# Reimplement ContainerWindow as Mongbat Mod

## Overview

Replace the default `ContainerWindow` with a Mongbat mod (`mongbat-container-window`). Container windows display inventory grids for backpacks, chests, corpses, and other containers.

**Complexity:** High
**Priority:** Tier 2
**Branch:** `mod/container-window`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (DynamicImages, Labels) in a simple grid layout. Focus on **functionality over visual parity** — the goal is a clean, minimal grid-only replacement, not a pixel-perfect clone. **Skip legacy container view** — grid view only.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/ContainerWindow.lua` |
| XML | `Source/ContainerWindow.xml` |
| Lua (settings) | `Source/settingswindow.lua` (container grid settings section) |

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.ContainerWindow` | Per-container by object ID | Container contents: item IDs, hues, quantities, grid positions |
| `WindowData.ContainerWindowInfo` | Per-container | Container metadata |

## Key Interactions

- **Grid view** — items displayed in grid cells with icons and quantities
- **Legacy view** — items displayed at free-form positions (like Classic Client)
- **Left click** → select item
- **Double click** → use item (open sub-container, equip, eat, etc.)
- **Right click** → context menu on item
- **Drag from container** → pick up item (DragSlot system)
- **Drop into container** → place item at grid position
- **Tooltips** — hover shows item properties
- **Resize** — grid containers are resizable
- **Grid color customization** — alternating slot colors from settings
- **Multiple simultaneous containers** — many container windows can be open

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdateContainerWindow` — needs `DataEvent(WindowData.ContainerWindow, "OnUpdateContainerWindow")`
- `OnUpdateContainerWindowInfo` — for container metadata changes

### Missing Data Wrappers
- `Data.ContainerWindow(id)` — new wrapper exposing item array with icon, hue, quantity, grid position
- `Data.ContainerWindowInfo(id)` — metadata wrapper (name, container type, slot count)

### Missing DefaultComponents
- `DefaultContainerWindowComponent` — wrapping `ContainerWindow` global

### Missing API Wrappers
- `Api.Drag.DropOnContainer` — **already exists**
- `Api.Drag.DropOnObjectAtIndex` — **already exists**
- Container-related settings access may need wrappers

### Architecture Notes

This is another **multi-instance system** — many container windows exist simultaneously. Each is created by the engine when a container is opened (via server packet). The `Interface.lua` file has a `ContainerWindow` creation path to trace.

Container windows have TWO distinct modes (grid vs legacy) controlled by `SystemData.Settings.Interface.LegacyContainers`. Grid mode uses a uniform grid layout; legacy mode uses per-item x/y coordinates and legacy container background art.

## Mod Structure

```
src/mods/mongbat-container-window/
    MongbatContainerWindow.mod
    MongbatContainerWindowMod.lua
```

## Acceptance Criteria

- [ ] Default ContainerWindow is fully suppressed
- [ ] Grid view displays all items with correct icons and quantities
- [ ] Double-click uses items (open bags, equip, eat, etc.)
- [ ] Drag and drop works (pick up items, drop into slots)
- [ ] Right-click opens context menu
- [ ] Tooltips show item properties on hover
- [ ] Multiple container windows can be open simultaneously
- [ ] Container window closes when container goes out of range
- [ ] Player backpack works correctly
- [ ] Clean shutdown restores default container system
- [ ] All engine calls go through Mongbat context wrappers
