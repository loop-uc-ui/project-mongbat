-- Forces the vendor-search gump to render via the classic GenericGump path
-- instead of the engine's specialised VendorSearch window, then recolors the
-- label text to off-black so it is legible against the parchment background.
--
-- Both effects are init-time monkey-patches on default UI globals; no windows
-- are owned by this mod because the gump is owned by GenericGump.

local Api       = Mongbat.Api
local Utils     = Mongbat.Utils
local Constants = Mongbat.Constants

local VENDOR_SEARCH_ID = Constants.GumpIds.VendorSearch
local OVERRIDE_NAME    = "MONGBAT_OVERRIDE_VENDOR_SEARCH"
local ORIGINAL_NAME    = "VendorSearch"

local M = {}

function M.OnLoad()
    -- (1) Defeat the specialised vendor-search renderer by renaming its
    --     entry in GumpsParsing. The engine's parser only takes the
    --     specialised path when it sees the exact "VendorSearch" name,
    --     so any other string makes it fall back to GenericGump.
    Api.GumpsParsing.SetGumpName(VENDOR_SEARCH_ID, OVERRIDE_NAME)

    -- (2) Chain GenericGump.OnShown so that when a vendor-search gump is
    --     created we recolor its labels.
    Api.GenericGump.OnShown(function()
        if Api.Window.GetId(Api.Window.GetActiveName()) ~= VENDOR_SEARCH_ID then return end

        -- LastGumpLabels is populated by GenericGump.OnLabelInit during
        -- the gump's construction; each entry is { windowName = "..." }.
        Utils.Array.ForEach(Api.GenericGump.GetLastLabels(), function(label)
            Api.Label.SetTextColor(label.windowName, Constants.Colors.OffBlack)
        end)
    end)
end

function M.OnUnload()
    Api.GumpsParsing.SetGumpName(VENDOR_SEARCH_ID, ORIGINAL_NAME)
end

Mongbat.Mod {
    Name   = "MongbatClassicVendorSearch",
    Path   = "/src/mods/mongbat-classic-vendor-search",
    Module = M,
}
