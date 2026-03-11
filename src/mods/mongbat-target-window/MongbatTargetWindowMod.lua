local NAME = "MongbatTargetWindow"
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants

local function OnInitialize()
    local targetWindow = Components.Defaults.TargetWindow
    targetWindow:asComponent():setShowing(false)
    targetWindow:disable()

    local targetId = 0

    local nameLabel = Components.Label {
        OnInitialize = function(self)
            self:centerText()
        end,
        OnUpdateMobileName = function(self, mobileName)
            self:setText(mobileName:getName())
            self:setTextColor(mobileName:getNotorietyColor())
        end
    }

    -- healthBar is the innermost interactive child: all user interactions
    -- (click to target, double-click to use, right-click for menu, hover for tooltip)
    -- are registered here rather than on the parent Window.
    local healthBar = Components.StatusBar {
        OnUpdateMobileStatus = function(self, mobileStatus)
            self:setCurrentValue(mobileStatus:getCurrentHealth())
            self:setMaxValue(mobileStatus:getMaxHealth())
            if not self._colorSet then
                self:setColor(Constants.Colors.HealhBar[1])
                self._colorSet = true
            end
        end,
        OnUpdateHealthBarColor = function(self, healthBarColor)
            self:setColor(healthBarColor:getVisualStateColor())
            self._colorSet = true
        end,
        OnLButtonUp = function()
            if Data.Drag():isDraggingItem() then
                Api.Drag.DragToObject(targetId)
            else
                Api.Target.LeftClick(targetId)
            end
        end,
        OnLButtonDblClk = function()
            if targetId ~= 0 then
                Api.UserAction.UseItem(targetId, false)
            end
        end,
        OnRButtonUp = function()
            if targetId ~= 0 then
                Api.ContextMenu.RequestMenu(targetId)
            end
        end,
        OnMouseOver = function(self)
            if targetId ~= 0 then
                Api.ItemProperties.SetActiveItem({
                    windowName = self:getName(),
                    itemId = targetId,
                    itemType = Constants.ItemPropertyType.Item
                })
            end
        end,
        OnMouseOverEnd = function()
            Api.ItemProperties.ClearMouseOverItem()
        end
    }

    Components.Window {
        Name = NAME,
        OnInitialize = function(self)
            self:setDimensions(220, 70)
            self:setShowing(false)
            self:setChildren {
                nameLabel,
                healthBar
            }
        end,
        OnUpdateCurrentTarget = function(self, currentTarget)
            if currentTarget:hasTarget() and currentTarget:isMobile() then
                local newId = currentTarget:getId()
                if newId ~= targetId then
                    targetId = newId
                    nameLabel:setId(targetId)
                    healthBar:setId(targetId)
                    healthBar._colorSet = false
                end
                self:setShowing(true)
            else
                self:setShowing(false)
                targetId = 0
            end
        end
    }:create(false)
end

local function OnShutdown()
    Api.Window.Destroy(NAME)
    local targetWindow = Components.Defaults.TargetWindow
    targetWindow:restore()
    targetWindow:asComponent():setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatTargetWindow",
    Path = "/src/mods/mongbat-target-window",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
