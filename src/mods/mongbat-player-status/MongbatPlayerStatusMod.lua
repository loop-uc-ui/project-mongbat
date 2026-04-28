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

local PANEL_W = 200
local BAR_H   = 20
local PAD     = 8
local SPACING = 4
local NAME_H  = 20
local MIN_W   = 120
local MIN_H   = NAME_H + 3 * BAR_H + 3 * SPACING + 2 * PAD

-- Mutable layout state. The lib writes layout.w / layout.h while the user
-- drags the resize grip; Build reads them on the next frame. PANEL_W is
-- only used to seed the very first frame.
local layout = {
    w = PANEL_W,
    h = NAME_H + 3 * BAR_H + 3 * SPACING + 2 * PAD,
}

local DRAG_THRESHOLD = 4

local state = {
    downWinX = 0,
    downWinY = 0,
}

local M = {}

-- The lib emits StatusWindow & WarShield destroys via replacesDefault on
-- the panel, but the panel's engine name is "MongbatPlayerStatus_panel"
-- (default), not "StatusWindow". Destroy them once at load.
local destroyedDefaults = false
local function destroyDefaultsOnce()
    if destroyedDefaults then return end
    Api.Window.Destroy("StatusWindow")
    Api.Window.Destroy("WarShield")
    destroyedDefaults = true
end

-- Build a bar's dynamic image fill width/colour and label text.
local function emitBar(emit, key, current, max, color, yOffset, barWidth)
    local cur = math.max(current, 0)
    local mx  = math.max(max, 1)
    local pct = math.min(cur / mx, 1)
    local fillWidth = math.floor(barWidth * pct + 0.5)

    emit(key, {
        template = "MongbatStatusBar",
        parent   = "panel",
        widget   = UI.Window()
            :setDimensions(barWidth, BAR_H)
            :clearAnchors()
            :addAnchor("topleft", "panel", "topleft", PAD, yOffset),
    })
    emit(key .. "Fill", {
        template = "MongbatStatusBarFill",
        parent   = key,
        widget   = UI.DynamicImage()
            :setTexture("StatusBar", 0, 0)
            :setDimensions(fillWidth, BAR_H)
            :setColor(color)
            :clearAnchors()
            :addAnchor("topleft", key, "topleft", 0, 0),
    })
    emit(key .. "Label", {
        template = "MongbatLabel",
        parent   = key,
        widget   = UI.Label()
            :setText(string.format("%d / %d", cur, mx))
            :setDimensions(barWidth, BAR_H)
            :clearAnchors()
            :addAnchor("centerleft", key, "centerleft", 0, 0)
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
    if id == 0 then return end  -- emit nothing this frame; lib will destroy any prior

    local maxHealth  = math.max(p:getMaxHealth(),  1)
    local maxMana    = math.max(p:getMaxMana(),    1)
    local maxStamina = math.max(p:getMaxStamina(), 1)

    local healthColor = Data.HealthBarColor(id):getVisualStateColor()
        or Constants.Colors.HealhBar[1]
    local mobName = Data.MobileName(id):getName() or ""
    local frameColor = p:isInWarMode()
        and Constants.Colors.Notoriety[6]
        or  Constants.Colors.Notoriety[1]

    local barWidth = math.max(MIN_W - 2 * PAD, layout.w - 2 * PAD)

    emit("panel", {
        template  = "MongbatWindow",
        id        = id,
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
            :setDimensions(barWidth, NAME_H)
            :clearAnchors()
            :addAnchor("topleft", "panel", "topleft", PAD, PAD)
            :setWordWrap(false),
    })

    local baseY = PAD + NAME_H + SPACING
    emitBar(emit, "hp",   p:getCurrentHealth(),  maxHealth,  healthColor,                 baseY,                          barWidth)
    emitBar(emit, "mana", p:getCurrentMana(),    maxMana,    Constants.Colors.Blue,       baseY + BAR_H + SPACING,        barWidth)
    emitBar(emit, "stam", p:getCurrentStamina(), maxStamina, Constants.Colors.YellowDark, baseY + 2 * (BAR_H + SPACING),  barWidth)
end

-- ---- Click handling on the outer panel ---------------------------------

function M.OnLButtonDown(name, key)
    if key == "panel" then
        state.downWinX, state.downWinY = Api.Window.GetPosition(name)
        Api.Window.SetMoving(name, true)
    end
end

function M.OnLButtonDblClk(_name, key)
    if key == "panel" then
        local id = Data.PlayerStatus():getId()
        if id ~= 0 then Api.UserAction.UseItem(id) end
    end
end

function M.OnLButtonUp(name, key)
    if key ~= "panel" then return end
    Api.Window.SetMoving(name, false)
    local wx, wy = Api.Window.GetPosition(name)
    local dx = math.abs(wx - state.downWinX)
    local dy = math.abs(wy - state.downWinY)
    if dx > DRAG_THRESHOLD or dy > DRAG_THRESHOLD then return end
    local id = Data.PlayerStatus():getId()
    if id == 0 then return end
    if Data.Drag():isDraggingItem() then
        Api.Drag.DragToObject(id)
    else
        Api.Target.LeftClick(id)
    end
end

function M.OnRButtonUp(name, key)
    if key == "panel" then
        Api.Window.SetShowing(name, false)
    end
end

Mongbat.Mod {
    Name   = "MongbatPlayerStatus",
    Path   = "/src/mods/mongbat-player-status",
    Module = M,
}
