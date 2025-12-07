Mongbat.Mod {
    Name = "MongbatMainMenu",
    Path = "/src/mods/mongbat-main-menu",
    OnInitialize = function (context)
        local default = context.Components.Defaults.MainMenuWindow:asComponent()

        local function Button(text, onLButtonUp)
            return context.Components.Button {
                OnInitialize = function (self)
                    self:setText(text)
                end,
                OnLButtonUp = onLButtonUp,
            }
        end

        local function Window ()
            return context.Components.Window {
                Name = default:getName(),
                OnInitialize = function (self)
                    self:setDimensions(214, 440)
                    self:anchorToParentCenter()
                    self:setChildren {
                        Button(
                            3000128,
                            function ()
                                context.Api.Event.Logout()
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
                                Mongbat.ModManager.Window():create(true)
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
                end,
                OnRButtonUp = function (self)
                    self:setShowing(false)
                end
            }
        end

        default:destroy()
        Window():create(false)
    end,
    OnShutdown = function (context)
        local default = context.Components.Defaults.MainMenuWindow:asComponent()
        default:destroy()
    end
}
