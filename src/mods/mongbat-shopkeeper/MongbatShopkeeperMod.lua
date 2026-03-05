-- ========================================================================== --
-- MongbatShopkeeperMod
-- Replaces the default Shopkeeper (buy/sell) window with a clean Mongbat UI.
-- ========================================================================== --

-- Window layout constants
local WIN_W         = 720
local WIN_H         = 520
local PANEL_W       = 310
local PANEL_H       = 340
local ROW_H         = 36
local ICON_SIZE     = 28
local ITEMS_PER_PAGE = 9
local MARGIN        = 10
local SEARCH_H      = 24
local BTN_W         = 90
local BTN_H         = 28
local TITLE_H       = 24
local HDR_H         = 20

-- Saved original Shopkeeper lifecycle functions, used to restore on shutdown
local savedInitialize = nil
local savedShutdown   = nil

---@param context Context
local function OnInitialize(context)
    local Api        = context.Api
    local Data       = context.Data
    local Utils      = context.Utils
    local Constants  = context.Constants
    local Components = context.Components

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
    -- Helper: strip leading quantity from item name wstring
    -- e.g. "5 gold coins" → "gold coins"
    -- -----------------------------------------------------------------------
    local function stripFirstNumber(wStr)
        if not wStr then return L"" end
        local s = WStringToString(wStr)
        if not s or s == "" then return wStr end
        s = string.gsub(s, "^%d+ ", "")
        return StringToWString(s)
    end

    -- -----------------------------------------------------------------------
    -- Helper: check if an item name matches all current filter patterns
    -- Patterns are plain ASCII lowercased strings.
    -- -----------------------------------------------------------------------
    local function matchesFilter(name)
        if table.getn(filterPatterns) == 0 then return true end
        local lname = string.lower(WStringToString(name or L""))
        for i = 1, table.getn(filterPatterns) do
            if not string.find(lname, filterPatterns[i], 1, true) then
                return false
            end
        end
        return true
    end

    -- -----------------------------------------------------------------------
    -- Compute total purchase cost from cart quantities
    -- -----------------------------------------------------------------------
    local function computeTotal()
        local total = 0
        for i = 1, table.getn(items) do
            local item = items[i]
            if item.cartQty > 0 then
                total = total + item.cartQty * item.price
            end
        end
        return total
    end

    -- -----------------------------------------------------------------------
    -- Build filtered view of items (indices into items[])
    -- -----------------------------------------------------------------------
    local function getFilteredAvail()
        local result = {}
        for i = 1, table.getn(items) do
            local item = items[i]
            if item.availQty > 0 and item.price > 0 and matchesFilter(item.name) then
                table.insert(result, i)
            end
        end
        return result
    end

    local function getFilteredCart()
        local result = {}
        for i = 1, table.getn(items) do
            local item = items[i]
            if item.cartQty > 0 then
                table.insert(result, i)
            end
        end
        return result
    end

    -- -----------------------------------------------------------------------
    -- Update a single row view with item data (or clear it)
    -- -----------------------------------------------------------------------
    local function updateRowView(rowView, itemIdx, isCart)
        if not rowView then return end
        local iconView  = rowView._shopIconView
        local nameView  = rowView._shopNameView
        local priceView = rowView._shopPriceView
        local qtyView   = rowView._shopQtyView
        local addBtn    = rowView._shopAddBtn
        local remBtn    = rowView._shopRemBtn

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
                -- For sell mode, register and use ObjectInfo for the item
                local objInfo = Data.ObjectInfo(item.id)
                if objInfo then
                    Api.Equipment.UpdateItemIcon(iconView:getName(), objInfo)
                else
                    -- Request ObjectInfo if not yet registered
                    Api.Window.RegisterData(WindowData.ObjectInfo.Type, item.id)
                end
            else
                local objInfo = Data.ObjectInfo(item.id)
                if objInfo then
                    Api.Equipment.UpdateItemIcon(iconView:getName(), objInfo)
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
            priceView:setText(towstring(item.price) .. L"g")
        end

        if qtyView then
            qtyView:setShowing(true)
            qtyView:setText(towstring(qty))
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
        local total    = table.getn(filtered)
        local maxPage  = math.max(1, math.ceil(total / ITEMS_PER_PAGE))
        if availPage > maxPage then availPage = maxPage end

        local startIdx = (availPage - 1) * ITEMS_PER_PAGE + 1

        for row = 1, ITEMS_PER_PAGE do
            local filtIdx = startIdx + row - 1
            local itemIdx = filtered[filtIdx]
            updateRowView(availRowViews[row], itemIdx, false)
        end

        if availPrevBtn then availPrevBtn:setShowing(availPage > 1) end
        if availNextBtn then availNextBtn:setShowing(availPage < maxPage) end
    end

    -- -----------------------------------------------------------------------
    -- Refresh the cart panel
    -- -----------------------------------------------------------------------
    local function refreshCartPanel()
        local filtered = getFilteredCart()
        local total    = table.getn(filtered)
        local maxPage  = math.max(1, math.ceil(total / ITEMS_PER_PAGE))
        if cartPage > maxPage then cartPage = maxPage end

        local startIdx = (cartPage - 1) * ITEMS_PER_PAGE + 1

        for row = 1, ITEMS_PER_PAGE do
            local filtIdx = startIdx + row - 1
            local itemIdx = filtered[filtIdx]
            updateRowView(cartRowViews[row], itemIdx, true)
        end

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
            totalLabel:setText(towstring(total) .. L"/" .. towstring(gold))
        end
    end

    -- -----------------------------------------------------------------------
    -- Populate buy items from WindowData.ContainerWindow
    -- -----------------------------------------------------------------------
    local function loadBuyItems()
        local data = Data.ContainerWindow(sellContainerId)
        if not data then return end

        -- Unregister old items
        for i = 1, table.getn(items) do
            if items[i].registered then
                Api.Window.UnregisterData(WindowData.ObjectInfo.Type, items[i].id)
                Api.Window.UnregisterData(WindowData.ItemProperties.Type, items[i].id)
                items[i].registered = false
            end
        end

        -- Rebuild items list from container
        local newItems = {}
        for i = 1, data.numItems do
            local slot = data.ContainedItems[i]
            Api.Window.RegisterData(WindowData.ObjectInfo.Type, slot.objectId)
            Api.Window.RegisterData(WindowData.ItemProperties.Type, slot.objectId)

            local objInfo  = Data.ObjectInfo(slot.objectId)
            local itemName = L""
            local price    = 0
            local qty      = 0
            local objType  = 0

            if objInfo then
                price   = objInfo.shopValue or 0
                qty     = objInfo.shopQuantity or 0
                objType = objInfo.objectType or 0
            end

            local props = Data.ItemProperties(slot.objectId)
            if props and props.PropertiesList and props.PropertiesList[1] then
                itemName = stripFirstNumber(props.PropertiesList[1])
            end

            -- Find existing entry to preserve cartQty
            local existingCartQty = 0
            for j = 1, table.getn(items) do
                if items[j].id == slot.objectId then
                    existingCartQty = items[j].cartQty
                    break
                end
            end

            -- Clamp cartQty if vendor has less now
            if existingCartQty > qty then existingCartQty = qty end

            table.insert(newItems, {
                id         = slot.objectId,
                name       = itemName,
                price      = price,
                totalQty   = qty,
                availQty   = qty - existingCartQty,
                cartQty    = existingCartQty,
                objType    = objType,
                registered = true
            })
        end
        items = newItems
    end

    -- -----------------------------------------------------------------------
    -- Populate sell items from WindowData.ShopData.Sell
    -- -----------------------------------------------------------------------
    local function loadSellItems()
        items = {}
        local shopData = Data.ShopData()
        local count    = shopData:getSellCount()
        for i = 1, count do
            local entry = shopData:getSellItem(i)
            if entry then
                -- Register for item icon/tooltip data
                Api.Window.RegisterData(WindowData.ObjectInfo.Type, entry.id)
                Api.Window.RegisterData(WindowData.ItemProperties.Type, entry.id)
                table.insert(items, {
                    id         = entry.id,
                    name       = stripFirstNumber(entry.name),
                    price      = entry.price,
                    totalQty   = entry.quantity,
                    availQty   = entry.quantity,
                    cartQty    = 0,
                    objType    = entry.objType,
                    registered = true
                })
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- Move one unit from available → cart
    -- -----------------------------------------------------------------------
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
    -- Move one unit from cart → available
    -- -----------------------------------------------------------------------
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
        for i = 1, table.getn(items) do
            local item = items[i]
            item.availQty = item.totalQty
            item.cartQty  = 0
        end
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
        for i = 1, table.getn(items) do
            local item = items[i]
            if item.cartQty > 0 then
                table.insert(offerIds,  item.id)
                table.insert(offerQtys, item.cartQty)
            end
        end
        if table.getn(offerIds) == 0 then
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
    -- isCartPanel: boolean — if true, the + button adds-all, - removes one
    -- -----------------------------------------------------------------------
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
                self:setText(isCartPanel and L"All" or L"+")
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
                self:setText(L"-")
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
            OnLayout = function(win, children, child, idx)
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

        -- Stash child refs on the row for later refresh
        rowView._shopIconView  = iconView
        rowView._shopNameView  = nameView
        rowView._shopPriceView = priceView
        rowView._shopQtyView   = qtyView
        rowView._shopAddBtn    = addBtn
        rowView._shopRemBtn    = remBtn

        return rowView
    end

    -- -----------------------------------------------------------------------
    -- Build a panel (available or cart)
    -- isCartPanel controls button semantics
    -- Returns {panelWindow, rowViews, prevBtn, nextBtn}
    -- -----------------------------------------------------------------------
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
            local rowView = ItemRow(isCartPanel)
            rowViews[row] = rowView
            table.insert(children, rowView)
        end

        -- Pagination buttons
        prevBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(BTN_W / 2, 22)
                self:setText(L"< Prev")
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
                self:setText(L"Next >")
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

        table.insert(children, prevBtn)
        table.insert(children, nextBtn)

        local panelWindow = Components.Window {
            OnInitialize = function(self)
                self:setDimensions(PANEL_W, PANEL_H)
            end,
            OnLayout = function(win, ch, child, idx)
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
            titleText = L"Sellable Items"
        else
            -- Try to get the merchant's name
            local mobileName = Data.MobileName(mId)
            local mobData    = mobileName and mobileName:getData()
            if mobData and mobData.MobName and mobData.MobName ~= "" then
                titleText = StringToWString(mobData.MobName)
            else
                titleText = L"NPC Store"
            end
        end

        -- Available panel
        local availHdr  = isSelling and L"Sellable" or L"Available"
        local cartHdr   = isSelling and L"Sell List" or L"Cart"

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
            OnKeyEnter = function(self)
                local text = self:getText()
                if text and text ~= L"" then
                    local textStr = string.lower(WStringToString(text))
                    local found = false
                    for i = 1, table.getn(filterPatterns) do
                        if filterPatterns[i] == textStr then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(filterPatterns, textStr)
                    end
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
                self:setText(L"Clear")
            end,
            OnLButtonUp = function(self)
                filterPatterns = {}
                if searchBox then
                    searchBox:setText(L"")
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
                self:setText(isSelling and L"Sell" or L"Buy")
            end,
            OnLButtonUp = function(self)
                acceptOffer()
            end
        }

        -- Clear cart / Cancel button
        local cancelBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(BTN_W, BTN_H)
                self:setText(L"Clear")
            end,
            OnLButtonUp = function(self)
                clearCart()
            end
        }

        -- Close button
        local closeBtn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(BTN_W, BTN_H)
                self:setText(L"Close")
            end,
            OnLButtonUp = function(self)
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

        windowView = Components.Window {
            Name = "MongbatShopkeeperWindow",
            Resizable = false,
            OnInitialize = function(self)
                self:setDimensions(WIN_W, WIN_H)
                self:setChildren(children)
                self:setId(merchantId)
            end,
            OnUpdatePlayerStatus = function(self, ps)
                if totalLabel then
                    local total = computeTotal()
                    local gold  = ps:getGold()
                    totalLabel:setText(towstring(total) .. L"/" .. towstring(gold))
                end
            end,
            OnLayout = function(win, ch, child, idx)
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
                    child:addAnchor("topleft", searchBox:getName(), "topright", 4, 0)
                elseif idx == IDX_AVAIL then
                    child:clearAnchors()
                    child:addAnchor("topleft", winName, "topleft",
                        MARGIN,
                        MARGIN + TITLE_H + MARGIN + SEARCH_H + MARGIN)
                elseif idx == IDX_CART then
                    child:clearAnchors()
                    child:addAnchor("topleft", availPanel:getName(), "topright", MARGIN, 0)
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
            OnShutdown = function(self)
                -- Unregister buy-mode data
                if not isSelling then
                    Api.Window.UnregisterData(WindowData.ObjectInfo.Type, merchantId)
                    Api.Window.UnregisterData(WindowData.ContainerWindow.Type, sellContainerId)
                    for i = 1, table.getn(items) do
                        if items[i].registered then
                            Api.Window.UnregisterData(WindowData.ObjectInfo.Type, items[i].id)
                            Api.Window.UnregisterData(WindowData.ItemProperties.Type, items[i].id)
                            items[i].registered = false
                        end
                    end
                end
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
            end
        }

        windowView:create(true)

        -- Register for ContainerWindow updates (buy mode only)
        if not isSelling then
            Api.Window.RegisterEventHandler(
                "MongbatShopkeeperWindow",
                WindowData.ContainerWindow.Event,
                "MongbatShopkeeper.OnContainerUpdate"
            )
            Api.Window.RegisterEventHandler(
                "MongbatShopkeeperWindow",
                WindowData.ObjectInfo.Event,
                "MongbatShopkeeper.OnObjectUpdate"
            )
            Api.Window.RegisterEventHandler(
                "MongbatShopkeeperWindow",
                WindowData.ItemProperties.Event,
                "MongbatShopkeeper.OnItemPropertiesUpdate"
            )
        end

        -- Initial refresh
        refreshAll()
    end

    -- -----------------------------------------------------------------------
    -- Container / object event callbacks (buy mode)
    -- These are set on the raw global so the engine can call them.
    -- -----------------------------------------------------------------------
    MongbatShopkeeper = MongbatShopkeeper or {}

    function MongbatShopkeeper.OnContainerUpdate()
        if Api.Window.GetUpdateInstanceId() == sellContainerId then
            loadBuyItems()
            refreshAll()
        end
    end

    function MongbatShopkeeper.OnObjectUpdate()
        -- Refresh item data for the updated object
        local objId   = Api.Window.GetUpdateInstanceId()
        local objInfo = Data.ObjectInfo(objId)
        if objInfo then
            for i = 1, table.getn(items) do
                if items[i].id == objId then
                    local oldCart  = items[i].cartQty
                    local newTotal = objInfo.shopQuantity or 0
                    if oldCart > newTotal then oldCart = newTotal end
                    items[i].totalQty = newTotal
                    items[i].availQty = newTotal - oldCart
                    items[i].cartQty  = oldCart
                    items[i].price    = objInfo.shopValue or 0
                    items[i].objType  = objInfo.objectType or 0
                    break
                end
            end
        end
        refreshAll()
    end

    function MongbatShopkeeper.OnItemPropertiesUpdate()
        local objId = Api.Window.GetUpdateInstanceId()
        local props = Data.ItemProperties(objId)
        if props and props.PropertiesList and props.PropertiesList[1] then
            local name = stripFirstNumber(props.PropertiesList[1])
            for i = 1, table.getn(items) do
                if items[i].id == objId then
                    items[i].name = name
                    break
                end
            end
        end
        refreshAll()
    end

    -- -----------------------------------------------------------------------
    -- Override Shopkeeper.Initialize — intercepts vendor window creation
    -- Save original functions so we can restore them on mod shutdown.
    -- -----------------------------------------------------------------------
    savedInitialize = shopkeeperDefault:getDefault().Initialize
    savedShutdown   = shopkeeperDefault:getDefault().Shutdown

    shopkeeperDefault:getDefault().Initialize = function()
        local defaultWin = Api.Window.GetActiveWindowName()
        local mId        = Api.Window.GetDynamicWindowId()

        -- Destroy the default Shopkeeper XML window
        if Api.Window.DoesExist(defaultWin) then
            Api.Window.Destroy(defaultWin)
        end

        -- Destroy any leftover Mongbat shopkeeper window
        if Api.Window.DoesExist("MongbatShopkeeperWindow") then
            Api.Window.Destroy("MongbatShopkeeperWindow")
        end

        local isSell = Data.ShopData():isSelling()

        -- For buy mode: register ObjectInfo to get sellContainerId
        if not isSell then
            Api.Window.RegisterData(WindowData.ObjectInfo.Type, mId)
            local objInfo = Data.ObjectInfo(mId)
            if objInfo then
                sellContainerId = objInfo.sellContainerId or 0
            end
            Api.Window.RegisterData(WindowData.ContainerWindow.Type, sellContainerId)
            -- Register for MobileName to show vendor name
            Api.Window.RegisterData(WindowData.MobileName.Type, mId)
        end

        -- Register PlayerStatus for gold display
        Api.Window.RegisterData(WindowData.PlayerStatus.Type, 0)

        createShopWindow(mId, isSell)
    end

    -- -----------------------------------------------------------------------
    -- Override Shopkeeper.Shutdown — intercepts vendor window closure
    -- -----------------------------------------------------------------------
    shopkeeperDefault:getDefault().Shutdown = function()
        local defaultWin = Api.Window.GetActiveWindowName()
        if Api.Window.DoesExist(defaultWin) then
            Api.Window.Destroy(defaultWin)
        end

        -- Unregister PlayerStatus
        Api.Window.UnregisterData(WindowData.PlayerStatus.Type, 0)

        -- Broadcast cancel if window still exists (user closed via X)
        if windowView ~= nil then
            Api.Event.Broadcast(Constants.Broadcasts.ShopCancelOffer())
            Api.Window.Destroy("MongbatShopkeeperWindow")
        end
    end
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.Destroy("MongbatShopkeeperWindow")

    -- Restore original Initialize/Shutdown on the Shopkeeper global
    local shopkeeperDefault = context.Components.Defaults.Shopkeeper
    if savedInitialize ~= nil then
        shopkeeperDefault:getDefault().Initialize = savedInitialize
        savedInitialize = nil
    end
    if savedShutdown ~= nil then
        shopkeeperDefault:getDefault().Shutdown = savedShutdown
        savedShutdown = nil
    end

    -- Restore the default Shopkeeper global proxy to original
    shopkeeperDefault:restoreGlobal()
end

Mongbat.Mod {
    Name = "MongbatShopkeeper",
    Path = "/src/mods/mongbat-shopkeeper",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown
}
