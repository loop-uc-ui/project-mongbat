# Reimplement BugReportWindow as Mongbat Mod

## Overview

Replace the default `BugReportWindow` with a Mongbat mod (`mongbat-bug-report`). The Bug Report window lets players submit bug reports to the server. It presents 15 bug type categories, a text description area, and Submit/Clear buttons.

**Complexity:** Low-Medium
**Priority:** Tier 6
**Branch:** `mod/bug-report`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. Display bug type categories as labeled radio buttons in a column, with a text area below for the description. Submit/Clear buttons at the bottom.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/BugReportWindow.lua` |
| XML | `Source/BugReportWindow.xml` |

Fetch both files completely before writing any code.

## Architecture

### Bug Type Categories

15 categories defined in `BugReportWindow.bugTypes`:

| Constant | Value | Label (from WindowData.BugReport) |
|----------|-------|---------------------------------|
| BUG_WORLD | 1 | World |
| BUG_WEARABLES | 2 | Wearables |
| BUG_COMBAT | 3 | Combat |
| BUG_UI | 4 | UI |
| BUG_CRASH | 5 | Crash |
| BUG_STUCK | 6 | Stuck |
| BUG_ANIMATIONS | 7 | Animations |
| BUG_PERFORMANCE | 8 | Performance |
| BUG_NPCS | 9 | NPCs |
| BUG_CREATURES | 10 | Creatures |
| BUG_PETS | 11 | Pets |
| BUG_HOUSING | 12 | Housing |
| BUG_LOST_ITEM | 13 | Lost Item |
| BUG_EXPLOIT | 14 | Exploit |
| BUG_OTHER | 15 | Other |

### Data Flow

1. `Initialize()` registers `WindowData.BugReport.Type` with id 0
2. Bug type labels are loaded from `WindowData.BugReport[i].flagName` (server-provided names)
3. Player selects bug type → `SelectBugType(type)` updates button pressed states
4. Player types description in text edit box
5. Submit → `SendBugReport(selectedType, text)` → show confirmation dialog → clear & close
6. Clear → reset to BUG_OTHER, clear text

### TIDs

| TID field | Value | Text |
|-----------|-------|------|
| Bug | 1077790 | "Bug Report" (title) |
| Submit | 1077787 | "Submit" |
| Clear | 3000154 | "Clear" |
| Select | 1077788 | "Select Bug Type" |
| Description | 1077789 | "Please enter description of Bug" |
| Sent | 1077901 | "Your bug has been sent" |

### Toggle/Hide Pattern

The window is toggled via `ToggleWindowByName("BugReportWindow", ...)`. The `Hide()` function uses `ToggleWindowByName` with `OnOpen`/`OnClose` callbacks that manage text box focus.

### Confirmation Dialog

After submission, a `UO_StandardDialog` confirmation dialog is shown:
```lua
{ titleTid = BugReportWindow.TID.Bug, bodyTid = BugReportWindow.TID.Sent, windowName = "BugReportWindow" }
```

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.BugReport` | `RegisterWindowData(WindowData.BugReport.Type, 0)` | Array of bug types with `.flagName` per entry |

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `SendBugReport(type, text)` | Submit bug report to server |
| `RegisterWindowData(WindowData.BugReport.Type, 0)` | Register for bug type data |
| `UnregisterWindowData(WindowData.BugReport.Type, 0)` | Unregister on shutdown |
| `TextEditBoxSetText(name, text)` | Set/clear description text |
| `WindowAssignFocus(name, bool)` | Focus management for text box |
| `UO_StandardDialog.CreateDialog(data)` | Show confirmation after submit |

## Key Events

| Event | Purpose |
|-------|---------|
| `BUG_REPORT_SCREEN` | System event that triggers opening the bug report (registered on Root by Interface) |

## Key Interactions

- **Bug type buttons** → radio-style selection (StayDown flag, mutually exclusive)
- **Description text area** → free-text input
- **Submit button** → send report, show confirmation, clear & close
- **Clear button** → reset type to "Other", clear text
- **Focus management** → text box gets focus on open, loses focus on close

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultBugReportWindowComponent` — for `BugReportWindow` global table

### Missing API Wrappers
- `Api.BugReport.Send(type, text)` — wrapper for `SendBugReport`

### Missing Data Wrappers
- `Data.BugReport()` — wrapper for `WindowData.BugReport` (array of bug types with flagName)

### Missing Constants
- `Constants.BugTypes` — enumeration of the 15 bug type constants

### BUG_REPORT_SCREEN Event
- The system event `BUG_REPORT_SCREEN` is registered on Root by Interface.lua. The mod may need to intercept this or the `Interface.InitBugReport` function to open the Mongbat version.

## Mod Structure

```
src/mods/mongbat-bug-report/
    MongbatBugReport.mod
    MongbatBugReportMod.lua
```

## Implementation Notes

- The window is pre-created at startup (`CreateWindow("BugReportWindow", false)` in Interface.CreateWindows) but shown on demand, unlike most Tier 6 windows. The Mongbat version should use lazy creation instead.
- `BugReportWindow.selectedType` defaults to `BUG_OTHER` (15).
- Bug type buttons use `ButtonSetStayDownFlag` for toggle behavior and `ButtonSetPressedFlag` for mutual exclusion.
- `BugReportWindowReportBoxText.Text` is read to get the description text (engine populates `.Text` on the text edit box's global table).
- The `Interface.InitBugReport` function calls `ToggleWindowByName("BugReportWindow", ...)` — the mod needs to intercept this path.
- MainMenuWindow has a "Bug Report" button that calls `MainMenuWindow.ToggleBugReportWindow()` which calls `ToggleWindowByName`.
- On shutdown, `UnregisterWindowData(WindowData.BugReport.Type, 0)` must be called.

## Acceptance Criteria

- [ ] Default BugReportWindow is fully suppressed (BugReportWindow global table replaced)
- [ ] Bug Report window opens from main menu and BUG_REPORT_SCREEN event
- [ ] 15 bug type categories displayed with server-provided labels
- [ ] Radio-style bug type selection works
- [ ] Description text area accepts input
- [ ] Submit button sends report and shows confirmation dialog
- [ ] Clear button resets form
- [ ] Focus management on open/close
- [ ] WindowData.BugReport registered on init, unregistered on shutdown
- [ ] Clean shutdown restores default
- [ ] All engine calls go through Mongbat context wrappers
