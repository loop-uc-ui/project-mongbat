-- Player status panel: name + HP / Mana / Stamina bars. Hijacks the default
-- StatusWindow and WarShield so this mod owns presentation entirely.
--
-- Pattern: Mongbat is a router. The mod registers one outer window plus
-- three bar composites (each composite = container + fill + label). Live
-- engine data is pulled each frame in M.OnUpdateWindow and pushed straight
-- to the Api setters; no descriptor diff, no Render, no cached values.

local Api       = Mongbat.Api
local UI        = Mongbat.UI
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
local MIN_W   = 120
local MIN_H   = NAME_H + 3 * BAR_H + 3 * SPACING + 2 * PAD

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

local DRAG_THRESHOLD = 4

-- Mod-owned state. Only mouse-drag bookkeeping needs caching; live engine
-- data is pulled every frame in OnUpdateWindow.
local state = {
    downWinX = 0,
    downWinY = 0,
}

-- UI widget handles, populated in OnLoad.
local W = {}

local M = {}

-- ---- Push to engine ----------------------------------------------------

local function setBar(bar, current, max, color, fmt)
    bar:setValue(current, max, color)
       :setLabel(string.format(fmt, current, max))
end

--- Pull live state from the engine and push it straight to the windows.
--- Called every frame from M.OnUpdateWindow on the panel key, and once at
--- the end of M.OnLoad so the first frame shows live values.
local function refresh()
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
    W.frame:setColor(frameColor):setId(id)
    W.nameLabel:setText(mobName ~= "" and mobName or " ")

    setBar(W.hp,   p:getCurrentHealth(),  maxHealth,  healthColor,                 "%d / %d")
    setBar(W.mana, p:getCurrentMana(),    maxMana,    Constants.Colors.Blue,       "%d / %d")
    setBar(W.stam, p:getCurrentStamina(), maxStamina, Constants.Colors.YellowDark, "%d / %d")
end

-- ---- Resize callback --------------------------------------------------

--- Called by Api.Window.BeginResize when the user finishes dragging the grip.
local function onResizeEnd(_)
    local dims = W.frame:getDimensions()
    BAR_W = math.max(MIN_W - 2 * PAD, dims.x - 2 * PAD)
    W.nameLabel:setDimensions(BAR_W, NAME_H)
    UI.Window(NAMES.hp)       :setDimensions(BAR_W, BAR_H)
    UI.Window(NAMES.mana)     :setDimensions(BAR_W, BAR_H)
    UI.Window(NAMES.stam)     :setDimensions(BAR_W, BAR_H)
    UI.Window(NAMES.hpLabel)  :setDimensions(BAR_W, BAR_H)
    UI.Window(NAMES.manaLabel):setDimensions(BAR_W, BAR_H)
    UI.Window(NAMES.stamLabel):setDimensions(BAR_W, BAR_H)
    refresh()
end

-- ---- Window construction ------------------------------------------------

local function createBar(containerName, fillName, labelName, parentName, yOffset, key, fillKey, labelKey)
    Mongbat.CreateWindow {
        name = containerName, template = "MongbatStatusBar",
        parent = parentName, module = M, key = key,
    }
    UI.Window(containerName)
        :setDimensions(BAR_W, BAR_H)
        :clearAnchors()
        :addAnchor("topleft", parentName, "topleft", PAD, yOffset)

    Mongbat.CreateWindow {
        name = fillName, template = "MongbatStatusBarFill",
        parent = containerName, module = M, key = fillKey,
    }
    UI.DynamicImage(fillName):setTexture("StatusBar", 0, 0)
    UI.Window(fillName)
        :setDimensions(0, BAR_H)
        :clearAnchors()
        :addAnchor("topleft", containerName, "topleft", 0, 0)

    Mongbat.CreateWindow {
        name = labelName, template = "MongbatLabel",
        parent = containerName, module = M, key = labelKey,
    }
    UI.Label(labelName)
        :setDimensions(BAR_W, BAR_H)
        :clearAnchors()
        :addAnchor("centerleft", containerName, "centerleft", 0, 0)
        :setLayer(Constants.WindowLayers.Secondary)
        :setTextColor(Constants.Colors.White)

    return UI.StatusBar { container = containerName, fill = fillName, label = labelName }
end

function M.OnLoad()
    Api.Window.Destroy("StatusWindow")
    Api.Window.Destroy("WarShield")
    local playerId = Data.PlayerStatus():getId()
    Mongbat.CreateWindow {
        name      = NAME,
        template  = "MongbatWindow",
        module    = M,
        key       = "panel",
        id        = playerId,
        resizable = true,
        minWidth  = MIN_W,
        minHeight = MIN_H,
        onResizeEnd = onResizeEnd,
    }
    W.frame = UI.Window(NAME):setDimensions(PANEL_W, NAME_H + 3 * BAR_H + 3 * SPACING + 2 * PAD)

    -- Name label, then three bars stacked as a column.
    Mongbat.CreateWindow {
        name = NAMES.name, template = "MongbatLabel",
        parent = NAME, module = M, key = "name",
    }
    W.nameLabel = UI.Label(NAMES.name)
        :setDimensions(BAR_W, NAME_H)
        :clearAnchors()
        :addAnchor("topleft", NAME, "topleft", PAD, PAD)
        :setWordWrap(false)

    local baseY = PAD + NAME_H + SPACING
    W.hp   = createBar(NAMES.hp,   NAMES.hpFill,   NAMES.hpLabel,   NAME, baseY,                       "hpBar",   "hpFill",   "hpLabel")
    W.mana = createBar(NAMES.mana, NAMES.manaFill, NAMES.manaLabel, NAME, baseY + BAR_H + SPACING,     "manaBar", "manaFill", "manaLabel")
    W.stam = createBar(NAMES.stam, NAMES.stamFill, NAMES.stamLabel, NAME, baseY + 2*(BAR_H + SPACING), "stamBar", "stamFill", "stamLabel")

    -- First-frame paint so the panel isn't empty until the next tick.
    refresh()
end

function M.OnUnload()
    Utils.Table.ForEach(NAMES, function(_, n) Mongbat.DestroyWindow(n) end)
    Mongbat.DestroyWindow(NAME)
end

-- ---- Per-frame pull/push ------------------------------------------------

--- The lib calls this once per registered window per frame. We only want to
--- refresh the panel; the bar containers, fills, and labels share data with
--- the panel and would be redundant work.
function M.OnUpdateWindow(_name, key, _dt)
    if key == "panel" then refresh() end
end

-- ---- Click handling on the outer panel ---------------------------------

function M.OnLButtonDown(_name, key)
    if key == "panel" then
        state.downWinX, state.downWinY = W.frame:getPosition()
        W.frame:setMoving(true)
    end
end

function M.OnLButtonDblClk(_name, key)
    if key == "panel" then
        local id = Data.PlayerStatus():getId()
        if id ~= 0 then Api.UserAction.UseItem(id) end
    end
end

function M.OnLButtonUp(_name, key)
    if key ~= "panel" then return end
    W.frame:setMoving(false)
    local wx, wy = W.frame:getPosition()
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

function M.OnRButtonUp(_name, key)
    if key == "panel" then
        W.frame:hide()
    end
end

Mongbat.Mod {
    Name   = "MongbatPlayerStatus",
    Path   = "/src/mods/mongbat-player-status",
    Module = M,
}
