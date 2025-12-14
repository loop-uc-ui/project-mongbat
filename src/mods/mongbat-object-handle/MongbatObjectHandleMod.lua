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
                    self:clearAnchors()
                    self:setText(handle.name)
                    self:centerInWindow()
                    self:centerText()
                    self:setTextColor(
                        context.Constants.Colors.Notoriety[handle.notoriety]
                    )
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
                    if context.Api.Object.IsMobile(self:getId()) then
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
