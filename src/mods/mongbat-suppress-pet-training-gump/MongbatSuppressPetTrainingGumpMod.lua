Mongbat.Mod {
    Name = "MongbatSuppressPetTrainingGump",
    Path = "/src/mods/mongbat-suppress-pet-training-gump",
    OnInitialize = function(context)
        local gumpsParsing = context.Components.Defaults.GumpsParsing:getDefault()
        local parsingCheck = gumpsParsing.MainParsingCheck
        gumpsParsing.MainParsingCheck = function(timePassed)
            parsingCheck(timePassed)
            gumpsParsing.ToShow[context.Constants.GumpIds.PetTrainingProgress] = nil
        end
    end,
    OnShutdown = function() end
}
