local NAME = "MongbatChannelWindow"
local CREATE_CHANNEL_NAME = "MongbatCreateChannelWindow"

local COLOR_SELECTED = { r = 255, g = 215, b = 0 }
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants
local Utils = Mongbat.Utils

--- Saved originals restored in OnShutdown. File-scope is justified because
--- these values bridge OnInitialize and OnShutdown and cannot be passed
--- through closures.
local savedInitialize = nil
local savedShutdown = nil

local function OnInitialize()
    local channelWindow = Components.Defaults.ChannelWindow

    -- Save originals before overriding so they can be restored in OnShutdown.
    -- Do NOT call disable() â€” when disabled, the proxy returns a no-op for
    -- every function, including our own Initialize override.
    savedInitialize = channelWindow:getDefault().Initialize
    savedShutdown = channelWindow:getDefault().Shutdown

    local currentSelection = 1

    --- Builds and shows the Create Channel sub-dialog.
    local function openCreateDialog()
        if Api.Window.DoesExist(CREATE_CHANNEL_NAME) then
            return
        end

        local textEntry = Components.EditTextBox {}

        local function submit()
            local text = textEntry:getText()
            if text and text ~= L"" then
                Api.Chat.CreateChannel(text)
            end
            Api.Window.Destroy(CREATE_CHANNEL_NAME)
            Api.Window.Destroy(NAME)
        end

        local function OkayButton()
            return Components.Button {
                OnInitialize = function(self)
                    self:setText(Api.String.GetStringFromTid(3000093))
                end,
                OnLButtonUp = function()
                    submit()
                end
            }
        end

        local function CancelButton()
            return Components.Button {
                OnInitialize = function(self)
                    self:setText(Api.String.GetStringFromTid(1006045))
                end,
                OnLButtonUp = function()
                    Api.Window.Destroy(CREATE_CHANNEL_NAME)
                end
            }
        end

        Components.Window {
            Name = CREATE_CHANNEL_NAME,
            OnInitialize = function(self)
                self:setDimensions(280, 140)
                self:anchorToParentCenter()
                self:setTitle(Api.String.GetStringFromTid(1114077))
                self:setChildren {
                    textEntry,
                    OkayButton(),
                    CancelButton()
                }
                textEntry:setFocus(true)
            end,
            OnRButtonUp = function()
                Api.Window.Destroy(CREATE_CHANNEL_NAME)
            end
        }:create(true)
    end

    --- Builds a Label for the current channel name, updated via CURRENT_CHANNEL_UPDATED.
    ---@return Label
    local function CurrentChannelLabel()
        local function refreshText(self)
            local channels = Data.ChannelList()
            local current = channels:getCurrentChannel()
            if current == L"" then
                self:setText(Api.String.GetStringFromTid(1011051))
                self:setTextColor(Constants.Colors.OffWhite)
            else
                self:setText(current)
                self:setTextColor(Constants.Colors.White)
            end
        end

        return Components.Label {
            OnInitialize = function(self)
                self:setDimensions(250, 20)
                refreshText(self)
            end,
            OnCurrentChannelUpdated = function(self)
                refreshText(self)
            end
        }
    end

    --- Builds the "Your Current Channel:" descriptor label.
    ---@return Label
    local function CurrentChannelDescLabel()
        return Components.Label {
            OnInitialize = function(self)
                self:setDimensions(250, 20)
                self:setText(Api.String.GetStringFromTid(1114072))
                self:setTextColor(Constants.Colors.White)
            end
        }
    end

    --- Builds the Join button.
    ---@return Button
    local function JoinButton()
        return Components.Button {
            OnInitialize = function(self)
                self:setText(Api.String.GetStringFromTid(1114074))
            end,
            OnLButtonUp = function()
                local channels = Data.ChannelList()
                local name = channels:getName(currentSelection)
                if name and name ~= L"" then
                    Api.Chat.JoinChannel(name)
                end
                Api.Window.Destroy(NAME)
            end
        }
    end

    --- Builds the Leave button.
    ---@return Button
    local function LeaveButton()
        return Components.Button {
            OnInitialize = function(self)
                self:setText(Api.String.GetStringFromTid(1114075))
            end,
            OnLButtonUp = function()
                Api.Chat.LeaveChannel()
                Api.Window.Destroy(NAME)
            end
        }
    end

    --- Builds the Create button.
    ---@return Button
    local function CreateButton()
        return Components.Button {
            OnInitialize = function(self)
                self:setText(Api.String.GetStringFromTid(1114076))
            end,
            OnLButtonUp = function()
                openCreateDialog()
            end
        }
    end

    --- Creates and shows the channel window, reading channel data at creation time.
    local function createWindow()
        if Api.Window.DoesExist(NAME) then
            return
        end

        currentSelection = 1

        ---@type Label[]
        local rows = {}

        Utils.Array.ForEach(
            Data.ChannelList():getNames(),
            function(channelName, index)
                rows[index] = Components.Label {
                    Name = Utils.String.Format("MongbatChannelRow_%d", index),
                    Id = index,
                    OnInitialize = function(self)
                        self:setDimensions(230, 20)
                        self:setText(channelName)
                        if index == currentSelection then
                            self:setTextColor(COLOR_SELECTED)
                        else
                            self:setTextColor(Constants.Colors.White)
                        end
                    end,
                    OnLButtonUp = function(self)
                        local previous = currentSelection
                        currentSelection = self:getId()
                        if rows[previous] then
                            rows[previous]:setTextColor(Constants.Colors.White)
                        end
                        self:setTextColor(COLOR_SELECTED)
                    end
                }
            end
        )

        local children = Utils.Array.Concat {
            {
                CurrentChannelLabel(),
                CurrentChannelDescLabel(),
                JoinButton(),
                LeaveButton(),
                CreateButton()
            },
            rows
        }

        Components.Window {
            Name = NAME,
            OnInitialize = function(self)
                self:setDimensions(300, 375)
                self:anchorToParentCenter()
                self:setTitle(Api.String.GetStringFromTid(1114073))
                self:setChildren(children)
            end,
            OnRButtonUp = function()
                Api.Window.Destroy(NAME)
            end
        }:create(true)
    end

    channelWindow:getDefault().Initialize = function()
        -- The engine has already created the default "ChannelWindow" XML template
        -- window before calling Initialize. Destroy it so only our Mongbat window
        -- is visible.
        Api.Window.Destroy("ChannelWindow")
        createWindow()
    end

    channelWindow:getDefault().Shutdown = function() end
end

local function OnShutdown()
    Api.Window.Destroy(CREATE_CHANNEL_NAME)
    Api.Window.Destroy(NAME)

    local channelWindow = Components.Defaults.ChannelWindow
    if savedInitialize then
        channelWindow:getDefault().Initialize = savedInitialize
        savedInitialize = nil
    end
    if savedShutdown then
        channelWindow:getDefault().Shutdown = savedShutdown
        savedShutdown = nil
    end
end

Mongbat.Mod {
    Name = "MongbatChannelWindow",
    Path = "/src/mods/mongbat-channel-window",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
