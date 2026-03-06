local NAME = "MongbatPartyInviteWindow"

---@param context Context
local function OnInitialize(context)
    local default = context.Components.Defaults.PartyInviteWindow
    local doNotShowChecked = false

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

    context.Api.Event.RegisterEventHandler(
        context.Constants.Broadcasts.ClosePartyInvite(),
        function()
            context.Api.Window.Destroy("PartyInviteWindow")
        end
    )
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.Destroy(NAME)
    context.Components.Defaults.PartyInviteWindow:restore()
end

Mongbat.Mod {
    Name = "MongbatPartyInvite",
    Path = "/src/mods/mongbat-party-invite",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
