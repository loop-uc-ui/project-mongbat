local Api = Mongbat.Api
local Components = Mongbat.Components
local Defaults = Components.Defaults

Mongbat.Mod {
    Name = "MongbatMainMenu",
    Path = "/src/mods/mongbat-main-menu",
    OnInitialize = function()
        local mainMenuWindow = Defaults.MainMenuWindow
        mainMenuWindow:destroy()

        local window = Components.Window { Name = mainMenuWindow:name() }
        window:setDimensions(214, 440)
        window:onRButtonUp(function() window:setShowing(false) end)

        local function Button(text, onLButtonUp)
            local btn = Components.Button {}
            btn:setDimensions(180, 40)
            btn:setText(text)
            if onLButtonUp then btn:onLButtonUp(onLButtonUp) end
            return btn
        end

        local logout = Button(3000128, function() Api.Event.Logout() end)
        local exit = Button(1077859, function() Api.Event.ExitGame() end)
        local settings = Button(L"Settings", function()
            Api.Window.ToggleWindow("SettingsWindow")
            window:setShowing(false)
        end)
        local store = Button(L"Store", function()
            Api.Event.OpenStore()
            window:setShowing(false)
        end)
        local agents = Button(L"Agents", function()
            Api.Window.ToggleWindow("OrganizerWindow")
            window:setShowing(false)
        end)
        local macros = Button(3000172, function()
            Api.Window.ToggleWindow("MacroWindow")
            window:setShowing(false)
        end)
        local actions = Button(1079812, function()
            Api.Window.ToggleWindow("ActionsWindow")
            window:setShowing(false)
        end)
        local mods = Button(1061037, function()
            Mongbat.ModManager.Window():create(true)
        end)
        local debug = Button(L"Debug", function()
            Api.Window.ToggleWindow("MongbatDebugWindow")
            window:setShowing(false)
        end)

        window:addChildren(
            { logout, exit, settings, store, agents, macros, actions, mods, debug },
            { offsetX = 17, offsetY = 17, spacing = 4 }
        )

        window:create(false)
    end,
    OnShutdown = function()
    end
}
