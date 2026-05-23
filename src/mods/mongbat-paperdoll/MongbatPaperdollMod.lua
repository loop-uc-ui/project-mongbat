-- Player paperdoll: equipment grid with a toggle to a full-figure view.
-- Hijacks the engine's per-player PaperdollWindow<id> by suppressing the
-- default UI's open flag and destroying any pre-existing instance, then
-- owns presentation entirely.
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
    playerId = 0,
    mode     = "grid",   -- "grid" | "figure"
    slots    = {},        -- [1..NUM_SLOTS] = raw slot data
}

-- ---- Pulls --------------------------------------------------------------

local function pullSlots()
    local pd = Data.Paperdoll(state.playerId)
    local n = pd:getNumSlots()
    for i = 1, NUM_SLOTS do
        state.slots[i] = (i <= n) and pd:getSlot(i) or nil
    end
end

local function notorietyColor()
    if state.playerId == 0 then return nil end
    local n = Data.MobileStatus(state.playerId):getNotoriety()
    if n == nil then return nil end
    return Constants.Colors.Notoriety[n + 1]
end

-- ---- Lifecycle --------------------------------------------------------

function M.OnLoad()
    state.playerId = Data.PlayerStatus():getId()

    -- Suppress the default UI from re-opening its paperdoll window, and
    -- destroy any instance the engine may already have created for this
    -- player. The default UI's globals stay intact.
    Api.Interface.SetPaperdollOpen(false)
    local defaultName = "PaperdollWindow" .. state.playerId
    if Api.Window.DoesExist(defaultName) then
        Api.Window.Destroy(defaultName)
    end
end

function M.OnUnload()
    Api.Interface.SetPaperdollOpen(true)
end

-- ---- Declarative build ------------------------------------------------

function M.Build(emit)
    if state.playerId == 0 then return end

    pullSlots()

    local nameText = Data.MobileName(state.playerId):getName() or " "
    local color    = notorietyColor()

    -- Outer panel: dimensions depend on mode (figure mode resizes to the
    -- texture's natural size).
    local panelW, panelH = GRID_WIN_W, GRID_WIN_H
    local figTex
    if state.mode == "figure" then
        figTex = Data.PaperdollTexture(state.playerId)
        if figTex:hasData() then
            panelW, panelH = figTex:getWidth(), figTex:getHeight()
        else
            panelW, panelH = 200, 400
        end
    end

    emit("panel", {
        template = "MongbatWindow",
        id       = state.playerId,
        widget   = UI.Window():setDimensions(panelW, panelH):setId(state.playerId),
    })

    -- Persistent name label across mode swaps.
    local nameLabel = UI.Label()
        :setDimensions(GRID_WIN_W - MARGIN * 2, LABEL_HEIGHT)
        :setOffsetFromParent(MARGIN, MARGIN)
        :setTextAlignment("center")
        :setText(nameText)
        :setId(state.playerId)
    if color then nameLabel:setTextColor(color) end

    emit("name", {
        template = "MongbatLabel",
        parent   = "panel",
        id       = state.playerId,
        widget   = nameLabel,
    })

    if state.mode == "grid" then
        for i = 1, NUM_SLOTS do
            local row = math.floor((i - 1) / COLUMNS)
            local col = (i - 1) % COLUMNS
            local slot = state.slots[i]
            emit("slot" .. i, {
                template = "MongbatDynamicImage",
                parent   = "panel",
                widget   = UI.DynamicImage()
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
        emit("toggle", {
            template = "MongbatButton18",
            parent   = "panel",
            widget   = UI.Button()
                :setDimensions(CELL, CELL)
                :setOffsetFromParent(
                    MARGIN + col * (CELL + PADDING),
                    MARGIN + LABEL_HEIGHT + LABEL_GAP + row * (CELL + PADDING))
                :setText("\xE2\x98\xBA"),
        })
    elseif state.mode == "figure" then
        local anchorX, anchorY
        if figTex and figTex:hasData() then
            anchorX, anchorY = figTex:getXOffset(), figTex:getYOffset() + 30
        else
            anchorX, anchorY = 0, 0
        end
        local texName = figTex and figTex:getTextureName() or ""
        emit("figure", {
            template = "MongbatFilteredDynamicImage",
            parent   = "panel",
            widget   = UI.DynamicImage()
                :setDimensions(panelW, panelH)
                :setTexture(texName, 0, 0)
                :clearAnchors()
                :addAnchor("center", "parent", "topleft", anchorX, anchorY),
        })
    end
end

-- ---- Click routing ----------------------------------------------------

local function slotIndexFromKey(key)
    if type(key) ~= "string" then return nil end
    local s = key:match("^slot(%d+)$")
    return s and tonumber(s) or nil
end

function M.OnLButtonDown(window)
    local i = slotIndexFromKey(window.key)
    if not i then return end
    local slot = state.slots[i]
    if not slot or slot.slotId == 0 then return end
    if Data.Cursor():isTarget() then
        Api.Target.LeftClick(slot.slotId)
        return
    end
    Api.Drag.SetObjectMouseClickData(slot.slotId, Constants.DragSource.Paperdoll())
end

function M.OnLButtonUp(window)
    if window.key == "toggle" then state.mode = "figure"; return end
    if window.key == "figure" then state.mode = "grid";   return end
    if window.key == "panel" then
        if Data.Drag():isDraggingItem() then
            Api.Drag.DropOnPaperdoll(state.playerId)
        end
        return
    end
    local i = slotIndexFromKey(window.key)
    if not i then return end
    if not Data.Drag():isDraggingItem() then return end
    local slot = state.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.Drag.DropOnPaperdollEquipment(slot.slotId)
    else
        Api.Drag.DropOnPaperdoll(state.playerId)
    end
end

function M.OnLButtonDblClk(window)
    local i = slotIndexFromKey(window.key)
    if not i then return end
    local slot = state.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.UserAction.UseItem(slot.slotId, false)
    end
end

function M.OnRButtonDown(window)
    local i = slotIndexFromKey(window.key)
    if not i then return end
    local slot = state.slots[i]
    if slot and slot.slotId ~= 0 then
        Api.ContextMenu.RequestMenu(slot.slotId)
    end
end

function M.OnRButtonUp(window)
    if window.key == "panel" then
        Api.Window.SetShowing(window.name, false)
    end
end

function M.OnMouseOver(window)
    local i = slotIndexFromKey(window.key)
    if not i then return end
    local slot = state.slots[i]
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
