# Reimplement UserWaypointWindow as Mongbat Mod

## Overview

Replace the default `UserWaypointWindow` with a Mongbat mod (`mongbat-user-waypoint`). The User Waypoint Window allows players to create, edit, and view map waypoints with custom names, icons, coordinate entry (lat/long or X/Y), and icon scaling. It is opened from the map context menu.

**Complexity:** High
**Priority:** Tier 6
**Branch:** `mod/user-waypoint`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. Use Mongbat components for the coordinate inputs, icon picker, and buttons. The default uses ComboBoxes for icon type selection — use a simple list or dropdown equivalent.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/UserWaypointWindow.lua` |
| XML | `Source/UserWaypointWindow.xml` |
| Lua (dependency) | `Source/MapCommon.lua` |

Fetch all files before writing any code. MapCommon.lua contains coordinate conversion functions used by this window.

## Architecture

### Dual Modes

The window operates in two modes:
1. **Create mode** (`InitializeCreateWaypointData`) — blank form for new waypoint
2. **View/Edit mode** (`InitializeViewWaypointData`) — pre-filled form for existing waypoint

The mode is determined by the `params` table passed during initialization from the map window.

### Icon System

61 predefined icon types defined in `UserWaypointWindow.Icons` table:
- Each entry: `{ id = N, name = L"IconName" }`
- Icons range from "Custom" (id=0) through game-specific types (Dungeon, Bank, Healer, Inn, Moongate, etc.) to letters and symbols
- Icon scale adjustable from 0.2 to 2.0 in 0.2 increments

### Coordinate System

Two coordinate display modes, toggled by `ToggleCoord()`:
1. **Lat/Long** — degrees/minutes format with N/S/E/W direction (e.g., "45° 12'N 120° 30'W")
2. **X/Y** — raw game coordinates

Conversion uses `MapCommon.ConvertToXYMinutes()` for lat/long → X/Y conversion.

Coordinate input fields:
- `LatDegrees`, `LatMinutes`, `LatDirection` (N/S ComboBox)
- `LongDegrees`, `LongMinutes`, `LongDirection` (E/W ComboBox)
- `XCoord`, `YCoord` (in X/Y mode)

### Waypoint Name Encoding

When creating a waypoint, the name string encodes metadata:
```
"WaypointName_ICON_xxx_SCALE_yyy_DUNG__ABYSS_"
```
- `_ICON_` prefix + icon type id
- `_SCALE_` prefix + scale value (multiplied by 10)
- `_DUNG_` flag for dungeon waypoints
- `_ABYSS_` flag for Abyss waypoints

### TIDs

| TID field | Value | Text |
|-----------|-------|------|
| Okay | 3000093 | "Okay" |
| Cancel | 1006045 | "Cancel" |
| CreateWaypoint | 1155145 | "Create Waypoint" |
| EditWaypoint | 1155146 | "Edit Waypoint" |
| ViewWaypoint | 1155147 | "View Waypoint" |
| Lat | 1154915 | "Lat" |
| Long | 1154916 | "Long" |
| X | 1155148 | "X" |
| Y | 1155149 | "Y" |
| N | 1155150 | "N" |
| S | 1155151 | "S" |
| E | 1155152 | "E" |
| W | 1155153 | "W" |

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.WaypointDisplay` | `RegisterWindowData(WindowData.WaypointDisplay.Type, 0)` | Waypoint display data, `typeNames` array |

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `UOCreateUserWaypoint(type, x, y, facet, encodedName)` | Create a user waypoint with encoded name |
| `MapCommon.ConvertToXYMinutes(degrees, minutes, direction, isLat)` | Convert lat/long to X/Y |
| `ComboBoxAddMenuItem(name, text)` | Add icon type to dropdown |
| `ComboBoxGetSelectedMenuItem(name)` | Get selected icon type index |
| `TextEditBoxSetText(name, text)` / `TextEditBoxGetText(name)` | Input field access |

## Key Interactions

- **Name text input** → waypoint name
- **Icon type ComboBox** → select from 61 icon types
- **Icon scale +/- buttons** → adjust scale 0.2–2.0
- **Coordinate mode toggle** → switch between Lat/Long and X/Y
- **Coordinate inputs** → degrees/minutes/direction or X/Y values
- **Okay button** → create/save waypoint
- **Cancel button** → close without saving

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultUserWaypointWindowComponent` — for `UserWaypointWindow` global table

### Missing API Wrappers
- `Api.Map.CreateUserWaypoint(type, x, y, facet, name)` — wrapper for `UOCreateUserWaypoint`

### Missing Data Wrappers
- `Data.WaypointDisplay()` — wrapper for `WindowData.WaypointDisplay`

### MapCommon Dependency
- The mod will need to access `MapCommon.ConvertToXYMinutes` and related coordinate utilities. These should be wrapped or the MapCommon default component used.

## Mod Structure

```
src/mods/mongbat-user-waypoint/
    MongbatUserWaypoint.mod
    MongbatUserWaypointMod.lua
```

## Implementation Notes

- The window is created on demand from the map context menu, not pre-created at startup.
- `params` carries: `x`, `y`, `facet`, `mapWindow`, `isDungeon`, `isAbyss`, `waypointId` (for edit/view mode), `name`, `type`, `scale`
- In view mode, coordinate fields are read-only and pre-populated. The window title changes to "View Waypoint" or "Edit Waypoint".
- The icon preview (`UserWaypointWindowTypeIcon`) shows the selected icon at the current scale using `DynamicImageSetTexture`.
- Scale is stored as a float but encoded in the name string multiplied by 10 (integer).
- The default facet ComboBox shows the map the waypoint is on — for new waypoints this comes from the map window's current facet.
- Heavy dependency on `MapCommon` for coordinate conversions and waypoint type constants.

## Acceptance Criteria

- [ ] Default UserWaypointWindow is fully suppressed (UserWaypointWindow global table replaced)
- [ ] Create mode: blank form opens from map context menu
- [ ] View mode: pre-filled form opens for existing waypoints
- [ ] 61 icon types available in picker
- [ ] Icon scale adjustment (0.2–2.0) works
- [ ] Lat/Long ↔ X/Y coordinate toggle works
- [ ] Coordinate input fields work correctly
- [ ] Okay button creates waypoint with properly encoded name
- [ ] Cancel closes without saving
- [ ] Clean shutdown unregisters data and restores default
- [ ] All engine calls go through Mongbat context wrappers
