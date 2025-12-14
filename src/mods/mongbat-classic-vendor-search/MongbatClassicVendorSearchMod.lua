Mongbat.Mod {
    Name = "MongbatClassicVendorSearch",
    Path = "/src/mods/mongbat-classic-vendor-search",
    OnInitialize = function(context)
        local gumpsParsing = context.Components.Defaults.GumpsParsing
        gumpsParsing:getVendorSearch().name = "MONGBAT_OVERRIDE_VENDOR_SEARCH"

        local genericGump = context.Components.Defaults.GenericGump:getDefault()
        local onShown = genericGump.OnShown

        genericGump.OnShown = function()
            onShown()
            local gump = context.Components.Gump()
            if gump ~= nil and gump:isVendorSearch() then
                context.Utils.Array.ForEach(
                    gump.textEntries,
                    function (textEntry)
                        textEntry:setTextColor(context.Constants.Colors.OffBlack)
                    end
                )
            end
        end
    end,
    OnShutdown = function(context)
        local gumpsParsing = context.Components.Defaults.GumpsParsing
        gumpsParsing:getVendorSearch().name = "VendorSearch"
    end
}
