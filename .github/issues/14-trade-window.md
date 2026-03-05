# Reimplement TradeWindow as Mongbat Mod

## Overview

Replace the default `TradeWindow` with a Mongbat mod (`mongbat-trade-window`). The trade window is a dynamic dialog that appears when two players initiate a trade, showing both players' offered items, accept/cancel toggles, and gold/platinum entry fields.

**Complexity:** Medium-High
**Priority:** Tier 4
**Branch:** `mod/trade-window`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (Labels, DynamicImages, Buttons, EditTextBoxes) in a clean two-column layout (your items | their items). Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/TradeWindow.lua` |
| XML | `Source/TradeWindow.xml` |

Fetch both files completely before writing any code.

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.ContainerWindow` | Per container ID (player's and partner's) | Items in each player's trade container |
| `WindowData.ObjectInfo` | Per object ID | Individual item info for display |
| `WindowData.TradeInfo` | Global | Trade state: container IDs, accept flags, gold/plat amounts |
| `WindowData.ItemProperties` | Per object ID | Item tooltips |

## Key Interactions

- **Accept button** → toggle accept/cancel (`BroadcastEvent(TRADE_SEND_ACCEPTMSG_WINDOW)`)
- **Drop items** → drag items into player's trade container area
- **Double-click item** → interact with item
- **Gold/Plat entry** → text fields for currency amounts (validated against balance)
- **Tab** → switch between gold/plat fields
- **Mouse over items** → show item property tooltips
- **Close** → cancel trade

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdateContainerWindow` — needs DataEvent for `WindowData.ContainerWindow`
- `OnUpdateObjectInfo` — needs DataEvent for `WindowData.ObjectInfo`

### Missing Data Wrappers
- `Data.ContainerWindow(id)` — wrap `WindowData.ContainerWindow[id]`
- `Data.TradeInfo()` — wrap `WindowData.TradeInfo` (container IDs, accept state, gold/plat)
- `Data.ObjectInfo(id)` — wrap `WindowData.ObjectInfo[id]` (item name, icon, quantity)

### Missing DefaultComponents
- `TradeWindow` — needs to be added to Mongbat.lua

### Missing System Event Support
- `TRADE_RECEIVE_CLOSE_WINDOW` — trade closed by server/partner
- `TRADE_RECEIVE_ACCEPTMSG_WINDOW` — accept state changed
- `TRADE_RECEIVE_MODIFYGOLD_WINDOW` — partner modified gold/plat offer
- `TRADE_RECEIVE_BALANCE_WINDOW` — balance update
- `TRADE_SEND_ACCEPTMSG_WINDOW` — send accept toggle
- `TRADE_SEND_MODIFYGOLD_WINDOW` — send gold/plat modification

### Notes
- Trade windows use `SystemData.DynamicWindowId` for unique instances
- Must handle `Interface.DestroyWindowOnClose` pattern
- Gold/plat entry needs comma formatting and balance validation
- Both players' items shown side-by-side

## Mod Structure

```
src/mods/mongbat-trade-window/
    MongbatTradeWindow.mod
    MongbatTradeWindowMod.lua
```

## Acceptance Criteria

- [ ] Default TradeWindow is fully suppressed
- [ ] Trade dialog appears on trade initiation
- [ ] Both players' offered items display correctly
- [ ] Accept/cancel toggle works
- [ ] Gold/platinum entry with validation
- [ ] Items can be dragged into trade area
- [ ] Mouse over shows item tooltips
- [ ] Trade closes properly on completion/cancellation
- [ ] Clean shutdown restores default window
- [ ] All engine calls go through Mongbat context wrappers
