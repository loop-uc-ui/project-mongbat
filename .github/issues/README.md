# Window Reimplementation Issues

Each file in this directory is a GitHub issue body for replacing one default UI window with a Mongbat mod. They are designed to be consumed by an AI coding agent using the copilot-instructions and the reimplementation skill file as context.

## Priority Tiers

| Tier | Windows | Rationale |
|------|---------|-----------|
| **1 — Quick Wins** | TargetWindow, AdvancedBuff, PetWindow | Small scope, few interactions, high visible impact |
| **2 — Core Gameplay** | MobileHealthBar, ContainerWindow, HotbarSystem, SkillsWindow | Medium complexity, essential everyday windows |
| **3 — Complex** | ChatWindow, Shopkeeper, SettingsWindow | Large scope, many sub-windows, lots of state |

## How to Create Issues

```bash
# Using GitHub CLI, from repo root:
for f in .github/issues/[0-9]*.md; do
  title=$(head -1 "$f" | sed 's/^# //')
  gh issue create --title "$title" --body-file "$f" --label "mod,enhancement"
done
```

## How Agents Should Use These

1. Read `.github/copilot-instructions.md` (framework overview)
2. Read `.github/skills/reimplementing-default-ui.md` (step-by-step procedure)
3. Read the specific issue for the window being implemented
4. Follow the skill file phases in order: Research → Framework Support → Implement → Shutdown Symmetry
5. Open a PR with the mod files + any Mongbat.lua wrapper additions

## Mongbat API Audit Summary

### Currently Wrapped API Namespaces

| Namespace | Count | Covers |
|-----------|-------|--------|
| Api.Ability | 4 | Racial/weapon ability queries |
| Api.AnimatedImage | 4 | Animated texture control |
| Api.Button | 11 | Button text, state, texture, color |
| Api.Chat | 2 | Send chat, print to chat window |
| Api.CircleImage | 5 | Circle image texture, rotation, fill |
| Api.ComboBox | 4 | Dropdown management |
| Api.ContextMenu | 1 | RequestContextMenu |
| Api.CSV | 2 | Load/unload CSV tables |
| Api.Drag | 7 | All drag-and-drop operations |
| Api.DynamicImage | 8 | Texture, scale, dimensions, shader |
| Api.EditTextBox | 10 | Text entry, font, history, color |
| Api.Event | 6 | Broadcast, register/unregister, logout, store |
| Api.Gump | 7 | Generic gump interactions |
| Api.Icon | 3 | Icon data, texture size, tile art |
| Api.Interface | 8 | Save/load settings, paperdoll state, mobile data |
| Api.InterfaceCore | 2 | Scale factor, reload UI |
| Api.ItemProperties | 2 | Tooltip active item |
| Api.Label | 5 | Text, color, alignment, word wrap |
| Api.ListBox | 4 | Data table, display order |
| Api.LogDisplay | 15 | Chat log display control |
| Api.Mod | 8 | Module loading |
| Api.Object | 4 | Distance, validity, mobile check, paperdoll object |
| Api.Radar | 18 | Full radar/map API |
| Api.ScrollWindow | 2 | Scroll offset, update rect |
| Api.Slider | 2 | Slider position |
| Api.StatusBar | 4 | Health/mana/stamina bars |
| Api.String | 3 | TID lookup, string conversion |
| Api.Target | 2 | Left click target, get all mobile targets |
| Api.TextLog | 10 | Text logging system |
| Api.Time | 1 | Current date/time |
| Api.UserAction | 2 | UseItem, ToggleWarMode |
| Api.Viewport | 1 | Update viewport bounds |
| Api.Waypoint | 8 | Waypoint CRUD and display |
| Api.Window | 56 | Comprehensive window management |
| Api.Equipment | 1 | UpdateItemIcon |

### Currently Wrapped Data Types

| Data Wrapper | Covers |
|-------------|--------|
| Data.ActiveMobile() | Active mobile info |
| Data.CurrentTarget() | Current target info |
| Data.Cursor() | Cursor/targeting state |
| Data.Drag() | Drag-and-drop state |
| Data.HealthBarColor(id) | Health bar tint per mobile |
| Data.MobileName(id) | Mobile name + notoriety |
| Data.MobileStatus(id) | Mobile health/status |
| Data.MousePosition() | Mouse x/y |
| Data.MouseOverWindow() | Currently hovered window |
| Data.Object(id) | Object properties |
| Data.ObjectHandles() | Object handle list |
| Data.PlayerLocation() | Player coordinates |
| Data.PlayerStatus() | Player stats (HP, mana, stats, etc.) |
| Data.Paperdoll(id) | Paperdoll equipment slots |
| Data.PaperdollTexture(id) | Paperdoll figure texture data |
| Data.IsShift/IsControl/IsAlt | Modifier key checks |

### Currently Wrapped DataEvents

- OnUpdatePlayerStatus, OnUpdateMobileName, OnUpdateHealthBarColor
- OnUpdateMobileStatus, OnUpdateRadar, OnUpdatePlayerLocation, OnUpdatePaperdoll

### Currently Wrapped DefaultComponents

Actions, MainMenuWindow, StatusWindow, WarShield, PaperdollWindow, Interface, ObjectHandle, HealthBarManager, GumpsParsing, GenericGump, MapWindow, MapCommon, DebugWindow

### Known Missing Wrappers (per window)

See individual issue files for specific gaps per window.
