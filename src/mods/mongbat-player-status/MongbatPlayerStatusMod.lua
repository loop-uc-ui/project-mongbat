-- Player status panel: name + HP / Mana / Stamina bars driven by the
-- engine''s PlayerStatus binding. Hijacks the default StatusWindow and
-- WarShield so this mod owns presentation entirely.
--
-- Pattern: Mongbat is a router. The mod registers one outer window plus
-- three bar composites (each composite = container + fill + label). All
-- engine -> mod traffic flows through M.OnUpdatePlayerStatus / etc., which
-- read state and call thin Api setters; no descriptor diff, no Render.

local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Utils     = Mongbat.Utils
local Constants = Mongbat.Constants

local NAME    = "MongbatPlayerStatusWindow"
local PANEL_W = 200
local BAR_W   = 184
local BAR_H   = 20
local PAD     = 8
local SPACING = 4
local NAME_H  = 20

local NAMES = {
    name      = NAME .. "Name",
    hp        = NAME .. "HpBar",
    hpFill    = NAME .. "HpBarFill",
    hpLabel   = NAME .. "HpBarLabel",
    mana      = NAME .. "ManaBar",
    manaFill  = NAME .. "ManaBarFill",
    manaLabel = NAME .. "ManaBarLabel",
    stam      = NAME .. "StamBar",
    stamFill  = NAME .. "StamBarFill",
    stamLabel = NAME .. "StamBarLabel",
}

local state = {
    id          = 0,
    name        = "",
    health      = 0, maxHealth  = 1,
    mana        = 0, maxMana    = 1,
    stamina     = 0, maxStamina = 1,
    inWar       = false,
    healthColor = Constants.Colors.HealhBar[1],
}

local M = {}

-- ---- Pulls --------------------------------------------------------------

local function pullPlayerStatus()
    local p = Data.PlayerStatus()
    if p:getId() == 0 then return false end
    state.id         = p:getId()
    state.health     = p:getCurrentHealth()
    state.maxHealth  = math.max(p:getMaxHealth(), 1)
    state.mana       = p:getCurrentMana()
    state.maxMana    = math.max(p:getMaxMana(), 1)
    state.stamina    = p:getCurrentStamina()
    state.maxStamina = math.max(p:getMaxStamina(), 1)
    state.inWar      = p:isInWarMode()
    return true
end

local function pullHealthColor()
    if state.id == 0 then return end
    local color = Data.HealthBarColor(state.id):getVisualStateColor()
    if color then state.healthColor = color end
end

local function pullMobileName()
    if state.id == 0 then return end
    local name = Data.MobileName(state.id):getName()
    if name and name ~= "" then state.name = name end
end

-- ---- Push to engine ----------------------------------------------------

local function setBar(fillName, labelName, current, max, color, fmt)
    local pct   = math.max(0, math.min(1, current / max))
    local width = math.floor(BAR_W * pct + 0.5)
    Api.Window.SetDimensions(fillName, width, BAR_H)
    Api.Window.SetColor(fillName, color)
    Api.Label.SetText(labelName, string.format(fmt, current, max))
end

local function pushAll()
    local frameColor = state.inWar
        and Constants.Colors.Notoriety[6]
        or  Constants.Colors.Notoriety[1]
    Api.Window.SetColor(NAME, frameColor)
    Api.Window.SetId(NAME, state.id)

    Api.Label.SetText(NAMES.name, state.name ~= "" and state.name or " ")

    setBar(NAMES.hpFill,   NAMES.hpLabel,   state.health,  state.maxHealth,  state.healthColor,            "%d / %d")
    setBar(NAMES.manaFill, NAMES.manaLabel, state.mana,    state.maxMana,    Constants.Colors.Blue,        "%d / %d")
    setBar(NAMES.stamFill, NAMES.stamLabel, state.stamina, state.maxStamina, Constants.Colors.YellowDark,  "%d / %d")
end

-- ---- Window construction ------------------------------------------------

local function createBar(containerName, fillName, labelName, parentName, yOffset, key, fillKey, labelKey)
    Mongbat.CreateWindow {
        name = containerName, template = "MongbatStatusBar",
        parent = parentName, module = M, key = key,
    }
    Api.Window.SetDimensions(containerName, BAR_W, BAR_H)
    Api.Window.SetOffsetFromParent(containerName, PAD, yOffset)

    Mongbat.CreateWindow {
        name = fillName, template = "MongbatStatusBarFill",
        parent = containerName, module = M, key = fillKey,
    }
    Api.DynamicImage.SetTexture(fillName, "StatusBar", 0, 0)
    Api.Window.SetDimensions(fillName, 0, BAR_H)
    Api.Window.SetOffsetFromParent(fillName, 0, 0)

    Mongbat.CreateWindow {
        name = labelName, template = "MongbatLabel",
        parent = containerName, module = M, key = labelKey,
    }
    Api.Window.SetDimensions(labelName, BAR_W, BAR_H)
    Api.Window.SetOffsetFromParent(labelName, 0, 0)
    Api.Label.SetTextColor(labelName, Constants.Colors.White)
    Api.Window.SetLayer(labelName, Constants.WindowLayers.Secondary)
end

function M.OnLoad()
    Api.Window.Destroy("StatusWindow")
    Api.Window.Destroy("WarShield")
    Mongbat.CreateWindow {
        name     = NAME,
        template = "MongbatWindow",
        module   = M,
        key      = "panel",
        bindings = { "PlayerStatus", "MobileName", "HealthBarColor" },
    }
    Api.Window.SetDimensions(NAME, PANEL_W, NAME_H + 3 * BAR_H + 3 * SPACING + 2 * PAD)

    -- Name label, then three bars stacked.
    Mongbat.CreateWindow {
        name = NAMES.name, template = "MongbatLabel",
        parent = NAME, module = M, key = "name",
    }
    Api.Window.SetDimensions(NAMES.name, BAR_W, NAME_H)
    Api.Window.SetOffsetFromParent(NAMES.name, PAD, PAD)

    local y = PAD + NAME_H + SPACING
    createBar(NAMES.hp,   NAMES.hpFill,   NAMES.hpLabel,   NAME, y,                      "hpBar",   "hpFill",   "hpLabel")
    y = y + BAR_H + SPACING
    createBar(NAMES.mana, NAMES.manaFill, NAMES.manaLabel, NAME, y,                      "manaBar", "manaFill", "manaLabel")
    y = y + BAR_H + SPACING
    createBar(NAMES.stam, NAMES.stamFill, NAMES.stamLabel, NAME, y,                      "stamBar", "stamFill", "stamLabel")

    -- Engine may push partial updates before PlayerStatus arrives;
    -- pull defensively so first frame shows live values too.
    if pullPlayerStatus() then
        pullMobileName()
        pullHealthColor()
        pushAll()
    end
end

function M.OnUnload()
    Utils.Table.ForEach(NAMES, function(_, n) Mongbat.DestroyWindow(n) end)
    Mongbat.DestroyWindow(NAME)
end

-- ---- Bindings -----------------------------------------------------------

function M.OnUpdatePlayerStatus()
    if pullPlayerStatus() then
        pullMobileName()
        pullHealthColor()
        pushAll()
    end
end

function M.OnUpdateMobileName()
    pullMobileName()
    pushAll()
end

function M.OnUpdateHealthBarColor()
    pullHealthColor()
    pushAll()
end

-- ---- Click handling on the outer panel ---------------------------------

function M.OnLButtonDblClk(_name, key)
    if key == "panel" and state.id ~= 0 then
        Api.UserAction.UseItem(state.id)
    end
end

function M.OnLButtonUp(_name, key)
    if key ~= "panel" or state.id == 0 then return end
    if Data.Drag():isDraggingItem() then
        Api.Drag.DragToObject(state.id)
    else
        Api.Target.LeftClick(state.id)
    end
end

function M.OnRButtonUp(_name, key)
    if key == "panel" then
        Api.Window.SetShowing(NAME, false)
    end
end

Mongbat.Mod {
    Name   = "MongbatPlayerStatus",
    Path   = "/src/mods/mongbat-player-status",
    Module = M,
}
