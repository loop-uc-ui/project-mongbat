-- MongbatQuickStatsMod.lua
-- Reimplements the default QuickStats system as a Mongbat mod.
-- Each label is an independent draggable window showing a player stat or item quantity.

local MAX_LABELS = 100
local LABEL_PREFIX = "MongbatQuickStat_"
local REFRESH_RATE = 1

local function OnInitialize(context)
    local default = context.Components.Defaults.QuickStats
    default:disable()

    -- Runtime state scoped to this initialization
    local labels = {}     -- [id] = settings table
    local delta = 0
    local pickingColor = nil   -- {windowName, colorKey}

    -- ====================================================================== --
    -- Persistence helpers
    -- ====================================================================== --

    local function labelKey(id)
        return LABEL_PREFIX .. id
    end

    local function saveLabel(id)
        local lab = labels[id]
        if not lab then return end
        local name = labelKey(id)
        local x, y = context.Api.Window.GetOffsetFromParent(name)
        context.Api.Interface.SaveNumber(name .. "_x", x)
        context.Api.Interface.SaveNumber(name .. "_y", y)
        if lab.attribute then
            context.Api.Interface.SaveNumber(name .. "_attribute", lab.attribute)
        else
            context.Api.Interface.DeleteSetting(name .. "_attribute")
        end
        if lab.objectType then
            context.Api.Interface.SaveNumber(name .. "_objectType", lab.objectType)
        else
            context.Api.Interface.DeleteSetting(name .. "_objectType")
        end
        context.Api.Interface.SaveNumber(name .. "_minQuantity", lab.minQuantity or -1)
        context.Api.Interface.SaveBoolean(name .. "_showIcon", lab.showIcon)
        context.Api.Interface.SaveBoolean(name .. "_showFrame", lab.showFrame)
        context.Api.Interface.SaveBoolean(name .. "_showName", lab.showName)
        context.Api.Interface.SaveBoolean(name .. "_showCap", lab.showCap)
        context.Api.Interface.SaveBoolean(name .. "_locked", lab.locked)
        context.Api.Interface.SaveColor(name .. "_bgColor", lab.bgColor)
        context.Api.Interface.SaveColor(name .. "_frameColor", lab.frameColor)
        context.Api.Interface.SaveColor(name .. "_nameColor", lab.nameColor)
        context.Api.Interface.SaveColor(name .. "_valueColor", lab.valueColor)
    end

    local function loadLabel(id)
        local name = labelKey(id)
        local bgColor = context.Api.Interface.LoadColor(name .. "_bgColor", nil)
        if not bgColor then
            return nil
        end
        local lab = {}
        lab.attribute  = context.Api.Interface.LoadNumber(name .. "_attribute", nil)
        lab.objectType = context.Api.Interface.LoadNumber(name .. "_objectType", nil)
        lab.minQuantity = context.Api.Interface.LoadNumber(name .. "_minQuantity", -1)
        lab.showIcon   = context.Api.Interface.LoadBoolean(name .. "_showIcon", true)
        lab.showFrame  = context.Api.Interface.LoadBoolean(name .. "_showFrame", true)
        lab.showName   = context.Api.Interface.LoadBoolean(name .. "_showName", true)
        lab.showCap    = context.Api.Interface.LoadBoolean(name .. "_showCap", false)
        lab.locked     = context.Api.Interface.LoadBoolean(name .. "_locked", false)
        lab.bgColor    = bgColor
        lab.frameColor = context.Api.Interface.LoadColor(name .. "_frameColor",
            { r = 255, g = 255, b = 255, a = 255 })
        lab.nameColor  = context.Api.Interface.LoadColor(name .. "_nameColor",
            { r = 255, g = 255, b = 255, a = 255 })
        lab.valueColor = context.Api.Interface.LoadColor(name .. "_valueColor",
            { r = 255, g = 200, b = 100, a = 255 })
        lab.x = context.Api.Interface.LoadNumber(name .. "_x", 200)
        lab.y = context.Api.Interface.LoadNumber(name .. "_y", 200)
        lab.blink = false
        return lab
    end

    local function deleteLabel(id)
        local name = labelKey(id)
        context.Api.Interface.DeleteSetting(name .. "_attribute")
        context.Api.Interface.DeleteSetting(name .. "_objectType")
        context.Api.Interface.DeleteSetting(name .. "_minQuantity")
        context.Api.Interface.DeleteSetting(name .. "_showIcon")
        context.Api.Interface.DeleteSetting(name .. "_showFrame")
        context.Api.Interface.DeleteSetting(name .. "_showName")
        context.Api.Interface.DeleteSetting(name .. "_showCap")
        context.Api.Interface.DeleteSetting(name .. "_locked")
        context.Api.Interface.DeleteSetting(name .. "_bgColor")
        context.Api.Interface.DeleteSetting(name .. "_frameColor")
        context.Api.Interface.DeleteSetting(name .. "_nameColor")
        context.Api.Interface.DeleteSetting(name .. "_valueColor")
        context.Api.Interface.DeleteSetting(name .. "_x")
        context.Api.Interface.DeleteSetting(name .. "_y")
        labels[id] = nil
    end

    local function getNextId()
        for i = 1, MAX_LABELS do
            if not labels[i] then
                return i
            end
        end
        return nil
    end

    -- ====================================================================== --
    -- Stat value helpers
    -- ====================================================================== --

    local function getStatValue(lab)
        if lab.objectType then
            local qty = 0
            local backPackItems = context.Api.Interface.GetBackPackItems()
            if backPackItems then
                for i = 1, #backPackItems do
                    local uid = backPackItems[i]
                    local info = context.Api.Items.GetObjectInfo(uid)
                    if info and info.objectType == lab.objectType then
                        qty = qty + (info.quantity or 0)
                    end
                end
            end
            return tostring(qty), "", ""
        end

        if not lab.attribute then
            return "?", "", ""
        end

        local csvWrapper = context.Data.PlayerStatsDataCSV(lab.attribute)
        local csvData = csvWrapper:getData()
        if not csvData then
            return "?", "", ""
        end

        local k = csvWrapper:getName()
        local curKey = k
        if k == "Health" or k == "Stamina" or k == "Mana" then
            curKey = "Current" .. k
        end

        local playerStatus = context.Data.PlayerStatus()
        local cur = playerStatus:getField(curKey)
        local value = tostring(cur or 0)

        local cap = ""
        local sep = ""
        if lab.showCap then
            local maxVal = playerStatus:getField("Max" .. k)
            if maxVal then
                cap = tostring(maxVal)
                sep = "/"
            end
        end

        return value, sep, cap
    end

    -- ====================================================================== --
    -- Blink helpers
    -- ====================================================================== --

    local function startBlink(id)
        local name = labelKey(id)
        local lab = labels[id]
        if not lab or lab.blink then return end
        lab.blink = true
        context.Api.Window.StartAlphaAnimation(name .. "Value",
            context.Constants.AnimationType.Loop, 0.3, 1.0, 1, false, 0, 0)
        context.Api.Window.StartAlphaAnimation(name .. "Name",
            context.Constants.AnimationType.Loop, 0.3, 1.0, 1, false, 0, 0)
    end

    local function stopBlink(id)
        local name = labelKey(id)
        local lab = labels[id]
        if not lab or not lab.blink then return end
        lab.blink = false
        context.Api.Window.StopAlphaAnimation(name .. "Value")
        context.Api.Window.StopAlphaAnimation(name .. "Name")
    end

    -- ====================================================================== --
    -- Warning threshold check
    -- ====================================================================== --

    local function checkWarning(id)
        local lab = labels[id]
        if not lab then return end
        local minQ = lab.minQuantity or -1

        if lab.objectType then
            if minQ == -1 then
                stopBlink(id)
                return
            end
            local valueStr, _, _ = getStatValue(lab)
            local qty = tonumber(valueStr) or 0
            if minQ >= qty then
                startBlink(id)
            else
                stopBlink(id)
            end
            return
        end

        if not lab.attribute then
            stopBlink(id)
            return
        end

        local csvWrapper = context.Data.PlayerStatsDataCSV(lab.attribute)
        local k = csvWrapper:getName()
        if k == "Weight" then
            local playerStatus = context.Data.PlayerStatus()
            local maxWeight = playerStatus:getField("MaxWeight") or 0
            local warnLevel = maxWeight - context.Api.HotbarSystem.GetWarningLevel()
            local curWeight = playerStatus:getField("Weight") or 0
            if curWeight >= warnLevel then
                startBlink(id)
            else
                stopBlink(id)
            end
        elseif minQ == -1 then
            stopBlink(id)
        else
            local valueStr, _, _ = getStatValue(lab)
            local qty = tonumber(valueStr) or 0
            if minQ >= qty then
                startBlink(id)
            else
                stopBlink(id)
            end
        end
    end

    -- ====================================================================== --
    -- Label window update
    -- ====================================================================== --

    local function updateLabelDisplay(id)
        local lab = labels[id]
        if not lab then return end
        local name = labelKey(id)
        if not context.Api.Window.DoesExist(name) then return end

        local value, sep, cap = getStatValue(lab)
        local valueText = value .. sep .. cap

        -- Name label
        local nameWin = name .. "Name"
        if lab.showName then
            context.Api.Window.SetShowing(nameWin, true)
            if lab.attribute then
                local csvWrapper = context.Data.PlayerStatsDataCSV(lab.attribute)
                local tid = csvWrapper:getTid()
                if tid and tid > 0 then
                    context.Api.Label.SetText(nameWin, context.Api.String.GetStringFromTid(tid))
                end
            elseif lab.objectType then
                local reagentTid = context.Api.Items.GetReagentTid(lab.objectType)
                if reagentTid then
                    context.Api.Label.SetText(nameWin, context.Api.String.GetStringFromTid(reagentTid))
                end
            end
            context.Api.Label.SetTextColor(nameWin, lab.nameColor)
        else
            context.Api.Window.SetShowing(nameWin, false)
        end

        -- Value label
        local valueWin = name .. "Value"
        context.Api.Label.SetText(valueWin, valueText)
        if not lab.blink then
            context.Api.Label.SetTextColor(valueWin, lab.valueColor)
        end

        -- Background
        local bgWin = name .. "Background"
        context.Api.Window.SetAlpha(bgWin, 0.8)
        context.Api.Window.SetColor(bgWin, lab.bgColor)

        -- Frame
        local frameWin = name .. "Frame"
        if lab.showFrame then
            context.Api.Window.SetShowing(frameWin, true)
            context.Api.Window.SetAlpha(frameWin, 0.8)
            context.Api.Window.SetColor(frameWin, lab.frameColor)
        else
            context.Api.Window.SetShowing(frameWin, false)
        end

        checkWarning(id)
    end

    -- ====================================================================== --
    -- Color picker helper
    -- ====================================================================== --

    local function openColorPicker(winName, colorKey)
        pickingColor = { winName, colorKey }
        context.Api.ColorPicker.Open(function()
            local color = context.Api.ColorPicker.GetSelectedColor()
            local wid = context.Api.Window.GetId(pickingColor[1])
            local lab = labels[wid]
            if lab then
                lab[pickingColor[2]] = color
                saveLabel(wid)
                updateLabelDisplay(wid)
            end
            context.Api.ColorPicker.Close()
        end)
    end

    -- ====================================================================== --
    -- Right-click context menu callback
    -- ====================================================================== --

    local function contextMenuCallback(returnCode, winName)
        local wid = context.Api.Window.GetId(winName)
        local lab = labels[wid]
        if not lab then return end

        if returnCode == "lock" then
            lab.locked = not lab.locked
        elseif returnCode == "showIcon" then
            lab.showIcon = not lab.showIcon
        elseif returnCode == "showFrame" then
            lab.showFrame = not lab.showFrame
        elseif returnCode == "showName" then
            lab.showName = not lab.showName
        elseif returnCode == "showCap" then
            lab.showCap = not lab.showCap
        elseif returnCode == "amtWarning" then
            context.Api.RenameWindow.Create({
                title = context.Api.String.GetStringFromTid(1155400),
                subtitle = context.Api.String.GetStringFromTid(1155401),
                callfunction = function(_, amount)
                    local n = tonumber(amount)
                    if n then
                        lab.minQuantity = n
                        stopBlink(wid)
                        saveLabel(wid)
                        updateLabelDisplay(wid)
                    end
                end,
                id = wid
            })
            return
        elseif returnCode == "destroy" then
            context.Api.Dialog.Create({
                windowName = winName,
                title = context.Api.String.GetStringFromTid(1155399),
                body = context.Api.String.GetStringFromTid(1155390),
                buttons = {
                    {
                        textTid = context.Api.Dialog.TID_OKAY,
                        callback = function()
                            if context.Api.Window.DoesExist(winName) then
                                context.Api.Window.Destroy(winName)
                            end
                            deleteLabel(wid)
                        end
                    },
                    { textTid = context.Api.Dialog.TID_CANCEL }
                }
            })
            return
        elseif returnCode == "bgColor" then
            openColorPicker(winName, "bgColor")
            return
        elseif returnCode == "frameColor" then
            openColorPicker(winName, "frameColor")
            return
        elseif returnCode == "nameColor" then
            openColorPicker(winName, "nameColor")
            return
        elseif returnCode == "valueColor" then
            openColorPicker(winName, "valueColor")
            return
        end

        saveLabel(wid)
        updateLabelDisplay(wid)
    end

    -- ====================================================================== --
    -- Label window factory
    -- ====================================================================== --

    local function createLabelWindow(id)
        local lab = labels[id]
        if not lab then return end
        local name = labelKey(id)

        local bgImage = context.Components.DynamicImage {
            Name = name .. "Background",
        }

        local frameImage = context.Components.DynamicImage {
            Name = name .. "Frame",
        }

        local nameLabel = context.Components.Label {
            Name = name .. "Name",
            OnInitialize = function(self)
                self:setDimensions(120, 20)
            end,
        }

        local valueLabel = context.Components.Label {
            Name = name .. "Value",
            OnInitialize = function(self)
                self:setDimensions(80, 20)
            end,
        }

        local window = context.Components.Window {
            Name = name,
            OnInitialize = function(self)
                self:setId(id)
                self:setDimensions(220, 26)
                context.Api.Window.SetOffsetFromParent(name, lab.x or 200, lab.y or 200)
                self:setChildren {
                    bgImage,
                    frameImage,
                    nameLabel,
                    valueLabel,
                }
            end,
            OnRButtonUp = function(self)
                local lid = self:getId()
                local lab2 = labels[lid]
                if not lab2 then return end

                local lockText = lab2.locked
                    and context.Api.String.GetStringFromTid(1111696)
                    or  context.Api.String.GetStringFromTid(1111697)
                context.Api.ContextMenu.CreateItemWithString(lockText, 0, "lock", name, false)
                context.Api.ContextMenu.CreateItemWithString(L" ", 0, "", nil, false)
                context.Api.ContextMenu.CreateItemWithString(
                    context.Api.String.GetStringFromTid(1155391), 0, "showIcon", name, lab2.showIcon)
                context.Api.ContextMenu.CreateItemWithString(
                    context.Api.String.GetStringFromTid(1155392), 0, "showFrame", name, lab2.showFrame)
                context.Api.ContextMenu.CreateItemWithString(
                    context.Api.String.GetStringFromTid(1155393), 0, "showName", name, lab2.showName)
                context.Api.ContextMenu.CreateItemWithString(
                    context.Api.String.GetStringFromTid(1155394), 0, "showCap", name, lab2.showCap)

                local showWarning = true
                if lab2.attribute then
                    local csvWrapper = context.Data.PlayerStatsDataCSV(lab2.attribute)
                    if csvWrapper:getName() == "Weight" then showWarning = false end
                end
                if showWarning then
                    local warnText = context.Api.String.ReplaceTokens(
                        context.Api.String.GetStringFromTid(1155478),
                        { towstring(lab2.minQuantity or -1) })
                    context.Api.ContextMenu.CreateItemWithString(warnText, 0, "amtWarning", name, false)
                end

                context.Api.ContextMenu.CreateItemWithString(L" ", 0, "", nil, false)
                context.Api.ContextMenu.CreateItemWithString(
                    context.Api.String.GetStringFromTid(1155395), 0, "bgColor", name, false)
                context.Api.ContextMenu.CreateItemWithString(
                    context.Api.String.GetStringFromTid(1155396), 0, "frameColor", name, false)
                context.Api.ContextMenu.CreateItemWithString(
                    context.Api.String.GetStringFromTid(1155397), 0, "nameColor", name, false)
                context.Api.ContextMenu.CreateItemWithString(
                    context.Api.String.GetStringFromTid(1155398), 0, "valueColor", name, false)
                context.Api.ContextMenu.CreateItemWithString(L" ", 0, "", nil, false)
                context.Api.ContextMenu.CreateItemWithString(
                    context.Api.String.GetStringFromTid(1155399), 0, "destroy", name, false)

                context.Api.ContextMenu.Activate(contextMenuCallback)
            end,
            OnLButtonDown = function(self)
                local lid = self:getId()
                local lab2 = labels[lid]
                if lab2 and not lab2.locked and not context.Api.Window.IsMoving(name) then
                    context.Api.Window.SetMoving(name, true)
                end
            end,
            OnLButtonUp = function(self)
                if context.Api.Window.IsMoving(name) then
                    context.Api.Window.SetMoving(name, false)
                    saveLabel(self:getId())
                end
            end,
        }

        window:create(true)
        updateLabelDisplay(id)
    end

    -- ====================================================================== --
    -- Public API exposed through QuickStats proxy
    -- ====================================================================== --

    local defaultQS = default:getDefault()

    defaultQS.DoesLabelExist = function(attributeId, isObject)
        for i = 1, MAX_LABELS do
            local lab = labels[i]
            if lab then
                if not isObject and lab.attribute == attributeId then
                    return i
                elseif isObject and lab.objectType == attributeId then
                    return i
                end
            end
        end
        return 0
    end

    defaultQS.GetId = function()
        return getNextId()
    end

    defaultQS.Initialize = function()
        for i = 1, MAX_LABELS do
            local lab = loadLabel(i)
            labels[i] = lab
            if lab then
                createLabelWindow(i)
            end
        end
    end

    defaultQS.Shutdown = function()
        for i = 1, MAX_LABELS do
            local name = labelKey(i)
            if labels[i] then
                saveLabel(i)
            end
            if context.Api.Window.DoesExist(name) then
                context.Api.Window.Destroy(name)
            end
        end
    end

    defaultQS.CreateLabel = function(attributeId, isObject)
        local existing = defaultQS.DoesLabelExist(attributeId, isObject)
        if existing > 0 then return end
        local id = getNextId()
        if not id then return end
        local lab = {
            showIcon    = true,
            showFrame   = true,
            showName    = true,
            showCap     = false,
            locked      = false,
            minQuantity = -1,
            blink       = false,
            bgColor     = { r = 0,   g = 0,   b = 0,   a = 200 },
            frameColor  = { r = 255, g = 255, b = 255, a = 255 },
            nameColor   = { r = 255, g = 255, b = 255, a = 255 },
            valueColor  = { r = 255, g = 200, b = 100, a = 255 },
            x           = 200 + (id - 1) * 10,
            y           = 200 + (id - 1) * 10,
        }
        if isObject then
            lab.objectType = attributeId
        else
            lab.attribute = attributeId
        end
        labels[id] = lab
        saveLabel(id)
        createLabelWindow(id)
    end

    -- ====================================================================== --
    -- Polling root window (invisible) for 1-second refresh
    -- ====================================================================== --

    context.Components.Window {
        Name = "MongbatQuickStatsRoot",
        OnInitialize = function(self)
            self:setDimensions(0, 0)
            self:setShowing(false)
        end,
        OnUpdate = function(self, timePassed)
            delta = delta + timePassed
            if delta >= REFRESH_RATE then
                delta = 0
                for i = 1, MAX_LABELS do
                    if labels[i] then
                        updateLabelDisplay(i)
                    end
                end
            end
        end,
    }:create(true)

    -- Initialize persisted labels (load settings and create windows for each saved label)
    defaultQS.Initialize()
end

local function OnShutdown(context)
    for i = 1, MAX_LABELS do
        local name = LABEL_PREFIX .. i
        if context.Api.Window.DoesExist(name) then
            context.Api.Window.Destroy(name)
        end
    end
    if context.Api.Window.DoesExist("MongbatQuickStatsRoot") then
        context.Api.Window.Destroy("MongbatQuickStatsRoot")
    end
    context.Components.Defaults.QuickStats:restore()
end

Mongbat.Mod {
    Name = "MongbatQuickStats",
    Path = "/src/mods/mongbat-quick-stats",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
