local MAX_MEMBERS = 10
local MANAGER_NAME = "MongbatPartyHealthBarManager"

local WINDOW_WIDTH = 175
local WINDOW_HEIGHT = 65
local LABEL_HEIGHT = 18
local BAR_HEIGHT = 6
local BAR_GAP = 3
local MARGIN = 8
local CLOSE_SIZE = 14

--- Custom layout: positions name label, three stat bars, and close button
--- precisely within the compact party bar window.
---@param window Window
---@param children View[]
---@param child View
---@param index integer
local function PartyBarLayout(window, children, child, index)
    local wName = window:getName()
    child:clearAnchors()
    if index == 1 then
        -- Name label: top-left, leaving room for close button on the right
        child:addAnchor("topleft", wName, "topleft", MARGIN, MARGIN)
        child:setDimensions(WINDOW_WIDTH - MARGIN * 2 - CLOSE_SIZE - 4, LABEL_HEIGHT)
    elseif index == 2 then
        -- Health bar
        local y = MARGIN + LABEL_HEIGHT + BAR_GAP
        child:addAnchor("topleft", wName, "topleft", MARGIN, y)
        child:setDimensions(WINDOW_WIDTH - MARGIN * 2, BAR_HEIGHT)
    elseif index == 3 then
        -- Mana bar
        local y = MARGIN + LABEL_HEIGHT + BAR_GAP + BAR_HEIGHT + BAR_GAP
        child:addAnchor("topleft", wName, "topleft", MARGIN, y)
        child:setDimensions(WINDOW_WIDTH - MARGIN * 2, BAR_HEIGHT)
    elseif index == 4 then
        -- Stamina bar
        local y = MARGIN + LABEL_HEIGHT + BAR_GAP + (BAR_HEIGHT + BAR_GAP) * 2
        child:addAnchor("topleft", wName, "topleft", MARGIN, y)
        child:setDimensions(WINDOW_WIDTH - MARGIN * 2, BAR_HEIGHT)
    elseif index == 5 then
        -- Close button: top-right corner
        child:addAnchor("topright", wName, "topright", -MARGIN, MARGIN)
        child:setDimensions(CLOSE_SIZE, CLOSE_SIZE)
    end
end

---@param context Context
local function OnInitialize(context)
    local Api = context.Api
    local Data = context.Data
    local Constants = context.Constants
    local Components = context.Components

    local partyHealthBar = Components.Defaults.PartyHealthBar
    partyHealthBar:disable()

    local memberIds = {}
    local memberWindows = {}
    for i = 1, MAX_MEMBERS do
        memberIds[i] = 0
        memberWindows[i] = nil
    end

    --- Creates a single party health bar window for the given slot and member.
    ---@param slotIndex integer Party slot index (1–10)
    ---@param memberId integer Mobile ID of the party member
    local function createBar(slotIndex, memberId)
        local barName = "MongbatPartyHealthBar_" .. slotIndex

        local nameLabel = Components.Label {
            OnInitialize = function(self)
                self:setId(memberId)
            end,
            OnUpdateMobileName = function(self, mobileName)
                self:setText(mobileName:getName())
            end,
            OnUpdateMobileStatus = function(self, mobileStatus)
                self:setTextColor(mobileStatus:getNotorietyColor())
            end
        }

        local healthBar = Components.StatusBar {
            OnInitialize = function(self)
                self:setColor(Constants.Colors.HealhBar[1])
                self:setId(memberId)
            end,
            OnUpdateMobileStatus = function(self, mobileStatus)
                self:setCurrentValue(mobileStatus:getCurrentHealth())
                self:setMaxValue(mobileStatus:getMaxHealth())
            end,
            OnUpdateHealthBarColor = function(self, healthBarColor)
                self:setColor(healthBarColor:getVisualStateColor())
            end
        }

        local manaBar = Components.StatusBar {
            OnInitialize = function(self)
                self:setColor(Constants.Colors.Blue)
                self:setId(memberId)
            end,
            OnUpdateMobileStatus = function(self, mobileStatus)
                self:setCurrentValue(mobileStatus:getCurrentMana())
                self:setMaxValue(mobileStatus:getMaxMana())
            end
        }

        local staminaBar = Components.StatusBar {
            OnInitialize = function(self)
                self:setColor(Constants.Colors.YellowDark)
                self:setId(memberId)
            end,
            OnUpdateMobileStatus = function(self, mobileStatus)
                self:setCurrentValue(mobileStatus:getCurrentStamina())
                self:setMaxValue(mobileStatus:getMaxStamina())
            end
        }

        local closeButton = Components.Button {
            OnInitialize = function(self)
                self:setText(L"\xD7")
            end,
            OnLButtonUp = function(self)
                memberIds[slotIndex] = 0
                memberWindows[slotIndex] = nil
                Api.Window.Destroy(barName)
            end
        }

        local window = Components.Window {
            Name = barName,
            Resizable = false,
            OnLayout = PartyBarLayout,
            OnInitialize = function(self)
                self:setDimensions(WINDOW_WIDTH, WINDOW_HEIGHT)
                self:setId(memberId)
                self:setChildren({ nameLabel, healthBar, manaBar, staminaBar, closeButton })
                -- Default stacking position: two columns of five, starting at y=110
                local col = math.floor((slotIndex - 1) / 5)
                local row = (slotIndex - 1) % 5
                local x = col * WINDOW_WIDTH
                local y = 110 + row * WINDOW_HEIGHT
                Api.Window.SetOffsetFromParent(barName, x, y)
            end,
            OnLButtonUp = function(self)
                if Data.Drag():isDraggingItem() then
                    Api.Drag.DragToObject(self:getId())
                else
                    Api.Target.LeftClick(self:getId())
                end
            end,
            OnRButtonUp = function(self)
                Api.ContextMenu.RequestMenu(self:getId())
            end
        }

        window:create(true)
        memberWindows[slotIndex] = window
    end

    --- Destroys the party bar for the given slot index.
    ---@param slotIndex integer
    local function destroyBar(slotIndex)
        Api.Window.Destroy("MongbatPartyHealthBar_" .. slotIndex)
        memberWindows[slotIndex] = nil
    end

    --- Reconciles the live party roster with displayed bars.
    --- Creates bars for new members and destroys bars for removed members.
    ---@param partyData PartyMemberWrapper
    local function refreshParty(partyData)
        local numMembers = partyData:getNumMembers()
        for i = 1, MAX_MEMBERS do
            local memberId = 0
            if i <= numMembers then
                memberId = partyData:getMemberId(i)
            end
            if memberIds[i] ~= memberId then
                if memberIds[i] ~= 0 then
                    destroyBar(i)
                end
                memberIds[i] = memberId
                if memberId ~= 0 then
                    createBar(i, memberId)
                end
            end
        end
    end

    -- Hidden manager window that receives OnUpdatePartyMember events and
    -- coordinates creation/destruction of the individual health bar windows.
    Components.Window {
        Name = MANAGER_NAME,
        Resizable = false,
        Snappable = false,
        OnUpdatePartyMember = function(self, partyData)
            refreshParty(partyData)
        end
    }:create(false)
end

---@param context Context
local function OnShutdown(context)
    for i = 1, MAX_MEMBERS do
        context.Api.Window.Destroy("MongbatPartyHealthBar_" .. i)
    end
    context.Api.Window.Destroy(MANAGER_NAME)

    local partyHealthBar = context.Components.Defaults.PartyHealthBar
    partyHealthBar:restore()
end

Mongbat.Mod {
    Name = "MongbatPartyHealthBar",
    Path = "/src/mods/mongbat-party-health-bar",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
