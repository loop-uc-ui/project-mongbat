local NAME = "MongbatTargetWindow"

---@param context Context
local function OnInitialize(context)
    local targetWindow = context.Components.Defaults.TargetWindow
    targetWindow:asComponent():setShowing(false)
    targetWindow:disable()

    local targetId = 0
    local nameLabel = nil
    local healthBar = nil

    nameLabel = context.Components.Label {
        OnInitialize = function(self)
            self:centerText()
        end,
        OnUpdateMobileName = function(self, mobileName)
            self:setText(mobileName:getName())
            self:setTextColor(mobileName:getNotorietyColor())
        end
    }

    healthBar = context.Components.StatusBar(
        {
            OnUpdateMobileStatus = function(self, mobileStatus)
                self:setCurrentValue(mobileStatus:getCurrentHealth())
                self:setMaxValue(mobileStatus:getMaxHealth())
                if not self._colorSet then
                    self:setColor(context.Constants.Colors.HealhBar[1])
                    self._colorSet = true
                end
            end,
            OnUpdateHealthBarColor = function(self, healthBarColor)
                self:setColor(healthBarColor:getVisualStateColor())
                self._colorSet = true
            end,
            OnLButtonUp = function()
                if context.Data.Drag():isDraggingItem() then
                    context.Api.Drag.DragToObject(targetId)
                else
                    context.Api.Target.LeftClick(targetId)
                end
            end
        },
        nil
    )

    context.Components.Window {
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
        end,
        OnLButtonDblClk = function()
            if targetId ~= 0 then
                context.Api.UserAction.UseItem(targetId, false)
            end
        end,
        OnRButtonUp = function()
            if targetId ~= 0 then
                context.Api.ContextMenu.RequestMenu(targetId)
            end
        end,
        OnMouseOver = function(self)
            if targetId ~= 0 then
                context.Api.ItemProperties.SetActiveItem({
                    windowName = self:getName(),
                    itemId = targetId,
                    itemType = context.Constants.ItemPropertyType.Item
                })
            end
        end,
        OnMouseOverEnd = function()
            context.Api.ItemProperties.ClearMouseOverItem()
        end
    }:create(false)
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.Destroy(NAME)
    local targetWindow = context.Components.Defaults.TargetWindow
    targetWindow:restore()
    targetWindow:asComponent():setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatTargetWindow",
    Path = "/src/mods/mongbat-target-window",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
