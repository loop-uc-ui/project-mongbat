---@type Window[]
local handles = {}
---@type Window[]
local createdHandles = {}

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
                    self:clearAnchors()
                    self:setText(handle.name)
                    self:centerInWindow()
                end
            }
        end

        ---@param handle ObjectHandle
        local function Window(handle)
            return context.Components.Window {
                Name = "ObjectHandleWindow" .. handle.id,
                Id = handle.id,
                OnInitialize = function(self)
                    self:setDimensions(100, 32)
                    self:attachToObject()
                    self:setChildren {
                        Label(handle)
                    }
                    self:onMouseOverEnd()
                end,
                OnMouseOver = function(self)
                    self:setAlpha(1.0):setLayer():overlay()
                end,
                OnMouseOverEnd = function(self)
                    self:setAlpha(0.5):setLayer():default()
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
