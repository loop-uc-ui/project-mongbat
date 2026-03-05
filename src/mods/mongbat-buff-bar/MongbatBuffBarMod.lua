local NAME_GOOD = "MongbatBuffBarGood"
local NAME_EVIL = "MongbatBuffBarEvil"

-- Default positions (can be dragged by the player)
local DEFAULT_GOOD_X = 451
local DEFAULT_GOOD_Y = 125
local DEFAULT_EVIL_X = 585
local DEFAULT_EVIL_Y = 125

-- Layout constants
local ICON_SIZE = 32
local TIMER_HEIGHT = 12
local ICON_GAP = 2
local PADDING = 4
local MIN_SIZE = ICON_SIZE + PADDING * 2

-- Names of the default AdvancedBuff container windows to hide/restore
local ADVANCED_BUFF_GOOD = "AdvancedBuffGood"
local ADVANCED_BUFF_EVIL = "AdvancedBuffEvil"

---@param context Context
local function OnInitialize(context)
    local Api = context.Api
    local Components = context.Components
    local Constants = context.Constants

    -- Suppress default systems
    local buffDebuffDefault = Components.Defaults.BuffDebuff
    local advancedBuffDefault = Components.Defaults.AdvancedBuff

    buffDebuffDefault:disable()
    advancedBuffDefault:disable()

    -- Hide any default AdvancedBuff windows already created before our mod loaded
    if Api.Window.DoesExist(ADVANCED_BUFF_GOOD) then
        Api.Window.SetShowing(ADVANCED_BUFF_GOOD, false)
    end
    if Api.Window.DoesExist(ADVANCED_BUFF_EVIL) then
        Api.Window.SetShowing(ADVANCED_BUFF_EVIL, false)
    end

    -- Load buff icon CSV data (will be a no-op if already loaded by the default system)
    Api.CSV.Load("Data/GameData/buffdata.csv", "BuffDataCSV")

    -- Buff classification tables (field reads pass through even when disabled)
    local buffDebuffProxy = buffDebuffDefault:getDefault()

    -- State
    local goodOrder = {}   -- array of buffIds (good/neutral)
    local evilOrder = {}   -- array of buffIds (evil)
    local buffEntries = {} -- buffId -> { iconView, timerView, timerSecs, hasTimer, nameVec, tooltipVec, isGood }
    local goodDirection = "H" -- "H"=horizontal, "V"=vertical
    local evilDirection = "H"
    local deltaTime = 0

    -- Determine if a buffId is a good/neutral buff
    local function isGoodBuff(buffId)
        return (buffDebuffProxy.Good and buffDebuffProxy.Good[buffId] == true)
            or (buffDebuffProxy.Neutral and buffDebuffProxy.Neutral[buffId] == true)
    end

    -- Get icon texture for a buff from the CSV via the framework wrapper
    local function getBuffTexture(buffId)
        return context.Data.BuffDebuff():getIconTexture(buffId)
    end

    -- Format a time in seconds as a readable string
    local function formatTimer(secs)
        if secs <= 0 then return L" " end
        local min = math.floor(secs / 60)
        if min > 60 then
            local h = math.floor(min / 60)
            return StringToWString(tostring(h) .. "h")
        elseif min > 0 then
            return StringToWString(tostring(min) .. "m")
        else
            return StringToWString(tostring(secs) .. "s")
        end
    end

    -- Resize a container window to fit its icon count
    local function resizeContainer(containerName, count, direction)
        local width, height
        if count == 0 then
            width = MIN_SIZE
            height = MIN_SIZE
        elseif direction == "V" then
            width = ICON_SIZE + PADDING * 2
            height = count * (ICON_SIZE + ICON_GAP) - ICON_GAP + PADDING * 2 + TIMER_HEIGHT + 4
        else
            width = count * (ICON_SIZE + ICON_GAP) - ICON_GAP + PADDING * 2
            height = ICON_SIZE + TIMER_HEIGHT + PADDING * 2 + 4
        end
        Api.Window.SetDimensions(containerName, width, height)
    end

    -- Reflow icon anchors for a container after add/remove
    local function reflowContainer(containerName, order, direction)
        for i = 1, #order do
            local buffId = order[i]
            local entry = buffEntries[buffId]
            if entry then
                entry.iconView:clearAnchors()
                entry.timerView:clearAnchors()

                if direction == "V" then
                    if i == 1 then
                        entry.iconView:addAnchor("topleft", containerName, "topleft", PADDING, PADDING)
                    else
                        local prevId = order[i - 1]
                        local prevEntry = buffEntries[prevId]
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
                        local prevId = order[i - 1]
                        local prevEntry = buffEntries[prevId]
                        if prevEntry then
                            entry.iconView:addAnchor(
                                "topleft", prevEntry.iconView:getName(), "topright", ICON_GAP, 0
                            )
                        end
                    end
                    entry.timerView:addAnchor("top", entry.iconView:getName(), "bottom", 0, 1)
                end
            end
        end
        resizeContainer(containerName, #order, direction)
    end

    -- Update the timer label for a single buff
    local function updateTimerLabel(buffId)
        local entry = buffEntries[buffId]
        if not entry then return end
        if entry.hasTimer then
            entry.timerView:setText(formatTimer(entry.timerSecs))
        else
            entry.timerView:setText(L" ")
        end
    end

    -- Create a buff icon view and its timer label inside a container
    local function createBuffIcon(buffId, containerName, nameVec, tooltipVec, timerSecs, hasTimer)
        local iconName = "MongbatBuffIcon" .. buffId
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
            OnMouseOver = function(_)
                local entry = buffEntries[buffId]
                if not entry then return end

                local nameStr = L""
                for i = 1, #entry.nameVec do
                    nameStr = nameStr .. entry.nameVec[i]
                end

                local bodyStr = L""
                for i = 1, #entry.tooltipVec do
                    bodyStr = bodyStr .. entry.tooltipVec[i]
                end

                local titleW = WindowUtils.translateMarkup(nameStr)
                local bodyW = WindowUtils.translateMarkup(bodyStr)

                if entry.hasTimer and entry.timerSecs > 0 then
                    bodyW = bodyW .. L"\n" .. towstring(tostring(entry.timerSecs)) .. L"s"
                end

                local itemData = {
                    windowName = iconName,
                    itemId = buffId,
                    itemType = Constants.ItemPropertyType.WStringData,
                    binding = L"",
                    title = titleW,
                    body = bodyW
                }
                Api.ItemProperties.SetActiveItem(itemData)
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

        -- Copy name and tooltip vectors so tooltip survives future event updates
        local nameVecCopy = {}
        for i = 1, #nameVec do
            nameVecCopy[i] = nameVec[i]
        end
        local tooltipVecCopy = {}
        for i = 1, #tooltipVec do
            tooltipVecCopy[i] = tooltipVec[i]
        end

        return {
            iconView = iconView,
            timerView = timerView,
            timerSecs = timerSecs,
            hasTimer = hasTimer,
            nameVec = nameVecCopy,
            tooltipVec = tooltipVecCopy
        }
    end

    -- Handle an OnUpdateBuffDebuff event
    local function onUpdateBuffDebuff(_, buffDebuff)
        local buffId = buffDebuff:getCurrentBuffId()
        if buffId == 0 then return end

        local good = isGoodBuff(buffId)
        local order = good and goodOrder or evilOrder
        local containerName = good and NAME_GOOD or NAME_EVIL
        local direction = good and goodDirection or evilDirection

        if buffDebuff:isBeingRemoved() then
            local entry = buffEntries[buffId]
            if entry then
                entry.iconView:destroy()
                entry.timerView:destroy()
                buffEntries[buffId] = nil
            end

            for i = #order, 1, -1 do
                if order[i] == buffId then
                    table.remove(order, i)
                    break
                end
            end

            reflowContainer(containerName, order, direction)
        else
            local nameVec = buffDebuff:getNameVector()
            local tooltipVec = buffDebuff:getTooltipVector()
            local timerSecs = buffDebuff:getTimerSeconds()
            local hasTimer = buffDebuff:hasTimer()

            if buffEntries[buffId] then
                -- Update existing entry (re-applied buff)
                local entry = buffEntries[buffId]
                entry.timerSecs = timerSecs
                entry.hasTimer = hasTimer
                -- Update cached name/tooltip vectors
                local nameVecCopy = {}
                for i = 1, buffDebuff:getNameVectorSize() do
                    nameVecCopy[i] = nameVec[i]
                end
                local tooltipVecCopy = {}
                for i = 1, buffDebuff:getTooltipVectorSize() do
                    tooltipVecCopy[i] = tooltipVec[i]
                end
                entry.nameVec = nameVecCopy
                entry.tooltipVec = tooltipVecCopy
                updateTimerLabel(buffId)
            else
                -- Create a new icon
                local nameVecSnap = {}
                for i = 1, buffDebuff:getNameVectorSize() do
                    nameVecSnap[i] = nameVec[i]
                end
                local tooltipVecSnap = {}
                for i = 1, buffDebuff:getTooltipVectorSize() do
                    tooltipVecSnap[i] = tooltipVec[i]
                end

                local entry = createBuffIcon(
                    buffId, containerName,
                    nameVecSnap, tooltipVecSnap,
                    timerSecs, hasTimer
                )
                buffEntries[buffId] = entry
                table.insert(order, buffId)
                reflowContainer(containerName, order, direction)
                updateTimerLabel(buffId)
            end
        end
    end

    -- Timer countdown: decrements per-second, updates labels, removes expired timers
    local function onUpdate(_, timePassed)
        deltaTime = deltaTime + timePassed
        if deltaTime < 1 then return end
        deltaTime = 0

        for buffId, entry in pairs(buffEntries) do
            if entry.hasTimer and entry.timerSecs > 0 then
                entry.timerSecs = entry.timerSecs - 1
                if entry.timerSecs < 0 then entry.timerSecs = 0 end
                updateTimerLabel(buffId)
            end
        end
    end

    -- Good bar: receives buff events and handles timer updates
    local goodWindow = Components.Window {
        Name = NAME_GOOD,
        OnInitialize = function(self)
            self:setDimensions(MIN_SIZE, MIN_SIZE)
            Api.Window.SetOffsetFromParent(NAME_GOOD, DEFAULT_GOOD_X, DEFAULT_GOOD_Y)
        end,
        OnUpdateBuffDebuff = onUpdateBuffDebuff,
        OnUpdate = onUpdate,
        OnRButtonUp = function(_)
            goodDirection = (goodDirection == "H") and "V" or "H"
            reflowContainer(NAME_GOOD, goodOrder, goodDirection)
        end
    }
    goodWindow:create(true)

    -- Evil bar: display container for debuffs
    local evilWindow = Components.Window {
        Name = NAME_EVIL,
        OnInitialize = function(self)
            self:setDimensions(MIN_SIZE, MIN_SIZE)
            Api.Window.SetOffsetFromParent(NAME_EVIL, DEFAULT_EVIL_X, DEFAULT_EVIL_Y)
        end,
        OnRButtonUp = function(_)
            evilDirection = (evilDirection == "H") and "V" or "H"
            reflowContainer(NAME_EVIL, evilOrder, evilDirection)
        end
    }
    evilWindow:create(true)
end

---@param context Context
local function OnShutdown(context)
    local Api = context.Api
    local Components = context.Components

    Api.Window.Destroy(NAME_GOOD)
    Api.Window.Destroy(NAME_EVIL)

    -- Destroy any dynamically created buff icons that may still be alive
    -- (the engine will remove them when their parent is destroyed, but be explicit)

    -- Restore the default systems
    Components.Defaults.BuffDebuff:restore()
    Components.Defaults.AdvancedBuff:restore()

    -- Show the default AdvancedBuff windows again
    if Api.Window.DoesExist(ADVANCED_BUFF_GOOD) then
        Api.Window.SetShowing(ADVANCED_BUFF_GOOD, true)
    end
    if Api.Window.DoesExist(ADVANCED_BUFF_EVIL) then
        Api.Window.SetShowing(ADVANCED_BUFF_EVIL, true)
    end
end

Mongbat.Mod {
    Name = "MongbatBuffBar",
    Path = "/src/mods/mongbat-buff-bar",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
