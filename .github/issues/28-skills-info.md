# Reimplement SkillsInfo as Mongbat Mod

## Overview

Replace the default `SkillsInfo` with a Mongbat mod (`mongbat-skills-info`). The Skills Info window is a detail popup that shows comprehensive information about a selected skill — description, requirements, usage methods (direct/interactive/automatic), title unlocked, training methods, and external links. It anchors to the Skills Window.

**Complexity:** Medium-High
**Priority:** Tier 6
**Branch:** `mod/skills-info`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. Display skill information as a scrollable text layout with labeled sections. The default uses many dynamically created label templates — the Mongbat version should use a cleaner approach with fewer templates.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/SkillsInfo.lua` |
| XML | `Source/SkillsInfo.xml` |
| Lua (dependency) | `Source/SkillsWindow.lua` |

Fetch SkillsInfo.lua and its XML completely before writing any code.

## Architecture

### Skill Data Structure

58 skill data arrays (`skill01` through `skill58`), each with 8 elements:

```lua
local skillNN = {
    titleTID,       -- [1] Skill title TID
    descTID,        -- [2] Description TID
    reqTID,         -- [3] Requirements TID
    directTID,      -- [4] Direct usage TID (0 = no direct usage)
    interTID,       -- [5] Interactive usage TID (0 = no interactive usage)
    autoTID,        -- [6] Automatic usage TID (0 = no automatic usage)
    moreTID,        -- [7] "More info" TID (0 = none)
    className       -- [8] Class name wstring (e.g., L"warrior", L"mage")
}
```

All 58 arrays are collected into `SkillsInfo.SkillInfoData[1..58]`.

### Section Layout

`UpdateGump(DisplaySkill)` creates sections in order:

1. **Description** — always shown (from descTID)
2. **Requirements** — always shown (from reqTID)
3. **Direct Usage** — optional, only if directTID > 0
4. **Interactive Usage** — optional, only if interTID > 0
5. **Automatic Usage** — optional, only if autoTID > 0
6. **Title Unlocked** — optional, only if titleTID > 0
7. **Training Methods** — loaded from external text file
8. **More** — optional, only if moreTID > 0

Each section has a title label and description label, created dynamically using `LabelTitle` and `LabelDescription` templates inside a scroll window.

### Training Text

Training methods text is loaded from the filesystem:
```lua
UOLoadTextFile("uo-skillinfo-training-" .. className .. ".txt")
```
The text is read from `WindowData.UOLoadTextFile.Text`.

### TIDs for Section Headers

| TID field | Value | Text |
|-----------|-------|------|
| TID_WINDOW_NAME | 1078584 | Window title |
| TID_REQUIRES | 1078597 | "Requirements" |
| TID_DIRECT | 1078598 | "Direct Usage" |
| TID_INTER | 1078599 | "Interactive Usage" |
| TID_AUTO | 1078600 | "Automatic Usage" |
| TID_TITLE | 1078596 | "Title Unlocked" |
| TID_TRAINING | 1079763 | "Training Methods" |
| TID_MORE | 1079764 | "More" |

### Anchoring

The window anchors to `SkillsWindow`:
```lua
WindowClearAnchors("SkillsInfo")
WindowAddAnchor("SkillsInfo", "topright", "SkillsWindow", "topleft", 0, 0)
```

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `GetStringFromTid(tid)` | Get localized text for TIDs |
| `UOLoadTextFile(filename)` | Load training text from filesystem |
| `WindowData.UOLoadTextFile.Text` | Retrieved text content |
| `CreateWindowFromTemplate(name, template, parent)` | Create section labels dynamically |
| `WindowAddAnchor(...)` | Anchor to SkillsWindow |

## Key Interactions

- **Skill selection in SkillsWindow** → triggers `UpdateGump(skillIndex)` to populate info
- **Scroll** → navigate through skill details
- **Window anchored** to SkillsWindow's right edge

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultSkillsInfoComponent` — for `SkillsInfo` global table

### Missing API Wrappers
- `Api.File.LoadTextFile(filename)` — wrapper for `UOLoadTextFile`

### Missing Data Wrappers
- `Data.LoadedTextFile()` — wrapper for `WindowData.UOLoadTextFile`

### Skill Data
- The 58 skill data arrays are hardcoded in SkillsInfo.lua — they must be replicated or accessed from the default component. These are static TID references, so they can be constants in the mod.

## Mod Structure

```
src/mods/mongbat-skills-info/
    MongbatSkillsInfo.mod
    MongbatSkillsInfoMod.lua
```

## Implementation Notes

- The window is shown when a skill is selected in SkillsWindow — the SkillsWindow calls `SkillsInfo.UpdateGump(skillIndex)`.
- `ClearGump()` destroys all previously created template windows (SkillDesc, RequirementsLbL, DirectLbL, InterLbL, AutoLbL, TtleLbL, MoreLbL, TrainLbL patterns).
- The skill index maps to `SkillsInfo.SkillInfoData[index]` to get the 8 TID values.
- Sections are created conditionally — only sections with non-zero TIDs are shown.
- The scroll child window auto-sizes based on content via sequential anchoring of label templates.
- Position is persisted via `WindowUtils.SaveWindowPosition` / `RestoreWindowPosition`.
- The mod needs to expose a function that SkillsWindow (or its Mongbat replacement) can call to display skill details. This integration point is critical.

## Acceptance Criteria

- [ ] Default SkillsInfo is fully suppressed (SkillsInfo global table replaced)
- [ ] Skills Info window opens anchored to Skills Window
- [ ] All 58 skills display correct description sections
- [ ] Conditional sections (Direct/Interactive/Automatic/Title/More) only shown when applicable
- [ ] Training methods text loaded from filesystem
- [ ] Scroll works for long skill descriptions
- [ ] ClearGump properly cleans up template windows
- [ ] Window position saved/restored
- [ ] Clean shutdown restores default
- [ ] All engine calls go through Mongbat context wrappers
