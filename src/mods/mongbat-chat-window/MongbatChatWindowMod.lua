local NAME = "MongbatChatWindowWindow"
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants
local Utils = Mongbat.Utils

-- Maximum number of dynamic bookmark tabs the default NewChatWindow can create
local MAX_TABS = 20

-- Channels available for sending messages
local SEND_CHANNELS = {
    { key = "SAY",      label = L"Say" },
    { key = "WHISPER",  label = L"Whisper" },
    { key = "YELL",     label = L"Yell" },
    { key = "PARTY",    label = L"Party" },
    { key = "GUILD",    label = L"Guild" },
    { key = "ALLIANCE", label = L"Alliance" },
}

-- Message types shown as filter toggle buttons in the toolbar
local FILTER_KEYS = {
    { key = "SAY",      label = L"Say" },
    { key = "WHISPER",  label = L"Wsp" },
    { key = "YELL",     label = L"Yell" },
    { key = "PARTY",    label = L"Pty" },
    { key = "GUILD",    label = L"Gld" },
    { key = "ALLIANCE", label = L"Alc" },
    { key = "EMOTE",    label = L"Emo" },
    { key = "SYSTEM",   label = L"Sys" },
    { key = "GM",       label = L"GM" },
}

-- Destroy all windows created by the default NewChatWindow system
---@param api Api
local function destroyNewChatWindows(api)
    -- Main window (XML-defined; destroying it also removes its XML children)
    api.Window.Destroy("NewChatWindow")
    -- Standalone XML-defined windows that are NOT children of NewChatWindow
    api.Window.Destroy("NewChatWindowInputTextButton")
    api.Window.Destroy("NewChatChannelSelectionWindow")
    -- Dynamic bookmark tabs and per-tab log windows created by LoadTabs()
    for i = 1, MAX_TABS do
        api.Window.Destroy("Bookmark" .. i)
        api.Window.Destroy("NewChatWindow" .. i)
        api.Window.Destroy("NewChatWindowBookmark" .. i)
    end
end

-- Destroy all windows created by the default ChatWindow (UO_ChatWindow) system
---@param api Api
local function destroyChatWindows(api)
    -- Main window (XML-defined; destroying it removes its XML children including tabs)
    api.Window.Destroy("ChatWindow")
    -- Shared text-input container (XML-defined, anchored to the chat log)
    api.Window.Destroy("ChatWindowContainer")
    -- Standalone windows created dynamically by ChatWindow.Initialize()
    api.Window.Destroy("ChatWindowInputTextButton")
    api.Window.Destroy("ChatChannelSelectionWindow")
    api.Window.Destroy("ChatWindowRenameWindow")
    api.Window.Destroy("ChatWindowSetOpacityWindow")
end

local function OnInitialize()
    -- ------------------------------------------------------------------ --
    -- Suppress both default chat systems (proxy + full window destruction)
    -- ------------------------------------------------------------------ --

    local newChatDefault = Components.Defaults.NewChatWindow
    newChatDefault:disable()
    destroyNewChatWindows(Api)

    local chatDefault = Components.Defaults.ChatWindow
    chatDefault:disable()
    destroyChatWindows(Api)

    -- ------------------------------------------------------------------ --
    -- Engine data references (obtained once at initialization)
    -- ------------------------------------------------------------------ --

    local filters  = Data.ChatLogFilters()
    local channels = Data.ChatChannels()

    -- ------------------------------------------------------------------ --
    -- Runtime state (local to this OnInitialize â€” closures capture these)
    -- ------------------------------------------------------------------ --

    local activeChannelIdx = 1

    -- All message types enabled by default
    local filterEnabled = {}
    Utils.Array.ForEach(FILTER_KEYS, function(entry)
        filterEnabled[entry.key] = true
    end)

    local currentAlpha = 0.9

    -- Forward-declared component references set before Window:create()
    local logDisplay    = nil
    local channelBtn    = nil
    local filterButtons = {}

    -- ------------------------------------------------------------------ --
    -- Helpers
    -- ------------------------------------------------------------------ --

    local function updateChannelButton()
        if channelBtn == nil then return end
        local ch       = SEND_CHANNELS[activeChannelIdx]
        local filterId = filters[ch.key]
        local color    = Data.ChatChannelColor(filterId)
        channelBtn:setText(ch.label)
        if color then
            channelBtn:setTextColor(Constants.ButtonStates.Normal,            color)
            channelBtn:setTextColor(Constants.ButtonStates.Highlighted,       color)
            channelBtn:setTextColor(Constants.ButtonStates.Pressed,           color)
            channelBtn:setTextColor(Constants.ButtonStates.PressedHighlighted,color)
        end
    end

    local function applyFilter(key, enabled)
        if logDisplay == nil then return end
        local filterId = filters[key]
        if filterId == nil then return end
        logDisplay:setFilterState("Chat", filterId, enabled)
    end

    -- ------------------------------------------------------------------ --
    -- Toolbar: filter toggle buttons + timestamp + alpha controls
    -- ------------------------------------------------------------------ --

    Utils.Array.ForEach(FILTER_KEYS, function(entry)
        local localKey   = entry.key
        local localLabel = entry.label
        local filterId   = filters[localKey]
        local color      = filterId and Data.ChatChannelColor(filterId) or nil

        local btn = Components.Button {
            OnInitialize = function(self)
                self:setCheckButton(true)
                self:setChecked(true)
                self:setText(localLabel)
                if color then
                    self:setTextColor(Constants.ButtonStates.Normal,            color)
                    self:setTextColor(Constants.ButtonStates.Highlighted,       color)
                    self:setTextColor(Constants.ButtonStates.Pressed,           color)
                    self:setTextColor(Constants.ButtonStates.PressedHighlighted,color)
                end
            end,
            OnLButtonUp = function(self)
                local nowEnabled = not filterEnabled[localKey]
                filterEnabled[localKey] = nowEnabled
                self:setChecked(nowEnabled)
                applyFilter(localKey, nowEnabled)
            end,
        }
        filterButtons[localKey] = btn
    end)

    -- Timestamp toggle
    local showTimestamp = false
    local timestampBtn = Components.Button {
        OnInitialize = function(self)
            self:setCheckButton(true)
            self:setChecked(false)
            self:setText(L"Time")
        end,
        OnLButtonUp = function(self)
            showTimestamp = not showTimestamp
            self:setChecked(showTimestamp)
            if logDisplay then
                logDisplay:showTimestamp(showTimestamp)
            end
        end,
    }

    -- Alpha decrement (-)
    local alphaDecrBtn = Components.Button {
        OnInitialize = function(self)
            self:setText(L"-")
        end,
        OnLButtonUp = function(self)
            currentAlpha = currentAlpha - 0.1
            if currentAlpha < 0.1 then currentAlpha = 0.1 end
            Api.Window.SetAlpha(NAME, currentAlpha)
        end,
    }

    -- Alpha increment (+)
    local alphaIncrBtn = Components.Button {
        OnInitialize = function(self)
            self:setText(L"+")
        end,
        OnLButtonUp = function(self)
            currentAlpha = currentAlpha + 0.1
            if currentAlpha > 1.0 then currentAlpha = 1.0 end
            Api.Window.SetAlpha(NAME, currentAlpha)
        end,
    }

    -- ------------------------------------------------------------------ --
    -- Log display
    -- ------------------------------------------------------------------ --

    logDisplay = Components.LogDisplay {
        OnInitialize = function(self)
            self:showTimestamp(false)
            self:showLogName(false)
            self:showFilterName(false)
            self:showScrollbar(true)
            self:addLog("Chat", true)

            -- Set per-channel colours for the "Chat" log
            Utils.Table.ForEach(channels, function(_, ch)
                if ch and ch.id and ch.logName then
                    local color = Data.ChatChannelColor(ch.id)
                    if color then
                        self:setFilterColor(ch.logName, ch.id, color)
                    end
                end
            end)

            -- Explicitly enable all filter types to match initial filter button state
            Utils.Array.ForEach(FILTER_KEYS, function(entry)
                local filterId = filters[entry.key]
                if filterId then
                    self:setFilterState("Chat", filterId, true)
                end
            end)

            self:scrollToBottom()
        end,
    }

    -- ------------------------------------------------------------------ --
    -- Bottom row: channel-cycle button + text input
    -- ------------------------------------------------------------------ --

    channelBtn = Components.Button {
        OnInitialize = function(self)
            updateChannelButton()
        end,
        OnLButtonUp = function(self)
            activeChannelIdx = activeChannelIdx + 1
            if activeChannelIdx > #SEND_CHANNELS then
                activeChannelIdx = 1
            end
            updateChannelButton()
        end,
    }

    local textInput = Components.EditTextBox {
        OnKeyEnter = function(self)
            local text = self:getText()
            if text and wstring.len(text) > 0 then
                local ch       = SEND_CHANNELS[activeChannelIdx]
                local filterId = filters[ch.key]
                if filterId then
                    Api.Chat.SendChat(filterId, text)
                end
                self:clear()
            end
        end,
        OnKeyEscape = function(self)
            self:clear()
        end,
    }

    -- ------------------------------------------------------------------ --
    -- Window with custom layout
    -- ------------------------------------------------------------------ --

    -- Child order:
    --   1 .. #FILTER_KEYS         filter toggle buttons  (toolbar)
    --   #FILTER_KEYS + 1          timestampBtn           (toolbar)
    --   #FILTER_KEYS + 2          alphaDecrBtn           (toolbar)
    --   #FILTER_KEYS + 3          alphaIncrBtn           (toolbar)
    --   #FILTER_KEYS + 4          logDisplay             (main area)
    --   #FILTER_KEYS + 5          channelBtn             (bottom row)
    --   #FILTER_KEYS + 6          textInput              (bottom row)
    local numFilters     = #FILTER_KEYS
    local numToolbarBtns = numFilters + 3   -- filters + Time + - + +

    Components.Window({
        Name = NAME,
        OnLayout = function(window, children, child, index)
            local dimens   = window:getDimensions()
            local padding  = 8
            local spacing  = 4
            local toolbarH = 22
            local inputH   = 26
            local contentW = dimens.x - (padding * 2)

            local btnW = math.floor(contentW / numToolbarBtns)

            if index <= numToolbarBtns then
                -- Toolbar row
                if index == 1 then
                    child:addAnchor("topleft", window:getName(), "topleft", padding, padding)
                else
                    child:addAnchor("topleft", children[index - 1]:getName(), "topright", spacing, 0)
                end
                child:setDimensions(btnW, toolbarH)

            elseif index == numToolbarBtns + 1 then
                -- LogDisplay fills the space between toolbar and input row
                local logH = dimens.y - (padding * 2) - toolbarH - spacing - inputH - spacing
                if logH < 0 then logH = 0 end
                child:addAnchor("topleft", children[1]:getName(), "bottomleft", 0, spacing)
                child:setDimensions(contentW, logH)

            elseif index == numToolbarBtns + 2 then
                -- Channel cycle button: bottom-left
                child:addAnchor(
                    "topleft",
                    children[numToolbarBtns + 1]:getName(),
                    "bottomleft",
                    0, spacing
                )
                child:setDimensions(72, inputH)

            else
                -- Text input: right of channel button, fills the rest
                child:addAnchor(
                    "topleft",
                    children[numToolbarBtns + 2]:getName(),
                    "topright",
                    spacing, 0
                )
                child:setDimensions(contentW - 72 - spacing, inputH)
            end
        end,
        OnInitialize = function(self)
            self:setDimensions(620, 300)
            self:setAlpha(currentAlpha)
            -- Default position: bottom-left of the screen
            self:addAnchor("bottomleft", "Root", "bottomleft", 10, -10)

            local childList = {}
            Utils.Array.ForEach(FILTER_KEYS, function(entry)
                table.insert(childList, filterButtons[entry.key])
            end)
            table.insert(childList, timestampBtn)
            table.insert(childList, alphaDecrBtn)
            table.insert(childList, alphaIncrBtn)
            table.insert(childList, logDisplay)
            table.insert(childList, channelBtn)
            table.insert(childList, textInput)
            self:setChildren(childList)
        end,
    }):create(true)

    updateChannelButton()
end

local function OnShutdown()
    Api.Window.Destroy(NAME)

    -- Restore the proxy tables so the engine can re-initialize them on next login
    Components.Defaults.NewChatWindow:restore()
    Components.Defaults.ChatWindow:restore()
end

Mongbat.Mod {
    Name = "MongbatChatWindow",
    Path = "/src/mods/mongbat-chat-window",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}

