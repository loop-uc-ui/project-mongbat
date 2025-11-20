---@param context Context
---@return Button
local Button = function (context, text, onLButtonUp, onShown)
    return context.Components.Button {
        OnLButtonUp = onLButtonUp,

        OnInitialize = function (self)
            self:setDimensions(130, 41)
            self:setText(text)
            if onShown ~= nil then
                onShown(self)
            end
        end
    }
end

---@param context Context
local Window = function (context)
    return context.Components.Window {
        Name = "MainMenuWindow",
        ---@param self Window
        OnInitialize = function (self)
            self:setDimensions(214, 440)
            self:anchorToParentCenter()
            self:setChildren {
                Button(
                    context,
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
                    context,
                    1077859,
                    function ()
                        context.Api.Event.ExitGame()
                    end
                ),
                Button(
                    context,
                    L"Settings",
                    function ()
                        context.Api.Window.ToggleWindow("SettingsWindow")
                        self:setShowing(false)
                    end
                ),
                Button(
                    context,
                    L"Store",
                    function ()
                        context.Api.Event.OpenStore()
                        self:setShowing(false)
                    end
                ),
                Button(
                    context,
                    L"Agents",
                    function ()
                        context.Api.Window.ToggleWindow("OrganizerWindow")
                        self:setShowing(false)
                    end
                ),
                Button(
                    context,
                    3000172,
                    function ()
                        context.Api.Window.ToggleWindow("MacroWindow")
                        self:setShowing(false)
                    end
                ),
                Button(
                    context,
                    1079812,
                    function ()
                        context.Api.Window.ToggleWindow("ActionsWindow")
                        self:setShowing(false)
                    end
                ),
                Button(
                    context,
                    1061037,
                    function ()
                        context.Api.Event.OpenHelpMenu()
                        self:setShowing(false)
                    end
                ),
                Button(
                    context,
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


MongbatMainMenuMod = Mongbat.Mod {
    Name = "MongbatMainMenu",
    Path = "/src/mods/mongbat-main-menu",
    OnInitialize = function (context)
        context.Components.Defaults.MainMenuWindow:asComponent():destroy()
        Window(context):create(false)
    end
}