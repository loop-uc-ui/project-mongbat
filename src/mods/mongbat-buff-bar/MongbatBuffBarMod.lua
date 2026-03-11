local Api        = Mongbat.Api
local Data       = Mongbat.Data
local Components = Mongbat.Components
local Constants  = Mongbat.Constants
local Utils      = Mongbat.Utils

-- Window name constants
local NAME_GOOD = "MongbatBuffBarGood"
local NAME_EVIL = "MongbatBuffBarEvil"

-- Persistence keys for direction settings
local KEY_GOOD_DIRECTION = "MongbatBuffBarGoodDirection"
local KEY_EVIL_DIRECTION = "MongbatBuffBarEvilDirection"

-- Default positions (player-draggable)
local DEFAULT_GOOD_X = 451
local DEFAULT_GOOD_Y = 125
local DEFAULT_EVIL_X = 585
local DEFAULT_EVIL_Y = 125

-- Layout constants
local ICON_SIZE    = 32
local TIMER_HEIGHT = 12
local ICON_GAP     = 2
local PADDING      = 4
local MIN_SIZE     = ICON_SIZE + PADDING * 2

-- Default container window names created by the default AdvancedBuff system
local ADVANCED_BUFF_GOOD = "AdvancedBuffGood"
local ADVANCED_BUFF_EVIL = "AdvancedBuffEvil"

local function OnInitialize()
    -- Suppress default buff systems
    local buffDebuffDefault   = Components.Defaults.BuffDebuff
    local advancedBuffDefault = Components.Defaults.AdvancedBuff

    buffDebuffDefault:disable()
    advancedBuffDefault:disable()

    -- Suppress any default windows already on-screen (SetShowing guards DoesExist internally)
    Api.Window.SetShowing(ADVANCED_BUFF_GOOD, false)
    Api.Window.SetShowing(ADVANCED_BUFF_EVIL, false)

    -- Load buff icon CSV (no-op if already loaded by the default system)
    Api.CSV.Load("Data/GameData/buffdata.csv", "BuffDataCSV")

    -- Proxy to classify buffs as good/neutral vs evil
    local buffDebuffProxy = buffDebuffDefault:getDefault()

    -- Persisted direction preferences ("H" or "V")
    local goodDirection = Api.Interface.LoadString(KEY_GOOD_DIRECTION, "H")
    local evilDirection = Api.Interface.LoadString(KEY_EVIL_DIRECTION, "H")

    -- Per-bar state captured by closures
    local goodOrder   = {}   ---@type integer[]
    local evilOrder   = {}   ---@type integer[]
    local goodEntries = {}   ---@type table<integer, {iconView:DynamicImage, timerView:Label, timerSecs:number, hasTimer:boolean, nameVec:table, tooltipVec:table}>
    local evilEntries = {}   ---@type table<integer, {iconView:DynamicImage, timerView:Label, timerSecs:number, hasTimer:boolean, nameVec:table, tooltipVec:table}>

    --- Returns true if the given buffId is a good or neutral buff.
    ---@param buffId integer
    ---@return boolean
    local function isGoodBuff(buffId)
        return (buffDebuffProxy.Good    and buffDebuffProxy.Good[buffId]    == true)
            or (buffDebuffProxy.Neutral and buffDebuffProxy.Neutral[buffId] == true)
    end

    --- Returns the icon texture name and UV coords for the given buffId via the CSV data.
    ---@param buffId integer
    ---@return string|nil, integer, integer
    local function getBuffTexture(buffId)
        return Data.BuffDebuff():getIconTexture(buffId)
    end

    --- Formats a duration in seconds as a readable wstring ("5s", "3m", "2h").
    ---@param secs number
    ---@return wstring
    local function formatTimer(secs)
        if secs <= 0 then return L" " end
        local min = math.floor(secs / 60)
        if min > 60 then
            return towstring(math.floor(min / 60)) .. L"h"
        elseif min > 0 then
            return towstring(min) .. L"m"
        else
            return towstring(secs) .. L"s"
        end
    end

    --- Resizes a container window to fit its current icon count and direction.
    ---@param containerName string
    ---@param count integer
    ---@param direction string "H" or "V"
    local function resizeContainer(containerName, count, direction)
        local w, h
        if count == 0 then
            w = MIN_SIZE
            h = MIN_SIZE
        elseif direction == "V" then
            w = ICON_SIZE + PADDING * 2
            h = count * (ICON_SIZE + ICON_GAP) - ICON_GAP + PADDING * 2 + TIMER_HEIGHT + 4
        else
            w = count * (ICON_SIZE + ICON_GAP) - ICON_GAP + PADDING * 2
            h = ICON_SIZE + TIMER_HEIGHT + PADDING * 2 + 4
        end
        Api.Window.SetDimensions(containerName, w, h)
    end

    --- Re-anchors all icons in a container after add/remove, then resizes the container.
    ---@param containerName string
    ---@param order integer[]
    ---@param entries table<integer, table>
    ---@param direction string "H" or "V"
    local function reflowContainer(containerName, order, entries, direction)
        Utils.Array.ForEach(order, function(buffId, i)
            local entry = entries[buffId]
            if not entry then return end

            entry.iconView:clearAnchors()
            entry.timerView:clearAnchors()

            if direction == "V" then
                if i == 1 then
                    entry.iconView:addAnchor("topleft", containerName, "topleft", PADDING, PADDING)
                else
                    local prevEntry = entries[order[i - 1]]
                    if prevEntry then
                        entry.iconView:addAnchor(
                            "topleft", prevEntry.iconView:getName(), "bottomleft", 0, ICON_GAP
                        )
                    end
                end
                entry.timerView:addAnchor("centerleft", entry.iconView:getName(), "centerright", 2, 0)
            else
                if i == 1 then
                    entry.iconView:addAnchor("topleft", containerName, "topleft", PADDING, PADDING)
                else
                    local prevEntry = entries[order[i - 1]]
                    if prevEntry then
                        entry.iconView:addAnchor(
                            "topleft", prevEntry.iconView:getName(), "topright", ICON_GAP, 0
                        )
                    end
                end
                entry.timerView:addAnchor("top", entry.iconView:getName(), "bottom", 0, 1)
            end
        end)
        resizeContainer(containerName, #order, direction)
    end

    --- Updates the timer label for a single buff entry.
    ---@param buffId integer
    ---@param entries table<integer, table>
    local function updateTimerLabel(buffId, entries)
        local entry = entries[buffId]
        if not entry then return end
        entry.timerView:setText(entry.hasTimer and formatTimer(entry.timerSecs) or L" ")
    end

    --- Creates a buff icon (DynamicImage + timer Label) inside the given container.
    ---@param buffId integer
    ---@param containerName string
    ---@param nameVec table
    ---@param tooltipVec table
    ---@param timerSecs number
    ---@param hasTimer boolean
    ---@param entries table<integer, table>
    ---@return table The new buff entry table.
    local function createBuffIcon(buffId, containerName, nameVec, tooltipVec, timerSecs, hasTimer, entries)
        local iconName  = "MongbatBuffIcon" .. buffId
        local timerName = iconName .. "Timer"

        local iconView = Components.DynamicImage {
            Name = iconName,
            OnInitialize = function(self)
                self:setDimensions(ICON_SIZE, ICON_SIZE)
                local texture, x, y = getBuffTexture(buffId)
                if texture then
                    self:setTexture(texture, x, y)
                end
            end,
            --- Show buff tooltip on mouse-over.
            OnMouseOver = function(_)
                local entry = entries[buffId]
                if not entry then return end

                local nameStr = L""
                Utils.Array.ForEach(entry.nameVec, function(part)
                    nameStr = nameStr .. part
                end)

                local bodyStr = L""
                Utils.Array.ForEach(entry.tooltipVec, function(part)
                    bodyStr = bodyStr .. part
                end)

                local titleW = Api.String.TranslateMarkup(nameStr)
                local bodyW  = Api.String.TranslateMarkup(bodyStr)

                if entry.hasTimer and entry.timerSecs > 0 then
                    bodyW = bodyW .. L"\n" .. towstring(entry.timerSecs) .. L"s"
                end

                Api.ItemProperties.SetActiveItem({
                    windowName = iconName,
                    itemId     = buffId,
                    itemType   = Constants.ItemPropertyType.WStringData,
                    binding    = L"",
                    title      = titleW,
                    body       = bodyW
                })
            end,
            OnMouseOverEnd = function(_)
                Api.ItemProperties.ClearMouseOverItem()
            end
        }
        iconView:create(true)
        iconView:onInitialize()
        iconView:setParent(containerName)

        local timerView = Components.Label {
            Name = timerName,
            OnInitialize = function(self)
                self:setDimensions(ICON_SIZE, TIMER_HEIGHT)
            end
        }
        timerView:create(true)
        timerView:onInitialize()
        timerView:setParent(containerName)

        return {
            iconView    = iconView,
            timerView   = timerView,
            timerSecs   = timerSecs,
            hasTimer    = hasTimer,
            nameVec     = Utils.Array.Copy(nameVec),
            tooltipVec  = Utils.Array.Copy(tooltipVec)
        }
    end

    --- Handles an OnUpdateBuffDebuff event for a specific container.
    --- Only processes buffIds that match the given classification predicate.
    ---@param buffDebuff BuffDebuffWrapper
    ---@param containerName string
    ---@param order integer[]
    ---@param entries table<integer, table>
    ---@param direction string "H" or "V"
    ---@param predicate fun(buffId: integer): boolean
    local function handleBuffUpdate(buffDebuff, containerName, order, entries, direction, predicate)
        local buffId = buffDebuff:getCurrentBuffId()
        if buffId == 0 then return end
        if not predicate(buffId) then return end

        if buffDebuff:isBeingRemoved() then
            local entry = entries[buffId]
            if entry then
                entry.iconView:destroy()
                entry.timerView:destroy()
                entries[buffId] = nil
            end
            local idx = Utils.Array.IndexOf(order, function(item) return item == buffId end)
            if idx ~= -1 then
                Utils.Array.Remove(order, idx)
            end
            reflowContainer(containerName, order, entries, direction)
        else
            local nameVec    = buffDebuff:getNameVector()
            local tooltipVec = buffDebuff:getTooltipVector()
            local timerSecs  = buffDebuff:getTimerSeconds()
            local hasTimer   = buffDebuff:hasTimer()

            if entries[buffId] then
                local entry = entries[buffId]
                entry.timerSecs   = timerSecs
                entry.hasTimer    = hasTimer
                entry.nameVec     = Utils.Array.Copy(nameVec)
                entry.tooltipVec  = Utils.Array.Copy(tooltipVec)
                updateTimerLabel(buffId, entries)
            else
                local entry = createBuffIcon(
                    buffId, containerName,
                    nameVec, tooltipVec, timerSecs, hasTimer, entries
                )
                entries[buffId] = entry
                Utils.Array.Add(order, buffId)
                reflowContainer(containerName, order, entries, direction)
                updateTimerLabel(buffId, entries)
            end
        end
    end

    --- Ticks timers for a set of buff entries and updates their labels.
    ---@param entries table<integer, table>
    local function tickTimers(entries)
        Utils.Table.ForEach(entries, function(buffId, entry)
            if entry.hasTimer and entry.timerSecs > 0 then
                entry.timerSecs = entry.timerSecs - 1
                if entry.timerSecs < 0 then entry.timerSecs = 0 end
                updateTimerLabel(buffId, entries)
            end
        end)
    end

    -- -----------------------------------------------------------------------
    -- Good buff bar
    -- OnUpdateBuffDebuff is the innermost handler for good/neutral buffs.
    -- OnUpdate ticks the timer labels each second.
    -- -----------------------------------------------------------------------
    local goodDelta = 0
    local goodWindow = Components.Window {
        Name = NAME_GOOD,
        OnInitialize = function(self)
            self:setDimensions(MIN_SIZE, MIN_SIZE)
            Api.Window.SetOffsetFromParent(NAME_GOOD, DEFAULT_GOOD_X, DEFAULT_GOOD_Y)
        end,
        --- Handles incoming good/neutral buff updates.
        OnUpdateBuffDebuff = function(_, buffDebuff)
            handleBuffUpdate(buffDebuff, NAME_GOOD, goodOrder, goodEntries, goodDirection, isGoodBuff)
        end,
        OnUpdate = function(_, timePassed)
            goodDelta = goodDelta + timePassed
            if goodDelta < 1 then return end
            goodDelta = 0
            tickTimers(goodEntries)
        end,
        OnRButtonUp = function(_)
            goodDirection = (goodDirection == "H") and "V" or "H"
            Api.Interface.SaveString(KEY_GOOD_DIRECTION, goodDirection)
            reflowContainer(NAME_GOOD, goodOrder, goodEntries, goodDirection)
        end
    }
    goodWindow:create(true)

    -- -----------------------------------------------------------------------
    -- Evil (debuff) bar
    -- OnUpdateBuffDebuff is the innermost handler for evil buffs.
    -- OnUpdate ticks the timer labels each second.
    -- -----------------------------------------------------------------------
    local evilDelta = 0
    local evilWindow = Components.Window {
        Name = NAME_EVIL,
        OnInitialize = function(self)
            self:setDimensions(MIN_SIZE, MIN_SIZE)
            Api.Window.SetOffsetFromParent(NAME_EVIL, DEFAULT_EVIL_X, DEFAULT_EVIL_Y)
        end,
        --- Handles incoming evil buff (debuff) updates.
        OnUpdateBuffDebuff = function(_, buffDebuff)
            handleBuffUpdate(buffDebuff, NAME_EVIL, evilOrder, evilEntries, evilDirection,
                function(id) return not isGoodBuff(id) end)
        end,
        OnUpdate = function(_, timePassed)
            evilDelta = evilDelta + timePassed
            if evilDelta < 1 then return end
            evilDelta = 0
            tickTimers(evilEntries)
        end,
        OnRButtonUp = function(_)
            evilDirection = (evilDirection == "H") and "V" or "H"
            Api.Interface.SaveString(KEY_EVIL_DIRECTION, evilDirection)
            reflowContainer(NAME_EVIL, evilOrder, evilEntries, evilDirection)
        end
    }
    evilWindow:create(true)
end

local function OnShutdown()
    Api.Window.Destroy(NAME_GOOD)
    Api.Window.Destroy(NAME_EVIL)

    -- Unload CSV data — mirrors default UI BuffDebuff.Shutdown() cleanup
    Api.CSV.Unload("BuffDataCSV")

    -- Restore the default buff systems
    Components.Defaults.BuffDebuff:restore()
    Components.Defaults.AdvancedBuff:restore()

    -- Re-show the default AdvancedBuff windows (SetShowing guards DoesExist internally)
    Api.Window.SetShowing(ADVANCED_BUFF_GOOD, true)
    Api.Window.SetShowing(ADVANCED_BUFF_EVIL, true)
end

Mongbat.Mod {
    Name         = "MongbatBuffBar",
    Path         = "/src/mods/mongbat-buff-bar",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown
}
