--- MongbatSpellbookMod.lua
--- Replaces the default Spellbook with a clean Mongbat-based implementation.
--- Supports all spell schools (Magery, Necromancy, Chivalry, Bushido, Ninjitsu,
--- Spellweaving, Mysticism) with tab navigation, spell icons, power words,
--- mouse-over tooltips, cast on click, and drag-to-hotbar support.
--- Multiple simultaneous spellbook instances are supported via DynamicWindowId.

-- ========================================================================== --
-- Constants
-- ========================================================================== --

--- Spells per tab for all supported schools.
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants
local Utils = Mongbat.Utils

local SPELLS_PER_TAB = {
    [1]   = 8, -- Magery
    [101] = 8, -- Necromancy
    [201] = 8, -- Chivalry
    [401] = 8, -- Bushido
    [501] = 8, -- Ninjitsu
    [601] = 8, -- Spellweaving
    [678] = 8, -- Mysticism
    [701] = 8, -- Bard Masteries
}

--- School names indexed by firstSpellNum, for the window title.
local SCHOOL_TIDS = {
    [1]   = 1044401, -- Magery
    [101] = 1044402, -- Necromancy
    [201] = 1044403, -- Chivalry
    [401] = 1044404, -- Bushido
    [501] = 1044405, -- Ninjitsu
    [601] = 1044406, -- Spellweaving
    [678] = 1044407, -- Mysticism
    [701] = 1044408, -- Bard Masteries
}

--- Maximum spells per tab.
local MAX_SPELLS_PER_TAB = 8

--- Grid layout constants.
local ICON_SIZE   = 44
local ICON_PAD    = 4
local COLS        = 4
local HEADER_H    = 24
local TAB_H       = 22
local MARGIN      = 8
local SPELL_ROW_H = ICON_SIZE + ICON_PAD

--- Prefix used to build per-instance window names.
local WIN_PREFIX = "MongbatSpellbook_"

-- ========================================================================== --
-- Helpers
-- ========================================================================== --

--- Returns the school-specific skill index for success-chance calculation.
---@param firstSpellNum integer
---@return integer skillIndex 0-based index into WindowData.SkillsCSV, 0 = no skill
local function getSchoolSkillIndex(firstSpellNum)
    if firstSpellNum == 1   then return 32 end -- Magery
    if firstSpellNum == 101 then return 38 end -- Necromancy
    if firstSpellNum == 201 then return 13 end -- Chivalry
    if firstSpellNum == 401 then return 9  end -- Bushido
    if firstSpellNum == 501 then return 39 end -- Ninjitsu
    if firstSpellNum == 601 then return 46 end -- Spellweaving
    if firstSpellNum == 678 then return 37 end -- Mysticism
    return 0
end

-- ========================================================================== --
-- Per-book instance state
-- ========================================================================== --

--- Holds per-instance state created in OpenBook and read in tab callbacks.
--- Key = bookId (DynamicWindowId), value = instance state table.
local books = {}

--- Holds the saved original Spellbook function references for restoration on shutdown.
local savedSpellbookFunctions = nil

-- ========================================================================== --
-- Build tooltip body for a spell
-- ========================================================================== --

---@param Api table
---@param Data table
---@param Constants table
---@param bookId integer
---@param abilityId integer
---@return wstring tooltipBody
local function buildTooltip(Api, Data, Constants, bookId, abilityId)
    local bookData = books[bookId]
    if bookData == nil then return L"" end
    local firstSpellNum = bookData.firstSpellNum

    local icon, serverId, tid, desctid, reagents, powerword, tithingcost, minskill, manacost =
        Api.Ability.GetAbilityData(abilityId)

    if icon == nil or tid == nil or tid == 0 then return L"" end

    local reagentsStr = L""
    local tithingStr  = L""
    local minskillStr = L""
    local manacostStr = L""

    if reagents ~= nil and reagents ~= "" then
        reagentsStr = L"<BR>== " .. Api.String.GetStringFromTid(1002127) .. L" ==<BR>" ..
            Api.String.StringToWString(reagents)
    end

    if tithingcost ~= nil and tithingcost > 0 then
        -- Chivalry: Tithing Cost  |  Bard: Upkeep Cost
        if serverId ~= nil and ((serverId >= 201 and serverId <= 210) or
                (serverId == 719) or (serverId == 720)) then
            tithingStr = L"<BR>" .. Api.String.GetStringFromTid(1062099) ..
                Api.String.StringToWString(tostring(tithingcost))
        else
            tithingStr = L"<BR>" .. Api.String.GetStringFromTid(1115718) ..
                Api.String.StringToWString(tostring(tithingcost))
        end
    end

    if minskill ~= nil then
        minskillStr = L"<BR>" .. Api.String.GetStringFromTid(1062101) .. L" " ..
            Api.String.StringToWString(tostring(minskill))

        local skillIdx = getSchoolSkillIndex(firstSpellNum)
        if skillIdx > 0 and abilityId < 701 then
            local skillDef   = Data.SkillsCSV(skillIdx)
            local skillDyn   = Data.SkillDynamicData(skillDef.ServerId)
            local skillLevel = skillDyn.TempSkillValue / 10
            local playerData = Data.PlayerStatus():getData()

            if playerData.Race == 1 and skillLevel < 20 then
                skillLevel = 20
            end

            local variation = Api.SpellsInfo.GetVariation(abilityId)
            local success
            if skillLevel < minskill then
                success = 0
            elseif skillLevel > minskill + variation then
                success = 100
            else
                success = ((skillLevel - minskill) * 100) / variation
            end
            success = string.format("%1.1f", success)
            minskillStr = minskillStr ..
                L"<BR><BR>" .. L"Success Chance: " ..
                Api.String.StringToWString(tostring(success)) .. L"%"
        end
    end

    if manacost ~= nil then
        local playerData = Data.PlayerStatus():getData()
        local lmcMana = math.floor(manacost -
            (manacost * (tonumber(playerData.LowerManaCost) / 100)))
        manacostStr = L"<BR>" .. Api.String.GetStringFromTid(1062100) .. L" " ..
            Api.String.StringToWString(tostring(lmcMana)) ..
            L" (" .. Api.String.StringToWString(tostring(manacost)) .. L")"
    end

    return reagentsStr .. tithingStr .. minskillStr .. manacostStr
end

-- ========================================================================== --
-- Spell slot component
-- ========================================================================== --

---@param bookId integer
---@param slotIndex integer 1-based index within current tab (1..8)
---@return DynamicImage
local function SpellSlot(bookId, slotIndex)
    local Api        = Api
    local Data       = Data
    local Constants  = Constants
    local Components = Components
    local winName = WIN_PREFIX .. bookId .. "Slot" .. slotIndex

    return Components.DynamicImage {
        Name = winName,
        OnInitialize = function(self)
            self:setDimensions(ICON_SIZE, ICON_SIZE)
        end,
        OnLButtonDown = function(self, flags)
            local bookData = books[bookId]
            if bookData == nil then return end
            local abilityId = bookData:getAbilityId(slotIndex)
            if abilityId == 0 then return end

            local icon, serverId = Api.Ability.GetAbilityData(abilityId)
            if serverId == nil then return end

            if flags == Constants.ButtonFlags.Control then
                -- Ctrl+click: create single-spell hotbar block
                local blockBar = Api.Hotbar.GetNextHotbarId()
                Api.Interface.SaveBoolean("Hotbar" .. blockBar .. "_IsBlockbar", true)
                Api.Hotbar.SpawnNew()
                Api.Hotbar.SetAction(
                    Constants.UserAction.Spell(), abilityId, icon, blockBar, 1)
            else
                -- Normal drag
                Api.Drag.SetActionMouseClickData(
                    Constants.UserAction.Spell(), serverId, icon)
            end
        end,
        OnLButtonUp = function(self, flags)
            local bookData = books[bookId]
            if bookData == nil then return end
            local abilityId = bookData:getAbilityId(slotIndex)
            if abilityId == 0 then return end

            local icon, serverId = Api.Ability.GetAbilityData(abilityId)
            if serverId == nil then return end
            Api.Ability.CastSpell(serverId)
        end,
        OnRButtonUp = function(self)
            local bookData = books[bookId]
            if bookData == nil then return end
            local abilityId = bookData:getAbilityId(slotIndex)
            if abilityId == 0 then return end
            Api.ContextMenu.RequestMenu(abilityId)
        end,
        OnMouseOver = function(self)
            local bookData = books[bookId]
            if bookData == nil then return end
            local abilityId = bookData:getAbilityId(slotIndex)
            if abilityId == 0 then return end

            local icon, serverId, tid = Api.Ability.GetAbilityData(abilityId)
            if tid == nil or tid == 0 then return end

            local winName2 = WIN_PREFIX .. bookId
            local body = buildTooltip(Api, Data, Constants, bookId, abilityId)
            local itemData = {
                windowName = winName2,
                itemId     = abilityId,
                itemType   = Constants.ItemPropertyType.Action,
                actionType = Constants.UserAction.Spell(),
                detail     = Constants.ItemPropertyDetail.Long,
                title      = L"",
                body       = body,
            }
            Api.ItemProperties.SetActiveItem(itemData)
        end,
        OnMouseOverEnd = function(self)
            Api.ItemProperties.ClearMouseOverItem()
        end,
    }
end

-- ========================================================================== --
-- Open a spellbook instance
-- ========================================================================== --

---@param bookId integer DynamicWindowId assigned by the engine
local function OpenBook(bookId)
    local Api       = Api
    local Data      = Data
    local Utils     = Utils
    local Constants = Constants
    local Components = Components

    -- Collect spell slots and tab-button views for this instance.
    local slotViews = {}
    local tabViews  = {}
    local tithLabel = nil
    local activeTab = 1

    -- Per-instance state object placed in the books registry.
    -- Provides helpers so event callbacks can resolve ability IDs.
    local bookState = {
        firstSpellNum = 0, -- filled when first update arrives
        activeTab     = 1,
        numTabs       = 0,
        --- Returns the ability ID for a given 1-based slot on the current tab,
        --- or 0 if no spell lives there.
        ---@param slotIndex integer
        ---@return integer
        getAbilityId = function(self, slotIndex)
            if self.firstSpellNum == 0 then return 0 end
            local spellsPerTab = SPELLS_PER_TAB[self.firstSpellNum] or MAX_SPELLS_PER_TAB
            local pageOffset   = (self.activeTab - 1) * spellsPerTab
            return self.firstSpellNum + pageOffset + slotIndex - 1
        end
    }
    books[bookId] = bookState

    -- ------------------------------------------------------------------ --
    -- ShowTab: populate slot icons/labels for the given tab number.
    -- ------------------------------------------------------------------ --
    local function ShowTab(tabNum)
        bookState.activeTab = tabNum
        activeTab = tabNum

        local firstSpellNum = bookState.firstSpellNum
        local spellsPerTab  = SPELLS_PER_TAB[firstSpellNum] or MAX_SPELLS_PER_TAB
        local pageOffset    = (tabNum - 1) * spellsPerTab
        local bookData      = Data.Spellbook(bookId)

        -- Highlight the selected tab.
        Utils.Array.ForEach(tabViews, function(view, i)
            view:setColor(i == tabNum
                and { r = 220, g = 200, b = 140, a = 255 }
                or  { r = 90,  g = 80,  b = 60,  a = 255 })
        end)

        -- Show tithing points for Chivalry.
        if tithLabel then
            if firstSpellNum == 201 then
                local status = Data.PlayerStatus():getData()
                local tithPoints = status and (status.TithingPoints or 0) or 0
                Api.Label.SetText(
                    tithLabel:getName(),
                    Api.String.GetStringFromTid(1062099) .. L" " ..
                    Api.String.StringToWString(tostring(tithPoints)))
                tithLabel:setShowing(true)
            else
                tithLabel:setShowing(false)
            end
        end

        Utils.Array.ForEach(slotViews, function(slot, i)
            local abilityId = firstSpellNum + pageOffset + i - 1
            -- Only icon is needed here for texture lookup; serverId/tid used elsewhere.
            local icon = Api.Ability.GetAbilityData(abilityId)

            if icon ~= nil and icon ~= 0 and i <= spellsPerTab then
                local texture, tx, ty = Api.Icon.GetIconData(icon)
                Api.DynamicImage.SetTexture(slot:getName(), texture, tx, ty)
                local known = bookData:isSpellKnown(pageOffset + i)
                slot:setAlpha(known and 1.0 or 0.4)
                slot:setShowing(true)
            else
                slot:setShowing(false)
            end
        end)
    end

    -- ------------------------------------------------------------------ --
    -- Layout: arrange children in the window.
    -- ------------------------------------------------------------------ --
    -- Children are in a fixed order:
    --   idx 1: title label         (row 1: y = MARGIN)
    --   idx 2: tithing label       (row 2: y = MARGIN + HEADER_H; hidden when not Chivalry)
    --   idx 3..10: tab buttons     (row 3: y = MARGIN + 2*HEADER_H)
    --   idx 11..18: spell slots    (4-column grid below tab row)
    local TAB_BASE  = 3
    local SLOT_BASE = 3 + MAX_SPELLS_PER_TAB  -- = 11

    local function BookLayout(window, children, child, idx)
        local winName2  = WIN_PREFIX .. bookId
        local tabRowY   = MARGIN + 2 * HEADER_H
        local slotRowY  = tabRowY + TAB_H + ICON_PAD

        -- Title label
        if idx == 1 then
            child:clearAnchors()
            child:addAnchor("topleft", winName2, "topleft", MARGIN, MARGIN)
            return
        end
        -- Tithing label (second header row; hidden for non-Chivalry books)
        if idx == 2 then
            child:clearAnchors()
            child:addAnchor("topleft", winName2, "topleft", MARGIN, MARGIN + HEADER_H)
            return
        end
        -- Tab buttons (fixed horizontal row)
        if idx >= TAB_BASE and idx < SLOT_BASE then
            local tabIdx = idx - TAB_BASE + 1
            child:clearAnchors()
            child:addAnchor("topleft", winName2, "topleft",
                MARGIN + (tabIdx - 1) * (TAB_H + 2),
                tabRowY)
            return
        end
        -- Spell slots (4-column grid below tab row)
        local slotIdx = idx - SLOT_BASE + 1
        if slotIdx >= 1 and slotIdx <= MAX_SPELLS_PER_TAB then
            local col = (slotIdx - 1) % COLS
            local row = math.floor((slotIdx - 1) / COLS)
            local x   = MARGIN + col * (ICON_SIZE + ICON_PAD)
            local y   = slotRowY + row * SPELL_ROW_H
            child:clearAnchors()
            child:addAnchor("topleft", winName2, "topleft", x, y)
        end
    end

    -- Compute window dimensions.
    -- Two header rows (title + tithing placeholder) + tab row + spell grid.
    local function bookWindowDimensions()
        local rows = math.ceil(MAX_SPELLS_PER_TAB / COLS)
        local w = MARGIN * 2 + COLS * ICON_SIZE + (COLS - 1) * ICON_PAD
        local h = MARGIN * 2 + 2 * HEADER_H + TAB_H + ICON_PAD + rows * SPELL_ROW_H
        return w, h
    end

    -- ------------------------------------------------------------------ --
    -- Build the window with MAX_SPELLS_PER_TAB slots.
    -- ------------------------------------------------------------------ --
    local children = {}

    -- Title label (child 1)
    local titleLabel = Components.Label {
        Name = WIN_PREFIX .. bookId .. "Title",
        OnInitialize = function(self)
            self:setDimensions(200, HEADER_H)
        end
    }
    table.insert(children, titleLabel)

    -- Tithing label (child 2)
    tithLabel = Components.Label {
        Name = WIN_PREFIX .. bookId .. "Tith",
        OnInitialize = function(self)
            self:setDimensions(200, HEADER_H)
        end
    }
    table.insert(children, tithLabel)

    -- Tab buttons (child 3..N) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ we create MAX_SPELLS_PER_TAB placeholders;
    -- some will be hidden if the book has fewer tabs.
    for i = 1, MAX_SPELLS_PER_TAB do
        local tabLabel = Components.Button {
            Name = WIN_PREFIX .. bookId .. "Tab" .. i,
            OnInitialize = function(self)
                self:setDimensions(TAB_H, TAB_H)
            end,
            OnLButtonUp = function(self)
                ShowTab(i)
            end,
        }
        tabViews[i] = tabLabel
        table.insert(children, tabLabel)
    end

    -- Spell slots (child N+1 onwards)
    for i = 1, MAX_SPELLS_PER_TAB do
        local slot = SpellSlot(bookId, i)
        slotViews[i] = slot
        table.insert(children, slot)
    end

    -- ------------------------------------------------------------------ --
    -- Create the top-level window.
    -- ------------------------------------------------------------------ --
    Components.Window {
        Name        = WIN_PREFIX .. bookId,
        Id          = bookId,
        OnLayout    = BookLayout,
        OnInitialize = function(self)
            local w, h = bookWindowDimensions()
            self:setDimensions(w, h)
            self:setMovable(true)
            self:setChildren(children)
        end,
        OnShutdown = function(self)
            -- Clean up hotbar spell icon registrations.
            Utils.Array.ForEach(slotViews, function(slot, i)
                Api.Hotbar.UnregisterSpellIcon(WIN_PREFIX .. bookId .. "Slot" .. i)
            end)
            books[bookId] = nil
        end,
        OnUpdateSpellbook = function(self, spellbook)
            local first = spellbook:getFirstSpellNum()
            if first == 0 then return end

            -- First update: compute tabs and title.
            if bookState.firstSpellNum ~= first then
                bookState.firstSpellNum = first

                -- Count tabs.
                local spellsPerTab = SPELLS_PER_TAB[first] or MAX_SPELLS_PER_TAB
                local numTabs = 0
                for i = first, first + 100, spellsPerTab do
                    local ic, sv, td = Api.Ability.GetAbilityData(i)
                    if td ~= nil and td > 0 then
                        numTabs = numTabs + 1
                    else
                        break
                    end
                end
                bookState.numTabs = numTabs

                -- Set title.
                local schoolTid = SCHOOL_TIDS[first]
                if schoolTid then
                    Api.Label.SetText(titleLabel:getName(),
                        Api.String.GetStringFromTid(schoolTid))
                end

                -- Show/hide tab buttons and set tab labels.
                local ordinals = { L"st", L"nd", L"rd" }
                Utils.Array.ForEach(tabViews, function(view, i)
                    if i <= numTabs then
                        if first == 1 then
                            -- Magery uses ordinal labels (1st, 2nd, ... circle)
                            local suffix = ordinals[i] or L"th"
                            view:setText(towstring(i) .. suffix)
                        else
                            view:setText(towstring(i))
                        end
                        view:setShowing(true)
                    else
                        view:setShowing(false)
                    end
                end)

                -- Register spell icons for hotbar drag.
                for i = first, first + spellsPerTab - 1 do
                    local ic, sv, td = Api.Ability.GetAbilityData(i)
                    if sv ~= nil then
                        local slotIdx = i - first + 1
                        Api.Hotbar.RegisterSpellIcon(
                            WIN_PREFIX .. bookId .. "Slot" .. slotIdx, sv)
                    end
                end
            end

            ShowTab(activeTab)
        end,
        OnUpdatePlayerStatus = function(self, status)
            -- Refresh tithing points display for Chivalry.
            if bookState.firstSpellNum == 201 and tithLabel then
                local playerData = status:getData()
                local tithPoints = playerData and (playerData.TithingPoints or 0) or 0
                Api.Label.SetText(
                    tithLabel:getName(),
                    Api.String.GetStringFromTid(1062099) .. L" " ..
                    Api.String.StringToWString(tostring(tithPoints)))
                tithLabel:setShowing(true)
            end
        end,
    }:create(true)
end

-- ========================================================================== --
-- Mod registration
-- ========================================================================== --

Mongbat.Mod {
    Name = "MongbatSpellbook",
    Path = "/src/mods/mongbat-spellbook",
    OnInitialize = function()
        local Api        = Api
        local Data       = Data
        local Components = Components

        -- Intercept the default Spellbook global by overriding its lifecycle
        -- functions. We do NOT call disable() because that would no-op our
        -- overrides when they are read back through the proxy.
        local originalSpellbook = Components.Defaults.Spellbook:getDefault()

        -- Save the original function references so we can restore them on shutdown.
        local savedFunctions = {
            Initialize         = originalSpellbook.Initialize,
            Shutdown           = originalSpellbook.Shutdown,
            ShutdownSpellIcon  = originalSpellbook.ShutdownSpellIcon,
            UpdateSpells       = originalSpellbook.UpdateSpells,
            ShowTab            = originalSpellbook.ShowTab,
            ToggleTab          = originalSpellbook.ToggleTab,
            UpdateTithing      = originalSpellbook.UpdateTithing,
            SpellLButtonDown   = originalSpellbook.SpellLButtonDown,
            SpellLButtonUp     = originalSpellbook.SpellLButtonUp,
            SpellMouseOver     = originalSpellbook.SpellMouseOver,
            RegisterSpellIcon  = originalSpellbook.RegisterSpellIcon,
        }

        -- Override Initialize so the engine's call opens our window instead.
        originalSpellbook.Initialize = function()
            local bookId = Data.DynamicWindowId()
            -- Destroy the default XML window the engine just created so it does
            -- not linger as a hidden resource.
            Api.Window.Destroy(Data.ActiveWindowName())
            -- Open our Mongbat window.
            OpenBook(bookId)
        end

        -- Override Shutdown so our window is destroyed cleanly.
        originalSpellbook.Shutdown = function()
            local bookId = Api.Window.GetId(Data.ActiveWindowName())
            Api.Window.Destroy(WIN_PREFIX .. bookId)
        end

        -- Override ShutdownSpellIcon (called per spell icon on close).
        originalSpellbook.ShutdownSpellIcon = function()
            -- No-op: our shutdown is handled in the window's OnShutdown.
        end

        -- Override data-update and interaction functions to prevent the default
        -- UI from trying to update windows that no longer exist.
        originalSpellbook.UpdateSpells       = function() end
        originalSpellbook.ShowTab            = function() end
        originalSpellbook.ToggleTab          = function() end
        originalSpellbook.UpdateTithing      = function() end
        originalSpellbook.SpellLButtonDown   = function() end
        originalSpellbook.SpellLButtonUp     = function() end
        originalSpellbook.SpellMouseOver     = function() end
        originalSpellbook.RegisterSpellIcon  = function() end

        -- Store savedFunctions in mod-level variable for restoration.
        savedSpellbookFunctions = savedFunctions
    end,
    OnShutdown = function()
        local Api        = Api
        local Utils      = Utils
        local Components = Components

        -- Destroy any open spellbook windows.
        Utils.Table.ForEach(books, function(bookId, _)
            Api.Window.Destroy(WIN_PREFIX .. bookId)
        end)
        books = {}

        -- Restore the original Spellbook functions.
        if savedSpellbookFunctions ~= nil then
            local originalSpellbook = Components.Defaults.Spellbook:getDefault()
            Utils.Table.ForEach(savedSpellbookFunctions, function(k, v)
                originalSpellbook[k] = v
            end)
            savedSpellbookFunctions = nil
        end
    end
}
