local NAME = "MongbatChatWindowWindow"

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

---@param context Context
local function OnInitialize(context)
    -- Suppress default chat windows
    local newChatDefault = context.Components.Defaults.NewChatWindow
    newChatDefault:disable()
    if context.Api.Window.DoesExist(newChatDefault.name) then
        newChatDefault:asComponent():setShowing(false)
    end

    local chatDefault = context.Components.Defaults.ChatWindow
    chatDefault:disable()
    if context.Api.Window.DoesExist(chatDefault.name) then
        chatDefault:asComponent():setShowing(false)
    end

    -- Engine data references (obtained once at initialization)
    local filters  = context.Api.Chat.GetLogFilters()
    local channels = context.Api.Chat.GetChannels()

    -- Active send channel index into SEND_CHANNELS
    local activeChannelIdx = 1

    -- Filter enabled state per key: true = show that message type in the log
    local filterEnabled = {}
    for _, entry in ipairs(FILTER_KEYS) do
        filterEnabled[entry.key] = true
    end

    -- Current alpha level
    local currentAlpha = 0.9

    -- Forward-declared component references
    local logDisplay   = nil
    local channelBtn   = nil
    local filterButtons = {}

    -- Update the channel cycle button text and colour to match the active channel
    local function updateChannelButton()
        if channelBtn == nil then return end
        local ch       = SEND_CHANNELS[activeChannelIdx]
        local filterId = filters[ch.key]
        local color    = context.Api.Chat.GetChannelColor(filterId)
        channelBtn:setText(ch.label)
        if color then
            channelBtn:setTextColor(context.Constants.ButtonStates.Normal,            color)
            channelBtn:setTextColor(context.Constants.ButtonStates.Highlighted,       color)
            channelBtn:setTextColor(context.Constants.ButtonStates.Pressed,           color)
            channelBtn:setTextColor(context.Constants.ButtonStates.PressedHighlighted,color)
        end
    end

    -- Toggle a message-type filter on the LogDisplay
    local function applyFilter(key, enabled)
        if logDisplay == nil then return end
        local filterId = filters[key]
        if filterId == nil then return end
        -- All main chat message types use log name "Chat"
        logDisplay:setFilterState("Chat", filterId, enabled)
    end

    -- ------------------------------------------------------------------ --
    -- Toolbar: filter toggle buttons + timestamp + alpha controls
    -- ------------------------------------------------------------------ --

    for _, entry in ipairs(FILTER_KEYS) do
        local localKey   = entry.key
        local localLabel = entry.label
        local filterId   = filters[localKey]
        local color      = filterId and context.Api.Chat.GetChannelColor(filterId) or nil

        local btn = context.Components.Button {
            OnInitialize = function(self)
                self:setCheckButton(true)
                self:setChecked(true)
                self:setText(localLabel)
                if color then
                    self:setTextColor(context.Constants.ButtonStates.Normal,            color)
                    self:setTextColor(context.Constants.ButtonStates.Highlighted,       color)
                    self:setTextColor(context.Constants.ButtonStates.Pressed,           color)
                    self:setTextColor(context.Constants.ButtonStates.PressedHighlighted,color)
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
    end

    -- Timestamp toggle
    local showTimestamp = false
    local timestampBtn = context.Components.Button {
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
    local alphaDecrBtn = context.Components.Button {
        OnInitialize = function(self)
            self:setText(L"-")
        end,
        OnLButtonUp = function(self)
            currentAlpha = currentAlpha - 0.1
            if currentAlpha < 0.1 then currentAlpha = 0.1 end
            context.Api.Window.SetAlpha(NAME, currentAlpha)
        end,
    }

    -- Alpha increment (+)
    local alphaIncrBtn = context.Components.Button {
        OnInitialize = function(self)
            self:setText(L"+")
        end,
        OnLButtonUp = function(self)
            currentAlpha = currentAlpha + 0.1
            if currentAlpha > 1.0 then currentAlpha = 1.0 end
            context.Api.Window.SetAlpha(NAME, currentAlpha)
        end,
    }

    -- ------------------------------------------------------------------ --
    -- Log display
    -- ------------------------------------------------------------------ --

    logDisplay = context.Components.LogDisplay {
        OnInitialize = function(self)
            self:showTimestamp(false)
            self:showLogName(false)
            self:showFilterName(false)
            self:addLog("Chat", true)

            -- Apply per-channel colours so messages render with the correct tint
            for _, ch in pairs(channels) do
                if ch and ch.id and ch.logName then
                    local color = context.Api.Chat.GetChannelColor(ch.id)
                    if color then
                        self:setFilterColor(ch.logName, ch.id, color)
                    end
                end
            end
        end,
    }

    -- ------------------------------------------------------------------ --
    -- Bottom row: channel-cycle button + text input
    -- ------------------------------------------------------------------ --

    -- Channel cycle button: click to rotate through SEND_CHANNELS
    channelBtn = context.Components.Button {
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

    -- Text input: Enter to send, Escape to clear
    local textInput = context.Components.EditTextBox {
        OnKeyEnter = function(self)
            local text = self:getText()
            if text and wstring.len(text) > 0 then
                local ch       = SEND_CHANNELS[activeChannelIdx]
                local filterId = filters[ch.key]
                if filterId then
                    context.Api.Chat.SendChat(filterId, text)
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

    -- Child index layout:
    --   1 .. #FILTER_KEYS         = filter toggle buttons  (toolbar)
    --   #FILTER_KEYS + 1          = timestampBtn           (toolbar)
    --   #FILTER_KEYS + 2          = alphaDecrBtn           (toolbar)
    --   #FILTER_KEYS + 3          = alphaIncrBtn           (toolbar)
    --   #FILTER_KEYS + 4          = logDisplay             (main area)
    --   #FILTER_KEYS + 5          = channelBtn             (bottom row)
    --   #FILTER_KEYS + 6          = textInput              (bottom row)
    local numFilters     = #FILTER_KEYS
    local numToolbarBtns = numFilters + 3   -- filters + Time + - + +

    context.Components.Window({
        Name = NAME,
        OnLayout = function(window, children, child, index)
            local dimens   = window:getDimensions()
            local padding  = 8
            local spacing  = 4
            local toolbarH = 22
            local inputH   = 26
            local contentW = dimens.x - (padding * 2)

            -- Spread all toolbar buttons evenly across the content width
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
                -- LogDisplay: fills the space between toolbar and input row
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

            local childList = {}
            for _, entry in ipairs(FILTER_KEYS) do
                table.insert(childList, filterButtons[entry.key])
            end
            table.insert(childList, timestampBtn)
            table.insert(childList, alphaDecrBtn)
            table.insert(childList, alphaIncrBtn)
            table.insert(childList, logDisplay)
            table.insert(childList, channelBtn)
            table.insert(childList, textInput)
            self:setChildren(childList)
        end,
    }):create(true)

    -- Sync channel button label/colour now that all components are live
    updateChannelButton()
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.Destroy(NAME)

    local newChatDefault = context.Components.Defaults.NewChatWindow
    newChatDefault:restore()
    if context.Api.Window.DoesExist(newChatDefault.name) then
        newChatDefault:asComponent():setShowing(true)
    end

    local chatDefault = context.Components.Defaults.ChatWindow
    chatDefault:restore()
    if context.Api.Window.DoesExist(chatDefault.name) then
        chatDefault:asComponent():setShowing(true)
    end
end

Mongbat.Mod {
    Name = "MongbatChatWindow",
    Path = "/src/mods/mongbat-chat-window",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown,
}
