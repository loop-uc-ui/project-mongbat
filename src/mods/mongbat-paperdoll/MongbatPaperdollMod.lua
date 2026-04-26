-- Player paperdoll: equipment grid with a toggle to a full-figure view.
-- Hijacks the engine''s per-player PaperdollWindow<id> by suppressing the
-- default UI''s open flag and destroying any pre-existing instance, then
-- owns presentation entirely with a stable name.
--
-- Pattern: Mongbat is a router. Each slot, the toggle, the figure, and the
-- name label are individually-registered windows. Mode swaps destroy the
-- mode-specific children and recreate the other set; the outer window and
-- name label persist across mode changes.

local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Constants = Mongbat.Constants
local Utils     = Mongbat.Utils

local NAME         = "MongbatPaperdollWindow"
local TOGGLE_NAME  = "MongbatPaperdollToggle"
local FIGURE_NAME  = "MongbatPaperdollFigure"
local LABEL_NAME   = "MongbatPaperdollName"

local NUM_SLOTS    = 19
local COLUMNS      = 4
local CELL         = 50
local PADDING      = 8
local MARGIN       = 16
local LABEL_HEIGHT = 22
local LABEL_GAP    = 12
local FIGURE_SCALE = 0.70

local ROWS         = math.ceil(NUM_SLOTS / COLUMNS)
local GRID_W       = COLUMNS * CELL + (COLUMNS - 1) * PADDING
local GRID_H       = ROWS    * CELL + (ROWS    - 1) * PADDING
local GRID_WIN_W   = GRID_W + MARGIN * 2 + 16
local GRID_WIN_H   = LABEL_HEIGHT + LABEL_GAP + GRID_H + MARGIN * 2 + 16

local M = {}
local state = {
    playerId = 0,
    mode     = "grid",   -- "grid" | "figure"
    name     = "",
    slots    = {},        -- [1..NUM_SLOTS] = raw slot data
}

local function slotName(i) return NAME .. "Slot" .. i end

-- ---- Pulls --------------------------------------------------------------

local function pullSlots()
    local pd = Data.Paperdoll(state.playerId)
    local n = pd:getNumSlots()
    for i = 1, NUM_SLOTS do
        state.slots[i] = (i <= n) and pd:getSlot(i) or nil
    end
end

local function pullName()
    if state.playerId == 0 then return end
    local n = Data.MobileName(state.playerId):getName()
    if n then state.name = n end
end

local function notorietyColor()
    if state.playerId == 0 then return nil end
    local n = Data.MobileStatus(state.playerId):getNotoriety()
    if n == nil then return nil end
    return Constants.Colors.Notoriety[n + 1]
end

-- ---- Push -------------------------------------------------------------

local function pushNameLabel()
    if not Api.Window.DoesExist(LABEL_NAME) then return end
    local text = state.name ~= "" and state.name or " "
    Api.Label.SetText(LABEL_NAME, text)
    local color = notorietyColor()
    if color then Api.Label.SetTextColor(LABEL_NAME, color) end
    Api.Window.SetId(LABEL_NAME, state.playerId)
end

local function pushSlotIcons()
    for i = 1, NUM_SLOTS do
        local n = slotName(i)
        if Api.Window.DoesExist(n) then
            Api.Equipment.UpdateItemIcon(n, state.slots[i])
        end
    end
end

-- ---- Mode-specific creation ------------------------------------------

local function destroyGridChildren()
    for i = 1, NUM_SLOTS do Mongbat.DestroyWindow(slotName(i)) end
    Mongbat.DestroyWindow(TOGGLE_NAME)
end

local function destroyFigureChildren()
    Mongbat.DestroyWindow(FIGURE_NAME)
end

local function createGridChildren()
    Api.Window.SetDimensions(NAME, GRID_WIN_W, GRID_WIN_H)

    for i = 1, NUM_SLOTS do
        local n = slotName(i)
        local row = math.floor((i - 1) / COLUMNS)
        local col = (i - 1) % COLUMNS
        Mongbat.CreateWindow {
            name = n, template = "MongbatDynamicImage",
            parent = NAME, module = M, key = "slot" .. i,
        }
        Api.Window.SetDimensions(n, CELL, CELL)
        Api.Window.SetOffsetFromParent(n,
            MARGIN + col * (CELL + PADDING),
            MARGIN + LABEL_HEIGHT + LABEL_GAP + row * (CELL + PADDING))
        Api.Equipment.UpdateItemIcon(n, state.slots[i])
    end

    -- Toggle lives in the next grid cell (the 20th).
    local toggleIndex = NUM_SLOTS + 1
    local row = math.floor((toggleIndex - 1) / COLUMNS)
    local col = (toggleIndex - 1) % COLUMNS
    Mongbat.CreateWindow {
        name = TOGGLE_NAME, template = "MongbatButton18",
        parent = NAME, module = M, key = "toggle",
    }
    Api.Window.SetDimensions(TOGGLE_NAME, CELL, CELL)
    Api.Window.SetOffsetFromParent(TOGGLE_NAME,
        MARGIN + col * (CELL + PADDING),
        MARGIN + LABEL_HEIGHT + LABEL_GAP + row * (CELL + PADDING))
    Api.Button.SetText(TOGGLE_NAME, "\xE2\x98\xBA")
end

local function createFigureChildren()
    local tex = Data.PaperdollTexture(state.playerId)
    local texW, texH, anchorX, anchorY
    if tex:hasData() then
        texW, texH = tex:getWidth(), tex:getHeight()
        anchorX, anchorY = tex:getXOffset(), tex:getYOffset() + 30
    else
        texW, texH = 200, 400
        anchorX, anchorY = 0, 0
    end

    Api.Window.SetDimensions(NAME, texW, texH)

    Mongbat.CreateWindow {
        name = FIGURE_NAME, template = "MongbatFilteredDynamicImage",
        parent = NAME, module = M, key = "figure",
    }
    Api.Window.SetDimensions(FIGURE_NAME, texW, texH)
    Api.DynamicImage.SetTexture(FIGURE_NAME, tex:getTextureName(), 0, 0)
    Api.Window.ClearAnchors(FIGURE_NAME)
    Api.Window.AddAnchor(FIGURE_NAME, "center", "parent", "topleft", anchorX, anchorY)
end

local function setMode(mode)
    if state.mode == mode then return end
    if state.mode == "grid"   then destroyGridChildren()   end
    if state.mode == "figure" then destroyFigureChildren() end
    state.mode = mode
    if mode == "grid"   then createGridChildren()   end
    if mode == "figure" then createFigureChildren() end
end

-- ---- Lifecycle --------------------------------------------------------

function M.OnLoad()
    state.playerId = Data.PlayerStatus():getId()

    -- Suppress the default UI from re-opening its paperdoll window, and
    -- destroy any instance the engine may already have created for this
    -- player. The default UI''s globals stay intact.
    Api.Interface.SetPaperdollOpen(false)
    local defaultName = "PaperdollWindow" .. state.playerId
    if Api.Window.DoesExist(defaultName) then
        Api.Window.Destroy(defaultName)
    end

    pullSlots(); pullName()

    Mongbat.CreateWindow {
        name = NAME, template = "MongbatWindow",
        module = M, key = "panel",
        bindings = { "Paperdoll", "MobileName", "MobileStatus" },
    }
    Api.Window.SetDimensions(NAME, GRID_WIN_W, GRID_WIN_H)
    Api.Window.SetId(NAME, state.playerId)

    -- Persistent name label across mode swaps.
    Mongbat.CreateWindow {
        name = LABEL_NAME, template = "MongbatLabel",
        parent = NAME, module = M, key = "name",
    }
    Api.Window.SetDimensions(LABEL_NAME, GRID_WIN_W - MARGIN * 2, LABEL_HEIGHT)
    Api.Window.SetOffsetFromParent(LABEL_NAME, MARGIN, MARGIN)
    Api.Label.SetTextAlignment(LABEL_NAME, "center")
    pushNameLabel()

    createGridChildren()
end

function M.OnUnload()
    if state.mode == "grid"   then destroyGridChildren()   end
    if state.mode == "figure" then destroyFigureChildren() end
    Mongbat.DestroyWindow(LABEL_NAME)
    Mongbat.DestroyWindow(NAME)
    Api.Interface.SetPaperdollOpen(true)
end

-- ---- Bindings ---------------------------------------------------------

function M.OnUpdatePaperdoll()
    pullSlots()
    if state.mode == "grid" then pushSlotIcons() end
end

function M.OnUpdateMobileName()
    pullName()
    pushNameLabel()
end

function M.OnUpdateMobileStatus()
    pushNameLabel()
end

-- ---- Click routing ----------------------------------------------------

local function slotIndexFromKey(key)
    if type(key) ~= "string" then return nil end
    local s = key:match("^slot(%d+)$")
    return s and tonumber(s) or nil
end

function M.OnLButtonDown(_name, key)
    local i = slotIndexFromKey(key)
    if not i then return end
    local slot = state.slots[i]
    if not slot or slot.slotId == 0 then return end
    if Data.Cursor():isTarget() then
        Api.Target.LeftClick(slot.slotId)
        return
    end
    Api.Drag.SetObjectMouseClickData(slot.slotId, Constants.DragSource.Paperdoll())
end

function M.OnLButtonUp(_name, key)
    if key == "toggle" then
        setMode("figure")
        return
    end
    if key == "figure" then
        setMode("grid")
        return
    end
    if key == "panel" then
        if Data.Drag():isDraggingItem() then
            Api.Drag.DropOnPaperdoll(state.playerId)
        end
        return
    end
    local i = slotIndexFromKey(key)
    if not i then return end
    if not Data.Drag():isDraggingItem() then return end
    local slot = state.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.Drag.DropOnPaperdollEquipment(slot.slotId)
    else
        Api.Drag.DropOnPaperdoll(state.playerId)
    end
end

function M.OnLButtonDblClk(_name, key)
    local i = slotIndexFromKey(key)
    if not i then return end
    local slot = state.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.UserAction.UseItem(slot.slotId, false)
    end
end

function M.OnRButtonDown(_name, key)
    local i = slotIndexFromKey(key)
    if not i then return end
    local slot = state.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.ContextMenu.RequestMenu(slot.slotId)
    end
end

function M.OnRButtonUp(_name, key)
    if key == "panel" then
        M.OnUnload()
    end
end

function M.OnMouseOver(_name, key)
    local i = slotIndexFromKey(key)
    if not i then return end
    local slot = state.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.ItemProperties.SetActiveItem({
            windowName = NAME,
            itemId     = slot.slotId,
            itemType   = Constants.ItemPropertyType.Item,
            detail     = Constants.ItemPropertyDetail.Long,
            data       = slot,
        })
    end
end

function M.OnMouseOverEnd(_name, key)
    if slotIndexFromKey(key) then
        Api.ItemProperties.ClearMouseOverItem()
    end
end

Mongbat.Mod {
    Name   = "MongbatPaperdoll",
    Path   = "/src/mods/mongbat-paperdoll",
    Module = M,
}
