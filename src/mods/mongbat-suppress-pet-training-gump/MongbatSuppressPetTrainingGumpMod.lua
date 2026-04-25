-- Suppresses the pet training progress gump by intercepting GumpsParsing's
-- per-frame parsing pass and clearing the entry before the engine can show
-- it. No windows; pure init-time hook via Api.GumpsParsing.

local Api       = Mongbat.Api
local Constants = Mongbat.Constants

local M = {}

function M.OnLoad()
    Api.GumpsParsing.SuppressGump(Constants.GumpIds.PetTrainingProgress)
end

Mongbat.Mod {
    Name   = "MongbatSuppressPetTrainingGump",
    Path   = "/src/mods/mongbat-suppress-pet-training-gump",
    Module = M,
}
