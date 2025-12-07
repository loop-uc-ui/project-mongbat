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
                    self:setDimensions(100, 20)
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
                    return Window(v)
                end
            )
        end

        default:getDefault().DestroyObjectHandles = function()
            context.Utils.Array.ForEach(
                createdHandles,
                function (window)
                    window:destroy()
                end
            )
            handles = {}
            createdHandles = {}
        end
    end,
    OnShutdown = function()
        handles = {}
        createdHandles = {}
    end,
    OnUpdate = function(context)
        --- We use the onUpdate callback to avoid horrendous stuttering
        --- when creating many handles at once.
        local handle = context.Utils.Array.Remove(handles, 1)

        if handle == nil then
            return
        else
            handle:create(true)
            context.Utils.Array.Add(createdHandles, handle)
        end
    end
}