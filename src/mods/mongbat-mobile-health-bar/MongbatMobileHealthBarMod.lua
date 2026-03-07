local BAR_WIDTH = 180
local BAR_HEIGHT = 72
local NAME_PREFIX = "MongbatMobileHealthBar_"
local PARTY_PREFIX = "MongbatPartyHealthBar_"
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants
local Utils = Mongbat.Utils

---@type table<integer, Window>
local bars = {}

---@type table<integer, { window: Window, mobileId: integer }>
local partyBars = {}

local function OnInitialize()
    local mhb = Components.Defaults.MobileHealthBar
    local phb = Components.Defaults.PartyHealthBar
    local hbm = Components.Defaults.HealthBarManager

    -- Disable the default health bar systems so their original functions
    -- become no-ops; we rawset our own replacements on the proxy tables below.
    mhb:disable()
    phb:disable()

    -- ------------------------------------------------------------------ --
    -- Child component factories
    -- ------------------------------------------------------------------ --

    local function NameLabel(mobileId)
        return Components.Label {
            Name = NAME_PREFIX .. "Name_" .. mobileId,
            Id = mobileId,
            OnInitialize = function(self)
                self:centerText()
            end,
            OnUpdateMobileStatus = function(self, mobileStatus)
                self:setText(mobileStatus:getName())
                self:setTextColor(mobileStatus:getNotorietyColor())
            end
        }
    end

    local function HealthBar(mobileId)
        return Components.StatusBar(
            {
                Name = NAME_PREFIX .. "Health_" .. mobileId,
                Id = mobileId,
                OnInitialize = function(self)
                    self:setColor(Constants.Colors.HealhBar[1])
                end,
                OnUpdateMobileStatus = function(self, mobileStatus)
                    local data = mobileStatus:getData()
                    self:setCurrentValue(data.CurrentHealth)
                    self:setMaxValue(data.MaxHealth)
                end,
                OnUpdateHealthBarColor = function(self, healthBarColor)
                    self:setColor(healthBarColor:getVisualStateColor())
                end
            },
            nil
        )
    end

    local function PartyNameLabel(partyIndex, mobileId)
        return Components.Label {
            Name = PARTY_PREFIX .. "Name_" .. partyIndex,
            Id = mobileId,
            OnInitialize = function(self)
                self:centerText()
            end,
            OnUpdateMobileStatus = function(self, mobileStatus)
                self:setText(mobileStatus:getName())
                self:setTextColor(mobileStatus:getNotorietyColor())
            end
        }
    end

    local function PartyHealthBar(partyIndex, mobileId)
        return Components.StatusBar(
            {
                Name = PARTY_PREFIX .. "Health_" .. partyIndex,
                Id = mobileId,
                OnInitialize = function(self)
                    self:setColor(Constants.Colors.HealhBar[1])
                end,
                OnUpdateMobileStatus = function(self, mobileStatus)
                    local data = mobileStatus:getData()
                    self:setCurrentValue(data.CurrentHealth)
                    self:setMaxValue(data.MaxHealth)
                end,
                OnUpdateHealthBarColor = function(self, healthBarColor)
                    self:setColor(healthBarColor:getVisualStateColor())
                end
            },
            nil
        )
    end

    -- ------------------------------------------------------------------ --
    -- Health bar lifecycle helpers
    -- ------------------------------------------------------------------ --

    local function createHealthBar(mobileId)
        local name = NAME_PREFIX .. mobileId

        if bars[mobileId] then
            -- Bar already exists: detach from world so it becomes free-floating
            -- (this is triggered by the HealthBarManager drag flow).
            Api.Window.DetachFromWorldObject(mobileId, name)
            return
        end

        local attachedToWorld = true

        local function detachFromWorld(self)
            if attachedToWorld then
                attachedToWorld = false
                Api.Window.DetachFromWorldObject(self:getId(), self:getName())
            end
        end

        local window = Components.Window {
            Name = name,
            Id = mobileId,
            Resizable = false,
            Snappable = false,
            OnInitialize = function(self)
                self:setDimensions(BAR_WIDTH, BAR_HEIGHT)
                self:attachToObject()
                self:setChildren {
                    NameLabel(mobileId),
                    HealthBar(mobileId)
                }
            end,
            OnShutdown = function(self)
                bars[self:getId()] = nil
            end,
            OnRButtonUp = function(self)
                Api.ContextMenu.RequestMenu(self:getId())
            end,
            OnLButtonUp = function(self)
                Api.Target.LeftClick(self:getId())
            end,
            OnUpdate = function(self)
                -- Detach from world when the user starts dragging the window.
                if attachedToWorld and self:isMoving() then
                    detachFromWorld(self)
                end
            end,
            OnEnableHealthBar = function(self)
                self:setShowing(true)
            end,
            OnDisableHealthBar = function(self)
                self:setShowing(false)
            end,
            OnEndHealthBarDrag = function(self)
                -- OnUpdate handles detach while dragging; this is a no-op.
            end
        }

        window:create(true)
        bars[mobileId] = window
    end

    local function closeHealthBar(mobileId)
        local window = bars[mobileId]
        if window then
            bars[mobileId] = nil
            window:destroy()
        end
    end

    local function hasHealthBar(mobileId)
        return bars[mobileId] ~= nil
    end

    -- ------------------------------------------------------------------ --
    -- Party health bar lifecycle helpers
    -- ------------------------------------------------------------------ --

    local function createPartyBar(mobileId, useDefaultPos)
        if mobileId == 0 then return end

        local partyIndex = hbm:getDefault().GetMemberIndex(mobileId)
        if partyIndex == 0 then return end

        -- Already showing the correct mobile at this slot.
        if partyBars[partyIndex] and partyBars[partyIndex].mobileId == mobileId then
            return
        end

        local name = PARTY_PREFIX .. partyIndex

        local window = Components.Window {
            Name = name,
            Id = mobileId,
            Resizable = false,
            Snappable = false,
            OnInitialize = function(self)
                self:setDimensions(BAR_WIDTH, BAR_HEIGHT)
                self:setChildren {
                    PartyNameLabel(partyIndex, mobileId),
                    PartyHealthBar(partyIndex, mobileId)
                }
            end,
            OnShutdown = function(self)
                local foundIdx = nil
                Utils.Table.ForEach(partyBars, function(idx, entry)
                    if entry.window == self then
                        foundIdx = idx
                    end
                end)
                if foundIdx then
                    partyBars[foundIdx] = nil
                end
            end,
            OnRButtonUp = function(self)
                Api.ContextMenu.RequestMenu(self:getId())
            end,
            OnLButtonUp = function(self)
                Api.Target.LeftClick(self:getId())
            end,
            OnEnableHealthBar = function(self)
                self:setShowing(true)
            end,
            OnDisableHealthBar = function(self)
                self:setShowing(false)
            end,
            OnEndHealthBarDrag = function(self)
                -- Bar is now free-floating after a HealthBarManager drag.
            end
        }

        window:create(true)
        partyBars[partyIndex] = { window = window, mobileId = mobileId }
    end

    local function closePartyBarByIndex(index)
        local entry = partyBars[index]
        if entry then
            partyBars[index] = nil
            entry.window:destroy()
        end
    end

    local function hasPartyBarByIndex(index)
        return partyBars[index] ~= nil
    end

    local function hasPartyBar(mobileId)
        return Utils.Table.Find(partyBars, function(_, entry)
            return entry.mobileId == mobileId
        end) ~= nil
    end

    local function refreshPartyBar(index, mobileId)
        local current = partyBars[index]
        if not current then return end

        if current.mobileId ~= mobileId then
            local oldMobileId = current.mobileId
            -- If the old mobile is no longer a party member, give it a
            -- free-floating mobile health bar.
            if oldMobileId ~= 0 and not hbm:getDefault().IsPartyMember(oldMobileId) then
                createHealthBar(oldMobileId)
            end
            closePartyBarByIndex(index)
            if mobileId ~= 0 then
                createPartyBar(mobileId, true)
            end
        end
    end

    -- ------------------------------------------------------------------ --
    -- Override MobileHealthBar functions via the proxy
    -- ------------------------------------------------------------------ --

    local mhbProxy = mhb:getDefault()
    rawset(mhbProxy, "CreateHealthBar", createHealthBar)
    rawset(mhbProxy, "CloseWindowByMobileId", closeHealthBar)
    rawset(mhbProxy, "HasWindow", hasHealthBar)

    -- ------------------------------------------------------------------ --
    -- Override PartyHealthBar functions via the proxy
    -- ------------------------------------------------------------------ --

    local phbProxy = phb:getDefault()
    rawset(phbProxy, "CreateHealthBar", createPartyBar)
    rawset(phbProxy, "CloseWindowByIndex", closePartyBarByIndex)
    rawset(phbProxy, "HasWindow", hasPartyBar)
    rawset(phbProxy, "HasWindowByIndex", hasPartyBarByIndex)
    rawset(phbProxy, "RefreshHealthBar", refreshPartyBar)
end

local function OnShutdown()
    local mhb = Components.Defaults.MobileHealthBar
    local phb = Components.Defaults.PartyHealthBar

    -- Remove our proxy overrides so the originals are visible again.
    local mhbProxy = mhb:getDefault()
    rawset(mhbProxy, "CreateHealthBar", nil)
    rawset(mhbProxy, "CloseWindowByMobileId", nil)
    rawset(mhbProxy, "HasWindow", nil)

    local phbProxy = phb:getDefault()
    rawset(phbProxy, "CreateHealthBar", nil)
    rawset(phbProxy, "CloseWindowByIndex", nil)
    rawset(phbProxy, "HasWindow", nil)
    rawset(phbProxy, "HasWindowByIndex", nil)
    rawset(phbProxy, "RefreshHealthBar", nil)

    -- Re-enable the default health bar systems.
    mhb:restore()
    phb:restore()

    -- Destroy all active health bar windows.
    local barSnapshot = bars
    bars = {}
    Utils.Table.ForEach(barSnapshot, function(_, window)
        window:destroy()
    end)

    local partyBarSnapshot = partyBars
    partyBars = {}
    Utils.Table.ForEach(partyBarSnapshot, function(_, entry)
        entry.window:destroy()
    end)
end

Mongbat.Mod {
    Name = "MongbatMobileHealthBar",
    Path = "/src/mods/mongbat-mobile-health-bar",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
