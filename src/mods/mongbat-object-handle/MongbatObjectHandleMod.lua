---@type Window[]
local handles = {}

Mongbat.Mod {
    Name = "MongbatObjectHandle",
    Path = "/src/mods/mongbat-object-handle",
    OnInitialize = function(context)
        local default = context.Components.Defaults.ObjectHandle

        ---@param handle ObjectHandle
        local function Label(handle)
            return context.Components.Label {
                Name = "ObjectHandleLabel" .. handle.id,
                Id = handle.id,
                OnInitialize = function(self)
                    self:setDimensions(#handle.name * 12, 32)
                    self:setText(handle.name)
                    self:centerText()
                    local color = context.Constants.Colors.Notoriety[handle.notoriety]
                    self:setTextColor(color)
                end
            }
        end

        ---@param handle ObjectHandle
        local function Window(handle)
            return context.Components.Window {
                Name = "ObjectHandleWindow" .. handle.id,
                Id = handle.id,
                OnInitialize = function(self)
                    self:setDimensions(#handle.name * 12 + 16, 32)
                    self:attachToObject()
                    self:setChildren {
                        Label(handle)
                    }
                    self:onMouseOverEnd()

                    if handle.isMobile then
                        local color = context.Constants.Colors.Notoriety[handle.notoriety]
                        self:getFrame():setColor(color)
                    end
                end,
                OnLayout = function (_, _, child, _)
                    child:centerInWindow()
                end,
                OnMouseOver = function(self)
                    self:setAlpha(1.0):setLayer():default()
                end,
                OnMouseOverEnd = function(self)
                    self:setAlpha(0.7):setLayer():background()
                end,
                OnLButtonDblClk = function(self)
                    context.Api.UserAction.UseItem(self:getId())
                end,
                OnLButtonUp = function(self)
                    if context.Data.Drag():isDraggingItem() then
                        context.Api.Drag.DragToObject(self:getId())
                    else
                        context.Api.Target.LeftClick(self:getId())
                    end
                end,
                OnLButtonDown = function(self)
                    if handle.isMobile then
                        context.Components.Defaults.HealthBarManager
                            :getDefault()
                            .OnBeginDragHealthBar(self:getId())
                    end
                end
            }
        end

        default:getDefault().CreateObjectHandles = function()
            handles = context.Utils.Table.MapToArray(
                context.Data.ObjectHandles():getHandles(),
                function (_, v)
                    local window = Window(v)
                    window:create(true)
                    return window
                end
            )
        end

        default:getDefault().DestroyObjectHandles = function()
            context.Utils.Array.ForEach(
                handles,
                function (window)
                    window:destroy()
                end
            )
            handles = {}
        end
    end,
    OnShutdown = function()
        handles = {}
    end
}
