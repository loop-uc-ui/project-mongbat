local NAME = "BugReportWindow"
local NUM_TYPES = 15

local PADDING = 12
local BUTTON_HEIGHT = 24
local BUTTON_WIDTH = 200
local DESCRIPTION_HEIGHT = 150
local ACTION_BAR_HEIGHT = 36

---@param ctx Context
local function buildWindow(ctx)
    local Api = ctx.Api
    local Data = ctx.Data
    local Constants = ctx.Constants
    local Components = ctx.Components

    local selectedType = Constants.BugTypes.Other
    local typeButtons = {}
    local descriptionBox = nil

    local function selectType(t)
        selectedType = t
        for i = 1, NUM_TYPES do
            if typeButtons[i] then
                typeButtons[i]:setChecked(selectedType == i)
            end
        end
    end

    local function clearForm()
        selectType(Constants.BugTypes.Other)
        if descriptionBox then
            descriptionBox:clear()
        end
    end

    local function submitReport()
        local text = descriptionBox and descriptionBox:getText() or L""
        Api.BugReport.Send(selectedType, text)
        Api.Window.Destroy(NAME)
        Api.Dialog.CreateStandard {
            titleTid = 1077790,
            bodyTid  = 1077901,
            windowName = NAME,
        }
    end

    -- Build one bug-type radio button
    ---@param index integer The bug type index (1-based)
    ---@return Button
    local function TypeButton(index)
        local bugReport = Data.BugReport()
        local entry = bugReport:getEntry(index)
        local label = entry and entry.flagName or towstring(index)
        return Components.Button {
            OnInitialize = function(self)
                self:setDimensions(BUTTON_WIDTH, BUTTON_HEIGHT)
                self:setText(label)
                self:setStayDown(true)
                self:setChecked(selectedType == index)
                typeButtons[index] = self
            end,
            OnShutdown = function(self)
                typeButtons[index] = nil
            end,
            OnLButtonUp = function(self)
                selectType(index)
            end,
        }
    end

    local submitButton = Components.Button {
        OnInitialize = function(self)
            self:setText(1077787)
        end,
        OnLButtonUp = function(self)
            submitReport()
        end,
    }

    local clearButton = Components.Button {
        OnInitialize = function(self)
            self:setText(3000154)
        end,
        OnLButtonUp = function(self)
            clearForm()
        end,
    }

    descriptionBox = Components.EditTextBox {
        OnInitialize = function(self)
            self:setDimensions(BUTTON_WIDTH * 2 + PADDING, DESCRIPTION_HEIGHT)
        end,
        OnShutdown = function(self)
            self:setFocus(false)
        end,
    }

    local typeList = {}
    for i = 1, NUM_TYPES do
        typeList[i] = TypeButton(i)
    end

    Components.Window {
        Name = NAME,
        Resizable = false,
        OnLayout = function(window, children, child, index)
            local dimens = window:getDimensions()
            local contentWidth = dimens.x - (PADDING * 2)

            if index <= NUM_TYPES then
                -- Bug type buttons in a column
                if index == 1 then
                    child:addAnchor("topleft", window:getName(), "topleft", PADDING, PADDING)
                else
                    child:addAnchor("topleft", children[index - 1]:getName(), "bottomleft", 0, 4)
                end
                child:setDimensions(BUTTON_WIDTH, BUTTON_HEIGHT)
            elseif index == NUM_TYPES + 1 then
                -- Description text box
                child:addAnchor("topleft", children[NUM_TYPES]:getName(), "bottomleft", 0, PADDING)
                child:setDimensions(contentWidth, DESCRIPTION_HEIGHT)
            elseif index == NUM_TYPES + 2 then
                -- Submit button
                child:addAnchor("topleft", children[NUM_TYPES + 1]:getName(), "bottomleft", 0, PADDING)
            elseif index == NUM_TYPES + 3 then
                -- Clear button
                child:addAnchor("left", children[NUM_TYPES + 2]:getName(), "right", PADDING, 0)
            end
        end,
        OnInitialize = function(self)
            local totalHeight = PADDING
                + NUM_TYPES * (BUTTON_HEIGHT + 4)
                + PADDING
                + DESCRIPTION_HEIGHT
                + PADDING
                + ACTION_BAR_HEIGHT
                + PADDING
            self:setDimensions(BUTTON_WIDTH * 2 + PADDING * 2, totalHeight)
            self:anchorToParentCenter()

            local allChildren = {}
            for i = 1, NUM_TYPES do
                allChildren[i] = typeList[i]
            end
            allChildren[NUM_TYPES + 1] = descriptionBox
            allChildren[NUM_TYPES + 2] = submitButton
            allChildren[NUM_TYPES + 3] = clearButton

            self:setChildren(allChildren)
        end,
        OnShown = function(self)
            if descriptionBox then
                descriptionBox:setFocus(true)
            end
        end,
        OnHidden = function(self)
            if descriptionBox then
                descriptionBox:setFocus(false)
            end
        end,
        OnRButtonUp = function(self)
            Api.Window.Destroy(NAME)
        end,
    }:create(true)
end

---@param ctx Context
local function OnInitialize(ctx)
    local Api = ctx.Api
    local Constants = ctx.Constants
    local Components = ctx.Components

    -- Register bug report data globally
    Api.Window.RegisterData(Constants.DataEvents.OnUpdateBugReport.getType(), 0)

    -- Suppress the default BugReportWindow
    Components.Defaults.BugReportWindow:disable()

    -- Intercept Interface.InitBugReport to open our window instead
    local iface = Components.Defaults.Interface:getDefault()
    iface.InitBugReport = function()
        if Api.Window.DoesExist(NAME) then
            Api.Window.Destroy(NAME)
        else
            buildWindow(ctx)
        end
    end
end

---@param ctx Context
local function OnShutdown(ctx)
    local Api = ctx.Api
    local Constants = ctx.Constants
    local Components = ctx.Components

    Api.Window.UnregisterData(Constants.DataEvents.OnUpdateBugReport.getType(), 0)
    Api.Window.Destroy(NAME)
    Components.Defaults.BugReportWindow:restore()
end

Mongbat.Mod {
    Name = "MongbatBugReport",
    Path = "/src/mods/mongbat-bug-report",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
