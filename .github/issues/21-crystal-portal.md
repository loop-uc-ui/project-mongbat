# Reimplement CrystalPortal as Mongbat Mod

## Overview

Replace the default `CrystalPortal` with a Mongbat mod (`mongbat-crystal-portal`). The Crystal Portal is an interactive gump triggered by a server-side gump (TID 1113945) that lets players teleport to predefined destinations across Trammel and Felucca, organized by category (Dungeons, Moongates, Banks, plus a skill-gated Wind destination).

**Complexity:** Medium
**Priority:** Tier 6
**Branch:** `mod/crystal-portal`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. Use Mongbat components (Labels, Buttons) with clean layout. The default uses ComboBoxes for destination selection and radio buttons for facet/category — the Mongbat version should use equivalent simple controls.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/CrystalPortal.lua` |
| XML | `Source/CrystalPortal.xml` |

Fetch both files completely before writing any code.

## Architecture

The CrystalPortal is triggered by GumpsParsing when a gump with TID 1113945 is detected. It is NOT a standard window toggle — it is created on demand via `GumpsParsing.RegisteredTIDHandlers[1113945]`.

### Data Flow

1. Server sends a generic gump
2. `GumpsParsing` detects TID 1113945 → calls `CrystalPortal.Initialize()`
3. Player picks facet (Trammel/Felucca), category (Dungeons/Moongates/Banks), and destination from ComboBox
4. Player clicks "GO!" → `CrystalPortal.GoButton()` formats a chat command and calls `SendChat(cmd)`
5. Wind destination requires Magery ≥ 71.5 skill check via `WindowData.SkillDynamicData`

### Destination Tables

The default UI defines 3 destination tables per facet:

| Category | Trammel var | Felucca var | Count |
|----------|-------------|-------------|-------|
| Dungeons | `CrystalPortal.TrammelDungeons` | `CrystalPortal.FeluccaDungeons` | ~15 each |
| Moongates | `CrystalPortal.TrammelMoongates` | `CrystalPortal.FeluccaMoongates` | ~10 each |
| Banks | `CrystalPortal.TrammelBanks` | `CrystalPortal.FeluccaBanks` | ~30 each |

Each entry has `{ name = L"LocationName" }`.

Wind is a special 4th destination (only when Magery ≥ 71.5).

### Persistence

Uses `Interface.LoadNumber` / `Interface.SaveNumber` for:
- `CrystalPortalMap` — last selected facet (1=Trammel, 2=Felucca)
- `CrystalPortalArea` — last selected category (1-3)
- `CrystalPortalSelection` — last selected destination index

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `SendChat(command)` | Sends a chat command to navigate (e.g. `"/teleport Britain Bank"`) |
| `Interface.LoadNumber(key, default)` | Load persisted setting |
| `Interface.SaveNumber(key, value)` | Save persisted setting |
| `ComboBoxAddMenuItem(name, text)` | Add destination to dropdown |
| `ComboBoxGetSelectedMenuItem(name)` | Get selected destination index |
| `ComboBoxClearMenuItems(name)` | Clear dropdown |
| `GumpsParsing.RegisteredTIDHandlers` | TID → handler table for gump interception |

## Key Interactions

- **Facet toggle buttons** (Trammel / Felucca) → filter destinations
- **Category toggle buttons** (Dungeons / Moongates / Banks) → switch destination list
- **ComboBox** → select specific destination
- **GO! button** → teleport to selected destination via `SendChat`
- **Wind** appears as destination option only when Magery ≥ 71.5

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultCrystalPortalComponent` — for `CrystalPortal` global table

### Missing API Wrappers
- `Api.Chat.Send(command)` — wrapper for `SendChat`
- `Api.Interface.LoadNumber(key, default)` / `Api.Interface.SaveNumber(key, value)` — persistence wrappers (may already exist, verify)

### Missing Data Wrappers
- `Data.SkillDynamicData()` — for reading skill levels (Magery check). May already exist from SkillsWindow work.

### GumpsParsing Integration
- The mod must register itself as a TID handler in GumpsParsing. `Components.Defaults.GumpsParsing` or `Components.Defaults.CrystalPortal` must be used.

## Mod Structure

```
src/mods/mongbat-crystal-portal/
    MongbatCrystalPortal.mod
    MongbatCrystalPortalMod.lua
```

## Implementation Notes

- The window is created/destroyed on demand (lazy creation), not pre-created at startup.
- `Interface.DestroyWindowOnClose` is set — the window is destroyed when closed.
- The facet/category buttons use `ButtonSetCheckButtonFlag` for radio-button behavior.
- The default stores its GumpsParsing gump data in `CrystalPortal.gumpData` / `CrystalPortal.gumpID` and calls `GumpsParsing.PressButton` on shutdown to properly close the server-side gump.
- SnappableWindows integration: adds window name to `SnapUtils.SnappableWindows`.

## Acceptance Criteria

- [ ] Default CrystalPortal is fully suppressed (CrystalPortal global table replaced)
- [ ] Crystal Portal opens when server sends gump with TID 1113945
- [ ] Trammel/Felucca facet toggle works
- [ ] Dungeons/Moongates/Banks category selection works
- [ ] Destination list populates correctly per facet+category
- [ ] GO! button teleports to selected destination
- [ ] Wind destination appears only when Magery ≥ 71.5
- [ ] Last selections persisted across sessions
- [ ] Server gump properly closed on window close (GumpsParsing.PressButton)
- [ ] Clean shutdown restores default
- [ ] All engine calls go through Mongbat context wrappers
