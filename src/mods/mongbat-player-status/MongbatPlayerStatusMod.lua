-- Player status panel: name + HP / Mana / Stamina bars. Hijacks the default
-- StatusWindow and WarShield so this mod owns presentation entirely.
--
-- Pattern: declarative. M.Build(emit) runs every frame; the lib diffs and
-- creates / updates / destroys the engine windows. Live engine data is
-- pulled inside Build and pushed via UI widget setters that the lib applies.

local UI        = Mongbat.UI
local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Constants = Mongbat.Constants

-- Initial / minimum sizes. Once the user resizes, layout.w/h drive
-- everything; the proportions below decide how inner space is divided.
local PANEL_W   = 200
local PANEL_H   = 100
local PAD       = 8       -- inset from panel edge to inner content
local SPACING   = 6       -- gap between rows
local NUM_BARS  = 3
local NAME_RATIO = 0.20   -- name row's share of inner height
local MIN_W     = 120
local MIN_H     = 80

-- Mutable layout state. The lib writes layout.w / layout.h while the user
-- drags the resize grip; Build reads them on the next frame. PANEL_W/H
-- only seed the very first frame.
local layout = { w = PANEL_W, h = PANEL_H }

local M = {}

local destroyedDefaults = false
local function destroyDefaultsOnce()
    if destroyedDefaults then return end
    Api.Window.Destroy("StatusWindow")
    Api.Window.Destroy("WarShield")
    destroyedDefaults = true
end

-- Emit one bar row. `yOffset` is the absolute y offset from panel.topleft.
-- `barW` / `barH` are derived from the panel size in Build.
local function emitBar(emit, key, yOffset, current, max, color, barW, barH)
    local cur = math.max(current, 0)
    local mx  = math.max(max, 1)
    local pct = math.min(cur / mx, 1)
    local fillWidth = math.floor(barW * pct + 0.5)

    emit(key, {
        template = "MongbatStatusBar",
        parent   = "panel",
        widget   = UI.Window()
            :setDimensions(barW, barH)
            :onlyOnCreate()
                :clearAnchors()
            :always()
            :setOffsetFromParent(PAD, yOffset),
    })
    emit(key .. "Fill", {
        template = "MongbatSolidFill",
        parent   = key,
        widget   = UI.DynamicImage()
            :setTexture("StatusBar", 40, 24)
            :setTextureDimensions(1, 1)
            :setDimensions(fillWidth, barH)
            :setColor(color)
            :onlyOnCreate()
                :clearAnchors()
                :addAnchor("topleft", key, "topleft", 0, 0),
    })
    emit(key .. "Label", {
        template = "MongbatLabel",
        parent   = key,
        widget   = UI.Label()
            :setText(string.format("%d / %d", cur, mx))
            :setDimensions(barW, barH)
            :onlyOnCreate()
                :clearAnchors()
                :addAnchor("topleft", key, "topleft", 0, 0)
            :always()
            :setLayer(Constants.WindowLayers.Secondary)
            :setTextColor(Constants.Colors.White),
    })
end

function M.OnLoad()
    destroyDefaultsOnce()
end

function M.Build(emit)
    local p = Data.PlayerStatus()
    local id = p:getId()
    if id == 0 then return end

    local maxHealth  = math.max(p:getMaxHealth(),  1)
    local maxMana    = math.max(p:getMaxMana(),    1)
    local maxStamina = math.max(p:getMaxStamina(), 1)

    local healthColor = Data.HealthBarColor(id):getVisualStateColor()
        or Constants.Colors.HealhBar[1]
    local mobName = Data.MobileName(id):getName() or ""
    local frameColor = p:isInWarMode()
        and Constants.Colors.Notoriety[6]
        or  Constants.Colors.Notoriety[1]

    -- Reactive layout: derive every child dim from layout.w / layout.h.
    -- Inner content area is the panel minus PAD on every side. Vertical
    -- space is split between the name row and NUM_BARS bar rows; SPACING
    -- separates each adjacent pair (name|bar1, bar1|bar2, bar2|bar3 -> 3
    -- gaps).
    local innerW   = layout.w - 2 * PAD
    local innerH   = layout.h - 2 * PAD
    local nameH    = math.floor(innerH * NAME_RATIO + 0.5)
    local barsAreaH = innerH - nameH - NUM_BARS * SPACING
    local barH     = math.max(1, math.floor(barsAreaH / NUM_BARS + 0.5))

    emit("panel", {
        template  = "MongbatWindow",
        id        = id,
        draggable = true,
        widget    = UI.Window()
            :setDimensions(layout.w, layout.h)
            :setColor(frameColor)
            :setId(id),
        resizable = { minW = MIN_W, minH = MIN_H, state = layout },
    })

    emit("name", {
        template = "MongbatLabel",
        parent   = "panel",
        widget   = UI.Label()
            :setText(mobName ~= "" and mobName or " ")
            :setDimensions(innerW, nameH)
            :onlyOnCreate()
                :clearAnchors()
                :addAnchor("topleft", "panel", "topleft", PAD, PAD)
            :always()
            :setWordWrap(false),
    })

    -- Absolute y offsets computed from proportional row heights so every
    -- row grows/shrinks when the panel is resized.
    local hpY   = PAD + nameH + SPACING
    local manaY = hpY   + barH + SPACING
    local stamY = manaY + barH + SPACING

    emitBar(emit, "hp",   hpY,   p:getCurrentHealth(),  maxHealth,  healthColor,                 innerW, barH)
    emitBar(emit, "mana", manaY, p:getCurrentMana(),    maxMana,    Constants.Colors.Blue,       innerW, barH)
    emitBar(emit, "stam", stamY, p:getCurrentStamina(), maxStamina, Constants.Colors.YellowDark, innerW, barH)
end

-- ---- Click handling on the outer panel ---------------------------------


function M.OnLButtonDblClk(_name, key)
    if key == "panel" then
        local id = Data.PlayerStatus():getId()
        if id ~= 0 then Api.UserAction.UseItem(id) end
    end
end

function M.OnLButtonUp(name, key)
    if key ~= "panel" then return end
    local id = Data.PlayerStatus():getId()
    if id == 0 then return end
    if Data.Drag():isDraggingItem() then
        Api.Drag.DragToObject(id)
    else
        Api.Target.LeftClick(id)
    end
end

Mongbat.Mod {
    Name   = "MongbatPlayerStatus",
    Path   = "/src/mods/mongbat-player-status",
    Module = M,
}
