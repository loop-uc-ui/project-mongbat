# Reimplement PartyInviteWindow as Mongbat Mod

## Overview

Replace the default `PartyInviteWindow` with a Mongbat mod (`mongbat-party-invite`). The Party Invite Window is a simple dialog that appears when another player invites you to a party. It shows the inviter's name and provides Accept/Decline buttons, plus a "Do not show" checkbox.

**Complexity:** Low
**Priority:** Tier 6
**Branch:** `mod/party-invite`

## Design Direction

**Do NOT replicate the default UI appearance.** Use the standard `MongbatWindow` (MaskWindow) frame. A simple dialog with the invite message, Accept/Decline buttons, and a checkbox.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/PartyInviteWindow.lua` |
| XML | `Source/PartyInviteWindow.xml` |

Fetch both files completely before writing any code.

## Architecture

### Data Flow

1. Engine creates the window when a party invite is received
2. `WindowData.PartyInviteName` contains the inviter's name (wstring)
3. Dialog text: `inviterName .. GetStringFromTid(1115373)` (e.g., "PlayerName has invited you to join a party")
4. Accept → `AcceptPartyInvite()` → window destroyed
5. Decline → `DeclinePartyInvite()` → window destroyed
6. CLOSE_PARTY_INVITE event → destroy window externally

### TIDs

| TID | Value | Text |
|-----|-------|------|
| Title | 1115370 | Party Invite window title |
| Accept | 1115371 | "Accept" |
| Decline | 1115372 | "Decline" |
| Dialog | 1115373 | " has invited you to join a party" (prepended with name) |
| DoNotShow | 1115374 | "Do not show this dialog" |

### Checkbox Behavior

The "Do not show" checkbox sets `SystemData.Settings.GameOptions.partyInvitePopUp = false`. When unchecked, party invites auto-decline without showing the window.

## Key Engine Functions

| Function | Purpose |
|----------|---------|
| `AcceptPartyInvite()` | Accept the party invitation |
| `DeclinePartyInvite()` | Decline the party invitation |

## Key Events

| Event | Purpose |
|-------|---------|
| `CLOSE_PARTY_INVITE` | External signal to close/destroy the invite window |

## Key Interactions

- **Accept button** → accept invite, destroy window
- **Decline button** → decline invite, destroy window
- **Do not show checkbox** → toggle `partyInvitePopUp` setting
- **CLOSE_PARTY_INVITE event** → destroy window if still open

## Framework Gaps to Address

### Missing DefaultComponents
- `DefaultPartyInviteWindowComponent` — for `PartyInviteWindow` global table

### Missing API Wrappers
- `Api.Party.AcceptInvite()` — wrapper for `AcceptPartyInvite`
- `Api.Party.DeclineInvite()` — wrapper for `DeclinePartyInvite`

### Missing Data Wrappers
- `Data.PartyInviteName()` — wrapper for `WindowData.PartyInviteName`

### Missing Constants/Events
- `Constants.Events.CLOSE_PARTY_INVITE` — for `SystemData.Events.CLOSE_PARTY_INVITE`

## Mod Structure

```
src/mods/mongbat-party-invite/
    MongbatPartyInvite.mod
    MongbatPartyInviteMod.lua
```

## Implementation Notes

- `Interface.DestroyWindowOnClose["PartyInviteWindow"] = true` — the default UI destroys this window on close. Mongbat's lazy creation handles this naturally.
- The window is event-triggered (engine creates it when invite arrives), not toggled from a menu.
- The checkbox flag is stored in `PartyInviteWindow.checkboxFlag` locally, then applied to settings on accept/decline.
- The default Shutdown calls `DeclinePartyInvite()` if the window is closed without explicit accept/decline.
- This is one of the simplest windows — good candidate for a straightforward implementation.

## Acceptance Criteria

- [ ] Default PartyInviteWindow is fully suppressed (PartyInviteWindow global table replaced)
- [ ] Party invite dialog shows inviter name and message
- [ ] Accept button accepts the invite
- [ ] Decline button declines the invite
- [ ] "Do not show" checkbox toggles partyInvitePopUp setting
- [ ] CLOSE_PARTY_INVITE event closes the window
- [ ] Shutdown declines invite if neither accepted nor declined
- [ ] Clean shutdown restores default
- [ ] All engine calls go through Mongbat context wrappers
