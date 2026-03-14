---@type Window[]
local handles = {}

local Api = Mongbat.Api
local Data = Mongbat.Data
local Utils = Mongbat.Utils
local Constants = Mongbat.Constants
local Components = Mongbat.Components

Mongbat.Mod {
    Name = "MongbatObjectHandle",
    Path = "/src/mods/mongbat-object-handle",
    OnInitialize = function()
        local default = Components.Defaults.ObjectHandle

        ---@param handle ObjectHandle
        local function Label(handle)
            return Components.Label {
                Name = "ObjectHandleLabel" .. handle.id,
                Id = handle.id,
                OnInitialize = function(self)
                    self.dimensions = {#handle.name * 12, 32}
                    self.text = handle.name
                    self:centerText()
                    local color = Constants.Colors.Notoriety[handle.notoriety]
                    self.textColor = color
                end
            }
        end

        ---@param handle ObjectHandle
        local function Window(handle)
            return Components.Window {
                Name = "ObjectHandleWindow" .. handle.id,
                Id = handle.id,
                OnInitialize = function(self)
                    self.dimensions = {#handle.name * 12 + 16, 32}
                    self:attachToObject()
                    self.children = {
                        Label(handle)
                    }
                    self:onMouseOverEnd()

                    if handle.isMobile then
                        local color = Constants.Colors.Notoriety[handle.notoriety]
                        self.frame.color = color
                    end

                    self.bindings = self:bindingsBuilder(function(bind)
                        bind:onMouseOver(function()
                            self.alpha = 1.0
                            self.layer = self:layerBuilder(function(l) return l:default() end)
                        end)
                        :onMouseOverEnd(function()
                            self.alpha = 0.7
                            self.layer = self:layerBuilder(function(l) return l:background() end)
                        end)
                        :onLButtonDblClk(function()
                            Api.UserAction.UseItem(self.id)
                        end)
                        :onLButtonUp(function()
                            if Data.Drag().draggingItem then
                                Api.Drag.DragToObject(self.id)
                            else
                                Api.Target.LeftClick(self.id)
                            end
                        end)
                        :onLButtonDown(function()
                            if handle.isMobile then
                                Components.Defaults.HealthBarManager
                                    .default
                                    .OnBeginDragHealthBar(handle.id)
                            end
                        end)
                    end)
                end,
                OnLayout = function (_, _, child, _)
                    child.anchors = child:anchorBuilder(function(a)
                        return { a:centerIn() }
                    end)
                end,
            }
        end

        default.default.CreateObjectHandles = function()
            handles = Utils.Table.MapToArray(
                Data.ObjectHandles().handles,
                function (_, v)
                    local window = Window(v)
                    window:create(true)
                    return window
                end
            )
        end

        default.default.DestroyObjectHandles = function()
            Utils.Array.ForEach(
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
