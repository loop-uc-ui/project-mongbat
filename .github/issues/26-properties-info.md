# Reimplement PropertiesInfo as Mongbat Mod

## Overview

Replace the default `PropertiesInfo` with a Mongbat mod (`mongbat-properties-info`). The Properties Info window displays item properties for the currently equipped/active item. It shows a searchable, scrollable list of item properties with their names, descriptions, and active/inactive status. It is opened from the ItemProperties system.

**Complexity:** Medium
**Priority:** Tier 6
**Branch:** `mod/properties-info`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. Use Mongbat components for the property list, search box, and item icon. Display properties as a clean scrollable list with visual indication of active vs inactive properties.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/PropertiesInfo.lua` |
| Lua (dependency) | `Source/ItemProperties.lua` |
| XML | `Source/PropertiesInfo.xml` |

Fetch all files before writing any code. ItemProperties.lua provides `GetActiveProperties()` and related functions.

## Architecture

### Data Flow

1. `PropertiesInfo.Toggle()` opens/closes the window
2. On open, `Restart()` calls `ItemProperties.GetActiveProperties()` to get current item's properties
3. Properties read from `WindowData.PlayerItemPropCSV` (loaded CSV data)
4. Each property has: NameTID, DescriptionTID, active/inactive status
5. Search filters properties by name match
6. Mouse-over shows description tooltip

### Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `ITEMPROPERTY_OFFSET` | 5000 | Offset for property IDs |
| `ITEMPROPICON` | 3015 | Default icon texture ID |

### Toggle/Close Pattern

```
Toggle() → if showing: Close() | else: Show + Restart()
Close() → ClearMouseOverItem + Reset + Hide
Restart() → GetActiveProperties + populate list
```

### Info Text TID

`1154921` — instructional text shown in the window.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.PlayerItemPropCSV` | Loaded via `UOBuildTableFromCSV` at startup | CSV data with property NameTID, DescriptionTID fields |

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `ItemProperties.GetActiveProperties()` | Returns active properties for current item |
| `ItemProperties.ClearMouseOverItem()` | Clear tooltip state |
| `ItemProperties.SetActiveItem(itemData)` | Set item for tooltip display on mouse-over |
| `WindowData.PlayerItemPropCSV[i].NameTID` | Property name TID |
| `WindowData.PlayerItemPropCSV[i].DescriptionTID` | Property description TID |

## Key Interactions

- **Open/Toggle** — standard toggle via menu or button
- **Search text input** → filters property list by name
- **Property list item mouse-over** → shows description tooltip
- **Scroll** → navigate property list
- **Snappable** — added to `SnapUtils.SnappableWindows`

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultPropertiesInfoComponent` — for `PropertiesInfo` global table

### Missing API Wrappers
- `Api.ItemProperties.GetActiveProperties()` — wrapper for `ItemProperties.GetActiveProperties`
- `Api.ItemProperties.ClearMouseOverItem()` — may already exist
- `Api.ItemProperties.SetActiveItem(itemData)` — may already exist

### Missing Data Wrappers
- `Data.PlayerItemPropCSV()` — wrapper for `WindowData.PlayerItemPropCSV`

## Mod Structure

```
src/mods/mongbat-properties-info/
    MongbatPropertiesInfo.mod
    MongbatPropertiesInfoMod.lua
```

## Implementation Notes

- The window uses `SnapUtils.SnappableWindows` for snap-to-edge behavior.
- Position is persisted via `WindowUtils.SaveWindowPosition` / `RestoreWindowPosition`.
- The default UI creates scroll list items using `CreateWindowFromTemplate("ItemTemplatePR"..i, "ItemTemplatePR", scrollChild)`.
- Active properties are shown enabled; remaining properties shown disabled (visually dimmed).
- Search is case-insensitive by converting to lowercase with `WStringToString` and comparing.
- The window should be created on demand (lazy creation), not at mod init.
- `PropertiesInfo.Items` stores the list of created template window references for cleanup.

## Acceptance Criteria

- [ ] Default PropertiesInfo is fully suppressed (PropertiesInfo global table replaced)
- [ ] Properties Info window opens and shows item properties
- [ ] Active properties visually distinguished from inactive
- [ ] Search/filter by property name works
- [ ] Mouse-over shows property description tooltip
- [ ] Scroll works for long property lists
- [ ] Window position saved/restored
- [ ] Clean shutdown restores default
- [ ] All engine calls go through Mongbat context wrappers
