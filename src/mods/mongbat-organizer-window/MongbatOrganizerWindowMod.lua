-- ============================================================
-- MongbatOrganizerWindowMod.lua
-- Replaces the default OrganizerWindow UI with a clean
-- Mongbat implementation.  The Organizer data model
-- (global table `Organizer`) is intentionally left intact so
-- that ContainerWindow, Shopkeeper, ObjectHandle, and Actions
-- continue to read from it without modification.
-- ============================================================

local NAME = "OrganizerWindow"

-- Layout constants
local WIN_W      = 500
local MARGIN     = 10
local AVAIL_W    = WIN_W - MARGIN * 2   -- 480px
local ROW_H      = 28
local ROW_GAP    = 4
local TAB_W      = math.floor(AVAIL_W / 6)  -- 80px per tab

-- Row Y positions (relative to top of window interior)
local TAB_Y    = MARGIN                         -- 10
local AGENT_Y  = TAB_Y  + ROW_H + ROW_GAP      -- 42
local CONT_Y   = AGENT_Y + ROW_H + ROW_GAP     -- 74
local ADD_Y    = CONT_Y  + ROW_H + ROW_GAP     -- 106
local ITEM_Y   = ADD_Y   + ROW_H + ROW_GAP + 4 -- 142 (items start here)

-- Agent-row child widths (sum must equal AVAIL_W = 480)
local PREV_W   = 28   -- [<]
local LABEL_W  = 182  -- AgentName (= AVAIL_W - other widths - gaps)
local NEXT_W   = 28   -- [>]
local RENAME_W = 72   -- [Rename]
local ADDAGNT_W = 28  -- [+]
local REMAGNT_W = 28  -- [-]
local DEF_W    = 100  -- [Set Default] / "(Default)"
-- sum = 28+2+182+2+28+4+72+2+28+2+28+2+100 = 480 ✓

-- Container-row widths
local CONT_BTN_W  = 150
local CLOSE_BTN_W = 150

-- Add-buttons-row widths
local ADDTYPE_W  = 140
local ADDID_W    = 140
local SCROLL_D_W = 28
local SCROLL_U_W = 28

-- Max item rows visible without scrolling
local MAX_VISIBLE = 14
local ITEM_H      = 24
local ITEM_GAP    = 2

-- Window height = controls + item rows + frame overhead
local WIN_H = ITEM_Y + MAX_VISIBLE * (ITEM_H + ITEM_GAP) + MARGIN + 30

-- ============================================================
-- Agent-type descriptor table.
-- Drives all type-specific branching.
-- ============================================================

---@class AgentTypeDesc
---@field key        string   Display prefix ("Organizer", "Undress", …)
---@field countKey   string   Organizer.*count* field ("Organizers","Undresses",…)
---@field listKey    string   Organizer.*list* field ("Organizer","Undress",…)
---@field itemsKey   string   Organizer.*_Items field
---@field descKey    string   Organizer.*_Desc  field
---@field contKey    string|nil  Organizer.*_Cont  field (nil = no container)
---@field closeKey   string|nil  Organizer.*_CloseCont field
---@field activeKey  string   Organizer.Active* field
---@field savePrefix string   Item key prefix ("Organizer","Undress",…)
---@field hasType    boolean
---@field hasId      boolean
---@field hasQta     boolean

local AGENT_TYPES = {
    {
        key="Organizer", countKey="Organizers", listKey="Organizer",
        itemsKey="Organizers_Items", descKey="Organizers_Desc",
        contKey="Organizers_Cont", closeKey="Organizers_CloseCont",
        activeKey="ActiveOrganizer", savePrefix="Organizer",
        hasType=true, hasId=true, hasQta=false,
    },
    {
        key="Undress", countKey="Undresses", listKey="Undress",
        itemsKey="Undresses_Items", descKey="Undresses_Desc",
        contKey="Undresses_Cont", closeKey=nil,
        activeKey="ActiveUndress", savePrefix="Undress",
        hasType=false, hasId=true, hasQta=false,
    },
    {
        key="Restock", countKey="Restocks", listKey="Restock",
        itemsKey="Restocks_Items", descKey="Restocks_Desc",
        contKey="Restocks_Cont", closeKey=nil,
        activeKey="ActiveRestock", savePrefix="Restock",
        hasType=true, hasId=false, hasQta=true,
    },
    {
        key="Buy", countKey="Buys", listKey="Buy",
        itemsKey="Buys_Items", descKey="Buys_Desc",
        contKey=nil, closeKey=nil,
        activeKey="ActiveBuy", savePrefix="Buy",
        hasType=true, hasId=false, hasQta=true,
    },
    {
        key="Sell", countKey="Sells", listKey="Sell",
        itemsKey="Sells_Items", descKey="Sells_Desc",
        contKey=nil, closeKey=nil,
        activeKey="ActiveSell", savePrefix="Sell",
        hasType=true, hasId=false, hasQta=true,
    },
    {
        key="Scavenger", countKey="Scavengers", listKey="Scavenger",
        itemsKey="Scavengers_Items", descKey="Scavengers_Desc",
        contKey="Scavengers_Cont", closeKey=nil,
        activeKey="ActiveScavenger", savePrefix="Scavenger",
        hasType=true, hasId=false, hasQta=false,
    },
}

-- ============================================================
-- Data helpers (read-only access to the Organizer model)
-- ============================================================

---@param typeIndex integer 1-6
---@return AgentTypeDesc
local function getTypeDesc(typeIndex)
    return AGENT_TYPES[typeIndex]
end

---@param desc AgentTypeDesc
---@return integer
local function agentCount(desc)
    return Organizer[desc.countKey] or 1
end

---@param desc AgentTypeDesc
---@param agentIndex integer
---@return integer
local function itemCount(desc, agentIndex)
    local t = Organizer[desc.itemsKey]
    return (t and t[agentIndex]) or 0
end

---@param desc AgentTypeDesc
---@param agentIndex integer
---@return wstring
local function agentDesc(desc, agentIndex)
    local d = Organizer[desc.descKey]
    return (d and d[agentIndex]) or L""
end

---@param desc AgentTypeDesc
---@param agentIndex integer
---@return wstring
local function agentDisplayName(desc, agentIndex)
    local custom = agentDesc(desc, agentIndex)
    local base   = StringToWString(desc.key) .. L" " .. towstring(agentIndex)
    if custom and custom ~= L"" then
        return custom .. L" (" .. base .. L")"
    end
    return base
end

--- Formats an item for display in the list.
---@param desc AgentTypeDesc
---@param item table
---@param itemIndex integer
---@return wstring
local function formatItemLabel(desc, item, itemIndex)
    if not item then return L"" end
    local name = StringToWString(item.name or "")
    if item.type and item.type ~= 0 then
        local s = towstring(itemIndex) .. L". " .. name ..
                  L" - Type: " .. towstring(item.type) ..
                  L", Hue: "   .. towstring(item.hue or 0)
        if desc.hasQta and item.qta then
            s = s .. L", Amount: " .. towstring(item.qta)
        end
        return s
    elseif item.id and item.id ~= 0 then
        return towstring(itemIndex) .. L". " .. name .. L" - ID: " .. towstring(item.id)
    end
    return towstring(itemIndex) .. L". " .. name
end

--- Strips leading numeric quantity (mirrors Shopkeeper.stripFirstNumber).
---@param name wstring
---@return wstring
local function stripFirstNumber(name)
    if not name then return L"" end
    local s       = WStringToString(name)
    local stripped = string.gsub(s, "^%d+%s*", "")
    return StringToWString(stripped)
end

-- ============================================================
-- Persistence helpers
-- ============================================================

--- Saves all items for one agent to Interface storage.
---@param desc AgentTypeDesc
---@param agentIndex integer
---@param Api table
local function saveAgentItems(desc, agentIndex, Api)
    local count = itemCount(desc, agentIndex)
    Api.Interface.SaveNumber("Organizer" .. desc.countKey .. "_Items" .. agentIndex, count)
    local list = Organizer[desc.listKey]
    if not list or not list[agentIndex] then return end
    for k = 1, count do
        local item = list[agentIndex][k]
        if item then
            Api.Interface.SaveString(
                desc.savePrefix .. agentIndex .. "it" .. k .. "Name", item.name or "")
            Api.Interface.SaveNumber(
                desc.savePrefix .. agentIndex .. "it" .. k .. "Type", item.type or 0)
            Api.Interface.SaveNumber(
                desc.savePrefix .. agentIndex .. "it" .. k .. "Hue",  item.hue  or 0)
            if desc.hasQta then
                Api.Interface.SaveNumber(
                    desc.savePrefix .. agentIndex .. "it" .. k .. "Qta", item.qta or 0)
            else
                Api.Interface.SaveNumber(
                    desc.savePrefix .. agentIndex .. "it" .. k .. "Id",  item.id  or 0)
            end
        end
    end
end

--- Deletes all stored items for all agents of a given type (used before re-saving).
---@param desc AgentTypeDesc
---@param Api table
local function deleteAllAgentItems(desc, Api)
    local count = agentCount(desc)
    for i = 1, count do
        local ic = itemCount(desc, i)
        for k = 1, ic do
            Api.Interface.DeleteSetting(desc.savePrefix .. i .. "it" .. k .. "Name")
            Api.Interface.DeleteSetting(desc.savePrefix .. i .. "it" .. k .. "Type")
            Api.Interface.DeleteSetting(desc.savePrefix .. i .. "it" .. k .. "Hue")
            if desc.hasQta then
                Api.Interface.DeleteSetting(desc.savePrefix .. i .. "it" .. k .. "Qta")
            else
                Api.Interface.DeleteSetting(desc.savePrefix .. i .. "it" .. k .. "Id")
            end
        end
        Api.Interface.DeleteSetting("Organizer" .. desc.countKey .. "_Items" .. i)
        Api.Interface.DeleteSetting("Organizer" .. desc.countKey .. "_Desc"  .. i)
        if desc.contKey then
            Api.Interface.DeleteSetting("Organizer" .. desc.contKey .. i)
        end
        if desc.closeKey then
            Api.Interface.DeleteSetting("Organizer" .. desc.closeKey .. i)
        end
    end
end

--- Saves all agents of a type after a structural change (add/remove agent).
---@param desc AgentTypeDesc
---@param Api table
local function saveAllAgents(desc, Api)
    local count = agentCount(desc)
    Api.Interface.SaveNumber("Organizer" .. desc.countKey, count)
    for i = 1, count do
        saveAgentItems(desc, i, Api)
        Api.Interface.SaveWString("Organizer" .. desc.countKey .. "_Desc" .. i, agentDesc(desc, i))
        if desc.contKey then
            local cont  = Organizer[desc.contKey]
            Api.Interface.SaveNumber("Organizer" .. desc.contKey .. i, (cont and cont[i]) or 0)
        end
        if desc.closeKey then
            local cc = Organizer[desc.closeKey]
            Api.Interface.SaveBoolean("Organizer" .. desc.closeKey .. i, (cc and cc[i]) or false)
        end
    end
end

-- ============================================================
-- OnInitialize / OnShutdown
-- ============================================================

---@param context Context
local function OnInitialize(context)
    local Api        = context.Api
    local Components = context.Components
    local Constants  = context.Constants

    -- Suppress the default OrganizerWindow UI
    local orgDefault = Components.Defaults.OrganizerWindow
    orgDefault:disable()

    -- Destroy the default engine window if it already exists
    if Api.Window.DoesExist(NAME) then
        Api.Window.Destroy(NAME)
    end

    -- --------------------------------------------------------
    -- Mutable state (all scoped inside OnInitialize)
    -- --------------------------------------------------------
    local selectedType  = 1   -- current AgentTypeDesc index (1-6)
    local selectedIndex = 1   -- current agent index within type
    local itemViews     = {}  -- current dynamic item-row Button views
    local scrollOffset  = 0   -- index of first visible item (0-based)

    -- References set during layout construction
    local agentLabel    = nil
    local prevBtn       = nil
    local nextBtn       = nil
    local setDefaultBtn = nil
    local defaultLabel  = nil
    local containerBtn  = nil
    local autoCloseBtn  = nil
    local addTypeBtn    = nil
    local addIdBtn      = nil
    local scrollUpBtn   = nil
    local scrollDownBtn = nil

    -- Forward declaration
    local refreshUI

    -- --------------------------------------------------------
    -- Dynamic item list management
    -- --------------------------------------------------------

    local function clearItemList()
        for _, v in ipairs(itemViews) do
            v:destroy()
        end
        itemViews = {}
    end

    --- Removes an item from the agent list and persists the change.
    ---@param desc AgentTypeDesc
    ---@param capturedIndex integer  1-based item index to remove
    local function removeItem(desc, capturedIndex)
        local list  = Organizer[desc.listKey]
        local items = Organizer[desc.itemsKey]
        if not list or not list[selectedIndex] then return end

        -- Delete all stored keys for this agent first
        local ic = itemCount(desc, selectedIndex)
        for k = 1, ic do
            Api.Interface.DeleteSetting(desc.savePrefix .. selectedIndex .. "it" .. k .. "Name")
            Api.Interface.DeleteSetting(desc.savePrefix .. selectedIndex .. "it" .. k .. "Type")
            Api.Interface.DeleteSetting(desc.savePrefix .. selectedIndex .. "it" .. k .. "Hue")
            if desc.hasQta then
                Api.Interface.DeleteSetting(desc.savePrefix .. selectedIndex .. "it" .. k .. "Qta")
            else
                Api.Interface.DeleteSetting(desc.savePrefix .. selectedIndex .. "it" .. k .. "Id")
            end
        end
        table.remove(list[selectedIndex], capturedIndex)
        if items then items[selectedIndex] = math.max(0, (items[selectedIndex] or 1) - 1) end
        saveAgentItems(desc, selectedIndex, Api)
        refreshUI()
    end

    --- Creates one item-row button and places it inside the main window.
    ---@param desc AgentTypeDesc
    ---@param item table
    ---@param itemIndex integer  1-based
    ---@param prevName string|nil  engine name of the button above
    ---@return Button
    local function makeItemRow(desc, item, itemIndex, prevName)
        local labelText  = formatItemLabel(desc, item, itemIndex)
        local capturedIdx = itemIndex

        local btn = Components.Button {
            OnInitialize = function(self)
                self:setDimensions(AVAIL_W - 4, ITEM_H)
                self:setText(labelText)
            end,
            OnRButtonUp = function(self)
                if desc.hasQta then
                    -- Context menu: edit amount or remove
                    Api.ContextMenu.CreateLuaItem(L"Edit Amount", 0, "Edit",   2, false)
                    Api.ContextMenu.CreateLuaItem(L"Remove",      0, "Delete", 2, false)
                    Api.ContextMenu.ActivateLuaMenu(function(returnCode, _)
                        if returnCode == "Edit" then
                            Api.RenameWindow.Create {
                                title        = L"Set Amount",
                                subtitle     = L"Enter quantity:",
                                callfunction = function(_, amountStr)
                                    local amount = tonumber(amountStr)
                                    if type(amount) == "number" then
                                        local list = Organizer[desc.listKey]
                                        if list and list[selectedIndex] and list[selectedIndex][capturedIdx] then
                                            list[selectedIndex][capturedIdx].qta = amount
                                            Api.Interface.SaveNumber(
                                                desc.savePrefix .. selectedIndex .. "it" .. capturedIdx .. "Qta",
                                                amount)
                                            refreshUI()
                                        end
                                    end
                                end,
                                id = capturedIdx
                            }
                        elseif returnCode == "Delete" then
                            removeItem(desc, capturedIdx)
                        end
                    end)
                else
                    -- Confirmation dialog before removing
                    local idx = capturedIdx
                    Api.Dialog.Create {
                        windowName = "OrganizerRemoveItem",
                        title      = L"Remove Item",
                        body       = L"Remove this item from the agent list?",
                        buttons    = {
                            { textTid = 1011036, callback = function() removeItem(desc, idx) end },
                            { textTid = Api.Dialog.TID_CANCEL() }
                        }
                    }
                end
            end
        }

        -- Reparent BEFORE onInitialize to prevent resize-grip / snapping logic
        -- (Window:onInitialize checks isParentRoot(); must be false before that call)
        btn:create(false)
        btn:setParent(NAME)
        btn:onInitialize()
        btn:clearAnchors()

        if prevName then
            btn:addAnchor("topleft", prevName, "bottomleft", 0, ITEM_GAP)
        else
            btn:addAnchor("topleft", NAME, "topleft", MARGIN + 2, ITEM_Y)
        end

        btn:setShowing(true)
        return btn
    end

    --- Rebuilds the visible item list for the current selection.
    local function refreshItemList()
        clearItemList()

        local desc  = getTypeDesc(selectedType)
        local total = itemCount(desc, selectedIndex)
        local list  = Organizer[desc.listKey]

        if scrollOffset >= total then scrollOffset = 0 end

        local prevName = nil
        local shown    = 0
        for j = scrollOffset + 1, total do
            if shown >= MAX_VISIBLE then break end
            local item = list and list[selectedIndex] and list[selectedIndex][j]
            if item then
                local btn = makeItemRow(desc, item, j, prevName)
                table.insert(itemViews, btn)
                prevName = btn:getName()
                shown    = shown + 1
            end
        end

        if scrollUpBtn   then scrollUpBtn:setShowing(scrollOffset > 0)                         end
        if scrollDownBtn then scrollDownBtn:setShowing(total > scrollOffset + MAX_VISIBLE) end
    end

    --- Updates all static control states and refreshes the item list.
    refreshUI = function()
        local desc  = getTypeDesc(selectedType)
        local count = agentCount(desc)

        -- Clamp selection
        if selectedIndex < 1     then selectedIndex = 1     end
        if selectedIndex > count then selectedIndex = count end

        if agentLabel  then agentLabel:setText(agentDisplayName(desc, selectedIndex)) end
        if prevBtn     then prevBtn:setShowing(selectedIndex > 1)                     end
        if nextBtn     then nextBtn:setShowing(selectedIndex < count)                 end

        -- Default indicator
        local activeIdx = Organizer[desc.activeKey] or 1
        local isDefault = (activeIdx == selectedIndex)
        if setDefaultBtn then setDefaultBtn:setShowing(not isDefault) end
        if defaultLabel  then defaultLabel:setShowing(isDefault)      end

        -- Container button
        if containerBtn then
            local hasCont = desc.contKey ~= nil
            containerBtn:setShowing(hasCont)
            if hasCont then
                local cont   = Organizer[desc.contKey]
                local contId = (cont and cont[selectedIndex]) or 0
                if contId > 0 then
                    containerBtn:setText(L"Clear Container")
                else
                    containerBtn:setText(L"Set Container")
                end
            end
        end

        -- Auto-close checkbox (Organizer only)
        if autoCloseBtn then
            local show = (selectedType == 1 and desc.closeKey ~= nil)
            autoCloseBtn:setShowing(show)
            if show then
                local cc     = Organizer[desc.closeKey]
                local pressed = (cc and cc[selectedIndex]) or false
                autoCloseBtn:setChecked(pressed)
            end
        end

        -- Add buttons
        if addTypeBtn then addTypeBtn:setShowing(desc.hasType) end
        if addIdBtn   then addIdBtn:setShowing(desc.hasId)     end

        refreshItemList()
    end

    -- --------------------------------------------------------
    -- Targeting helpers
    -- --------------------------------------------------------

    local function unregisterTargetHandler()
        Api.Window.UnregisterEventHandler(
            NAME, Constants.SystemEvents.OnTargetSendIdClient.getEvent())
    end

    local targetingForType = false

    --- Adds an item to the current agent after targeting.
    ---@param objectId number
    ---@param qta number|nil
    local function addItemFromObject(objectId, qta)
        local itemData = Data.ObjectInfo(objectId)
        if not itemData then return end

        local desc  = getTypeDesc(selectedType)
        local items = Organizer[desc.itemsKey]
        local list  = Organizer[desc.listKey]
        if not items then return end

        if not items[selectedIndex] then items[selectedIndex] = 0 end
        items[selectedIndex] = items[selectedIndex] + 1
        local j = items[selectedIndex]

        if not list[selectedIndex] then list[selectedIndex] = {} end

        local itemName = WStringToString(stripFirstNumber(itemData.name))

        if targetingForType then
            if desc.hasQta then
                local item = { name=itemName, type=itemData.objectType, hue=itemData.hueId, qta=qta or 0 }
                list[selectedIndex][j] = item
                Api.Interface.SaveString(desc.savePrefix..selectedIndex.."it"..j.."Name", item.name)
                Api.Interface.SaveNumber(desc.savePrefix..selectedIndex.."it"..j.."Type", item.type)
                Api.Interface.SaveNumber(desc.savePrefix..selectedIndex.."it"..j.."Hue",  item.hue)
                Api.Interface.SaveNumber(desc.savePrefix..selectedIndex.."it"..j.."Qta",  item.qta)
            else
                local item = { name=itemName, type=itemData.objectType, hue=itemData.hueId, id=0 }
                list[selectedIndex][j] = item
                Api.Interface.SaveString(desc.savePrefix..selectedIndex.."it"..j.."Name", item.name)
                Api.Interface.SaveNumber(desc.savePrefix..selectedIndex.."it"..j.."Type", item.type)
                Api.Interface.SaveNumber(desc.savePrefix..selectedIndex.."it"..j.."Hue",  item.hue)
                Api.Interface.SaveNumber(desc.savePrefix..selectedIndex.."it"..j.."Id",   0)
            end
        else
            -- Add by ID
            local item = { name=itemName, type=0, hue=0, id=objectId }
            list[selectedIndex][j] = item
            Api.Interface.SaveString(desc.savePrefix..selectedIndex.."it"..j.."Name", item.name)
            Api.Interface.SaveNumber(desc.savePrefix..selectedIndex.."it"..j.."Type", 0)
            Api.Interface.SaveNumber(desc.savePrefix..selectedIndex.."it"..j.."Hue",  0)
            Api.Interface.SaveNumber(desc.savePrefix..selectedIndex.."it"..j.."Id",   objectId)
        end

        Api.Interface.SaveNumber("Organizer"..desc.countKey.."_Items"..selectedIndex, items[selectedIndex])
        refreshUI()
    end

    local function onAddTypeTargetReceived()
        unregisterTargetHandler()
        local objectId = Data.RequestInfoObjectId()
        if objectId == 0 then return end

        local desc = getTypeDesc(selectedType)
        if desc.hasQta then
            local capturedId = objectId
            Api.RenameWindow.Create {
                title        = L"Set Amount",
                subtitle     = L"Enter quantity:",
                callfunction = function(_, amountStr)
                    local amount = tonumber(amountStr)
                    if type(amount) ~= "number" then return end
                    targetingForType = true
                    addItemFromObject(capturedId, amount)
                end,
                id = objectId,
            }
        else
            targetingForType = true
            addItemFromObject(objectId, nil)
        end
    end

    local function onAddIdTargetReceived()
        unregisterTargetHandler()
        local objectId = Data.RequestInfoObjectId()
        if objectId == 0 then return end
        targetingForType = false
        addItemFromObject(objectId, nil)
    end

    local function onAddContainerTargetReceived()
        unregisterTargetHandler()
        local bag  = Data.RequestInfoObjectId()
        if bag == 0 then return end
        local desc = getTypeDesc(selectedType)
        if not desc.contKey then return end
        local cont = Organizer[desc.contKey]
        if not cont then return end
        cont[selectedIndex] = bag
        Api.Interface.SaveNumber("Organizer"..desc.contKey..selectedIndex, bag)
        refreshUI()
    end

    -- --------------------------------------------------------
    -- Static child factory helpers
    -- --------------------------------------------------------

    local function makeTypeTab(typeIndex)
        local label = StringToWString(AGENT_TYPES[typeIndex].key)
        return Components.Button {
            OnInitialize = function(self)
                self:setDimensions(TAB_W, ROW_H)
                self:setText(label)
            end,
            OnLButtonUp = function(self)
                selectedType  = typeIndex
                selectedIndex = 1
                scrollOffset  = 0
                refreshUI()
            end
        }
    end

    prevBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(PREV_W, ROW_H)
            self:setText(L"<")
        end,
        OnLButtonUp = function(self)
            if selectedIndex > 1 then
                selectedIndex = selectedIndex - 1
                scrollOffset  = 0
                refreshUI()
            end
        end
    }

    agentLabel = Components.Label {
        OnInitialize = function(self)
            self:setDimensions(LABEL_W, ROW_H)
        end
    }

    nextBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(NEXT_W, ROW_H)
            self:setText(L">")
        end,
        OnLButtonUp = function(self)
            local desc  = getTypeDesc(selectedType)
            local count = agentCount(desc)
            if selectedIndex < count then
                selectedIndex = selectedIndex + 1
                scrollOffset  = 0
                refreshUI()
            end
        end
    }

    local renameBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(RENAME_W, ROW_H)
            self:setText(L"Rename")
        end,
        OnLButtonUp = function(self)
            local desc = getTypeDesc(selectedType)
            Api.RenameWindow.Create {
                title        = L"Rename Agent",
                subtitle     = L"Enter new name:",
                callfunction = function(_, name)
                    if not name then return end
                    local d = Organizer[desc.descKey]
                    if d then d[selectedIndex] = name end
                    Api.Interface.SaveWString(
                        "Organizer"..desc.countKey.."_Desc"..selectedIndex, name)
                    refreshUI()
                end,
                id = selectedIndex,
            }
        end
    }

    local addAgentBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(ADDAGNT_W, ROW_H)
            self:setText(L"+")
        end,
        OnLButtonUp = function(self)
            Api.ContextMenu.CreateLuaItem(L"Organizer", 0, "MoreOrganizer", 2, false)
            Api.ContextMenu.CreateLuaItem(L"Undress",   0, "MoreUndress",   2, false)
            Api.ContextMenu.CreateLuaItem(L"Restock",   0, "MoreRestock",   2, false)
            Api.ContextMenu.CreateLuaItem(L"Buy",       0, "MoreBuy",       2, false)
            Api.ContextMenu.CreateLuaItem(L"Sell",      0, "MoreSell",      2, false)
            Api.ContextMenu.CreateLuaItem(L"Scavenger", 0, "MoreScavenger", 2, false)
            Api.ContextMenu.ActivateLuaMenu(function(returnCode, _)
                local typeMap = {
                    MoreOrganizer=1, MoreUndress=2, MoreRestock=3,
                    MoreBuy=4, MoreSell=5, MoreScavenger=6,
                }
                local ti = typeMap[returnCode]
                if not ti then return end
                local d = getTypeDesc(ti)

                Organizer[d.countKey] = Organizer[d.countKey] + 1
                local i = Organizer[d.countKey]

                local list  = Organizer[d.listKey]
                local items = Organizer[d.itemsKey]
                local descs = Organizer[d.descKey]

                if not list[i]  then list[i]  = {}    end
                items[i] = 0
                descs[i] = L""

                Api.Interface.SaveNumber("Organizer"..d.countKey.."_Items"..i, 0)
                Api.Interface.SaveWString("Organizer"..d.countKey.."_Desc"..i, L"")
                Api.Interface.SaveNumber("Organizer"..d.countKey, i)

                if d.contKey then
                    local cont = Organizer[d.contKey]
                    if not cont[i] then cont[i] = 0 end
                    Api.Interface.SaveNumber("Organizer"..d.contKey..i, 0)
                end
                if d.closeKey then
                    local cc = Organizer[d.closeKey]
                    if not cc[i] then cc[i] = false end
                    Api.Interface.SaveBoolean("Organizer"..d.closeKey..i, false)
                end

                selectedType  = ti
                selectedIndex = i
                scrollOffset  = 0
                refreshUI()
            end)
        end
    }

    local removeAgentBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(REMAGNT_W, ROW_H)
            self:setText(L"-")
        end,
        OnLButtonUp = function(self)
            local desc  = getTypeDesc(selectedType)
            if agentCount(desc) <= 1 then return end   -- never remove last

            local capturedType  = selectedType
            local capturedIndex = selectedIndex

            Api.Dialog.Create {
                windowName = "OrganizerRemoveAgent",
                title      = L"Remove Agent",
                body       = L"Remove this agent and all its items?",
                buttons    = {
                    { textTid = 1011036, callback = function()
                        local d     = getTypeDesc(capturedType)
                        local list  = Organizer[d.listKey]
                        local items = Organizer[d.itemsKey]
                        local descs = Organizer[d.descKey]

                        deleteAllAgentItems(d, Api)

                        table.remove(list,  capturedIndex)
                        table.remove(items, capturedIndex)
                        table.remove(descs, capturedIndex)

                        Organizer[d.countKey] = Organizer[d.countKey] - 1
                        if Organizer[d.countKey] <= 0 then
                            Organizer[d.countKey] = 1
                            list[1]  = {}
                            items[1] = 0
                            descs[1] = L""
                        end

                        Organizer[d.activeKey] = 1
                        Api.Interface.SaveNumber("Organizer"..d.activeKey, 1)

                        if d.contKey then
                            local cont = Organizer[d.contKey]
                            table.remove(cont, capturedIndex)
                            if #cont == 0 then cont[1] = 0 end
                        end
                        if d.closeKey then
                            local cc = Organizer[d.closeKey]
                            table.remove(cc, capturedIndex)
                            if #cc == 0 then cc[1] = false end
                        end

                        saveAllAgents(d, Api)

                        selectedIndex = 1
                        scrollOffset  = 0
                        refreshUI()
                    end },
                    { textTid = Api.Dialog.TID_CANCEL() }
                }
            }
        end
    }

    setDefaultBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(DEF_W, ROW_H)
            self:setText(L"Set Default")
        end,
        OnLButtonUp = function(self)
            local desc = getTypeDesc(selectedType)
            Organizer[desc.activeKey] = selectedIndex
            Api.Interface.SaveNumber("Organizer"..desc.activeKey, selectedIndex)
            refreshUI()
        end
    }

    defaultLabel = Components.Label {
        OnInitialize = function(self)
            self:setDimensions(DEF_W, ROW_H)
            self:setText(L"[Default]")
        end
    }

    containerBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(CONT_BTN_W, ROW_H)
            self:setText(L"Set Container")
        end,
        OnLButtonUp = function(self)
            local desc = getTypeDesc(selectedType)
            if not desc.contKey then return end
            local cont   = Organizer[desc.contKey]
            local contId = (cont and cont[selectedIndex]) or 0
            if contId > 0 then
                -- Clear
                cont[selectedIndex] = 0
                Api.Interface.SaveNumber("Organizer"..desc.contKey..selectedIndex, 0)
                refreshUI()
            else
                -- Request target
                Api.Target.RequestTargetInfo()
                Api.Window.SendOverheadText(L"Click a container to set as default.", 1152, true)
                -- Mongbat.EventHandler is the framework's global dispatch table.
                -- Assigning here creates a named callback the engine can call by string.
                -- The callback unregisters itself after one invocation.
                Mongbat.EventHandler.OrganizerAddContainer = onAddContainerTargetReceived
                Api.Window.RegisterEventHandler(
                    NAME,
                    Constants.SystemEvents.OnTargetSendIdClient.getEvent(),
                    "Mongbat.EventHandler.OrganizerAddContainer")
            end
        end
    }

    autoCloseBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(CLOSE_BTN_W, ROW_H)
            self:setText(L"Auto-close")
            self:setCheckButton(true)
        end,
        OnLButtonDown = function(self)
            local desc = getTypeDesc(selectedType)
            if not desc.closeKey then return end
            local cc      = Organizer[desc.closeKey]
            local pressed = self:isChecked()
            if cc then
                cc[selectedIndex] = pressed
                Api.Interface.SaveBoolean("Organizer"..desc.closeKey..selectedIndex, pressed)
            end
        end
    }

    addTypeBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(ADDTYPE_W, ROW_H)
            self:setText(L"Add by Type")
        end,
        OnLButtonUp = function(self)
            local desc = getTypeDesc(selectedType)
            if not desc.hasType then return end
            targetingForType = true
            Api.Target.RequestTargetInfo()
            Api.Window.SendOverheadText(L"Click an item to add it by type.", 1152, true)
            Mongbat.EventHandler.OrganizerAddType = onAddTypeTargetReceived
            Api.Window.RegisterEventHandler(
                NAME,
                Constants.SystemEvents.OnTargetSendIdClient.getEvent(),
                "Mongbat.EventHandler.OrganizerAddType")
        end
    }

    addIdBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(ADDID_W, ROW_H)
            self:setText(L"Add by ID")
        end,
        OnLButtonUp = function(self)
            local desc = getTypeDesc(selectedType)
            if not desc.hasId then return end
            targetingForType = false
            Api.Target.RequestTargetInfo()
            Api.Window.SendOverheadText(L"Click an item to add it by ID.", 1152, true)
            Mongbat.EventHandler.OrganizerAddId = onAddIdTargetReceived
            Api.Window.RegisterEventHandler(
                NAME,
                Constants.SystemEvents.OnTargetSendIdClient.getEvent(),
                "Mongbat.EventHandler.OrganizerAddId")
        end
    }

    scrollUpBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(SCROLL_U_W, ROW_H)
            self:setText(L"^")
            self:setShowing(false)
        end,
        OnLButtonUp = function(self)
            if scrollOffset > 0 then
                scrollOffset = scrollOffset - 1
                refreshItemList()
            end
        end
    }

    scrollDownBtn = Components.Button {
        OnInitialize = function(self)
            self:setDimensions(SCROLL_D_W, ROW_H)
            self:setText(L"v")
            self:setShowing(false)
        end,
        OnLButtonUp = function(self)
            local desc  = getTypeDesc(selectedType)
            local total = itemCount(desc, selectedIndex)
            if scrollOffset + MAX_VISIBLE < total then
                scrollOffset = scrollOffset + 1
                refreshItemList()
            end
        end
    }

    -- --------------------------------------------------------
    -- Window layout function
    -- --------------------------------------------------------
    -- Child index to screen position mapping:
    --  1-6  = type tabs (row 1)
    --  7    = prevBtn
    --  8    = agentLabel
    --  9    = nextBtn
    --  10   = renameBtn
    --  11   = addAgentBtn
    --  12   = removeAgentBtn
    --  13   = setDefaultBtn
    --  14   = defaultLabel   (same X/Y as setDefaultBtn, toggled by visibility)
    --  15   = containerBtn
    --  16   = autoCloseBtn
    --  17   = addTypeBtn
    --  18   = addIdBtn
    --  19   = scrollUpBtn
    --  20   = scrollDownBtn

    local function Layout(window, children, child, index)
        local n = window:getName()
        child:clearAnchors()

        -- Row 1: type tab buttons
        if index >= 1 and index <= 6 then
            child:addAnchor("topleft", n, "topleft", MARGIN + (index-1)*TAB_W, TAB_Y)
            return
        end

        -- Row 2: agent navigation and management
        local x2 = MARGIN
        if index == 7 then       -- prevBtn
            child:addAnchor("topleft", n, "topleft", x2, AGENT_Y)
        elseif index == 8 then   -- agentLabel
            child:addAnchor("topleft", n, "topleft", x2 + PREV_W + 2, AGENT_Y)
        elseif index == 9 then   -- nextBtn
            child:addAnchor("topleft", n, "topleft", x2 + PREV_W + 2 + LABEL_W + 2, AGENT_Y)
        elseif index == 10 then  -- renameBtn
            child:addAnchor("topleft", n, "topleft",
                x2 + PREV_W + 2 + LABEL_W + 2 + NEXT_W + 4, AGENT_Y)
        elseif index == 11 then  -- addAgentBtn
            child:addAnchor("topleft", n, "topleft",
                x2 + PREV_W + 2 + LABEL_W + 2 + NEXT_W + 4 + RENAME_W + 2, AGENT_Y)
        elseif index == 12 then  -- removeAgentBtn
            child:addAnchor("topleft", n, "topleft",
                x2 + PREV_W + 2 + LABEL_W + 2 + NEXT_W + 4 + RENAME_W + 2 + ADDAGNT_W + 2, AGENT_Y)
        elseif index == 13 or index == 14 then  -- setDefaultBtn / defaultLabel
            child:addAnchor("topleft", n, "topleft",
                x2 + PREV_W + 2 + LABEL_W + 2 + NEXT_W + 4 + RENAME_W + 2 + ADDAGNT_W + 2 + REMAGNT_W + 2, AGENT_Y)

        -- Row 3: container and auto-close controls
        elseif index == 15 then  -- containerBtn
            child:addAnchor("topleft", n, "topleft", MARGIN, CONT_Y)
        elseif index == 16 then  -- autoCloseBtn
            child:addAnchor("topleft", n, "topleft", MARGIN + CONT_BTN_W + 6, CONT_Y)

        -- Row 4: add-item buttons and scroll buttons
        elseif index == 17 then  -- addTypeBtn
            child:addAnchor("topleft", n, "topleft", MARGIN, ADD_Y)
        elseif index == 18 then  -- addIdBtn
            child:addAnchor("topleft", n, "topleft", MARGIN + ADDTYPE_W + 6, ADD_Y)
        elseif index == 19 then  -- scrollUpBtn
            child:addAnchor("topleft", n, "topleft",
                MARGIN + AVAIL_W - SCROLL_U_W - SCROLL_D_W - 4, ADD_Y)
        elseif index == 20 then  -- scrollDownBtn
            child:addAnchor("topleft", n, "topleft",
                MARGIN + AVAIL_W - SCROLL_D_W, ADD_Y)
        end
    end

    -- --------------------------------------------------------
    -- Build and create the window
    -- --------------------------------------------------------
    local window = Components.Window {
        Name      = NAME,
        Resizable = true,
        OnLayout  = Layout,
        OnInitialize = function(self)
            self:setDimensions(WIN_W, WIN_H)
            self:setChildren {
                makeTypeTab(1), makeTypeTab(2), makeTypeTab(3),
                makeTypeTab(4), makeTypeTab(5), makeTypeTab(6),
                prevBtn, agentLabel, nextBtn,
                renameBtn, addAgentBtn, removeAgentBtn,
                setDefaultBtn, defaultLabel,
                containerBtn, autoCloseBtn,
                addTypeBtn, addIdBtn,
                scrollUpBtn, scrollDownBtn,
            }
        end,
        OnRButtonUp = function(self)
            self:setShowing(false)
        end
    }

    window:create(false)
    -- The engine fires OnInitialize via Mongbat.xml, which calls window:onInitialize()
    -- and then calls refreshUI via the model's OnInitialize → setChildren → Layout flow.
    -- We call refreshUI explicitly here to set initial text/visibility on controls.
    refreshUI()
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.SavePosition(NAME, true)
    context.Api.Window.Destroy(NAME)

    -- Clean up any targeting event handlers we may have registered
    if Mongbat.EventHandler.OrganizerAddType      then
        Mongbat.EventHandler.OrganizerAddType = nil
    end
    if Mongbat.EventHandler.OrganizerAddId        then
        Mongbat.EventHandler.OrganizerAddId = nil
    end
    if Mongbat.EventHandler.OrganizerAddContainer then
        Mongbat.EventHandler.OrganizerAddContainer = nil
    end

    context.Components.Defaults.OrganizerWindow:restore()
end

Mongbat.Mod {
    Name         = "MongbatOrganizerWindow",
    Path         = "/src/mods/mongbat-organizer-window",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown,
}
