-- ========================================================================== --
-- MongbatTradeWindow
-- Replaces the default TradeWindow with a clean two-column Mongbat layout.
-- Two-column design: left = my items, right = their items.
-- Gold/plat input fields on my side; read-only display on their side.
-- ========================================================================== --

-- TID string constants  (My Offer, Their Offer, Accept, Cancel, Trade)
local TID_MY_OFFER    = 1077713
local TID_THEIR_OFFER = 3000145
local TID_ACCEPT      = 1013076
local TID_CANCEL      = 1006045
local TID_TRADE       = 1077728

-- Icon IDs for gold and platinum currency
local ICON_GOLD_ID = 85843
local ICON_PLAT_ID = 85842

-- Layout constants
local WINDOW_W       = 560
local WINDOW_H       = 500
local COL_W          = 250
local ICON_SIZE      = 36
local PADDING        = 6
local HEADER_H       = 22
local LIST_H         = 240
local CURRENCY_ICON  = 20
local ROW_H          = 28
local ACCEPT_H       = 30

-- File-scoped: must survive across OnInitialize and OnShutdown to allow
-- the original TradeWindow functions to be restored on mod unload.
local _savedInit, _savedShutdown, _savedClose

---@param context Context
local function OnInitialize(context)
    local Api        = context.Api
    local Data       = context.Data
    local Constants  = context.Constants
    local Components = context.Components

    local tradeDefault = Components.Defaults.TradeWindow

    -- Save originals before overriding so they can be restored in OnShutdown
    _savedInit     = tradeDefault:getDefault().Initialize
    _savedShutdown = tradeDefault:getDefault().Shutdown
    _savedClose    = tradeDefault:getDefault().CloseWindow

    -- Track active trade windows: defaultWindowName -> mongbatWindowName
    local activeWindows = {}

    -- ------------------------------------------------------------------ --
    -- Helper: safely destroy our Mongbat window
    -- ------------------------------------------------------------------ --
    local function destroyTradeWindow(mongbatName)
        if Api.Window.DoesExist(mongbatName) then
            Api.Window.Destroy(mongbatName)
        end
    end

    -- ------------------------------------------------------------------ --
    -- Rebuild one side's item list from container data
    -- Slots are simple DynamicImage windows stacked top-to-bottom.
    -- ------------------------------------------------------------------ --
    ---@param scrollChild string  parent window for item slots
    ---@param containerId integer
    ---@param registeredItems table<integer, boolean>  updated in-place
    local function rebuildItemList(scrollChild, containerId, registeredItems)
        -- Unregister previously tracked objects
        for id, _ in pairs(registeredItems) do
            Api.Window.UnregisterData(
                Constants.DataEvents.OnUpdateObjectInfo.getType(), id)
        end
        -- Destroy old slot windows
        local i = 1
        while Api.Window.DoesExist(scrollChild .. "Slot" .. i) do
            Api.Window.Destroy(scrollChild .. "Slot" .. i)
            i = i + 1
        end
        -- Clear the table
        for k, _ in pairs(registeredItems) do
            registeredItems[k] = nil
        end

        local container = Data.ContainerWindow(containerId)
        local numItems  = container:getNumItems()
        local prevSlot  = nil

        for idx = 1, numItems do
            local item = container:getItem(idx)
            if item then
                local oid      = item.objectId
                registeredItems[oid] = true
                Api.Window.RegisterData(
                    Constants.DataEvents.OnUpdateObjectInfo.getType(), oid)

                local slotName = scrollChild .. "Slot" .. idx
                Api.Window.CreateFromTemplate(
                    slotName, "MongbatDynamicImage", scrollChild, true)
                Api.Window.SetDimensions(slotName, ICON_SIZE, ICON_SIZE)
                Api.Window.ClearAnchors(slotName)
                if prevSlot == nil then
                    Api.Window.AddAnchor(slotName, "topleft", scrollChild,
                        "topleft", PADDING, PADDING)
                else
                    Api.Window.AddAnchor(slotName, "topleft", prevSlot,
                        "bottomleft", 0, PADDING)
                end
                prevSlot = slotName

                -- Set the icon texture
                local info = Data.ObjectInfo(oid)
                local tex  = info:getIconTexture()
                if tex ~= "" then
                    Api.DynamicImage.SetTexture(
                        slotName, tex, info:getIconX(), info:getIconY())
                    Api.DynamicImage.SetTextureDimensions(
                        slotName, ICON_SIZE, ICON_SIZE)
                end
            end
        end
    end

    -- ------------------------------------------------------------------ --
    -- Create the Mongbat trade window for one trade instance
    -- ------------------------------------------------------------------ --
    ---@param defaultWindowName string  the engine-created XML window name
    ---@param tradeId integer           SystemData.DynamicWindowId
    local function createTradeWindow(defaultWindowName, tradeId)
        local mongbatName = "MongbatTradeWindow" .. tradeId

        -- Snapshot the TradeInfo (before async updates)
        local tradeInfo    = Data.TradeInfo()
        local containerId  = tradeInfo:getContainerId()
        local containerId2 = tradeInfo:getContainerId2()

        -- Register container data with the engine for both sides
        Api.Window.RegisterData(
            Constants.DataEvents.OnUpdateContainerWindow.getType(), containerId)
        Api.Window.RegisterData(
            Constants.DataEvents.OnUpdateContainerWindow.getType(), containerId2)

        -- Per-container item tracking tables
        local myRegisteredItems    = {}
        local theirRegisteredItems = {}

        -- Sub-window names referenced by closures
        local myScrollChild    = mongbatName .. "MyList"
        local theirScrollChild = mongbatName .. "TheirList"
        local theirGoldLabel   = mongbatName .. "TheirGold"
        local theirPlatLabel   = mongbatName .. "TheirPlat"
        local balGoldLabel     = mongbatName .. "BalGold"
        local balPlatLabel     = mongbatName .. "BalPlat"
        local acceptBtnName    = mongbatName .. "Accept"
        local myGoldEditName   = mongbatName .. "GoldEdit"
        local myPlatEditName   = mongbatName .. "PlatEdit"

        -- Cached icon data for currency (fetched once per trade)
        local goldTex, goldX, goldY = Api.Icon.GetIconData(ICON_GOLD_ID)
        local platTex, platX, platY = Api.Icon.GetIconData(ICON_PLAT_ID)

        -- ---------------------------------------------------------------- --
        -- Helper: create a small DynamicImage currency icon
        -- ---------------------------------------------------------------- --
        local function makeCurrencyIcon(iconName, parent, anchorTo, anchorToPoint,
                                        offX, offY, tex, tx, ty)
            Api.Window.CreateFromTemplate(iconName, "MongbatDynamicImage", parent, true)
            Api.Window.SetDimensions(iconName, CURRENCY_ICON, CURRENCY_ICON)
            Api.Window.ClearAnchors(iconName)
            Api.Window.AddAnchor(iconName, "topleft", anchorTo, anchorToPoint,
                offX, offY)
            if tex and tex ~= "" then
                Api.DynamicImage.SetTexture(iconName, tex, tx, ty)
                Api.DynamicImage.SetTextureDimensions(iconName, CURRENCY_ICON, CURRENCY_ICON)
            end
        end

        -- ---------------------------------------------------------------- --
        -- Helper: create a read-only label aligned next to a currency icon
        -- ---------------------------------------------------------------- --
        local function makeCurrencyLabel(labelName, parent, iconName)
            Api.Window.CreateFromTemplate(labelName, "MongbatLabel", parent, true)
            Api.Window.SetDimensions(labelName,
                COL_W - CURRENCY_ICON - PADDING * 2, ROW_H)
            Api.Window.ClearAnchors(labelName)
            Api.Window.AddAnchor(labelName, "topleft", iconName,
                "topright", PADDING, 0)
            Api.Label.SetText(labelName, L"0")
        end

        -- ---------------------------------------------------------------- --
        -- Accept/Cancel button component
        -- ---------------------------------------------------------------- --
        local acceptButton = Components.Button {
            Name     = acceptBtnName,
            Template = "MongbatButton",
            OnInitialize = function(self)
                self:setDimensions(COL_W, ACCEPT_H)
                self:setText(Api.String.GetStringFromTid(TID_ACCEPT))
            end,
            OnLButtonUp = function(self)
                local ti      = Data.TradeInfo()
                local current = ti:isMyAccepted()
                ti:setMyAccepted(not current)
                Api.Event.Broadcast(Constants.TradeEvents.SendAcceptMsg())
            end
        }

        -- ---------------------------------------------------------------- --
        -- Gold edit box (my offer, gold)
        -- ---------------------------------------------------------------- --
        local goldEdit = Components.EditTextBox {
            Name     = myGoldEditName,
            Template = "MongbatEditTextBox",
            OnInitialize = function(self)
                self:setDimensions(
                    COL_W - CURRENCY_ICON - PADDING * 2, ROW_H)
                self:setText(L"0")
            end,
            OnKeyEnter = function(self)
                local text = Api.String.WStringToString(self:getText())
                local val  = tonumber(text) or 0
                local ti   = Data.TradeInfo()
                ti:setMyGold(val)
                Api.Event.Broadcast(Constants.TradeEvents.SendModifyGold())
            end
        }

        -- ---------------------------------------------------------------- --
        -- Plat edit box (my offer, platinum)
        -- ---------------------------------------------------------------- --
        local platEdit = Components.EditTextBox {
            Name     = myPlatEditName,
            Template = "MongbatEditTextBox",
            OnInitialize = function(self)
                self:setDimensions(
                    COL_W - CURRENCY_ICON - PADDING * 2, ROW_H)
                self:setText(L"0")
            end,
            OnKeyEnter = function(self)
                local text = Api.String.WStringToString(self:getText())
                local val  = tonumber(text) or 0
                local ti   = Data.TradeInfo()
                ti:setMyPlat(val)
                Api.Event.Broadcast(Constants.TradeEvents.SendModifyGold())
            end
        }

        -- ---------------------------------------------------------------- --
        -- Main window
        -- ---------------------------------------------------------------- --
        local window = Components.Window {
            Name      = mongbatName,
            Resizable = false,
            -- Layout is handled manually in OnInitialize via explicit anchors,
            -- so no automatic layout pass is needed.
            OnLayout  = function() end,
            OnInitialize = function(self)
                local n = self:getName()
                self:setDimensions(WINDOW_W, WINDOW_H)
                self:anchorToParentCenter()

                -- ---- Column headers ---- --
                local myHeader = n .. "MyHdr"
                Api.Window.CreateFromTemplate(myHeader, "MongbatLabel", n, true)
                Api.Window.SetDimensions(myHeader, COL_W, HEADER_H)
                Api.Window.ClearAnchors(myHeader)
                Api.Window.AddAnchor(myHeader, "topleft", n, "topleft",
                    PADDING, PADDING)
                Api.Label.SetText(myHeader,
                    Api.String.GetStringFromTid(TID_MY_OFFER))

                local theirHeader = n .. "TheirHdr"
                Api.Window.CreateFromTemplate(theirHeader, "MongbatLabel", n, true)
                Api.Window.SetDimensions(theirHeader, COL_W, HEADER_H)
                Api.Window.ClearAnchors(theirHeader)
                Api.Window.AddAnchor(theirHeader, "topleft", n, "topleft",
                    PADDING + COL_W + PADDING, PADDING)

                -- Use the trade partner's name if available
                local tradeName = tradeInfo:getTradeName()
                if tradeName and tradeName ~= "" then
                    Api.Label.SetText(theirHeader,
                        Api.String.StringToWString(tradeName))
                else
                    Api.Label.SetText(theirHeader,
                        Api.String.GetStringFromTid(TID_THEIR_OFFER))
                end

                -- ---- Item list panes ---- --
                local myPane = n .. "MyPane"
                Api.Window.CreateFromTemplate(myPane, "MongbatWindow", n, true)
                Api.Window.SetDimensions(myPane, COL_W, LIST_H)
                Api.Window.ClearAnchors(myPane)
                Api.Window.AddAnchor(myPane, "topleft", myHeader, "bottomleft",
                    0, PADDING)

                Api.Window.CreateFromTemplate(myScrollChild, "MongbatWindow",
                    myPane, true)
                Api.Window.SetDimensions(myScrollChild, COL_W, LIST_H)
                Api.Window.ClearAnchors(myScrollChild)
                Api.Window.AddAnchor(myScrollChild, "topleft", myPane,
                    "topleft", 0, 0)

                local theirPane = n .. "TheirPane"
                Api.Window.CreateFromTemplate(theirPane, "MongbatWindow", n, true)
                Api.Window.SetDimensions(theirPane, COL_W, LIST_H)
                Api.Window.ClearAnchors(theirPane)
                Api.Window.AddAnchor(theirPane, "topleft", theirHeader,
                    "bottomleft", 0, PADDING)

                Api.Window.CreateFromTemplate(theirScrollChild, "MongbatWindow",
                    theirPane, true)
                Api.Window.SetDimensions(theirScrollChild, COL_W, LIST_H)
                Api.Window.ClearAnchors(theirScrollChild)
                Api.Window.AddAnchor(theirScrollChild, "topleft", theirPane,
                    "topleft", 0, 0)

                -- ---- My gold row ---- --
                local myGoldRow = n .. "MyGoldRow"
                Api.Window.CreateFromTemplate(myGoldRow, "MongbatWindow", n, true)
                Api.Window.SetDimensions(myGoldRow, COL_W, ROW_H)
                Api.Window.ClearAnchors(myGoldRow)
                Api.Window.AddAnchor(myGoldRow, "topleft", myPane,
                    "bottomleft", 0, PADDING)

                local myGoldIcon = n .. "MyGoldIcon"
                makeCurrencyIcon(myGoldIcon, myGoldRow, myGoldRow, "topleft",
                    0, 0, goldTex, goldX, goldY)

                goldEdit:create(true)
                goldEdit:onInitialize()
                goldEdit:setParent(myGoldRow)
                goldEdit:clearAnchors()
                goldEdit:addAnchor("topleft", myGoldIcon, "topright", PADDING, 0)

                -- ---- My plat row ---- --
                local myPlatRow = n .. "MyPlatRow"
                Api.Window.CreateFromTemplate(myPlatRow, "MongbatWindow", n, true)
                Api.Window.SetDimensions(myPlatRow, COL_W, ROW_H)
                Api.Window.ClearAnchors(myPlatRow)
                Api.Window.AddAnchor(myPlatRow, "topleft", myGoldRow,
                    "bottomleft", 0, PADDING)

                local myPlatIcon = n .. "MyPlatIcon"
                makeCurrencyIcon(myPlatIcon, myPlatRow, myPlatRow, "topleft",
                    0, 0, platTex, platX, platY)

                platEdit:create(true)
                platEdit:onInitialize()
                platEdit:setParent(myPlatRow)
                platEdit:clearAnchors()
                platEdit:addAnchor("topleft", myPlatIcon, "topright", PADDING, 0)

                -- ---- Their gold row ---- --
                local theirGoldRow = n .. "TheirGoldRow"
                Api.Window.CreateFromTemplate(theirGoldRow, "MongbatWindow",
                    n, true)
                Api.Window.SetDimensions(theirGoldRow, COL_W, ROW_H)
                Api.Window.ClearAnchors(theirGoldRow)
                Api.Window.AddAnchor(theirGoldRow, "topleft", theirPane,
                    "bottomleft", 0, PADDING)

                local theirGoldIcon = n .. "TheirGoldIcon"
                makeCurrencyIcon(theirGoldIcon, theirGoldRow, theirGoldRow,
                    "topleft", 0, 0, goldTex, goldX, goldY)
                makeCurrencyLabel(theirGoldLabel, theirGoldRow, theirGoldIcon)

                -- ---- Their plat row ---- --
                local theirPlatRow = n .. "TheirPlatRow"
                Api.Window.CreateFromTemplate(theirPlatRow, "MongbatWindow",
                    n, true)
                Api.Window.SetDimensions(theirPlatRow, COL_W, ROW_H)
                Api.Window.ClearAnchors(theirPlatRow)
                Api.Window.AddAnchor(theirPlatRow, "topleft", theirGoldRow,
                    "bottomleft", 0, PADDING)

                local theirPlatIcon = n .. "TheirPlatIcon"
                makeCurrencyIcon(theirPlatIcon, theirPlatRow, theirPlatRow,
                    "topleft", 0, 0, platTex, platX, platY)
                makeCurrencyLabel(theirPlatLabel, theirPlatRow, theirPlatIcon)

                -- ---- My balance row ---- --
                local balGoldRow = n .. "BalGoldRow"
                Api.Window.CreateFromTemplate(balGoldRow, "MongbatWindow", n, true)
                Api.Window.SetDimensions(balGoldRow, COL_W, ROW_H)
                Api.Window.ClearAnchors(balGoldRow)
                Api.Window.AddAnchor(balGoldRow, "topleft", myPlatRow,
                    "bottomleft", 0, PADDING)

                local balGoldIcon = n .. "BalGoldIcon"
                makeCurrencyIcon(balGoldIcon, balGoldRow, balGoldRow,
                    "topleft", 0, 0, goldTex, goldX, goldY)
                makeCurrencyLabel(balGoldLabel, balGoldRow, balGoldIcon)

                local balPlatRow = n .. "BalPlatRow"
                Api.Window.CreateFromTemplate(balPlatRow, "MongbatWindow", n, true)
                Api.Window.SetDimensions(balPlatRow, COL_W, ROW_H)
                Api.Window.ClearAnchors(balPlatRow)
                Api.Window.AddAnchor(balPlatRow, "topleft", balGoldRow,
                    "bottomleft", 0, PADDING)

                local balPlatIcon = n .. "BalPlatIcon"
                makeCurrencyIcon(balPlatIcon, balPlatRow, balPlatRow,
                    "topleft", 0, 0, platTex, platX, platY)
                makeCurrencyLabel(balPlatLabel, balPlatRow, balPlatIcon)

                -- ---- Accept button ---- --
                acceptButton:create(true)
                acceptButton:onInitialize()
                acceptButton:setParent(n)
                acceptButton:clearAnchors()
                acceptButton:addAnchor("topleft", balPlatRow,
                    "bottomleft", 0, PADDING)

                -- ---- Register per-window events for this trade instance ---- --
                Api.Window.RegisterEventHandler(
                    mongbatName,
                    Constants.SystemEvents.OnTradeReceiveClose.getEvent(),
                    "Mongbat.EventHandler.OnTradeReceiveClose"
                )
                Api.Window.RegisterEventHandler(
                    mongbatName,
                    Constants.SystemEvents.OnTradeReceiveAcceptMsg.getEvent(),
                    "Mongbat.EventHandler.OnTradeReceiveAcceptMsg"
                )
                Api.Window.RegisterEventHandler(
                    mongbatName,
                    Constants.SystemEvents.OnTradeReceiveModifyGold.getEvent(),
                    "Mongbat.EventHandler.OnTradeReceiveModifyGold"
                )
                Api.Window.RegisterEventHandler(
                    mongbatName,
                    Constants.SystemEvents.OnTradeReceiveBalance.getEvent(),
                    "Mongbat.EventHandler.OnTradeReceiveBalance"
                )
                Api.Window.RegisterEventHandler(
                    mongbatName,
                    Constants.DataEvents.OnUpdateContainerWindow.getEvent(),
                    "Mongbat.EventHandler.OnUpdateContainerWindow"
                )
                Api.Window.RegisterEventHandler(
                    mongbatName,
                    Constants.DataEvents.OnUpdateObjectInfo.getEvent(),
                    "Mongbat.EventHandler.OnUpdateObjectInfo"
                )

                -- ---- Initial item list population ---- --
                rebuildItemList(myScrollChild,    containerId,
                    myRegisteredItems)
                rebuildItemList(theirScrollChild, containerId2,
                    theirRegisteredItems)
            end,

            -- Drop items into my trade container
            OnLButtonUp = function(self)
                if Data.Drag():isDraggingItem() then
                    Api.Drag.DropOnContainer(containerId, 0)
                end
            end,

            -- Container contents changed
            OnUpdateContainerWindow = function(self, container)
                local cid = container:getId()
                if cid == containerId then
                    rebuildItemList(myScrollChild, cid,
                        myRegisteredItems)
                elseif cid == containerId2 then
                    rebuildItemList(theirScrollChild, cid,
                        theirRegisteredItems)
                end
            end,

            -- Individual item info updated — refresh the affected side
            OnUpdateObjectInfo = function(self, objectInfo)
                local oid = objectInfo:getId()
                if myRegisteredItems[oid] then
                    rebuildItemList(myScrollChild, containerId,
                        myRegisteredItems)
                elseif theirRegisteredItems[oid] then
                    rebuildItemList(theirScrollChild, containerId2,
                        theirRegisteredItems)
                end
            end,

            -- Accept state toggled by either side
            OnTradeReceiveAcceptMsg = function(self, ti)
                if Api.Window.DoesExist(acceptBtnName) then
                    if ti:isMyAccepted() then
                        Api.Button.SetText(acceptBtnName,
                            Api.String.GetStringFromTid(TID_CANCEL))
                    else
                        Api.Button.SetText(acceptBtnName,
                            Api.String.GetStringFromTid(TID_ACCEPT))
                    end
                    -- Lock gold fields while either side has accepted
                    local locked = ti:isMyAccepted() or ti:isTheirAccepted()
                    Api.Window.SetHandleInput(myGoldEditName, not locked)
                    Api.Window.SetHandleInput(myPlatEditName, not locked)
                end
            end,

            -- Partner changed their gold/plat offer
            OnTradeReceiveModifyGold = function(self, ti)
                if Api.Window.DoesExist(theirGoldLabel) then
                    Api.Label.SetText(theirGoldLabel,
                        Api.String.AddCommasToNumber(ti:getTheirGold()))
                end
                if Api.Window.DoesExist(theirPlatLabel) then
                    Api.Label.SetText(theirPlatLabel,
                        Api.String.AddCommasToNumber(ti:getTheirPlat()))
                end
            end,

            -- Balance updated
            OnTradeReceiveBalance = function(self, ti)
                if Api.Window.DoesExist(balGoldLabel) then
                    Api.Label.SetText(balGoldLabel,
                        Api.String.AddCommasToNumber(ti:getMyGoldBalance()))
                end
                if Api.Window.DoesExist(balPlatLabel) then
                    Api.Label.SetText(balPlatLabel,
                        Api.String.AddCommasToNumber(ti:getMyPlatBalance()))
                end
            end,

            -- Trade closed by server or partner
            OnTradeReceiveClose = function(self)
                -- Unregister container and item data
                for id, _ in pairs(myRegisteredItems) do
                    Api.Window.UnregisterData(
                        Constants.DataEvents.OnUpdateObjectInfo.getType(), id)
                end
                for id, _ in pairs(theirRegisteredItems) do
                    Api.Window.UnregisterData(
                        Constants.DataEvents.OnUpdateObjectInfo.getType(), id)
                end
                Api.Window.UnregisterData(
                    Constants.DataEvents.OnUpdateContainerWindow.getType(),
                    containerId)
                Api.Window.UnregisterData(
                    Constants.DataEvents.OnUpdateContainerWindow.getType(),
                    containerId2)
                activeWindows[defaultWindowName] = nil
                destroyTradeWindow(mongbatName)
            end,

            -- Right-click cancels the trade
            OnRButtonUp = function(self)
                Api.Event.Broadcast(Constants.TradeEvents.SendClose())
            end
        }

        window:create(true)
        activeWindows[defaultWindowName] = mongbatName
    end

    -- ------------------------------------------------------------------ --
    -- Override TradeWindow.Initialize
    -- Engine calls this when it creates a new trade window from XML.
    -- ------------------------------------------------------------------ --
    tradeDefault:getDefault().Initialize = function()
        local defaultWindowName = Data.ActiveWindowName()
        local tradeId           = Data.DynamicWindowId()

        -- Hide the default XML window immediately so only our window shows
        if Api.Window.DoesExist(defaultWindowName) then
            Api.Window.SetShowing(defaultWindowName, false)
        end

        createTradeWindow(defaultWindowName, tradeId)
    end

    -- ------------------------------------------------------------------ --
    -- Override TradeWindow.Shutdown
    -- Engine fires this when the XML trade window instance is destroyed.
    -- ------------------------------------------------------------------ --
    tradeDefault:getDefault().Shutdown = function()
        local defaultWindowName = Data.ActiveWindowName()
        local mongbatName       = activeWindows[defaultWindowName]
        if mongbatName then
            destroyTradeWindow(mongbatName)
            activeWindows[defaultWindowName] = nil
        end
        Api.ItemProperties.ClearMouseOverItem()
    end

    -- ------------------------------------------------------------------ --
    -- Override TradeWindow.CloseWindow
    -- Called when TRADE_RECEIVE_CLOSE_WINDOW fires on the default window.
    -- ------------------------------------------------------------------ --
    tradeDefault:getDefault().CloseWindow = function()
        local defaultWindowName = Data.ActiveWindowName()
        local mongbatName       = activeWindows[defaultWindowName]
        if mongbatName then
            destroyTradeWindow(mongbatName)
            activeWindows[defaultWindowName] = nil
        end
        Api.ItemProperties.ClearMouseOverItem()
        if Api.Window.DoesExist(defaultWindowName) then
            Api.Window.Destroy(defaultWindowName)
        end
    end
end

-- ========================================================================== --
-- OnShutdown: restore the original TradeWindow functions and global
-- ========================================================================== --
---@param context Context
local function OnShutdown(context)
    local tradeDefault = context.Components.Defaults.TradeWindow
    -- Restore the individual function overrides so the original table is
    -- pristine before restoring the global pointer.
    if _savedInit then
        tradeDefault:getDefault().Initialize = _savedInit
    end
    if _savedShutdown then
        tradeDefault:getDefault().Shutdown = _savedShutdown
    end
    if _savedClose then
        tradeDefault:getDefault().CloseWindow = _savedClose
    end
    -- Restore _G.TradeWindow = originalTable
    tradeDefault:restoreGlobal()
end

Mongbat.Mod {
    Name         = "MongbatTradeWindow",
    Path         = "/src/mods/mongbat-trade-window",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown
}
