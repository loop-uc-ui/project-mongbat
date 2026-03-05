# Reimplement ChatWindow as Mongbat Mod

## Overview

Replace the default `ChatWindow` / `NewChatWindow` system with a Mongbat mod (`mongbat-chat-window`). The chat system handles all text communication: say, whisper, yell, party chat, guild chat, alliance chat, system messages, and custom channels.

**Complexity:** Very High
**Priority:** Tier 3
**Branch:** `mod/chat-window`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (LogDisplay, EditTextBox, Labels, Buttons). Focus on **functionality over visual parity** — the goal is a clean, minimal single-tab chat window, not the complex multi-tab extractable system. Start simple; tabs can be added later.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua (new) | `Source/NewChatWindow.lua` |
| Lua (classic) | `UO_ChatWindow/Source/ChatWindow.lua` |
| XML | `Source/NewChatWindow.xml`, `UO_ChatWindow/Source/ChatWindow.xml` |
| Lua (channel) | `Source/ChannelWindow.lua` |

**Note:** The game has TWO chat systems — `NewChatWindow` (tabbed) and the older `ChatWindow` (from `UO_ChatWindow` mod). Research which is active by default and what `SystemData.Settings.Interface.ChatStyle` controls.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| Chat data flows through the TextLog system, not WindowData | — | Use `Api.TextLog.*` and `Api.LogDisplay.*` |

## Key Interactions

- **Text input** — type messages, send with Enter
- **Channel selection** — say, whisper, yell, party, guild, alliance, emote
- **Tab system** — multiple tabs with independent filter configs
- **Filter toggles** — show/hide message types per tab
- **Resizable** — drag to resize chat area
- **Transparency** — adjustable alpha, fades when inactive
- **Timestamp toggle** — show/hide timestamps
- **Extractable tabs** — detach tabs into separate windows
- **Right-click context** — tab options, filter settings
- **Scrollback** — scroll through message history
- **Chat log** — optional file logging
- **Links** — clickable links in messages

## Framework Gaps to Address

### Missing Data Wrappers
- Chat mostly works through `TextLog` and `LogDisplay` engine components, which Mongbat already wraps extensively via `Api.TextLog.*` (10 functions) and `Api.LogDisplay.*` (15 functions)

### Missing DefaultComponents
- `DefaultNewChatWindowComponent` — wrapping `NewChatWindow` global
- `DefaultChatWindowComponent` — wrapping `ChatWindow` global (from UO_ChatWindow)

### Missing API Wrappers
- `Api.Chat.SendChat` — **already exists**
- `Api.Chat.PrintToChatWindow` — **already exists**
- `Api.EditTextBox.*` — **already exists** (10 functions)
- Chat channel management functions may need wrappers (join/leave/create channel)

### Architecture Notes

This is the most complex window in the default UI. The chat system interacts deeply with the `TextLog` and `LogDisplay` engine components. Multiple independent tab windows can exist, each with its own log display, filter set, and font configuration.

Consider implementing in phases:
1. **Phase 1:** Single chat window with input and filtered output
2. **Phase 2:** Tab system with per-tab filters
3. **Phase 3:** Extractable tabs, resize, transparency

## Mod Structure

```
src/mods/mongbat-chat-window/
    MongbatChatWindow.mod
    MongbatChatWindowMod.lua
```

## Acceptance Criteria

- [ ] Default chat window system is fully suppressed
- [ ] Text input works with Enter to send
- [ ] Channel selection (say/whisper/yell/party/guild/alliance)
- [ ] Messages display with correct colors per channel
- [ ] Scrollback through message history
- [ ] At least basic filter toggles per message type
- [ ] Resizable chat area
- [ ] Adjustable alpha/transparency
- [ ] Clean shutdown restores default chat system
- [ ] All engine calls go through Mongbat context wrappers
