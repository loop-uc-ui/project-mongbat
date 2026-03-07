local NAME = "MongbatPartyInviteWindow"
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants

-- File-scope: needed by both OnInitialize and OnShutdown to restore overridden functions
local originalInitialize
local originalShutdown
local originalCloseWindow

local function OnInitialize()
    local default = Components.Defaults.PartyInviteWindow
    local doNotShowChecked = false

    -- Save originals before overriding so OnShutdown can restore them
    originalInitialize = default:getDefault().Initialize
    originalShutdown = default:getDefault().Shutdown
    originalCloseWindow = default:getDefault().CloseWindow

    local function createWindow()
        doNotShowChecked = false
        local inviterName = Data.PartyInviteName()
        local dialogText = inviterName .. Api.String.GetStringFromTid(1115373)

        Components.Window {
            Name = NAME,
            Resizable = false,
            OnRButtonUp = function()
                Api.Window.Destroy("PartyInviteWindow")
            end,
            OnInitialize = function(self)
                self:setDimensions(350, 165)
                self:anchorToParentCenter()
                self:setChildren {
                    Components.Label {
                        OnInitialize = function(self)
                            self:setDimensions(310, 50)
                            self:setText(dialogText)
                            self:centerText()
                        end
                    },
                    Components.Button {
                        OnInitialize = function(self)
                            self:setText(Api.String.GetStringFromTid(1115371))
                        end,
                        OnLButtonUp = function()
                            Api.Party.AcceptInvite()
                            Api.Window.Destroy("PartyInviteWindow")
                        end
                    },
                    Components.Button {
                        OnInitialize = function(self)
                            self:setText(Api.String.GetStringFromTid(1115372))
                        end,
                        OnLButtonUp = function()
                            Api.Party.DeclineInvite()
                            Api.Window.Destroy("PartyInviteWindow")
                        end
                    },
                    Components.Button {
                        OnInitialize = function(self)
                            self:setText(Api.String.GetStringFromTid(1115374))
                        end,
                        OnLButtonUp = function(self)
                            doNotShowChecked = not doNotShowChecked
                            if doNotShowChecked then
                                self:setText(L"[x] " .. Api.String.GetStringFromTid(1115374))
                            else
                                self:setText(Api.String.GetStringFromTid(1115374))
                            end
                        end
                    }
                }
            end
        }:create(true)

        -- Mirror the default UI's window-level CLOSE_PARTY_INVITE registration so the
        -- engine signal reaches CloseWindow even though we skipped the original Initialize.
        Api.Window.RegisterEventHandler(
            "PartyInviteWindow",
            Constants.Broadcasts.ClosePartyInvite(),
            "PartyInviteWindow.CloseWindow"
        )
    end

    default:getDefault().Initialize = function()
        createWindow()
    end

    default:getDefault().Shutdown = function()
        if Api.Party.IsRequestPending() then
            Api.Party.DeclineInvite()
        end
        if doNotShowChecked then
            Api.Party.SetShowInvitePopUp(false)
        end
        Api.Window.Destroy(NAME)
    end

    -- CloseWindow is called by the CLOSE_PARTY_INVITE engine signal (registered above in
    -- createWindow). Destroying "PartyInviteWindow" triggers the overridden Shutdown.
    default:getDefault().CloseWindow = function()
        Api.Window.Destroy("PartyInviteWindow")
    end
end

local function OnShutdown()
    local default = Components.Defaults.PartyInviteWindow

    -- If a party invite is showing, destroy the XML window first so the overridden Shutdown
    -- fires (declining the pending invite and applying the "do not show" setting) before we
    -- restore the originals.
    Api.Window.Destroy("PartyInviteWindow")
    Api.Window.Destroy(NAME)

    -- Restore the functions we overwrote on the original table.
    default:getDefault().Initialize = originalInitialize
    default:getDefault().Shutdown = originalShutdown
    default:getDefault().CloseWindow = originalCloseWindow
end

Mongbat.Mod {
    Name = "MongbatPartyInvite",
    Path = "/src/mods/mongbat-party-invite",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
