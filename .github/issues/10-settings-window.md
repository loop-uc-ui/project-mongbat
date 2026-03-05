# Reimplement SettingsWindow as Mongbat Mod

## Overview

Replace the default `SettingsWindow` with a Mongbat mod (`mongbat-settings-window`). The settings window is a large tabbed panel covering graphics, sound, key bindings, gameplay options, legacy settings, profanity filter, overhead text, container settings, health bar settings, and mobile display settings.

**Complexity:** Very High
**Priority:** Tier 3
**Branch:** `mod/settings-window`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (Labels, Buttons, Sliders, ComboBoxes) in a simple tabbed layout. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/settingswindow.lua` (~2400 lines) |
| XML | `Source/settingswindow.xml` |

**Note:** This is one of the largest files in the default UI.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `SystemData.Settings.*` | Read/write | All game settings (graphics, sound, options) |
| `WindowData.BadWordList` | For profanity filter | Bad word entries |

## Key Interactions

- **Tab navigation** — 11 settings pages via tabs
- **Sliders** — volume, gamma, zoom, etc.
- **Checkboxes** — toggle options on/off
- **Dropdowns (ComboBox)** — resolution, language, display modes
- **Key binding editor** — record key combinations for actions
- **Color pickers** — container grid colors, overhead text colors
- **Apply/OK/Cancel** — commit or discard changes
- **UserSettingsChanged()** — push changes to C++ engine
- **Profanity filter** — add/remove bad words

## Framework Gaps to Address

### Missing Data Wrappers
- `Data.Settings()` — wrapper for `SystemData.Settings.*` sub-tables (Graphics, Sound, GameOptions, Interface, Language, etc.)
- This is a massive surface area — may need individual getters/setters per setting category

### Missing DefaultComponents
- `DefaultSettingsWindowComponent` — wrapping `SettingsWindow` global

### Missing API Wrappers
- `Api.Settings.UserSettingsChanged()` — wrapping `UserSettingsChanged()` engine call
- `Api.Settings.GetResolutions()` — wrapping resolution enumeration
- Key binding recording functions
- Various engine-level setting accessors

### Architecture Notes

This window is best approached incrementally:
1. **Phase 1:** Graphics and sound settings (sliders, dropdowns)
2. **Phase 2:** Gameplay options (checkboxes, toggles)
3. **Phase 3:** Key bindings (complex recording system)
4. **Phase 4:** Profanity, overhead text, container, health bar settings

The `UserSettingsChanged()` call pushes Lua-side settings to the C++ engine. Missing this call means settings won't take effect. Many settings directly modify `SystemData.Settings.*` tables and then call `UserSettingsChanged()`.

## Mod Structure

```
src/mods/mongbat-settings-window/
    MongbatSettingsWindow.mod
    MongbatSettingsWindowMod.lua
```

## Acceptance Criteria

- [ ] Default SettingsWindow is fully suppressed
- [ ] All 11 settings tabs are accessible
- [ ] Graphics settings (resolution, gamma, effects) work
- [ ] Sound settings (volume sliders, toggles) work
- [ ] Key bindings can be viewed and modified
- [ ] Gameplay options toggle correctly
- [ ] Settings persist across sessions (UserSettingsChanged() called)
- [ ] Apply/OK commits changes, Cancel discards
- [ ] Clean shutdown restores default settings window
- [ ] All engine calls go through Mongbat context wrappers
