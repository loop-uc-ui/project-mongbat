-- Debug log viewer: a filter EditBox over two LogDisplays (full + filtered),
-- toggled by whether the filter has any text. Hijacks the default
-- DebugWindow so this mod owns presentation entirely.

local Api   = Mongbat.Api
local Utils = Mongbat.Utils

local NAME           = "MongbatDebugWindow"
local FILTER_LOG     = "MongbatDebugFiltered"
local FILTER_INPUT   = "MongbatDebugFilterInput"
local FULL_LOG       = "MongbatDebugFullLog"
local FILTERED_LOG_W = "MongbatDebugFilteredLog"

local FilterColors = {
    [1] = { r = 255, g = 0,   b = 255 }, -- System: Magenta
    [2] = { r = 255, g = 0,   b = 0   }, -- Error:  Red
    [3] = { r = 255, g = 255, b = 0   }, -- Debug:  Yellow
    [4] = { r = 0,   g = 255, b = 0   }, -- Function: Green
}

local PADDING       = 12
local SPACING       = 4
local FILTER_HEIGHT = 24
local PANEL_W       = 800
local PANEL_H       = 500

local M = {}
local state = { filtered = false }

local function rebuildFilteredLog(filterText)
    Api.TextLog.Clear(FILTER_LOG)
    if Utils.String.IsEmpty(filterText) then return end

    local needle = Utils.String.Lower(filterText)
    Utils.Array.ForEach({ "UiLog", "DebugPrint" }, function(sourceLog)
        local count = Api.TextLog.GetNumEntries(sourceLog)
        for i = 0, count - 1 do
            local _, filterType, entryText = Api.TextLog.GetEntry(sourceLog, i)
            if entryText and Utils.String.Find(Utils.String.Lower(entryText), needle) then
                Api.TextLog.AddEntry(FILTER_LOG, filterType, entryText)
            end
        end
    end)
end

local function applyFilter(text)
    rebuildFilteredLog(text)
    local nowFiltered = not Utils.String.IsEmpty(text)
    if nowFiltered ~= state.filtered then
        state.filtered = nowFiltered
        Api.Window.SetShowing(FULL_LOG,       not nowFiltered)
        Api.Window.SetShowing(FILTERED_LOG_W, nowFiltered)
    end
end

function M.OnLoad()
    Api.Window.Destroy("DebugWindow")
    -- TextLog setup (engine state, not a window).
    Api.TextLog.Create("DebugPrint", 500)
    Api.TextLog.SetEnabled("DebugPrint", true)
    Api.TextLog.Clear("DebugPrint")
    Api.TextLog.SetIncrementalSaving("DebugPrint", true, "logs/Debug.Print.log")
    Api.TextLog.SetEnabled("UiLog", true)
    Api.TextLog.SetIncrementalSaving("UiLog", true, "logs/lua.log")

    Api.TextLog.Create(FILTER_LOG, 500)
    Api.TextLog.SetEnabled(FILTER_LOG, true)
    for id = 1, 4 do
        Api.TextLog.AddFilterType(FILTER_LOG, id, Utils.String.ToWString(""))
    end

    -- Outer window.
    Mongbat.CreateWindow {
        name = NAME, template = "MongbatWindow",
        module = M, key = "panel", showing = false,
    }
    Api.Window.SetDimensions(NAME, PANEL_W, PANEL_H)
    Api.Window.SetAlpha(NAME, 0.75)

    -- Filter input.
    Mongbat.CreateWindow {
        name = FILTER_INPUT, template = "MongbatEditTextBox",
        parent = NAME, module = M, key = "filter",
    }
    Api.Window.SetDimensions(FILTER_INPUT, PANEL_W - 2 * PADDING, FILTER_HEIGHT)
    Api.Window.SetOffsetFromParent(FILTER_INPUT, PADDING, PADDING)

    -- Full (unfiltered) log.
    Mongbat.CreateWindow {
        name = FULL_LOG, template = "MongbatLogDisplay",
        parent = NAME, module = M, key = "fullLog",
    }
    Api.Window.SetOffsetFromParent(FULL_LOG, PADDING, PADDING + FILTER_HEIGHT + SPACING)
    Api.Window.SetDimensions(FULL_LOG,
        PANEL_W - 2 * PADDING,
        PANEL_H - PADDING - FILTER_HEIGHT - SPACING - PADDING)
    Api.LogDisplay.ShowTimestamp(FULL_LOG, false)
    Api.LogDisplay.ShowLogName(FULL_LOG, true)
    Api.LogDisplay.ShowFilterName(FULL_LOG, true)
    Api.LogDisplay.AddLog(FULL_LOG, "UiLog", true)
    Api.LogDisplay.AddLog(FULL_LOG, "DebugPrint", true)
    Utils.Table.ForEach(FilterColors, function(level, color)
        Api.LogDisplay.SetFilterColor(FULL_LOG, "UiLog", level, color)
    end)

    -- Filtered log (hidden until filter has text).
    Mongbat.CreateWindow {
        name = FILTERED_LOG_W, template = "MongbatLogDisplay",
        parent = NAME, module = M, key = "filteredLog",
        showing = false,
    }
    Api.Window.SetOffsetFromParent(FILTERED_LOG_W, PADDING, PADDING + FILTER_HEIGHT + SPACING)
    Api.Window.SetDimensions(FILTERED_LOG_W,
        PANEL_W - 2 * PADDING,
        PANEL_H - PADDING - FILTER_HEIGHT - SPACING - PADDING)
    Api.LogDisplay.ShowTimestamp(FILTERED_LOG_W, false)
    Api.LogDisplay.ShowLogName(FILTERED_LOG_W, false)
    Api.LogDisplay.ShowFilterName(FILTERED_LOG_W, true)
    Api.LogDisplay.AddLog(FILTERED_LOG_W, FILTER_LOG, true)
    Utils.Table.ForEach(FilterColors, function(level, color)
        Api.LogDisplay.SetFilterColor(FILTERED_LOG_W, FILTER_LOG, level, color)
    end)
end

function M.OnUnload()
    Mongbat.DestroyWindow(FILTERED_LOG_W)
    Mongbat.DestroyWindow(FULL_LOG)
    Mongbat.DestroyWindow(FILTER_INPUT)
    Mongbat.DestroyWindow(NAME)
    Api.TextLog.Destroy(FILTER_LOG)
end

function M.OnEditBoxChanged(name, key)
    if key == "filter" then applyFilter(Api.EditTextBox.GetText(name)) end
end

function M.OnEditBoxKeyEscape(name, key)
    if key == "filter" then
        Api.EditTextBox.Clear(name)
        applyFilter(Utils.String.ToWString(""))
    end
end

Mongbat.Mod {
    Name   = "MongbatDebug",
    Path   = "/src/mods/mongbat-debug",
    Module = M,
}
