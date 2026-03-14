local NAME = "MongbatDebugWindow"
local FILTERED_LOG = "MongbatDebugFiltered"

local Api = Mongbat.Api
local Components = Mongbat.Components

local FilterColors = {
    [1] = { r = 255, g = 0,   b = 255 }, -- System: Magenta
    [2] = { r = 255, g = 0,   b = 0   }, -- Error: Red
    [3] = { r = 255, g = 255, b = 0   }, -- Debug: Yellow
    [4] = { r = 0,   g = 255, b = 0   }, -- Function: Green
}

--- Populates the filtered text log with entries matching the filter text,
--- then toggles visibility between the full and filtered LogDisplays.
---@param fullLog LogDisplay
---@param filteredLog LogDisplay
---@param text wstring
local function applyFilter(fullLog, filteredLog, text)
    if wstring.len(text) <= 0 then
        filteredLog.showing = false
        fullLog.showing = true
        return
    end

    Api.TextLog.Clear(FILTERED_LOG)
    local lowerFilter = wstring.lower(text)

    for _, logName in ipairs({ "UiLog", "DebugPrint" }) do
        local count = Api.TextLog.GetNumEntries(logName)
        for i = 0, count - 1 do
            local _, filterType, entryText = Api.TextLog.GetEntry(logName, i)
            if entryText and wstring.find(wstring.lower(entryText), lowerFilter) then
                Api.TextLog.AddEntry(FILTERED_LOG, filterType, entryText)
            end
        end
    end

    fullLog.showing = false
    filteredLog.showing = true
end

local function OnInitialize()
    local original = Components.Defaults.DebugWindow
    original:disable()

    Api.TextLog.Create("DebugPrint", 500)
    Api.TextLog.SetEnabled("DebugPrint", true)
    Api.TextLog.Clear("DebugPrint")
    Api.TextLog.SetIncrementalSaving("DebugPrint", true, "logs/Debug.Print.log")
    Api.TextLog.SetEnabled("UiLog", true)
    Api.TextLog.SetIncrementalSaving("UiLog", true, "logs/lua.log")

    Api.TextLog.Create(FILTERED_LOG, 500)
    Api.TextLog.SetEnabled(FILTERED_LOG, true)
    for id = 1, 4 do
        Api.TextLog.AddFilterType(FILTERED_LOG, id, L"")
    end

    local fullLogDisplay = Components.LogDisplay {
        OnInitialize = function(self)
            self.timestampVisible = false
            self.logNameVisible = true
            self.filterNameVisible = true
            self.logs = self:logBuilder(function(log)
                local uiLog = log:newLog("UiLog", true)
                for id, color in pairs(FilterColors) do
                    uiLog:filterColor(id, color)
                end
                return { uiLog, log:newLog("DebugPrint", true) }
            end)
        end,
    }

    local filteredLogDisplay = Components.LogDisplay {
        OnInitialize = function(self)
            self.timestampVisible = false
            self.logNameVisible = false
            self.filterNameVisible = true
            self.logs = self:logBuilder(function(log)
                local filteredLog = log:newLog(FILTERED_LOG, true)
                for id, color in pairs(FilterColors) do
                    filteredLog:filterColor(id, color)
                end
                return { filteredLog }
            end)

            self.showing = false
        end,
    }

    local filterInput = Components.FilterInput {
        OnTextChanged = function(self, text)
            applyFilter(fullLogDisplay, filteredLogDisplay, text)
        end,
        OnKeyEscape = function(self)
            self:clear()
            applyFilter(fullLogDisplay, filteredLogDisplay, L"")
        end,
    }

    Components.Window({
        Name = NAME,
        OnLayout = function(window, children, child, index)
            local dimens = window.dimensions
            local padding = 12
            local spacing = 4
            local filterHeight = 24
            local contentWidth = dimens.x - (padding * 2)
            local logHeight = dimens.y - (padding * 2) - filterHeight - spacing

            if index == 1 then
                -- FilterInput
                child.anchors = child:anchorBuilder(function(a)
                    return { a:add("topleft", window.name, "topleft", padding, padding) }
                end)
                child.dimensions = {contentWidth, filterHeight}
            else
                -- Both LogDisplays occupy the same space below the filter
                child.anchors = child:anchorBuilder(function(a)
                    return { a:add("bottomleft", children[1].name, "topleft", 0, spacing) }
                end)
                child.dimensions = {contentWidth, logHeight}
            end
        end,
        OnInitialize = function(self)
            self.dimensions = {800, 500}
            self.alpha = 0.75
            self.children = { filterInput, fullLogDisplay, filteredLogDisplay }
        end
    }):create(false)
end

local function OnShutdown()
    Api.Window.Destroy(NAME)
    Api.TextLog.Destroy(FILTERED_LOG)
    local original = Components.Defaults.DebugWindow
    original:restore()
end

Mongbat.Mod {
    Name = "MongbatDebug",
    Path = "/src/mods/mongbat-debug",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
