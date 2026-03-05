local NAME = "MongbatSkillsTrackerWindow"
local SKILL_COUNT = 58
local MAX_ROWS = 61     -- 58 skills + 1 divider + 1 remaining + 1 spare
local ROW_HEIGHT = 16
local ROW_PADDING = 2
local WINDOW_WIDTH = 220
local MIN_HEIGHT = 40
local SAVE_KEY = "MongbatSkillsTracker.ShowAllMySkills"

---@param context Context
local function OnInitialize(context)
    local showAllMySkills = context.Api.Interface.LoadBoolean(SAVE_KEY, true)

    local skillsTracker = context.Components.Defaults.SkillsTracker
    skillsTracker:asComponent():setShowing(false)
    skillsTracker:disable()

    -- Pre-create a fixed pool of Label views for the skill rows.
    -- They are created hidden; rebuild() shows and re-anchors the visible ones.
    local labelPool = {}
    local windowRef = nil   -- set once Window:OnInitialize fires

    local function makeLabelForPool()
        return context.Components.Label {
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
            end
        }
    end

    for i = 1, MAX_ROWS do
        labelPool[i] = makeLabelForPool()
    end

    -- Format a skill value (stored in tenths) as "XX.X"
    local function formatSkillValue(value)
        local whole = tostring(value)
        local lastDigit = string.sub(whole, -1, -1)
        local intPart = string.sub(whole, 1, string.len(whole) - 1)
        if intPart == "" then intPart = "0" end
        return intPart .. "." .. lastDigit
    end

    -- Format the remaining skill points (in tenths) as "XX.X%"
    local function formatRemaining(remaining)
        if remaining <= 0 then
            return "0.0%"
        end
        local whole = tostring(remaining)
        local lastDigit = string.sub(whole, -1, -1)
        local intPart = string.sub(whole, 1, string.len(whole) - 1)
        if intPart == "" then intPart = "0" end
        return intPart .. "." .. lastDigit .. "%"
    end

    -- Rebuild the visible skill list and resize the window.
    local function rebuild(window)
        -- Collect the rows to display
        local rows = {}

        if showAllMySkills then
            local totalUsed = 0
            for i = 1, SKILL_COUNT do
                local csv = context.Data.SkillsCSV(i)
                local serverId = csv:getServerId()
                local dynamic = context.Data.SkillDynamicData(serverId)
                local value = dynamic:getRealValue()
                totalUsed = totalUsed + value
                if value > 0 then
                    local nameStr = context.Utils.String.FromWString(csv:getName())
                    rows[#rows + 1] = nameStr .. ": " .. formatSkillValue(value) .. "%"
                end
            end

            if #rows > 0 then
                -- Divider row
                rows[#rows + 1] = "--------------------------------"
                -- Remaining row
                local remaining = (720 * 10) - totalUsed
                rows[#rows + 1] = "Remaining: " .. formatRemaining(remaining)
            end
        else
            local customSkills = context.Data.CustomSkills()
            for i = 1, #customSkills do
                local skillId = customSkills[i]
                local csv = context.Data.SkillsCSV(skillId)
                local serverId = csv:getServerId()
                local dynamic = context.Data.SkillDynamicData(serverId)
                local value = dynamic:getRealValue()
                local nameStr = context.Utils.String.FromWString(csv:getName())
                rows[#rows + 1] = nameStr .. ": " .. formatSkillValue(value) .. "%"
            end
        end

        -- Hide all pool labels
        for i = 1, MAX_ROWS do
            if context.Api.Window.DoesExist(labelPool[i]:getName()) then
                labelPool[i]:setShowing(false)
            end
        end

        local windowName = window:getName()
        local prevName = nil
        local count = math.min(#rows, MAX_ROWS)

        for i = 1, count do
            local label = labelPool[i]
            local labelName = label:getName()

            if context.Api.Window.DoesExist(labelName) then
                label:setShowing(true)
                label:setText(rows[i])
                label:clearAnchors()

                if prevName == nil then
                    label:addAnchor("topleft", windowName, "topleft", 8, 8)
                else
                    label:addAnchor("topleft", prevName, "bottomleft", 0, ROW_PADDING)
                end

                label:setDimensions(WINDOW_WIDTH - 16, ROW_HEIGHT)
                prevName = labelName
            end
        end

        -- Resize the window to fit the visible rows
        local rowCount = count
        local newHeight = 16 + rowCount * (ROW_HEIGHT + ROW_PADDING)
        if newHeight < MIN_HEIGHT then newHeight = MIN_HEIGHT end
        window:setDimensions(WINDOW_WIDTH, newHeight)
    end

    -- Context menu callback
    local function onContextMenuCallback(returnCode, param)
        if returnCode == "all" then
            context.Api.Interface.SaveBoolean(SAVE_KEY, true)
            showAllMySkills = true
        elseif returnCode == "custom" then
            context.Api.Interface.SaveBoolean(SAVE_KEY, false)
            showAllMySkills = false
        end
        if windowRef ~= nil then
            rebuild(windowRef)
        end
    end

    local window = context.Components.Window {
        Name = NAME,
        Resizable = false,
        OnInitialize = function(self)
            windowRef = self
            self:setDimensions(WINDOW_WIDTH, MIN_HEIGHT)

            -- Create and parent pool labels to this window.
            -- Because these labels are not passed to Window:setChildren, the normal
            -- component lifecycle (which wraps children in Window:onInitialize) does
            -- not apply.  We call create() + onInitialize() directly to register their
            -- event handlers, then reparent them to this window manually.
            for i = 1, MAX_ROWS do
                local label = labelPool[i]
                label:create(false)
                label:onInitialize()
                label:setParent(self:getName())
            end

            rebuild(self)
        end,
        OnUpdateSkillDynamicData = function(self)
            rebuild(self)
        end,
        OnRButtonUp = function(self, flags, x, y)
            if showAllMySkills then
                context.Api.ContextMenu.CreateLuaItem(
                    context.Api.String.GetStringFromTid(1154801), 0, "custom", 2, false)
            else
                context.Api.ContextMenu.CreateLuaItem(
                    context.Api.String.GetStringFromTid(1154802), 0, "all", 2, false)
            end
            context.Api.ContextMenu.ActivateLua(onContextMenuCallback)
        end
    }

    window:create(true)
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.Destroy(NAME)

    local skillsTracker = context.Components.Defaults.SkillsTracker
    skillsTracker:restore()
    skillsTracker:asComponent():setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatSkillsTracker",
    Path = "/src/mods/mongbat-skills-tracker",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
