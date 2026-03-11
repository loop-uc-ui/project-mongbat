local NAME = "MongbatSkillsTrackerWindow"
local SKILL_COUNT = 58
local MAX_ROWS = 63     -- 58 skills + 1 divider + 1 remaining + 3 spares
local ROW_HEIGHT = 16
local ROW_PADDING = 2
local WINDOW_WIDTH = 220
local BTN_HEIGHT = 18
local BTN_WIDTH = 65
local BTN_GAP = 4
local BTN_TOP = 8
local ROWS_TOP = BTN_TOP + BTN_HEIGHT + 8   -- first skill row y-offset (34)
local MIN_HEIGHT = ROWS_TOP + ROW_HEIGHT + 16
local SAVE_KEY = "MongbatSkillsTracker.ShowAllMySkills"
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Utils = Mongbat.Utils

-- Colors for delta display
local COLOR_DEFAULT = { r = 255, g = 255, b = 255 }
local COLOR_GAIN    = { r = 64,  g = 192, b = 64  }
local COLOR_LOSS    = { r = 192, g = 64,  b = 64  }

--- Formats a skill value stored in tenths as "XX.X".
--- Uses arithmetic instead of string slicing to avoid raw string.* calls.
---@param value number Integer tenths value (e.g. 995 => "99.5")
---@return string
local function formatSkillValue(value)
    local whole = math.floor(value / 10)
    local tenths = value - whole * 10
    return tostring(whole) .. "." .. tostring(tenths)
end

--- Formats remaining skill points (in tenths) as "XX.X%".
---@param remaining number Integer tenths value
---@return string
local function formatRemaining(remaining)
    if remaining <= 0 then return "0.0%" end
    return formatSkillValue(remaining) .. "%"
end

--- Builds display text and color for a single skill row.
---@param nameStr string Plain-string skill name
---@param value number Skill value in tenths
---@param delta number|nil Session delta in tenths; nil when no session is active
---@return string text
---@return table color
local function formatSkillRow(nameStr, value, delta)
    local valueStr = formatSkillValue(value) .. "%"
    if delta == nil then
        return nameStr .. ": " .. valueStr, COLOR_DEFAULT
    elseif delta > 0 then
        return nameStr .. ": " .. valueStr .. " (+" .. formatSkillValue(math.abs(delta)) .. ")", COLOR_GAIN
    elseif delta < 0 then
        return nameStr .. ": " .. valueStr .. " (-" .. formatSkillValue(math.abs(delta)) .. ")", COLOR_LOSS
    end
    return nameStr .. ": " .. valueStr, COLOR_DEFAULT
end

local function OnInitialize()
    local showAllMySkills = Api.Interface.LoadBoolean(SAVE_KEY, true)

    -- Session state
    local sessionActive = false
    local sessionStartValues = {}   -- serverId -> value-in-tenths at session start
    local frozenDeltas = {}         -- serverId -> delta frozen at Stop time

    local skillsTracker = Components.Defaults.SkillsTracker
    skillsTracker:asComponent():setShowing(false)
    skillsTracker:disable()

    -- Pre-create a fixed pool of Label views for the skill rows.
    -- They are created hidden; rebuild() shows, anchors, and binds the visible ones.
    local labelPool = {}
    local rebuild   -- forward declaration: assigned below after getDelta and makeLabelForPool
    local windowRef = nil   -- set once Window:OnInitialize fires
    local startBtnRef = nil
    local stopBtnRef  = nil
    local resetBtnRef = nil

    --- Returns the session delta for a serverId, or nil if no session data exists.
    ---@param serverId number
    ---@return number|nil
    local function getDelta(serverId)
        if not sessionStartValues[serverId] then return nil end
        if sessionActive then
            return Data.SkillDynamicData(serverId):getRealValue() - sessionStartValues[serverId]
        else
            return frozenDeltas[serverId]
        end
    end

    --- Creates one label for pool slot i.
    --- OnUpdateSkillDynamicData is placed on the label (child-centric dispatch).
    --- rebuild() binds each visible label to its skill via setId(serverId), so only
    --- the label tracking the changed skill fires -- triggering exactly one rebuild.
    ---@param i number 1-based pool slot index
    ---@return Label
    local function makeLabelForPool(i)
        return Components.Label {
            OnLButtonDown = function(self, flags, x, y)
                if windowRef ~= nil then
                    windowRef:onLButtonDown(flags, x, y)
                end
            end,
            OnLButtonUp = function(self, flags, x, y)
                if windowRef ~= nil then
                    windowRef:onLButtonUp(flags, x, y)
                end
            end,
            OnRButtonUp = function(self, flags, x, y)
                if windowRef ~= nil then
                    windowRef:onRButtonUp(flags, x, y)
                end
            end,
            OnUpdateSkillDynamicData = function(_)
                -- This fires only for the skill bound to this label via setId().
                -- Triggering a full rebuild keeps the remaining total accurate.
                if windowRef ~= nil then
                    rebuild(windowRef)
                end
            end,
        }
    end

    for i = 1, MAX_ROWS do
        labelPool[i] = makeLabelForPool(i)
    end

    --- Snapshots all current skill values as the session start baseline.
    local function snapshotCurrentValues()
        sessionStartValues = {}
        frozenDeltas = {}
        for i = 1, SKILL_COUNT do
            local csv = Data.SkillsCSV(i)
            local serverId = csv:getServerId()
            sessionStartValues[serverId] =
                Data.SkillDynamicData(serverId):getRealValue()
        end
    end

    --- Freezes the current live deltas (called when Stop is pressed).
    local function freezeDeltas()
        frozenDeltas = {}
        Utils.Table.ForEach(sessionStartValues, function(serverId, startVal)
            local current = Data.SkillDynamicData(serverId):getRealValue()
            frozenDeltas[serverId] = current - startVal
        end)
    end

    --- Updates enabled/disabled state of session control buttons.
    local function updateButtonStates()
        if startBtnRef and startBtnRef:doesExist() then
            Api.Button.SetDisabled(startBtnRef:getName(), sessionActive)
        end
        if stopBtnRef and stopBtnRef:doesExist() then
            Api.Button.SetDisabled(stopBtnRef:getName(), not sessionActive)
        end
        if resetBtnRef and resetBtnRef:doesExist() then
            Api.Button.SetDisabled(
                resetBtnRef:getName(), next(sessionStartValues) == nil)
        end
    end

    --- Rebuilds the visible skill list and resizes the window.
    --- Also called by each pool label's OnUpdateSkillDynamicData handler.
    ---@param window Window
    rebuild = function(window)
        -- Collect the rows to display as {text, color, serverId?} entries
        local rows = {}

        if showAllMySkills then
            local totalUsed = 0
            for i = 1, SKILL_COUNT do
                local csv = Data.SkillsCSV(i)
                local serverId = csv:getServerId()
                local value = Data.SkillDynamicData(serverId):getRealValue()
                totalUsed = totalUsed + value
                if value > 0 then
                    local nameStr = Utils.String.FromWString(csv:getName())
                    local text, color = formatSkillRow(nameStr, value, getDelta(serverId))
                    Utils.Array.Add(rows, { text = text, color = color, serverId = serverId })
                end
            end

            if not Utils.Table.IsEmpty(rows) then
                Utils.Array.Add(rows, {
                    text  = "--------------------------------",
                    color = COLOR_DEFAULT
                })
                local remaining = (720 * 10) - totalUsed
                Utils.Array.Add(rows, {
                    text  = "Remaining: " .. formatRemaining(remaining),
                    color = COLOR_DEFAULT
                })
            end
        else
            local customSkills = Data.CustomSkills()
            Utils.Array.ForEach(customSkills, function(skillId)
                local csv = Data.SkillsCSV(skillId)
                local serverId = csv:getServerId()
                local value = Data.SkillDynamicData(serverId):getRealValue()
                local nameStr = Utils.String.FromWString(csv:getName())
                local text, color = formatSkillRow(nameStr, value, getDelta(serverId))
                Utils.Array.Add(rows, { text = text, color = color, serverId = serverId })
            end)
        end

        -- Deregister all pool labels from their current skills before reassignment.
        -- setId(0) unregisters the old skill data binding so that labels not
        -- reassigned below will not fire OnUpdateSkillDynamicData.
        Utils.Array.ForEach(labelPool, function(label)
            if Api.Window.DoesExist(label:getName()) then
                label:setShowing(false)
                label:setId(0)
            end
        end)

        local windowName = window:getName()
        local prevName   = nil

        -- labelPool always has MAX_ROWS entries; rows has at most SKILL_COUNT + 2
        -- (<= 60), so labelPool[i] is always valid for any i within rows.
        Utils.Array.ForEach(rows, function(row, i)
            local label     = labelPool[i]
            local labelName = label:getName()

            if Api.Window.DoesExist(labelName) then
                label:setShowing(true)
                label:setText(row.text)
                label:setTextColor(row.color)
                label:clearAnchors()

                if prevName == nil then
                    label:addAnchor("topleft", windowName, "topleft", 8, ROWS_TOP)
                else
                    label:addAnchor("topleft", prevName, "bottomleft", 0, ROW_PADDING)
                end

                label:setDimensions(WINDOW_WIDTH - 16, ROW_HEIGHT)

                -- Bind this label to its specific skill so OnUpdateSkillDynamicData
                -- fires only for this label when that skill changes.
                -- Divider and remaining rows have no serverId and stay at id=0.
                if row.serverId ~= nil then
                    label:setId(row.serverId)
                end

                prevName = labelName
            end
        end)

        -- Resize the window to fit the visible rows
        local newHeight = ROWS_TOP + #rows * (ROW_HEIGHT + ROW_PADDING) + 8
        if newHeight < MIN_HEIGHT then newHeight = MIN_HEIGHT end
        window:setDimensions(WINDOW_WIDTH, newHeight)
    end

    -- Context menu callback
    local function onContextMenuCallback(returnCode, param)
        if returnCode == "all" then
            Api.Interface.SaveBoolean(SAVE_KEY, true)
            showAllMySkills = true
        elseif returnCode == "custom" then
            Api.Interface.SaveBoolean(SAVE_KEY, false)
            showAllMySkills = false
        end
        if windowRef ~= nil then
            rebuild(windowRef)
        end
    end

    --- Creates a session control button, manually parented to the window.
    --- Because these are not in Window:setChildren, the Window lifecycle does not
    --- wrap them. We call create() + onInitialize() directly, then reparent.
    ---@param label wstring Button label text
    ---@param onLButtonUp fun() Callback invoked when the button is clicked
    ---@return Button
    local function makeControlButton(label, onLButtonUp)
        return Components.Button {
            OnInitialize = function(self)
                self:setText(label)
                self:setDimensions(BTN_WIDTH, BTN_HEIGHT)
            end,
            OnLButtonUp = onLButtonUp
        }
    end

    local window = Components.Window {
        Name = NAME,
        Resizable = false,
        OnInitialize = function(self)
            windowRef = self
            self:setDimensions(WINDOW_WIDTH, MIN_HEIGHT)

            -- Session control buttons
            startBtnRef = makeControlButton(L"Start", function()
                snapshotCurrentValues()
                sessionActive = true
                updateButtonStates()
                rebuild(self)
            end)
            stopBtnRef = makeControlButton(L"Stop", function()
                freezeDeltas()
                sessionActive = false
                updateButtonStates()
                rebuild(self)
            end)
            resetBtnRef = makeControlButton(L"Reset", function()
                    snapshotCurrentValues()
                    updateButtonStates()
                    rebuild(self)
                end
            )

            local windowName = self:getName()
            Utils.Array.ForEach(
                { startBtnRef, stopBtnRef, resetBtnRef },
                function(btn, idx)
                    btn:create(false)
                    btn:onInitialize()
                    btn:setParent(windowName)
                    btn:clearAnchors()
                    btn:addAnchor(
                        "topleft", windowName, "topleft",
                        8 + (idx - 1) * (BTN_WIDTH + BTN_GAP), BTN_TOP)
                end
            )
            updateButtonStates()

            -- Label pool
            -- Because these labels are not passed to Window:setChildren, the
            -- normal component lifecycle does not apply. We call create() +
            -- onInitialize() directly to register their event handlers, then
            -- reparent them to this window manually.
            Utils.Array.ForEach(labelPool, function(lbl)
                lbl:create(false)
                lbl:onInitialize()
                lbl:setParent(windowName)
            end)

            rebuild(self)
        end,
        OnRButtonUp = function(self, flags, x, y)
            if showAllMySkills then
                Api.ContextMenu.CreateLuaItem(
                    Api.String.GetStringFromTid(1154801), 0, "custom", 2, false)
            else
                Api.ContextMenu.CreateLuaItem(
                    Api.String.GetStringFromTid(1154802), 0, "all", 2, false)
            end
            Api.ContextMenu.ActivateLua(onContextMenuCallback)
        end
    }

    window:create(true)
end

local function OnShutdown()
    Api.Window.Destroy(NAME)

    local skillsTracker = Components.Defaults.SkillsTracker
    skillsTracker:restore()
    skillsTracker:asComponent():setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatSkillsTracker",
    Path = "/src/mods/mongbat-skills-tracker",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
