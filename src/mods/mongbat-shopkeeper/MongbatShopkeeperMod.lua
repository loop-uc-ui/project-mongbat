-- ========================================================================== --
-- MongbatShopkeeperMod
-- Replaces the default Shopkeeper (buy/sell) window with a clean Mongbat UI.
-- Uses ListBox components for scrollable item display with auto-population.
-- ========================================================================== --

-- Framework namespaces
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants
local Utils = Mongbat.Utils

-- Window layout constants
local WIN_W        = 720
local WIN_H        = 520
local PANEL_W      = 310
local PANEL_H      = 340
local VISIBLE_ROWS = 12
local ROW_H        = 24
local MARGIN       = 10
local SEARCH_H     = 24
local BTN_W        = 90
local BTN_H        = 28
local TITLE_H      = 24
-- Width of the engine-managed list scrollbar (pixels)
local SCROLLBAR_W  = 22
-- ListBox row column x-offsets (left edges within row content area = PANEL_W - SCROLLBAR_W)
local COL_NAME_X   = 2
local COL_PRICE_X  = 148
local COL_QTY_X    = 215

-- Mutable file-scope: must survive across OnInitialize/OnShutdown.
-- Set when the default Shopkeeper XML window is hidden; cleared on destroy.
local defaultWindowName = nil

local function OnInitialize()
    local shopkeeperDefault = Components.Defaults.Shopkeeper

    -- -----------------------------------------------------------------------
    -- Per-session state (reset each time a vendor window opens)
    -- -----------------------------------------------------------------------
    -- items: array of {id, name, price, totalQty, availQty, cartQty, objType}
    -- Each entry mirrors both the "available" and "cart" quantity for that item.
    local merchantId      = 0
    local isSelling       = false
    local items           = {}
    local filterPatterns  = {}
    local windowView      = nil   -- the main Window view
    local availList       = nil   -- ListBox view for available items
    local cartList        = nil   -- ListBox view for cart items
    local totalLabel      = nil
    local searchBox       = nil
    local sellContainerId = 0

    -- -----------------------------------------------------------------------
    -- Helper: check if an item name matches all current filter patterns
    -- Patterns are plain ASCII lowercased strings.
    -- -----------------------------------------------------------------------
    --- @param name wstring?
    --- @return boolean
    local function matchesFilter(name)
        return Utils.Array.Every(filterPatterns, function(pattern)
            return Utils.String.Contains(name, pattern, true, true)
        end)
    end

    -- -----------------------------------------------------------------------
    -- Compute total purchase cost from cart quantities
    -- -----------------------------------------------------------------------
    --- @return integer
    local function computeTotal()
        return Utils.Array.Reduce(items, function(total, item)
            if item.cartQty > 0 then
                return total + item.cartQty * item.price
            end
            return total
        end, 0)
    end

    -- -----------------------------------------------------------------------
    -- Build filtered view of items (indices into items[])
    -- -----------------------------------------------------------------------
    local function getFilteredAvail()
        return Utils.Array.Indices(items, function(item)
            return item.availQty > 0 and item.price > 0 and matchesFilter(item.name)
        end)
    end

    local function getFilteredCart()
        return Utils.Array.Indices(items, function(item)
            return item.cartQty > 0
        end)
    end

    -- -----------------------------------------------------------------------
    -- Build a ListBox data table mirroring items[] (same indices).
    -- Each entry has { name, price, qty } as wstrings for ListColumn binding.
    -- -----------------------------------------------------------------------
    --- @param isCart boolean  If true, use cartQty; otherwise use availQty
    --- @return table[] dataTable  Indexed 1..#items, fields match ListColumn vars
    local function buildDataTable(isCart)
        local data = {}
        Utils.Array.ForEach(items, function(item, i)
            data[i] = {
                name  = item.name or L"",
                price = Utils.String.Concat(item.price, "g"),
                qty   = Utils.String.Concat(isCart and item.cartQty or item.availQty)
            }
        end)
        return data
    end

    -- -----------------------------------------------------------------------
    -- Refresh both ListBoxes and the total label
    -- -----------------------------------------------------------------------
    local function refreshAll()
        if availList then
            availList:setDataTable(buildDataTable(false))
            availList:setDisplayOrder(getFilteredAvail())
        end
        if cartList then
            cartList:setDataTable(buildDataTable(true))
            cartList:setDisplayOrder(getFilteredCart())
        end
        if totalLabel then
            local total = computeTotal()
            local gold  = Data.PlayerStatus():getGold()
            totalLabel:setText(Utils.String.Concat(total, "/", gold))
        end
    end

    -- -----------------------------------------------------------------------
    -- Populate buy items from WindowData.ContainerWindow
    -- -----------------------------------------------------------------------
    local function loadBuyItems()
        local data = Data.ContainerWindow(sellContainerId)
        if not data then return end

        -- Unregister old items
        Utils.Array.ForEach(items, function(item)
            if item.registered then
                Api.Window.UnregisterData(Constants.DataEvents.OnUpdateObjectInfo.getType(), item.id)
                Api.Window.UnregisterData(Constants.DataEvents.OnUpdateItemProperties.getType(), item.id)
                item.registered = false
            end
        end)

        -- Rebuild items list from container
        local newItems = {}
        Utils.Array.ForEach(data.ContainedItems, function(slot)
            Api.Window.RegisterData(Constants.DataEvents.OnUpdateObjectInfo.getType(), slot.objectId)
            Api.Window.RegisterData(Constants.DataEvents.OnUpdateItemProperties.getType(), slot.objectId)

            local objInfo  = Data.ObjectInfo(slot.objectId)
            local price    = objInfo:getShopValue()
            local qty      = objInfo:getShopQuantity()
            local objType  = objInfo:getObjectType()
            local itemName = "" ---@type string|wstring

            local props = Data.ItemProperties(slot.objectId)
            if props and props.PropertiesList and props.PropertiesList[1] then
                itemName = Utils.String.Replace(props.PropertiesList[1], "^%d+ ", "")
            end

            -- Find existing entry to preserve cartQty
            local existingItem    = Utils.Array.Find(items, function(item) return item.id == slot.objectId end)
            local existingCartQty = existingItem and existingItem.cartQty or 0

            -- Clamp cartQty if vendor has less now
            if existingCartQty > qty then existingCartQty = qty end

            Utils.Array.Add(newItems, {
                id         = slot.objectId,
                name       = itemName,
                price      = price,
                totalQty   = qty,
                availQty   = qty - existingCartQty,
                cartQty    = existingCartQty,
                objType    = objType,
                registered = true
            })
        end)
        items = newItems
    end

    -- -----------------------------------------------------------------------
    -- Populate sell items from WindowData.ShopData.Sell
    -- -----------------------------------------------------------------------
    local function loadSellItems()
        items = {}
        local shopData = Data.ShopData()
        Utils.Array.ForEach(shopData:getSellItems(), function(entry)
            Utils.Array.Add(items, {
                id       = entry.id,
                name     = Utils.String.Replace(entry.name, "^%d+ ", ""),
                price    = entry.price,
                totalQty = entry.quantity,
                availQty = entry.quantity,
                cartQty  = 0,
                objType  = entry.objType
            })
        end)
    end

    -- -----------------------------------------------------------------------
    -- Move units from available -> cart
    -- -----------------------------------------------------------------------
    --- @param itemIdx integer
    --- @param amount integer?
    local function addToCart(itemIdx, amount)
        amount = amount or 1
        local item = items[itemIdx]
        if not item then return end
        if item.availQty < amount then amount = item.availQty end
        if amount <= 0 then return end
        item.availQty = item.availQty - amount
        item.cartQty  = item.cartQty  + amount
        refreshAll()
    end

    -- -----------------------------------------------------------------------
    -- Move units from cart -> available
    -- -----------------------------------------------------------------------
    --- @param itemIdx integer
    --- @param amount integer?
    local function removeFromCart(itemIdx, amount)
        amount = amount or 1
        local item = items[itemIdx]
        if not item then return end
        if item.cartQty < amount then amount = item.cartQty end
        if amount <= 0 then return end
        item.cartQty  = item.cartQty  - amount
        item.availQty = item.availQty + amount
        refreshAll()
    end

    -- -----------------------------------------------------------------------
    -- Clear all cart selections (reset to available)
    -- -----------------------------------------------------------------------
    local function clearCart()
        Utils.Array.ForEach(items, function(item)
            item.availQty = item.totalQty
            item.cartQty  = 0
        end)
        refreshAll()
    end

    -- -----------------------------------------------------------------------
    -- Execute the transaction: populate OfferIds/OfferQuantities and broadcast
    -- -----------------------------------------------------------------------
    local function acceptOffer()
        local offerIds  = {}
        local offerQtys = {}
        Utils.Array.ForEach(items, function(item)
            if item.cartQty > 0 then
                Utils.Array.Add(offerIds,  item.id)
                Utils.Array.Add(offerQtys, item.cartQty)
            end
        end)
        if Utils.Array.IsEmpty(offerIds) then
            Api.Window.Destroy("MongbatShopkeeperWindow")
            return
        end
        Data.ShopData():setOffer(offerIds, offerQtys)
        Api.Event.Broadcast(Constants.Broadcasts.ShopOfferAccept())
        Api.Window.Destroy("MongbatShopkeeperWindow")
    end

    -- -----------------------------------------------------------------------
    -- Cancel: broadcast cancel and destroy window
    -- -----------------------------------------------------------------------
    local function cancelOffer()
        Api.Event.Broadcast(Constants.Broadcasts.ShopCancelOffer())
        Api.Window.Destroy("MongbatShopkeeperWindow")
    end

    -- -----------------------------------------------------------------------
    -- Item tooltip helper
    -- -----------------------------------------------------------------------
    --- @param itemIdx integer
    local function showItemTooltip(itemIdx)
        local item = items[itemIdx]
        if not item or item.id == 0 then return end
        local itemData = {
            windowName = "MongbatShopkeeperWindow",
            itemId     = item.id,
            itemType   = Constants.ItemPropertyType.Item,
            detail     = Constants.ItemPropertyDetail.Long
        }
        Api.ItemProperties.SetActiveItem(itemData)
    end

    -- -----------------------------------------------------------------------
    -- Set column anchors for all visible rows of a list box.
    -- Called after setVisibleRowCount() so the row windows exist.
    -- Columns: Name | Price | Qty, with SCROLLBAR_W clear on the right.
    -- Row width is explicitly constrained so content does not extend
    -- under the engine-managed scrollbar.
    -- -----------------------------------------------------------------------
    --- @param listName string  The engine window name of the ListBox
    local function applyRowColumnAnchors(listName)
        local rowContentWidth = PANEL_W - SCROLLBAR_W
        for rowIdx = 1, VISIBLE_ROWS do
            local rowName = listName .. "Row" .. rowIdx
            -- Constrain row width so it stops before the scrollbar
            Api.Window.SetDimensions(rowName, rowContentWidth, ROW_H)
            local nameWin  = rowName .. "Name"
            local priceWin = rowName .. "Price"
            local qtyWin   = rowName .. "Qty"
            Api.Window.ClearAnchors(nameWin)
            Api.Window.AddAnchor(nameWin,  "left", rowName, "left", COL_NAME_X,  0)
            Api.Window.ClearAnchors(priceWin)
            Api.Window.AddAnchor(priceWin, "left", rowName, "left", COL_PRICE_X, 0)
            Api.Window.ClearAnchors(qtyWin)
            Api.Window.AddAnchor(qtyWin,   "left", rowName, "left", COL_QTY_X,   0)
        end
    end

    -- -----------------------------------------------------------------------
    -- Build the complete shopkeeper window
    -- -----------------------------------------------------------------------
    --- @param mId integer Merchant entity ID
    --- @param isSell boolean True for sell mode, false for buy mode
    local function createShopWindow(mId, isSell)
        merchantId = mId
        isSelling  = isSell

        -- Load initial data
        if isSelling then
            loadSellItems()
        else
            loadBuyItems()
        end

        -- Title text
        local titleText
        if isSelling then
            titleText = "Sellable Items"
        else
            -- Try to get the merchant's name
            local mobileName = Data.MobileName(mId)
            local mobData    = mobileName and mobileName:getData()
            if mobData and not Utils.String.IsEmpty(mobData.MobName) then
                titleText = mobData.MobName
            else
                titleText = "NPC Store"
            end
        end

        -- Panel headers
        local availHdr = isSelling and "Sellable" or "Available"
        local cartHdr  = isSelling and "Sell List" or "Cart"

        -- Title label
        local titleLabel = Components.Label {
            OnInitialize = function(self)
                self:setDimensions(WIN_W - MARGIN * 2, TITLE_H)
                self:setText(titleText)
                self:centerText()
            end
        }

        -- Search box
        searchBox = Components.EditTextBox {
            OnInitialize = function(self)
                self:setDimensions(PANEL_W - 58, SEARCH_H)
            end,
            OnKeyEnter = function(_)
                local text = searchBox:getText()
                if not Utils.String.IsEmpty(text) then
                    Utils.Array.AddUnique(filterPatterns, Utils.String.Lower(text))
                    refreshAll()
                end
            end
        }

        -- Clear filter button
        local clearFilterBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(52, SEARCH_H)
                self:setText("Clear")
            end,
            OnLButtonUp = function(_)
                filterPatterns = {}
                if searchBox then
                    searchBox:setText("")
                end
                refreshAll()
            end
        }

        -- Available panel header
        local availHeader = Components.Label {
            OnInitialize = function(self)
                self:setDimensions(PANEL_W, 20)
                self:setText(availHdr)
                self:centerText()
            end
        }

        -- Cart panel header
        local cartHeader = Components.Label {
            OnInitialize = function(self)
                self:setDimensions(PANEL_W, 20)
                self:setText(cartHdr)
                self:centerText()
            end
        }

        -- Available items ListBox
        -- Left-click on a row adds one unit of that item to the cart.
        availList = Components.ListBox {
            Template = "ShopkeeperItemList",
            OnInitialize = function(self)
                self:setDimensions(PANEL_W, PANEL_H)
                self:setVisibleRowCount(VISIBLE_ROWS)
                applyRowColumnAnchors(self:getName())
                self:setDataTable(buildDataTable(false))
                self:setDisplayOrder(getFilteredAvail())
            end,
            OnLButtonDown = function(self)
                local dataIdx = self:getClickedDataIndex()
                if dataIdx and dataIdx > 0 then
                    addToCart(dataIdx, 1)
                end
            end,
            OnMouseOver = function(self)
                local dataIdx = self:getHoveredDataIndex()
                if dataIdx and dataIdx > 0 then
                    showItemTooltip(dataIdx)
                end
            end,
            OnMouseOverEnd = function(_)
                Api.ItemProperties.ClearMouseOverItem()
            end
        }

        -- Cart items ListBox
        -- Left-click on a row removes one unit of that item from the cart.
        cartList = Components.ListBox {
            Template = "ShopkeeperItemList",
            OnInitialize = function(self)
                self:setDimensions(PANEL_W, PANEL_H)
                self:setVisibleRowCount(VISIBLE_ROWS)
                applyRowColumnAnchors(self:getName())
                self:setDataTable(buildDataTable(true))
                self:setDisplayOrder(getFilteredCart())
            end,
            OnLButtonDown = function(self)
                local dataIdx = self:getClickedDataIndex()
                if dataIdx and dataIdx > 0 then
                    removeFromCart(dataIdx, 1)
                end
            end,
            OnMouseOver = function(self)
                local dataIdx = self:getHoveredDataIndex()
                if dataIdx and dataIdx > 0 then
                    showItemTooltip(dataIdx)
                end
            end,
            OnMouseOverEnd = function(_)
                Api.ItemProperties.ClearMouseOverItem()
            end
        }

        -- Total gold label (shows cost/gold)
        totalLabel = Components.Label {
            OnInitialize = function(self)
                self:setDimensions(200, 22)
            end
        }

        -- Accept button
        local acceptBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(BTN_W, BTN_H)
                self:setText(isSelling and "Sell" or "Buy")
            end,
            OnLButtonUp = function(_)
                acceptOffer()
            end
        }

        -- Clear cart / Cancel button
        local cancelBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(BTN_W, BTN_H)
                self:setText("Clear")
            end,
            OnLButtonUp = function(_)
                clearCart()
            end
        }

        -- Close button
        local closeBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(BTN_W, BTN_H)
                self:setText("Close")
            end,
            OnLButtonUp = function(_)
                cancelOffer()
            end
        }

        -- Children in layout order
        local children = {
            titleLabel,     -- 1
            searchBox,      -- 2
            clearFilterBtn, -- 3
            availHeader,    -- 4
            cartHeader,     -- 5
            availList,      -- 6
            cartList,       -- 7
            totalLabel,     -- 8
            acceptBtn,      -- 9
            cancelBtn,      -- 10
            closeBtn        -- 11
        }

        local IDX_TITLE     = 1
        local IDX_SEARCH    = 2
        local IDX_CLRFILTER = 3
        local IDX_AVAILHDR  = 4
        local IDX_CARTHDR   = 5
        local IDX_AVAIL     = 6
        local IDX_CART      = 7
        local IDX_TOTAL     = 8
        local IDX_ACCEPT    = 9
        local IDX_CANCEL    = 10
        local IDX_CLOSE     = 11

        local panelTop = MARGIN + TITLE_H + MARGIN + SEARCH_H + MARGIN

        -- Build the Window model.  Buy-mode update handlers are added
        -- conditionally so the framework only registers those events in buy mode.
        local windowModel = {
            Name      = "MongbatShopkeeperWindow",
            Resizable = false,
            OnInitialize = function(self)
                self:setDimensions(WIN_W, WIN_H)
                self:setChildren(children)
                self:setId(merchantId)
            end,
            OnUpdatePlayerStatus = function(_, ps)
                if totalLabel then
                    local total = computeTotal()
                    local gold  = ps:getGold()
                    totalLabel:setText(Utils.String.Concat(total, "/", gold))
                end
            end,
            OnLayout = function(win, _, child, idx)
                local winName = win:getName()
                if idx == IDX_TITLE then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft", MARGIN, MARGIN)
                elseif idx == IDX_SEARCH then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN, MARGIN + TITLE_H + MARGIN)
                elseif idx == IDX_CLRFILTER then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN + (PANEL_W - 58) + 4,
                        MARGIN + TITLE_H + MARGIN)
                elseif idx == IDX_AVAILHDR then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN, panelTop)
                elseif idx == IDX_CARTHDR then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN + PANEL_W + MARGIN, panelTop)
                elseif idx == IDX_AVAIL then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN, panelTop + 22)
                elseif idx == IDX_CART then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN + PANEL_W + MARGIN, panelTop + 22)
                elseif idx == IDX_TOTAL then
                    child:clearAnchors()
                    child:addAnchor("bottomleft", winName, "bottomleft",
                        MARGIN, -MARGIN - BTN_H)
                elseif idx == IDX_ACCEPT then
                    child:clearAnchors()
                    child:addAnchor("bottomright", winName, "bottomright",
                        -MARGIN - BTN_W * 2 - 8, -MARGIN)
                elseif idx == IDX_CANCEL then
                    child:clearAnchors()
                    child:addAnchor("bottomright", winName, "bottomright",
                        -MARGIN - BTN_W - 4, -MARGIN)
                elseif idx == IDX_CLOSE then
                    child:clearAnchors()
                    child:addAnchor("bottomright", winName, "bottomright",
                        -MARGIN, -MARGIN)
                end
            end,
            OnShutdown = function(_)
                -- Unregister mode-specific data
                if not isSelling then
                    -- Buy mode: unregister merchant ObjectInfo, container, MobileName, and items
                    Api.Window.UnregisterData(Constants.DataEvents.OnUpdateObjectInfo.getType(), merchantId)
                    Api.Window.UnregisterData(Constants.DataEvents.OnUpdateContainerWindow.getType(), sellContainerId)
                    Api.Window.UnregisterData(Constants.DataEvents.OnUpdateMobileName.getType(), merchantId)
                    Utils.Array.ForEach(items, function(item)
                        if item.registered then
                            Api.Window.UnregisterData(Constants.DataEvents.OnUpdateObjectInfo.getType(), item.id)
                            Api.Window.UnregisterData(Constants.DataEvents.OnUpdateItemProperties.getType(), item.id)
                            item.registered = false
                        end
                    end)
                end
                -- PlayerStatus was registered in Initialize; unregister it here
                Api.Window.UnregisterData(Constants.DataEvents.OnUpdatePlayerStatus.getType(), 0)
                -- Explicitly destroy child ListBoxes to clean up their _G DataTable globals
                -- before the parent window teardown clears the parent's own DataTable.
                if availList then
                    Api.Window.Destroy(availList:getName())
                end
                if cartList then
                    Api.Window.Destroy(cartList:getName())
                end
                -- Reset per-session state
                items           = {}
                filterPatterns  = {}
                windowView      = nil
                availList       = nil
                cartList        = nil
                totalLabel      = nil
                searchBox       = nil
                sellContainerId = 0
                -- Destroy the hidden default window to fully end the
                -- engine-side shop session.  If the Shutdown override
                -- already cleared it (server-initiated close), this is
                -- a no-op.
                if defaultWindowName then
                    Api.Window.Destroy(defaultWindowName)
                    defaultWindowName = nil
                end
            end
        }

        -- Declarative buy-mode event handlers.  The framework registers these
        -- automatically via View:onInitialize() when they appear as model keys.
        -- SystemData.ActiveWindow.name resolves to "MongbatShopkeeperWindow"
        -- when ContainerWindow / ObjectInfo / ItemProperties events fire, so
        -- the framework dispatches them here via Cache["MongbatShopkeeperWindow"].
        if not isSelling then
            windowModel.OnUpdateContainerWindow = function(_, instanceId)
                if instanceId == sellContainerId then
                    loadBuyItems()
                    refreshAll()
                end
            end

            windowModel.OnUpdateObjectInfo = function(_, instanceId, objInfo)
                local found = Utils.Array.Find(items, function(item) return item.id == instanceId end)
                if found then
                    local oldCart  = found.cartQty
                    local newTotal = objInfo:getShopQuantity()
                    if oldCart > newTotal then oldCart = newTotal end
                    found.totalQty = newTotal
                    found.availQty = newTotal - oldCart
                    found.cartQty  = oldCart
                    found.price    = objInfo:getShopValue()
                    found.objType  = objInfo:getObjectType()
                end
                refreshAll()
            end

            windowModel.OnUpdateItemProperties = function(_, instanceId, props)
                if props and props.PropertiesList and props.PropertiesList[1] then
                    local name  = Utils.String.Replace(props.PropertiesList[1], "^%d+ ", "")
                    local found = Utils.Array.Find(items, function(item) return item.id == instanceId end)
                    if found then
                        found.name = name
                    end
                end
                refreshAll()
            end
        end

        windowView = Components.Window(windowModel)
        windowView:create(true)

        -- Initial refresh
        refreshAll()
    end

    -- -----------------------------------------------------------------------
    -- disable() must be called BEFORE setting overrides.  disable() sets
    -- _disabled=true on the proxy.  Override assignments go to _overrides
    -- (not _original), so they are unaffected by the disabled state.
    -- Any call to an _overrides key bypasses _disabled and executes our
    -- custom function; calls to original-only keys return no-ops.
    -- restore() clears _overrides and sets _disabled=false, reverting
    -- everything cleanly without any manual save/restore bookkeeping.
    -- -----------------------------------------------------------------------
    shopkeeperDefault:disable()

    shopkeeperDefault:getDefault().Initialize = function()
        local defaultWin = Api.Window.GetActiveWindowName()
        local mId        = Api.Window.GetDynamicWindowId()

        -- Hide the default Shopkeeper XML window instead of destroying it.
        -- The engine expects this window to exist for the shop session;
        -- destroying it may trigger a deferred Shutdown callback or cause
        -- the engine to close the shop session internally.
        Api.Window.SetShowing(defaultWin, false)
        defaultWindowName = defaultWin

        -- Destroy any leftover Mongbat shopkeeper window
        Api.Window.Destroy("MongbatShopkeeperWindow")

        local isSell = Data.ShopData():isSelling()

        -- For buy mode: register ObjectInfo to get sellContainerId
        if not isSell then
            Api.Window.RegisterData(Constants.DataEvents.OnUpdateObjectInfo.getType(), mId)
            sellContainerId = Data.ObjectInfo(mId):getSellContainerId()
            Api.Window.RegisterData(Constants.DataEvents.OnUpdateContainerWindow.getType(), sellContainerId)
            Api.Window.RegisterData(Constants.DataEvents.OnUpdateMobileName.getType(), mId)
        end

        -- Register PlayerStatus for gold display
        Api.Window.RegisterData(Constants.DataEvents.OnUpdatePlayerStatus.getType(), 0)

        createShopWindow(mId, isSell)
    end

    -- Override Shopkeeper.Shutdown -- called when the default XML window is torn
    -- down (e.g. server closes shop).  Broadcast cancel and destroy our window
    -- if it is still open; our window's OnShutdown handles data cleanup.
    shopkeeperDefault:getDefault().Shutdown = function()
        -- Prevent MongbatShopkeeperWindow OnShutdown from trying to
        -- destroy the default window again (it's already being destroyed
        -- by the engine right now).
        defaultWindowName = nil
        if windowView ~= nil then
            Api.Event.Broadcast(Constants.Broadcasts.ShopCancelOffer())
            Api.Window.Destroy("MongbatShopkeeperWindow")
        end
    end
end

local function OnShutdown()
    Api.Window.Destroy("MongbatShopkeeperWindow")

    -- Destroy the hidden default window if it's still alive (e.g. shop
    -- was open when the mod was unloaded).
    if defaultWindowName then
        Api.Window.Destroy(defaultWindowName)
        defaultWindowName = nil
    end

    -- restore() clears all _overrides (Initialize/Shutdown hooks) and
    -- re-enables the original Shopkeeper functions.
    local shopkeeperDefault = Components.Defaults.Shopkeeper
    shopkeeperDefault:restore()
end

Mongbat.Mod {
    Name = "MongbatShopkeeper",
    Path = "/src/mods/mongbat-shopkeeper",
    Files = { "MongbatShopkeeper.xml" },
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown
}
