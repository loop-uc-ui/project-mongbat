# Reimplement ChannelWindow as Mongbat Mod

## Overview

Replace the default `ChannelWindow` with a Mongbat mod (`mongbat-channel-window`). The Channel Window manages chat channels — it displays the current channel name, lists available channels, and provides Join, Leave, and Create channel actions.

**Complexity:** Low
**Priority:** Tier 6
**Branch:** `mod/channel-window`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. Use Mongbat components (Labels, Buttons) with clean layout. The channel list can use a simple scroll list of Labels.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/ChannelWindow.lua` |
| XML | `Source/ChannelWindow.xml` |

Fetch both files completely before writing any code.

## Architecture

### Data Flow

1. Window shows current channel via `WindowData.ChannelList.currentChannel`
2. Channel list populated from `WindowData.ChannelListCount` and `WindowData.ChannelList[i].name`
3. CURRENT_CHANNEL_UPDATED event refreshes the current channel display
4. Join/Leave/Create use engine chat functions

### TIDs

| TID | Value | Text |
|-----|-------|------|
| Title | 1114073 | Channel Window title |
| YourCurrentChannel | 1114072 | "Your Current Channel:" |
| Join | 1114074 | "Join" |
| Leave | 1114075 | "Leave" |
| Create | 1114076 | "Create" |
| Okay | 3000093 | "Okay" |
| Cancel | 1006045 | "Cancel" |
| CreateChannelTitle | 1114077 | Create channel dialog title |

### Sub-Dialog: CreateChannelWindow

When the Create button is pressed, a sub-dialog appears with a text input for the new channel name and Okay/Cancel buttons. This calls `ChatCreateChannel(name)`.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.ChannelListCount` | Read directly | Number of channels |
| `WindowData.ChannelList` | Read directly | Array with `.name` and `.currentChannel` fields |

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `ChatJoinChannel(name)` | Join a chat channel |
| `ChatLeaveChannel()` | Leave current channel |
| `ChatCreateChannel(name)` | Create a new chat channel |

## Key Events

| Event | Purpose |
|-------|---------|
| `CURRENT_CHANNEL_UPDATED` | Refresh current channel display |

## Key Interactions

- **Channel list item click** → select a channel
- **Join button** → join selected channel via `ChatJoinChannel`
- **Leave button** → leave current channel via `ChatLeaveChannel`
- **Create button** → open sub-dialog for channel creation
- **Create sub-dialog Okay** → create channel via `ChatCreateChannel`
- Window opened via `Interface.DestroyWindowOnClose` pattern

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultChannelWindowComponent` — for `ChannelWindow` global table

### Missing API Wrappers
- `Api.Chat.JoinChannel(name)` — wrapper for `ChatJoinChannel`
- `Api.Chat.LeaveChannel()` — wrapper for `ChatLeaveChannel`
- `Api.Chat.CreateChannel(name)` — wrapper for `ChatCreateChannel`

### Missing Data Wrappers
- `Data.ChannelList()` — wrapper for `WindowData.ChannelList` / `WindowData.ChannelListCount`

### Missing Constants/Events
- `Constants.Events.CURRENT_CHANNEL_UPDATED` — for `SystemData.Events.CURRENT_CHANNEL_UPDATED`

## Mod Structure

```
src/mods/mongbat-channel-window/
    MongbatChannelWindow.mod
    MongbatChannelWindowMod.lua
```

## Implementation Notes

- The default UI uses `Interface.DestroyWindowOnClose["ChannelWindow"] = true` — window is destroyed on close, fitting Mongbat's lazy creation pattern.
- The ChannelWindow uses a scroll list (`ChannelWindowScrollWindowScrollChild`) to display channel names.
- Selection tracking is done via `ChannelWindow.currentSelection` — index into the channel list.
- The CreateChannelWindow sub-dialog can be implemented as a separate Mongbat Window created on demand.
- Channel list refresh: when CURRENT_CHANNEL_UPDATED fires, re-read `WindowData.ChannelList` and update the display.

## Acceptance Criteria

- [ ] Default ChannelWindow is fully suppressed (ChannelWindow global table replaced)
- [ ] Channel Window opens and shows current channel
- [ ] Channel list displays available channels
- [ ] Join button joins selected channel
- [ ] Leave button leaves current channel
- [ ] Create button opens sub-dialog
- [ ] Create sub-dialog creates new channel
- [ ] Current channel updates when CURRENT_CHANNEL_UPDATED fires
- [ ] Clean shutdown restores default
- [ ] All engine calls go through Mongbat context wrappers
