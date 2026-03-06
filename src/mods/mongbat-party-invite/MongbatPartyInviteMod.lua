local NAME = "MongbatPartyInviteWindow"

-- File-scope: needed by both OnInitialize and OnShutdown to restore overridden functions
local originalInitialize
local originalShutdown
local originalCloseWindow

---@param context Context
local function OnInitialize(context)
    local default = context.Components.Defaults.PartyInviteWindow
    local doNotShowChecked = false

    -- Save originals before overriding so OnShutdown can restore them
    originalInitialize = default:getDefault().Initialize
    originalShutdown = default:getDefault().Shutdown
    originalCloseWindow = default:getDefault().CloseWindow

    local function destroyWindow()
        context.Api.Window.Destroy(NAME)
    end

    local function createWindow()
        doNotShowChecked = false
        local inviterName = context.Data.PartyInviteName()
        local dialogText = inviterName .. context.Api.String.GetStringFromTid(1115373)

        context.Components.Window {
            Name = NAME,
            Resizable = false,
            OnRButtonUp = function()
                context.Api.Window.Destroy("PartyInviteWindow")
            end,
            OnInitialize = function(self)
                self:setDimensions(350, 165)
                self:anchorToParentCenter()
                self:setChildren {
                    context.Components.Label {
                        OnInitialize = function(self)
                            self:setDimensions(310, 50)
                            self:setText(dialogText)
                            self:centerText()
                        end
                    },
                    context.Components.Button {
                        OnInitialize = function(self)
                            self:setText(context.Api.String.GetStringFromTid(1115371))
                        end,
                        OnLButtonUp = function()
                            context.Api.Party.AcceptInvite()
                            context.Api.Window.Destroy("PartyInviteWindow")
                        end
                    },
                    context.Components.Button {
                        OnInitialize = function(self)
                            self:setText(context.Api.String.GetStringFromTid(1115372))
                        end,
                        OnLButtonUp = function()
                            context.Api.Party.DeclineInvite()
                            context.Api.Window.Destroy("PartyInviteWindow")
                        end
                    },
                    context.Components.Button {
                        OnInitialize = function(self)
                            self:setText(context.Api.String.GetStringFromTid(1115374))
                        end,
                        OnLButtonUp = function(self)
                            doNotShowChecked = not doNotShowChecked
                            if doNotShowChecked then
                                self:setText(L"[x] " .. context.Api.String.GetStringFromTid(1115374))
                            else
                                self:setText(context.Api.String.GetStringFromTid(1115374))
                            end
                        end
                    }
                }
            end
        }:create(true)

        -- Mirror the default UI's window-level CLOSE_PARTY_INVITE registration so the
        -- engine signal reaches CloseWindow even though we skipped the original Initialize.
        context.Api.Window.RegisterEventHandler(
            "PartyInviteWindow",
            context.Constants.Broadcasts.ClosePartyInvite(),
            "PartyInviteWindow.CloseWindow"
        )
    end

    default:getDefault().Initialize = function()
        createWindow()
    end

    default:getDefault().Shutdown = function()
        if context.Api.Party.IsRequestPending() then
            context.Api.Party.DeclineInvite()
        end
        if doNotShowChecked then
            context.Api.Party.SetShowInvitePopUp(false)
        end
        destroyWindow()
    end

    -- CloseWindow is called by the CLOSE_PARTY_INVITE engine signal (registered above in
    -- createWindow). Destroying "PartyInviteWindow" triggers the overridden Shutdown.
    default:getDefault().CloseWindow = function()
        context.Api.Window.Destroy("PartyInviteWindow")
    end
end

---@param context Context
local function OnShutdown(context)
    local default = context.Components.Defaults.PartyInviteWindow

    -- If a party invite is showing, destroy the XML window first so the overridden Shutdown
    -- fires (declining the pending invite and applying the "do not show" setting) before we
    -- restore the originals.
    context.Api.Window.Destroy("PartyInviteWindow")
    context.Api.Window.Destroy(NAME)

    -- Restore the functions we overwrote on the original table.
    default:getDefault().Initialize = originalInitialize
    default:getDefault().Shutdown = originalShutdown
    default:getDefault().CloseWindow = originalCloseWindow
    default:restore()
end

Mongbat.Mod {
    Name = "MongbatPartyInvite",
    Path = "/src/mods/mongbat-party-invite",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
