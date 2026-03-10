local Api = Mongbat.Api
local Components = Mongbat.Components

Mongbat.Mod {
    Name = "MongbatMainMenu",
    Path = "/src/mods/mongbat-main-menu",
    OnInitialize = function ()
        local default = Components.Defaults.MainMenuWindow:asComponent()

        local function Button(text, onLButtonUp)
            return Components.Button {
                OnInitialize = function (self)
                    self:setText(text)
                end,
                OnLButtonUp = onLButtonUp,
            }
        end

        local function Window ()
            return Components.Scaffold {
                Name = default:getName(),
                Resizable = false,
                OnInitialize = function (self)
                    self:setDimensions(214, 440)
                    self:anchorToParentCenter()
                    self:setChildren {
                        Button(
                            3000128,
                            function ()
                                Api.Event.Logout()
                            end
                        ),
                        Button(
                            1077859,
                            function ()
                                Api.Event.ExitGame()
                            end
                        ),
                        Button(
                            L"Settings",
                            function ()
                                Api.Window.ToggleWindow("SettingsWindow")
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            L"Store",
                            function ()
                                Api.Event.OpenStore()
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            L"Agents",
                            function ()
                                Api.Window.ToggleWindow("OrganizerWindow")
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            3000172,
                            function ()
                                Api.Window.ToggleWindow("MacroWindow")
                                self:setShowing(false)
                            end
                        ),
                        Button(
                            1079812,
                            function ()
                                Api.Window.ToggleWindow("ActionsWindow")
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
                                Api.Window.ToggleWindow("MongbatDebugWindow")
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
    OnShutdown = function ()
        local default = Components.Defaults.MainMenuWindow:asComponent()
        default:destroy()
    end
}
