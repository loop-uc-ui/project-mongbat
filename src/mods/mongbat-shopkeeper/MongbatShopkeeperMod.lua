-- ========================================================================== --
-- MongbatShopkeeperMod
-- Replaces the default Shopkeeper (buy/sell) window with a clean Mongbat UI.
-- ========================================================================== --

-- Window layout constants
local Api = Mongbat.Api
local Data = Mongbat.Data
local Components = Mongbat.Components
local Constants = Mongbat.Constants
local Utils = Mongbat.Utils

local WIN_W          = 720
local WIN_H          = 520
local PANEL_W        = 310
local PANEL_H        = 340
local ROW_H          = 36
local ICON_SIZE      = 28
local ITEMS_PER_PAGE = 9
local MARGIN         = 10
local SEARCH_H       = 24
local BTN_W          = 90
local BTN_H          = 28
local TITLE_H        = 24
local HDR_H          = 20

-- Icon scaling constants for RequestTileArt
local ICON_SCALE_MAX  = 10
local ICON_SCALE_MIN  = 0.1
local ICON_SCALE_STEP = 0.1

-- Mutable file-scope: must survive across OnInitialize/OnShutdown.
-- Set when the default Shopkeeper XML window is hidden; cleared on destroy.
local defaultWindowName = nil

local function OnInitialize()
    local Api        = Api
    local Data       = Data
    local Utils      = Utils
    local Constants  = Constants
    local Components = Components

    local shopkeeperDefault = Components.Defaults.Shopkeeper

    -- -----------------------------------------------------------------------
    -- Per-session state (reset each time a vendor window opens)
    -- -----------------------------------------------------------------------
    -- items: array of {id, name, price, totalQty, availQty, cartQty, objType}
    -- Each entry mirrors both the "available" and "cart" quantity for that item.
    local merchantId        = 0
    local isSelling         = false
    local items             = {}
    local filterPatterns    = {}
    local availPage         = 1
    local cartPage          = 1
    local windowView        = nil   -- the main Window view
    local availRowViews     = {}    -- Views for available-items rows
    local cartRowViews      = {}    -- Views for cart-items rows
    local availPrevBtn      = nil
    local availNextBtn      = nil
    local cartPrevBtn       = nil
    local cartNextBtn       = nil
    local totalLabel        = nil
    local searchBox         = nil
    local sellContainerId   = 0

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
    -- Update a single row with item data (or clear it)
    -- -----------------------------------------------------------------------
    --- @param rowData table? { view, iconView, nameView, priceView, qtyView, addBtn, remBtn }
    --- @param itemIdx integer?
    --- @param isCart boolean
    local function updateRowView(rowData, itemIdx, isCart)
        if not rowData then return end
        local iconView  = rowData.iconView
        local nameView  = rowData.nameView
        local priceView = rowData.priceView
        local qtyView   = rowData.qtyView
        local addBtn    = rowData.addBtn
        local remBtn    = rowData.remBtn

        if itemIdx == nil then
            -- Clear the row
            if iconView  then iconView:setShowing(false) end
            if nameView  then nameView:setShowing(false) end
            if priceView then priceView:setShowing(false) end
            if qtyView   then qtyView:setShowing(false) end
            if addBtn    then addBtn:setShowing(false) end
            if remBtn    then remBtn:setShowing(false) end
            return
        end

        local item = items[itemIdx]
        local qty  = isCart and item.cartQty or item.availQty

        if iconView then
            iconView:setShowing(true)
            iconView:setId(itemIdx)
            if isSelling then
                -- Sell mode: items are in player backpack; use TileArt for icon display
                local name, x, y, scale, nw, nh = Api.Icon.RequestTileArt(item.objType, 300, 300)
                if name and nw and nh then
                    scale = ICON_SCALE_MAX
                    if nw * scale > ICON_SIZE or nh * scale > ICON_SIZE then
                        for j = scale, ICON_SCALE_MIN, -ICON_SCALE_STEP do
                            if nw * j <= ICON_SIZE and nh * j <= ICON_SIZE then
                                scale = j
                                break
                            end
                        end
                    end
                    iconView:setTextureDimensions(nw * scale, nh * scale)
                    iconView:setDimensions(nw * scale, nh * scale)
                    iconView:setTexture(name, x, y)
                    iconView:setTextureScale(scale)
                end
            else
                -- Buy mode: use ObjectInfo (shop-registered items have ObjectInfo data)
                local objInfo = Data.ObjectInfo(item.id)
                if objInfo:exists() then
                    iconView:updateItemIcon(objInfo)
                end
            end
        end

        if nameView then
            nameView:setShowing(true)
            nameView:setId(itemIdx)
            nameView:setText(item.name)
        end

        if priceView then
            priceView:setShowing(true)
            priceView:setText(Utils.String.Concat(item.price, "g"))
        end

        if qtyView then
            qtyView:setShowing(true)
            qtyView:setText(Utils.String.Concat(qty))
        end

        if addBtn then
            addBtn:setShowing(true)
            addBtn:setId(itemIdx)
        end

        if remBtn then
            remBtn:setShowing(true)
            remBtn:setId(itemIdx)
        end
    end

    -- -----------------------------------------------------------------------
    -- Refresh the available-items panel
    -- -----------------------------------------------------------------------
    local function refreshAvailPanel()
        local filtered = getFilteredAvail()
        local total    = #filtered
        local maxPage  = math.max(1, math.ceil(total / ITEMS_PER_PAGE))
        if availPage > maxPage then availPage = maxPage end

        local startIdx = (availPage - 1) * ITEMS_PER_PAGE + 1

        Utils.Array.ForEach(availRowViews, function(rowData, row)
            local filtIdx = startIdx + row - 1
            local itemIdx = filtered[filtIdx]
            updateRowView(rowData, itemIdx, false)
        end)

        if availPrevBtn then availPrevBtn:setShowing(availPage > 1) end
        if availNextBtn then availNextBtn:setShowing(availPage < maxPage) end
    end

    -- -----------------------------------------------------------------------
    -- Refresh the cart panel
    -- -----------------------------------------------------------------------
    local function refreshCartPanel()
        local filtered = getFilteredCart()
        local total    = #filtered
        local maxPage  = math.max(1, math.ceil(total / ITEMS_PER_PAGE))
        if cartPage > maxPage then cartPage = maxPage end

        local startIdx = (cartPage - 1) * ITEMS_PER_PAGE + 1

        Utils.Array.ForEach(cartRowViews, function(rowData, row)
            local filtIdx = startIdx + row - 1
            local itemIdx = filtered[filtIdx]
            updateRowView(rowData, itemIdx, true)
        end)

        if cartPrevBtn then cartPrevBtn:setShowing(cartPage > 1) end
        if cartNextBtn then cartNextBtn:setShowing(cartPage < maxPage) end
    end

    -- -----------------------------------------------------------------------
    -- Refresh both panels and the total label
    -- -----------------------------------------------------------------------
    local function refreshAll()
        refreshAvailPanel()
        refreshCartPanel()
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
    -- Move one unit from available ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ cart
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
    -- Move one unit from cart ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ available
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
    -- Add ALL available units of an item to cart
    -- -----------------------------------------------------------------------
    --- @param itemIdx integer
    local function addAllToCart(itemIdx)
        local item = items[itemIdx]
        if not item or item.availQty == 0 then return end
        item.cartQty  = item.cartQty  + item.availQty
        item.availQty = 0
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
        availPage = 1
        cartPage  = 1
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
    -- Build a single item row (shared between avail and cart panels)
    -- isCartPanel: boolean ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â if true, the + button adds-all, - removes one
    -- -----------------------------------------------------------------------
    --- @param isCartPanel boolean If true, + button adds-all, - removes one
    --- @return table { view: Window, iconView: DynamicImage, nameView: Label, priceView: Label, qtyView: Label, addBtn: Button, remBtn: Button }
    local function ItemRow(isCartPanel)
        local iconView  = nil
        local nameView  = nil
        local priceView = nil
        local qtyView   = nil
        local addBtn    = nil
        local remBtn    = nil

        -- Item icon
        iconView = Components.DynamicImage {
            OnInitialize = function(self)
                self:setDimensions(ICON_SIZE, ICON_SIZE)
                self:setShowing(false)
            end,
            OnMouseOver = function(self)
                local idx = self:getId()
                if idx and idx > 0 then showItemTooltip(idx) end
            end,
            OnMouseOverEnd = function(self)
                Api.ItemProperties.ClearMouseOverItem()
            end,
            OnLButtonDown = function(self)
                local idx = self:getId()
                if idx and idx > 0 then
                    if isCartPanel then
                        removeFromCart(idx, 1)
                    else
                        addToCart(idx, 1)
                    end
                end
            end
        }

        -- Item name label
        nameView = Components.Label {
            OnInitialize = function(self)
                self:setDimensions(110, ROW_H)
                self:setShowing(false)
            end,
            OnMouseOver = function(self)
                local idx = self:getId()
                if idx and idx > 0 then showItemTooltip(idx) end
            end,
            OnMouseOverEnd = function(self)
                Api.ItemProperties.ClearMouseOverItem()
            end
        }

        -- Price label
        priceView = Components.Label {
            OnInitialize = function(self)
                self:setDimensions(55, ROW_H)
                self:setShowing(false)
            end
        }

        -- Quantity label
        qtyView = Components.Label {
            OnInitialize = function(self)
                self:setDimensions(28, ROW_H)
                self:centerText()
                self:setShowing(false)
            end
        }

        -- Add / All button
        addBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(22, 22)
                self:setText(isCartPanel and "All" or "+")
                self:setShowing(false)
            end,
            OnLButtonUp = function(self)
                local idx = self:getId()
                if idx and idx > 0 then
                    if isCartPanel then
                        addAllToCart(idx)
                    else
                        addToCart(idx, 1)
                    end
                end
            end
        }

        -- Remove / - button
        remBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(22, 22)
                self:setText("-")
                self:setShowing(false)
            end,
            OnLButtonUp = function(self)
                local idx = self:getId()
                if idx and idx > 0 then
                    removeFromCart(idx, 1)
                end
            end
        }

        -- Row container window
        local rowView = Components.Window {
            OnInitialize = function(self)
                self:setDimensions(PANEL_W - MARGIN * 2, ROW_H)
                self:setChildren { iconView, nameView, priceView, qtyView, addBtn, remBtn }
            end,
            OnLayout = function(win, _, child, idx)
                local winName = win:getName()
                -- Absolute offsets: [icon(28)] [name(110)] [price(50)] [qty(28)] [+btn(22)] [-btn(22)]
                if idx == 1 then
                    child:clearAnchors()
                    child:addAnchor("left", winName, "left", 2, 0)
                elseif idx == 2 then
                    child:clearAnchors()
                    child:addAnchor("left", winName, "left", ICON_SIZE + 4, 0)
                elseif idx == 3 then
                    child:clearAnchors()
                    child:addAnchor("left", winName, "left", ICON_SIZE + 4 + 112, 0)
                elseif idx == 4 then
                    child:clearAnchors()
                    child:addAnchor("left", winName, "left", ICON_SIZE + 4 + 112 + 52, 0)
                elseif idx == 5 then
                    child:clearAnchors()
                    child:addAnchor("right", winName, "right", -26, 0)
                elseif idx == 6 then
                    child:clearAnchors()
                    child:addAnchor("right", winName, "right", -2, 0)
                end
            end
        }

        -- Stash child refs alongside the row view for later refresh
        return {
            view      = rowView,
            iconView  = iconView,
            nameView  = nameView,
            priceView = priceView,
            qtyView   = qtyView,
            addBtn    = addBtn,
            remBtn    = remBtn
        }
    end

    -- -----------------------------------------------------------------------
    -- Build a panel (available or cart)
    -- isCartPanel controls button semantics
    -- Returns {panelWindow, rowViews, prevBtn, nextBtn}
    -- -----------------------------------------------------------------------
    --- @param headerText string
    --- @param isCartPanel boolean
    --- @return Window panelWindow
    --- @return table[] rowViews Array of ItemRow tables
    --- @return Button prevBtn
    --- @return Button nextBtn
    local function Panel(headerText, isCartPanel)
        local rowViews = {}
        local prevBtn  = nil
        local nextBtn  = nil

        -- Header label
        local hdrLabel = Components.Label {
            OnInitialize = function(self)
                self:setDimensions(PANEL_W - MARGIN * 2, HDR_H)
                self:setText(headerText)
                self:centerText()
            end
        }

        -- Item rows
        local children = { hdrLabel }
        for row = 1, ITEMS_PER_PAGE do
            local itemRow = ItemRow(isCartPanel)
            rowViews[row] = itemRow
            Utils.Array.Add(children, itemRow.view)
        end

        -- Pagination buttons
        prevBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(BTN_W / 2, 22)
                self:setText("< Prev")
                self:setShowing(false)
            end,
            OnLButtonUp = function(self)
                if isCartPanel then
                    if cartPage > 1 then
                        cartPage = cartPage - 1
                        refreshCartPanel()
                    end
                else
                    if availPage > 1 then
                        availPage = availPage - 1
                        refreshAvailPanel()
                    end
                end
            end
        }

        nextBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(BTN_W / 2, 22)
                self:setText("Next >")
                self:setShowing(false)
            end,
            OnLButtonUp = function(self)
                if isCartPanel then
                    cartPage = cartPage + 1
                    refreshCartPanel()
                else
                    availPage = availPage + 1
                    refreshAvailPanel()
                end
            end
        }

        Utils.Array.Add(children, prevBtn)
        Utils.Array.Add(children, nextBtn)

        local panelWindow = Components.Window {
            OnInitialize = function(self)
                self:setDimensions(PANEL_W, PANEL_H)
                self:setChildren(children)
            end,
            OnLayout = function(win, _, child, idx)
                local winName = win:getName()
                if idx == 1 then
                    -- Header at top
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft", MARGIN, MARGIN)
                elseif idx >= 2 and idx <= ITEMS_PER_PAGE + 1 then
                    -- Item rows stacked
                    local row = idx - 1
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN,
                        MARGIN + HDR_H + MARGIN + (row - 1) * (ROW_H + 2))
                elseif idx == ITEMS_PER_PAGE + 2 then
                    -- Prev button
                    child:clearAnchors()
                    child:addAnchor("bottomleft", winName, "bottomleft", MARGIN, -MARGIN)
                elseif idx == ITEMS_PER_PAGE + 3 then
                    -- Next button
                    child:clearAnchors()
                    child:addAnchor("bottomright", winName, "bottomright", -MARGIN, -MARGIN)
                end
            end
        }

        return panelWindow, rowViews, prevBtn, nextBtn
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

        -- Available panel
        local availHdr  = isSelling and "Sellable" or "Available"
        local cartHdr   = isSelling and "Sell List" or "Cart"

        local availPanel, aRows, aPrev, aNext = Panel(availHdr, false)
        local cartPanel,  cRows, cPrev, cNext = Panel(cartHdr, true)

        availRowViews = aRows
        cartRowViews  = cRows
        availPrevBtn  = aPrev
        availNextBtn  = aNext
        cartPrevBtn   = cPrev
        cartNextBtn   = cNext

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
                self:setDimensions(PANEL_W - 50, SEARCH_H)
            end,
            OnKeyEnter = function(_)
                local text = searchBox:getText()
                if not Utils.String.IsEmpty(text) then
                    Utils.Array.AddUnique(filterPatterns, Utils.String.Lower(text))
                    availPage = 1
                    refreshAvailPanel()
                end
            end
        }

        -- Clear filter button
        local clearFilterBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(44, SEARCH_H)
                self:setText("Clear")
            end,
            OnLButtonUp = function(_)
                filterPatterns = {}
                if searchBox then
                    searchBox:setText("")
                end
                availPage = 1
                refreshAvailPanel()
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
            titleLabel,    -- 1
            searchBox,     -- 2
            clearFilterBtn,-- 3
            availPanel,    -- 4
            cartPanel,     -- 5
            totalLabel,    -- 6
            acceptBtn,     -- 7
            cancelBtn,     -- 8
            closeBtn       -- 9
        }

        local IDX_TITLE      = 1
        local IDX_SEARCH     = 2
        local IDX_CLRFILTER  = 3
        local IDX_AVAIL      = 4
        local IDX_CART       = 5
        local IDX_TOTAL      = 6
        local IDX_ACCEPT     = 7
        local IDX_CANCEL     = 8
        local IDX_CLOSE      = 9

        -- Build the Window model.  Buy-mode update handlers are added
        -- conditionally so the framework only registers those events in buy mode.
        local windowModel = {
            Name     = "MongbatShopkeeperWindow",
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
                        MARGIN + (PANEL_W - 50) + 4,
                        MARGIN + TITLE_H + MARGIN)
                elseif idx == IDX_AVAIL then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN,
                        MARGIN + TITLE_H + MARGIN + SEARCH_H + MARGIN)
                elseif idx == IDX_CART then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN + PANEL_W + MARGIN,
                        MARGIN + TITLE_H + MARGIN + SEARCH_H + MARGIN)
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
                -- Reset per-session state
                items           = {}
                filterPatterns  = {}
                availPage       = 1
                cartPage        = 1
                windowView      = nil
                availRowViews   = {}
                cartRowViews    = {}
                availPrevBtn    = nil
                availNextBtn    = nil
                cartPrevBtn     = nil
                cartNextBtn     = nil
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

    -- Override Shopkeeper.Shutdown ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â called when the default XML window is torn
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
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown
}
