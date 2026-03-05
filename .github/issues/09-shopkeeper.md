# Reimplement Shopkeeper Window as Mongbat Mod

## Overview

Replace the default `Shopkeeper` buy/sell window with a Mongbat mod (`mongbat-shopkeeper`). The shop window shows vendor inventory, allows quantity selection, displays purchase totals, and handles buying and selling items.

**Complexity:** High
**Priority:** Tier 3
**Branch:** `mod/shopkeeper`

## Design Direction

**Do NOT replicate the default UI appearance.** This mod should be cosmetically simple and use the standard `MongbatWindow` (MaskWindow) as its frame. Use plain Mongbat components (DynamicImages, Labels, Buttons) in a simple list layout. Focus on **functionality over visual parity** — the goal is a clean, minimal replacement, not a pixel-perfect clone.

## Default UI Files

| File | Path in `loop-uc-ui/enhanced-client-default` |
|------|----------------------------------------------|
| Lua | `Source/Shopkeeper.lua` |
| XML | `Source/Shopkeeper.xml` |

## WindowData Types Used

| Type | Registration | Notes |
|------|-------------|-------|
| `WindowData.ShopData` | Per-merchant ID | Buy/sell item lists with names, prices, quantities, icons |

Study the Lua file to find the exact `WindowData` table names and registration calls.

## Key Interactions

- **Buy tab** — browse vendor inventory with prices
- **Sell tab** — select items from your backpack to sell
- **Quantity selection** — left/right arrows or input to set quantity
- **Item tooltips** — hover for detailed item properties
- **Purchase/sell buttons** — confirm transaction
- **Gold total** — running total of transaction cost
- **Search/filter** — text filter for items (default UI has this)
- **Scrollable list** — paginated item list with icons
- **Dynamic window** — created when interacting with a vendor NPC

## Framework Gaps to Address

### Missing DataEvents
- `OnUpdateShopData` — needs DataEvent for `WindowData.ShopData` (or whatever the correct type is)

### Missing Data Wrappers
- `Data.ShopData(merchantId)` — new wrapper exposing buy/sell item arrays with prices, quantities, icons

### Missing DefaultComponents
- `DefaultShopkeeperComponent` — wrapping `Shopkeeper` global

### Missing API Wrappers
- Shop transaction functions (buy/sell confirmation) — study the default UI for engine function names
- May need `Api.Icon.RequestTileArt` — **already exists** (for item icons)

### Architecture Notes

Shopkeeper windows are **dynamic** — each vendor interaction creates a new window. The default implementation dynamically creates item rows from templates. Gold tracking requires reading the player's gold count (possibly from `WindowData.PlayerStatus` or a separate gold field).

## Mod Structure

```
src/mods/mongbat-shopkeeper/
    MongbatShopkeeper.mod
    MongbatShopkeeperMod.lua
```

## Acceptance Criteria

- [ ] Default Shopkeeper window is fully suppressed
- [ ] Buy view shows vendor inventory with items, prices, and icons
- [ ] Sell view shows sellable items from player inventory
- [ ] Quantity controls work (increment/decrement/input)
- [ ] Running gold total updates correctly
- [ ] Buy/sell transaction executes successfully
- [ ] Item tooltips display on hover
- [ ] Text search/filter works
- [ ] Window created dynamically when interacting with vendors
- [ ] Clean shutdown restores default shop system
- [ ] All engine calls go through Mongbat context wrappers
