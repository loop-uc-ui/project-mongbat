local NAME = "MongbatIgnoreWindow"
local ITEM_HEIGHT = 22
local WINDOW_WIDTH = 320
local WINDOW_HEIGHT = 280
local ITEM_WIDTH = 280
local SCROLL_NAME = NAME .. "Scroll"
local SCROLL_CHILD = NAME .. "ScrollChild"

-- Saved default IgnoreWindow functions, shared between OnInitialize and OnShutdown.
local savedFunctions = {}

---@param context Context
local function OnInitialize(context)
    local Api = context.Api
    local Data = context.Data
    local Components = context.Components

    local ignoreDefault = Components.Defaults.IgnoreWindow:getDefault()
    local settingsDefault = Components.Defaults.SettingsWindow:getDefault()

    -- Save originals so OnShutdown can restore them.
    savedFunctions.Initialize = ignoreDefault.Initialize
    savedFunctions.Add_OnLButtonUp = ignoreDefault.Add_OnLButtonUp
    savedFunctions.Cancel_OnLButtonUp = ignoreDefault.Cancel_OnLButtonUp
    savedFunctions.SelectPlayer = ignoreDefault.SelectPlayer

    --- Creates a button for a single player row.
    --- Each call binds playerId and playerName as function parameters so that the
    --- returned closures capture distinct per-player values regardless of call order.
    ---@param playerId number
    ---@param playerName string
    ---@param itemName string
    ---@return Button
    local function makePlayerButton(playerId, playerName, itemName)
        return Components.Button {
            Name = itemName,
            OnInitialize = function(self)
                self:setDimensions(ITEM_WIDTH, ITEM_HEIGHT)
                self:setText(playerName)
            end,
            OnLButtonUp = function(self)
                local listType = settingsDefault.ignoreListType
                Api.Chat.AddPlayerToIgnoreList(playerId, playerName, listType)
                Api.Window.Destroy(NAME)
            end
        }
    end

    --- Populates the scroll child window with one button per recent chat player.
    --- Must be called after the window template has been created so that SCROLL_CHILD exists.
    local function populatePlayerList()
        local playerList = Data.RecentChatPlayerList()
        local count = playerList:getCount()
        local prevName = nil

        for i = 1, count do
            local playerId = playerList:getId(i)
            local playerName = playerList:getName(i)
            local itemName = NAME .. "Item" .. i

            local btn = makePlayerButton(playerId, playerName, itemName)
            -- MongbatButton has no OnInitialize event handler in its XML template,
            -- so the engine will not fire OnInitialize automatically; call it manually.
            btn:create(true)
            btn:onInitialize()
            btn:setParent(SCROLL_CHILD)
            btn:clearAnchors()
            if prevName == nil then
                btn:addAnchor("topleft", SCROLL_CHILD, "topleft", 0, 0)
            else
                btn:addAnchor("topleft", prevName, "bottomleft", 0, 0)
            end
            prevName = itemName
        end

        Api.ScrollWindow.UpdateScrollRect(SCROLL_NAME)
    end

    --- Creates and shows the Mongbat ignore window.
    local function showIgnoreWindow()
        if Api.Window.DoesExist(NAME) then
            Api.Window.Destroy(NAME)
        end

        -- MongbatIgnoreWindowTemplate has an OnInitialize event handler, so the
        -- engine fires Mongbat.EventHandler.OnInitialize automatically on create.
        -- Do NOT call window:onInitialize() manually to avoid double-initialisation.
        Components.Window {
            Name = NAME,
            Template = "MongbatIgnoreWindowTemplate",
            Resizable = false,
            OnInitialize = function(self)
                self:setDimensions(WINDOW_WIDTH, WINDOW_HEIGHT)
                self:anchorToParentCenter()
                populatePlayerList()
            end,
            OnRButtonUp = function(self)
                Api.Window.Destroy(NAME)
            end
        }:create(true)
    end

    -- Override IgnoreWindow.Initialize to intercept the engine-driven open and
    -- replace it with our Mongbat window. The engine calls this after
    -- CreateWindow("IgnoreWindow") fires OnInitialize on the XML window.
    ignoreDefault.Initialize = function()
        -- Destroy the engine-created default XML window immediately.
        Api.Window.Destroy("IgnoreWindow")
        showIgnoreWindow()
    end

    -- No-op the remaining default callbacks since our per-item buttons handle
    -- the add action directly and the cancel/select flow is not applicable.
    ignoreDefault.Add_OnLButtonUp = function() end
    ignoreDefault.Cancel_OnLButtonUp = function() end
    ignoreDefault.SelectPlayer = function() end

    -- Destroy any pre-existing default IgnoreWindow (created at XML load time).
    Api.Window.Destroy("IgnoreWindow")
end

---@param context Context
local function OnShutdown(context)
    -- Destroy our window if it is open.
    context.Api.Window.Destroy(NAME)

    -- Restore the original IgnoreWindow functions.
    local ignoreDefault = context.Components.Defaults.IgnoreWindow:getDefault()
    ignoreDefault.Initialize = savedFunctions.Initialize
    ignoreDefault.Add_OnLButtonUp = savedFunctions.Add_OnLButtonUp
    ignoreDefault.Cancel_OnLButtonUp = savedFunctions.Cancel_OnLButtonUp
    ignoreDefault.SelectPlayer = savedFunctions.SelectPlayer

    savedFunctions = {}
end

Mongbat.Mod {
    Name = "MongbatIgnoreWindow",
    Path = "/src/mods/mongbat-ignore-window",
    Files = { "MongbatIgnoreWindow.xml" },
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
