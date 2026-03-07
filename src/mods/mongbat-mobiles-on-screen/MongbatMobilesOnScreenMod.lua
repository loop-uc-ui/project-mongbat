local NAME = "MongbatMobilesOnScreenWindow"
local Api = Mongbat.Api
local Components = Mongbat.Components
local Utils = Mongbat.Utils

-- Saved original MobilesOnScreen lifecycle functions, restored in OnShutdown.
-- File-scope because they must survive between OnInitialize and OnShutdown.
local _savedMosInitialize = nil
local _savedMosShutdown = nil

-- Dockspot window names and their notoriety-based config
local DOCKSPOTS = {
    { name = "YellowDockspot", filterIndex = 8, enabledKey = "MobilesOnScreenYellowEnabled" },
    { name = "GreyDockspot",   filterIndex = 4, enabledKey = "MobilesOnScreenGreyEnabled" },
    { name = "BlueDockspot",   filterIndex = 2, enabledKey = "MobilesOnScreenBlueEnabled" },
    { name = "RedDockspot",    filterIndex = 7, enabledKey = "MobilesOnScreenRedEnabled" },
    { name = "GreenDockspot",  filterIndex = 3, enabledKey = "MobilesOnScreenGreenEnabled" },
    { name = "OrangeDockspot", filterIndex = 6, enabledKey = "MobilesOnScreenOrangeEnabled" },
}

-- TID constants matching default MobilesOnScreen
local TID_FILTER_NAMES = {
    [2]  = 1154822, -- Blue  (Innocent)
    [3]  = 1078866, -- Green (Friend)
    [4]  = 1154823, -- Grey  (CanAttack)
    [5]  = 1153802, -- Grey  (Criminal)
    [6]  = 1095164, -- Orange (Enemy)
    [7]  = 1154824, -- Red   (Murderer)
    [8]  = 3000509, -- Yellow (Invulnerable)
    [9]  = 1154825, -- Farm animals
    [10] = 1154826, -- Summons
}

---
--- Loads settings from persistent storage into the MobilesOnScreen data table.
---@param mos DefaultMobilesOnScreen
---@param api Api
---@param utils Utils
local function loadSettings(mos, api, utils)
    mos.DistanceSort = api.Interface.LoadBoolean("MobilesOnScreenDistanceSort", false)
    mos.UpdateLimit = api.Interface.LoadNumber("MobilesOnScreenUpdateLimit", 1)
    mos.windowOffset = api.Interface.LoadNumber("MobilesOnScreenOffset", 0)
    mos.locked = api.Interface.LoadBoolean("LockMobilesOnScreen", false)
    mos.Dockspotlocked = api.Interface.LoadBoolean("DockspotlockedMobilesOnScreen", false)
    mos.SavedFilter[1] = false -- Index 1 ("None") is always disabled; this matches the default UI's ReloadFilterSettings behavior.
    for i = 2, 10 do
        mos.SavedFilter[i] = api.Interface.LoadBoolean("MoSFilter" .. i, true)
    end
    utils.Array.ForEach(DOCKSPOTS, function(ds)
        if ds.name == "YellowDockspot" then
            mos.YellowEnabled = api.Interface.LoadBoolean(ds.enabledKey, false)
        elseif ds.name == "GreyDockspot" then
            mos.GreyEnabled = api.Interface.LoadBoolean(ds.enabledKey, false)
        elseif ds.name == "BlueDockspot" then
            mos.BlueEnabled = api.Interface.LoadBoolean(ds.enabledKey, false)
        elseif ds.name == "RedDockspot" then
            mos.RedEnabled = api.Interface.LoadBoolean(ds.enabledKey, false)
        elseif ds.name == "GreenDockspot" then
            mos.GreenEnabled = api.Interface.LoadBoolean(ds.enabledKey, false)
        elseif ds.name == "OrangeDockspot" then
            mos.OrangeEnabled = api.Interface.LoadBoolean(ds.enabledKey, false)
        end
    end)
end

---
--- Saves filter and slider settings to persistent storage.
---@param mos DefaultMobilesOnScreen
---@param api Api
local function saveSettings(mos, api)
    for i = 2, 10 do
        api.Interface.SaveBoolean("MoSFilter" .. i, mos.SavedFilter[i])
    end
    api.Interface.SaveBoolean("MobilesOnScreenDistanceSort", mos.DistanceSort)
    api.Interface.SaveNumber("MobilesOnScreenUpdateLimit", mos.UpdateLimit)
    api.Interface.SaveNumber("MobilesOnScreenOffset", mos.windowOffset)
    api.Interface.SaveBoolean("LockMobilesOnScreen", mos.locked)
    api.Interface.SaveBoolean("DockspotlockedMobilesOnScreen", mos.Dockspotlocked)
    api.Interface.SaveBoolean("MobilesOnScreenYellowEnabled", mos.YellowEnabled)
    api.Interface.SaveBoolean("MobilesOnScreenGreyEnabled", mos.GreyEnabled)
    api.Interface.SaveBoolean("MobilesOnScreenBlueEnabled", mos.BlueEnabled)
    api.Interface.SaveBoolean("MobilesOnScreenRedEnabled", mos.RedEnabled)
    api.Interface.SaveBoolean("MobilesOnScreenGreenEnabled", mos.GreenEnabled)
    api.Interface.SaveBoolean("MobilesOnScreenOrangeEnabled", mos.OrangeEnabled)
end

---
--- Creates or restores a dockspot window.  The dockspot uses the DockPointTemplate
--- defined in the default MobilesOnScreenWindow.xml, which provides the correct
--- child naming (ShowView) required by MobilesOnScreen.HandleAnchorsForCategory.
---@param dockspot table Entry from DOCKSPOTS
---@param mos DefaultMobilesOnScreen
---@param api Api
local function setupDockspot(dockspot, mos, api)
    local windowName = dockspot.name
    if not api.Window.DoesExist(windowName) then
        api.Window.CreateFromTemplate(windowName, "DockPointTemplate", "Root", false)
        api.Window.RestorePosition(windowName, false)
    end
    local isEnabled = false
    if windowName == "YellowDockspot" then
        isEnabled = mos.YellowEnabled
    elseif windowName == "GreyDockspot" then
        isEnabled = mos.GreyEnabled
    elseif windowName == "BlueDockspot" then
        isEnabled = mos.BlueEnabled
    elseif windowName == "RedDockspot" then
        isEnabled = mos.RedEnabled
    elseif windowName == "GreenDockspot" then
        isEnabled = mos.GreenEnabled
    elseif windowName == "OrangeDockspot" then
        isEnabled = mos.OrangeEnabled
    end
    api.Window.SetShowing(windowName, isEnabled)
end

---
--- Returns whether a dockspot is enabled on mos.
---@param dockspot table
---@param mos DefaultMobilesOnScreen
---@return boolean
local function isDockspotEnabled(dockspot, mos)
    local name = dockspot.name
    if name == "YellowDockspot" then return mos.YellowEnabled
    elseif name == "GreyDockspot" then return mos.GreyEnabled
    elseif name == "BlueDockspot" then return mos.BlueEnabled
    elseif name == "RedDockspot" then return mos.RedEnabled
    elseif name == "GreenDockspot" then return mos.GreenEnabled
    elseif name == "OrangeDockspot" then return mos.OrangeEnabled
    end
    return false
end

---
--- Enables or disables a dockspot on mos and saves the setting.
---@param dockspot table
---@param enabled boolean
---@param mos DefaultMobilesOnScreen
---@param api Api
local function setDockspotEnabled(dockspot, enabled, mos, api)
    local name = dockspot.name
    if name == "YellowDockspot" then mos.YellowEnabled = enabled
    elseif name == "GreyDockspot" then mos.GreyEnabled = enabled
    elseif name == "BlueDockspot" then mos.BlueEnabled = enabled
    elseif name == "RedDockspot" then mos.RedEnabled = enabled
    elseif name == "GreenDockspot" then mos.GreenEnabled = enabled
    elseif name == "OrangeDockspot" then mos.OrangeEnabled = enabled
    end
    api.Interface.SaveBoolean(dockspot.enabledKey, enabled)
    api.Window.SetShowing(name, enabled)
    mos.isDirty = true
end

local function OnInitialize()
    local mosDefault = Components.Defaults.MobilesOnScreen
    ---@type DefaultMobilesOnScreen
    local mos = mosDefault:getDefault()

    -- Save original lifecycle functions before overriding so they can be
    -- restored in OnShutdown (proxy __newindex writes through to _original).
    _savedMosInitialize = mos.Initialize
    _savedMosShutdown = mos.Shutdown

    -- Hide the default MobilesOnScreenWindow. The window stays alive so that
    -- its XML-registered OnUpdate handler continues to fire MobilesOnScreen.SlowUpdate
    -- every frame, keeping MobilesSort and health-bar management fully operational.
    mosDefault:asComponent():setShowing(false)

    -- Override Initialize so that on future UI reloads the default window is not
    -- rebuilt and our settings are loaded instead.
    mos.Initialize = function()
        loadSettings(mos, Api, Utils)
        Utils.Array.ForEach(DOCKSPOTS, function(ds)
            setupDockspot(ds, mos, Api)
        end)
        mosDefault:asComponent():setShowing(false)
        -- Restore our control window position so health bars re-anchor correctly.
        if Api.Window.DoesExist(NAME) then
            Api.Window.RestorePosition(NAME)
        end
    end

    -- Override Shutdown so that the default window does not attempt to save
    -- positions for windows we manage ourselves.
    mos.Shutdown = function()
        -- Settings are saved by our OnShutdown.
    end

    -- Load settings now (Initialize already ran before this mod loaded).
    loadSettings(mos, Api, Utils)

    -- Ensure dockspot windows exist and are in the correct show/hide state.
    Utils.Array.ForEach(DOCKSPOTS, function(ds)
        setupDockspot(ds, mos, Api)
    end)

    -- ------------------------------------------------------------------ --
    -- Context menu callback
    -- ------------------------------------------------------------------ --
    local function contextMenuCallback(returnCode, param)
        if returnCode == "Lock" then
            mos.locked = not mos.locked
            Api.Interface.SaveBoolean("LockMobilesOnScreen", mos.locked)
            Api.Window.SetMovable(NAME, not mos.locked)

        elseif returnCode == "Lockdockspot" then
            mos.Dockspotlocked = not mos.Dockspotlocked
            Api.Interface.SaveBoolean("DockspotlockedMobilesOnScreen", mos.Dockspotlocked)

        elseif returnCode == "ToggleSortDistance" then
            mos.DistanceSort = not mos.DistanceSort
            Api.Interface.SaveBoolean("MobilesOnScreenDistanceSort", mos.DistanceSort)

        elseif returnCode == "reset" then
            Api.Window.ClearAnchors(NAME)
            Api.Window.AddAnchor(NAME, "topleft", "Root", "topleft", 0, 100)

        elseif returnCode == "clear" then
            mos.Clear()

        elseif returnCode == "setfilter" then
            Api.RenameWindow.Create({
                title    = Api.String.GetStringFromTid(1062476),
                subtitle = Api.String.GetStringFromTid(1154851),
                callfunction = mos.SetFilter,
                id = 2
            })

        elseif returnCode == "addfilter" then
            Api.RenameWindow.Create({
                title    = Api.String.GetStringFromTid(1062476),
                subtitle = Api.String.GetStringFromTid(1154851),
                callfunction = mos.SetFilter,
                id = 3
            })

        elseif returnCode == "removefilter" then
            mos.STRFilter = L""

        else
            -- Dockspot toggle return codes: "<name>On" / "<name>Off"
            Utils.Array.ForEach(DOCKSPOTS, function(ds)
                local baseName = string.gsub(ds.name, "Dockspot", "")
                local lower = string.lower(baseName)
                if returnCode == lower .. "DockspotOn" then
                    setDockspotEnabled(ds, true, mos, Api)
                    -- Restore saved position; if no saved position the dockspot
                    -- stays at whatever position it currently holds.
                    Api.Window.RestorePosition(ds.name, false)
                elseif returnCode == lower .. "DockspotOff" then
                    setDockspotEnabled(ds, false, mos, Api)
                end
            end)

            -- Filter checkbox toggles: "filter<i>"
            for i = 2, 10 do
                if returnCode == "filter" .. i then
                    mos.SavedFilter[i] = not mos.SavedFilter[i]
                    Api.Interface.SaveBoolean("MoSFilter" .. i, mos.SavedFilter[i])
                    mos.isDirty = true
                end
            end
        end
    end

    -- ------------------------------------------------------------------ --
    -- Context menu builder
    -- ------------------------------------------------------------------ --
    local function showContextMenu()
        -- Show/hide toggle hint
        if mos.DistanceSort then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154829), 0, "ToggleSortDistance", 1, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154830), 0, "ToggleSortDistance", 1, false)
        end

        -- Lock / unlock
        if mos.locked then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1111696), 0, "Lock", 1, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1111697), 0, "Lock", 1, false)
        end

        -- Dockspot lock
        local dockLockDisabled = 0
        if not mos.GetVisible(true) then dockLockDisabled = 1 end
        if mos.Dockspotlocked then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154831), dockLockDisabled, "Lockdockspot", 1, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154832), dockLockDisabled, "Lockdockspot", 1, false)
        end

        -- Per-dockspot toggles
        -- Yellow
        local yellowDisabled = 0
        if mos.SavedFilter[8] == false then yellowDisabled = 1 end
        if not mos.YellowEnabled then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154833), yellowDisabled, "yellowDockspotOn", 2, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154834), yellowDisabled, "yellowDockspotOff", 2, false)
        end

        -- Grey
        local greyDisabled = 0
        if mos.SavedFilter[4] == false and mos.SavedFilter[5] == false then greyDisabled = 1 end
        if not mos.GreyEnabled then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154835), greyDisabled, "greyDockspotOn", 2, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154836), greyDisabled, "greyDockspotOff", 2, false)
        end

        -- Blue
        local blueDisabled = 0
        if mos.SavedFilter[2] == false then blueDisabled = 1 end
        if not mos.BlueEnabled then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154837), blueDisabled, "blueDockspotOn", 2, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154838), blueDisabled, "blueDockspotOff", 2, false)
        end

        -- Red
        local redDisabled = 0
        if mos.SavedFilter[7] == false then redDisabled = 1 end
        if not mos.RedEnabled then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154839), redDisabled, "redDockspotOn", 2, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154840), redDisabled, "redDockspotOff", 2, false)
        end

        -- Green
        local greenDisabled = 0
        if mos.SavedFilter[3] == false then greenDisabled = 1 end
        if not mos.GreenEnabled then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154841), greenDisabled, "greenDockspotOn", 2, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154842), greenDisabled, "greenDockspotOff", 2, false)
        end

        -- Orange
        local orangeDisabled = 0
        if mos.SavedFilter[6] == false then orangeDisabled = 1 end
        if not mos.OrangeEnabled then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154843), orangeDisabled, "orangeDockspotOn", 2, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154844), orangeDisabled, "orangeDockspotOff", 2, false)
        end

        -- Notoriety filters (2-10)
        Api.ContextMenu.CreateLuaItem(L"", 0, "nil", 2, false)
        for i = 2, 10 do
            local filterName = Api.String.GetStringFromTid(TID_FILTER_NAMES[i])
            local label
            if mos.SavedFilter[i] then
                label = L"[x] " .. filterName
            else
                label = L"[ ] " .. filterName
            end
            Api.ContextMenu.CreateLuaItem(label, 0, "filter" .. i, 2, false)
        end

        -- Name filter
        Api.ContextMenu.CreateLuaItem(L"", 0, "nil", 2, false)
        if mos.STRFilter == L"" or mos.STRFilter == "" then
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1062476), 0, "setfilter", 2, false)
        else
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154850), 0, "addfilter", 2, false)
            Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154849), 0, "removefilter", 2, false)
        end

        -- Utilities
        Api.ContextMenu.CreateLuaItem(L"", 0, "nil", 2, false)
        Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154847), 0, "reset", 2, false)
        Api.ContextMenu.CreateLuaItem(Api.String.GetStringFromTid(1154848), 0, "clear", 2, false)

        Api.ContextMenu.ActivateLua(contextMenuCallback)
    end

    -- ------------------------------------------------------------------ --
    -- Build our compact Mongbat control window
    -- ------------------------------------------------------------------ --
    Components.Window {
        Name = NAME,
        OnInitialize = function(self)
            self:setDimensions(190, 37)
            -- Restore saved position; fall back to same default as the original window.
            if not Api.Window.CanRestorePosition(NAME) then
                Api.Window.AddAnchor(NAME, "topleft", "Root", "topleft", 0, 100)
            else
                Api.Window.RestorePosition(NAME, false)
            end
            Api.Window.SetMovable(NAME, not mos.locked)

            -- Anchor the invisible MobilesOnScreenWindow to follow our control panel.
            -- Health bars (Root-level windows) are anchored to MobilesOnScreenWindowShowView
            -- which is a child of MobilesOnScreenWindow, so moving our panel repositions them.
            Api.Window.ClearAnchors("MobilesOnScreenWindow")
            Api.Window.AddAnchor("MobilesOnScreenWindow", "topleft", NAME, "topleft", 0, 37)

            self:setChildren {
                -- Label
                Components.Label {
                    OnInitialize = function(label)
                        label:setText(Api.String.GetStringFromTid(1075672))
                        label:setDimensions(140, 20)
                        Api.Window.AddAnchor(label:getName(), "center", NAME, "center", 0, 0)
                    end
                },
                -- Toggle show/hide button
                Components.Button {
                    OnInitialize = function(btn)
                        btn:setDimensions(30, 30)
                        Api.Window.AddAnchor(btn:getName(), "right", NAME, "right", -5, 0)
                    end,
                    OnLButtonUp = function(btn)
                        if mos.Hidden then
                            mos.ShowPet()
                        else
                            mos.HidePet()
                        end
                    end,
                },
            }
        end,
        OnRButtonUp = function(self)
            showContextMenu()
        end,
    }:create(true)
end

local function OnShutdown()
    local mosDefault = Components.Defaults.MobilesOnScreen
    local mos = mosDefault:getDefault()

    -- Save positions and settings
    if Api.Window.DoesExist(NAME) then
        Api.Window.SavePosition(NAME)
    end
    if Api.Window.DoesExist("MobilesOnScreenWindow") then
        Api.Window.SavePosition("MobilesOnScreenWindow")
    end
    Utils.Array.ForEach(DOCKSPOTS, function(ds)
        if Api.Window.DoesExist(ds.name) and isDockspotEnabled(ds, mos) then
            Api.Window.SavePosition(ds.name)
        end
    end)
    saveSettings(mos, Api)

    -- Restore overridden lifecycle functions before restoring the default window,
    -- so that future MobilesOnScreen.Initialize / Shutdown calls work correctly.
    if _savedMosInitialize then
        mos.Initialize = _savedMosInitialize
        _savedMosInitialize = nil
    end
    if _savedMosShutdown then
        mos.Shutdown = _savedMosShutdown
        _savedMosShutdown = nil
    end

    -- Destroy our control window
    Api.Window.Destroy(NAME)

    -- Restore the default MobilesOnScreen window
    mosDefault:restore()
    mosDefault:asComponent():setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatMobilesOnScreen",
    Path = "/src/mods/mongbat-mobiles-on-screen",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
