# Reimplement MapFind as Mongbat Mod

## Overview

Replace the default `MapFind` with a Mongbat mod (`mongbat-map-find`). The Map Find window is a search tool for the map — it lets players search for locations by name across built-in waypoints and user-created waypoints, then center the map on a selected result.

**Complexity:** Medium
**Priority:** Tier 6
**Branch:** `mod/map-find`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. Use Mongbat components for the search input, results scroll list, and Locate button.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/MapFind.lua` |
| Lua (dependency) | `Source/Waypoints.lua` |
| Lua (dependency) | `Source/MapCommon.lua` |
| XML | `Source/MapFind.xml` |

Fetch MapFind.lua and its XML completely before writing any code. Waypoints.lua contains the built-in location data.

## Architecture

### Data Flow

1. Player types search text in the input box
2. `SearchText()` iterates:
   - `Waypoints.Facet[currentMap]` — built-in location data (towns, dungeons, etc.)
   - `WindowData.WaypointList` — user-created waypoints
3. Matches by lowercase name containment
4. Results displayed as a scroll list with `ItemTemplateMF` template items
5. Selecting an item and clicking Locate → `UOCenterRadarOnLocation(x, y)` centers the map

### Search Algorithm

```lua
-- For each waypoint in current facet + user waypoints:
if string.find(lowercase(waypoint.name), lowercase(searchText)) then
    -- add to results
end
```

### Info Text TID

`1154869` — instructional text shown in the window.

### Toggle/Close Pattern

```
Toggle() → if showing: Close() | else: Show + Restart()
Close() → ClearMouseOverItem + Reset + Hide
```

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.WaypointList` | Read directly | User-created waypoints array |
| `Waypoints.Facet[map]` | Read directly (not WindowData) | Built-in waypoints per facet |

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `UOCenterRadarOnLocation(x, y)` | Center the map on coordinates |
| `ItemProperties.ClearMouseOverItem()` | Clear tooltip state |
| `ItemProperties.SetActiveItem(itemData)` | Set item for tooltip on mouse-over |

## Key Interactions

- **Search text input** → filter locations by name
- **Results list item click** → select a location
- **Locate button** → center map on selected location via `UOCenterRadarOnLocation`
- **Mouse-over result** → show tooltip with facet name and coordinates
- **Snappable** — added to `SnapUtils.SnappableWindows`

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultMapFindComponent` — for `MapFind` global table

### Missing API Wrappers
- `Api.Map.CenterOnLocation(x, y)` — wrapper for `UOCenterRadarOnLocation`

### Missing Data Wrappers
- `Data.WaypointList()` — wrapper for `WindowData.WaypointList`
- Access to `Waypoints.Facet` — may need `Components.Defaults.Waypoints` or a Data wrapper

## Mod Structure

```
src/mods/mongbat-map-find/
    MongbatMapFind.mod
    MongbatMapFindMod.lua
```

## Implementation Notes

- The window uses `SnapUtils.SnappableWindows` for snap-to-edge behavior.
- Position is persisted via `WindowUtils.SaveWindowPosition` / `RestoreWindowPosition`.
- The default UI creates scroll list items using `CreateWindowFromTemplate("ItemTemplateMF"..i, "ItemTemplateMF", scrollChild)`.
- `MapFind.Items` stores references to created template windows for cleanup.
- The current map index comes from the map window's state — the mod needs access to `MapCommon` or the map's current facet.
- Mouse-over tooltip shows: facet name (from `Waypoints.FacetNames[facet]`) + coordinates.
- The window should be created on demand (lazy creation), opened from the map window.
- `ClearItemList()` destroys all template items before repopulating.

## Acceptance Criteria

- [ ] Default MapFind is fully suppressed (MapFind global table replaced)
- [ ] Map Find window opens and shows search input
- [ ] Search filters built-in waypoints by name
- [ ] Search also includes user-created waypoints
- [ ] Results displayed as scrollable list
- [ ] Locate button centers map on selected result
- [ ] Mouse-over shows location tooltip with coordinates
- [ ] Window position saved/restored
- [ ] Clean shutdown restores default
- [ ] All engine calls go through Mongbat context wrappers
