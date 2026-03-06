# Reimplement TipoftheDayWindow as Mongbat Mod

## Overview

Replace the default `TipoftheDayWindow` with a Mongbat mod (`mongbat-tip-of-the-day`). The Tip of the Day window shows a random gameplay tip loaded from a CSV file. It appears on login (if enabled) and offers Next/Close buttons plus a "Do not show again" checkbox.

**Complexity:** Low
**Priority:** Tier 6
**Branch:** `mod/tip-of-the-day`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. A simple dialog with a text area for the tip, Next/Close buttons, and a checkbox. Clean and readable.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/TipoftheDayWindow.lua` |
| XML | `Source/TipoftheDayWindow.xml` |

Fetch both files completely before writing any code.

## Architecture

### Data Flow

1. On Initialize, loads CSV data: `UOBuildTableFromCSV("Data/GameData/tipoftheday.csv", "TipoftheDayCSV")`
2. `GetRandomTip()` selects random index from `WindowData.TipoftheDayCSV`
3. Tip text displayed in a label (the CSV contains TIDs for tip text)
4. Next button → calls `GetRandomTip()` for another random tip
5. Close button → destroys window
6. "Do not show" checkbox → toggles `SystemData.Settings.Interface.showTipoftheDay`

### TIDs

| TID field | Value | Text |
|-----------|-------|------|
| TipoftheDay | 1094689 | Window title |
| DoNotShow | 1094690 | "Do not show this again" |
| Next | 1043353 | "Next" |
| Close | 1052061 | "Close" |

### Variables

| Variable | Type | Purpose |
|----------|------|---------|
| `tipIndex` | number | Current random tip index |
| `saveOnClose` | boolean | Whether to save settings on close |

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.TipoftheDayCSV` | Loaded via `UOBuildTableFromCSV` | Array of tip entries from CSV |

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `UOBuildTableFromCSV(path, tableName)` | Load CSV into WindowData table |
| `UOUnloadCSVTable(tableName)` | Unload CSV table |
| `GetRandomNumber(max)` | Get random number 0 to max-1 |
| `GetStringFromTid(tid)` | Get localized tip text |
| `SettingsWindow.UpdateSettings()` | Push settings changes |
| `UserSettingsChanged()` | Notify C++ of settings change |

## Key Interactions

- **Next button** → show another random tip
- **Close button** → close/destroy window
- **"Do not show" checkbox** → toggle `showTipoftheDay` setting
- Window appears on login if `showTipoftheDay` is true

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultTipoftheDayWindowComponent` — for `TipoftheDayWindow` global table

### Missing API Wrappers
- `Api.CSV.BuildTable(path, tableName)` — wrapper for `UOBuildTableFromCSV`
- `Api.CSV.Unload(tableName)` — wrapper for `UOUnloadCSVTable`
- `Api.Math.GetRandomNumber(max)` — wrapper for `GetRandomNumber`

### Missing Data Wrappers
- `Data.TipoftheDayCSV()` — wrapper for `WindowData.TipoftheDayCSV`

## Mod Structure

```
src/mods/mongbat-tip-of-the-day/
    MongbatTipOfTheDay.mod
    MongbatTipOfTheDayMod.lua
```

## Implementation Notes

- `Interface.DestroyWindowOnClose["TipoftheDayWindow"] = true` — window destroyed on close, fits lazy creation.
- Shutdown calls `SettingsWindow.UpdateSettings()` and `UserSettingsChanged()` to persist the "do not show" setting.
- Shutdown also calls `UOUnloadCSVTable("TipoftheDayCSV")` to free CSV data.
- This is one of the simplest windows — a text display with two buttons and a checkbox.
- The CSV path is `"Data/GameData/tipoftheday.csv"` — this is a game data file, not a mod file.
- Position is persisted via `WindowUtils.SaveWindowPosition` / `RestoreWindowPosition`.
- The "do not show" button uses `ButtonSetPressedFlag` with the inverse of `showTipoftheDay` (pressed = don't show).

## Acceptance Criteria

- [ ] Default TipoftheDayWindow is fully suppressed (TipoftheDayWindow global table replaced)
- [ ] Tip of the Day window opens on login (if setting enabled)
- [ ] Random tip displayed from CSV data
- [ ] Next button shows another random tip
- [ ] Close button closes/destroys window
- [ ] "Do not show" checkbox toggles the setting
- [ ] Setting persisted via SettingsWindow.UpdateSettings + UserSettingsChanged
- [ ] CSV data loaded on init, unloaded on shutdown
- [ ] Clean shutdown restores default
- [ ] All engine calls go through Mongbat context wrappers
