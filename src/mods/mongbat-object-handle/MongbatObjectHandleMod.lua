--[[
    Object Handle Mod - Reactive Version

    Displays floating name labels above objects in the world.
]]

---@type Window[]
local createdHandles = {}

Mongbat.Mod {
    Name = "MongbatObjectHandle",
    Path = "/src/mods/mongbat-object-handle",
    OnInitialize = function(context)
        local Reactive = context.Reactive
        local default = context.Components.Defaults.ObjectHandle

        ---@param handle ObjectHandle
        local function ObjectHandleUI(handle)
            return Reactive.Window {
                name = "ObjectHandleWindow" .. handle.id,
                id = handle.id,
                width = 100,
                height = 20,
                attachToObject = true,
                children = {
                    Reactive.Label {
                        key = "name",
                        text = handle.name
                    }
                }
            }
        end

        default:getDefault().CreateObjectHandles = function()
            local handles = context.Data.ObjectHandles():getHandles()

            for _, handle in pairs(handles) do
                -- Create a simple state for each handle (no reactivity needed, just structure)
                local state = Reactive.State {
                    id = handle.id,
                    name = handle.name
                }

                local app = Reactive.App(
                    function(s) return ObjectHandleUI(s) end,
                    state,
                    "ObjectHandleWindow" .. handle.id
                ):mount()

                table.insert(createdHandles, app)
            end
        end

        default:getDefault().DestroyObjectHandles = function()
            for _, app in ipairs(createdHandles) do
                app:unmount()
            end
            createdHandles = {}
        end
    end,
    OnShutdown = function()
        for _, app in ipairs(createdHandles) do
            app:unmount()
        end
        createdHandles = {}
    end
}
