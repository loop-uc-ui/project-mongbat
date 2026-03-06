# Reimplement IgnoreWindow as Mongbat Mod

## Overview

Replace the default `IgnoreWindow` with a Mongbat mod (`mongbat-ignore-window`). The Ignore Window displays a list of recent chat players and allows the user to add them to an ignore list. It is accessed from the Settings Window's chat settings.

**Complexity:** Low
**Priority:** Tier 6
**Branch:** `mod/ignore-window`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. Display a scrollable list of player names with a button to add each to the ignore list.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/IgnoreWindow.lua` |
| XML | `Source/IgnoreWindow.xml` |

Fetch both files completely before writing any code.

## Architecture

### Data Flow

1. Window reads `WindowData.RecentChatPlayerListCount` for the number of recent chat players
2. Iterates `WindowData.RecentChatPlayerIdList[i]` and `WindowData.RecentChatPlayerNameList[i]`
3. Creates a scroll list of player names
4. Add button calls `AddPlayerToIgnoreList(playerId, ignoreListType)`

### Integration with SettingsWindow

`SettingsWindow.ignoreListType` determines which ignore list type to use when adding. The IgnoreWindow reads this value when adding a player.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.RecentChatPlayerListCount` | Read directly | Number of recent chat players |
| `WindowData.RecentChatPlayerIdList` | Read directly | Array of player entity IDs |
| `WindowData.RecentChatPlayerNameList` | Read directly | Array of player names (wstring) |

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `AddPlayerToIgnoreList(playerId, listType)` | Add a player to the specified ignore list |

## Key Interactions

- **Player name click / Add button** → add player to ignore list
- **Scroll** → navigate long player list
- Window opened on demand from Settings

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultIgnoreWindowComponent` — for `IgnoreWindow` global table

### Missing API Wrappers
- `Api.Chat.AddPlayerToIgnoreList(playerId, listType)` — wrapper for `AddPlayerToIgnoreList`

### Missing Data Wrappers
- `Data.RecentChatPlayerList()` — wrapper for `WindowData.RecentChatPlayerListCount`, `WindowData.RecentChatPlayerIdList`, `WindowData.RecentChatPlayerNameList`

## Mod Structure

```
src/mods/mongbat-ignore-window/
    MongbatIgnoreWindow.mod
    MongbatIgnoreWindowMod.lua
```

## Implementation Notes

- The default UI creates items with `CreateWindowFromTemplate("IgnoreWindowItem"..i, "IgnoreWindowItemTemplate", scrollChild)`.
- Each list item has an OnLButtonUp handler that adds the player and refreshes the list.
- The window is relatively simple — a scroll list + add functionality.
- `SettingsWindow.ignoreListType` must be accessed through `Components.Defaults.SettingsWindow` or a Data wrapper.

## Acceptance Criteria

- [ ] Default IgnoreWindow is fully suppressed (IgnoreWindow global table replaced)
- [ ] Ignore Window opens and displays recent chat players
- [ ] Player list shows names correctly
- [ ] Add-to-ignore functionality works
- [ ] Scroll works for long player lists
- [ ] Clean shutdown restores default
- [ ] All engine calls go through Mongbat context wrappers
