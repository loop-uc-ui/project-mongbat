local NAME = "MongbatDebugWindow"
local FILTERED_LOG = "MongbatDebugFiltered"

local FilterColors = {
    [1] = { r = 255, g = 0,   b = 255 }, -- System: Magenta
    [2] = { r = 255, g = 0,   b = 0   }, -- Error: Red
    [3] = { r = 255, g = 255, b = 0   }, -- Debug: Yellow
    [4] = { r = 0,   g = 255, b = 0   }, -- Function: Green
}

--- Populates the filtered text log with entries matching the filter text,
--- then toggles visibility between the full and filtered LogDisplays.
---@param ctx Context
---@param fullLog LogDisplay
---@param filteredLog LogDisplay
---@param text wstring
local function applyFilter(ctx, fullLog, filteredLog, text)
    if wstring.len(text) <= 0 then
        filteredLog:setShowing(false)
        fullLog:setShowing(true)
        return
    end

    ctx.Api.TextLog.Clear(FILTERED_LOG)
    local lowerFilter = wstring.lower(text)

    for _, logName in ipairs({ "UiLog", "DebugPrint" }) do
        local count = ctx.Api.TextLog.GetNumEntries(logName)
        for i = 1, count do
            local _, filterType, entryText = ctx.Api.TextLog.GetEntry(logName, i)
            if entryText and wstring.find(wstring.lower(entryText), lowerFilter) then
                ctx.Api.TextLog.AddEntry(FILTERED_LOG, filterType, entryText)
            end
        end
    end

    fullLog:setShowing(false)
    filteredLog:setShowing(true)
end

---@param ctx Context
local function OnInitialize(ctx)
    local original = ctx.Components.Defaults.DebugWindow
    original:disable()

    ctx.Api.TextLog.Create("DebugPrint", 1)
    ctx.Api.TextLog.SetEnabled("DebugPrint", true)
    ctx.Api.TextLog.Clear("DebugPrint")
    ctx.Api.TextLog.SetIncrementalSaving("DebugPrint", true, "logs/Debug.Print.log")
    ctx.Api.TextLog.SetEnabled("UiLog", true)
    ctx.Api.TextLog.SetIncrementalSaving("UiLog", true, "logs/lua.log")

    ctx.Api.TextLog.Create(FILTERED_LOG, 500)
    ctx.Api.TextLog.SetEnabled(FILTERED_LOG, true)
    for id = 1, 4 do
        ctx.Api.TextLog.AddFilterType(FILTERED_LOG, id, L"")
    end

    local fullLogDisplay = ctx.Components.LogDisplay {
        OnInitialize = function(self)
            self:showTimestamp(false)
            self:showLogName(true)
            self:showFilterName(true)
            self:addLog("UiLog", true)
            self:addLog("DebugPrint", true)

            for id, color in pairs(FilterColors) do
                self:setFilterColor("UiLog", id, color)
            end
        end,
    }

    local filteredLogDisplay = ctx.Components.LogDisplay {
        OnInitialize = function(self)
            self:showTimestamp(false)
            self:showLogName(false)
            self:showFilterName(true)
            self:addLog(FILTERED_LOG, true)

            for id, color in pairs(FilterColors) do
                self:setFilterColor(FILTERED_LOG, id, color)
            end

            self:setShowing(false)
        end,
    }

    local filterInput = ctx.Components.FilterInput {
        OnTextChanged = function(self, text)
            applyFilter(ctx, fullLogDisplay, filteredLogDisplay, text)
        end,
        OnKeyEscape = function(self)
            self:clear()
            applyFilter(ctx, fullLogDisplay, filteredLogDisplay, L"")
        end,
    }

    ctx.Components.Window({
        Name = NAME,
        OnLayout = function(window, children, child, index)
            local dimens = window:getDimensions()
            local padding = 12
            local spacing = 4
            local filterHeight = 24
            local contentWidth = dimens.x - (padding * 2)
            local logHeight = dimens.y - (padding * 2) - filterHeight - spacing

            if index == 1 then
                -- FilterInput
                child:addAnchor("topleft", window:getName(), "topleft", padding, padding)
                child:setDimensions(contentWidth, filterHeight)
            else
                -- Both LogDisplays occupy the same space below the filter
                child:addAnchor("bottomleft", children[1]:getName(), "topleft", 0, spacing)
                child:setDimensions(contentWidth, logHeight)
            end
        end,
        OnInitialize = function(self)
            self:setDimensions(800, 500)
            self:setAlpha(0.75)
            self:setChildren { filterInput, fullLogDisplay, filteredLogDisplay }
        end
    }):create(false)
end

---@param ctx Context
local function OnShutdown(ctx)
    ctx.Api.Window.Destroy(NAME)
    ctx.Api.TextLog.Destroy(FILTERED_LOG)
    local original = ctx.Components.Defaults.DebugWindow
    original:restore()
end

Mongbat.Mod {
    Name = "MongbatDebug",
    Path = "/src/mods/mongbat-debug",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
