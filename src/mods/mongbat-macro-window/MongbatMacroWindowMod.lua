local NAME = "MacroWindow"

-- Layout constants
local ICON_SIZE     = 40
local ROW_HEIGHT    = 46   -- ICON_SIZE + 6px gap
local MAX_VISIBLE   = 8
local WINDOW_WIDTH  = 390
local HEADER_HEIGHT = 30
local FOOTER_HEIGHT = 50
local MARGIN        = 12

-- Context-menu return codes
local RC_EDIT       = 1
local RC_ASSIGN_KEY = 2
local RC_DESTROY    = 3

-- TIDs sourced from the default UI globals
local TID_NO_KEYBINDING = 1078509   -- "(No Key Binding)"
local TID_CREATE        = 1077830   -- "Create"
local TID_EDIT_ITEM     = 1078196   -- "Edit"
local TID_ASSIGN_HOTKEY = 1078019   -- "Assign Hotkey"
local TID_DESTROY       = 1078351   -- "Destroy Macro"

---@param context Context
local function OnInitialize(context)
    local Api        = context.Api
    local Constants  = context.Constants
    local Components = context.Components

    -- Suppress the default MacroWindow
    local macroDefault = Components.Defaults.MacroWindow
    macroDefault:disable()

    -- State captured by closures below
    local scrollOffset         = 0
    local numMacros            = 0
    local iconViews            = {}
    local nameViews            = {}
    local bindingViews         = {}
    local scrollUpButton       = nil
    local scrollDownButton     = nil
    local recordingIndex       = 0
    local recordingKey         = false

    local staticMacroId = Constants.MacroSystem.StaticId()

    -- ------------------------------------------------------------------ --
    -- Row refresh helpers
    -- ------------------------------------------------------------------ --

    --- Updates a single visible row slot (1-based) to display macroIndex.
    --- Hides the row when macroIndex > numMacros.
    local function RefreshRow(slot, macroIndex)
        local iconView    = iconViews[slot]
        local nameView    = nameViews[slot]
        local bindingView = bindingViews[slot]
        if not iconView then return end

        if macroIndex > numMacros then
            iconView:setShowing(false)
            nameView:setShowing(false)
            bindingView:setShowing(false)
            return
        end

        -- Icon
        local iconId = Api.Macro.GetIconId(staticMacroId, macroIndex)
        local texture, tx, ty = Api.Macro.GetIconData(iconId)
        Api.DynamicImage.SetTexture(iconView:getName(), texture, tx, ty)
        iconView:setId(macroIndex)
        iconView:setShowing(true)

        -- Name
        nameView:setText(Api.Macro.GetName(staticMacroId, macroIndex))
        nameView:setId(macroIndex)
        nameView:setShowing(true)

        -- Binding
        local binding = Api.Macro.GetBinding(staticMacroId, macroIndex)
        if binding == L"" then
            bindingView:setText(GetStringFromTid(TID_NO_KEYBINDING))
        else
            bindingView:setText(binding)
        end
        bindingView:setId(macroIndex)
        bindingView:setShowing(true)
    end

    --- Repaints all visible rows from the current scroll offset.
    local function RefreshList()
        numMacros = Api.Macro.GetNumMacros()
        for slot = 1, MAX_VISIBLE do
            RefreshRow(slot, slot + scrollOffset)
        end
        -- Update scroll button states
        if scrollUpButton then
            scrollUpButton:setShowing(scrollOffset > 0)
        end
        if scrollDownButton then
            scrollDownButton:setShowing(scrollOffset + MAX_VISIBLE < numMacros)
        end
    end

    -- ------------------------------------------------------------------ --
    -- Context-menu callback
    -- ------------------------------------------------------------------ --

    local contextMacroIndex = 0

    local function ContextMenuCallback(returnCode, param)
        if returnCode == RC_EDIT then
            Api.Macro.OpenEditWindow(staticMacroId, param)
            Api.Window.SetShowing("ActionsWindow", true)
        elseif returnCode == RC_ASSIGN_KEY then
            recordingIndex = param
            recordingKey   = true
            Api.Event.RecordKey()
        elseif returnCode == RC_DESTROY then
            Api.Macro.DestroyMacroItem(param)
            if scrollOffset > 0 then
                scrollOffset = scrollOffset - 1
            end
            RefreshList()
        end
    end

    --- Shared right-click handler for icon and name views.
    local function OnRButtonUp(self)
        local macroIndex = self:getId()
        if macroIndex == 0 or macroIndex > numMacros then return end
        contextMacroIndex = macroIndex
        Api.ContextMenu.CreateLuaMenuItem(TID_EDIT_ITEM,     0, RC_EDIT,       macroIndex)
        Api.ContextMenu.CreateLuaMenuItem(TID_ASSIGN_HOTKEY, 0, RC_ASSIGN_KEY, macroIndex)
        Api.ContextMenu.CreateLuaMenuItem(TID_DESTROY,       0, RC_DESTROY,    macroIndex)
        Api.ContextMenu.ActivateLuaMenu(ContextMenuCallback)
    end

    --- Shared left-click handler: drag the macro to a hotbar.
    local function OnLButtonDown(self, flags)
        local macroIndex = self:getId()
        if macroIndex == 0 or macroIndex > numMacros then return end

        local macroId = Api.Macro.GetId(staticMacroId, macroIndex)
        local iconId  = Api.Macro.GetIconId(staticMacroId, macroIndex)

        if flags == Constants.ButtonFlags.Control then
            -- Ctrl+click: spawn a new hotbar pre-loaded with this macro.
            Api.Hotbar.SpawnNew()
            local blockBar = Api.Hotbar.GetNextId() - 1
            if blockBar > 0 then
                Api.Hotbar.SetAction(
                    Constants.UserAction.TypeMacroReference(),
                    macroId, iconId, blockBar, 1)
            end
        else
            Api.Drag.SetActionMouseClickData(
                Constants.UserAction.TypeMacroReference(),
                macroId, iconId)
        end
    end

    -- ------------------------------------------------------------------ --
    -- Key-recording handlers (window-level system events)
    -- ------------------------------------------------------------------ --

    local function OnInterfaceKeyRecorded(self)
        if not recordingKey then return end
        recordingKey = false

        local macroIndex = recordingIndex
        recordingIndex   = 0

        if Api.Macro.HasBindingConflict() then
            -- Conflict: ask the user via a standard dialog whether to replace.
            local recordedKey  = Api.Macro.GetRecordedKey()
            local conflictBody = GetStringFromTid(1079170) ..
                L"\n\n" ..
                Api.Hotbar.GetKeyName(
                    Api.Macro.GetConflictHotbarId(),
                    Api.Macro.GetConflictItemIndex(),
                    Api.Macro.GetConflictBindType()) ..
                L"\n\n" .. GetStringFromTid(1094839)

            local yesButton = {
                textTid  = 1049717,
                callback = function()
                    Api.Hotbar.ReplaceKey(
                        Api.Macro.GetConflictHotbarId(),
                        Api.Macro.GetConflictItemIndex(),
                        Api.Macro.GetConflictBindType(),
                        staticMacroId, macroIndex,
                        Constants.BindType.Macro(),
                        recordedKey)
                    RefreshList()
                end
            }
            local noButton = { textTid = 1049718 }
            Api.Dialog.Create({
                windowName = NAME,
                titleTid   = 1079169,
                body       = conflictBody,
                buttons    = { yesButton, noButton }
            })
        else
            Api.Macro.UpdateBinding(staticMacroId, macroIndex, Api.Macro.GetRecordedKey())
            RefreshList()
        end
    end

    local function OnInterfaceKeyCancelRecord(self)
        if not recordingKey then return end
        recordingKey   = false
        recordingIndex = 0
    end

    -- ------------------------------------------------------------------ --
    -- Child factory functions
    -- ------------------------------------------------------------------ --

    --- Creates one icon DynamicImage for the given slot (1-based).
    local function MakeIcon(slot)
        return Components.DynamicImage {
            OnInitialize = function(self)
                self:setDimensions(ICON_SIZE, ICON_SIZE)
                self:setShowing(false)
            end,
            OnLButtonDown = OnLButtonDown,
            OnRButtonUp   = OnRButtonUp,
        }
    end

    --- Creates one name Label for the given slot.
    local function MakeName(slot)
        return Components.Label {
            OnInitialize = function(self)
                local labelW = WINDOW_WIDTH - MARGIN * 2 - ICON_SIZE - MARGIN
                self:setDimensions(labelW, 20)
                self:setShowing(false)
            end,
            OnLButtonDown = OnLButtonDown,
            OnRButtonUp   = OnRButtonUp,
        }
    end

    --- Creates one binding Label for the given slot.
    local function MakeBinding(slot)
        return Components.Label {
            OnInitialize = function(self)
                local labelW = WINDOW_WIDTH - MARGIN * 2 - ICON_SIZE - MARGIN
                self:setDimensions(labelW, 20)
                self:setShowing(false)
            end,
        }
    end

    -- ------------------------------------------------------------------ --
    -- Assemble children
    -- ------------------------------------------------------------------ --

    local children = {}
    local IDX_OFFSET = 0

    -- Slot rows: icons + name labels + binding labels
    for slot = 1, MAX_VISIBLE do
        local iconView    = MakeIcon(slot)
        local nameView    = MakeName(slot)
        local bindingView = MakeBinding(slot)
        iconViews[slot]    = iconView
        nameViews[slot]    = nameView
        bindingViews[slot] = bindingView
        children[IDX_OFFSET + (slot - 1) * 3 + 1] = iconView
        children[IDX_OFFSET + (slot - 1) * 3 + 2] = nameView
        children[IDX_OFFSET + (slot - 1) * 3 + 3] = bindingView
    end

    local IDX_CREATE     = MAX_VISIBLE * 3 + 1
    local IDX_SCROLL_UP  = MAX_VISIBLE * 3 + 2
    local IDX_SCROLL_DN  = MAX_VISIBLE * 3 + 3

    children[IDX_CREATE] = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            self:setDimensions(100, 30)
            self:setText(GetStringFromTid(TID_CREATE))
        end,
        OnLButtonUp = function(self)
            local newIndex = Api.Macro.AddMacroItem()
            Api.Macro.SetName(staticMacroId, newIndex,
                GetStringFromTid(3000394) .. towstring(newIndex))
            Api.Macro.SetIconId(staticMacroId, newIndex, 0)
            Api.Macro.OpenEditWindow(staticMacroId, newIndex)
            Api.Window.SetShowing("ActionsWindow", true)
            RefreshList()
        end,
    }

    scrollUpButton = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            self:setDimensions(30, 30)
            self:setText(L"^")
            self:setShowing(false)
        end,
        OnLButtonUp = function(self)
            if scrollOffset > 0 then
                scrollOffset = scrollOffset - 1
                RefreshList()
            end
        end,
    }
    children[IDX_SCROLL_UP] = scrollUpButton

    scrollDownButton = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            self:setDimensions(30, 30)
            self:setText(L"v")
            self:setShowing(false)
        end,
        OnLButtonUp = function(self)
            if scrollOffset + MAX_VISIBLE < numMacros then
                scrollOffset = scrollOffset + 1
                RefreshList()
            end
        end,
    }
    children[IDX_SCROLL_DN] = scrollDownButton

    -- ------------------------------------------------------------------ --
    -- Layout: position each child relative to the parent window.
    -- ------------------------------------------------------------------ --

    local contentHeight = MAX_VISIBLE * ROW_HEIGHT - (ROW_HEIGHT - ICON_SIZE)
    local windowHeight  = HEADER_HEIGHT + MARGIN + contentHeight + MARGIN + FOOTER_HEIGHT + MARGIN

    local function MacroLayout(window, allChildren, child, index)
        local winName = window:getName()
        local labelX  = MARGIN + ICON_SIZE + MARGIN

        -- Slot rows (icon, name, binding)
        if index <= MAX_VISIBLE * 3 then
            local slot          = math.floor((index - 1) / 3) + 1
            local componentIndex = math.mod(index - 1, 3)  -- 0=icon, 1=name, 2=binding
            local rowY          = HEADER_HEIGHT + MARGIN + (slot - 1) * ROW_HEIGHT

            child:clearAnchors()
            if componentIndex == 0 then
                -- Icon
                child:addAnchor("topleft", winName, "topleft", MARGIN, rowY)
            elseif componentIndex == 1 then
                -- Name label (upper half of the row)
                child:addAnchor("topleft", winName, "topleft", labelX, rowY)
            else
                -- Binding label (lower half)
                child:addAnchor("topleft", winName, "topleft", labelX, rowY + 20)
            end
            return
        end

        -- Footer buttons
        local footerY = HEADER_HEIGHT + MARGIN + contentHeight + MARGIN
        child:clearAnchors()
        if index == IDX_CREATE then
            child:addAnchor("topleft", winName, "topleft", MARGIN, footerY)
        elseif index == IDX_SCROLL_UP then
            child:addAnchor("topright", winName, "topright", -(MARGIN + 30 + 4), footerY)
        elseif index == IDX_SCROLL_DN then
            child:addAnchor("topright", winName, "topright", -MARGIN, footerY)
        end
    end

    -- ------------------------------------------------------------------ --
    -- Window
    -- ------------------------------------------------------------------ --

    local function MacroWindow()
        return Components.Window {
            Name      = NAME,
            Resizable = false,
            OnLayout  = MacroLayout,
            OnInitialize = function(self)
                self:setDimensions(WINDOW_WIDTH, windowHeight)
                self:setChildren(children)
            end,
            OnShown = function(self)
                scrollOffset = 0
                RefreshList()
            end,
            OnMouseWheel = function(self, x, y, delta)
                if delta < 0 then
                    -- scroll down
                    if scrollOffset + MAX_VISIBLE < numMacros then
                        scrollOffset = scrollOffset + 1
                        RefreshList()
                    end
                else
                    -- scroll up
                    if scrollOffset > 0 then
                        scrollOffset = scrollOffset - 1
                        RefreshList()
                    end
                end
            end,
            OnInterfaceKeyRecorded    = OnInterfaceKeyRecorded,
            OnInterfaceKeyCancelRecord = OnInterfaceKeyCancelRecord,
        }
    end

    MacroWindow():create(false)
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.Destroy(NAME)
    context.Components.Defaults.MacroWindow:restore()
end

Mongbat.Mod {
    Name       = "MongbatMacroWindow",
    Path       = "/src/mods/mongbat-macro-window",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown,
}
