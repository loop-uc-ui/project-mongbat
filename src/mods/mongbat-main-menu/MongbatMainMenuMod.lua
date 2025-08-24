---@param context Context
---@return Button
local Button = function (context, text, onLButtonUp, onShown)
    return context.Views.Button {
        events = {
            OnLButtonUp = onLButtonUp,

            OnInitialize = function (self)
                self:setDimensions(130, 41)
                self:setText(text)
                if onShown ~= nil then
                    onShown(self)
                end
            end
        }
    }
end

---@param context Context
local UusCorpMainMenuWindow = function (context)
    return context.Views.Window {
        name = "UusCorpMainMenuWindow",
        events = {
            OnInitialize = function (self)
                self:setDimensions(214, 440)
                self:anchorToParentCenter()
                self:setChildren {
                    Button(
                        context,
                        3000128,
                        function ()
                            EventApi.broadcast(Events.logOut())
                        end,
                        ---@param button Button
                        function (button)
                            button:anchorToParentTop()
                        end
                    ),
                    Button(
                        context,
                        1077859,
                        function ()
                            InterfaceCore.OnExitGame()
                        end
                    ),
                    Button(
                        context,
                        L"Settings",
                        function ()
                            if self:doesExist() then
                                ToggleWindowByName("UusCorpSettingsWindow", "")
                                self:setShowing(false)
                            else
                                ToggleWindowByName("SettingsWindow", "")
                            end
                        end
                    ),
                    Button(
                        context,
                        L"Store",
                        function ()
                            EventApi.broadcast(Events.store())
                            self:setShowing(false)
                        end
                    ),
                    Button(
                        context,
                        L"Agents",
                        function ()
                            ToggleWindowByName("OrganizerWindow", "")
                            self:setShowing(false)
                        end
                    ),
                    Button(
                        context,
                        3000172,
                        function ()
                            ToggleWindowByName("MacroWindow", "")
                            self:setShowing(false)
                        end
                    ),
                    Button(
                        context,
                        1079812,
                        function ()
                            ToggleWindowByName("ActionsWindow", "")
                            self:setShowing(false)
                        end
                    ),
                    Button(
                        context,
                        1061037,
                        function ()
                            context.Api.Event.Broadcast(Events.help())
                            EventApi.broadcast(Events.help())
                            self:setShowing(false)
                        end
                    ),
                    Button(
                        context,
                        L"Debug",
                        function ()
                            ToggleWindowByName("DebugWindow", "")
                            self:setShowing(false)
                        end
                    )
                }
            end,
            OnRButtonUp = function (self)
                self:setShowing(false)
            end
        }
    }
end


MongbatMainMenuMod = Mongbat.Mod {
    Name = "MongbatMainMenu",
    Path = "/src/mods/mongbat-main-menu",
    OnInitialize = function (context)
        context.Components.Window {
            Name = "MongbatMainMenu",
            OnInitialize = function (self)
                Debug.Print("Window Init")
                self:setDimensions(100, 100)
            end
        }:create(true)
    end
}