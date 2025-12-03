Mongbat.Mod {
    Name = "MongbatObjectHandle",
    Path = "/src/mods/mongbat-object-handle",
    OnInitialize = function(context)
        local default = context.Components.Defaults.ObjectHandle
        local handles = {}

        ---@param handle ObjectHandle
        local function Label(handle)
            return context.Components.Label {
                Name = "ObjectHandleLabel" .. handle.id,
                Id = handle.id,
                OnInitialize = function(self)
                    self:setText(handle.name)
                end
            }
        end

        ---@param handle ObjectHandle
        local function Window(handle)
            return context.Components.Window {
                Name = "ObjectHandleWindow" .. handle.id,
                Id = handle.id,
                OnInitialize = function(self)
                    self:attachToObject()
                    self:setChildren {
                        Label(handle)
                    }
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
                function (v)
                    v:destroy()
                end
            )
        end
    end,
    OnShutdown = function(context)
    end
}