-- Paperdolls: equipment grid with a toggle to a full-figure view. Owns every
-- opened `PaperdollWindow<id>` declaratively, including non-player mobiles
-- announced when the suppressed default PaperdollWindow.Initialize fires.
--
-- Pattern: declarative. M.Build(emit) re-emits every window each frame.
-- Mode swaps simply emit a different child set; the lib auto-destroys
-- the missing keys and creates the new ones.

local UI        = Mongbat.UI
local Api       = Mongbat.Api
local Data      = Mongbat.Data
local Constants = Mongbat.Constants
local Utils     = Mongbat.Utils

local NUM_SLOTS    = 19
local COLUMNS      = 4
local CELL         = 50
local PADDING      = 8
local MARGIN       = 16
local LABEL_HEIGHT = 22
local LABEL_GAP    = 12

local ROWS         = math.ceil(NUM_SLOTS / COLUMNS)
local GRID_W       = COLUMNS * CELL + (COLUMNS - 1) * PADDING
local GRID_H       = ROWS    * CELL + (ROWS    - 1) * PADDING
local GRID_WIN_W   = GRID_W + MARGIN * 2 + 16
local GRID_WIN_H   = LABEL_HEIGHT + LABEL_GAP + GRID_H + MARGIN * 2 + 16

local M = {}
local state = {
    playerId   = 0,
    playerOpen = false,
    ids        = {},      -- ordered paperdoll ids
    paperdolls = {},      -- [id] = { id, mode, open, slots }
}

-- ---- Pulls --------------------------------------------------------------

local function paperdollName(id)
    return "PaperdollWindow" .. id
end

local function panelKey(id)
    return "panel_" .. id
end

local function slotKey(id, index)
    return "slot_" .. id .. "_" .. index
end

local function ensurePaperdoll(id)
    if not id or id == 0 then return nil end
    local doll = state.paperdolls[id]
    if not doll then
        doll = { id = id, mode = "grid", open = true, slots = {} }
        state.paperdolls[id] = doll
        Utils.Array.Add(state.ids, id)
    end
    return doll
end

local function syncPlayerId()
    local playerId = Data.PlayerStatus():getId()
    if playerId ~= 0 and playerId ~= state.playerId then
        state.playerId = playerId
        local doll = ensurePaperdoll(playerId)
        if doll then
            doll.open = state.playerOpen
            Api.Interface.SetPaperdollOpen(doll.open)
        end
    end
    return state.playerId ~= 0
end

local function setOpen(id, open)
    local doll = ensurePaperdoll(id)
    if not doll then return end
    doll.open = open and true or false
    if id == state.playerId then
        state.playerOpen = doll.open
        Api.Interface.SetPaperdollOpen(doll.open)
        Api.Interface.SaveBoolean("PaperdollOpen", doll.open)
    end
end

local function pullSlots(doll)
    local pd = Data.Paperdoll(doll.id)
    local n = pd:getNumSlots()
    for i = 1, NUM_SLOTS do
        doll.slots[i] = (i <= n) and pd:getSlot(i) or nil
    end
end

local function notorietyColor(id)
    if id == 0 then return nil end
    local n = Data.MobileStatus(id):getNotoriety()
    if n == nil then return nil end
    return Constants.Colors.Notoriety[n + 1]
end

local function handlePaperdollOpened(id)
    local name = paperdollName(id)
    if Api.Window.DoesExist(name) then
        Api.Window.SetShowing(name, false)
        Api.Window.Destroy(name)
    end

    local doll = ensurePaperdoll(id)
    if doll then setOpen(id, true) end
end

-- ---- Lifecycle --------------------------------------------------------

function M.OnLoad()
    state.playerOpen = Api.Interface.LoadBoolean("PaperdollOpen", Api.Interface.GetPaperdollOpen() == true) == true
    if syncPlayerId() then setOpen(state.playerId, state.playerOpen) end
    Mongbat.UI.Defaults.OverrideAction("TogglePaperdollWindow", function()
        if syncPlayerId() then
            local doll = ensurePaperdoll(state.playerId)
            setOpen(state.playerId, not (doll and doll.open))
        end
    end)
    Mongbat.UI.Defaults.Suppress("PaperdollWindow", nil, function(fnName)
        if fnName == "Initialize" then handlePaperdollOpened(Data.CurrentPaperdollId()) end
    end)
end

function M.OnUnload()
    local doll = state.paperdolls[state.playerId]
    Api.Interface.SetPaperdollOpen(doll ~= nil and doll.open == true)
end

-- ---- Declarative build ------------------------------------------------

local function emitPaperdoll(emit, doll)
    if not doll.open then return end

    pullSlots(doll)

    local id = doll.id
    local rootKey = panelKey(id)
    local nameText = Data.MobileName(id):getName() or " "
    local color    = notorietyColor(id)

    -- Outer panel: dimensions depend on mode (figure mode resizes to the
    -- texture's natural size).
    local panelW, panelH = GRID_WIN_W, GRID_WIN_H
    local figTex
    if doll.mode == "figure" then
        figTex = Data.PaperdollTexture(id)
        if figTex:hasData() then
            panelW, panelH = figTex:getWidth(), figTex:getHeight()
        else
            panelW, panelH = 200, 400
        end
    end

    emit(rootKey, {
        name            = paperdollName(id),
        replacesDefault = true,
        template        = "MongbatWindow",
        id              = id,
        draggable       = true,
        widget          = UI.Window():setDimensions(panelW, panelH):setId(id),
    })

    -- Persistent name label across mode swaps.
    local nameLabel = UI.Label()
        :setDimensions(GRID_WIN_W - MARGIN * 2, LABEL_HEIGHT)
        :setOffsetFromParent(MARGIN, MARGIN)
        :setTextAlignment("center")
        :setText(nameText)
        :setId(id)
    if color then nameLabel:setTextColor(color) end

    emit("name_" .. id, {
        template = "MongbatLabel",
        parent   = rootKey,
        id       = id,
        widget   = nameLabel,
    })

    if doll.mode == "grid" then
        for i = 1, NUM_SLOTS do
            local row = math.floor((i - 1) / COLUMNS)
            local col = (i - 1) % COLUMNS
            local slot = doll.slots[i]
            emit(slotKey(id, i), {
                template = "MongbatDynamicImage",
                parent   = rootKey,
                id       = id,
                widget   = UI.DynamicImage()
                    :setHandleInput(true)
                    :setDimensions(CELL, CELL)
                    :setOffsetFromParent(
                        MARGIN + col * (CELL + PADDING),
                        MARGIN + LABEL_HEIGHT + LABEL_GAP + row * (CELL + PADDING))
                    :tap(function(name) Api.Equipment.UpdateItemIcon(name, slot) end),
            })
        end

        -- Toggle in the next grid cell (the 20th).
        local toggleIndex = NUM_SLOTS + 1
        local row = math.floor((toggleIndex - 1) / COLUMNS)
        local col = (toggleIndex - 1) % COLUMNS
        emit("toggle_" .. id, {
            template = "MongbatButton18",
            parent   = rootKey,
            id       = id,
            widget   = UI.Button()
                :setDimensions(CELL, CELL)
                :setOffsetFromParent(
                    MARGIN + col * (CELL + PADDING),
                    MARGIN + LABEL_HEIGHT + LABEL_GAP + row * (CELL + PADDING))
                :setText("\xE2\x98\xBA"),
        })
    elseif doll.mode == "figure" then
        local anchorX, anchorY
        if figTex and figTex:hasData() then
            anchorX, anchorY = figTex:getXOffset(), figTex:getYOffset() + 30
        else
            anchorX, anchorY = 0, 0
        end
        local texName = figTex and figTex:getTextureName() or ""
        emit("figure_" .. id, {
            template = "MongbatFilteredDynamicImage",
            parent   = rootKey,
            id       = id,
            widget   = UI.DynamicImage()
                :setHandleInput(true)
                :setDimensions(panelW, panelH)
                :setTexture(texName, 0, 0)
                :clearAnchors()
                :addAnchor("center", "parent", "topleft", anchorX, anchorY),
        })
    end
end

function M.Build(emit)
    syncPlayerId()
    Utils.Array.ForEach(state.ids, function(id)
        emitPaperdoll(emit, state.paperdolls[id])
    end)
end

-- ---- Click routing ----------------------------------------------------

local function slotIndexFromKey(key)
    if type(key) ~= "string" then return nil end
    local s = Utils.String.Match(key, "^slot_%d+_(%d+)$")
    return s and tonumber(s) or nil
end

local function getDoll(window)
    return state.paperdolls[window.id]
end

function M.OnLButtonDown(window)
    local doll = getDoll(window)
    if not doll then return end
    local i = slotIndexFromKey(window.key)
    if not i then return end
    local slot = doll.slots[i]
    if not slot or slot.slotId == 0 then return end
    if Data.Cursor():isTarget() then
        Api.Target.LeftClick(slot.slotId)
        return
    end
    Api.Drag.SetObjectMouseClickData(slot.slotId, Constants.DragSource.Paperdoll())
end

function M.OnLButtonUp(window)
    local doll = getDoll(window)
    if not doll then return end
    if window.key == "toggle_" .. doll.id then doll.mode = "figure"; return end
    if window.key == "figure_" .. doll.id then doll.mode = "grid";   return end
    if window.key == panelKey(doll.id) then
        if Data.Drag():isDraggingItem() then
            Api.Drag.DropOnPaperdoll(doll.id)
        end
        return
    end
    local i = slotIndexFromKey(window.key)
    if not i then return end
    if not Data.Drag():isDraggingItem() then return end
    local slot = doll.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.Drag.DropOnPaperdollEquipment(slot.slotId)
    else
        Api.Drag.DropOnPaperdoll(doll.id)
    end
end

function M.OnLButtonDblClk(window)
    local doll = getDoll(window)
    if not doll then return end
    local i = slotIndexFromKey(window.key)
    if not i then return end
    local slot = doll.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.UserAction.UseItem(slot.slotId, false)
    end
end

function M.OnRButtonDown(window)
    local doll = getDoll(window)
    if not doll then return end
    local i = slotIndexFromKey(window.key)
    if not i then return end
    local slot = doll.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.ContextMenu.RequestMenu(slot.slotId)
    end
end

function M.OnRButtonUp(window)
    if window.key == panelKey(window.id) then
        setOpen(window.id, false)
    end
end

function M.OnMouseOver(window)
    local doll = getDoll(window)
    if not doll then return end
    local i = slotIndexFromKey(window.key)
    if not i then return end
    local slot = doll.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.ItemProperties.SetActiveItem({
            windowName = window.name,
            itemId     = slot.slotId,
            itemType   = Constants.ItemPropertyType.Item,
            detail     = Constants.ItemPropertyDetail.Long,
            data       = slot,
        })
    end
end

function M.OnMouseOverEnd(window)
    if slotIndexFromKey(window.key) then
        Api.ItemProperties.ClearMouseOverItem()
    end
end

Mongbat.Mod {
    Name   = "MongbatPaperdoll",
    Path   = "/src/mods/mongbat-paperdoll",
    Module = M,
}
