-- Debug log viewer: filter EditBox over two LogDisplays (full + filtered),
-- toggled by whether the filter has any text. Hijacks the default
-- DebugWindow so this mod owns presentation entirely.
--
-- Pattern: declarative. M.Build(emit) re-emits all four windows every
-- frame; the filtered/unfiltered toggle is driven by `state.filtered`
-- through `showing = ...`. TextLog setup runs once in M.OnLoad (engine
-- resources, not windows).

local UI    = Mongbat.UI
local Api   = Mongbat.Api
local Utils = Mongbat.Utils

local FILTER_LOG = "MongbatDebugFilteredText"

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
local LOG_W         = PANEL_W - 2 * PADDING
local LOG_H         = PANEL_H - PADDING - FILTER_HEIGHT - SPACING - PADDING

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
    state.filtered = not Utils.String.IsEmpty(text)
end

-- LogDisplay setup is not expressible as widget setters; use :tap() to
-- bind one-off configuration once per (re)create.
local function configureFullLog(name)
    Api.LogDisplay.ShowTimestamp(name, false)
    Api.LogDisplay.ShowLogName(name, true)
    Api.LogDisplay.ShowFilterName(name, true)
    Api.LogDisplay.AddLog(name, "UiLog", true)
    Api.LogDisplay.AddLog(name, "DebugPrint", true)
    Utils.Table.ForEach(FilterColors, function(level, color)
        Api.LogDisplay.SetFilterColor(name, "UiLog", level, color)
    end)
end

local function configureFilteredLog(name)
    Api.LogDisplay.ShowTimestamp(name, false)
    Api.LogDisplay.ShowLogName(name, false)
    Api.LogDisplay.ShowFilterName(name, true)
    Api.LogDisplay.AddLog(name, FILTER_LOG, true)
    Utils.Table.ForEach(FilterColors, function(level, color)
        Api.LogDisplay.SetFilterColor(name, FILTER_LOG, level, color)
    end)
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
end

function M.OnUnload()
    Api.TextLog.Destroy(FILTER_LOG)
end

function M.Build(emit)
    emit("panel", {
        name     = "MongbatDebugWindow",     -- stable engine name
        template = "MongbatWindow",
        showing  = false,                    -- toggled by debug mod's hotkey
        widget   = UI.Window():setDimensions(PANEL_W, PANEL_H):setAlpha(0.75),
    })

    emit("filter", {
        template = "MongbatEditTextBox",
        parent   = "panel",
        widget   = UI.EditBox()
            :setDimensions(LOG_W, FILTER_HEIGHT)
            :setOffsetFromParent(PADDING, PADDING),
    })

    emit("fullLog", {
        template = "MongbatLogDisplay",
        parent   = "panel",
        showing  = not state.filtered,
        widget   = UI.Window()
            :setDimensions(LOG_W, LOG_H)
            :setOffsetFromParent(PADDING, PADDING + FILTER_HEIGHT + SPACING)
            :tap(configureFullLog),
    })

    emit("filteredLog", {
        template = "MongbatLogDisplay",
        parent   = "panel",
        showing  = state.filtered,
        widget   = UI.Window()
            :setDimensions(LOG_W, LOG_H)
            :setOffsetFromParent(PADDING, PADDING + FILTER_HEIGHT + SPACING)
            :tap(configureFilteredLog),
    })
end

function M.OnEditBoxChanged(window)
    if window.key == "filter" then applyFilter(Api.EditTextBox.GetText(window.name)) end
end

function M.OnEditBoxKeyEscape(window)
    if window.key == "filter" then
        Api.EditTextBox.Clear(window.name)
        applyFilter(Utils.String.ToWString(""))
    end
end

Mongbat.Mod {
    Name   = "MongbatDebug",
    Path   = "/src/mods/mongbat-debug",
    Module = M,
}
