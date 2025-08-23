MongbatMainMenu = Mongbat.Mod {
    Name = "MongbatMainMenu",
    Path = "src/mongbat-main-menu",
    OnInitialize = function(mongbat)
        mongbat.Components.Window {
            Name = "MainMenuWindow",
            State = nil
        }

        mongbat.Components.Window {
            Name = "MongbatMainMenu",
            State = {
                Shadow = "MainMenuWindow",
                Dimensions = {
                    x = 100,
                    y = 300
                }
            }
        }
    end
}