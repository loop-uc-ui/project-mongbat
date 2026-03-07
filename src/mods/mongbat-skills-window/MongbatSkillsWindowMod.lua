local NAME = "MongbatSkillsWindow"
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants
local Utils = Mongbat.Utils

-- Layout constants
local MARGIN = 10
local HEADER_H = 86
local ROW_H = 26
local VISIBLE_ROWS = 15
local WIN_W = 320
local WIN_H = HEADER_H + VISIBLE_ROWS * ROW_H + MARGIN + 16

-- Total number of CSV skill entries (1-indexed, 1..58) and server ID range (0..57)
local NUM_CSV_SKILLS = 58
local MAX_SERVER_ID = 57

-- Lock state display symbols: 0=increasing (â–²), 1=decreasing (â–¼), 2=locked (â– )
local LOCK_SYMBOLS = {}
LOCK_SYMBOLS[0] = L"\x25B2"
LOCK_SYMBOLS[1] = L"\x25BC"
LOCK_SYMBOLS[2] = L"\x25A0"

local MAX_LOCK_STATE = 2

local INFO_NAME = "MongbatSkillsInfo"

-- Saved reference to the original Actions.ToggleSkillsWindow for restoration on shutdown
local originalToggleSkillsWindow = nil

local function OnInitialize()
    local Api = Api
    local Data = Data
    local Utils = Utils
    local Constants = Constants
    local Components = Components

    -- Suppress the default SkillsWindow
    local skillsDefault = Components.Defaults.SkillsWindow
    skillsDefault:disable()

    -- Destroy the already-existing default window (created by Interface.lua at startup)
    Api.Window.Destroy("SkillsWindow")

    -- Load skill CSV data so WindowData.SkillsCSV is populated
    Api.Skill.LoadCSV()

    -- Override the toggle action so the hotkey shows/hides our window instead
    originalToggleSkillsWindow = Api.Actions.GetToggleSkillsWindow()
    Api.Actions.SetToggleSkillsWindow(function()
        Api.Window.ToggleWindow(NAME)
    end)

    -- Scrollable virtual list state
    local scrollOffset = 0

    -- rowServerIds[i] = serverId currently displayed in visible row slot i
    local rowServerIds = {}
    for i = 1, VISIBLE_ROWS do
        rowServerIds[i] = -1
    end

    -- rowCsvIds[i] = csvId currently displayed in visible row slot i
    local rowCsvIds = {}
    for i = 1, VISIBLE_ROWS do
        rowCsvIds[i] = -1
    end

    -- References to visible row Button views
    local rowButtons = {}

    -- Reference to the total points label
    local totalPointsLabel = nil

    -- Ordered list of csvIds (1..NUM_CSV_SKILLS), modified by sorting
    local sortedSkills = {}
    for i = 1, NUM_CSV_SKILLS do
        sortedSkills[i] = i
    end

    -- Current filter text (lowercase plain string for matching)
    local filterText = ""
    -- Ordered subset of sortedSkills that pass the current filter
    local filteredSkills = {}

    -- Pre-cached lowercase skill names keyed by csvId (1..NUM_CSV_SKILLS)
    -- Built once at init to avoid repeated TID lookups on every keystroke
    local skillNamesLower = {}
    Utils.Table.ForEach(Data.SkillsCSV(), function(csvId, entry)
        skillNamesLower[csvId] = string.lower(Api.String.WStringToString(
            Api.String.GetStringFromTid(entry.NameTid)))
    end)

    -- Rebuild filteredSkills from sortedSkills using current filterText.
    -- Side effect: resets scrollOffset to 0 so the list always starts from the top.
    local function rebuildFilteredList()
        filteredSkills = {}
        Utils.Array.ForEach(sortedSkills, function(csvId)
            if filterText == "" or string.find(skillNamesLower[csvId] or "", filterText, 1, true) then
                filteredSkills[#filteredSkills + 1] = csvId
            end
        end)
        scrollOffset = 0
    end

    -- Sort helpers
    local function sortByName()
        local csv = Data.SkillsCSV()
        if csv == nil then return end
        -- Cache names to avoid repeated TID lookups in the comparator
        local names = {}
        Utils.Array.ForEach(sortedSkills, function(csvId)
            names[csvId] = Api.String.WStringToString(Api.String.GetStringFromTid(csv[csvId].NameTid))
        end)
        table.sort(sortedSkills, function(a, b)
            return names[a] < names[b]
        end)
        rebuildFilteredList()
    end

    local function sortByValue()
        local csv = Data.SkillsCSV()
        if csv == nil then return end
        -- Cache values to avoid repeated wrapper allocations in the comparator
        local values = {}
        Utils.Array.ForEach(sortedSkills, function(csvId)
            values[csvId] = Data.SkillDynamicData(csv[csvId].ServerId):getValue()
        end)
        table.sort(sortedSkills, function(a, b)
            return values[a] > values[b]
        end)
        rebuildFilteredList()
    end

    -- Apply default sort (alphabetical by name)
    sortByName()

    -- Format a raw skill integer (value Ã— 10) as "NN.N"
    local function formatValue(raw)
        if raw == nil or raw == 0 then return L"0.0" end
        local whole = math.floor(raw / 10)
        local decimal = raw - whole * 10
        return towstring(whole) .. L"." .. towstring(decimal)
    end

    -- Build the display text for a row given its csvId
    local function getRowText(csvId)
        local csv = Data.SkillsCSV()
        if csv == nil or csv[csvId] == nil then return L"" end
        local entry = csv[csvId]
        local serverId = entry.ServerId
        local name = Api.String.GetStringFromTid(entry.NameTid)
        local skillData = Data.SkillDynamicData(serverId)
        local lockSym = LOCK_SYMBOLS[0]
        local valStr = L"0.0"
        local capStr = L"0.0"
        local rawData = skillData:getData()
        if rawData ~= nil then
            local state = rawData.SkillState or 0
            lockSym = LOCK_SYMBOLS[state] or LOCK_SYMBOLS[0]
            valStr = formatValue(skillData:getValue())
            capStr = formatValue(skillData:getCap())
        end
        return lockSym .. L" " .. name .. L"  " .. valStr .. L"/" .. capStr
    end

    -- Update a single visible row slot's content
    local function updateRow(rowIndex)
        local slotIndex = rowIndex + scrollOffset
        local csvId = filteredSkills[slotIndex]
        local btn = rowButtons[rowIndex]
        if btn == nil then return end
        if csvId == nil then
            rowServerIds[rowIndex] = -1
            rowCsvIds[rowIndex] = -1
            btn:setShowing(false)
        else
            local csv = Data.SkillsCSV()
            local serverId = csv and csv[csvId] and csv[csvId].ServerId or -1
            rowServerIds[rowIndex] = serverId
            rowCsvIds[rowIndex] = csvId
            btn:setText(getRowText(csvId))
            btn:setShowing(true)
        end
    end

    -- Update all visible rows
    local function updateAllRows()
        Utils.Array.ForEach(rowButtons, function(_, rowIndex)
            updateRow(rowIndex)
        end)
    end

    -- Update the total skill points label
    local function updateTotalPoints()
        if totalPointsLabel == nil then return end
        local total = 0
        for i = 0, MAX_SERVER_ID do
            total = total + Data.SkillDynamicData(i):getValue()
        end
        local points = math.floor(total / 10)
        totalPointsLabel:setText(L"Total: " .. towstring(points) .. L" / 720")
    end

    -- Show a skill detail popup for a skill identified by its csvId.
    -- Destroys any existing popup before creating the new one (lazy creation).
    local function showSkillInfo(csvId)
        Api.Window.Destroy(INFO_NAME)
        local csv = Data.SkillsCSV()
        if csv == nil or csv[csvId] == nil then return end
        local entry = csv[csvId]
        local skillData = Data.SkillDynamicData(entry.ServerId)
        local lockState = skillData:getLockState()
        local lockSym = LOCK_SYMBOLS[lockState] or LOCK_SYMBOLS[0]
        local infoChildren = {
            Components.Label {
                OnInitialize = function(self)
                    self:setDimensions(180, 20)
                    self:setText(Api.String.GetStringFromTid(entry.NameTid))
                end
            },
            Components.Label {
                OnInitialize = function(self)
                    self:setDimensions(180, 20)
                    local realVal = skillData:getValue()
                    local modVal = skillData:getModifiedValue()
                    local text = L"Value: " .. formatValue(realVal)
                    if modVal ~= realVal then
                        text = text .. L" (" .. formatValue(modVal) .. L")"
                    end
                    self:setText(text)
                end
            },
            Components.Label {
                OnInitialize = function(self)
                    self:setDimensions(180, 20)
                    self:setText(L"Cap: " .. formatValue(skillData:getCap()))
                end
            },
            Components.Label {
                OnInitialize = function(self)
                    self:setDimensions(180, 20)
                    self:setText(L"Lock: " .. lockSym)
                end
            },
        }
        Components.Window {
            Name = INFO_NAME,
            Resizable = false,
            OnInitialize = function(self)
                self:setDimensions(200, 110)
                self:setChildren(infoChildren)
            end,
            OnLayout = function(window, _, child, index)
                local winName = window:getName()
                child:clearAnchors()
                child:addAnchor("topleft", winName, "topleft", 10, 10 + (index - 1) * 24)
            end,
            OnRButtonUp = function()
                Api.Window.Destroy(INFO_NAME)
            end
        }:create(true)
    end

    -- Find which visible row is displaying a given serverId, or nil if not visible.
    -- Utils.Table.ForEach has no early-exit mechanism; we accumulate the first match
    -- and guard with `found == nil`. With VISIBLE_ROWS = 15 the full iteration is negligible.
    local function findRowForServerId(serverId)
        local found = nil
        Utils.Table.ForEach(rowServerIds, function(rowIndex, id)
            if id == serverId and found == nil then
                found = rowIndex
            end
        end)
        return found
    end

    -- Scroll handler shared by all components
    local function onScroll(delta)
        local maxScroll = math.max(0, #filteredSkills - VISIBLE_ROWS)
        if delta > 0 then
            scrollOffset = math.max(0, scrollOffset - 1)
        else
            scrollOffset = math.min(maxScroll, scrollOffset + 1)
        end
        updateAllRows()
    end

    -- Create a visible row Button for slot rowIndex
    local function SkillRowButton(rowIndex)
        return Components.Button {
            Template = "MongbatButton18",
            Resizable = false,
            Snappable = false,
            OnInitialize = function(self)
                self:setDimensions(WIN_W - MARGIN * 2 - 16, ROW_H)
            end,
            OnLButtonUp = function(self)
                -- Cycle lock state for the skill shown in this row
                local serverId = rowServerIds[rowIndex]
                if serverId == nil or serverId < 0 then return end
                local skillData = Data.SkillDynamicData(serverId)
                local rawData = skillData:getData()
                if rawData == nil then return end
                local newState = ((rawData.SkillState or 0) + 1)
                if newState > MAX_LOCK_STATE then newState = 0 end
                -- Optimistically update local data before server confirmation
                rawData.SkillState = newState
                -- Notify the server of the state change
                Api.Skill.SetLockState(serverId, newState)
                updateRow(rowIndex)
            end,
            OnLButtonDblClk = function(self)
                -- Activate the skill shown in this row
                local serverId = rowServerIds[rowIndex]
                if serverId == nil or serverId < 0 then return end
                Api.Skill.UseSkill(serverId)
            end,
            OnRButtonUp = function(self)
                -- Show skill info popup for the skill in this row
                local csvId = rowCsvIds[rowIndex]
                if csvId == nil or csvId < 0 then return end
                showSkillInfo(csvId)
            end,
            OnMouseWheel = function(self, x, y, delta)
                onScroll(delta)
            end
        }
    end

    -- Build the fixed children list
    local children = {}

    -- Title label
    local titleLabel = Components.Label {
        OnInitialize = function(self)
            self:setDimensions(120, 20)
            self:setText(L"Skills")
        end,
        OnMouseWheel = function(self, x, y, delta)
            onScroll(delta)
        end
    }
    children[1] = titleLabel

    -- Total skill points label
    totalPointsLabel = Components.Label {
        OnInitialize = function(self)
            self:setDimensions(WIN_W - MARGIN * 2 - 16 - 124, 20)
        end,
        OnMouseWheel = function(self, x, y, delta)
            onScroll(delta)
        end
    }
    children[2] = totalPointsLabel

    -- Sort-by-name button
    local sortNameBtn = Components.Button {
        Template = "MongbatButton18",
        Resizable = false,
        Snappable = false,
        OnInitialize = function(self)
            self:setDimensions(72, 22)
            self:setText(L"By Name")
        end,
        OnLButtonUp = function(self)
            sortByName()
            updateAllRows()
        end,
        OnMouseWheel = function(self, x, y, delta)
            onScroll(delta)
        end
    }
    children[3] = sortNameBtn

    -- Sort-by-value button
    local sortValueBtn = Components.Button {
        Template = "MongbatButton18",
        Resizable = false,
        Snappable = false,
        OnInitialize = function(self)
            self:setDimensions(72, 22)
            self:setText(L"By Value")
        end,
        OnLButtonUp = function(self)
            sortByValue()
            updateAllRows()
        end,
        OnMouseWheel = function(self, x, y, delta)
            onScroll(delta)
        end
    }
    children[4] = sortValueBtn

    -- Filter input: typing narrows the skill list to matching names
    local filterInput = Components.FilterInput {
        OnInitialize = function(self)
            self:setDimensions(WIN_W - MARGIN * 2 - 16, 22)
        end,
        OnTextChanged = function(self, text)
            filterText = string.lower(Api.String.WStringToString(text))
            rebuildFilteredList()
            updateAllRows()
        end,
        OnKeyEscape = function(self)
            self:clear()
            filterText = ""
            rebuildFilteredList()
            updateAllRows()
        end
    }
    children[5] = filterInput

    -- Visible row buttons (15 slots)
    for i = 1, VISIBLE_ROWS do
        local btn = SkillRowButton(i)
        rowButtons[i] = btn
        children[5 + i] = btn
    end

    -- Custom layout: positions header children then fixed-position row slots
    local function SkillsLayout(window, _, child, index)
        local winName = window:getName()
        if index == 1 then
            -- "Skills" title: top-left
            child:clearAnchors()
            child:addAnchor("topleft", winName, "topleft", MARGIN, MARGIN)
        elseif index == 2 then
            -- Total points label: right of title
            child:clearAnchors()
            child:addAnchor("topleft", winName, "topleft", MARGIN + 128, MARGIN)
        elseif index == 3 then
            -- Sort-by-name button: below title row
            child:clearAnchors()
            child:addAnchor("topleft", winName, "topleft", MARGIN, MARGIN + 26)
        elseif index == 4 then
            -- Sort-by-value button: right of sort-by-name
            child:clearAnchors()
            child:addAnchor("topleft", winName, "topleft", MARGIN + 82, MARGIN + 26)
        elseif index == 5 then
            -- Filter input: below sort row
            child:clearAnchors()
            child:addAnchor("topleft", winName, "topleft", MARGIN, MARGIN + 52)
        else
            -- Skill row slots: stacked below the header area
            local rowIndex = index - 5
            local y = HEADER_H + (rowIndex - 1) * ROW_H
            child:clearAnchors()
            child:addAnchor("topleft", winName, "topleft", MARGIN, y)
        end
    end

    local function Window()
        return Components.Window {
            Name = NAME,
            Resizable = false,
            OnLayout = SkillsLayout,
            OnInitialize = function(self)
                self:setDimensions(WIN_W, WIN_H)
                self:setChildren(children)
                -- Register dynamic skill data for all server IDs (0..57)
                local dataType = Constants.DataEvents.OnUpdateSkillDynamicData.getType()
                for i = 0, MAX_SERVER_ID do
                    Api.Window.RegisterData(dataType, i)
                end
            end,
            OnUpdateSkillDynamicData = function(self, skillData)
                -- A skill's data changed: update the visible row showing it (if any)
                local serverId = skillData:getServerId()
                local rowIndex = findRowForServerId(serverId)
                if rowIndex ~= nil then
                    updateRow(rowIndex)
                end
                updateTotalPoints()
            end,
            OnMouseWheel = function(self, x, y, delta)
                onScroll(delta)
            end,
            OnShown = function(self)
                updateAllRows()
                updateTotalPoints()
            end,
            OnRButtonUp = function() end
        }
    end

    Window():create(true)

    -- Populate rows and total points after window and children are fully created
    updateAllRows()
    updateTotalPoints()
end

local function OnShutdown()
    -- Restore the original skills toggle action
    if originalToggleSkillsWindow ~= nil then
        Api.Actions.SetToggleSkillsWindow(originalToggleSkillsWindow)
        originalToggleSkillsWindow = nil
    end

    -- Unregister skill dynamic data for all server IDs
    local dataType = Constants.DataEvents.OnUpdateSkillDynamicData.getType()
    for i = 0, MAX_SERVER_ID do
        Api.Window.UnregisterData(dataType, i)
    end

    Api.Window.Destroy(INFO_NAME)
    Api.Window.Destroy(NAME)

    -- Unload the skills CSV table from memory
    Api.Skill.UnloadCSV()

    -- Restore the default SkillsWindow
    Components.Defaults.SkillsWindow:restore()
end

Mongbat.Mod {
    Name = "MongbatSkillsWindow",
    Path = "/src/mods/mongbat-skills-window",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
