local Constants = Mongbat.Constants
local Components = Mongbat.Components

Mongbat.Mod {
    Name = "MongbatSuppressPetTrainingGump",
    Path = "/src/mods/mongbat-suppress-pet-training-gump",
    OnInitialize = function()
        local gumpsParsing = Components.Defaults.GumpsParsing.default
        local parsingCheck = gumpsParsing.MainParsingCheck
        gumpsParsing.MainParsingCheck = function(timePassed)
            parsingCheck(timePassed)
            gumpsParsing.ToShow[Constants.GumpIds.PetTrainingProgress] = nil
        end
    end,
    OnShutdown = function() end
}
