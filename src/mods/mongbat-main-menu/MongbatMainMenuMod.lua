Mongbat.Mod {
    Name = "MongbatMainMenu",
    Path = "/src/mods/mongbat-main-menu",
    OnInitialize = function (context)
        local default = context.Components.Defaults.MainMenuWindow:asComponent()

        local Button = function (text, onLButtonUp, onShown)
            return context.Components.Button()
                :onLButtonUp(onLButtonUp)
                :onInitialize(function (self)
                    self:setDimensions(130, 41)
                    self:setText(text)
                    if onShown ~= nil then
                        onShown(self)
                    end
                end)
                :build()
        end

        local Window = function ()
            return context.Components.Window()
                :withName(default:getName())
                :onInitialize(function (self)
                    self:setDimensions(214, 440)
                    self:anchorToParentCenter()
                    self:setChildren {
                        Button(
                            3000128,
                            function ()
                                context.Api.Event.Logout()
                            end,
                            ---@param button Button
                            function (button)
                                button:anchorToParentTop()
                            end
                        ),
                        Button(
                            1077859,
                            function ()
                                context.Api.Event.ExitGame()
                            end
                        ),
                        Button(
                            L"Settings",
                            function ()
                                context.Api.Window.ToggleWindow("SettingsWindow")
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            L"Store",
                            function ()
                                context.Api.Event.OpenStore()
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            L"Agents",
                            function ()
                                context.Api.Window.ToggleWindow("OrganizerWindow")
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            3000172,
                            function ()
                                context.Api.Window.ToggleWindow("MacroWindow")
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            1079812,
                            function ()
                                context.Api.Window.ToggleWindow("ActionsWindow")
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            1061037,
                            function ()
                                context.Api.Event.OpenHelpMenu()
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            L"Debug",
                            function ()
                                context.Api.Window.ToggleWindow("DebugWindow")
                                self:setShowing(false)
                            end
                        )
                    }
                end)
                :onRButtonUp(function (self)
                    self:setShowing(false)
                end)
                :build()
        end

        default:destroy()
        Window():create(false)
    end
}