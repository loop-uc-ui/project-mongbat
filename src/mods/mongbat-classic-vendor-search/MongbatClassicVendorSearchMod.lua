local Utils = Mongbat.Utils
local Constants = Mongbat.Constants
local Components = Mongbat.Components

Mongbat.Mod {
    Name = "MongbatClassicVendorSearch",
    Path = "/src/mods/mongbat-classic-vendor-search",
    OnInitialize = function()
        local gumpsParsing = Components.Defaults.GumpsParsing
        gumpsParsing:getVendorSearch().name = "MONGBAT_OVERRIDE_VENDOR_SEARCH"

        local genericGump = Components.Defaults.GenericGump:getDefault()
        local onShown = genericGump.OnShown

        genericGump.OnShown = function()
            onShown()
            local gump = Components.Gump()
            if gump ~= nil and gump:isVendorSearch() then
                Utils.Array.ForEach(
                    gump.textEntries,
                    function (textEntry)
                        textEntry:setTextColor(Constants.Colors.OffBlack)
                    end
                )
            end
        end
    end,
    OnShutdown = function()
        local gumpsParsing = Components.Defaults.GumpsParsing
        gumpsParsing:getVendorSearch().name = "VendorSearch"
    end
}
