---@class Api
local Api = {}

---@class Constants
local Constants = {}

---@class Views
local Components = {}

---@class Data
local Data = {}

---@class Utils
local Utils = {}

-- ========================================================================== --
-- Global Overrides
-- ========================================================================== --

--[[
    In order to reduce errors as we override parts of the default UI, we override
    certain global functions to add safety checks.
]] --

-- Save the original function
local old_WindowGetShowing = WindowGetShowing

-- Override the global
function WindowGetShowing(windowName)
    if not Api.Window.DoesExist(windowName) then
        return false
    end
    return old_WindowGetShowing(windowName)
end

-- Save the original function
local old_WindowSetShowing = WindowSetShowing

-- Override the global
function WindowSetShowing(windowName, show)
    if Api.Window.DoesExist(windowName) then
        old_WindowSetShowing(windowName, show)
    end
end

-- Save the original function
local old_LabelSetText = LabelSetText

-- Override the global
function LabelSetText(labelName, text)
    if Api.Window.DoesExist(labelName) then
        old_LabelSetText(labelName, text)
    end
end

-- Save the original function
local old_CircleImageSetTextureScale = CircleImageSetTextureScale

-- Override the global
function CircleImageSetTextureScale(imageName, scale)
    if Api.Window.DoesExist(imageName) then
        old_CircleImageSetTextureScale(imageName, scale)
    end
end

-- Save the original function
local old_CircleImageSetTexture = CircleImageSetTexture

-- Override the global
function CircleImageSetTexture(imageName, texture, x, y)
    if Api.Window.DoesExist(imageName) then
        old_CircleImageSetTexture(imageName, texture, x, y)
    end
end

local old_RegisterWindowData = RegisterWindowData

function RegisterWindowData(dataType, id)
    old_RegisterWindowData(dataType, id or 0)
end

local old_StatusBarSetMaximumValue = StatusBarSetMaximumValue

function StatusBarSetMaximumValue(barName, maxValue)
    if maxValue ~= nil and Api.Window.DoesExist(barName) then
        old_StatusBarSetMaximumValue(barName, maxValue)
    end
end

local old_StatusBarSetCurrentValue = StatusBarSetCurrentValue

function StatusBarSetCurrentValue(barName, currentValue)
    if currentValue ~= nil and Api.Window.DoesExist(barName) then
        old_StatusBarSetCurrentValue(barName, currentValue)
    end
end

local old_InterfaceCoreUpdate = InterfaceCore.Update

function InterfaceCore.Update(elapsedTime)
    pcall(old_InterfaceCoreUpdate, elapsedTime)
end

local old_HotbarSystemUpdate = HotbarSystem.Update

function HotbarSystem.Update(elapsedTime)
    pcall(old_HotbarSystemUpdate, elapsedTime)
end

-- ========================================================================== --
-- Api - Ability
-- ========================================================================== --


Api.Ability = {}

---
--- Returns the maximum number of racial abilities.
---@return number The maximum number of racial abilities.
function Api.Ability.GetMaxRacialAbilities()
    return GetMaxRacialAbilities()
end

---
--- Gets the racial ability ID for a given index.
---@param index number The index of the racial ability.
---@return number The racial ability ID.
function Api.Ability.GetRacialAbilityId(index)
    return GetRacialAbilityId(index) + 3000
end

---
--- Gets the ability data for a given ID.
---@param id number The ID of the ability.
---@return any The ability data.
function Api.Ability.GetAbilityData(id)
    return GetAbilityData(id)
end

---
--- Gets the weapon ability ID for a given index.
---@param index number The index of the weapon ability.
---@return number The weapon ability ID.
function Api.Ability.GetWeaponAbilityId(index)
    return GetWeaponAbilityId(index) + 1000
end

-- ========================================================================== --
-- Api - Animated Image
-- ========================================================================== --

Api.AnimatedImage = {}

---
--- Sets the texture for an animated image.
---@param imageName string The name of the animated image.
---@param texture string The texture to set.
function Api.AnimatedImage.SetTexture(imageName, texture)
    AnimatedImageSetTexture(imageName, texture)
end

---
--- Starts the animation for an animated image.
---@param imageName string The name of the animated image.
---@param startFrame number The frame to start the animation from.
---@param loop boolean Whether the animation should loop.
---@param hideWhenDone boolean Whether the image should be hidden when the animation is done.
---@param delay number The delay before the animation starts.
function Api.AnimatedImage.StartAnimation(imageName, startFrame, loop, hideWhenDone, delay)
    AnimatedImageStartAnimation(imageName, startFrame, loop, hideWhenDone, delay)
end

---
--- Stops the animation for an animated image.
---@param imageName string The name of the animated image.
function Api.AnimatedImage.StopAnimation(imageName)
    AnimatedImageStopAnimation(imageName)
end

---
--- Sets the play speed of an animated image.
---@param imageName string The name of the animated image.
---@param fps number The frames per second.
function Api.AnimatedImage.SetPlaySpeed(imageName, fps)
    AnimatedImageSetPlaySpeed(imageName, fps)
end

-- ========================================================================== --
-- Api - Action Button
-- ========================================================================== --

Api.ActionButton = {}

---
--- Sets the game action on an ActionButton window.
---@param windowName string The name of the action button.
---@param actionType number The action type.
---@param actionId number The action ID.
function Api.ActionButton.SetAction(windowName, actionType, actionId)
    WindowSetGameActionData(windowName, actionType, actionId, L"")
end

---
--- Gets the action data from an ActionButton window.
---@param windowName string The name of the action button.
---@return any The game action button data.
function Api.ActionButton.GetAction(windowName)
    return WindowGetGameActionButton(windowName)
end

---
--- Sets the game action trigger for an ActionButton window.
---@param windowName string The name of the action button.
---@param action any The action trigger value.
function Api.ActionButton.SetGameActionTrigger(windowName, action)
    WindowSetGameActionTrigger(windowName, action)
end

-- ========================================================================== --
-- Api - Button
-- ========================================================================== --

Api.Button = {}

---
--- Gets the text dimensions of a button.
---@param id string The ID of the button.
---@return number, number The width and height of the button text.
function Api.Button.GetTextDimensions(id)
    return ButtonGetTextDimensions(id)
end

---
--- Sets the text of a button.
---@param id string The ID of the button.
---@param text string The text to set.
function Api.Button.SetText(id, text)
    ButtonSetText(id, text)
end

---
--- Gets the text of a button.
---@param id string The ID of the button.
---@return string The text of the button.
function Api.Button.GetText(id)
    return ButtonGetText(id)
end

---
--- Sets the disabled flag of a button.
---@param id string The ID of the button.
---@param isDisabled boolean Whether the button is disabled.
function Api.Button.SetDisabled(id, isDisabled)
    ButtonSetDisabledFlag(id, isDisabled)
end

---
--- Gets the disabled flag of a button.
---@param id string The ID of the button.
---@return boolean Whether the button is disabled.
function Api.Button.IsDisabled(id)
    return ButtonGetDisabledFlag(id)
end

---
--- Sets the enabled flag of a button.
---@param id string The ID of the button.
---@param isEnabled boolean Whether the button is enabled.
function Api.Button.SetEnabled(id, isEnabled)
    ButtonSetCheckButtonFlag(id, isEnabled)
end

---
--- Sets the pressed flag of a button.
---@param id string The ID of the button.
---@param isChecked boolean Whether the button is pressed.
function Api.Button.SetChecked(id, isChecked)
    ButtonSetPressedFlag(id, isChecked)
end

---
--- Gets the pressed flag of a button.
---@param id string The ID of the button.
---@return boolean Whether the button is pressed.
function Api.Button.IsChecked(id)
    return ButtonGetPressedFlag(id)
end

---
--- Sets the texture of a button.
---@param id string The ID of the button.
---@param state number The state of the button.
---@param texture string The texture to set.
---@param x number The x-coordinate of the texture.
---@param y number The y-coordinate of the texture.
function Api.Button.SetTexture(id, state, texture, x, y)
    ButtonSetTexture(id, state, texture, x, y)
end

---
--- Sets the highlight flag of a button.
---@param id string The ID of the button.
---@param doHighlight boolean Whether to highlight the button.
function Api.Button.SetHighlight(id, doHighlight)
    ButtonSetHighlightFlag(id, doHighlight)
end

---
--- Sets the stay down flag of a button.
---@param id string The ID of the button.
---@param stayDown boolean Whether the button should stay down.
function Api.Button.SetStayDown(id, stayDown)
    ButtonSetStayDownFlag(id, stayDown)
end

---
--- Gets the stay down flag of a button.
---@param id string The ID of the button.
---@return boolean Whether the button stays down.
function Api.Button.IsStayDown(id)
    return ButtonGetStayDownFlag(id)
end

---
--- Sets the text color of a button.
---@param id string The ID of the button.
---@param r number The red component of the color.
---@param g number The green component of the color.
---@param b number The blue component of the color.
---@param a number The alpha component of the color.
function Api.Button.SetTextColor(id, r, g, b, a)
    ButtonSetTextColor(id, r, g, b, a)
end

-- ========================================================================== --
-- Api - Chat
-- ========================================================================== --

Api.Chat = {}

---
--- Sends a chat message.
---@param channel string The channel to send the message to.
---@param text string The message to send.
function Api.Chat.SendChat(channel, text)
    SendChat(channel, text)
end

---
--- Prints a message to the chat window.
---@param wString string The message to print.
---@param filter string The filter to use.
function Api.Chat.PrintToChatWindow(wString, filter)
    PrintWStringToChatWindow(wString, filter)
end

-- ========================================================================== --
-- Api - Circle Image
-- ========================================================================== --

Api.CircleImage = {}

---
--- Sets the texture for a circle image.
---@param id string The ID of the circle image.
---@param texture string The texture to set.
---@param xCord number The x-coordinate of the texture.
---@param yCord number The y-coordinate of the texture.
function Api.CircleImage.SetTexture(id, texture, xCord, yCord)
    CircleImageSetTexture(id, texture, xCord, yCord)
end

---
--- Sets the texture scale for a circle image.
---@param id string The ID of the circle image.
---@param scale number The scale to set.
function Api.CircleImage.SetTextureScale(id, scale)
    CircleImageSetTextureScale(id, scale)
end

---
--- Sets the rotation for a circle image.
---@param id string The ID of the circle image.
---@param rotation number The rotation to set.
function Api.CircleImage.SetRotation(id, rotation)
    CircleImageSetRotation(id, rotation)
end

function Api.CircleImage.SetFillParams(name, startAngle, fillAngle)
    CircleImageSetFillParams(name, startAngle, fillAngle)
end

function Api.CircleImage.SetTextureSlice(name, sliceName)
    CircleImageSetTextureSlice(name, sliceName)
end

-- ========================================================================== --
-- Api - ComboBox
-- ========================================================================== --


Api.ComboBox = {}

---
--- Adds an item to a combo box.
---@param id string The ID of the combo box.
---@param item string The item to add.
function Api.ComboBox.AddItem(id, item)
    ComboBoxAddMenuItem(id, item)
end

---
--- Clears the items from a combo box.
---@param id string The ID of the combo box.
function Api.ComboBox.ClearItems(id)
    ComboBoxClearMenuItems(id)
end

---
--- Sets the selected item in a combo box.
---@param id string The ID of the combo box.
---@param item string The item to select.
function Api.ComboBox.SetSelectedItem(id, item)
    ComboBoxSetSelectedMenuItem(id, item)
end

---
--- Gets the selected item from a combo box.
---@param id string The ID of the combo box.
---@return string The selected item.
function Api.ComboBox.GetSelectedItem(id)
    return ComboBoxGetSelectedMenuItem(id)
end

-- ========================================================================== --
-- Api - Context Menu
-- ========================================================================== --


Api.ContextMenu = {}

---
--- Requests a context menu.
---@param id number The ID of the context menu.
function Api.ContextMenu.RequestMenu(id)
    RequestContextMenu(id)
end

-- ========================================================================== --
-- Api - CSV
-- ========================================================================== --


Api.CSV = {}

---
--- Loads a CSV file.
---@param path string The path to the CSV file.
---@param name string The name to give the loaded data.
function Api.CSV.Load(path, name)
    UOBuildTableFromCSV(path, name)
end

---
--- Unloads a CSV file.
---@param name string The name of the CSV data to unload.
function Api.CSV.Unload(name)
    UOUnloadCSVTable(name)
end

-- ========================================================================== --
-- Api - Drag
-- ========================================================================== --

Api.Drag = {}

---
--- Drags an object to another object.
---@param id number The ID of the object to drag to.
function Api.Drag.DragToObject(id)
    DragSlotDropObjectToObject(id)
end

---
--- Sets the mouse click data for a user action.
---@param userAction string The user action.
---@param actionId number The action ID.
---@param iconId number The icon ID.
function Api.Drag.SetActionMouseClickData(userAction, actionId, iconId)
    DragSlotSetActionMouseClickData(userAction, actionId, iconId)
end

---
--- Sets the mouse click data for an object.
---@param objectId number The object ID.
---@param dragSource string The drag source.
function Api.Drag.SetObjectMouseClickData(objectId, dragSource)
    DragSlotSetObjectMouseClickData(objectId, dragSource)
end

---
--- Drops an object on the paperdoll equipment.
---@param objectId number The object ID.
function Api.Drag.DropOnPaperdollEquipment(objectId)
    DragSlotDropObjectToPaperdollEquipment(objectId)
end

---
--- Drops an object on the paperdoll.
---@param paperdollId number The paperdoll ID.
function Api.Drag.DropOnPaperdoll(paperdollId)
    DragSlotDropObjectToPaperdoll(paperdollId)
end

---
--- Drops an object on an object at a given index.
---@param objectId number The object ID.
---@param gridIndex number The grid index.
function Api.Drag.DropOnObjectAtIndex(objectId, gridIndex)
    DragSlotDropObjectToObjectAtIndex(objectId, gridIndex)
end

---
--- Drops an object on a container.
---@param containerId number The container ID.
---@param gridIndex number The grid index.
function Api.Drag.DropOnContainer(containerId, gridIndex)
    DragSlotDropObjectToContainer(containerId, gridIndex)
end

---
--- Automatically picks up an object.
---@param objectId number The object ID.
function Api.Drag.AutoPickupObject(objectId)
    DragSlotAutoPickupObject(objectId)
end

-- ========================================================================== --
-- Api - Dynamic Image
-- ========================================================================== --

Api.DynamicImage = {}

---
--- Sets the texture for a dynamic image.
---@param dynamicImageName string The name of the dynamic image.
---@param texture string The texture to set.
---@param x number The x-coordinate of the texture.
---@param y number The y-coordinate of the texture.
function Api.DynamicImage.SetTexture(dynamicImageName, texture, x, y)
    DynamicImageSetTexture(dynamicImageName, texture or "", x or 0, y or 0)
end

---
--- Sets the texture scale for a dynamic image.
---@param dynamicImageName string The name of the dynamic image.
---@param textureScale number The scale to set.
function Api.DynamicImage.SetTextureScale(dynamicImageName, textureScale)
    DynamicImageSetTextureScale(dynamicImageName, textureScale)
end

---
--- Sets the texture dimensions for a dynamic image.
---@param dynamicImageName string The name of the dynamic image.
---@param x number The width of the texture.
---@param y number The height of the texture.
function Api.DynamicImage.SetTextureDimensions(dynamicImageName, x, y)
    DynamicImageSetTextureDimensions(dynamicImageName, x, y)
end

---
--- Sets the texture orientation for a dynamic image.
---@param dynamicImageName string The name of the dynamic image.
---@param mirrored boolean Whether the texture is mirrored.
function Api.DynamicImage.SetTextureOrientation(dynamicImageName, mirrored)
    DynamicImageSetTextureOrientation(dynamicImageName, mirrored)
end

---
--- Sets the texture slice for a dynamic image.
---@param dynamicImageName string The name of the dynamic image.
---@param sliceName string The name of the slice.
function Api.DynamicImage.SetTextureSlice(dynamicImageName, sliceName)
    DynamicImageSetTextureSlice(dynamicImageName, sliceName)
end

---
--- Sets the rotation for a dynamic image.
---@param dynamicImageName string The name of the dynamic image.
---@param rotation number The rotation to set.
function Api.DynamicImage.SetRotation(dynamicImageName, rotation)
    DynamicImageSetRotation(dynamicImageName, rotation)
end

---
--- Checks if a dynamic image has a texture.
---@param dynamicImageName string The name of the dynamic image.
---@return boolean Whether the dynamic image has a texture.
function Api.DynamicImage.HasTexture(dynamicImageName)
    return DynamicImageHasTexture(dynamicImageName)
end

---
--- Sets a custom shader for a dynamic image.
---@param dynamicImageName string The name of the dynamic image.
---@param shader string The shader to set.
---@param hue number The hue to use.
function Api.DynamicImage.SetCustomShader(dynamicImageName, shader, hue)
    DynamicImageSetCustomShader(dynamicImageName, shader, hue)
end

-- ========================================================================== --
-- Api - Edit Text Box
-- ========================================================================== --


Api.EditTextBox = {}

---
--- Sets the text of an edit box.
---@param editBoxName string The name of the edit box.
---@param text string The text to set.
function Api.EditTextBox.SetText(editBoxName, text)
    TextEditBoxSetText(editBoxName, text or L "")
end

---
--- Gets the text of an edit box.
---@param editBoxName string The name of the edit box.
---@return string The text of the edit box.
function Api.EditTextBox.GetText(editBoxName)
    return TextEditBoxGetText(editBoxName)
end

---
--- Gets the text lines of an edit box.
---@param editBoxName string The name of the edit box.
---@return table The text lines of the edit box.
function Api.EditTextBox.GetTextLines(editBoxName)
    return TextEditBoxGetTextLines(editBoxName)
end

---
--- Inserts text into an edit box.
---@param editBoxName string The name of the edit box.
---@param text string The text to insert.
function Api.EditTextBox.InsertText(editBoxName, text)
    TextEditBoxInsertText(editBoxName, text)
end

---
--- Sets the text color of an edit box.
---@param editBoxName string The name of the edit box.
---@param r number The red component of the color.
---@param g number The green component of the color.
---@param b number The blue component of the color.
function Api.EditTextBox.SetTextColor(editBoxName, r, g, b)
    TextEditBoxSetTextColor(editBoxName, r, g, b)
end

---
--- Gets the text color of an edit box.
---@param editBoxName string The name of the edit box.
---@return number, number, number The red, green, and blue components of the color.
function Api.EditTextBox.GetTextColor(editBoxName)
    return TextEditBoxGetTextColor(editBoxName)
end

---
--- Selects all text in an edit box.
---@param editBoxName string The name of the edit box.
function Api.EditTextBox.SelectAll(editBoxName)
    TextEditBoxSelectAll(editBoxName)
end

---
--- Sets the font of an edit box.
---@param editBoxName string The name of the edit box.
---@param fontName string The name of the font.
---@param lineSpacing number The line spacing.
function Api.EditTextBox.SetFont(editBoxName, fontName, lineSpacing)
    TextEditBoxSetFont(editBoxName, fontName, lineSpacing)
end

---
--- Gets the font of an edit box.
---@param editBoxName string The name of the edit box.
---@return string, number The name of the font and the line spacing.
function Api.EditTextBox.GetFont(editBoxName)
    return TextEditBoxGetFont(editBoxName)
end

---
--- Gets the history of an edit box.
---@param editBoxName string The name of the edit box.
---@return table The history of the edit box.
function Api.EditTextBox.GetHistory(editBoxName)
    return TextEditBoxGetHistory(editBoxName)
end

---
--- Sets the history of an edit box.
---@param editBoxName string The name of the edit box.
---@param history table The history to set.
function Api.EditTextBox.SetHistory(editBoxName, history)
    TextEditBoxSetHistory(editBoxName, history)
end

---
--- Sets whether an edit box handles key down events.
---@param editBoxName string The name of the edit box.
---@param handle boolean Whether to handle key down events.
function Api.EditTextBox.HandleKeyDown(editBoxName, handle)
    TextEditBoxSetHandleKeyDown(editBoxName, handle)
end

-- ========================================================================== --
-- Api - Event
-- ========================================================================== --

Api.Event = {}

---
--- Broadcasts an event.
---@param event string The event to broadcast.
function Api.Event.Broadcast(event)
    BroadcastEvent(event)
end

function Api.Event.OpenHelpMenu()
    Api.Event.Broadcast(SystemData.Events.REQUEST_OPEN_HELP_MENU)
end

function Api.Event.OpenStore()
    Api.Event.Broadcast(SystemData.Events.UO_STORE_REQUEST)
end

function Api.Event.Logout()
    Api.Event.Broadcast(SystemData.Events.LOG_OUT)
end

function Api.Event.ExitGame()
    Api.Event.Broadcast(SystemData.Events.EXIT_GAME)
end

function Api.Event.RegisterEventHandler(event, callback)
    RegisterEventHandler(event, callback)
end

function Api.Event.UnregisterEventHandler(event, callback)
    UnregisterEventHandler(event, callback)
end

-- ========================================================================== --
-- Api - Gump
-- ========================================================================== --


Api.Gump = {}

---
--- Handles a left click on a gump.
---@param gumpId number The ID of the gump.
---@param windowName string The name of the window.
function Api.Gump.OnLeftClick(gumpId, windowName)
    GenericGumpOnClicked(gumpId, windowName)
end

---
--- Handles a double click on a gump.
---@param gumpId number The ID of the gump.
---@param windowName string The name of the window.
function Api.Gump.OnDoubleClick(gumpId, windowName)
    GenericGumpOnDoubleClicked(gumpId, windowName)
end

---
--- Handles a right click on a gump.
---@param gumpId number The ID of the gump.
function Api.Gump.OnRightClick(gumpId)
    GenericGumpOnRClicked(gumpId)
end

---
--- Gets the tooltip text for a gump.
---@param gumpId number The ID of the gump.
---@param windowName string The name of the window.
---@return string The tooltip text.
function Api.Gump.GetTooltipText(gumpId, windowName)
    return GenericGumpGetToolTipText(gumpId, windowName)
end

---
--- Opens a web browser.
---@param link string The link to open.
function Api.Gump.OpenWebBrowser(link)
    OpenWebBrowser(tostring(link))
end

---
--- Handles closing a container.
---@param id number The ID of the container.
function Api.Gump.OnCloseContainer(id)
    GumpManagerOnCloseContainer(id)
end

---
--- Gets the item properties object ID for a gump.
---@param gumpId number The ID of the gump.
---@param windowName string The name of the window.
---@return number The item properties object ID.
function Api.Gump.GetItemPropertiesObjectId(gumpId, windowName)
    return GenericGumpGetItemPropertiesId(gumpId, windowName)
end

-- ========================================================================== --
-- Api - Icon
-- ========================================================================== --

Api.Icon = {}

---
--- Gets the icon data for a texture ID.
---@param textureId number The texture ID.
---@return any The icon data.
function Api.Icon.GetIconData(textureId)
    return GetIconData(textureId)
end

---
--- Gets the texture size for a texture ID.
---@param textureId number The texture ID.
---@return number, number The width and height of the texture.
function Api.Icon.GetTextureSize(textureId)
    return UOGetTextureSize(textureId)
end

---
--- Requests tile art.
---@param type number The type of tile art.
---@param width number The width of the tile art.
---@param height number The height of the tile art.
---@return any The tile art.
function Api.Icon.RequestTileArt(type, width, height)
    return RequestTileArt(type, width, height)
end

-- ========================================================================== --
-- Api - Label
-- ========================================================================== --


Api.Label = {}

---
--- Sets the text of a label.
---@param name string The name of the label.
---@param text string|number The text to set.
function Api.Label.SetText(name, text)
    if text == nil then
        return
    elseif type(text) == "number" then
        text = Api.String.GetStringFromTid(text)
    elseif type(text) == "string" then
        text = Api.String.StringToWString(text)
    end
    LabelSetText(name, text)
end

---
--- Gets the text of a label.
---@param name string The name of the label.
---@return string The text of the label.
function Api.Label.GetText(name)
    return LabelGetText(name)
end

---
--- Sets the text color of a label.
---@param name string The name of the label.
---@param color table The color to set.
function Api.Label.SetTextColor(name, color)
    LabelSetTextColor(name, color.r, color.g, color.b)
end

---
--- Sets the text alignment of a label.
---@param name string The name of the label.
---@param alignment string The alignment to set.
function Api.Label.SetTextAlignment(name, alignment)
    LabelSetTextAlign(name, alignment)
end

---
--- Sets the word wrap of a label.
---@param name string The name of the label.
---@param wordWrap boolean Whether to wrap words.
function Api.Label.SetWordWrap(name, wordWrap)
    LabelSetWordWrap(name, wordWrap)
end

-- ========================================================================== --
-- Api - List Box
-- ========================================================================== --


Api.ListBox = {}

---
--- Sets the data table for a list box.
--- The engine expects ListBoxSetDataTable(windowName, globalVarName) where
--- globalVarName is the string name of a global Lua variable holding the data.
--- This wrapper stores the table in _G under a deterministic key and passes
--- that key string to the engine.
---@param name string The name of the list box.
---@param data table The data table to set.
function Api.ListBox.SetDataTable(name, data)
    local globalName = name .. "_DataTable"
    _G[globalName] = data
    ListBoxSetDataTable(name, globalName)
end

---
--- Gets the data index for a row in a list box.
---@param name string The name of the list box.
---@param rowIndex number The row index.
---@return number The data index.
function Api.ListBox.GetDataIndex(name, rowIndex)
    return ListBoxGetDataIndex(name, rowIndex)
end

---
--- Sets the display order for a list box.
---@param name string The name of the list box.
---@param orderArray table The display order to set.
function Api.ListBox.SetDisplayOrder(name, orderArray)
    ListBoxSetDisplayOrder(name, orderArray)
end

---
--- Sets the visible row count for a list box.
---@param name string The name of the list box.
---@param count number The visible row count to set.
function Api.ListBox.SetVisibleRowCount(name, count)
    ListBoxSetVisibleRowCount(name, count)
end

---
--- Gets the engine-managed PopulatorIndices for a list box.
--- This table maps visible row indices to data indices and is populated by the engine
--- after the list box display is updated.
---@param name string The name of the list box.
---@return table? The PopulatorIndices array, or nil if not populated.
function Api.ListBox.GetPopulatorIndices(name)
    local tbl = _G[name]
    if tbl then
        return tbl.PopulatorIndices
    end
    return nil
end

---
--- Clears the global data table entry for a list box.
--- Call this when the list box is destroyed to free the global reference.
---@param name string The name of the list box.
function Api.ListBox.ClearDataTable(name)
    local globalName = name .. "_DataTable"
    _G[globalName] = nil
end

---
--- Gets the engine-managed number of visible rows for a list box.
---@param name string The name of the list box.
---@return number The number of visible rows.
function Api.ListBox.GetNumVisibleRows(name)
    local tbl = _G[name]
    if tbl then
        return tbl.numVisibleRows or 0
    end
    return 0
end

-- ========================================================================== --
-- Api - Log Display
-- ========================================================================== --

Api.LogDisplay = {}

---
--- Sets whether to show timestamps in a log display.
---@param name string The name of the log display.
---@param doShow boolean Whether to show timestamps.
function Api.LogDisplay.ShowTimestamp(name, doShow)
    LogDisplaySetShowTimestamp(name, doShow == nil or doShow)
end

---
--- Gets whether timestamps are showing in a log display.
---@param name string The name of the log display.
---@return boolean Whether timestamps are showing.
function Api.LogDisplay.IsTimestampShowing(name)
    return LogDisplayGetShowTimestamp(name)
end

---
--- Sets whether to show the log name in a log display.
---@param name string The name of the log display.
---@param doShow boolean Whether to show the log name.
function Api.LogDisplay.ShowLogName(name, doShow)
    LogDisplaySetShowLogName(name, doShow == nil or doShow)
end

---
--- Sets whether to show the filter name in a log display.
---@param name string The name of the log display.
---@param doShow boolean Whether to show the filter name.
function Api.LogDisplay.ShowFilterName(name, doShow)
    LogDisplaySetShowFilterName(name, doShow == nil or doShow)
end

---
--- Adds a log to a log display.
---@param name string The name of the log display.
---@param log string The log to add.
---@param displayPreviousEntries boolean? Whether to display previous entries.
function Api.LogDisplay.AddLog(name, log, displayPreviousEntries)
    LogDisplayAddLog(name, log, displayPreviousEntries == nil or displayPreviousEntries)
end

---
--- Removes a log from a log display.
---@param name string The name of the log display.
---@param log string The log to remove.
function Api.LogDisplay.RemoveLog(name, log)
    LogDisplayRemoveLog(name, log)
end

---
--- Sets the filter color for a log display.
---@param name string The name of the log display.
---@param log string The log to set the color for.
---@param level number The level of the filter.
---@param color table The color to set.
function Api.LogDisplay.SetFilterColor(name, log, level, color)
    LogDisplaySetFilterColor(name, log, level, color.r, color.g, color.b)
end

---
--- Sets the filter state for a log display.
---@param name string The name of the log display.
---@param log string The log to set the state for.
---@param filterId number The ID of the filter.
---@param isEnabled boolean Whether the filter is enabled.
function Api.LogDisplay.SetFilterState(name, log, filterId, isEnabled)
    LogDisplaySetFilterState(name, log, filterId, isEnabled)
end

---
--- Sets the text fade time for a log display.
---@param name string The name of the log display.
---@param time number The fade time to set.
function Api.LogDisplay.SetTextFadeTime(name, time)
    LogDisplaySetTextFadeTime(name, time)
end

---
--- Gets the text fade time for a log display.
---@param name string The name of the log display.
---@return number The text fade time.
function Api.LogDisplay.GetTextFadeTime(name)
    return LogDisplayGetTextFadeTime(name)
end

---
--- Gets whether the scrollbar is active in a log display.
---@param name string The name of the log display.
---@return boolean Whether the scrollbar is active.
function Api.LogDisplay.IsScrollbarActive(name)
    return LogDisplayIsScrollbarActive(name)
end

---
--- Sets the font for a log display.
---@param name string The name of the log display.
---@param font string The font to set.
function Api.LogDisplay.SetFont(name, font)
    LogDisplaySetFont(name, font)
end

---
--- Gets the font for a log display.
---@param name string The name of the log display.
---@return string The font.
function Api.LogDisplay.GetFont(name)
    return LogDisplayGetFont(name)
end

---
--- Scrolls a log display to the bottom.
---@param name string The name of the log display.
function Api.LogDisplay.ScrollToBottom(name)
    LogDisplayScrollToBottom(name)
end

---
--- Gets whether a log display is scrolled to the bottom.
---@param name string The name of the log display.
---@return boolean Whether the log display is scrolled to the bottom.
function Api.LogDisplay.IsScrolledToBottom(name)
    return LogDisplayIsScrolledToBottom(name)
end

---
--- Resets the line fade time for a log display.
---@param name string The name of the log display.
function Api.LogDisplay.ResetLineFadeTime(name)
    LogDisplayResetLineFadeTime(name)
end

---
--- Sets whether to show the scrollbar in a log display.
---@param name string The name of the log display.
---@param showScrollbar boolean Whether to show the scrollbar.
function Api.LogDisplay.ShowScrollbar(name, showScrollbar)
    LogDisplayShowScrollbar(name, showScrollbar)
end

---
--- Scrolls a log display to the top.
---@param name string The name of the log display.
function Api.LogDisplay.ScrollToTop(name)
    LogDisplayScrollToTop(name)
end

---
--- Gets whether a log display is scrolled to the top.
---@param name string The name of the log display.
---@return boolean Whether the log display is scrolled to the top.
function Api.LogDisplay.IsScrolledToTop(name)
    return LogDisplayIsScrolledToTop(name)
end

-- ========================================================================== --
-- Api - Mod
-- ========================================================================== --


Api.Mod = {}

---
--- Loads resources for a mod.
---@param path string The path to the resources.
---@param file string The file to load.
---@param resource string The resource to load.
function Api.Mod.LoadResources(path, file, resource)
    LoadResources(path, file, resource)
end

---
--- Sets whether a module is enabled.
---@param moduleName string The name of the module.
---@param isEnabled boolean Whether the module is enabled.
function Api.Mod.SetEnabled(moduleName, isEnabled)
    ModuleSetEnabled(moduleName, isEnabled)
end

---
--- Initializes a module.
---@param moduleName string The name of the module.
function Api.Mod.Initialize(moduleName)
    ModuleInitialize(moduleName)
end

---
--- Gets the data for all modules.
---@return any The data for all modules.
function Api.Mod.GetData()
    return ModulesGetData()
end

---
--- Initializes restricted modules.
function Api.Mod.InitializeRestricted()
    ModulesInitializeRestricted()
end

---
--- Initializes all enabled modules.
function Api.Mod.InitializeAllEnabled()
    ModulesInitializeAllEnabled()
end

---
--- Loads a module as restricted.
---@param modFilePath string The path to the module file.
---@param allowRaw boolean Whether to allow raw loading.
function Api.Mod.LoadModuleAsRestricted(modFilePath, allowRaw)
    ModuleRestrictedLoad(modFilePath, allowRaw)
end

---
--- Loads a module.
---@param modFilePath string The path to the module file.
---@param setName string The name of the set.
---@param allowRaw boolean Whether to allow raw loading.
function Api.Mod.LoadModule(modFilePath, setName, allowRaw)
    ModuleLoad(modFilePath, setName, allowRaw)
end

---
--- Loads modules from a list file.
---@param listFilePath string The path to the list file.
---@param setName string The name of the set.
---@param allowRaw boolean Whether to allow raw loading.
function Api.Mod.LoadModulesFromList(listFilePath, setName, allowRaw)
    ModulesLoadFromListFile(listFilePath, setName, allowRaw)
end

---
--- Loads modules from a directory.
---@param directory string The directory to load modules from.
---@param setName string The name of the set.
function Api.Mod.LoadModulesFromDirectory(directory, setName)
    ModulesLoadFromDirectory(directory, setName)
end

-- ========================================================================== --
-- Api - Object
-- ========================================================================== --

Api.Object = {}

---
--- Gets the distance of an object from the player.
---@param id number The ID of the object.
---@return number The distance of the object from the player.
function Api.Object.GetDistanceFromPlayer(id)
    return GetDistanceFromPlayer(id)
end

---
--- Checks if an object is valid.
---@param id number The ID of the object.
---@return boolean Whether the object is valid.
function Api.Object.IsValid(id)
    return IsValidObject(id)
end

---
--- Checks if an object is a mobile.
---@param id number The ID of the object.
---@return boolean Whether the object is a mobile.
function Api.Object.IsMobile(id)
    return IsMobile(id)
end

---
--- Gets the paperdoll object for a paperdoll ID.
---@param paperdollId number The paperdoll ID.
---@param scale number The scale of the object.
---@return any The paperdoll object.
function Api.Object.GetPaperdollObject(paperdollId, scale)
    return GetPaperdollObject(paperdollId, scale or 1.0)
end

-- ========================================================================== --
-- Api - Radar
-- ========================================================================== --


Api.Radar = {}

---
--- Sets the window size for the radar.
---@param sizeX number The width of the window.
---@param sizeY number The height of the window.
---@param boolOne boolean A boolean value.
---@param centerOnPlayer boolean Whether to center the radar on the player.
function Api.Radar.SetWindowSize(sizeX, sizeY, boolOne, centerOnPlayer)
    UORadarSetWindowSize(sizeX, sizeY, boolOne, centerOnPlayer)
end

function Api.Radar.SetWindowOffset(x, y)
    UORadarSetWindowOffset(x, y)
end
---
--- Gets the facet for the radar.
---@return any The facet for the radar.
function Api.Radar.GetFacet()
    return UOGetRadarFacet()
end

---
--- Gets the area for the radar.
---@return any The area for the radar.
function Api.Radar.GetArea()
    return UOGetRadarArea()
end

---
--- Gets the maximum zoom for a map.
---@param facet any The facet of the map.
---@param area any The area of the map.
---@return number The maximum zoom.
function Api.Radar.GetMaxZoom(facet, area)
    return UORadarGetMaxZoomForMap(facet or Api.Radar.GetFacet(),
        area or Api.Radar.GetArea())
end

function Api.Radar.GetCurrentZoom()
    return Api.Interface.LoadNumber("MapZoom", 0)
end

---
--- Sets the zoom for the radar.
---@param zoom number The zoom to set.
function Api.Radar.SetZoom(zoom)
    UOSetRadarZoom(zoom)
    Api.Interface.SaveNumber("MapZoom", zoom)
end

---
--- Sets whether to center the radar on the player.
---@param isCenter boolean Whether to center the radar on the player.
function Api.Radar.SetCenterOnPlayer(isCenter)
    UORadarSetCenterOnPlayer(isCenter)
end

---
--- Gets the physical facet for the radar.
---@return any The physical facet for the radar.
function Api.Radar.GetPhysicalFacet()
    return UOGetPhysicalRadarFacet()
end

---
--- Gets the physical area for the radar.
---@param facet any The facet of the map.
---@param area any The area of the map.
---@return any The physical area for the radar.
function Api.Radar.GetPhysicalArea(facet, area)
    return UORadarGetAreaDimensions(facet, area)
end

---
--- Gets the facet label TID for the radar.
---@param facet any The facet of the map.
---@return integer The facet label TID.
function Api.Radar.GetFacetLabel(facet)
    return UORadarGetFacetLabel(facet)
end

---
--- Gets the area label TID for the radar.
---@param facet any The facet of the map.
---@param area any The area of the map.
---@return integer The area label TID.
function Api.Radar.GetAreaLabel(facet, area)
    return UORadarGetAreaLabel(facet, area)
end

---
--- Gets the facet dimensions for the radar.
---@param num number A number.
---@return any The facet dimensions.
function Api.Radar.GetFacetDimensions(num)
    return UORadarGetFacetDimensions(num)
end

---
--- Gets the center of the radar.
---@return any The center of the radar.
function Api.Radar.GetCenter()
    return UOGetRadarCenter()
end

---
--- Sets the rotation for the radar.
---@param rotation number The rotation to set.
function Api.Radar.SetRotation(rotation)
    UOSetRadarRotation(rotation)
end

---
--- Centers the radar on a location.
---@param x number The x-coordinate of the location.
---@param y number The y-coordinate of the location.
---@param facet any The facet of the map.
---@param area any The area of the map.
---@param bool boolean A boolean value.
function Api.Radar.CenterOnLocation(x, y, facet, area, bool)
    UOCenterRadarOnLocation(x, y, facet, area, bool)
end

---
--- Checks if a location is in an area.
---@param x number The x-coordinate of the location.
---@param y number The y-coordinate of the location.
---@param facet any The facet of the map.
---@param area any The area of the map.
---@return boolean Whether the location is in the area.
function Api.Radar.IsLocationInArea(x, y, facet, area)
    return UORadarIsLocationInArea(x, y, facet, area)
end

---
--- Translates a radar position to a world position.
---@param offsetX number The x-offset of the radar position.
---@param offsetY number The y-offset of the radar position.
---@param useScale boolean Whether to use the scale.
---@return any The world position.
function Api.Radar.TranslateRadarPositionToWorldPosition(offsetX, offsetY, useScale)
    return UOGetRadarPosToWorld(offsetX, offsetY, useScale)
end

---
--- Translates a world position to a radar position.
---@param x number The x-coordinate of the world position.
---@param y number The y-coordinate of the world position.
---@return any The radar position.
function Api.Radar.TranslateWorldPositionToRadarPosition(x, y)
    return UOGetWorldPosToRadar(x, y)
end

---
--- Gets the area count for a facet.
---@param facet any The facet.
---@return number The area count.
function Api.Radar.GetAreaCount(facet)
    return UORadarGetAreaCount(facet)
end

-- ========================================================================== --
-- Api - Scroll Window
-- ========================================================================== --

Api.ScrollWindow = {}

---
--- Sets the offset for a scroll window.
---@param id string The ID of the scroll window.
---@param offset number The offset to set.
function Api.ScrollWindow.SetOffset(id, offset)
    ScrollWindowSetOffset(id, offset)
end

---
--- Updates the scroll rect for a scroll window.
---@param id string The ID of the scroll window.
function Api.ScrollWindow.UpdateScrollRect(id)
    ScrollWindowUpdateScrollRect(id)
end

-- ========================================================================== --
-- Api - Horizontal Scroll Window
-- ========================================================================== --

Api.HorizontalScrollWindow = {}

---
--- Sets the offset for a horizontal scroll window.
---@param id string The ID of the horizontal scroll window.
---@param offset number The horizontal offset to set.
function Api.HorizontalScrollWindow.SetOffset(id, offset)
    HorizontalScrollWindowSetOffset(id, offset)
end

---
--- Updates the scroll rect for a horizontal scroll window.
---@param id string The ID of the horizontal scroll window.
function Api.HorizontalScrollWindow.UpdateScrollRect(id)
    HorizontalScrollWindowUpdateScrollRect(id)
end

-- ========================================================================== --
-- Api - Page Window
-- ========================================================================== --

Api.PageWindow = {}

---
--- Sets the active page on a page window.
---@param id string The name of the page window.
---@param pageNumber number The 1-based page number to show.
function Api.PageWindow.SetActivePage(id, pageNumber)
    PageWindowSetActivePage(id, pageNumber)
end

---
--- Gets the currently active page number.
---@param id string The name of the page window.
---@return number The active page number.
function Api.PageWindow.GetActivePage(id)
    return PageWindowGetActivePage(id)
end

---
--- Gets the total number of pages.
---@param id string The name of the page window.
---@return number The page count.
function Api.PageWindow.GetNumPages(id)
    return PageWindowGetNumPages(id)
end

-- ========================================================================== --
-- Api - Slider
-- ========================================================================== --

Api.Slider = {}

---
--- Sets the current position of a slider.
---@param id string The ID of the slider.
---@param position number The position to set.
function Api.Slider.SetCurrentPosition(id, position)
    SliderBarSetCurrentPosition(id, position)
end

---
--- Gets the current position of a slider.
---@param id string The ID of the slider.
---@return number The current position of the slider.
function Api.Slider.GetCurrentPosition(id)
    return SliderBarGetCurrentPosition(id)
end

-- ========================================================================== --
-- Api - Settings
-- ========================================================================== --

Api.Settings = {}

---
--- Pushes current Lua-side settings to the C++ engine.
--- Must be called after modifying SystemData.Settings.* tables to persist changes.
---@return boolean needsReload Whether the client needs to reload to apply the changes.
function Api.Settings.UserSettingsChanged()
    return UserSettingsChanged()
end

---
--- Returns the current key binding string for the given action type.
---@param actionType string The action type string (e.g. "FORWARD", "ZOOM_IN").
---@return wstring The key binding wstring, or an empty wstring if unbound.
function Api.Settings.GetKeybinding(actionType)
    return SystemData.Settings.Keybindings[actionType] or L""
end

---
--- Sets a key binding for the given action type.
--- Call Api.Settings.UserSettingsChanged() afterwards to persist.
---@param actionType string The action type string.
---@param key wstring The key wstring to assign.
function Api.Settings.SetKeybinding(actionType, key)
    SystemData.Settings.Keybindings[actionType] = key
end

---
--- Begins interactive key recording. Sets IsRecordingSettings and broadcasts the
--- INTERFACE_RECORD_KEY event. The engine will fire INTERFACE_KEY_RECORDED when done.
function Api.Settings.StartRecordKey()
    SystemData.IsRecordingSettings = true
    Api.Event.Broadcast(SystemData.Events.INTERFACE_RECORD_KEY)
end

---
--- Returns the key wstring that was last recorded by the engine.
---@return wstring The recorded key, or an empty wstring if none.
function Api.Settings.GetRecordedKey()
    return SystemData.RecordedKey or L""
end

---
--- Cancels an in-progress key recording session.
function Api.Settings.CancelRecordKey()
    SystemData.IsRecordingSettings = false
end

-- ========================================================================== --
-- Api - Status Bar
-- ========================================================================== --

Api.StatusBar = {}

---
--- Sets the maximum value of a status bar.
---@param id string The ID of the status bar.
---@param value number The maximum value to set.
function Api.StatusBar.SetMaxValue(id, value)
    StatusBarSetMaximumValue(id, value or 0)
end

---
--- Sets the current value of a status bar.
---@param id string The ID of the status bar.
---@param value number The current value to set.
function Api.StatusBar.SetCurrentValue(id, value)
    StatusBarSetCurrentValue(id, value or 0)
end

---
--- Sets the foreground tint of a status bar.
---@param id string The ID of the status bar.
---@param color table The color to set.
function Api.StatusBar.SetForegroundTint(id, color)
    StatusBarSetForegroundTint(id, color.r, color.g, color.b)
end

---
--- Sets the background tint of a status bar.
---@param id string The ID of the status bar.
---@param color table The color to set.
function Api.StatusBar.SetBackgroundTint(id, color)
    StatusBarSetBackgroundTint(id, color.r, color.g, color.b)
end

-- ========================================================================== --
-- Api - String
-- ========================================================================== --

Api.String = {}

---
--- Gets a string from a TID.
---@param tid number The TID.
---@return string The string.
function Api.String.GetStringFromTid(tid)
    return GetStringFromTid(tid)
end

---
--- Converts a string to a wstring.
---@param string string The string to convert.
---@return wstring The wstring.
function Api.String.StringToWString(string)
    return StringToWString(string)
end

---
--- Converts a wstring to a string.
---@param wString wstring The wstring to convert.
---@return string The string.
function Api.String.WStringToString(wString)
    return WStringToString(wString)
end

-- ========================================================================== --
-- Api - Target
-- ========================================================================== --

Api.Target = {}

---
--- Handles a single left click on a target.
---@param id number The ID of the target.
function Api.Target.LeftClick(id)
    HandleSingleLeftClkTarget(id)
end

---
--- Gets all mobile targets.
---@return table All mobile targets.
function Api.Target.GetAllMobileTargets()
    return GetAllMobileTargets()
end

-- ========================================================================== --
-- Api - Text Log
-- ========================================================================== --

Api.TextLog = {}

---
--- Creates a text log.
---@param name string The name of the text log.
---@param num number A number.
function Api.TextLog.Create(name, num)
    TextLogCreate(name, num)
end

---
--- Destroys a text log.
---@param name string The name of the text log.
function Api.TextLog.Destroy(name)
    TextLogDestroy(name)
end

---
--- Adds a filter type to a text log.
---@param name string The name of the text log.
---@param filterId number The unique ID number for this filter type.
---@param prefix wstring? The text to be prepended to entries of this type. Defaults to L"".
function Api.TextLog.AddFilterType(name, filterId, prefix)
    TextLogAddFilterType(name, filterId, prefix or L"")
end

---
--- Sets whether a text log is enabled.
---@param name string The name of the text log.
---@param isEnable boolean Whether the text log is enabled.
function Api.TextLog.SetEnabled(name, isEnable)
    TextLogSetEnabled(name, isEnable == nil or isEnable)
end

---
--- Clears a text log.
---@param name string The name of the text log.
function Api.TextLog.Clear(name)
    TextLogClear(name)
end

---
--- Sets incremental saving for a text log.
---@param name string The name of the text log.
---@param doSave boolean Whether to do incremental saving.
---@param path string The path to save to.
function Api.TextLog.SetIncrementalSaving(name, doSave, path)
    TextLogSetIncrementalSaving(name, doSave, path)
end

---
--- Gets whether a text log is enabled.
---@param name string The name of the text log.
---@return boolean Whether the text log is enabled.
function Api.TextLog.IsEnabled(name)
    return TextLogGetEnabled(name)
end

---
--- Gets the number of entries in a text log.
---@param name string The name of the text log.
---@return number The number of entries.
function Api.TextLog.GetNumEntries(name)
    return TextLogGetNumEntries(name)
end

---
--- Gets an entry from a text log.
---@param name string The name of the text log.
---@param index number The index of the entry.
---@return any The entry.
function Api.TextLog.GetEntry(name, index)
    return TextLogGetEntry(name, index)
end

---
--- Adds an entry to a text log.
---@param name string The name of the text log.
---@param filterId number The ID of the filter.
---@param text string The text of the entry.
function Api.TextLog.AddEntry(name, filterId, text)
    TextLogAddEntry(name, filterId, text)
end

---
--- Gets the event ID broadcast when a text log is updated.
---@param name string The name of the text log.
---@return number The event ID.
function Api.TextLog.GetUpdateEventId(name)
    return TextLogGetUpdateEventId(name)
end

-- ========================================================================== --
-- Api - Time
-- ========================================================================== --

Api.Time = {}

---
--- Gets the current date and time.
---@return any The current date and time.
function Api.Time.GetCurrentDateTime()
    return GetCurrentDateTime()
end

-- ========================================================================== --
-- Api - User Action
-- ========================================================================== --

Api.UserAction = {}

---
--- Uses an item.
---@param id number The ID of the item.
---@param flag boolean? A flag.
function Api.UserAction.UseItem(id, flag)
    flag = flag or false
    UserActionUseItem(id, flag)
end

---
--- Toggles war mode.
function Api.UserAction.ToggleWarMode()
    UserActionToggleWarMode()
end

-- ========================================================================== --
-- Api - Viewport
-- ========================================================================== --

Api.Viewport = {}

---
--- Updates the viewport.
---@param x1 number The x1 coordinate.
---@param y1 number The y1 coordinate.
---@param x2 number The x2 coordinate.
---@param y2 number The y2 coordinate.
function Api.Viewport.Update(x1, y1, x2, y2)
    UpdateViewport(x1, y1, x2, y2)
end

-- ========================================================================== --
-- Api - Waypoint
-- ========================================================================== --

Api.Waypoint = {}

---
--- Sets the facet for the waypoint map.
---@param facet any The facet to set.
function Api.Waypoint.SetFacet(facet)
    UOSetWaypointMapFacet(facet)
end

---
--- Creates a user waypoint.
---@param type any The type of the waypoint.
---@param facet any The facet of the map.
---@param x number The x-coordinate of the waypoint.
---@param y number The y-coordinate of the waypoint.
---@param id number The ID of the waypoint.
function Api.Waypoint.Create(type, facet, x, y, id)
    UOCreateUserWaypoint(type, facet, x, y, id)
end

---
--- Deletes a user waypoint.
---@param id number The ID of the waypoint to delete.
function Api.Waypoint.Delete(id)
    UODeleteUserWaypoint(id)
end

---
--- Edits a user waypoint.
---@param id number The ID of the waypoint to edit.
function Api.Waypoint.Edit(id)
    UOEditUserWaypoint(id)
end

---
--- Resets the facet for the waypoint map.
function Api.Waypoint.ResetFacet()
    UOResetWaypointMapFacet()
end

---
--- Sets the display info for a waypoint type.
function Api.Waypoint.SetTypeDisplayInfo()
    UOSetWaypointTypeDisplayInfo()
end

---
--- Sets the display mode for waypoints.
---@param mode any The display mode to set.
function Api.Waypoint.SetDisplayMode(mode)
    UOSetWaypointDisplayMode(mode)
end

---
--- Gets the info for a waypoint.
---@param id number The ID of the waypoint.
---@return any The waypoint info.
function Api.Waypoint.GetInfo(id)
    return UOGetWaypointInfo(id)
end

-- ========================================================================== --
-- Api - Window
-- ========================================================================== --

Api.Window = {}


function Api.Window.GetState(windowName)
    return WindowGetState(windowName)
end

--- Destroys a window.
---@param windowName string The name of the window to destroy.
---@return boolean Whether the window was destroyed.
function Api.Window.Destroy(windowName)
    if Api.Window.DoesExist(windowName) then
        DestroyWindow(windowName)
        _G[windowName .. "_DataTable"] = nil
        return true
    end

    return false
end

---
--- Checks if a window exists.
---@param windowName string The name of the window.
---@return boolean Whether the window exists.
function Api.Window.DoesExist(windowName)
    return DoesWindowNameExist(windowName)
end

---
--- Sets the showing state of a window.
---@param windowName string The name of the window.
---@param show boolean Whether to show the window.
function Api.Window.SetShowing(windowName, show)
    WindowSetShowing(windowName, show)
end

---
--- Gets the showing state of a window.
---@param windowName string The name of the window.
---@return boolean Whether the window is showing.
function Api.Window.IsShowing(windowName)
    return WindowGetShowing(windowName)
end

---
--- Sets the layer of a window.
---@param windowName string The name of the window.
---@param layer number The layer to set.
function Api.Window.SetLayer(windowName, layer)
    WindowSetLayer(windowName, layer)
end

---
--- Gets the layer of a window.
---@param windowName string The name of the window.
---@return number The layer of the window.
function Api.Window.GetLayer(windowName)
    return WindowGetLayer(windowName)
end

---
--- Sets whether a window handles input.
---@param windowName string The name of the window.
---@param handleInput boolean Whether to handle input.
function Api.Window.SetHandleInput(windowName, handleInput)
    WindowSetHandleInput(windowName, handleInput)
end

---
--- Gets whether a window handles input.
---@param windowName string The name of the window.
---@return boolean Whether the window handles input.
function Api.Window.GetHandleInput(windowName)
    return WindowGetHandleInput(windowName)
end

---
--- Sets whether a window is popable.
---@param windowName string The name of the window.
---@param popable boolean Whether the window is popable.
function Api.Window.SetPopable(windowName, popable)
    WindowSetPopable(windowName, popable)
end

---
--- Gets whether a window is popable.
---@param windowName string The name of the window.
---@return boolean Whether the window is popable.
function Api.Window.IsPopable(windowName)
    return WindowGetPopable(windowName)
end

---
--- Sets whether a window is movable.
---@param windowName string The name of the window.
---@param movable boolean Whether the window is movable.
function Api.Window.SetMovable(windowName, movable)
    WindowSetMovable(windowName, movable)
end

---
--- Gets whether a window is movable.
---@param windowName string The name of the window.
---@return boolean Whether the window is movable.
function Api.Window.IsMovable(windowName)
    return WindowGetMovable(windowName)
end

---
--- Sets the offset from the parent of a window.
---@param windowName string The name of the window.
---@param xOffset number The x-offset.
---@param yOffset number The y-offset.
function Api.Window.SetOffsetFromParent(windowName, xOffset, yOffset)
    WindowSetOffsetFromParent(windowName, xOffset, yOffset)
end

---
--- Gets the offset from the parent of a window.
---@param windowName string The name of the window.
---@return number, number The x-offset and y-offset.
function Api.Window.GetOffsetFromParent(windowName)
    return WindowGetOffsetFromParent(windowName)
end

---
--- Sets the dimensions of a window.
---@param windowName string The name of the window.
---@param xOffset number The width.
---@param yOffset number The height.
function Api.Window.SetDimensions(windowName, xOffset, yOffset)
    WindowSetDimensions(windowName, xOffset, yOffset)
end

---
--- Gets the dimensions of a window.
---@param windowName string The name of the window.
---@return table The dimensions of the window.
function Api.Window.GetDimensions(windowName)
    local x, y = WindowGetDimensions(windowName)
    return { x = x, y = y }
end

---
--- Checks if a window is sticky.
---@param windowName string The name of the window.
---@return boolean Whether the window is sticky.
function Api.Window.IsSticky(windowName)
    return WindowIsSticky(windowName)
end

---
--- Clears the anchors of a window.
---@param windowName string The name of the window.
function Api.Window.ClearAnchors(windowName)
    WindowClearAnchors(windowName)
end

---
--- Adds an anchor to a window.
---@param windowName string The name of the window.
---@param anchorPoint string The anchor point.
---@param relativeTo string The window to be relative to.
---@param relativePoint string The relative point.
---@param pointX number The x-point.
---@param pointY number The y-point.
function Api.Window.AddAnchor(windowName, anchorPoint, relativeTo, relativePoint, pointX, pointY)
    WindowAddAnchor(windowName, anchorPoint, relativeTo, relativePoint, pointX or 0, pointY or 0)
end

---
--- Gets an anchor of a window.
---@param windowName string The name of the window.
---@param anchorId number The ID of the anchor.
---@return any The anchor.
function Api.Window.GetAnchor(windowName, anchorId)
    return WindowGetAnchor(windowName, anchorId)
end

---
--- Gets the anchor count of a window.
---@param windowName string The name of the window.
---@return number The anchor count.
function Api.Window.GetAnchorCount(windowName)
    return WindowGetAnchorCount(windowName)
end

---
--- Forces a window to process its anchors.
---@param windowName string The name of the window.
function Api.Window.ForceProcessAnchors(windowName)
    WindowForceProcessAnchors(windowName)
end

---
--- Assigns focus to a window.
---@param windowName string The name of the window.
---@param doFocus boolean Whether to focus the window.
---@return boolean Whether focus was assigned.
function Api.Window.AssignFocus(windowName, doFocus)
    return WindowAssignFocus(windowName, doFocus)
end

---
--- Checks if a window has focus.
---@param windowName string The name of the window.
---@return boolean Whether the window has focus.
function Api.Window.HasFocus(windowName)
    return WindowHasFocus(windowName)
end

---
--- Sets the resizing state of a window.
---@param windowName string The name of the window.
---@param isResizing boolean Whether the window is resizing.
function Api.Window.SetResizing(windowName, isResizing)
    WindowSetResizing(windowName, isResizing)
end

---
--- Gets the resizing state of a window.
---@param windowName string The name of the window.
---@return boolean Whether the window is resizing.
function Api.Window.IsResizing(windowName)
    return WindowGetResizing(windowName)
end

---
--- Starts an alpha animation on a window.
---@param windowName string The name of the window.
---@param animType any The type of the animation.
---@param startAlpha number The starting alpha.
---@param endAlpha number The ending alpha.
---@param duration number The duration of the animation.
---@param setStartBeforeDelay boolean Whether to set the start before the delay.
---@param delay number The delay before the animation starts.
---@param numLoop number The number of times to loop the animation.
function Api.Window.StartAlphaAnimation(windowName, animType, startAlpha, endAlpha, duration, setStartBeforeDelay, delay,
                                        numLoop)
    WindowStartAlphaAnimation(windowName, animType, startAlpha, endAlpha, duration, setStartBeforeDelay,
        delay, numLoop)
end

---
--- Stops the alpha animation on a window.
---@param windowName string The name of the window.
function Api.Window.StopAlphaAnimation(windowName)
    WindowStopAlphaAnimation(windowName)
end

---
--- Stops the scale animation on a window.
---@param windowName string The name of the window.
function Api.Window.StopScaleAnimation(windowName)
    WindowStopScaleAnimation(windowName)
end

---
--- Starts a scale animation on a window.
---@param windowName string The name of the window.
---@param animType any The type of the animation.
---@param startX number The starting x-scale.
---@param startY number The starting y-scale.
---@param endX number The ending x-scale.
---@param endY number The ending y-scale.
---@param duration number The duration of the animation.
---@param setStartBeforeDelay boolean Whether to set the start before the delay.
---@param delay number The delay before the animation starts.
---@param numLoop number The number of times to loop the animation.
function Api.Window.StartScaleAnimation(windowName, animType, startX, startY, endX, endY, duration, setStartBeforeDelay,
                                        delay, numLoop)
    WindowStartScaleAnimation(
        windowName,
        animType,
        startX,
        startY,
        endX,
        endY,
        duration,
        setStartBeforeDelay,
        delay,
        numLoop
    )
end

---
--- Stops the position animation on a window.
---@param windowName string The name of the window.
function Api.Window.StopPositionAnimation(windowName)
    WindowStopPositionAnimation(windowName)
end

---
--- Sets the alpha of a window.
---@param windowName string The name of the window.
---@param alpha number The alpha to set.
function Api.Window.SetAlpha(windowName, alpha)
    WindowSetAlpha(windowName, alpha)
end

---
--- Gets the alpha of a window.
---@param windowName string The name of the window.
---@return number The alpha of the window.
function Api.Window.GetAlpha(windowName)
    return WindowGetAlpha(windowName)
end

---
--- Sets the color of a window.
---@param windowName string The name of the window.
---@param color table The color to set.
function Api.Window.SetColor(windowName, color)
    WindowSetTintColor(windowName, color.r, color.g, color.b)
end

---
--- Gets the color of a window.
---@param windowName string The name of the window.
---@return table The color of the window.
function Api.Window.GetColor(windowName)
    local r, g, b = WindowGetTintColor(windowName)
    return { r = r, g = g, b = b }
end

---
--- Creates a window from a template.
---@param windowName string The name of the window.
---@param template string The name of the template.
---@param parent string The name of the parent window.
---@param doShow boolean Whether to show the window.
---@return boolean Whether the window was created.
function Api.Window.CreateFromTemplate(windowName, template, parent, doShow)
    if not Api.Window.DoesExist(windowName) then
        CreateWindowFromTemplateShow(windowName, template or windowName, parent or "Root",
            doShow == nil or doShow)
        return true
    end
    return false
end

---
--- Creates a window.
---@param windowName string The name of the window.
---@param doShow boolean Whether to show the window.
---@return boolean Whether the window was created.
function Api.Window.Create(windowName, doShow)
    if not Api.Window.DoesExist(windowName) then
        CreateWindow(windowName, doShow == nil or doShow)
        return true
    end
    return false
end

---
--- Toggles a window.
---@param windowName string The name of the window.
---@return boolean Whether the window was created or shown.
function Api.Window.ToggleWindow(windowName)
    if not Api.Window.DoesExist(windowName) then
        return Api.Window.Create(windowName, true)
    else
        local state = not Api.Window.IsShowing(windowName)
        Api.Window.SetShowing(windowName, state)
        return state
    end
end

---
--- Sets the ID of a window.
---@param windowName string The name of the window.
---@param id number The ID to set.
function Api.Window.SetId(windowName, id)
    WindowSetId(windowName, id)
end

---
--- Gets the ID of a window.
---@param windowName string The name of the window.
---@return number The ID of the window.
function Api.Window.GetId(windowName)
    return WindowGetId(windowName)
end

---
--- Sets the tab order of a window.
---@param windowName string The name of the window.
---@param tabOrder number The tab order to set.
function Api.Window.SetTabOrder(windowName, tabOrder)
    WindowSetTabOrder(windowName, tabOrder)
end

---
--- Gets the tab order of a window.
---@param windowName string The name of the window.
---@return number The tab order of the window.
function Api.Window.GetTabOrder(windowName)
    return WindowGetTabOrder(windowName)
end

---
--- Sets the moving state of a window.
---@param windowName string The name of the window.
---@param isMoving boolean Whether the window is moving.
function Api.Window.SetMoving(windowName, isMoving)
    WindowSetMoving(windowName, isMoving)
end

---
--- Gets the moving state of a window.
---@param windowName string The name of the window.
---@return boolean Whether the window is moving.
function Api.Window.IsMoving(windowName)
    return WindowGetMoving(windowName)
end

---
--- Registers an event handler for a window.
---@param windowName string The name of the window.
---@param event string The event to register.
---@param callback function The callback function.
function Api.Window.RegisterEventHandler(windowName, event, callback)
    WindowRegisterEventHandler(windowName, event, callback)
end

---
--- Unregisters an event handler for a window.
---@param windowName string The name of the window.
---@param event string The event to unregister.
function Api.Window.UnregisterEventHandler(windowName, event)
    WindowUnregisterEventHandler(windowName, event)
end

---
--- Registers a core event handler for a window.
---@param windowName string The name of the window.
---@param event string The event to register.
---@param callback function The callback function.
function Api.Window.RegisterCoreEventHandler(windowName, event, callback)
    WindowRegisterCoreEventHandler(windowName, event, callback)
end

---
--- Unregisters a core event handler for a window.
---@param windowName string The name of the window.
---@param event string The event to unregister.
function Api.Window.UnregisterCoreEventHandler(windowName, event)
    WindowUnregisterCoreEventHandler(windowName, event)
end

---
--- Sets the parent of a window.
---@param windowName string The name of the window.
---@param parentId string The ID of the parent window.
function Api.Window.SetParent(windowName, parentId)
    WindowSetParent(windowName, parentId)
end

---
--- Gets the parent of a window.
---@param windowName string The name of the window.
---@return string The parent of the window.
function Api.Window.GetParent(windowName)
    return WindowGetParent(windowName)
end

---
--- Sets the scale of a window.
---@param windowName string The name of the window.
---@param scale number The scale to set.
function Api.Window.SetScale(windowName, scale)
    WindowSetScale(windowName, scale)
end

---
--- Gets the scale of a window.
---@param windowName string The name of the window.
---@return number The scale of the window.
function Api.Window.GetScale(windowName)
    return WindowGetScale(windowName)
end

---
--- Sets the relative scale of a window.
---@param windowName string The name of the window.
---@param scale number The relative scale to set.
function Api.Window.SetRelativeScale(windowName, scale)
    WindowSetRelativeScale(windowName, scale)
end

---
--- Resizes a window based on its children.
---@param windowName string The name of the window.
---@param isRecursive boolean Whether to resize recursively.
---@param borderSpacing number The border spacing.
function Api.Window.SetResizeOnChildren(windowName, isRecursive, borderSpacing)
    WindowResizeOnChildren(windowName, isRecursive, borderSpacing)
end

---
--- Sets the game action trigger for a window.
---@param windowName string The name of the window.
---@param action any The action to set.
function Api.Window.SetGameActionTrigger(windowName, action)
    WindowSetGameActionTrigger(windowName, action)
end

---
--- Sets the game action data for a window.
---@param windowName string The name of the window.
---@param actionType any The type of the action.
---@param actionId number The ID of the action.
---@param actionText string The text of the action.
function Api.Window.SetGameActionData(windowName, actionType, actionId, actionText)
    WindowSetGameActionData(windowName, actionType, actionId, actionText)
end

---
--- Sets the game action button for a window.
---@param windowName string The name of the window.
---@param button any The button to set.
function Api.Window.SetGameActionButton(windowName, button)
    WindowSetGameActionButton(windowName, button)
end

---
--- Gets the game action button for a window.
---@param windowName string The name of the window.
---@return any The game action button.
function Api.Window.GetGameActionButton(windowName)
    return WindowGetGameActionButton(windowName)
end

---
--- Checks if the game action is locked for a window.
---@param windowName string The name of the window.
---@return boolean Whether the game action is locked.
function Api.Window.IsGameActionLocked(windowName)
    return WindowIsGameActionLocked(windowName)
end

---
--- Sets whether to draw a window when the interface is hidden.
---@param windowName string The name of the window.
---@param doDraw boolean Whether to draw the window.
function Api.Window.SetDrawWhenInterfaceHidden(windowName, doDraw)
    WindowSetDrawWhenInterfaceHidden(windowName, doDraw)
end

---
--- Restores the default settings for a window.
---@param windowName string The name of the window.
function Api.Window.RestoreDefaults(windowName)
    WindowRestoreDefaultSettings(windowName)
end

---
--- Sets the update frequency for a window.
---@param windowName string The name of the window.
---@param frequency number The update frequency to set.
function Api.Window.SetUpdateFrequency(windowName, frequency)
    WindowSetUpdateFrequency(windowName, frequency)
end

---
--- Gets the screen position of a window.
---@param id string The ID of the window.
---@return number, number The x and y coordinates of the window.
function Api.Window.GetPosition(id)
    return WindowGetScreenPosition(id)
end

---
--- Attaches a window to a world object.
---@param objectId number The ID of the world object.
---@param window string The name of the window.
function Api.Window.AttachToWorldObject(objectId, window)
    AttachWindowToWorldObject(objectId, window)
end

---
--- Detaches a window from a world object.
---@param objectId number The ID of the world object.
---@param window string The name of the window.
function Api.Window.DetachFromWorldObject(objectId, window)
    DetachWindowFromWorldObject(objectId, window)
end

---
--- Registers window data.
---@param data any The data to register.
---@param id number The ID of the data.
function Api.Window.RegisterData(data, id)
    RegisterWindowData(data, id or 0)
end

---
--- Unregisters window data.
---@param data any The data to unregister.
---@param id number The ID of the data.
function Api.Window.UnregisterData(data, id)
    UnregisterWindowData(data, id or 0)
end

---
--- Saves the position of a window.
---@param window string The name of the window.
---@param closing boolean Whether the window is closing.
---@param alias string An alias for the window.
function Api.Window.SavePosition(window, closing, alias)
    WindowUtils.SaveWindowPosition(window, closing, alias)
end

---
--- Restores the position of a window.
---@param window string The name of the window.
---@param trackSize boolean Whether to track the size of the window.
---@param alias string An alias for the window.
---@param ignoreBounds boolean Whether to ignore the bounds of the window.
function Api.Window.RestorePosition(window, trackSize, alias, ignoreBounds)
    WindowUtils.RestoreWindowPosition(window, trackSize, alias, ignoreBounds)
end

---
--- Returns the name of the currently active (event-dispatching) window.
---@return string
function Api.Window.GetActiveWindowName()
    return SystemData.ActiveWindow.name
end

---
--- Returns the dynamic window ID set by the engine when a dynamic window is created
--- (e.g. the merchant ID for a Shopkeeper window).
---@return integer
function Api.Window.GetDynamicWindowId()
    return SystemData.DynamicWindowId
end

---
--- Returns the UpdateInstanceId from the most recent WindowData update event.
---@return integer
function Api.Window.GetUpdateInstanceId()
    return WindowData.UpdateInstanceId
end

-- ========================================================================== --
-- Api - Interface Core
-- ========================================================================== --


Api.InterfaceCore = {}

---
--- Gets the scale factor of the interface.
---@return number The scale factor.
function Api.InterfaceCore.GetScaleFactor()
    return 1 / InterfaceCore.scale
end

function Api.InterfaceCore.ReloadUI()
    InterfaceCore.ReloadUI()
end

-- ========================================================================== --
-- Api - Interface
-- ========================================================================== --

Api.Interface = {}

function Api.Interface.SaveString(key, value)
    Interface.SaveString(key, value)
end

function Api.Interface.LoadString(key, default)
    return Interface.LoadString(key, default)
end

function Api.Interface.SaveNumber(key, value)
    Interface.SaveNumber(key, value)
end

function Api.Interface.LoadNumber(key, default)
    return Interface.LoadNumber(key, default)
end

function Api.Interface.SaveBoolean(key, value)
    Interface.SaveBoolean(key, value)
end

function Api.Interface.LoadBoolean(key, default)
    return Interface.LoadBoolean(key, default)
end

---
--- Sets whether the player's paperdoll is considered open by the engine.
---@param open boolean
function Api.Interface.SetPaperdollOpen(open)
    Interface.PaperdollOpen = open
end

---
--- Gets whether the player's paperdoll is considered open by the engine.
---@return boolean
function Api.Interface.GetPaperdollOpen()
    return Interface.PaperdollOpen
end

---
--- Gets mobile data for a given ID from the engine.
---@param id number The mobile ID.
---@param includeEquipment boolean Whether to include equipment data.
---@return table Mobile data table with Race, Gender, etc.
function Api.Interface.GetMobileData(id, includeEquipment)
    return Interface.GetMobileData(id, includeEquipment)
end

-- ========================================================================== --
-- Api - Item Properties
-- ========================================================================== --

Api.ItemProperties = {}

---
--- Sets the active item for tooltip display.
---@param itemData table Table with windowName, itemId, itemType, detail, data fields.
function Api.ItemProperties.SetActiveItem(itemData)
    ItemProperties.SetActiveItem(itemData)
end

---
--- Clears the current mouse-over item tooltip.
function Api.ItemProperties.ClearMouseOverItem()
    ItemProperties.ClearMouseOverItem()
end

-- ========================================================================== --
-- Api - Equipment
-- ========================================================================== --

Api.Equipment = {}

---
--- Updates an item icon DynamicImage from equipment slot data.
---@param elementName string The DynamicImage window name.
---@param slotData PaperdollSlot The slot data from WindowData.Paperdoll.
function Api.Equipment.UpdateItemIcon(elementName, slotData)
    EquipmentData.UpdateItemIcon(elementName, slotData)
end

-- ========================================================================== --
-- Utils
-- ========================================================================== --

-- ========================================================================== --
-- Utils - Array
-- ========================================================================== --

Utils.Array = {}

---@generic K
---@generic R
---@param array K[]
---@param mapper fun(k: K, index: number): R?
---@return R[]
function Utils.Array.MapToArray(array, mapper)
    local newArray = {}

    Utils.Array.ForEach(
        array,
        function(k, index)
            local item = mapper(k, index)
            if item ~= nil then
                table.insert(newArray, item)
            end
        end
    )

    return newArray
end

---@generic T
---@param array T[]
---@return T[]
function Utils.Array.Copy(array)
    return Utils.Array.MapToArray(array, function(item, _)
        return item
    end)
end

---@generic T
---@param array T[]
---@param index integer
---@return T?
function Utils.Array.Remove(array, index)
    if index > #array then
        return nil
    else
        return table.remove(array, index)
    end
end

---@generic T
---@param array T[]
---@param predicate fun(item: T, index: integer): boolean
function Utils.Array.Filter(array, predicate)
    return Utils.Array.MapToArray(
        array,
        function(item, index)
            if predicate(item, index) then
                return item
            else
                return nil
            end
        end
    )
end

---@generic T
---@param array T[]
---@param predicate fun(item: T, index: integer): boolean
---@return integer[]
function Utils.Array.Indices(array, predicate)
    return Utils.Array.MapToArray(
        array,
        function(item, index)
            if predicate(item, index) then
                return index
            else
                return nil
            end
        end
    )
end

---@generic T, R
---@param array T[]
---@param reducer fun(accumulator: R, item: T, index: integer): R
---@param initial R
---@return R
function Utils.Array.Reduce(array, reducer, initial)
    local acc = initial
    Utils.Array.ForEach(array, function(item, index)
        acc = reducer(acc, item, index)
    end)
    return acc
end

---@generic K
---@param arrays K[][]
---@return K[]
function Utils.Array.Concat(arrays)
    local newArray = {}

    if not arrays or #arrays == 0 then
        return newArray
    end

    if #arrays == 1 then
        return arrays[1]
    end

    Utils.Array.ForEach(
        arrays,
        function(item, _)
            Utils.Array.ForEach(
                item,
                function(subItem, _)
                    table.insert(newArray, subItem)
                end
            )
        end
    )

    return newArray
end

---@generic K
---@generic V
---@generic T
---@param array T[]
---@param getKey fun(item: T, index: integer): K
---@param getValue fun(item: T, index: integer): V
---@return table<K,V>
function Utils.Array.MapToTable(array, getKey, getValue)
    local newTable = {}

    Utils.Array.ForEach(
        array,
        function(item, index)
            newTable[getKey(item, index)] = getValue(item, index)
        end
    )

    return newTable
end

---@generic T
---@param array T[]
---@param find fun(item: T): boolean
---@return integer
function Utils.Array.IndexOf(array, find)
    for i = 1, #array do
        local item = array[i]
        if find(item) then
            return i
        end
    end

    return -1
end

---Returns the 1-based index of the first element matching `find`, or `default` if not found.
---@generic T
---@param array T[]
---@param find fun(item: T): boolean
---@param default integer Fallback index when no match is found
---@return integer
function Utils.Array.IndexOfOrDefault(array, find, default)
    local idx = Utils.Array.IndexOf(array, find)
    if idx < 1 then return default end
    return idx
end

---@generic T
---@param array T[]
---@param find fun(item: T): boolean
---@return T?
function Utils.Array.Find(array, find)
    if not array or #array == 0 then
        return nil
    end

    for i = 1, #array do
        local item = array[i]
        if find(item) then
            return item
        end
    end

    return nil
end

--- Returns true if every element in the array satisfies the predicate.
--- Returns true for nil or empty arrays (vacuous truth).
---@generic T
---@param array T[]?
---@param predicate fun(item: T, index: integer): boolean
---@return boolean
function Utils.Array.Every(array, predicate)
    if not array or #array == 0 then
        return true
    end

    for i = 1, #array do
        if not predicate(array[i], i) then
            return false
        end
    end

    return true
end

---@generic T
---@param array T[]
---@param forEach fun(item: T, index: integer)
function Utils.Array.ForEach(array, forEach)
    if not array or #array == 0 then
        return
    end

    for i = 1, #array do
        local item = array[i]
        forEach(item, i)
    end
end

---@generic T
---@param array T[]
---@param item T
---@param pos integer?
function Utils.Array.Add(array, item, pos)
    if pos and pos > 0 and pos <= #array + 1 then
        table.insert(array, pos, item)
    else
        table.insert(array, item)
    end
end

--- Returns true if the array is nil or has no elements.
---@param array any[]?
---@return boolean
function Utils.Array.IsEmpty(array)
    return not array or #array == 0
end

--- Adds item to the array only if it is not already present (by == equality).
--- Returns true if the item was added, false if it was already in the array.
---@generic T
---@param array T[]
---@param item T
---@return boolean added
function Utils.Array.AddUnique(array, item)
    for i = 1, #array do
        if array[i] == item then
            return false
        end
    end
    table.insert(array, item)
    return true
end

-- ========================================================================== --
-- Utils - Table
-- ========================================================================== --

Utils.Table = {}

---@generic K
---@generic V
---@param table table<K, V>?
---@param forEach fun(k: K, v: V)
function Utils.Table.ForEach(table, forEach)
    if not table then
        return
    end

    for k, v in pairs(table) do
        forEach(k, v)
    end
end



---@generic K
---@generic V
---@param table table<K, V>?
---@param  isFound fun(k: K, v: V): boolean
---@return V?
function Utils.Table.Find(table, isFound)
    if not table then
        return nil
    end

    for k, v in pairs(table) do
        if isFound(k, v) then
            return v
        end
    end

    return nil
end

---@param targetTable table?
---@param sourceTable table?
---@return table
function Utils.Table.Merge(targetTable, sourceTable)
    if not targetTable and not sourceTable then
        return {}
    end
    if not targetTable then
        return Utils.Table.Copy(sourceTable)
    end
    if not sourceTable then
        return Utils.Table.Copy(targetTable)
    end

    local newTable = Utils.Table.Copy(targetTable)

    Utils.Table.ForEach(sourceTable, function(k, v)
        if type(v) == "table" and type(newTable[k]) == "table" then
            newTable[k] = Utils.Table.Merge(newTable[k], v)
        else
            newTable[k] = v
        end
    end)

    return newTable
end

---@param a table
---@param b table
---@param seen table?
---@return boolean
function Utils.Table.AreEqual(a, b, seen)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    seen = seen or {}
    if seen[a] == b then return true end
    seen[a] = b
    for k, v in pairs(a) do
        if not Utils.Table.AreEqual(v, b[k], seen) then
            return false
        end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

---@class TableValueDiff
---@field Before any?
---@field After any?


---@param prev table?
---@param next table?
---@return table<string, TableValueDiff>?
function Utils.Table.Diff(prev, next)
    prev = prev or {}
    next = next or {}

    ---@type type<string, TableValueDiff>
    local result = {}

    for k, pv in pairs(prev) do
        local nv = next[k]
        if nv == nil then
            result[k] = { Before = pv, After = nil }
        elseif pv ~= nv then
            if type(pv) == "table" and type(nv) == "table" and Utils.Table.AreEqual(pv, nv) then
                -- structurally same, skip
            else
                result[k] = { Before = pv, After = nv }
            end
        end
    end

    for k, nv in pairs(next) do
        if prev[k] == nil then
            result[k] = { Before = nil, After = nv }
        end
    end

    if Utils.Table.IsEmpty(result) then
        return nil
    else
        return result
    end
end

function Utils.Table.IsEmpty(table)
    if not table then
        return true
    end

    for _ in pairs(table) do
        return false
    end

    return true
end

---@generic K
---@generic V
---@param table table<K, V>?
---@return table<K, V>
function Utils.Table.Copy(table)
    local newTable = {}

    if not table then
        return newTable
    end

    for k, v in pairs(table) do
        newTable[k] = v
    end

    return newTable
end

---@generic K
---@generic V
---@param table table<K, V>
---@return table<K, V>
function Utils.Table.OverrideFunctions(table)
    for k, v in pairs(table) do
        if type(v) == "function" then
            table[k] = function() end
        end
    end
    return table
end

---@generic T
---@generic V
---@generic R
---@param _table table<T, V>
---@param forEach fun(k: T, v: V): R
---@return R[]
function Utils.Table.MapToArray(_table, forEach)
    local array = {}
    Utils.Table.ForEach(
        _table,
        function(k, v)
            table.insert(array, forEach(k, v))
        end
    )
    return array
end

-- ========================================================================== --
-- Utils - String
-- ========================================================================== --

Utils.String = {}

function Utils.String.ExtractNumber(text)
    return tonumber(string.match(text, "%d+") or 0)
end

function Utils.String.Random()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local result = ""
    for i = 1, 24 do
        local rand = math.random(1, #charset)
        result = result .. charset:sub(rand, rand)
    end
    return result
end

function Utils.String.FromWString(text)
    if type(text) == "string" then
        return text
    else
        return Api.String.WStringToString(text)
    end
end

--- Returns true if text is nil, empty string "", or empty wstring L"".
--- @param text string|wstring|nil
--- @return boolean
function Utils.String.IsEmpty(text)
    if text == nil then return true end
    if text == "" then return true end
    if text == L"" then return true end
    return false
end

function Utils.String.ToWString(text)
    if text == nil then return L"" end
    if type(text) == "number" then
        return Api.String.GetStringFromTid(text)
    elseif type(text) == "wstring" then
        return text
    elseif type(text) == "string" then
        return Api.String.StringToWString(text)
    else
        return Api.String.StringToWString(tostring(text))
    end
end

function Utils.String.Lower(text)
    if text == nil then return "" end
    if type(text) == "string" then
        return string.lower(text)
    elseif type(text) == "wstring" then
        return string.lower(Utils.String.FromWString(text))
    end
end

function Utils.String.Upper(text)
    if text == nil then return "" end
    if type(text) == "string" then
        return string.upper(text)
    elseif type(text) == "wstring" then
        return string.upper(Utils.String.FromWString(text))
    end
end

--- Substitutes all occurrences of pattern in text.
--- Accepts string or wstring; returns the same type as the input.
--- Nil input returns L"".
---@param text string|wstring|nil
---@param pattern string Lua pattern
---@param replacement string
---@return string|wstring
function Utils.String.Replace(text, pattern, replacement)
    if text == nil then return L"" end
    if type(text) == "wstring" then
        local s = Api.String.WStringToString(text)
        return Api.String.StringToWString(string.gsub(s, pattern, replacement))
    end
    return string.gsub(text, pattern, replacement)
end

--- Searches for the first occurrence of pattern in text.
--- Accepts string or wstring. Returns start/end positions (always integers).
---@param text string|wstring|nil
---@param pattern string Lua pattern or plain substring
---@param init integer? Start position (default 1)
---@param plain boolean? If true, pattern is a plain string
---@param ignoreCase boolean? If true, lowercases both text and pattern before matching
---@return integer|nil startPos
---@return integer|nil endPos
function Utils.String.Find(text, pattern, init, plain, ignoreCase)
    if text == nil then return nil end
    if type(text) == "wstring" then
        text = Api.String.WStringToString(text)
    end
    if ignoreCase then
        text = string.lower(text)
        pattern = string.lower(pattern)
    end
    return string.find(text, pattern, init, plain)
end

--- Returns true if text contains the given pattern.
--- Accepts string or wstring.
---@param text string|wstring|nil
---@param pattern string Lua pattern or plain substring
---@param plain boolean? If true, pattern is a plain string
---@param ignoreCase boolean? If true, lowercases both text and pattern before matching
---@return boolean
function Utils.String.Contains(text, pattern, plain, ignoreCase)
    return Utils.String.Find(text, pattern, 1, plain, ignoreCase) ~= nil
end

--- Returns the first match of pattern in text, or nil if no match.
--- When the pattern contains captures, returns the first capture.
--- Accepts string or wstring; returns the same type as the input (or nil).
---@param text string|wstring|nil
---@param pattern string Lua pattern
---@return string|wstring|nil
function Utils.String.Match(text, pattern)
    if text == nil then return nil end
    local isW = type(text) == "wstring"
    local s = isW and Api.String.WStringToString(text) or text
    local result = string.match(s, pattern)
    if result == nil then return nil end
    if isW then return Api.String.StringToWString(result) end
    return result
end

--- Returns an array of all matches of pattern in text.
--- When the pattern contains captures, each element is the first capture.
--- Accepts string or wstring; elements are the same type as the input.
--- Returns an empty table if no matches or text is nil.
---@param text string|wstring|nil
---@param pattern string Lua pattern
---@return (string|wstring)[]
function Utils.String.MatchAll(text, pattern)
    local results = {}
    if text == nil then return results end
    local isW = type(text) == "wstring"
    local s = isW and Api.String.WStringToString(text) or text
    for match in string.gmatch(s, pattern) do
        if isW then
            results[#results + 1] = Api.String.StringToWString(match)
        else
            results[#results + 1] = match
        end
    end
    return results
end

---@param fmt string
---@param ... any
---@return string
function Utils.String.Format(fmt, ...)
    return string.format(fmt, ...)
end

--- Concatenates any mix of string, wstring, number, or nil values into a single wstring.
--- Numbers are converted to their display representation (e.g. 123 → L"123"), NOT treated as TIDs.
--- Nil values are skipped.
--- @param ... string|wstring|number|nil
--- @return wstring
function Utils.String.Concat(...)
    local result = L""
    local numArgs = select("#", ...)
    for i = 1, numArgs do
        local v = select(i, ...)
        if v ~= nil then
            local t = type(v)
            if t == "wstring" then
                result = result .. v
            elseif t == "number" then
                result = result .. towstring(v)
            elseif t == "string" then
                result = result .. Api.String.StringToWString(v)
            else
                result = result .. Api.String.StringToWString(tostring(v))
            end
        end
    end
    return result
end

-- ========================================================================== --
-- Constants
-- ========================================================================== --

Constants.TargetType = {
    Mobile = 2,
    Object = 3,
    Corpse = 4
}

Constants.ButtonFlags = {
    Control = 8,
    Alt = 32,
    Shift = 4
}

Constants.DragSource = {}

function Constants.DragSource.Object()
    return SystemData.DragSource["SOURCETYPE_OBJECT"]
end

function Constants.DragSource.Paperdoll()
    return SystemData.DragSource["SOURCETYPE_PAPERDOLL"]
end

Constants.Broadcasts = {}

function Constants.Broadcasts.Help()
    return SystemData.Events["REQUEST_OPEN_HELP_MENU"]
end

function Constants.Broadcasts.BeginHealthBarDrag()
    return SystemData.Events["BEGIN_DRAG_HEALTHBAR_WINDOW"]
end

function Constants.Broadcasts.EscapeKeyProcessed()
    return SystemData.Events["ESCAPE_KEY_PROCESSED"]
end

function Constants.Broadcasts.ExitGame()
    return SystemData.Events["EXIT_GAME"]
end

function Constants.Broadcasts.BugReport()
    return SystemData.Events["BUG_REPORT_SCREEN"]
end

function Constants.Broadcasts.ResetMmoKeyBindings()
    return SystemData.Events["RESET_MMO_KEY_BINDINGS"]
end

function Constants.Broadcasts.ResetLegacyKeyBindings()
    return SystemData.Events["RESET_LEGACY_KEY_BINDINGS"]
end

function Constants.Broadcasts.ShopOfferAccept()
    return SystemData.Events["SHOP_OFFER_ACCEPT"]
end

function Constants.Broadcasts.ShopCancelOffer()
    return SystemData.Events["SHOP_CANCEL_OFFER"]
end

Constants.Settings = {}
Constants.Settings.ShowNames = {}

function Constants.Settings.ShowNames.None()
    return SystemData.Settings.GameOptions.SHOWNAMES_NONE
end

function Constants.Settings.ShowNames.Approaching()
    return SystemData.Settings.GameOptions.SHOWNAMES_APPROACHING
end

function Constants.Settings.ShowNames.All()
    return SystemData.Settings.GameOptions.SHOWNAMES_ALL
end

---@class DataEvent
---@field getType fun(): integer
---@field getEvent fun(): integer
---@field name string

---@type table<string, DataEvent>
Constants.DataEvents = {}

---@param windowData table The WindowData table (e.g. WindowData.PlayerStatus)
---@param name string The event name
---@return table DataEvent with lazy-cached getType/getEvent
local function DataEvent(windowData, name)
    local cachedType, cachedEvent
    return {
        getType = function()
            if not cachedType then cachedType = windowData.Type end
            return cachedType
        end,
        getEvent = function()
            if not cachedEvent then cachedEvent = windowData.Event end
            return cachedEvent
        end,
        name = name
    }
end

Constants.DataEvents.OnUpdatePlayerStatus = DataEvent(WindowData.PlayerStatus, "OnUpdatePlayerStatus")
Constants.DataEvents.OnUpdateMobileName = DataEvent(WindowData.MobileName, "OnUpdateMobileName")
Constants.DataEvents.OnUpdateHealthBarColor = DataEvent(WindowData.HealthBarColor, "OnUpdateHealthBarColor")
Constants.DataEvents.OnUpdateMobileStatus = DataEvent(WindowData.MobileStatus, "OnUpdateMobileStatus")
Constants.DataEvents.OnUpdateRadar = DataEvent(WindowData.Radar, "OnUpdateRadar")
Constants.DataEvents.OnUpdatePlayerLocation = DataEvent(WindowData.PlayerLocation, "OnUpdatePlayerLocation")
Constants.DataEvents.OnUpdatePaperdoll = DataEvent(WindowData.Paperdoll, "OnUpdatePaperdoll")
Constants.DataEvents.OnUpdateShopData = DataEvent(WindowData.ShopData, "OnUpdateShopData")
Constants.DataEvents.OnUpdateContainerWindow = DataEvent(WindowData.ContainerWindow, "OnUpdateContainerWindow")
Constants.DataEvents.OnUpdateObjectInfo = DataEvent(WindowData.ObjectInfo, "OnUpdateObjectInfo")
Constants.DataEvents.OnUpdateItemProperties = DataEvent(WindowData.ItemProperties, "OnUpdateItemProperties")

---@class SystemEvent
---@field getEvent fun(): integer
---@field name string

---@type table<string, SystemEvent>
Constants.SystemEvents = {}

Constants.SystemEvents.OnEndHealthBarDrag = {
    getEvent = function()
        return SystemData.Events["END_DRAG_HEALTHBAR_WINDOW"]
    end,
    name = "OnEndHealthBarDrag"
}

Constants.SystemEvents.OnLButtonUpProcessed = {
    getEvent = function()
        return SystemData.Events["L_BUTTON_UP_PROCESSED"]
    end,
    name = "OnLButtonUpProcessed"
}

Constants.SystemEvents.OnLButtonDownProcessed = {
    getEvent = function()
        return SystemData.Events["L_BUTTON_DOWN_PROCESSED"]
    end,
    name = "OnLButtonDownProcessed"
}

Constants.SystemEvents.OnUpdateProcessed = {
    getEvent = function()
        return SystemData.Events["UPDATE_PROCESSED"]
    end,
    name = "OnUpdateProcessed"
}

Constants.SystemEvents.OnKeyRecorded = {
    getEvent = function()
        return SystemData.Events.INTERFACE_KEY_RECORDED
    end,
    name = "OnKeyRecorded"
}

Constants.SystemEvents.OnKeyCancelRecord = {
    getEvent = function()
        return SystemData.Events.INTERFACE_KEY_CANCEL_RECORD
    end,
    name = "OnKeyCancelRecord"
}

Constants.SystemEvents.OnUserSettingsUpdated = {
    getEvent = function()
        return SystemData.Events.USER_SETTINGS_UPDATED
    end,
    name = "OnUserSettingsUpdated"
}

Constants.SystemEvents.OnToggleUserPreference = {
    getEvent = function()
        return SystemData.Events.TOGGLE_USER_PREFERENCE
    end,
    name = "OnToggleUserPreference"
}

Constants.CoreEvents = {}
Constants.CoreEvents.OnInitialize = "OnInitialize"
Constants.CoreEvents.OnShown = "OnShown"
Constants.CoreEvents.OnHidden = "OnHidden"
Constants.CoreEvents.OnShutdown = "OnShutdown"
Constants.CoreEvents.OnRButtonUp = "OnRButtonUp"
Constants.CoreEvents.OnRButtonDown = "OnRButtonDown"
Constants.CoreEvents.OnUpdate = "OnUpdate"
Constants.CoreEvents.OnLButtonDblClk = "OnLButtonDblClk"
Constants.CoreEvents.OnMouseOver = "OnMouseOver"
Constants.CoreEvents.OnMouseOverEnd = "OnMouseOverEnd"
Constants.CoreEvents.OnMouseWheel = "OnMouseWheel"
Constants.CoreEvents.OnSlide = "OnSlide"
Constants.CoreEvents.OnSelChanged = "OnSelChanged"

Constants.AnchorPoints = {}
Constants.AnchorPoints.BottomLeft = "bottomleft"
Constants.AnchorPoints.TopLeft = "topleft"
Constants.AnchorPoints.Top = "top"
Constants.AnchorPoints.Bottom = "bottom"
Constants.AnchorPoints.Center = "center"

Constants.WindowLayers = {}
Constants.WindowLayers.Background = 0
Constants.WindowLayers.Default = 1
Constants.WindowLayers.Secondary = 2
Constants.WindowLayers.Popup = 3
Constants.WindowLayers.Overlay = 4

Constants.ButtonStates = {}
Constants.ButtonStates.Normal = 0
Constants.ButtonStates.Pressed = 1
Constants.ButtonStates.Disabled = 2
Constants.ButtonStates.Highlighted = 3
Constants.ButtonStates.PressedHighlighted = 4
Constants.ButtonStates.DisabledPressed = 5

Constants.Textures = {}
Constants.Textures.MenuSelection = "MenuSelection"

Constants.Colors = {}
Constants.Colors.OffBlack = {
    r = 34,
    g = 34,
    b = 34
}
Constants.Colors.White = { r = 255, g = 255, b = 255 }
Constants.Colors.OffWhite = { r = 206, g = 217, b = 242 }
Constants.Colors.Red = { r = 164, g = 32, b = 32 }
Constants.Colors.YellowDark = { r = 164, g = 164, b = 32 }
Constants.Colors.Blue = { r = 32, g = 32, b = 164 }
Constants.Colors.HealhBar = {
    { r = 164, g = 32,  b = 32 }, -- Healthy
    { r = 32,  g = 164, b = 32 }, -- Poisoned
    { r = 128, g = 128, b = 128 } -- Cursed
}
Constants.Colors.Notoriety = {
    { r = 128, g = 200, b = 255 }, -- Innocent
    { r = 0,   g = 180, b = 0 },   -- Friendly
    { r = 225, g = 225, b = 225 }, -- Attackable
    { r = 225, g = 225, b = 225 }, -- Criminal
    { r = 242, g = 159, b = 77 },  -- Enemy
    { r = 255, g = 64,  b = 64 },  -- Murderer
    { r = 255, g = 255, b = 0 }    -- Invulnerable
}

Constants.TextAlignment = {}
Constants.TextAlignment.Center = "center"

Constants.ItemPropertyType = {}
Constants.ItemPropertyType.Item = WindowData.ItemProperties.TYPE_ITEM
Constants.ItemPropertyType.WStringData = WindowData.ItemProperties.TYPE_WSTRINGDATA

Constants.ItemPropertyDetail = {}
Constants.ItemPropertyDetail.Long = ItemProperties.DETAIL_LONG
Constants.ItemPropertyDetail.Short = ItemProperties.DETAIL_SHORT

Constants.GumpIds = {}
Constants.GumpIds.VendorSearch = 999112
Constants.GumpIds.PetTrainingProgress = 999139


-- ========================================================================== --
-- Data
-- ========================================================================== --

-- ========================================================================== --
-- Data - Active Mobile
-- ========================================================================== --

---@class SystemData.ActiveMobile
---@field Id number

---@class ActiveMobileWrapper
local ActiveMobile = {}
ActiveMobile.__index = ActiveMobile

function ActiveMobile:new()
    return setmetatable({}, self)
end

---@return SystemData.ActiveMobile
function ActiveMobile:getData()
    return SystemData.ActiveMobile
end

function ActiveMobile:getId()
    return self:getData().Id
end

function ActiveMobile:setId(id)
    self:getData().Id = id
end

function Data.ActiveMobile()
    return ActiveMobile:new()
end

-- ========================================================================== --
-- Data - Current Target
-- ========================================================================== --

---@class WindowData.CurrentTarget
---@field TargetId number
---@field HasPaperdoll boolean
---@field TargetType number
---@field HasTarget boolean
---@field isMobile fun(): boolean
---@field isObject fun(): boolean
---@field isCorpse fun(): boolean

---@class CurrentTargetWrapper
local CurrentTarget = {}
CurrentTarget.__index = CurrentTarget

function CurrentTarget:new()
    return setmetatable({}, self)
end

---@return WindowData.CurrentTarget
function CurrentTarget:getData()
    return WindowData.CurrentTarget
end

function CurrentTarget:hasTarget()
    return self:getData().HasTarget
end

function CurrentTarget:isMobile()
    return self:getData().TargetType == 2
end

function CurrentTarget:isCorpse()
    return self:getData().TargetType == 4
end

function CurrentTarget:isObject()
    return self:getData().TargetType == 3
end

function CurrentTarget:getId()
    return self:getData().TargetId
end

function Data.CurrentTarget()
    return CurrentTarget:new()
end

-- ========================================================================== --
-- Data - Cursor
-- ========================================================================== --

---@class WindowData.Cursor
---@field target boolean

---@class CursorDataWrapper
local Cursor = {}
Cursor.__index = Cursor

function Cursor:new()
    return setmetatable({}, self)
end

---@return WindowData.Cursor
function Cursor:getData()
    return WindowData.Cursor
end

function Cursor:isTarget()
    local data = self:getData()
    if data == nil then return false end
    return data.target == true
end

function Data.Cursor()
    return Cursor:new()
end

-- ========================================================================== --
-- Data - Drag
-- ========================================================================== --

---@class DragDataWrapper
local Drag = {}
Drag.__index = Drag

function Drag:new()
    return setmetatable({}, self)
end

---@return table<string, number>
function Drag:getDragItemData()
    return SystemData.DragItem
end

---@return table<string, number>
function Drag:getDragSourceData()
    return SystemData.DragSource
end

function Drag:isDraggingItem()
    return self:getDragItemData().DragType == SystemData.DragItem.TYPE_ITEM
end

function Drag:getDraggingObject()
    return self:getDragSourceData()["SOURCETYPE_OBJECT"]
end

function Data.Drag()
    return Drag:new()
end

-- ========================================================================== --
-- Color
-- ========================================================================== --

---@class Color
---@field r number
---@field g number
---@field b number


-- ========================================================================== --
-- Data - Health Bar Color
-- ========================================================================== --

---@class WindowData.HealthBarColor
---@field VisualStateId number

---@class HealthBarColorWrapper
---@field _id number
local HealthBarColor = {}
HealthBarColor.__index = HealthBarColor

function HealthBarColor:new(id)
    local instance = setmetatable({}, self)
    instance._id = id
    return instance
end

---@return WindowData.HealthBarColor
function HealthBarColor:getData()
    return WindowData.HealthBarColor[self._id]
end

function HealthBarColor:getVisualStateId()
    return self:getData().VisualStateId
end

function HealthBarColor:getVisualStateColor()
    return Constants.Colors.HealhBar[self:getVisualStateId() + 1]
end

function Data.HealthBarColor(id)
    return HealthBarColor:new(id)
end

-- ========================================================================== --
-- Data - Mobile Name
-- ========================================================================== --

---@class MobileNameWrapper
---@field _id number
local MobileName = {}
MobileName.__index = MobileName

function MobileName:new(id)
    local instance = setmetatable({}, self)
    instance._id = id
    return instance
end

---@return MobileName
function MobileName:getData()
    return WindowData.MobileName[self._id]
end

function MobileName:getName()
    return self:getData().MobName
end

function Data.MobileName(id)
    return MobileName:new(id)
end

-- ========================================================================== --
-- Data - Mobile Status
-- ========================================================================== --

---@class WindowData.MobileStatus
---@field MaxMana number
---@field Gender number
---@field MobName string
---@field MaxStamina number
---@field CurrentHealth number
---@field Race number
---@field MyPet boolean
---@field CurrentStamina number
---@field IsDead boolean
---@field CurrentMana number
---@field MaxHealth number
---@field Notoriety number

---@class MobileStatusWrapper
---@field _id number
local MobileStatus = {}
MobileStatus.__index = MobileStatus

function MobileStatus:new(id)
    local instance = setmetatable({}, self)
    instance._id = id
    return instance
end

---@return WindowData.MobileStatus
function MobileStatus:getData()
    return WindowData.MobileStatus[self._id]
end

function MobileStatus:getName()
    return self:getData().MobName
end

function MobileStatus:getNotoriety()
    return self:getData().Notoriety
end

function MobileStatus:getNotorietyColor()
    return Constants.Colors.Notoriety[self:getNotoriety() + 1]
end

function Data.MobileStatus(id)
    return MobileStatus:new(id)
end

-- ========================================================================== --
-- Data - Button Flags
-- ========================================================================== --

--- Checks whether a flags value contains the Shift modifier.
---@param flags number
---@return boolean
function Data.IsShift(flags)
    return flags == Constants.ButtonFlags.Shift
end

--- Checks whether a flags value contains the Control modifier.
---@param flags number
---@return boolean
function Data.IsControl(flags)
    return flags == Constants.ButtonFlags.Control
end

--- Checks whether a flags value contains the Alt modifier.
---@param flags number
---@return boolean
function Data.IsAlt(flags)
    return flags == Constants.ButtonFlags.Alt
end

-- ========================================================================== --
-- Data - Mouse
-- ========================================================================== --

---@class SystemData.Position
---@field x number
---@field y number

--- Returns the current mouse position.
---@return SystemData.Position
function Data.MousePosition()
    return SystemData.MousePosition
end

-- ========================================================================== --
-- Data - Mouse Over
-- ========================================================================== --

---@class SystemData.Window
---@field name string

--- Returns the name of the window currently under the mouse.
---@return string
function Data.MouseOverWindow()
    return SystemData.MouseOverWindow.name
end

-- ========================================================================== --
-- Data - Object
-- ========================================================================== --

---@class ObjectWrapper
---@field _id number
local Object = {}
Object.__index = Object

function Object:new(id)
    local instance = setmetatable({}, self)
    instance._id = id
    return instance
end

function Object:isValid()
    return Api.Object.IsValid(self._id)
end

function Object:isMobile()
    return Api.Object.IsMobile(self._id)
end

function Data.Object(id)
    return Object:new(id)
end

-- ========================================================================== --
-- Data - Object Handles
-- ========================================================================== --

---@class WindowData.ObjectHandle
---@field ObjectId integer[]
---@field Names string[]
---@field Notoriety integer[]
---@field IsMobile boolean[]

---@class ObjectHandle
---@field id integer
---@field name string
---@field isMobile boolean
---@field isValid fun(): boolean
---@field notoriety integer

---@class ObjectHandleDataWrapper
local ObjectHandles = {}
ObjectHandles.__index = ObjectHandles

function ObjectHandles:new()
    return setmetatable({}, self)
end

---@return WindowData.ObjectHandle
function ObjectHandles:getData()
    return WindowData.ObjectHandle
end

---@return table<number, ObjectHandle>
function ObjectHandles:getHandles()
    local windowData = self:getData()

    return Utils.Array.MapToTable(
        windowData.ObjectId,
        function(item)
            return item
        end,
        function(item, index)
            return {
                id = item,
                name = Utils.String.FromWString(windowData.Names[index]),
                notoriety = windowData.Notoriety[index],
                isMobile = windowData.IsMobile[index],
                isValid = function()
                    return Data.Object(item):isValid()
                        and Utils.Array.Find(windowData.ObjectId, function(id)
                            return id == item
                        end)
                end
            }
        end
    )
end

function ObjectHandles:getHandle(id)
    return self:getHandles()[id]
end

function Data.ObjectHandles()
    return ObjectHandles:new()
end

-- ========================================================================== --
-- Data - Player Location
-- ========================================================================== --

---@class WindowData.PlayerLocation
---@field x number
---@field y number
---@field z number
---@field facet number

---@class PlayerLocationWrapper
local PlayerLocation = {}
PlayerLocation.__index = PlayerLocation

function PlayerLocation:new()
    return setmetatable({}, self)
end

---@return WindowData.PlayerLocation
function PlayerLocation:getData()
    return WindowData.PlayerLocation
end

---@return number
function PlayerLocation:getX()
    return self:getData().x or 0
end

---@return number
function PlayerLocation:getY()
    return self:getData().y or 0
end

---@return number
function PlayerLocation:getZ()
    return self:getData().z or 0
end

---@return number
function PlayerLocation:getFacet()
    return self:getData().facet or 0
end

function Data.PlayerLocation()
    return PlayerLocation:new()
end

-- ========================================================================== --
-- Data - Player Status
-- ========================================================================== --

---@class WindowData.PlayerStatus
---@field StatCap number
---@field StamRegen number
---@field StatLock number[]
---@field Intelligence number
---@field IncreaseManaMax number
---@field InWarMode boolean
---@field Race number
---@field TithingPoints number
---@field Gold number
---@field EnhancePotions number
---@field IncreaseStamMax number
---@field ReflectPhysicalDamage number
---@field CurrentMana number
---@field IncreaseStr number
---@field IncreaseHitPointsMax number
---@field SwingSpeedIncrease number
---@field HitPointRegen number
---@field MaxPhysicalResist number
---@field Strength number
---@field MaxStamina number
---@field CurrentHealth number
---@field IncreaseMana number
---@field MaxEnergyResist number
---@field CurrentStamina number
---@field MaxWeight number
---@field DamageChangeIncrease number
---@field MaxHealth number
---@field PlayerId number
---@field MaxFollowers number
---@field LowerManaCost number
---@field MaxColdResist number
---@field FasterCastRecovery number
---@field SpellDamageIncrease number
---@field MaxDefenseChanceIncrease number
---@field IncreaseStam number
---@field IncreaseHitPoints number
---@field LowerReagentCost number
---@field ManaRegen number
---@field Luck number
---@field Weight number
---@field ColdResist number
---@field Followers number
---@field HitChanceIncrease number
---@field EnergyResist number
---@field MaxMana number
---@field PhysicalResist number
---@field MaxPoisonResist number
---@field MaxDamage number
---@field IncreaseInt number
---@field FasterCasting number
---@field MaxFireResist number
---@field IncreaseDex number
---@field DefenseChanceIncrease number
---@field VisualStateId number
---@field Dead number
---@field PoisonResist number
---@field Damage number
---@field FireResist number
---@field Dexterity number
---@field Type integer
---@field Event integer

---@class PlayerStatusWrapper
local PlayerStatus = {}
PlayerStatus.__index = PlayerStatus

function PlayerStatus:new()
    return setmetatable({}, self)
end

---@return WindowData.PlayerStatus
function PlayerStatus:getData()
    return WindowData.PlayerStatus or { PlayerId = 0 }
end

function PlayerStatus:getStatCap()
    return self:getData().StatCap or 0
end

function PlayerStatus:getCurrentMana()
    return self:getData().CurrentMana or 0
end

function PlayerStatus:getMaxMana()
    return self:getData().MaxMana or 0
end

function PlayerStatus:getCurrentHealth()
    return self:getData().CurrentHealth or 0
end

function PlayerStatus:getMaxHealth()
    return self:getData().MaxHealth or 0
end

function PlayerStatus:getCurrentStamina()
    return self:getData().CurrentStamina or 0
end

function PlayerStatus:getMaxStamina()
    return self:getData().MaxStamina or 0
end

function PlayerStatus:isInWarMode()
    return self:getData().InWarMode or false
end

function PlayerStatus:getId()
    return self:getData().PlayerId or 0
end

---@return integer
function PlayerStatus:getGold()
    return self:getData().Gold or 0
end

---@return integer
function PlayerStatus:getEvent()
    return self:getData().Event
end

---@return integer
function PlayerStatus:getType()
    return self:getData().Type
end

function Data.PlayerStatus()
    return PlayerStatus:new()
end

-- ========================================================================== --
-- Data - Paperdoll
-- ========================================================================== --

---@class PaperdollSlot
---@field slotId integer The object ID in this slot (0 if empty)
---@field slotTextureName string Texture name for the slot
---@field iconName string Texture name for the item icon
---@field newWidth number Width for the icon
---@field newHeight number Height for the icon
---@field iconScale number Scale factor for the icon
---@field hueId number Hue ID for the shader
---@field objectType number Object type for the shader
---@field hue table Table with r, g, b, a hue values

---@class PaperdollWrapper
local PaperdollData = {}
PaperdollData.__index = PaperdollData

function PaperdollData:new(id)
    return setmetatable({ _id = id }, self)
end

---@return table|nil
function PaperdollData:getData()
    if WindowData.Paperdoll then
        return WindowData.Paperdoll[self._id]
    end
    return nil
end

---@return integer
function PaperdollData:getId()
    return self._id
end

---@return integer
function PaperdollData:getNumSlots()
    local data = self:getData()
    if data then return data.numSlots or 0 end
    return 0
end

--- Gets the slot data for a given index.
---@param index integer Slot index (1-based)
---@return PaperdollSlot|nil
function PaperdollData:getSlot(index)
    local data = self:getData()
    if data then return data[index] end
    return nil
end

---@param id integer The paperdoll entity ID
---@return PaperdollWrapper
function Data.Paperdoll(id)
    return PaperdollData:new(id)
end

-- ========================================================================== --
-- Data - Paperdoll Texture
-- ========================================================================== --

---@class PaperdollTextureWrapper
---@field _id number
local PaperdollTexture = {}
PaperdollTexture.__index = PaperdollTexture

function PaperdollTexture:new(id)
    return setmetatable({ _id = id }, self)
end

---@return table|nil Raw SystemData.PaperdollTexture entry
function PaperdollTexture:getData()
    return SystemData.PaperdollTexture[self._id]
end

---@return boolean Whether texture data is available
function PaperdollTexture:hasData()
    return self:getData() ~= nil
end

---@return number Texture width (doubled for legacy textures)
function PaperdollTexture:getWidth()
    local data = self:getData()
    if not data then return 0 end
    local w = data.Width
    if data.IsLegacy == 1 then w = w * 2 end
    return w
end

---@return number Texture height (doubled for legacy textures)
function PaperdollTexture:getHeight()
    local data = self:getData()
    if not data then return 0 end
    local h = data.Height
    if data.IsLegacy == 1 then h = h * 2 end
    return h
end

---@return number X offset for anchoring
function PaperdollTexture:getXOffset()
    local data = self:getData()
    if not data then return 0 end
    return data.xOffset
end

---@return number Y offset for anchoring
function PaperdollTexture:getYOffset()
    local data = self:getData()
    if not data then return 0 end
    return data.yOffset
end

---@return boolean Whether this is a legacy texture
function PaperdollTexture:isLegacy()
    local data = self:getData()
    if not data then return false end
    return data.IsLegacy == 1
end

---@return string The engine texture name for this paperdoll
function PaperdollTexture:getTextureName()
    return "paperdoll_texture" .. self._id
end

---@param id number The mobile/player ID
---@return PaperdollTextureWrapper
function Data.PaperdollTexture(id)
    return PaperdollTexture:new(id)
end

-- ========================================================================== --
-- Data - Settings
-- ========================================================================== --

---@class SettingsWrapper
local SettingsData = {}
SettingsData.__index = SettingsData

function SettingsData:new()
    return setmetatable({}, self)
end

-- Resolution / Graphics
---@return boolean
function SettingsData:getUseFullScreen()    return SystemData.Settings.Resolution.useFullScreen end
function SettingsData:setUseFullScreen(v)   SystemData.Settings.Resolution.useFullScreen = v end

---@return number gamma value 0-1
function SettingsData:getGamma()            return SystemData.Settings.Resolution.gamma end
function SettingsData:setGamma(v)           SystemData.Settings.Resolution.gamma = v end

---@return boolean
function SettingsData:getShowShadows()      return SystemData.Settings.Resolution.showShadows end
function SettingsData:setShowShadows(v)     SystemData.Settings.Resolution.showShadows = v end

---@return boolean
function SettingsData:getEnableVSync()      return SystemData.Settings.Resolution.enableVSync end
function SettingsData:setEnableVSync(v)     SystemData.Settings.Resolution.enableVSync = v end

---@return boolean
function SettingsData:getShowWindowFrame()  return SystemData.Settings.Resolution.showWindowFrame end
function SettingsData:setShowWindowFrame(v) SystemData.Settings.Resolution.showWindowFrame = v end

---@return boolean
function SettingsData:getDisplayFoliage()   return SystemData.Settings.Resolution.displayFoliage end
function SettingsData:setDisplayFoliage(v)  SystemData.Settings.Resolution.displayFoliage = v end

---@return integer max framerate
function SettingsData:getFramerateMax()     return SystemData.Settings.Resolution.framerateMax end
function SettingsData:setFramerateMax(v)    SystemData.Settings.Resolution.framerateMax = v end

-- Sound
---@return boolean
function SettingsData:getMasterEnabled()    return SystemData.Settings.Sound.master.enabled end
function SettingsData:setMasterEnabled(v)   SystemData.Settings.Sound.master.enabled = v end

---@return integer 0-100
function SettingsData:getMasterVolume()     return SystemData.Settings.Sound.master.volume end
function SettingsData:setMasterVolume(v)    SystemData.Settings.Sound.master.volume = v end

---@return boolean
function SettingsData:getEffectsEnabled()   return SystemData.Settings.Sound.effects.enabled end
function SettingsData:setEffectsEnabled(v)  SystemData.Settings.Sound.effects.enabled = v end

---@return integer 0-100
function SettingsData:getEffectsVolume()    return SystemData.Settings.Sound.effects.volume end
function SettingsData:setEffectsVolume(v)   SystemData.Settings.Sound.effects.volume = v end

---@return boolean
function SettingsData:getMusicEnabled()     return SystemData.Settings.Sound.music.enabled end
function SettingsData:setMusicEnabled(v)    SystemData.Settings.Sound.music.enabled = v end

---@return integer 0-100
function SettingsData:getMusicVolume()      return SystemData.Settings.Sound.music.volume end
function SettingsData:setMusicVolume(v)     SystemData.Settings.Sound.music.volume = v end

---@return boolean
function SettingsData:getFootsteps()        return SystemData.Settings.Sound.footsteps.enabled end
function SettingsData:setFootsteps(v)       SystemData.Settings.Sound.footsteps.enabled = v end

-- GameOptions
---@return boolean
function SettingsData:getAlwaysRun()        return SystemData.Settings.GameOptions.alwaysRun end
function SettingsData:setAlwaysRun(v)       SystemData.Settings.GameOptions.alwaysRun = v end

---@return boolean
function SettingsData:getEnableAutorun()    return SystemData.Settings.GameOptions.enableAutorun end
function SettingsData:setEnableAutorun(v)   SystemData.Settings.GameOptions.enableAutorun = v end

---@return boolean
function SettingsData:getEnablePathfinding() return SystemData.Settings.GameOptions.enablePathfinding end
function SettingsData:setEnablePathfinding(v) SystemData.Settings.GameOptions.enablePathfinding = v end

---@return boolean
function SettingsData:getQueryBeforeCriminal() return SystemData.Settings.GameOptions.queryBeforeCriminalAction end
function SettingsData:setQueryBeforeCriminal(v) SystemData.Settings.GameOptions.queryBeforeCriminalAction = v end

---@return boolean
function SettingsData:getIgnoreMouseOnSelf() return SystemData.Settings.GameOptions.ignoreMouseActionsOnSelf end
function SettingsData:setIgnoreMouseOnSelf(v) SystemData.Settings.GameOptions.ignoreMouseActionsOnSelf = v end

---@return boolean
function SettingsData:getHoldShiftToUnstack() return SystemData.Settings.GameOptions.holdShiftToUnstack end
function SettingsData:setHoldShiftToUnstack(v) SystemData.Settings.GameOptions.holdShiftToUnstack = v end

---@return boolean
function SettingsData:getShiftRightClick()  return SystemData.Settings.GameOptions.shiftRightClickContextMenus end
function SettingsData:setShiftRightClick(v) SystemData.Settings.GameOptions.shiftRightClickContextMenus = v end

---@return boolean
function SettingsData:getTargetQueueing()   return SystemData.Settings.GameOptions.targetQueueing end
function SettingsData:setTargetQueueing(v)  SystemData.Settings.GameOptions.targetQueueing = v end

---@return boolean
function SettingsData:getAlwaysAttack()     return SystemData.Settings.GameOptions.alwaysAttack end
function SettingsData:setAlwaysAttack(v)    SystemData.Settings.GameOptions.alwaysAttack = v end

---@return boolean
function SettingsData:getShowCorpseNames()  return SystemData.Settings.GameOptions.showCorpseNames end
function SettingsData:setShowCorpseNames(v) SystemData.Settings.GameOptions.showCorpseNames = v end

---@return boolean
function SettingsData:getEnableChatLog()    return SystemData.Settings.GameOptions.enableChatLog end
function SettingsData:setEnableChatLog(v)   SystemData.Settings.GameOptions.enableChatLog = v end

---@return boolean
function SettingsData:getNoWarOnPets()      return SystemData.Settings.GameOptions.noWarOnPets end
function SettingsData:setNoWarOnPets(v)     SystemData.Settings.GameOptions.noWarOnPets = v end

---@return boolean
function SettingsData:getNoWarOnParty()     return SystemData.Settings.GameOptions.noWarOnParty end
function SettingsData:setNoWarOnParty(v)    SystemData.Settings.GameOptions.noWarOnParty = v end

---@return boolean
function SettingsData:getCircleOfTrans()    return SystemData.Settings.GameOptions.circleOfTransEnabled end
function SettingsData:setCircleOfTrans(v)   SystemData.Settings.GameOptions.circleOfTransEnabled = v end

---@return boolean
function SettingsData:getLegacyTargeting()  return SystemData.Settings.GameOptions.legacyTargeting end
function SettingsData:setLegacyTargeting(v) SystemData.Settings.GameOptions.legacyTargeting = v end

---@return boolean
function SettingsData:getShowStrLabel()     return SystemData.Settings.GameOptions.showStrLabel end
function SettingsData:setShowStrLabel(v)    SystemData.Settings.GameOptions.showStrLabel = v end

---@return integer show-names engine constant
function SettingsData:getShowNames()        return SystemData.Settings.GameOptions.showNames end
function SettingsData:setShowNames(v)       SystemData.Settings.GameOptions.showNames = v end

-- Interface
---@return boolean
function SettingsData:getShowTooltips()     return SystemData.Settings.Interface.showTooltips end
function SettingsData:setShowTooltips(v)    SystemData.Settings.Interface.showTooltips = v end

---@return boolean
function SettingsData:getOverheadChat()     return SystemData.Settings.Interface.OverheadChat end
function SettingsData:setOverheadChat(v)    SystemData.Settings.Interface.OverheadChat = v end

---@return integer 1-5 seconds
function SettingsData:getOverheadChatFadeDelay() return SystemData.Settings.Interface.OverheadChatFadeDelay end
function SettingsData:setOverheadChatFadeDelay(v) SystemData.Settings.Interface.OverheadChatFadeDelay = v end

---@return boolean
function SettingsData:getPartyInvitePopUp() return SystemData.Settings.Interface.partyInvitePopUp end
function SettingsData:setPartyInvitePopUp(v) SystemData.Settings.Interface.partyInvitePopUp = v end

---@return boolean
function SettingsData:getLegacyContainers() return SystemData.Settings.Interface.LegacyContainers end
function SettingsData:setLegacyContainers(v) SystemData.Settings.Interface.LegacyContainers = v end

---@return boolean
function SettingsData:getLegacyPaperdolls() return SystemData.Settings.Interface.LegacyPaperdolls end
function SettingsData:setLegacyPaperdolls(v) SystemData.Settings.Interface.LegacyPaperdolls = v end

---@return boolean
function SettingsData:getLegacyChat()       return SystemData.Settings.Interface.LegacyChat end
function SettingsData:setLegacyChat(v)      SystemData.Settings.Interface.LegacyChat = v end

---@return number scale 0.5-2.0
function SettingsData:getCustomUiScale()    return SystemData.Settings.Interface.customUiScale end
function SettingsData:setCustomUiScale(v)   SystemData.Settings.Interface.customUiScale = v end

-- Profanity
---@return boolean
function SettingsData:getBadWordFilter()    return SystemData.Settings.Profanity.BadWordFilter end
function SettingsData:setBadWordFilter(v)   SystemData.Settings.Profanity.BadWordFilter = v end

---@return boolean
function SettingsData:getIgnoreListFilter() return SystemData.Settings.Profanity.IgnoreListFilter end
function SettingsData:setIgnoreListFilter(v) SystemData.Settings.Profanity.IgnoreListFilter = v end

---@return boolean
function SettingsData:getIgnoreConfFilter() return SystemData.Settings.Profanity.IgnoreConfListFilter end
function SettingsData:setIgnoreConfFilter(v) SystemData.Settings.Profanity.IgnoreConfListFilter = v end

-- Optimization
---@return boolean
function SettingsData:getIdleAnimation()    return SystemData.Settings.Optimization.idleAnimation end
function SettingsData:setIdleAnimation(v)   SystemData.Settings.Optimization.idleAnimation = v end

---@return SettingsWrapper
function Data.Settings()
    return SettingsData:new()
end

-- ========================================================================== --
-- Data - Radar
-- Data - ShopData
-- ========================================================================== --

---@class WindowData.ShopData.SellList
---@field Names wstring[]
---@field Quantities integer[]
---@field Ids integer[]
---@field Prices integer[]
---@field Types integer[]

---@class WindowData.ShopData
---@field IsSelling boolean
---@field Sell WindowData.ShopData.SellList
---@field OfferIds integer[]
---@field OfferQuantities integer[]
---@field Type integer
---@field Event integer

---@class ShopDataItem
---@field id integer Object ID of the item
---@field name wstring Display name of the item
---@field price integer Gold price per unit
---@field quantity integer Available quantity
---@field objType integer Object type for icon rendering

---@class ShopDataWrapper
local ShopData = {}
ShopData.__index = ShopData

---@return ShopDataWrapper
function ShopData:new()
    local instance = setmetatable({}, self)
    return instance
end

---@return boolean
function ShopData:isSelling()
    return WindowData.ShopData and WindowData.ShopData.IsSelling == true
end

---@return integer Number of sell items
function ShopData:getSellCount()
    if not WindowData.ShopData or not WindowData.ShopData.Sell then
        return 0
    end
    return table.getn(WindowData.ShopData.Sell.Names)
end

---@param index integer 1-based index
---@return ShopDataItem|nil
function ShopData:getSellItem(index)
    local sell = WindowData.ShopData and WindowData.ShopData.Sell
    if not sell then return nil end
    if sell.Quantities[index] == 0 then return nil end
    return {
        id       = sell.Ids[index],
        name     = sell.Names[index],
        price    = sell.Prices[index],
        quantity = sell.Quantities[index],
        objType  = sell.Types[index]
    }
end

--- Returns all sell items as an array, skipping entries with zero quantity.
---@return ShopDataItem[]
function ShopData:getSellItems()
    local result = {}
    local count = self:getSellCount()
    for i = 1, count do
        local entry = self:getSellItem(i)
        if entry then
            table.insert(result, entry)
        end
    end
    return result
end

---@param offerIds integer[]
---@param offerQuantities integer[]
function ShopData:setOffer(offerIds, offerQuantities)
    if not WindowData.ShopData then return end
    for i = 1, table.getn(offerIds) do
        WindowData.ShopData.OfferIds[i] = offerIds[i]
        WindowData.ShopData.OfferQuantities[i] = offerQuantities[i]
    end
end

---@return ShopDataWrapper
function Data.ShopData()
    return ShopData:new()
end

-- ========================================================================== --
-- Data - ObjectInfo
-- ========================================================================== --

---@class WindowData.ObjectInfo
---@field name wstring Display name of the object
---@field objectType integer Numeric type ID of the object
---@field shopValue integer Gold price per unit (shop context)
---@field shopQuantity integer Available quantity in shop
---@field sellContainerId integer Container ID for buy mode
---@field quantity integer Quantity of the item
---@field containerId integer Parent container's object ID
---@field hueId integer Hue/color ID
---@field Type integer
---@field Event integer

---@class ObjectInfoWrapper
local ObjectInfoData = {}
ObjectInfoData.__index = ObjectInfoData

---@param id integer The object ID
---@return ObjectInfoWrapper
function ObjectInfoData:new(id)
    return setmetatable({ _id = id }, self)
end

---@return WindowData.ObjectInfo|nil
function ObjectInfoData:getData()
    if WindowData.ObjectInfo then
        return WindowData.ObjectInfo[self._id]
    end
    return nil
end

--- Returns true if the engine has ObjectInfo data for this ID.
---@return boolean
function ObjectInfoData:exists()
    return self:getData() ~= nil
end

--- Returns the object ID this wrapper was created for.
---@return integer
function ObjectInfoData:getId()
    return self._id
end

--- Returns the display name of the object.
---@return wstring
function ObjectInfoData:getName()
    local data = self:getData()
    return data and data.name or L""
end

--- Returns the numeric type ID of the object.
---@return integer
function ObjectInfoData:getObjectType()
    local data = self:getData()
    return data and data.objectType or 0
end

--- Returns the gold price per unit (shop context).
---@return integer
function ObjectInfoData:getShopValue()
    local data = self:getData()
    return data and data.shopValue or 0
end

--- Returns the available quantity in shop.
---@return integer
function ObjectInfoData:getShopQuantity()
    local data = self:getData()
    return data and data.shopQuantity or 0
end

--- Returns the container ID for buy mode.
---@return integer
function ObjectInfoData:getSellContainerId()
    local data = self:getData()
    return data and data.sellContainerId or 0
end

--- Returns the quantity of the item.
---@return integer
function ObjectInfoData:getQuantity()
    local data = self:getData()
    return data and data.quantity or 0
end

--- Returns the parent container's object ID.
---@return integer
function ObjectInfoData:getContainerId()
    local data = self:getData()
    return data and data.containerId or 0
end

--- Returns the hue/color ID.
---@return integer
function ObjectInfoData:getHueId()
    local data = self:getData()
    return data and data.hueId or 0
end

--- Returns ObjectInfo data wrapped for the given object ID.
---@param id integer The object ID.
---@return ObjectInfoWrapper
function Data.ObjectInfo(id)
    return ObjectInfoData:new(id)
end

-- ========================================================================== --
-- Data - ContainerWindow
-- ========================================================================== --

---
--- Returns raw ContainerWindow data for the given container ID.
---@param id integer The container ID.
---@return WindowData.Container|nil
function Data.ContainerWindow(id)
    return WindowData.ContainerWindow and WindowData.ContainerWindow[id] or nil
end

-- ========================================================================== --
-- Data - ItemProperties
-- ========================================================================== --

---
--- Returns raw ItemProperties data for the given object ID.
---@param id integer The object ID.
---@return table|nil
function Data.ItemProperties(id)
    return WindowData.ItemProperties and WindowData.ItemProperties[id] or nil
end
---@field TexCoordX integer
---@field TexCoordY integer
---@field TexScale number


-- ========================================================================== --
-- Components
-- ========================================================================== --

local Active = {}

function Active.window()
    return SystemData.ActiveWindow.name
end

Components.Defaults = {}

local EventHandler = {}

---@type table<string, View>
local Cache = {}

--- Module-level resize tracking
---@type Window?
local resizingWindow = nil
---@type { startMouseX: number, startMouseY: number, startWidth: number, startHeight: number, minWidth: number, minHeight: number }?
local resizeState = nil
--- The original OnUpdate handler saved before resize injected its own
---@type fun(self: Window, timePassed: integer)?
local resizeOriginalOnUpdate = nil
--- Whether we dynamically registered OnUpdate (it wasn't already present)
local resizeRegisteredOnUpdate = false

--- Window snapping: registry of snappable window names for edge detection
---@type table<string, boolean>
local SnappableWindows = {}
local SNAP_THRESHOLD = 20

---@class ButtonModel : WindowModel
---@field OnInitialize fun(self: Button)?
---@field OnLButtonUp fun(self: Button, flags: integer, x: integer, y: integer)?
---@field OnMouseOver fun(self: Button)?
---@field OnMouseOverEnd fun(self: Button)?

---@class Button: Window
local Button = {}
Button.__index = Button

---@class CheckBoxModel : ViewModel
---@field OnInitialize fun(self: CheckBox)?
---@field OnShutdown fun(self: CheckBox)?
---@field OnLButtonUp fun(self: CheckBox, flags: integer, x: integer, y: integer)?
---@field OnMouseOver fun(self: CheckBox)?
---@field OnMouseOverEnd fun(self: CheckBox)?

---@class CheckBox: View
---@field label Label?
local CheckBox = {}
CheckBox.__index = CheckBox

---@class ComboBoxModel : ViewModel
---@field OnInitialize fun(self: ComboBox)?
---@field OnShutdown fun(self: ComboBox)?
---@field OnSelChanged fun(self: ComboBox)?

---@class ComboBox: View
local ComboBox = {}
ComboBox.__index = ComboBox

---@class ListBoxModel : ViewModel]
---@field OnInitialize fun(self: ListBox)?
---@field OnShutdown fun(self: ListBox)?
---@field OnMouseWheel fun(self: ListBox, x: number, y: number, delta: number)?
---@field OnMouseOver fun(self: ListBox)?
---@field OnMouseOverEnd fun(self: ListBox)?
---@field OnLButtonDown fun(self: ListBox, flags: integer, x: integer, y: integer)?
---@field OnLButtonUp fun(self: ListBox, flags: integer, x: integer, y: integer)?
---@field OnPopulateRow fun(self: ListBox)?

---@class ListBox: View
local ListBox = {}
ListBox.__index = ListBox

---@class SliderBarModel : ViewModel
---@field OnInitialize fun(self: SliderBar)?
---@field OnShutdown fun(self: SliderBar)?
---@field OnSlide fun(self: SliderBar, position: number)?

---@class SliderBar: View
local SliderBar = {}
SliderBar.__index = SliderBar

---@class AnimatedImageModel : ViewModel
---@field OnInitialize fun(self: AnimatedImage)?
---@field OnShutdown fun(self: AnimatedImage)?

---@class AnimatedImage: View
local AnimatedImage = {}
AnimatedImage.__index = AnimatedImage

---@class ActionButtonModel : ViewModel
---@field OnInitialize fun(self: ActionButton)?
---@field OnShutdown fun(self: ActionButton)?
---@field OnLButtonDown fun(self: ActionButton, flags: integer, x: integer, y: integer)?
---@field OnLButtonUp fun(self: ActionButton, flags: integer, x: integer, y: integer)?
---@field OnRButtonUp fun(self: ActionButton, flags: integer, x: integer, y: integer)?
---@field OnMouseOver fun(self: ActionButton)?
---@field OnMouseOverEnd fun(self: ActionButton)?

---@class ActionButton: Button
local ActionButton = {}
ActionButton.__index = ActionButton

---@class ActionButtonGroupModel : WindowModel
---@field Count number? The number of action button slots (default 12).
---@field ButtonSize number? The pixel size of each button (default 50).
---@field Spacing number? The pixel gap between buttons (default 0).
---@field OnInitialize fun(self: ActionButtonGroup)?
---@field OnShutdown fun(self: ActionButtonGroup)?
---@field OnButtonLButtonDown fun(self: ActionButtonGroup, button: ActionButton, index: number, flags: integer, x: integer, y: integer)?
---@field OnButtonLButtonUp fun(self: ActionButtonGroup, button: ActionButton, index: number, flags: integer, x: integer, y: integer)?
---@field OnButtonRButtonUp fun(self: ActionButtonGroup, button: ActionButton, index: number, flags: integer, x: integer, y: integer)?
---@field OnButtonMouseOver fun(self: ActionButtonGroup, button: ActionButton, index: number)?
---@field OnButtonMouseOverEnd fun(self: ActionButtonGroup, button: ActionButton, index: number)?

---@class ActionButtonGroup: Window
---@field _buttons ActionButton[] The group's action button slots.
local ActionButtonGroup = {}
ActionButtonGroup.__index = ActionButtonGroup

---@class CooldownDisplayModel : ViewModel
---@field OnInitialize fun(self: CooldownDisplay)?
---@field OnShutdown fun(self: CooldownDisplay)?

---@class CooldownDisplay: AnimatedImage
local CooldownDisplay = {}
CooldownDisplay.__index = CooldownDisplay

---@class DockableWindowModel : WindowModel
---@field OnInitialize fun(self: DockableWindow)?
---@field OnShutdown fun(self: DockableWindow)?

---@class DockableWindow: Window
local DockableWindow = {}
DockableWindow.__index = DockableWindow

---@class PageWindowModel : ViewModel
---@field OnInitialize fun(self: PageWindow)?
---@field OnShutdown fun(self: PageWindow)?

---@class PageWindow: View
local PageWindow = {}
PageWindow.__index = PageWindow

---@class DefaultComponentProxy
---@field _disabled boolean Whether the proxy is disabled (function calls become no-ops)
---@field _original table The original global table being proxied

---@class DefaultComponent : Component
---@field _proxy DefaultComponentProxy? The metatable proxy wrapping the original global
local DefaultComponent = {}
DefaultComponent.__index = DefaultComponent

--- @class DefaultActions
--- @field WarMode integer
--- @field nxt integer
--- @field MassOrganize boolean
--- @field VacuumObjects table|nil
--- @field AutoLoadShurikens boolean
--- @field BeltMenuRequest any
--- @field Nextshuri number
--- @field DefaultRecordID integer|nil
--- @field itemQuantities table|nil
--- @field AllItems table|nil
--- @field Undress boolean|nil
--- @field OrganizeBag integer|nil
--- @field OrganizeParent integer|nil
--- @field UndressItems table|nil
--- @field ToggleMainMenu fun()
--- @field ToggleWarMode fun()
--- @field ToggleInventoryWindow fun()
--- @field ToggleMapWindow fun()
--- @field ToggleGuildWindow fun()
--- @field ToggleChatWindow fun()
--- @field ToggleSkillsWindow fun()
--- @field ToggleVirtuesWindow fun()
--- @field ToggleQuestWindow fun()
--- @field ToggleHelpWindow fun()
--- @field ToggleUOStoreWindow fun()
--- @field TogglePaperdollWindow fun()
--- @field ToggleFoliage fun()
--- @field ToggleSound fun()
--- @field ToggleSoundEffects fun()
--- @field ToggleMusic fun()
--- @field ToggleFootsteps fun()
--- @field ToggleCharacterSheet fun(noloyalty:any)
--- @field ToggleCharacterAbilities fun()
--- @field IgnorePlayer fun()
--- @field Ignore fun()
--- @field ToggleUserSettings fun()
--- @field ToggleActions fun()
--- @field ToggleMacros fun()
--- @field PrevTarget fun()
--- @field SearchValidPrevTarget fun():table|nil
--- @field NextTarget fun()
--- @field TargetAllowed fun(mobileId:integer):boolean
--- @field IsMobileVisible fun(mobileId:integer):boolean
--- @field NearTarget fun()
--- @field InjuredFollower fun()
--- @field InjuredParty fun()
--- @field InjuredMobile fun()
--- @field TargetFirstContainerObject fun()
--- @field TargetType fun()
--- @field TypeRequestTargetInfoReceived fun()
--- @field TargetByType fun(type:integer, hue:integer)
--- @field ScanQuantities fun()
--- @field ScanSubCont fun(id:integer):boolean
--- @field TargetDefaultPet fun(id:integer)
--- @field SetDefaultPet fun()
--- @field TargetDefaultItem fun(id:integer)
--- @field SetDefaultItem fun()
--- @field TargetPetball fun()
--- @field PetballRequestTargetInfoReceived fun()
--- @field TargetMount fun()
--- @field MountRequestTargetInfoReceived fun()
--- @field ToggleLegacyContainers fun()
--- @field IgnoreActionSelf fun()
--- @field EnablePVPWarning fun()
--- @field ReleaseCoownership fun()
--- @field LeaveHouse fun()
--- @field QuestConversation fun()
--- @field ViewQuestLog fun()
--- @field CancelQuest fun()
--- @field QuestItem fun()
--- @field InsuranceMenu fun()
--- @field ToggleItemInsurance fun()
--- @field TitlesMenu fun()
--- @field LoyaltyRating fun()
--- @field CancelProtection fun()
--- @field VoidPool fun()
--- @field ToggleTrades fun()
--- @field SiegeBlessItem fun()
--- @field ExportContainerItems fun()
--- @field RequestContItems fun()
--- @field ToggleEnglishNames fun()
--- @field CloseAllContainers fun()
--- @field CloseAllCorpses fun()
--- @field MassOrganizerStart fun()
--- @field MassOrganizer fun(timePassed:number)
--- @field LoadShuri fun()
--- @field Shuriken fun(timePassed:number)
--- @field AutoLoadShuri fun()
--- @field DressHolding fun()
--- @field DropHolding fun()
--- @field ToggleTrapBox fun()
--- @field TrapboxTargetReceived fun()
--- @field ToggleLootbag fun()
--- @field LootbagTargetReceived fun()
--- @field ToggleAlphaMode fun()
--- @field ToggleScaleMode fun()
--- @field ObjectHandleContextMenu fun()
--- @field ObjectHandleContextMenuCallback fun(returnCode:any, param:any)
--- @field ObjectHandleSetFilter fun(j:integer, newval:any)
--- @field GetHealthbar fun()
--- @field GetTypeID fun()
--- @field ItemIDRequestTargetInfoReceived fun()
--- @field GetHueID fun()
--- @field ColorRequestTargetInfoReceived fun()
--- @field IgnoreTargettedItem fun()
--- @field IgnoreItemRequestTargetInfoReceived fun()
--- @field ClearIgnoreList fun()
--- @field ToggleBlockPaperdolls fun()
--- @field UndressMe fun()
--- @field UndressTargetInfoReceived fun()
--- @field UndressAgent fun(timePassed:number)
--- @field ImbueLast fun()
--- @field UnravelItem fun()
--- @field EnhanceItem fun()
--- @field SmeltItem fun()
--- @field AlterItem fun()
--- @field MakeLast fun()
--- @field RepairItem fun()

---@class DefaultActionsComponent : DefaultComponent
local DefaultActionsComponent = {}
DefaultActionsComponent.__index = DefaultActionsComponent

---@class DefaultInterfaceComponent : DefaultComponent
local DefaultInterfaceComponent = {}
DefaultInterfaceComponent.__index = DefaultInterfaceComponent

--- @class DefaultStatusWindow
--- @field CurPlayerId integer
--- @field Skills table
--- @field Notoriety table
--- @field TextColors table
--- @field Locked boolean
--- @field HPLocked boolean
--- @field MANALocked boolean
--- @field STAMLocked boolean
--- @field DisableDelta number
--- @field TempDisabled boolean
--- @field TCToolsHandle boolean
--- @field MPHeight integer
--- @field MPWidth integer
--- @field LastMPHeight integer
--- @field HPHeight integer
--- @field HPWidth integer
--- @field LastHPHeight integer
--- @field Initialize fun(reinit:any)
--- @field Shutdown fun()
--- @field Latency_OnMouseOver fun()
--- @field LockTooltip fun()
--- @field Lock fun()
--- @field LockTooltipHP fun()
--- @field LockHP fun()
--- @field LockTooltipMANA fun()
--- @field LockMANA fun()
--- @field LockTooltipSTAM fun()
--- @field LockSTAM fun()
--- @field MenuTooltip fun()
--- @field Menu fun()
--- @field UpdateLatency fun()
--- @field ClickOutside fun()
--- @field EnableInput fun(timePassed:number)
--- @field UpdateStatus fun()
--- @field OnLButtonUp fun()
--- @field OnLButtonDown fun()
--- @field OnHPLButtonUp fun()
--- @field OnHPLButtonDown fun()
--- @field OnMLANAButtonUp fun()
--- @field OnMANALButtonDown fun()
--- @field OnSTAMLButtonUp fun()
--- @field OnSTAMLButtonDown fun()
--- @field GuardsButton_OnLButtonUp fun()
--- @field GuardsButton_OnMouseOver fun()
--- @field OnRButtonUp fun()
--- @field UpdateLabelContent fun()
--- @field OnMouseOver fun()
--- @field OnMouseOverEnd fun()
--- @field ToggleStrLabel fun()
--- @field OnMouseDlbClk fun()
--- @field TCTools fun()
--- @field TCContextMenuCallback fun(returnCode:any, param:any)
--- @field EditSkill fun(id:any, value:any, max:any, min:any)
--- @field EditStr fun(id:any, value:any, max:any, min:any)
--- @field TCToolsTooltip fun()
--- @field TCToolsOver fun()
--- @field TCToolsOnLButtonDown fun()
--- @field TCToolsOverend fun()
--- @field SetMana fun(current:number, maximum:number)
--- @field SetHealth fun(current:number, maximum:number)
--- @field ChangeStyle fun(style:any)
--- @field ToggleButtons fun()

---@class DefaultStatusWindowComponent : DefaultComponent
local DefaultStatusWindowComponent = {}
DefaultStatusWindowComponent.__index = DefaultStatusWindowComponent

---@class DefaultWarShield

---@class DefaultWarShieldComponent : DefaultComponent
local DefaultWarShieldComponent = {}
DefaultWarShieldComponent.__index = DefaultWarShieldComponent

---@class DefaultPaperdollWindow
---@field Initialize fun()
---@field Shutdown fun()
---@field UpdatePaperdoll fun(windowName: string, paperdollId: integer)
---@field HandleUpdatePaperdollEvent fun()

---@class DefaultPaperdollWindowComponent : DefaultComponent
local DefaultPaperdollWindowComponent = {}
DefaultPaperdollWindowComponent.__index = DefaultPaperdollWindowComponent

---@class DefaultObjectHandle
---@field CreateObjectHandles fun()
---@field DestroyObjectHandles fun()

---@class DefaultObjectHandleComponent : DefaultComponent
local DefaultObjectHandleComponent = {}
DefaultObjectHandleComponent.__index = DefaultObjectHandleComponent

---@class DefaultSettingsWindow
---@field Initialize fun()
---@field Shutdown fun()
---@field ToggleSettingsWindow fun()

---@class DefaultSettingsWindowComponent : DefaultComponent
local DefaultSettingsWindowComponent = {}
DefaultSettingsWindowComponent.__index = DefaultSettingsWindowComponent

---@class DefaultShopkeeper
---@field Initialize fun()
---@field Shutdown fun()

local DefaultShopkeeperComponent = {}
DefaultShopkeeperComponent.__index = DefaultShopkeeperComponent


---@class CircleImageModel : ViewModel
---@field OnInitialize fun(self: CircleImage)?
---@field OnShutdown fun(self: CircleImage)?
---@field OnUpdate fun(self: CircleImage, timePassed: integer)?
---@field OnUpdateRadar fun(self: CircleImage, data: WindowData.Radar)?

---@class CircleImage : View
local CircleImage = {}
CircleImage.__index = CircleImage

---@class Component
---@field name string
local Component = {}
Component.__index = Component

---@class DynamicImageModel : ViewModel
---@field OnInitialize fun(self: DynamicImage)?
---@field OnShutdown fun(self: DynamicImage)?
---@field OnUpdate fun(self: DynamicImage, timePassed: integer)?
---@field OnLButtonUp fun(self: DynamicImage, flags: integer, x: integer, y: integer)?
---@field OnLButtonDown fun(self: DynamicImage, flags: integer, x: integer, y: integer)?
---@field OnLButtonDblClk fun(self: DynamicImage, flags: integer, x: integer, y: integer)?
---@field OnMouseOver fun(self: DynamicImage)?
---@field OnMouseOverEnd fun(self: DynamicImage)?
---@field OnMouseWheel fun(self: DynamicImage, x: number, y: number, delta: number)?
---@field OnUpdateRadar fun(self: DynamicImage, data: WindowData.Radar)?
---@field OnUpdatePlayerLocation fun(self: DynamicImage, data: WindowData.PlayerLocation)?
---@field OnUpdatePaperdoll fun(self: DynamicImage, paperdoll: PaperdollWrapper)?

---@class DynamicImage: View
local DynamicImage = {}
DynamicImage.__index = DynamicImage

---@class EditTextBoxModel : ViewModel
---@field OnInitialize fun(self: EditTextBox)?
---@field OnShutdown fun(self: EditTextBox)?
---@field OnTextChanged fun(self: EditTextBox, text: wstring)?
---@field OnKeyEnter fun(self: EditTextBox)?
---@field OnKeyEscape fun(self: EditTextBox)?

---@class EditTextBox: View
local EditTextBox = {}
EditTextBox.__index = EditTextBox

---@class FilterInputModel : EditTextBoxModel
---@field OnInitialize fun(self: FilterInput)?
---@field OnShutdown fun(self: FilterInput)?
---@field OnTextChanged fun(self: FilterInput, text: wstring)?
---@field OnKeyEnter fun(self: FilterInput)?
---@field OnKeyEscape fun(self: FilterInput)?

---@class FilterInput: EditTextBox
local FilterInput = {}
FilterInput.__index = FilterInput



---@class WindowModel : ViewModel
---@field Name string? The name of the window. If not provided, a random name will be generated.
---@field Id integer?
---@field Template string? The template to use for the window. Defaults to "MongbatWindow"
---@field OnInitialize fun(self: Window)?
---@field OnShutdown fun(self: Window)?
---@field OnUpdate fun(self: Window, timePassed: integer)?
---@field OnShown fun(self: Window)?
---@field OnHidden fun(self: Window)?
---@field OnLButtonUp fun(self: Window, flags: integer, x: integer, y: integer)?
---@field OnLButtonDown fun(self: Window, flags: integer, x: integer, y: integer)?
---@field OnRButtonUp fun(self: Window, flags: integer, x: integer, y: integer)?
---@field OnLButtonDblClk fun(self: Window, flags: integer, x: integer, y: integer)?
---@field OnMouseOver fun(self: Window)?
---@field OnMouseOverEnd fun(self: Window)?
---@field OnMouseWheel fun(self: Window, x: number, y: number, delta: number)?
---@field OnEndHealthBarDrag fun(self: Window)?
---@field OnUpdatePlayerStatus fun(self: Window, playerStatus: PlayerStatusWrapper)?
---@field OnUpdateMobileName fun(self: Window, mobileName: MobileNameWrapper)?
---@field OnUpdateHealthBarColor fun(self: Window, healthBarColor: HealthBarColorWrapper)?
---@field OnUpdateMobileStatus fun(self: Window, mobileStatus: MobileStatusWrapper)?
---@field OnUpdateRadar fun(self: Window, data: WindowData.Radar)?
---@field OnUpdatePlayerLocation fun(self: Window, data: WindowData.PlayerLocation)?
---@field OnUpdatePaperdoll fun(self: Window, paperdoll: PaperdollWrapper)?
---@field OnUpdateShopData fun(self: Window, shopData: ShopDataWrapper)?
---@field OnUpdateContainerWindow fun(self: Window, instanceId: integer, data: WindowData.Container|nil)?
---@field OnUpdateObjectInfo fun(self: Window, instanceId: integer, data: ObjectInfoWrapper)?
---@field OnUpdateItemProperties fun(self: Window, instanceId: integer, data: table|nil)?
---@field OnLayout fun(self: Window, children: View[], child: View, index: integer)?

---@class LabelModel : ViewModel
---@field OnInitialize fun(self: Label)?
---@field OnShutdown fun(self: Label)?
---@field OnUpdate fun(self: Label, timePassed: integer)?
---@field OnLButtonUp fun(self: Label, flags: integer, x: integer, y: integer)?
---@field OnMouseOver fun(self: Label)?
---@field OnMouseOverEnd fun(self: Label)?
---@field OnUpdatePlayerStatus fun(self: Label, playerStatus: PlayerStatusWrapper)?
---@field OnUpdateMobileName fun(self: Label, mobileName: MobileNameWrapper)?
---@field OnUpdateHealthBarColor fun(self: Label, healthBarColor: HealthBarColorWrapper)?
---@field OnUpdateMobileStatus fun(self: Label, mobileStatus: MobileStatusWrapper)?
---@field OnUpdateRadar fun(self: Label, data: WindowData.Radar)?
---@field OnUpdatePlayerLocation fun(self: Label, data: WindowData.PlayerLocation)?

---@class GumpItem
---@field tid integer
---@field windowName string
---@field id integer

---@class GumpWModel : ScaffoldModel
---@field windowName string
---@field TextEntry string[]?
---@field Labels GumpItem[]?
---@field Images string[]?
---@field Buttons string[]?
---@field OnInitialize fun(self: Gump)?
---@field OnShutdown fun(self: Gump)?

---@class Gump : Scaffold
---@field buttons Button[]
---@field textEntries EditTextBox[]
---@field _id integer The unique ID of the gump window.
local Gump = {}
Gump.__index = Gump

---@class Label: View
local Label = {}
Label.__index = Label

---@class LogDisplayModel : ViewModel
---@field OnInitialize fun(self: LogDisplay)?
---@field OnShutdown fun(self: LogDisplay)?

---@class LogDisplay: View
local LogDisplay = {}
LogDisplay.__index = LogDisplay

---@class ViewModel
---@field Name string?
---@field Template string?
---@field Id integer?
---@field OnInitialize fun(self: View)?
---@field OnLButtonUp fun(self: View, flags: integer, x: integer, y: integer)?
---@field OnRButtonUp fun(self: View, flags: integer, x: integer, y: integer)?
---@field OnShutdown fun(self: View)?
---@field OnHidden fun(self: View)?
---@field OnShown fun(self: View)?
---@field OnLButtonDown fun(self: View, flags: integer, x: integer, y: integer)?
---@field OnRButtonDown fun(self: View, flags: integer, x: integer, y: integer)?
---@field OnUpdate fun(self: View, timePassed: integer)?
---@field OnLButtonDblClk fun(self: View, flags: integer, x: integer, y: integer)?
---@field OnMouseOver fun(self: View)?
---@field OnMouseOverEnd fun(self: View)?
---@field OnEndHealthBarDrag fun(self: View)?
---@field OnUpdatePlayerStatus fun(self: View, playerStatus: PlayerStatusWrapper)?
---@field OnUpdateMobileName fun(self: View, mobileName: MobileNameWrapper)?
---@field OnUpdateHealthBarColor fun(self: View, healthBarColor: HealthBarColorWrapper)?
---@field OnUpdateMobileStatus fun(self: View, mobileStatus: MobileStatusWrapper)?
---@field OnUpdateRadar fun(self: View, data: WindowData.Radar)?
---@field OnUpdatePlayerLocation fun(self: View, data: WindowData.PlayerLocation)?
---@field OnUpdatePaperdoll fun(self: View, paperdoll: PaperdollWrapper)?
---@field OnUpdateShopData fun(self: View, shopData: ShopDataWrapper)?
---@field OnMouseWheel fun(self: View, x: number, y: number, delta: number)?

---@class StatusBarModel : ViewModel
---@field OnInitialize fun(self: StatusBar)?
---@field OnShutdown fun(self: StatusBar)?
---@field OnUpdate fun(self: StatusBar, timePassed: integer)?
---@field OnLButtonUp fun(self: StatusBar, flags: integer, x: integer, y: integer)?
---@field OnLButtonDblClk fun(self: StatusBar, flags: integer, x: integer, y: integer)?
---@field OnMouseOver fun(self: StatusBar)?
---@field OnMouseOverEnd fun(self: StatusBar)?
---@field OnUpdatePlayerStatus fun(self: StatusBar, playerStatus: PlayerStatusWrapper)?
---@field OnUpdateMobileStatus fun(self: StatusBar, mobileStatus: MobileStatusWrapper)?
---@field OnUpdateHealthBarColor fun(self: StatusBar, healthBarColor: HealthBarColorWrapper)?

---@class ScrollWindowModel : WindowModel
---@field ItemHeight number? Height per item row used for vertical stacking and content container sizing. Defaults to 50.
---@field ItemWidth number? Width per item column used for horizontal stacking (only when Horizontal is true). Defaults to 50.
---@field Horizontal boolean? When true, the scroll window scrolls horizontally instead of vertically. Defaults to false.
---@field OnInitialize fun(self: ScrollWindow)?
---@field OnShutdown fun(self: ScrollWindow)?

---@class ScrollWindow : Window
---@field _items View[] Views added as rows into the scroll content area.
local ScrollWindow = {}
ScrollWindow.__index = ScrollWindow

---@class StatusBar: View
---@field label Label?
local StatusBar = {}
StatusBar.__index = StatusBar

---@class View : Component
---@field _model ViewModel
local View = {}
View.__index = View

---@class Window : View
---@field _model WindowModel?
---@field _children Window[] A list of child windows.
---@field _frame string The name of the window's frame component.
---@field _background string The name of the window's background component.
---@field _startDrag SystemData.Position x, y coordinates for tracking how far the window was dragged
---@field _endDrag SystemData.Position x, y coordinates for tracking how far the window was dragged
local Window = {}
Window.__index = Window

---@class ScaffoldModel : WindowModel
---@field Resizable boolean? Whether the window can be resized by dragging the corner grip. Defaults to true.
---@field Snappable boolean? Whether the window snaps to edges of other windows and the screen. Defaults to true.
---@field MinWidth number? Minimum width when resizing. Defaults to 100.
---@field MinHeight number? Minimum height when resizing. Defaults to 100.

---@class Scaffold : Window
---@field _model ScaffoldModel?
local Scaffold = {}
Scaffold.__index = Scaffold

-- ========================================================================== --
-- Components - Internal Builders
-- ========================================================================== --

-- ========================================================================== --
-- Components - Internal Builders - Layer Builder
-- ========================================================================== --

---@class LayerBuilder
---@field _getView fun(): View
local LayerBuilder = {}
LayerBuilder.__index = LayerBuilder

---@param getView fun(): View
---@return LayerBuilder
function LayerBuilder:new(getView)
    local instance = setmetatable({}, self)
    instance._getView = getView
    return instance
end

function LayerBuilder:default()
    local view = self._getView()
    Api.Window.SetLayer(view:getName(), Constants.WindowLayers.Default)
    return view
end

function LayerBuilder:overlay()
    local view = self._getView()
    Api.Window.SetLayer(view:getName(), Constants.WindowLayers.Overlay)
    return view
end

function LayerBuilder:popup()
    local view = self._getView()
    Api.Window.SetLayer(view:getName(), Constants.WindowLayers.Popup)
    return view
end

function LayerBuilder:background()
    local view = self._getView()
    Api.Window.SetLayer(view:getName(), Constants.WindowLayers.Background)
    return view
end

-- ========================================================================== --
-- Components - Internal Builders - Layout Builder
-- ========================================================================== --

local Layouts = {}

Layouts.StackAndFill = function(window, children, child, index)
    if index > 1 then
        child:addAnchor(
            "bottomleft",
            children[index - 1]:getName(),
            "topleft",
            0,
            8
        )
    else
        child:addAnchor(
            "topleft",
            window:getName(),
            "topleft",
            12,
            12
        )
    end

    local parentDimens = window:getDimensions()
    local parentX = parentDimens.x
    local parentY = parentDimens.y

    local childWidth = parentX - 24
    if childWidth < 0 then
        childWidth = parentX
    end

    local childSpaceOffset = (#children - 1) * 8

    local childHeight = (parentY - 24 - childSpaceOffset) / #children
    if childHeight < 0 then
        childHeight = parentY
    end

    child:setDimensions(childWidth, childHeight)
end

-- ========================================================================== --
-- Components - Button
-- ========================================================================== --

---@param model ButtonModel?
---@return Button
function Button:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatButton"
    local instance = Window.new(self, model)
    return instance --[[@as Button]]
end

function Button:getTextDimensions()
    Api.Button.GetTextDimensions(self:getName())
end

function Button:setText(text)
    if text == nil then return end
    Api.Button.SetText(self:getName(), Utils.String.ToWString(text))
end

function Button:getText()
    return Api.Button.GetText(self:getName())
end

function Button:setTexture(state, texture, x, y)
    Api.Button.SetTexture(self:getName(), state, texture, x, y)
end

function Button:setTextColor(state, color)
    Api.Button.SetTextColor(self:getName(), state, color.r, color.g, color.b)
end

function Button:setChecked(isChecked)
    Api.Button.SetChecked(self:getName(), isChecked)
    return self
end

function Button:isChecked()
    return Api.Button.IsChecked(self:getName())
end

function Button:setStayDown(stayDown)
    Api.Button.SetStayDown(self:getName(), stayDown)
    return self
end

function Button:setCheckButton(enabled)
    Api.Button.SetEnabled(self:getName(), enabled)
    return self
end

---@param model ButtonModel?
---@return Button
function Components.Button(model)
    local button = Button:new(model)
    Cache[button:getName()] = button
    return button
end

-- ========================================================================== --
-- Components - Circle Image
-- ========================================================================== --

---@param model CircleImageModel?
---@return CircleImage
function CircleImage:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatCircleImage"
    local instance = View.new(CircleImage, model)
    return instance --[[@as CircleImage]]
end

function CircleImage:setTexture(texture, x, y)
    Api.CircleImage.SetTexture(self:getName(), texture, x, y)
end

function CircleImage:SetFillParams(startAngle, fillAngle)
    Api.CircleImage.SetFillParams(self:getName(), startAngle, fillAngle)
end

function CircleImage:setTextureSlice(sliceName)
    Api.CircleImage.SetTextureSlice(self:getName(), sliceName)
end

function CircleImage:setTextureScale(scale)
    Api.CircleImage.SetTextureScale(self:getName(), scale)
end

function CircleImage:setRotation(rotation)
    Api.CircleImage.SetRotation(self:getName(), rotation)
end

---@param model CircleImageModel?
---@return CircleImage
function Components.CircleImage(model)
    local circleImage = CircleImage:new(model)
    Cache[circleImage:getName()] = circleImage
    return circleImage
end

-- ========================================================================== --
-- Components - Component
-- ========================================================================== --

---@param name string
---@return Component
function Component:new(name)
    local instance = setmetatable({}, self)
    instance.name = name
    return instance
end

function Component:getName()
    return self.name
end

-- ========================================================================== --
-- Components - Default
-- ========================================================================== --

---@param name string
---@return DefaultComponent
function DefaultComponent:new(name)
    local instance = Component.new(self, name) --[[@as DefaultComponent]]
    return instance
end

function DefaultComponent:getDefault()
    return Component:new(self.name)
end

function DefaultComponent:asComponent()
    return Component:new(self.name)
end

--- Creates a proxy table that wraps the original global table.
--- When disabled, all function calls become no-ops UNLESS they were explicitly
--- overridden via assignment (stored in _overrides). Overrides always execute,
--- allowing a mod to intercept specific functions while the rest are suppressed.
---@param original table The original global table to wrap
---@return table proxy The proxy table
function DefaultComponent:_createProxy(original)
    local proxy = {
        _disabled = false,
        _original = original,
        _overrides = {}
    }

    setmetatable(proxy, {
        __index = function(self, key)
            -- Don't intercept internal keys
            if key == "_disabled" or key == "_original" or key == "_overrides" then
                return rawget(self, key)
            end

            -- Overrides always take precedence regardless of disabled state.
            -- This lets mods hook Initialize/Shutdown while still suppressing
            -- all other original functions via disable().
            local override = rawget(self, "_overrides")[key]
            if override ~= nil then
                return override
            end

            local value = rawget(self, "_original")[key]

            -- If disabled and it's a function, return a no-op
            if rawget(self, "_disabled") and type(value) == "function" then
                return function() end
            end

            return value
        end,
        __newindex = function(self, key, value)
            -- Don't intercept internal keys
            if key == "_disabled" or key == "_original" or key == "_overrides" then
                rawset(self, key, value)
                return
            end
            -- Store as an override (not in _original).
            -- restore() will clear all overrides, reverting to original behaviour.
            rawget(self, "_overrides")[key] = value
        end
    })

    return proxy
end

--- Disables the default component. All function calls become no-ops.
--- Functions explicitly overridden via assignment continue to work.
function DefaultComponent:disable()
    local proxy = self._proxy
    if proxy then
        proxy._disabled = true
    end
end

--- Restores the default component: re-enables original functions and clears
--- any overrides set via assignment, leaving no trace of the mod's hooks.
function DefaultComponent:restore()
    local proxy = self._proxy
    if proxy then
        proxy._disabled = false
        proxy._overrides = {}
    end
end

--- Restores the original global table that was replaced by the proxy.
--- Called during framework shutdown to leave no traces.
function DefaultComponent:restoreGlobal()
    if self._proxy and self._globalKey then
        _G[self._globalKey] = self._proxy._original
    end
end

-- ========================================================================== --
-- Components - Default - Actions
-- ========================================================================== --

---@return DefaultActionsComponent
function DefaultActionsComponent:new()
    local instance = DefaultComponent.new(self, "Actions") --[[@as DefaultActionsComponent]]
    instance._proxy = instance:_createProxy(Actions)
    instance._globalKey = "Actions"
    _G.Actions = instance._proxy
    return instance
end

---@return DefaultActions
function DefaultActionsComponent:getDefault()
    return self._proxy or Actions --[[@as DefaultActions]]
end

-- ========================================================================== --
-- Components - Default - Generic Gump
-- ========================================================================== --

---@class DefaultGenericGump
---@field LastGump string Name of the last gump window
---@field LastGumpLabels table Table of last gump labels
---@field GumpsList table Table of gumps list
---@field Initialize fun() Initializes the generic gump
---@field OnLabelInit fun() Handles label initialization
---@field Shutdown fun() Shuts down the generic gump
---@field OnClicked fun() Handles gump click
---@field OnDoubleClicked fun() Handles gump double click
---@field OnRClicked fun() Handles gump right click
---@field OnMouseOver fun() Handles mouse over on gump
---@field OnHyperLinkClicked fun(link: any) Handles hyperlink click
---@field OnShown fun() Handles gump shown event

---@class DefaultGenericGumpComponent : DefaultComponent
local DefaultGenericGumpComponent = {}
DefaultGenericGumpComponent.__index = DefaultGenericGumpComponent

---@return DefaultGenericGumpComponent
function DefaultGenericGumpComponent:new()
    local instance = DefaultComponent.new(self, "GenericGump") --[[@as DefaultGenericGumpComponent]]
    instance._proxy = instance:_createProxy(GenericGump)
    instance._proxy.OnShown = function () end
    instance._globalKey = "GenericGump"
    _G.GenericGump = instance._proxy
    return instance
end

---@return DefaultGenericGump
function DefaultGenericGumpComponent:getDefault()
    return self._proxy or GenericGump --[[@as DefaultGenericGump]]
end


-- ========================================================================== --
-- Components - Default - Gumps Parsing
-- ========================================================================== --

---@class DefaultGumpMapItem
---@field name string
---@field show integer

---@class DefaultGumpsParsing
---@field ParsedGumps table Table of parsed gumps
---@field ToShow table Table of gumps to show/hide
---@field SOSTids table Table of SOS TIDs
---@field GumpMaps table<integer, DefaultGumpMapItem> Table of gump mappings
---@field CheckGumpType fun(timePassed: any) Checks the gump type and processes gumps
---@field MainParsingCheck fun(timePassed: any) Main parsing check for gumps
---@field DestroyGump fun(gumpID: integer) Destroys a gump window
---@field PressButton fun(gumpID: integer, buttonID: integer) Presses a button on a gump
---@field TextentryGetText fun(gumpID: integer, TextentryID: integer): any Gets text from a text entry
---@field ShowHide fun(timePassed: any) Shows or hides gumps based on ToShow
---@field SixMonthsRewardGump fun() Handles the six months reward gump
---@field SOSGump fun(data: table) Handles SOS gump logic
---@field CreateSOSWaypoint fun(sosID: any, map: any, x: any, y: any) Creates a SOS waypoint
---@field GetSOSCoords fun(coords: any): number, any, number, any Gets SOS coordinates from a string

---@class DefaultGumpsParsingComponent : DefaultComponent
local DefaultGumpsParsingComponent = {}
DefaultGumpsParsingComponent.__index = DefaultGumpsParsingComponent

---@return DefaultGumpsParsingComponent
function DefaultGumpsParsingComponent:new()
    local instance = DefaultComponent.new(self, "GumpsParsing") --[[@as DefaultGumpsParsingComponent]]
    instance._proxy = instance:_createProxy(GumpsParsing)
    instance._globalKey = "GumpsParsing"
    _G.GumpsParsing = instance._proxy
    return instance
end

---@return DefaultGumpsParsing
function DefaultGumpsParsingComponent:getDefault()
    return self._proxy or GumpsParsing --[[@as DefaultGumpsParsing]]
end

function DefaultGumpsParsingComponent:getVendorSearch()
    return self:getDefault().GumpMaps[Constants.GumpIds.VendorSearch]
end

-- ========================================================================== --
-- Components - Default - Health Bar Manager
-- ========================================================================== --

---@class DefaultHealthBarManager
---@field OnBeginDragHealthBar fun(objectId: integer)

---@class DefaultHealthBarManagerComponent : DefaultComponent
local DefaultHealthBarManagerComponent = {}
DefaultHealthBarManagerComponent.__index = DefaultHealthBarManagerComponent

---@return DefaultHealthBarManagerComponent
function DefaultHealthBarManagerComponent:new()
    local instance = DefaultComponent.new(self, "HealthBarManager") --[[@as DefaultHealthBarManagerComponent]]
    instance._proxy = instance:_createProxy(HealthBarManager)
    instance._globalKey = "HealthBarManager"
    _G.HealthBarManager = instance._proxy
    return instance
end

---@return DefaultHealthBarManager
function DefaultHealthBarManagerComponent:getDefault()
    return self._proxy or HealthBarManager --[[@as DefaultHealthBarManager]]
end


-- ========================================================================= --
-- Components - Default - Interface
-- ========================================================================= --

---@return DefaultInterfaceComponent
function DefaultInterfaceComponent:new()
    local instance = DefaultComponent.new(self, "Interface") --[[@as DefaultInterfaceComponent]]
    instance._proxy = instance:_createProxy(Interface)
    instance._globalKey = "Interface"
    _G.Interface = instance._proxy
    return instance
end

---@return Interface
function DefaultInterfaceComponent:getDefault()
    return self._proxy or Interface --[[@as Interface]]
end

-- ========================================================================== --
-- Components - Default - Main Menu Window
-- ========================================================================== --

--- @class DefaultMainMenuWindow
--- @field TID table
--- @field Initialize fun()
--- @field Shutdown fun()
--- @field OnLogOut fun()
--- @field OnOpenUserSettings fun()
--- @field OnOpenMacros fun()
--- @field OnOpenActions fun()
--- @field OnOpenBugReportItem fun()
--- @field OnOpenHelp fun()
--- @field OnOpenUOStore fun()
--- @field ToggleSettingsWindow fun()
--- @field ToggleBugReportWindow fun()
--- @field OnToggleAgentsSettings fun()

---@class DefaultMainMenuWindowComponent : DefaultComponent
local DefaultMainMenuWindowComponent = {}
DefaultMainMenuWindowComponent.__index = DefaultMainMenuWindowComponent

---@return DefaultMainMenuWindowComponent
function DefaultMainMenuWindowComponent:new()
    local instance = DefaultComponent.new(self, "MainMenuWindow") --[[@as DefaultMainMenuWindowComponent]]
    instance._proxy = instance:_createProxy(MainMenuWindow)
    instance._globalKey = "MainMenuWindow"
    _G.MainMenuWindow = instance._proxy
    return instance
end

---@return DefaultMainMenuWindow
function DefaultMainMenuWindowComponent:getDefault()
    return self._proxy or MainMenuWindow --[[@as DefaultMainMenuWindow]]
end

---@return Window
function DefaultMainMenuWindowComponent:asComponent()
    return Window:new { Name = self.name }
end

-- ========================================================================== --
-- Components - Default - Map Common
-- ========================================================================== --

---@class DefaultMapCommon

---@class DefaultMapCommonComponent : DefaultComponent
local DefaultMapCommonComponent = {}
DefaultMapCommonComponent.__index = DefaultMapCommonComponent

---@return DefaultMapCommonComponent
function DefaultMapCommonComponent:new()
    local instance = DefaultComponent.new(self, "MapCommon") --[[@as DefaultMapCommonComponent]]
    instance._proxy = instance:_createProxy(MapCommon)
    instance._globalKey = "MapCommon"
    _G.MapCommon = instance._proxy
    return instance
end

---@return DefaultMapCommon
function DefaultMapCommonComponent:getDefault()
    return self._proxy or MapCommon --[[@as DefaultMapCommon]]
end


-- ========================================================================== --
-- Components - Default - Map Window
-- ========================================================================== --

---@class DefaultMapWindow

---@class DefaultMapWindowComponent : DefaultComponent
local DefaultMapWindowComponent = {}
DefaultMapWindowComponent.__index = DefaultMapWindowComponent

---@return DefaultMapWindowComponent
function DefaultMapWindowComponent:new()
    local instance = DefaultComponent.new(self, "MapWindow") --[[@as DefaultMapWindowComponent]]
    instance._proxy = instance:_createProxy(MapWindow)
    instance._globalKey = "MapWindow"
    _G.MapWindow = instance._proxy
    return instance
end

---@return DefaultMapWindow
function DefaultMapWindowComponent:getDefault()
    return self._proxy or MapWindow --[[@as DefaultMapWindow]]
end

function DefaultMapWindowComponent:asComponent()
    return Window:new { Name = self.name }
end

-- ========================================================================== --
-- Components - Default - Debug Window
-- ========================================================================== --

---@class DefaultDebugWindowComponent : DefaultComponent
local DefaultDebugWindowComponent = {}
DefaultDebugWindowComponent.__index = DefaultDebugWindowComponent

---@return DefaultDebugWindowComponent
function DefaultDebugWindowComponent:new()
    local instance = DefaultComponent.new(self, "DebugWindow") --[[@as DefaultDebugWindowComponent]]
    instance._proxy = instance:_createProxy(DebugWindow)
    instance._globalKey = "DebugWindow"
    _G.DebugWindow = instance._proxy
    return instance
end

---@return table
function DefaultDebugWindowComponent:getDefault()
    return self._proxy or DebugWindow
end

---@return Window
function DefaultDebugWindowComponent:asComponent()
    return Window:new { Name = self.name }
end

-- ========================================================================== --
-- Components - Default - Object Handle
-- ========================================================================== --

---@return DefaultObjectHandleComponent
function DefaultObjectHandleComponent:new()
    local instance = DefaultComponent.new(self, "ObjectHandle") --[[@as DefaultObjectHandleComponent]]
    instance._proxy = instance:_createProxy(ObjectHandleWindow)
    instance._globalKey = "ObjectHandleWindow"
    _G.ObjectHandleWindow = instance._proxy
    return instance
end

---@return DefaultObjectHandle
function DefaultObjectHandleComponent:getDefault()
    return self._proxy or ObjectHandleWindow --[[@as DefaultObjectHandle]]
end

---@return Window
function DefaultObjectHandleComponent:asComponent()
    return Window:new { Name = self.name }
end

-- ========================================================================== --
-- Components - Default - Settings Window
-- ========================================================================== --

---@return DefaultSettingsWindowComponent
function DefaultSettingsWindowComponent:new()
    local instance = DefaultComponent.new(self, "SettingsWindow") --[[@as DefaultSettingsWindowComponent]]
    instance._proxy = instance:_createProxy(SettingsWindow)
    instance._globalKey = "SettingsWindow"
    _G.SettingsWindow = instance._proxy
    return instance
end

---@return DefaultSettingsWindow
function DefaultSettingsWindowComponent:getDefault()
    return self._proxy or SettingsWindow --[[@as DefaultSettingsWindow]]
end

---@return Window
function DefaultSettingsWindowComponent:asComponent()
    return Window:new { Name = self.name }
end

-- ========================================================================== --
-- Components - Default - Shopkeeper
-- ========================================================================== --

---@class DefaultShopkeeperComponent : DefaultComponent

---@return DefaultShopkeeperComponent
function DefaultShopkeeperComponent:new()
    local instance = DefaultComponent.new(self, "Shopkeeper") --[[@as DefaultShopkeeperComponent]]
    instance._proxy = instance:_createProxy(Shopkeeper)
    instance._globalKey = "Shopkeeper"
    _G.Shopkeeper = instance._proxy
    return instance
end

---@return table
function DefaultShopkeeperComponent:getDefault()
    return self._proxy or Shopkeeper
end

---@return Window
function DefaultShopkeeperComponent:asComponent()
    return Window:new { Name = self.name }
end

-- ========================================================================== --
-- Components - Default - Status Window
-- ========================================================================== --

---@return DefaultStatusWindowComponent
function DefaultStatusWindowComponent:new()
    local instance = DefaultComponent.new(self, "StatusWindow") --[[@as DefaultStatusWindowComponent]]
    -- Create proxy and replace global
    instance._proxy = instance:_createProxy(StatusWindow)
    instance._globalKey = "StatusWindow"
    _G.StatusWindow = instance._proxy
    return instance
end

---@return DefaultStatusWindow
function DefaultStatusWindowComponent:getDefault()
    return self._proxy or StatusWindow --[[@as DefaultStatusWindow]]
end

---@return Window
function DefaultStatusWindowComponent:asComponent()
    return Window:new { Name = self.name }
end

-- ========================================================================== --
-- Components - Default - War Shield
-- ========================================================================== --

---@return DefaultWarShieldComponent
function DefaultWarShieldComponent:new()
    local instance = DefaultComponent.new(self, "WarShield") --[[@as DefaultWarShieldComponent]]
    instance._proxy = instance:_createProxy(WarShield)
    instance._globalKey = "WarShield"
    _G.WarShield = instance._proxy
    return instance
end

---@return Window
function DefaultWarShieldComponent:asComponent()
    return Window:new { Name = self.name }
end

---@return DefaultWarShield
function DefaultWarShieldComponent:getDefault()
    return self._proxy or WarShield --[[@as DefaultWarShield]]
end

-- ========================================================================== --
-- Components - Default - Paperdoll Window
-- ========================================================================== --

---@return DefaultPaperdollWindowComponent
function DefaultPaperdollWindowComponent:new()
    local instance = DefaultComponent.new(self, "PaperdollWindow") --[[@as DefaultPaperdollWindowComponent]]
    instance._proxy = instance:_createProxy(PaperdollWindow)
    instance._globalKey = "PaperdollWindow"
    _G.PaperdollWindow = instance._proxy
    return instance
end

---@return DefaultPaperdollWindow
function DefaultPaperdollWindowComponent:getDefault()
    return self._proxy or PaperdollWindow --[[@as DefaultPaperdollWindow]]
end

---@return Window
function DefaultPaperdollWindowComponent:asComponent()
    return Window:new { Name = self.name }
end

-- ========================================================================== --
-- Components - Dynamic Image
-- ========================================================================== --

---@param model DynamicImageModel?
---@return DynamicImage
function DynamicImage:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatDynamicImage"
    local instance = View.new(self, model)
    return instance --[[@as DynamicImage]]
end

function DynamicImage:setTexture(texture, x, y)
    Api.DynamicImage.SetTexture(self:getName(), texture, x, y)
end

function DynamicImage:setTextureSlice(sliceName)
    Api.DynamicImage.SetTextureSlice(self:getName(), sliceName)
end

function DynamicImage:setTextureScale(scale)
    Api.DynamicImage.SetTextureScale(self:getName(), scale)
end

function DynamicImage:setRotation(rotation)
    Api.DynamicImage.SetRotation(self:getName(), rotation)
end

function DynamicImage:setTextureDimensions(width, height)
    Api.DynamicImage.SetTextureDimensions(self:getName(), width, height)
end

function DynamicImage:setTextureOrientation(isMirrored)
    Api.DynamicImage.SetTextureOrientation(self:getName(), isMirrored)
end

function DynamicImage:hasTexture()
    return Api.DynamicImage.HasTexture(self:getName())
end

--- Updates this DynamicImage as an item icon from object/equipment data.
--- Accepts either raw engine data or an ObjectInfoWrapper (auto-unwrapped via getData()).
---@param slotData table|ObjectInfoWrapper The object/slot data (e.g., from Data.ObjectInfo).
function DynamicImage:updateItemIcon(slotData)
    local data = type(slotData.getData) == "function" and slotData:getData() or slotData
    Api.Equipment.UpdateItemIcon(self:getName(), data)
end

---@param model DynamicImageModel?
---@return DynamicImage
function Components.DynamicImage(model)
    local dynamicImage = DynamicImage:new(model)
    Cache[dynamicImage:getName()] = dynamicImage
    return dynamicImage
end

-- ========================================================================== --
-- Components - Edit Text Box
-- ========================================================================== --

---@param model EditTextBoxModel?
---@return EditTextBox
function EditTextBox:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatEditTextBox"
    local instance = View.new(self, model)
    return instance --[[@as EditTextBox]]
end

function EditTextBox:setText(text)
    if text == nil then return end
    Api.EditTextBox.SetText(self:getName(), Utils.String.ToWString(text))
end

function EditTextBox:getText()
    return Api.EditTextBox.GetText(self:getName())
end

---@param color Color
function EditTextBox:setTextColor(color)
    Api.EditTextBox.SetTextColor(self:getName(), color.r, color.g, color.b)
end

function EditTextBox:selectAll()
    Api.EditTextBox.SelectAll(self:getName())
end

---@param focus boolean
function EditTextBox:setFocus(focus)
    Api.Window.AssignFocus(self:getName(), focus)
end

function EditTextBox:clear()
    Api.EditTextBox.SetText(self:getName(), L"")
end

---@param font string
function EditTextBox:setFont(font)
    Api.EditTextBox.SetFont(self:getName(), font)
end

---@param model EditTextBoxModel?
---@return EditTextBox
function Components.EditTextBox(model)
    local editTextBox = EditTextBox:new(model)
    Cache[editTextBox:getName()] = editTextBox
    return editTextBox
end

-- ========================================================================== --
-- Components - FilterInput
-- ========================================================================== --

setmetatable(FilterInput, { __index = EditTextBox })

---@param model FilterInputModel?
---@return FilterInput
function FilterInput:new(model)
    model = model or {}
    local instance = EditTextBox.new(self, model) --[[@as FilterInput]]
    return instance
end

---@return wstring
function FilterInput:getFilterText()
    return self:getText()
end

---@param model FilterInputModel?
---@return FilterInput
function Components.FilterInput(model)
    local filterInput = FilterInput:new(model)
    Cache[filterInput:getName()] = filterInput
    return filterInput
end

-- ========================================================================== --
-- Components - Window Snapping
-- ========================================================================== --

--- Gets the rectangle of a snappable window in offset space (unscaled Root coordinates).
--- Returns nil if the window does not exist or is not showing.
---@param name string
---@return { x: number, y: number, w: number, h: number }?
local function getWindowRect(name)
    if not DoesWindowNameExist(name) then return nil end
    if not WindowGetShowing(name) then return nil end
    if WindowGetParent(name) ~= "Root" then return nil end
    local ox, oy = WindowGetOffsetFromParent(name)
    local w, h = WindowGetDimensions(name)
    return { x = ox, y = oy, w = w, h = h }
end

--- Finds the best snap adjustment for a window against all other snappable windows
--- and screen edges. An optional exclusion set skips listed window names.
---@param windowName string
---@param exclude table<string, boolean>?
---@param skipScreenEdges boolean?
---@return number, number  dx, dy adjustment in offset space
local function findSnap(windowName, exclude, skipScreenEdges)
    local rect = getWindowRect(windowName)
    if rect == nil then return 0, 0 end

    local left = rect.x
    local top = rect.y
    local right = rect.x + rect.w
    local bottom = rect.y + rect.h

    local bestDx = 0
    local bestDy = 0
    local bestDistX = SNAP_THRESHOLD + 1
    local bestDistY = SNAP_THRESHOLD + 1

    local d

    if not skipScreenEdges then
        -- Screen edges in offset space
        local scale = InterfaceCore.scale
        local screenW = SystemData.screenResolution.x / scale
        local screenH = SystemData.screenResolution.y / scale

        -- Snap to screen left
        d = math.abs(left)
        if d < bestDistX then bestDistX = d; bestDx = -left end
        -- Snap to screen right
        d = math.abs(right - screenW)
        if d < bestDistX then bestDistX = d; bestDx = screenW - right end
        -- Snap to screen top
        d = math.abs(top)
        if d < bestDistY then bestDistY = d; bestDy = -top end
        -- Snap to screen bottom
        d = math.abs(bottom - screenH)
        if d < bestDistY then bestDistY = d; bestDy = screenH - bottom end
    end

    -- Snap to other windows (only when nearby on the perpendicular axis)
    for otherName, _ in pairs(SnappableWindows) do
        if otherName ~= windowName and (exclude == nil or not exclude[otherName]) then
            local other = getWindowRect(otherName)
            if other ~= nil then
                local oLeft = other.x
                local oTop = other.y
                local oRight = other.x + other.w
                local oBottom = other.y + other.h

                -- Check perpendicular proximity: are the two windows close
                -- enough vertically to justify a horizontal snap (and vice versa)?
                local nearV = (top < oBottom + SNAP_THRESHOLD) and (bottom > oTop - SNAP_THRESHOLD)
                local nearH = (left < oRight + SNAP_THRESHOLD) and (right > oLeft - SNAP_THRESHOLD)

                if nearV then
                    -- Horizontal: our left to their right
                    d = math.abs(left - oRight)
                    if d < bestDistX then bestDistX = d; bestDx = oRight - left end
                    -- Horizontal: our right to their left
                    d = math.abs(right - oLeft)
                    if d < bestDistX then bestDistX = d; bestDx = oLeft - right end
                    -- Horizontal: align left edges
                    d = math.abs(left - oLeft)
                    if d < bestDistX then bestDistX = d; bestDx = oLeft - left end
                    -- Horizontal: align right edges
                    d = math.abs(right - oRight)
                    if d < bestDistX then bestDistX = d; bestDx = oRight - right end
                end

                if nearH then
                    -- Vertical: our top to their bottom
                    d = math.abs(top - oBottom)
                    if d < bestDistY then bestDistY = d; bestDy = oBottom - top end
                    -- Vertical: our bottom to their top
                    d = math.abs(bottom - oTop)
                    if d < bestDistY then bestDistY = d; bestDy = oTop - bottom end
                    -- Vertical: align top edges
                    d = math.abs(top - oTop)
                    if d < bestDistY then bestDistY = d; bestDy = oTop - top end
                    -- Vertical: align bottom edges
                    d = math.abs(bottom - oBottom)
                    if d < bestDistY then bestDistY = d; bestDy = oBottom - bottom end
                end
            end
        end
    end

    if bestDistX > SNAP_THRESHOLD then bestDx = 0 end
    if bestDistY > SNAP_THRESHOLD then bestDy = 0 end

    return bestDx, bestDy
end

--- Applies a snap offset to a window by adjusting its anchor.
---@param windowName string
---@param dx number
---@param dy number
local function applySnap(windowName, dx, dy)
    if dx == 0 and dy == 0 then return end
    local ox, oy = WindowGetOffsetFromParent(windowName)
    WindowClearAnchors(windowName)
    WindowAddAnchor(windowName, "topleft", "Root", "topleft", ox + dx, oy + dy)
end

local ADJACENT_TOLERANCE = 2

--- Returns true if two rectangles share an edge (within tolerance) and overlap
--- on the perpendicular axis.
local function areAdjacent(a, b)
    local aRight = a.x + a.w
    local aBottom = a.y + a.h
    local bRight = b.x + b.w
    local bBottom = b.y + b.h

    local hOverlap = a.x < bRight and aRight > b.x
    local vOverlap = a.y < bBottom and aBottom > b.y

    if vOverlap and math.abs(aRight - b.x) <= ADJACENT_TOLERANCE then return true end
    if vOverlap and math.abs(a.x - bRight) <= ADJACENT_TOLERANCE then return true end
    if hOverlap and math.abs(aBottom - b.y) <= ADJACENT_TOLERANCE then return true end
    if hOverlap and math.abs(a.y - bBottom) <= ADJACENT_TOLERANCE then return true end

    return false
end

--- Finds all snappable windows transitively adjacent to the given window (BFS).
--- Returns a list of window names (including the given window).
---@param windowName string
---@return string[]
local function findJoinedGroup(windowName)
    local group = {}
    local visited = {}
    local queue = { windowName }

    while #queue > 0 do
        local current = table.remove(queue, 1)
        if not visited[current] then
            visited[current] = true
            table.insert(group, current)
            local currentRect = getWindowRect(current)
            if currentRect then
                for otherName, _ in pairs(SnappableWindows) do
                    if not visited[otherName] then
                        local otherRect = getWindowRect(otherName)
                        if otherRect and areAdjacent(currentRect, otherRect) then
                            table.insert(queue, otherName)
                        end
                    end
                end
            end
        end
    end

    return group
end

-- Snap preview ghost window (created lazily)
local SNAP_PREVIEW_NAME = "MongbatSnapPreviewWindow"
local snapPreviewCreated = false

--- Ensures the snap preview window exists (lazy creation).
local function ensureSnapPreview()
    if snapPreviewCreated then return end
    CreateWindowFromTemplate(SNAP_PREVIEW_NAME, "MongbatSnapPreview", "Root")
    WindowSetShowing(SNAP_PREVIEW_NAME, false)
    WindowSetAlpha(SNAP_PREVIEW_NAME, 0.35)
    snapPreviewCreated = true
end

--- Shows the snap preview ghost at the given position and size.
---@param x number
---@param y number
---@param w number
---@param h number
local function showSnapPreview(x, y, w, h)
    ensureSnapPreview()
    WindowSetDimensions(SNAP_PREVIEW_NAME, w, h)
    WindowClearAnchors(SNAP_PREVIEW_NAME)
    WindowAddAnchor(SNAP_PREVIEW_NAME, "topleft", "Root", "topleft", x, y)
    WindowSetShowing(SNAP_PREVIEW_NAME, true)
end

--- Hides the snap preview ghost.
local function hideSnapPreview()
    if snapPreviewCreated and DoesWindowNameExist(SNAP_PREVIEW_NAME) then
        WindowSetShowing(SNAP_PREVIEW_NAME, false)
    end
end

--- Destroys the snap preview ghost window.
local function destroySnapPreview()
    if snapPreviewCreated and DoesWindowNameExist(SNAP_PREVIEW_NAME) then
        DestroyWindow(SNAP_PREVIEW_NAME)
    end
    snapPreviewCreated = false
end

-- ========================================================================== --
-- Components - Event Handler
-- ========================================================================== --

--- Safely dispatches an event to the active window via Active.window().
--- If the window is nil or the callback errors, it is caught and logged.
---@param eventName string The name of the event (for error logging)
---@param callback fun(window: View)
local function withActiveView(eventName, callback)
    local success, err = pcall(function()
        local window = Cache[Active.window()]
        if window == nil then return end
        callback(window)
    end)
    if not success then
        Debug.Print("[Mongbat] Error in " .. eventName .. ": " .. tostring(err))
    end
end

--- Safely dispatches an event to the mouse-over window.
--- If the direct cache lookup fails, walks up the parent chain
--- to find the nearest ancestor that is a cached View. This allows
--- auto-created children (e.g. ListBox rows) to propagate events to
--- their parent View.
---@param eventName string The name of the event (for error logging)
---@param callback fun(window: View)
local function withMouseOverView(eventName, callback)
    local success, err = pcall(function()
        local mouseOverWindow = SystemData.MouseOverWindow
        if mouseOverWindow == nil then return end

        local name = mouseOverWindow.name
        if name == nil or name == "" then return end

        local window = Cache[name]
        if window == nil then
            -- Walk up the parent chain to find a cached ancestor View
            local parentName = name
            while parentName do
                parentName = WindowGetParent(parentName)
                if parentName == nil or parentName == "" or parentName == "Root" then
                    break
                end
                window = Cache[parentName]
                if window then break end
            end
            if window == nil then return end
        end

        callback(window)
    end)
    if not success then
        Debug.Print("[Mongbat] Error in " .. eventName .. ": " .. tostring(err))
    end
end

function EventHandler.OnInitialize()
    withActiveView("OnInitialize", function(window)
        window:onInitialize()
    end)
end

function EventHandler.OnShutdown()
    local success, err = pcall(function()
        local activeWindowName = Active.window()
        local window = Cache[activeWindowName]
        Cache[activeWindowName] = nil
        if window == nil then return end
        window:onShutdown()
    end)
    if not success then
        Debug.Print("[Mongbat] Error in OnShutdown: " .. tostring(err))
    end
end

--- Stops an active resize and re-layouts children.
local function stopResize()
    if resizingWindow == nil then return end
    local window = resizingWindow
    resizingWindow = nil
    resizeState = nil

    -- Restore the original OnUpdate handler
    window._model.OnUpdate = resizeOriginalOnUpdate

    -- If we dynamically registered OnUpdate, unregister it
    if resizeRegisteredOnUpdate then
        window:unregisterCoreEventHandler(Constants.CoreEvents.OnUpdate)
        resizeRegisteredOnUpdate = false
    end

    resizeOriginalOnUpdate = nil

    -- Re-layout children
    if window._model.OnLayout then
        Utils.Array.ForEach(window._children, function(child, index)
            child:clearAnchors()
            window._model.OnLayout(window, window._children, child, index)
        end)
    end
end

--- Begins a live resize for the given window. Injects a per-frame OnUpdate
--- handler on the window itself, chaining any existing OnUpdate.
---@param window Window
local function startResize(window)
    -- Cancel any in-progress resize first
    if resizingWindow ~= nil then stopResize() end

    resizingWindow = window
    local mousePos = SystemData.MousePosition
    local dimens = window:getDimensions()
    resizeState = {
        startMouseX = mousePos.x,
        startMouseY = mousePos.y,
        startWidth = dimens.x,
        startHeight = dimens.y,
        minWidth = window._model.MinWidth or 100,
        minHeight = window._model.MinHeight or 100,
    }

    -- Prevent the parent window from moving while resizing
    Api.Window.SetMoving(window.name, false)

    -- Save the original OnUpdate and inject our resize handler
    resizeOriginalOnUpdate = window._model.OnUpdate

    window._model.OnUpdate = function(self, timePassed)
        -- Perform resize calculations
        if resizingWindow ~= nil and resizeState ~= nil then
            local mPos = SystemData.MousePosition
            local scale = InterfaceCore.scale
            local dx = (mPos.x - resizeState.startMouseX) / scale
            local dy = (mPos.y - resizeState.startMouseY) / scale
            local newW = math.max(resizeState.startWidth + dx, resizeState.minWidth)
            local newH = math.max(resizeState.startHeight + dy, resizeState.minHeight)
            resizingWindow:setDimensions(newW, newH)

            -- Re-layout children each frame so content tracks the new size
            if resizingWindow._model.OnLayout then
                Utils.Array.ForEach(resizingWindow._children, function(child, index)
                    child:clearAnchors()
                    resizingWindow._model.OnLayout(resizingWindow, resizingWindow._children, child, index)
                end)
            end
        end

        -- Chain the original OnUpdate if it existed
        if resizeOriginalOnUpdate ~= nil then
            resizeOriginalOnUpdate(self, timePassed)
        end
    end

    -- If the window didn't already have OnUpdate registered, register the CoreEvent now.
    -- Snapping may have already registered it, so check _snapRegisteredOnUpdate too.
    if resizeOriginalOnUpdate == nil and not window._snapRegisteredOnUpdate then
        resizeRegisteredOnUpdate = true
        window:registerCoreEventHandler(
            Constants.CoreEvents.OnUpdate,
            "Mongbat.EventHandler.OnUpdate"
        )
    end
end

function EventHandler.OnLButtonUp(flags, x, y)
    if resizingWindow ~= nil then
        stopResize()
    end
    withMouseOverView("OnLButtonUp", function(window)
        window:onLButtonUp(flags, x, y)
    end)
end

function EventHandler.OnLButtonDown(flags, x, y)
    withMouseOverView("OnLButtonDown", function(window)
        window:onLButtonDown(flags, x, y)
    end)
end

function EventHandler.OnRButtonDown(flags, x, y)
    withActiveView("OnRButtonDown", function(window)
        window:onRButtonDown(flags, x, y)
    end)
end

function EventHandler.OnRButtonUp(flags, x, y)
    withActiveView("OnRButtonUp", function(window)
        window:onRButtonUp(flags, x, y)
    end)
end

function EventHandler.OnHidden()
    withActiveView("OnHidden", function(window)
        window:onHidden()
    end)
end

function EventHandler.OnShown()
    withActiveView("OnShown", function(window)
        window:onShown()
    end)
end

function EventHandler.OnUpdatePlayerStatus()
    withActiveView("OnUpdatePlayerStatus", function(window)
        window:onUpdatePlayerStatus()
    end)
end

function EventHandler.OnUpdateMobileName()
    withActiveView("OnUpdateMobileName", function(window)
        window:onUpdateMobileName()
    end)
end

function EventHandler.OnUpdateHealthBarColor()
    withActiveView("OnUpdateHealthBarColor", function(window)
        window:onUpdateHealthBarColor()
    end)
end

function EventHandler.OnUpdateMobileStatus()
    withActiveView("OnUpdateMobileStatus", function(window)
        window:onUpdateMobileStatus()
    end)
end

function EventHandler.OnUpdatePaperdoll()
    withActiveView("OnUpdatePaperdoll", function(window)
        window:onUpdatePaperdoll()
    end)
end

function EventHandler.OnUpdateShopData()
    withActiveView("OnUpdateShopData", function(window)
        window:onUpdateShopData()
    end)
end

function EventHandler.OnUpdateContainerWindow()
    withActiveView("OnUpdateContainerWindow", function(window)
        window:onUpdateContainerWindow()
    end)
end

function EventHandler.OnUpdateObjectInfo()
    withActiveView("OnUpdateObjectInfo", function(window)
        window:onUpdateObjectInfo()
    end)
end

function EventHandler.OnUpdateItemProperties()
    withActiveView("OnUpdateItemProperties", function(window)
        window:onUpdateItemProperties()
    end)
end

function EventHandler.OnUpdate(timePassed)
    withActiveView("OnUpdate", function(window)
        window:onUpdate(timePassed)
    end)
end

function EventHandler.OnLButtonDblClk(flags, x, y)
    withActiveView("OnLButtonDblClk", function(window)
        window:onLButtonDblClk(flags, x, y)
    end)
end

function EventHandler.OnMouseOver()
    withActiveView("OnMouseOver", function(window)
        window:onMouseOver()
    end)
end

function EventHandler.OnMouseOverEnd()
    withActiveView("OnMouseOverEnd", function(window)
        window:onMouseOverEnd()
    end)
end

function EventHandler.OnEndHealthBarDrag()
    withActiveView("OnEndHealthBarDrag", function(window)
        window:onEndHealthBarDrag()
    end)
end

function EventHandler.OnUpdateRadar()
    withActiveView("OnUpdateRadar", function(window)
        window:onUpdateRadar(WindowData.Radar)
    end)
end

function EventHandler.OnUpdatePlayerLocation()
    withActiveView("OnUpdatePlayerLocation", function(window)
        window:onUpdatePlayerLocation(WindowData.PlayerLocation)
    end)
end

function EventHandler.OnMouseWheel(x, y, delta)
    withActiveView("OnMouseWheel", function(window)
        window:onMouseWheel(x, y, delta)
    end)
end

function EventHandler.OnTextChanged(text)
    withActiveView("OnTextChanged", function(window)
        window:onTextChanged(text)
    end)
end

function EventHandler.OnKeyEnter()
    withActiveView("OnKeyEnter", function(window)
        window:onKeyEnter()
    end)
end

function EventHandler.OnKeyEscape()
    withActiveView("OnKeyEscape", function(window)
        window:onKeyEscape()
    end)
end

function EventHandler.OnKeyRecorded()
    withActiveView("OnKeyRecorded", function(window)
        window:onKeyRecorded()
    end)
end

function EventHandler.OnKeyCancelRecord()
    withActiveView("OnKeyCancelRecord", function(window)
        window:onKeyCancelRecord()
    end)
end

function EventHandler.OnUserSettingsUpdated()
    withActiveView("OnUserSettingsUpdated", function(window)
        window:onUserSettingsUpdated()
    end)
end

function EventHandler.OnToggleUserPreference()
    withActiveView("OnToggleUserPreference", function(window)
        window:onToggleUserPreference()
    end)
end

function EventHandler.OnSlide()
    withActiveView("OnSlide", function(view)
        view:onSlide()
    end)
end

function EventHandler.OnSelChanged()
    withActiveView("OnSelChanged", function(view)
        view:onSelChanged()
    end)
end

function EventHandler.OnPopulateRow(arg)
    withActiveView("OnPopulateRow", function(view)
        view:onPopulateRow()
    end)
end



-- ========================================================================== --
-- Components - Gump
-- ========================================================================== --

---@param gump GumpWModel
---@param id integer
---@return Gump
function Gump:new(gump, id)
    local instance = Scaffold.new(self, { Name = gump.windowName }) --[[@as Gump]]

    instance.buttons = Utils.Array.MapToArray(
        gump.Buttons,
        function(buttonName)
            return Button:new({ Name = buttonName })
        end
    )

    instance.textEntries = Utils.Array.MapToArray(
        gump.TextEntry,
        function(textEntryName)
            return EditTextBox:new({ Name = textEntryName })
        end
    )

    instance._children = Utils.Array.Concat {
        instance.buttons,
        instance.textEntries
    }

    instance._id = id
    return instance --[[@as Gump]]
end

function Gump:isVendorSearch()
    return self._id == 999112
end

function Gump:isJewelryBox()
    return self._id == 999143
end

---@param name string?
---@return Gump?
function Components.Gump(name)
    name = name or Active.window()
    if not GumpData then
        return nil
    end

    local id = -1

    local gump = Utils.Table.Find(
        GumpData.Gumps,
        function(k, v)
            id = k
            return v.windowName == name
        end
    )

    if not gump then
        return nil
    else
        return Gump:new(gump, id)
    end
end

-- ========================================================================== --
-- Components - Label
-- ========================================================================== --

---@param model LabelModel?
---@return Label
function Label:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatLabel"
    local instance = View.new(self, model)
    return instance --[[@as Label]]
end

function Label:setText(text)
    if text == nil then return end
    Api.Label.SetText(self:getName(), Utils.String.ToWString(text))
end

function Label:setTextColor(color)
    Api.Label.SetTextColor(self:getName(), color)
end

function Label:setTextAlignment(alignment)
    Api.Label.SetTextAlignment(self:getName(), alignment)
end

function Label:centerText()
    self:setTextAlignment(Constants.TextAlignment.Center)
end

---@param model LabelModel?
---@return Label
function Components.Label(model)
    local label = Label:new(model)
    Cache[label:getName()] = label
    return label
end

-- ========================================================================== --
-- Components - Log Display
-- ========================================================================== --

---@param model LogDisplayModel?
---@return LogDisplay
function LogDisplay:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatLogDisplay"
    local instance = View.new(self, model)
    return instance --[[@as LogDisplay]]
end

function LogDisplay:showTimestamp(showTimestamp)
    Api.LogDisplay.ShowTimestamp(self:getName(), showTimestamp)
    return self
end

function LogDisplay:showLogName(showLogName)
    Api.LogDisplay.ShowLogName(self:getName(), showLogName)
    return self
end

function LogDisplay:showFilterName(showFilterName)
    Api.LogDisplay.ShowFilterName(self:getName(), showFilterName)
    return self
end

function LogDisplay:setFilterState(logName, filterId, isEnabled)
    Api.LogDisplay.SetFilterState(self:getName(), logName, filterId, isEnabled)
    return self
end

function LogDisplay:setFilterColor(logName, filterId, color)
    Api.LogDisplay.SetFilterColor(self:getName(), logName, filterId, color)
    return self
end

---Registers the log to the log display
---@param logName string
---@param displayPreviousEntries boolean?
---@return LogDisplay
function LogDisplay:addLog(logName, displayPreviousEntries)
    Api.LogDisplay.AddLog(self:getName(), logName, displayPreviousEntries)
    return self
end

---Removes a log from the log display
---@param logName string
---@return LogDisplay
function LogDisplay:removeLog(logName)
    Api.LogDisplay.RemoveLog(self:getName(), logName)
    return self
end

---@param model LogDisplayModel?
---@return LogDisplay
function Components.LogDisplay(model)
    local logDisplay = LogDisplay:new(model)
    Cache[logDisplay:getName()] = logDisplay
    return logDisplay
end

-- ========================================================================== --
-- Components - Scroll Window
-- ========================================================================== --

---@param model ScrollWindowModel?
---@return ScrollWindow
function ScrollWindow:new(model)
    model = model or {}
    if model.Horizontal then
        model.Template = model.Template or "MongbatHorizontalScrollWindow"
    else
        model.Template = model.Template or "MongbatScrollWindow"
    end
    local instance = Window.new(self, model) --[[@as ScrollWindow]]
    instance._items = {}
    return instance
end

---@return string
function ScrollWindow:_getContainerName()
    return self.name .. "ChildCont"
end

---@return boolean
function ScrollWindow:isHorizontal()
    return self._model.Horizontal == true
end

function ScrollWindow:onInitialize()
    Window.onInitialize(self)
end

function ScrollWindow:onShutdown()
    self:clearItems()
    Window.onShutdown(self)
end

function ScrollWindow:onDimensionsChanged(width, height)
    local childName = self.name .. "Child"
    Api.Window.SetDimensions(childName, width - 20, height)
    self:_updateLayout()
    Window.onDimensionsChanged(self, width, height)
end

--- Adds a view as the next item in the scroll area. The view is created,
--- initialised, re-parented into the content container, and the scroll rect
--- is updated automatically.
---
--- In vertical mode (default), items are stacked top-to-bottom.
--- In horizontal mode (Horizontal = true), items are stacked left-to-right.
---
--- The view must be a freshly-constructed, not-yet-created component
--- (e.g. returned directly from a Components.* factory call).
---@param view View
---@return View
function ScrollWindow:addItem(view)
    local contName = self:_getContainerName()
    view:create(true)
    view:onInitialize()
    view:setParent(contName)
    if self:isHorizontal() then
        local itemWidth = self:_getItemWidth()
        local xOffset = #self._items * itemWidth
        view:clearAnchors()
        view:addAnchor("topleft", contName, "topleft", xOffset, 0)
    else
        local itemHeight = self:_getItemHeight()
        local yOffset = #self._items * itemHeight
        view:clearAnchors()
        view:addAnchor("topleft", contName, "topleft", 0, yOffset)
    end
    Utils.Array.Add(self._items, view)
    self:_updateLayout()
    return view
end

--- Removes a previously added view from the scroll area. The view is
--- destroyed and the remaining items are re-laid-out.
---@param view View
function ScrollWindow:removeItem(view)
    local idx = Utils.Array.IndexOf(self._items, function(v) return v == view end)
    if idx == -1 then return end
    Cache[view:getName()] = nil
    view:destroy()
    Utils.Array.Remove(self._items, idx)
    self:_updateLayout()
end

--- Destroys all items and resets the scroll offset.
function ScrollWindow:clearItems()
    Utils.Array.ForEach(self._items, function(item)
        Cache[item:getName()] = nil
        item:destroy()
    end)
    self._items = {}
    self:_updateLayout()
    self:setOffset(0)
end

--- Returns the number of items currently in the scroll area.
---@return number
function ScrollWindow:getItemCount()
    return #self._items
end

--- Iterates all items in the scroll area.
---@param fn fun(view: View, index: number)
function ScrollWindow:forEachItem(fn)
    Utils.Array.ForEach(self._items, fn)
end

--- Re-anchors all remaining items so they are stacked contiguously, then
--- resizes the content container and updates the engine scroll rect.
function ScrollWindow:_updateLayout()
    local contName = self:_getContainerName()
    if not Api.Window.DoesExist(contName) then return end
    if self:isHorizontal() then
        local itemWidth = self:_getItemWidth()
        Utils.Array.ForEach(self._items, function(item, index)
            item:clearAnchors()
            item:addAnchor("topleft", contName, "topleft", (index - 1) * itemWidth, 0)
        end)
        local dims = self:getDimensions()
        local totalWidth = #self._items * itemWidth
        Api.Window.SetDimensions(contName, totalWidth, dims.y)
        Api.HorizontalScrollWindow.UpdateScrollRect(self.name)
    else
        local itemHeight = self:_getItemHeight()
        Utils.Array.ForEach(self._items, function(item, index)
            item:clearAnchors()
            local yOffset = (index - 1) * itemHeight
            item:addAnchor("topleft", contName, "topleft", 0, yOffset)
            item:addAnchor("topright", contName, "topright", 0, yOffset)
        end)
        local childDims = Api.Window.GetDimensions(self.name .. "Child")
        local totalHeight = #self._items * itemHeight
        Api.Window.SetDimensions(contName, childDims.x, totalHeight)
        Api.ScrollWindow.UpdateScrollRect(self.name)
    end
end

---@return number
function ScrollWindow:_getItemHeight()
    return self._model.ItemHeight or 50
end

---@return number
function ScrollWindow:_getItemWidth()
    return self._model.ItemWidth or 50
end

--- Sets the scroll offset (in pixels from the start of the content area).
---@param offset number
---@return ScrollWindow
function ScrollWindow:setOffset(offset)
    if self:isHorizontal() then
        Api.HorizontalScrollWindow.SetOffset(self.name, offset)
    else
        Api.ScrollWindow.SetOffset(self.name, offset)
    end
    return self
end

--- Manually triggers a scroll rect update. Call this if the items in the
--- scroll area are resized externally.
---@return ScrollWindow
function ScrollWindow:updateScrollRect()
    if self:isHorizontal() then
        Api.HorizontalScrollWindow.UpdateScrollRect(self.name)
    else
        Api.ScrollWindow.UpdateScrollRect(self.name)
    end
    return self
end

---@param model ScrollWindowModel?
---@return ScrollWindow
function Components.ScrollWindow(model)
    local scrollWindow = ScrollWindow:new(model)
    Cache[scrollWindow:getName()] = scrollWindow
    return scrollWindow
end

-- ========================================================================== --
-- Components - Status Bar
-- ========================================================================== --

---@param model StatusBarModel?
---@param label Label?
---@return StatusBar
function StatusBar:new(model, label)
    model = model or {}
    model.Template = model.Template or "MongbatStatusBar"
    local instance = View.new(self, model) --[[@as StatusBar]]
    instance.label = label
    return instance
end

function StatusBar:onInitialize()
    View.onInitialize(self)

    -- Create a manual fill child from the FullResizeImage template.
    -- The engine's built-in StatusBar foreground is rendered internally
    -- at the template's fixed height and cannot grow vertically.  By
    -- managing the fill image ourselves we get full resize support.
    local name = self:getName()
    local fillName = name .. "Fill"
    Api.Window.CreateFromTemplate(fillName, "MongbatStatusBarFill", name, true)
    Api.Window.ClearAnchors(fillName)
    Api.Window.AddAnchor(fillName, "topleft", name, "topleft", 0, 0)

    -- Point the DynamicImage at a small solid region of the bar texture.
    -- The engine stretches this to fill the element's dimensions.
    -- Tinting via SetColor will color it.
    Api.DynamicImage.SetTexture(fillName, "StatusBar", 1, 25)
    Api.DynamicImage.SetTextureDimensions(fillName, 1, 1)

    -- Start with zero width; the first value update will size it.
    local dims = self:getDimensions()
    Api.Window.SetDimensions(fillName, 0, dims.y)
    self._fillChild = fillName

    local label = self.label
    if label ~= nil then
        label._model.OnLButtonDown = label._model.OnLButtonDown or
            self._model.OnLButtonDown
        label._model.OnLButtonUp = label._model.OnLButtonUp or
            self._model.OnLButtonUp
        label._model.OnRButtonDown = label._model.OnRButtonDown or
            self._model.OnRButtonDown
        label._model.OnRButtonUp = label._model.OnRButtonUp or
            self._model.OnRButtonUp

        label:create(true)
        label:onInitialize()
        label:setParent(self:getParent())

        local dimens = self:getDimensions()
        label:setDimensions(dimens.x, dimens.y)
        label:centerText()

        label:clearAnchors()
        label:addAnchor(
            "center",
            self:getName(),
            "center",
            0,
            0
        )
    end
end

function StatusBar:_updateFill()
    if not self._fillChild then return end
    local maxVal = self._maxValue or 0
    local curVal = self._currentValue or 0
    local dims = self:getDimensions()
    local barWidth = dims.x
    local barHeight = dims.y
    if maxVal > 0 and curVal > 0 then
        local fillWidth = math.floor(barWidth * math.min(curVal, maxVal) / maxVal)
        fillWidth = math.max(fillWidth, 1)
        Api.Window.SetDimensions(self._fillChild, fillWidth, barHeight)
        Api.Window.SetShowing(self._fillChild, true)
    else
        Api.Window.SetShowing(self._fillChild, false)
    end
end

function StatusBar:onDimensionsChanged(width, height)
    if self.label ~= nil then
        self.label:setDimensions(width, height)
    end
    self:_updateFill()
end

function StatusBar:onShutdown()
    if self._fillChild and Api.Window.DoesExist(self._fillChild) then
        Api.Window.Destroy(self._fillChild)
    end
    if self.label ~= nil then
        self.label:destroy()
    end
    View.onShutdown(self)
end

function StatusBar:setMaxValue(maxValue)
    self._maxValue = maxValue
    Api.StatusBar.SetMaxValue(self:getName(), maxValue)
    self:_updateFill()
end

function StatusBar:setCurrentValue(currentValue)
    self._currentValue = currentValue
    Api.StatusBar.SetCurrentValue(self:getName(), currentValue)
    self:_updateFill()
end

function StatusBar:setColor(color)
    if self._fillChild then
        Api.Window.SetColor(self._fillChild, color)
    end
end

function StatusBar:setBackgroundTint(tint)
    Api.StatusBar.SetBackgroundTint(self:getName(), tint)
end

function StatusBar:setForegroundTint(tint)
    if self._fillChild then
        Api.Window.SetColor(self._fillChild, tint)
    end
end

---@param model StatusBarModel?
---@param labelModel LabelModel?
---@return StatusBar
function Components.StatusBar(model, labelModel)
    local label

    if labelModel ~= nil then
        label = Components.Label(labelModel)
    end

    local statusBar = StatusBar:new(model, label)
    Cache[statusBar:getName()] = statusBar
    return statusBar
end

-- ========================================================================== --
-- Components - Slider Bar
-- ========================================================================== --

---@param model SliderBarModel?
---@return SliderBar
function SliderBar:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatSliderBar"
    local instance = View.new(self, model)
    return instance --[[@as SliderBar]]
end

---@param position number A value between 0 and 1 representing the slider position.
---@return SliderBar
function SliderBar:setCurrentPosition(position)
    Api.Slider.SetCurrentPosition(self:getName(), position)
    return self
end

---@return number A value between 0 and 1 representing the current slider position.
function SliderBar:getCurrentPosition()
    return Api.Slider.GetCurrentPosition(self:getName())
end

---@param model SliderBarModel?
---@return SliderBar
function Components.SliderBar(model)
    local sliderBar = SliderBar:new(model)
    Cache[sliderBar:getName()] = sliderBar
    return sliderBar
end

-- ========================================================================== --
-- Components - ComboBox
-- ========================================================================== --

---@param model ComboBoxModel?
---@return ComboBox
function ComboBox:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatComboBox"
    local instance = View.new(self, model)
    return instance --[[@as ComboBox]]
end

---@param item wstring The item to add.
---@return ComboBox
function ComboBox:addItem(item)
    Api.ComboBox.AddItem(self:getName(), item)
    return self
end

---@return ComboBox
function ComboBox:clearItems()
    Api.ComboBox.ClearItems(self:getName())
    return self
end

---@param item wstring The item to select.
---@return ComboBox
function ComboBox:setSelectedItem(item)
    Api.ComboBox.SetSelectedItem(self:getName(), item)
    return self
end

---@return wstring The currently selected item.
function ComboBox:getSelectedItem()
    return Api.ComboBox.GetSelectedItem(self:getName())
end

---@param model ComboBoxModel?
---@return ComboBox
function Components.ComboBox(model)
    local comboBox = ComboBox:new(model)
    Cache[comboBox:getName()] = comboBox
    return comboBox
end

-- ========================================================================== --
-- Components - List Box
-- ========================================================================== --

---@param model ListBoxModel?
---@return ListBox
function ListBox:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatListBox"
    local instance = View.new(self, model)
    return instance --[[@as ListBox]]
end

---@param data table The data table to populate the list box from.
---@return ListBox
function ListBox:setDataTable(data)
    Api.ListBox.SetDataTable(self:getName(), data)
    return self
end

---@param rowIndex number The 1-based visual row index.
---@return number The data index for that row.
function ListBox:getDataIndex(rowIndex)
    return Api.ListBox.GetDataIndex(self:getName(), rowIndex)
end

---@param orderArray table Array of data indices controlling display order.
---@return ListBox
function ListBox:setDisplayOrder(orderArray)
    Api.ListBox.SetDisplayOrder(self:getName(), orderArray)
    return self
end

---@param count number The number of visible rows.
---@return ListBox
function ListBox:setVisibleRowCount(count)
    Api.ListBox.SetVisibleRowCount(self:getName(), count)
    return self
end

--- Gets the engine-managed PopulatorIndices table that maps visible row indices to data indices.
--- Populated by the engine after each display update (scroll, display order change, etc.).
---@return table? The PopulatorIndices array, or nil if not populated.
function ListBox:getPopulatorIndices()
    return Api.ListBox.GetPopulatorIndices(self:getName())
end

--- Gets the engine-managed number of visible rows.
---@return number The number of visible rows.
function ListBox:getNumVisibleRows()
    return Api.ListBox.GetNumVisibleRows(self:getName())
end

--- Constructs the window name for a row element in this list box.
--- Rows are named "{ListBoxName}Row{index}" with optional child suffixes.
---@param rowIndex number The 1-based row index.
---@param childName string? Optional child window suffix (e.g., "Text", "CheckBox").
---@return string The full window name for the row or child within the row.
function ListBox:getRowName(rowIndex, childName)
    local name = self:getName() .. "Row" .. tostring(rowIndex)
    if childName then
        name = name .. childName
    end
    return name
end

--- Determines which row was clicked by inspecting the mouse-over window name.
--- Call this inside an OnLButtonDown/OnLButtonUp handler to find the clicked row.
--- Returns the 1-based visual row index, or nil if the click was not on a row.
---@return number? rowIndex The 1-based visual row index, or nil.
function ListBox:getClickedRowIndex()
    local mouseOverWindow = SystemData.MouseOverWindow
    if mouseOverWindow == nil then return nil end
    local mouseName = mouseOverWindow.name
    if mouseName == nil or mouseName == "" then return nil end
    -- Row windows are named "{ListBoxName}Row{index}" or "{ListBoxName}Row{index}{ChildName}"
    local prefix = self:getName() .. "Row"
    local prefixLen = string.len(prefix)
    if string.sub(mouseName, 1, prefixLen) ~= prefix then return nil end
    local rest = string.sub(mouseName, prefixLen + 1)
    -- Extract the leading digits from rest
    local digits = string.match(rest, "^(%d+)")
    if digits == nil then return nil end
    return tonumber(digits)
end

--- Determines which data index was clicked by inspecting the mouse-over window.
--- Combines getClickedRowIndex() with getDataIndex() for convenience.
--- Returns the data-table index, or nil if the click was not on a row.
---@return number? dataIndex The data-table index, or nil.
function ListBox:getClickedDataIndex()
    local rowIndex = self:getClickedRowIndex()
    if rowIndex == nil then return nil end
    return self:getDataIndex(rowIndex)
end

--- Alias for getClickedDataIndex() for use in OnMouseOver handlers.
--- Both rely on SystemData.MouseOverWindow to identify the row under the cursor,
--- but this name better communicates the hover-without-click context.
---@return number? dataIndex The data-table index of the hovered row, or nil.
function ListBox:getHoveredDataIndex()
    return self:getClickedDataIndex()
end

--- Iterates over all visible rows, calling the callback with the visual
--- row index and the corresponding data index for each row.
--- Empty rows (no backing data) receive a data index of 0.
--- If the visible row count is not yet known, this is a no-op.
---@param callback fun(rowIndex: number, dataIndex: number)
function ListBox:forEachRow(callback)
    local numRows = self:getNumVisibleRows()
    if not numRows then return end
    for rowIndex = 1, numRows do
        callback(rowIndex, self:getDataIndex(rowIndex) or 0)
    end
end

--- Override View:onShutdown to clean up the global data table entry
--- that the engine requires for list box data binding.
function ListBox:onShutdown()
    Api.ListBox.ClearDataTable(self:getName())
    View.onShutdown(self)
end

---@param model ListBoxModel?
---@return ListBox
function Components.ListBox(model)
    local listBox = ListBox:new(model)
    Cache[listBox:getName()] = listBox
    return listBox
end

-- ========================================================================== --
-- Components - CheckBox
-- ========================================================================== --

---@param model CheckBoxModel?
---@param label Label?
---@return CheckBox
function CheckBox:new(model, label)
    model = model or {}
    model.Template = model.Template or "MongbatCheckBox"
    local instance = View.new(self, model) --[[@as CheckBox]]
    instance.label = label
    return instance
end

function CheckBox:onInitialize()
    View.onInitialize(self)

    Api.Button.SetEnabled(self:getName(), true)
    Api.Button.SetStayDown(self:getName(), true)

    local label = self.label
    if label ~= nil then
        local checkBox = self
        -- Always wrap OnLButtonDown so label clicks always toggle the checkbox
        -- even when the labelModel already defined its own OnLButtonDown.
        local existingLDown = label._model.OnLButtonDown
        label._model.OnLButtonDown = function(labelSelf, flags, x, y)
            checkBox:setChecked(not checkBox:isChecked())
            if existingLDown ~= nil then
                existingLDown(labelSelf, flags, x, y)
            end
        end
        -- Always wrap OnLButtonUp so label releases propagate to the checkbox
        -- OnLButtonUp handler, chaining any handler the labelModel provided.
        local existingLUp = label._model.OnLButtonUp
        label._model.OnLButtonUp = function(labelSelf, flags, x, y)
            if checkBox._model.OnLButtonUp ~= nil then
                checkBox._model.OnLButtonUp(checkBox, flags, x, y)
            end
            if existingLUp ~= nil then
                existingLUp(labelSelf, flags, x, y)
            end
        end

        label:create(true)
        label:onInitialize()
        label:setParent(self:getParent())

        local dims = self:getDimensions()
        label:clearAnchors()
        label:addAnchor("left", self:getName(), "right", 4, 0)
        label:setDimensions(label:getDimensions().x, dims.y)
        label:centerText()
    end
end

function CheckBox:onShutdown()
    if self.label ~= nil then
        self.label:destroy()
    end
    View.onShutdown(self)
end

---@param isChecked boolean
---@return CheckBox
function CheckBox:setChecked(isChecked)
    Api.Button.SetChecked(self:getName(), isChecked)
    return self
end

---@return boolean
function CheckBox:isChecked()
    return Api.Button.IsChecked(self:getName())
end

--- Toggles the checked state.
---@return CheckBox
function CheckBox:toggle()
    self:setChecked(not self:isChecked())
    return self
end

---@param model CheckBoxModel?
---@param labelModel LabelModel?
---@return CheckBox
function Components.CheckBox(model, labelModel)
    local label

    if labelModel ~= nil then
        label = Components.Label(labelModel)
    end

    local checkBox = CheckBox:new(model, label)
    Cache[checkBox:getName()] = checkBox
    return checkBox
end

-- ========================================================================== --
-- Components - Animated Image
-- ========================================================================== --

---@param model AnimatedImageModel?
---@return AnimatedImage
function AnimatedImage:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatAnimatedImage"
    local instance = View.new(self, model) --[[@as AnimatedImage]]
    return instance
end

--- Sets the texture for this animated image.
---@param texture string The texture name.
---@return AnimatedImage
function AnimatedImage:setTexture(texture)
    Api.AnimatedImage.SetTexture(self:getName(), texture)
    return self
end

--- Starts the animation.
---@param startFrame number? The frame to start from (default 1).
---@param loop boolean? Whether to loop (default false).
---@param hideWhenDone boolean? Whether to hide when finished (default false).
---@param delay number? Delay before starting (default 0).
---@return AnimatedImage
function AnimatedImage:startAnimation(startFrame, loop, hideWhenDone, delay)
    Api.AnimatedImage.StartAnimation(
        self:getName(),
        startFrame or 1,
        loop or false,
        hideWhenDone or false,
        delay or 0
    )
    return self
end

--- Stops the animation.
---@return AnimatedImage
function AnimatedImage:stopAnimation()
    Api.AnimatedImage.StopAnimation(self:getName())
    return self
end

--- Sets the animation playback speed.
---@param fps number The frames per second.
---@return AnimatedImage
function AnimatedImage:setPlaySpeed(fps)
    Api.AnimatedImage.SetPlaySpeed(self:getName(), fps)
    return self
end

---@param model AnimatedImageModel?
---@return AnimatedImage
function Components.AnimatedImage(model)
    local animatedImage = AnimatedImage:new(model)
    Cache[animatedImage:getName()] = animatedImage
    return animatedImage
end

-- ========================================================================== --
-- Components - Action Button
-- ========================================================================== --

---@param model ActionButtonModel?
---@return ActionButton
function ActionButton:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatActionButton"
    local instance = Button.new(self, model) --[[@as ActionButton]]
    return instance
end

--- Sets the game action on this button.
---@param actionType number The action type.
---@param actionId number The action ID.
---@return ActionButton
function ActionButton:setAction(actionType, actionId)
    Api.ActionButton.SetAction(self:getName(), actionType, actionId)
    return self
end

--- Gets the action data from this button.
---@return any The game action button data.
function ActionButton:getAction()
    return Api.ActionButton.GetAction(self:getName())
end

--- Sets the game action trigger for this button.
---@param action any The action trigger value.
---@return ActionButton
function ActionButton:setGameActionTrigger(action)
    Api.ActionButton.SetGameActionTrigger(self:getName(), action)
    return self
end

---@param model ActionButtonModel?
---@return ActionButton
function Components.ActionButton(model)
    local actionButton = ActionButton:new(model)
    Cache[actionButton:getName()] = actionButton
    return actionButton
end

-- ========================================================================== --
-- Components - Action Button Group
-- ========================================================================== --

---@param model ActionButtonGroupModel?
---@return ActionButtonGroup
function ActionButtonGroup:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatWindow"
    local instance = Window.new(self, model) --[[@as ActionButtonGroup]]
    instance._buttons = {}
    return instance
end

function ActionButtonGroup:onInitialize()
    Window.onInitialize(self)

    local count = self._model.Count or 12
    local buttonSize = self._model.ButtonSize or 50
    local spacing = self._model.Spacing or 0
    local group = self

    for i = 1, count do
        local button = Components.ActionButton {
            Name = self:getName() .. "Button" .. i,
            Id = i,
            OnLButtonDown = function(btn, flags, x, y)
                if group._model.OnButtonLButtonDown then
                    group._model.OnButtonLButtonDown(group, btn, i, flags, x, y)
                end
            end,
            OnLButtonUp = function(btn, flags, x, y)
                if group._model.OnButtonLButtonUp then
                    group._model.OnButtonLButtonUp(group, btn, i, flags, x, y)
                end
            end,
            OnRButtonUp = function(btn, flags, x, y)
                if group._model.OnButtonRButtonUp then
                    group._model.OnButtonRButtonUp(group, btn, i, flags, x, y)
                end
            end,
            OnMouseOver = function(btn)
                if group._model.OnButtonMouseOver then
                    group._model.OnButtonMouseOver(group, btn, i)
                end
            end,
            OnMouseOverEnd = function(btn)
                if group._model.OnButtonMouseOverEnd then
                    group._model.OnButtonMouseOverEnd(group, btn, i)
                end
            end,
        }
        button:create(true)
        button:onInitialize()
        button:setParent(self:getName())
        button:setDimensions(buttonSize, buttonSize)
        button:clearAnchors()
        if i == 1 then
            button:addAnchor("topleft", self:getName(), "topleft", 0, 0)
        else
            button:addAnchor("topleft", self._buttons[i - 1]:getName(), "topright", spacing, 0)
        end
        self._buttons[i] = button
    end
end

function ActionButtonGroup:onShutdown()
    Utils.Array.ForEach(self._buttons, function(button)
        button:destroy()
    end)
    self._buttons = {}
    Window.onShutdown(self)
end

--- Gets the action button at the given 1-based index.
---@param index number The 1-based button index.
---@return ActionButton?
function ActionButtonGroup:getButton(index)
    return self._buttons[index]
end

--- Gets the total number of buttons in the group.
---@return number
function ActionButtonGroup:getButtonCount()
    return #self._buttons
end

---@param model ActionButtonGroupModel?
---@return ActionButtonGroup
function Components.ActionButtonGroup(model)
    local group = ActionButtonGroup:new(model)
    Cache[group:getName()] = group
    return group
end

-- ========================================================================== --
-- Components - Cooldown Display
-- ========================================================================== --

---@param model CooldownDisplayModel?
---@return CooldownDisplay
function CooldownDisplay:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatCooldownDisplay"
    local instance = AnimatedImage.new(self, model) --[[@as CooldownDisplay]]
    return instance
end

--- Plays the cooldown animation overlay.
---@param loop boolean? Whether to loop (default false).
---@param hideWhenDone boolean? Whether to hide when finished (default false).
---@return CooldownDisplay
function CooldownDisplay:play(loop, hideWhenDone)
    self:startAnimation(1, loop or false, hideWhenDone or false, 0)
    return self
end

--- Stops the cooldown animation.
---@return CooldownDisplay
function CooldownDisplay:stop()
    self:stopAnimation()
    return self
end

---@param model CooldownDisplayModel?
---@return CooldownDisplay
function Components.CooldownDisplay(model)
    local cooldownDisplay = CooldownDisplay:new(model)
    Cache[cooldownDisplay:getName()] = cooldownDisplay
    return cooldownDisplay
end

-- ========================================================================== --
-- Components - Dockable Window
-- ========================================================================== --

---@param model DockableWindowModel?
---@return DockableWindow
function DockableWindow:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatWindow"
    local instance = Window.new(self, model) --[[@as DockableWindow]]
    return instance
end

function DockableWindow:onInitialize()
    Window.onInitialize(self)
    self:restorePosition(false)
end

function DockableWindow:onShutdown()
    Api.Window.SavePosition(self:getName(), true, self:getName())
    Window.onShutdown(self)
end

--- Restores a previously saved position.
---@param trackSize boolean? Whether to also restore size (default false).
---@return DockableWindow
function DockableWindow:restorePosition(trackSize)
    Api.Window.RestorePosition(self:getName(), trackSize or false, self:getName())
    return self
end

---@param model DockableWindowModel?
---@return DockableWindow
function Components.DockableWindow(model)
    local dockableWindow = DockableWindow:new(model)
    Cache[dockableWindow:getName()] = dockableWindow
    return dockableWindow
end

-- ========================================================================== --
-- Components - Page Window
-- ========================================================================== --

---@param model PageWindowModel?
---@return PageWindow
function PageWindow:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatPageWindow"
    local instance = View.new(self, model) --[[@as PageWindow]]
    return instance
end

--- Sets the currently visible page.
---@param pageNumber number The 1-based page number.
---@return PageWindow
function PageWindow:setActivePage(pageNumber)
    Api.PageWindow.SetActivePage(self:getName(), pageNumber)
    return self
end

--- Gets the currently visible page number.
---@return number
function PageWindow:getActivePage()
    return Api.PageWindow.GetActivePage(self:getName())
end

--- Gets the total number of pages.
---@return number
function PageWindow:getNumPages()
    return Api.PageWindow.GetNumPages(self:getName())
end

--- Advances to the next page. Wraps around to the first page when at the end.
---@return PageWindow
function PageWindow:nextPage()
    local current = self:getActivePage()
    local total = self:getNumPages()
    if current < total then
        self:setActivePage(current + 1)
    else
        self:setActivePage(1)
    end
    return self
end

--- Goes to the previous page. Wraps around to the last page when at the start.
---@return PageWindow
function PageWindow:previousPage()
    local current = self:getActivePage()
    local total = self:getNumPages()
    if current > 1 then
        self:setActivePage(current - 1)
    else
        self:setActivePage(total)
    end
    return self
end

---@param model PageWindowModel?
---@return PageWindow
function Components.PageWindow(model)
    local pageWindow = PageWindow:new(model)
    Cache[pageWindow:getName()] = pageWindow
    return pageWindow
end


---@param model ViewModel
---@return View
function View:new(model)
    local name = model.Name or Utils.String.Random()
    local instance = Component.new(self, name) --[[@as View]]
    instance._model = model
    return instance
end

function View:onInitialize()
    local id = self._model.Id or Utils.String.ExtractNumber(self:getName())
    self:setId(id)

    local prefix = "Mongbat.EventHandler."

    for k, _ in pairs(self._model) do
        local systemEvent = Constants.SystemEvents[k]
        local isCore = Constants.CoreEvents[k] ~= nil
        local dataEvent = Constants.DataEvents[k]
        local skip = k == Constants.CoreEvents.OnInitialize or
            k == Constants.CoreEvents.OnShutdown

        local functionName = prefix .. k

        if isCore and not skip then
            self:registerCoreEventHandler(k, functionName)
        elseif systemEvent ~= nil then
            self:registerEventHandler(systemEvent.getEvent(), functionName)
        elseif dataEvent ~= nil then
            self:registerEventHandler(dataEvent.getEvent(), functionName)
        end
    end

    self:registerCoreEventHandler(
        Constants.CoreEvents.OnShutdown,
        prefix .. Constants.CoreEvents.OnShutdown
    )

    if self._model.OnInitialize ~= nil then
        self._model.OnInitialize(self)
    end

    pcall(function ()
        self:onUpdatePlayerStatus()
        self:onUpdateMobileName()
        self:onUpdateMobileStatus()
        self:onUpdateHealthBarColor()
        self:onUpdatePaperdoll()
    end)
end

function View:onShutdown()
    if self._model.OnShutdown ~= nil then
        self._model.OnShutdown(self)
    end

    self:setId(0)

    for k, _ in pairs(self._model) do
        local systemEvent = Constants.SystemEvents[k]
        local dataEvent = Constants.DataEvents[k]
        local isCore = k == Constants.CoreEvents.OnInitialize or
            k == Constants.CoreEvents.OnShutdown

        if isCore then
            self:unregisterCoreEventHandler(k)
        elseif systemEvent ~= nil then
            self:unregisterEventHandler(systemEvent.getEvent())
        elseif dataEvent ~= nil then
            self:unregisterEventHandler(dataEvent.getEvent())
        end
    end
end

function View:onLButtonUp(flags, x, y)
    if self._model.OnLButtonUp ~= nil then
        self._model.OnLButtonUp(self, flags, x, y)
        return true
    end
    return false
end

function View:onMouseWheel(x, y, delta)
    if self._model.OnMouseWheel ~= nil then
        self._model.OnMouseWheel(self, x, y, delta)
        return true
    end
    return false
end

function View:onLButtonDown(flags, x, y)
    if self._model.OnLButtonDown ~= nil then
        self._model.OnLButtonDown(self, flags, x, y)
        return true
    end
    return false
end

function View:onRButtonUp(flags, x, y)
    if self._model.OnRButtonUp ~= nil then
        self._model.OnRButtonUp(self, flags, x, y)
        return true
    end
    return false
end

function View:onRButtonDown(flags, x, y)
    if self._model.OnRButtonDown ~= nil then
        self._model.OnRButtonDown(self, flags, x, y)
        return true
    end
    return false
end

function View:onHidden()
    if self._model.OnHidden ~= nil then
        self._model.OnHidden(self)
        return true
    end
    return false
end

function View:onShown()
    if self._model.OnShown ~= nil then
        self._model.OnShown(self)
        return true
    end
    return false
end

function View:onUpdate(timePassed, windowData)
    if self._model.OnUpdate ~= nil then
        self._model.OnUpdate(self, timePassed, windowData)
    end
    return true
end

function View:onUpdateMobileName()
    if self._model.OnUpdateMobileName ~= nil then
        self._model.OnUpdateMobileName(self, Data.MobileName(self:getId()))
        return true
    end
    return false
end

function View:onUpdatePlayerStatus()
    if self._model.OnUpdatePlayerStatus ~= nil then
        self._model.OnUpdatePlayerStatus(self, Data.PlayerStatus())
        return true
    end
    return false
end

function View:onUpdateHealthBarColor()
    if self._model.OnUpdateHealthBarColor ~= nil then
        self._model.OnUpdateHealthBarColor(self, Data.HealthBarColor(self:getId()))
        return true
    end
    return false
end

function View:onUpdateMobileStatus()
    if self._model.OnUpdateMobileStatus ~= nil then
        self._model.OnUpdateMobileStatus(self, Data.MobileStatus(self:getId()))
        return true
    end
    return false
end

function View:onUpdatePaperdoll()
    if self._model.OnUpdatePaperdoll ~= nil then
        self._model.OnUpdatePaperdoll(self, Data.Paperdoll(self:getId()))
        return true
    end
    return false
end

function View:onUpdateShopData()
    if self._model.OnUpdateShopData ~= nil then
        self._model.OnUpdateShopData(self, Data.ShopData())
        return true
    end
    return false
end

function View:onUpdateContainerWindow()
    if self._model.OnUpdateContainerWindow ~= nil then
        local instanceId = Api.Window.GetUpdateInstanceId()
        self._model.OnUpdateContainerWindow(self, instanceId, Data.ContainerWindow(instanceId))
        return true
    end
    return false
end

function View:onUpdateObjectInfo()
    if self._model.OnUpdateObjectInfo ~= nil then
        local instanceId = Api.Window.GetUpdateInstanceId()
        self._model.OnUpdateObjectInfo(self, instanceId, Data.ObjectInfo(instanceId))
        return true
    end
    return false
end

function View:onUpdateItemProperties()
    if self._model.OnUpdateItemProperties ~= nil then
        local instanceId = Api.Window.GetUpdateInstanceId()
        self._model.OnUpdateItemProperties(self, instanceId, Data.ItemProperties(instanceId))
        return true
    end
    return false
end

function View:onLButtonDblClk(flags, x, y)
    if self._model.OnLButtonDblClk ~= nil then
        self._model.OnLButtonDblClk(self, flags, x, y)
        return true
    end
    return false
end

function View:onMouseOver()
    if self._model.OnMouseOver ~= nil then
        self._model.OnMouseOver(self)
        return true
    end
    return false
end

function View:onMouseOverEnd()
    if self._model.OnMouseOverEnd ~= nil then
        self._model.OnMouseOverEnd(self)
        return true
    end
    return false
end

function View:onEndHealthBarDrag()
    if self._model.OnEndHealthBarDrag ~= nil then
        self._model.OnEndHealthBarDrag(self)
        return true
    end
    return false
end

---@param data WindowData.Radar
function View:onUpdateRadar(data)
    if self._model.OnUpdateRadar ~= nil then
        self._model.OnUpdateRadar(self, data)
        return true
    end
    return false
end

function View:onUpdatePlayerLocation(data)
    if self._model.OnUpdatePlayerLocation ~= nil then
        self._model.OnUpdatePlayerLocation(self, data)
        return true
    end
    return false
end

function View:onTextChanged(text)
    if self._model.OnTextChanged ~= nil then
        self._model.OnTextChanged(self, text)
        return true
    end
    return false
end

function View:onKeyEnter()
    if self._model.OnKeyEnter ~= nil then
        self._model.OnKeyEnter(self)
        return true
    end
    return false
end

function View:onKeyEscape()
    if self._model.OnKeyEscape ~= nil then
        self._model.OnKeyEscape(self)
        return true
    end
    return false
end

function View:onKeyRecorded()
    if self._model.OnKeyRecorded ~= nil then
        self._model.OnKeyRecorded(self)
        return true
    end
    return false
end

function View:onSlide()
    if self._model.OnSlide ~= nil then
        self._model.OnSlide(self, Api.Slider.GetCurrentPosition(self:getName()))
        return true
    end
    return false
end

function View:onKeyCancelRecord()
    if self._model.OnKeyCancelRecord ~= nil then
        self._model.OnKeyCancelRecord(self)
    end
end

function View:onUserSettingsUpdated()
    if self._model.OnUserSettingsUpdated ~= nil then
        self._model.OnUserSettingsUpdated(self)
    end
end

function View:onToggleUserPreference()
    if self._model.OnToggleUserPreference ~= nil then
        self._model.OnToggleUserPreference(self)
    end
end

function View:onSelChanged()
    if self._model.OnSelChanged ~= nil then
        self._model.OnSelChanged(self)
        return true
    end
    return false
end

function View:onPopulateRow()
    if self._model.OnPopulateRow ~= nil then
        self._model.OnPopulateRow(self)
        return true
    end
    return false
end

function View:getId()
    return Api.Window.GetId(self.name)
end

function View:setId(id)
    id = id or 0
    local oldId = self:getId()

    if oldId == id then
        return
    end

    if oldId ~= 0 then
        for k, _ in pairs(self._model) do
            local dataEvent = Constants.DataEvents[k]
            if dataEvent ~= nil then
                local skip = dataEvent == Constants.DataEvents.OnUpdatePlayerStatus or
                    dataEvent == Constants.DataEvents.OnUpdateRadar or
                    dataEvent == Constants.DataEvents.OnUpdatePlayerLocation or
                    dataEvent == Constants.DataEvents.OnUpdateShopData or
                    dataEvent == Constants.DataEvents.OnUpdateContainerWindow or
                    dataEvent == Constants.DataEvents.OnUpdateObjectInfo or
                    dataEvent == Constants.DataEvents.OnUpdateItemProperties

                if not skip then
                    Api.Window.UnregisterData(dataEvent.getType(), oldId)
                end
            end
        end
    end

    if id ~= 0 then
        for k, _ in pairs(self._model) do
            local dataEvent = Constants.DataEvents[k]
            if dataEvent ~= nil then
                local skip = dataEvent == Constants.DataEvents.OnUpdatePlayerStatus or
                    dataEvent == Constants.DataEvents.OnUpdateRadar or
                    dataEvent == Constants.DataEvents.OnUpdatePlayerLocation or
                    dataEvent == Constants.DataEvents.OnUpdateShopData or
                    dataEvent == Constants.DataEvents.OnUpdateContainerWindow or
                    dataEvent == Constants.DataEvents.OnUpdateObjectInfo or
                    dataEvent == Constants.DataEvents.OnUpdateItemProperties

                if not skip then
                    Api.Window.RegisterData(dataEvent.getType(), id)
                end
            end
        end
    end

    Api.Window.SetId(self.name, id)
end

function View:setHandleInput(handleInput)
    Api.Window.SetHandleInput(self.name, handleInput)
end

function View:getParent()
    return Api.Window.GetParent(self.name)
end

function View:setParent(parent)
    Api.Window.SetParent(self.name, parent)
end

function View:matchParentWidth(percent)
    local parent = self:getParent()
    local parentDimen = Api.Window.GetDimensions(parent)
    local dimen = self:getDimensions()
    self:setDimensions(parentDimen.x * percent, dimen.y)
end

function View:registerCoreEventHandler(event, callback)
    Api.Window.RegisterCoreEventHandler(self.name, event, callback)
end

function View:unregisterCoreEventHandler(event)
    Api.Window.UnregisterCoreEventHandler(self.name, event)
end

function View:registerEventHandler(event, callback)
    Api.Window.RegisterEventHandler(self.name, event, callback)
end

function View:unregisterEventHandler(event)
    Api.Window.UnregisterEventHandler(self.name, event)
end

function View:isMoving()
    return Api.Window.IsMoving(self.name)
end

function View:setMoving(isMoving)
    Api.Window.SetMoving(self.name, isMoving)
    return self
end

function View:getDimensions()
    return Api.Window.GetDimensions(self.name)
end

function View:setDimensions(x, y)
    local current = Api.Window.GetDimensions(self.name)
    if current.x == x and current.y == y then
        return self
    end
    Api.Window.SetDimensions(self.name, x, y)
    self:onDimensionsChanged(x, y)
    return self
end

--- Called whenever this view's dimensions are set. Override in subclasses to
--- propagate size changes to internal sub-components (e.g. StatusBar's label).
---@param width number
---@param height number
function View:onDimensionsChanged(width, height)
    if self._model.OnDimensionsChanged ~= nil then
        self._model.OnDimensionsChanged(self, width, height)
    end
end

function View:getAlpha()
    return Api.Window.GetAlpha(self.name)
end

function View:setAlpha(alpha)
    Api.Window.SetAlpha(self.name, alpha)
    return self
end

function View:setLayer()
    return LayerBuilder:new(function()
        return self
    end)
end

function View:getScale()
    return Api.Window.GetScale(self.name)
end

function View:setScale(scale)
    Api.Window.SetScale(self.name, scale)
    return self
end

function View:getOffsetFromParent()
    return Api.Window.GetOffsetFromParent(self.name)
end

function View:setOffsetFromParent(x, y)
    Api.Window.SetOffsetFromParent(self.name, x, y)
    return self
end

function View:getColor()
    return Api.Window.GetColor(self.name)
end

function View:setColor(color)
    Api.Window.SetColor(self.name, color)
    return self
end

function View:getPosition()
    return Api.Window.GetPosition(self.name)
end

function View:isShowing()
    return Api.Window.IsShowing(self.name)
end

function View:setShowing(isShowing)
    Api.Window.SetShowing(self.name, isShowing)
    return self
end

function View:isPopable()
    return Api.Window.IsPopable(self.name)
end

function View:setPopable(isPopable)
    Api.Window.SetPopable(self.name, isPopable)
    return self
end

function View:isMovable()
    return Api.Window.IsMovable(self.name)
end

function View:setMovable(isMovable)
    Api.Window.SetMovable(self.name, isMovable)
    return self
end

function View:isSticky()
    return Api.Window.IsSticky(self.name)
end

function View:clearAnchors()
    Api.Window.ClearAnchors(self.name)
end

function View:forceProcessAnchors()
    Api.Window.ForceProcessAnchors(self.name)
    return self
end

function View:addAnchor(anchorPoint, relativeTo, relativePoint, x, y)
    Api.Window.AddAnchor(self.name, anchorPoint, relativeTo, relativePoint, x or 0, y or 0)
end

function View:anchorToParentTop(x, y)
    self:addAnchor(
        Constants.AnchorPoints.Top,
        self:getParent(),
        Constants.AnchorPoints.Top,
        x or 0,
        y or 0
    )
end

function View:centerInWindow(toCenter, x, y)
    self:addAnchor(
        Constants.AnchorPoints.Center,
        toCenter or self:getParent(),
        Constants.AnchorPoints.Center,
        x or 0,
        y or 0
    )
end

function View:anchorToParentCenter(x, y)
    self:centerInWindow(self:getParent(), x, y)
end

function View:isFocused()
    return Api.Window.HasFocus(self.name)
end

function View:setFocus(doFocus)
    Api.Window.AssignFocus(self.name, doFocus)
end

function View:isResizing()
    return Api.Window.IsResizing(self.name)
end

function View:setResizing(isResizing)
    Api.Window.SetResizing(self.name, isResizing)
end

function View:setRelativeScale(scale)
    Api.Window.SetRelativeScale(self.name, scale)
end

function View:doesExist()
    return Api.Window.DoesExist(self.name)
end

function View:destroy()
    return Api.Window.Destroy(self.name)
end

---@param doShow boolean? Whether to show the window after creation (default true).
---@param parent string? The parent window name (default "Root").
function View:create(doShow, parent)
    doShow = doShow == nil or doShow
    parent = parent or "Root"
    if self._model.Template == nil then
        return Api.Window.Create(self.name, doShow)
    else
        return Api.Window.CreateFromTemplate(self.name, self._model.Template, parent, doShow)
    end
end

function View:registerData(type)
    local id = self:getId()
    Api.Window.RegisterData(type, id)
end

function View:unregisterData(type)
    local id = self:getId()
    Api.Window.UnregisterData(type, id)
end

function View:isParentRoot()
    return self:getParent() == "Root"
end

--- Creates a generic View from a model table. Use this for lightweight
--- template-based elements that need event handling but do not require
--- the frame/background chrome of a Window or the specialised API of
--- Label, Button, etc.
---@param model ViewModel?
---@return View
function Components.View(model)
    model = model or {}
    local view = View:new(model) --[[@as View]]
    Cache[view:getName()] = view
    return view
end

-- ========================================================================== --
-- Components - Window
-- ========================================================================== --

---@param model WindowModel?
function Window:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatWindow"
    local instance = View.new(self, model) --[[@as Window]]

    instance._children = {}
    instance._frame = instance.name .. "Frame"
    instance._background = instance.name .. "Background"
    instance._startDrag = { x = -1, y = -1 }

    instance._model.OnLayout = model.OnLayout or Layouts.StackAndFill

    return instance
end

function Window:onInitialize()
    self:toggleBackground(false)
    self:toggleFrame(false)
    View.onInitialize(self)
    self:_initializeChildren()
end

--- Wraps each child's event handlers to propagate to this parent, then
--- creates and initialises every child window. Called by both Window and
--- Scaffold during their onInitialize.
function Window:_initializeChildren()
    Utils.Array.ForEach(
        self._children,
        function(item, index)
            -- Guard against double-wrapping if onInitialize is called more than once
            if item._parentWrapped then
                item:create(nil, self:getName())
                item:onInitialize()
                return
            end
            item._parentWrapped = true

            --- For each child, override its onInitialize to clear anchors and layout.
            --- Children are created directly at the parent window (see item:create
            --- below), so no reparent step is needed. This preserves anchor
            --- relationships inside XML templates (e.g. ListBox scrollbars).
            local onChildInitialize = item._model.OnInitialize

            item._model.OnInitialize = function(child)
                child:clearAnchors()
                self._model.OnLayout(self, self._children, child, index)
                if onChildInitialize ~= nil then
                    onChildInitialize(child)
                end
            end

            local onChildRButtonUp = item._model.OnRButtonUp

            --- For each child propagate the onRButtonUp event to the parent
            --- This is to allow closing the parent window when right-clicking on any child
            item._model.OnRButtonUp = function(child, flags, x, y)
                self:onRButtonUp(flags, x, y)
                if onChildRButtonUp ~= nil then
                    onChildRButtonUp(child, flags, x, y)
                end
            end

            local onChildLButtonDown = item._model.OnLButtonDown

            --- For each child propagate the onLButtonDown event to the parent
            --- This is to allow moving the parent window when left-clicking on any child
            item._model.OnLButtonDown = function(child, flags, x, y)
                if onChildLButtonDown ~= nil then
                    onChildLButtonDown(child, flags, x, y)
                end
                self:onLButtonDown(flags, x, y)
            end

            local onChildLButtonUp = item._model.OnLButtonUp

            --- For each child propagate the onLButtonUp event to the parent
            --- This is to allow stopping moving the parent window when releasing left-click on any child
            item._model.OnLButtonUp = function(child, flags, x, y)
                if onChildLButtonUp ~= nil then
                    onChildLButtonUp(child, flags, x, y)
                end
                self:onLButtonUp(flags, x, y)
            end

            local onChildLButtonDblClk = item._model.OnLButtonDblClk

            --- For each child propagate the onLButtonDblClk event to the parent
            item._model.OnLButtonDblClk = function(child, flags, x, y)
                self:onLButtonDblClk(flags, x, y)
                if onChildLButtonDblClk ~= nil then
                    onChildLButtonDblClk(child, flags, x, y)
                end
            end

            local onMouseOver = item._model.OnMouseOver

            item._model.OnMouseOver = function(child)
                if onMouseOver ~= nil then
                    onMouseOver(child)
                end
                self:onMouseOver()
            end

            local onMouseOverEnd = item._model.OnMouseOverEnd

            item._model.OnMouseOverEnd = function(child)
                self:onMouseOverEnd()
                if onMouseOverEnd ~= nil then
                    onMouseOverEnd(child)
                end
            end

            item:create(nil, self:getName())
            item:onInitialize()
        end
    )
end

function Window:onLButtonDown(flags, x, y)
    View.onLButtonDown(self, flags, x, y)
    self._startDrag = { x = x, y = y }
end

function Window:onLButtonUp(flags, x, y)
    local moved = (self._startDrag.x >= 0 and self._startDrag.x ~= x) or
        (self._startDrag.y >= 0 and self._startDrag.y ~= y)
    local isDraggingItem = Data.Drag():isDraggingItem()
    local shouldFire = (not moved) or isDraggingItem
    if shouldFire then
        View.onLButtonUp(self, flags, x, y)
    end
    self._startDrag = { x = -1, y = -1 }
end

function Window:onUpdate(timePassed)
    View.onUpdate(self, timePassed)
end

function Window:onShutdown()
    Utils.Array.ForEach(self._children, function(item)
        item:destroy()
    end)
    View.onShutdown(self)
end

---@return Window
function Window:getFrame()
    if self._frameWindow == nil then
        self._frameWindow = Window:new { Name = self._frame }
    end
    return self._frameWindow
end

---@return Window
function Window:getBackground()
    if self._backgroundWindow == nil then
        self._backgroundWindow = Window:new { Name = self._background }
    end
    return self._backgroundWindow
end

function Window:toggleFrame(doShow)
    if Api.Window.DoesExist(self._frame) then
        Api.Window.SetShowing(self._frame, doShow)
    end
end

function Window:toggleBackground(doShow)
    if Api.Window.DoesExist(self._background) then
        Api.Window.SetShowing(self._background, doShow)
    end
end

function Window:attachToObject()
    Api.Window.AttachToWorldObject(self:getId(), self:getName())
    return self
end

function Window:setChildren(children)
    self._children = children
end

-- ========================================================================== --
-- Components - Scaffold (top-level root window with resize, snap, close)
-- ========================================================================== --

function Scaffold:new(model)
    model = model or {}
    local instance = Window.new(self, model) --[[@as Scaffold]]

    instance._model.OnRButtonUp = model.OnRButtonUp or function(window)
        window:destroy()
    end

    return instance
end

local DETACH_NUDGE = 5

function Scaffold:onInitialize()
    self:toggleBackground(true)
    self:toggleFrame(true)
    View.onInitialize(self)

    Api.Window.RestorePosition(self.name)

    -- Create resize grip unless explicitly disabled
    if self._model.Resizable ~= false then
        local parentWindow = self
        local grip = Components.Button {
            Template = "MongbatResizeGrip",
            Resizable = false,
            OnLButtonDown = function()
                startResize(parentWindow)
            end,
        }
        grip:create()
        grip:onInitialize()
        grip:setParent(self.name)
        grip:clearAnchors()
        grip:addAnchor("bottomright", self.name, "bottomright", 0, 0)
        grip:setLayer():overlay()
        self._resizeGrip = grip
    end

    -- Register snappable windows for edge snapping
    if self._model.Snappable ~= false then
        SnappableWindows[self.name] = true
        self._wasMoving = false
        self._isSnapped = false
        -- Ensure OnUpdate CoreEvent is registered even if the model has no OnUpdate
        if self._model.OnUpdate == nil then
            self._snapRegisteredOnUpdate = true
            self:registerCoreEventHandler(
                Constants.CoreEvents.OnUpdate,
                "Mongbat.EventHandler.OnUpdate"
            )
        end
    end

    self:_initializeChildren()
end

function Scaffold:onLButtonDown(flags, x, y)
    -- Ctrl + left-click: detach this window from its snap group
    if self._isSnapped and flags == Constants.ButtonFlags.Control then
        local ox, oy = WindowGetOffsetFromParent(self.name)
        WindowClearAnchors(self.name)
        WindowAddAnchor(self.name, "topleft", "Root", "topleft",
            ox + DETACH_NUDGE, oy + DETACH_NUDGE)
        self._isSnapped = false
        return
    end

    Window.onLButtonDown(self, flags, x, y)
end

function Scaffold:onUpdate(timePassed)
    -- Snap + group drag logic for snappable windows
    if self._wasMoving ~= nil then
        local isMoving = self:isMoving()

        -- Drag start: compute the joined group and save offsets
        if isMoving and not self._wasMoving then
            local group = findJoinedGroup(self.name)
            local myRect = getWindowRect(self.name)
            local dragGroup = {}
            local exclude = { [self.name] = true }
            if myRect then
                for _, name in ipairs(group) do
                    exclude[name] = true
                    if name ~= self.name then
                        local rect = getWindowRect(name)
                        if rect then
                            table.insert(dragGroup, {
                                name = name,
                                offsetX = rect.x - myRect.x,
                                offsetY = rect.y - myRect.y,
                            })
                        end
                    end
                end
            end
            self._dragGroup = dragGroup
            self._dragExclude = exclude
        end

        if isMoving then
            -- Move group members to maintain their offsets from the dragged window
            local myRect = getWindowRect(self.name)
            if myRect and self._dragGroup then
                for _, member in ipairs(self._dragGroup) do
                    WindowClearAnchors(member.name)
                    WindowAddAnchor(member.name, "topleft", "Root", "topleft",
                        myRect.x + member.offsetX, myRect.y + member.offsetY)
                end
            end

            -- Show snap preview for window-to-window only (skip screen edges)
            local dx, dy = findSnap(self.name, self._dragExclude, true)
            if dx ~= 0 or dy ~= 0 then
                if myRect then
                    showSnapPreview(myRect.x + dx, myRect.y + dy, myRect.w, myRect.h)
                end
            else
                hideSnapPreview()
            end
        elseif self._wasMoving then
            -- Just stopped moving: apply snap to dragged window and shift group
            local isGroupDrag = self._dragGroup and #self._dragGroup > 0
            local dx, dy = findSnap(self.name, self._dragExclude, isGroupDrag)
            applySnap(self.name, dx, dy)
            if self._dragGroup then
                for _, member in ipairs(self._dragGroup) do
                    applySnap(member.name, dx, dy)
                end
            end
            self._dragGroup = nil
            self._dragExclude = nil
            hideSnapPreview()

            -- Update _isSnapped: true if this window is now adjacent to another
            local postGroup = findJoinedGroup(self.name)
            self._isSnapped = #postGroup > 1
        end

        self._wasMoving = isMoving
    end

    -- Chain to model OnUpdate via View
    View.onUpdate(self, timePassed)
end

function Scaffold:onShutdown()
    -- Cancel active resize if this window is being resized
    if resizingWindow == self then
        stopResize()
    end

    -- Clean up resize grip
    if self._resizeGrip then
        self._resizeGrip:destroy()
        self._resizeGrip = nil
    end

    -- Unregister from snap system
    SnappableWindows[self.name] = nil
    if self._snapRegisteredOnUpdate then
        self:unregisterCoreEventHandler(Constants.CoreEvents.OnUpdate)
        self._snapRegisteredOnUpdate = false
    end
    self._wasMoving = nil

    Api.Window.SavePosition(self.name)

    Window.onShutdown(self)
end

---@param model WindowModel?
---@return Window
function Components.Window(model)
    local window = Window:new(model)
    Cache[window:getName()] = window
    return window
end

---@param model ScaffoldModel?
---@return Scaffold
function Components.Scaffold(model)
    local scaffold = Scaffold:new(model)
    Cache[scaffold:getName()] = scaffold
    return scaffold
end

setmetatable(View, { __index = Component })
setmetatable(Window, { __index = View })
setmetatable(Scaffold, { __index = Window })
setmetatable(Button, { __index = Window })
setmetatable(EditTextBox, { __index = View })
setmetatable(Label, { __index = View })
setmetatable(LogDisplay, { __index = View })
setmetatable(ScrollWindow, { __index = Window })
setmetatable(StatusBar, { __index = View })
setmetatable(Gump, { __index = Scaffold })
setmetatable(CircleImage, { __index = View })
setmetatable(DynamicImage, { __index = View })
setmetatable(DefaultComponent, { __index = Component })
setmetatable(DefaultActionsComponent, { __index = DefaultComponent })
setmetatable(DefaultMainMenuWindowComponent, { __index = DefaultComponent })
setmetatable(DefaultStatusWindowComponent, { __index = DefaultComponent })
setmetatable(DefaultWarShieldComponent, { __index = DefaultComponent })
setmetatable(DefaultPaperdollWindowComponent, { __index = DefaultComponent })
setmetatable(DefaultInterfaceComponent, { __index = DefaultComponent })
setmetatable(DefaultObjectHandleComponent, { __index = DefaultComponent })
setmetatable(DefaultSettingsWindowComponent, { __index = DefaultComponent })
setmetatable(DefaultShopkeeperComponent, { __index = DefaultComponent })
setmetatable(DefaultHealthBarManagerComponent, { __index = DefaultComponent })
setmetatable(DefaultGumpsParsingComponent, { __index = DefaultComponent })
setmetatable(DefaultGenericGumpComponent, { __index = DefaultComponent })
setmetatable(DefaultMapWindowComponent, { __index = DefaultComponent })
setmetatable(DefaultMapCommonComponent, { __index = DefaultComponent })
setmetatable(DefaultDebugWindowComponent, { __index = DefaultComponent })
setmetatable(SliderBar, { __index = View })
setmetatable(ComboBox, { __index = View })
setmetatable(ListBox, { __index = View })
setmetatable(CheckBox, { __index = View })
setmetatable(AnimatedImage, { __index = View })
setmetatable(ActionButton, { __index = Button })
setmetatable(ActionButtonGroup, { __index = Window })
setmetatable(CooldownDisplay, { __index = AnimatedImage })
setmetatable(DockableWindow, { __index = Window })
setmetatable(PageWindow, { __index = View })

Components.Defaults.Actions = DefaultActionsComponent:new()
Components.Defaults.MainMenuWindow = DefaultMainMenuWindowComponent:new()
Components.Defaults.StatusWindow = DefaultStatusWindowComponent:new()
Components.Defaults.WarShield = DefaultWarShieldComponent:new()
Components.Defaults.PaperdollWindow = DefaultPaperdollWindowComponent:new()
Components.Defaults.Interface = DefaultInterfaceComponent:new()
Components.Defaults.ObjectHandle = DefaultObjectHandleComponent:new()
Components.Defaults.SettingsWindow = DefaultSettingsWindowComponent:new()
Components.Defaults.Shopkeeper = DefaultShopkeeperComponent:new()
Components.Defaults.HealthBarManager = DefaultHealthBarManagerComponent:new()
Components.Defaults.GumpsParsing = DefaultGumpsParsingComponent:new()
Components.Defaults.GenericGump = DefaultGenericGumpComponent:new()
Components.Defaults.MapWindow = DefaultMapWindowComponent:new()
Components.Defaults.MapCommon = DefaultMapCommonComponent:new()
Components.Defaults.DebugWindow = DefaultDebugWindowComponent:new()

-- ========================================================================== --
-- Mod
-- ========================================================================== --

---@class ModInitializer
---@field OnInitialize fun(): Mod Initializes the mod

---@class Mod
---@field Name string Name of the mod
---@field Path string Path to the mod resources
---@field Files string[]? list of files to load
---@field _onInitialize fun() Initializes the mod
---@field _onShutdown fun() Shutdown the mod
---@field _onUpdate fun(timePassed: number)? Updates the mod
local Mod = {}
Mod.__index = Mod

---@class ModModel
---@field Name string Name of the mod
---@field Path string Path to the mod resources
---@field Files string[]? list of files to load
---@field OnInitialize fun() Initializes the mod
---@field OnShutdown fun() Shutdown the mod
---@field OnUpdate fun(timePassed: number)? Updates the mod

---@param model ModModel
function Mod:new(model)
    local mod = setmetatable({}, self)
    mod.Name = model.Name
    mod.Path = model.Path
    mod.Files = model.Files or {}
    mod._onInitialize = model.OnInitialize or function() end
    mod._onShutdown = model.OnShutdown or function() end
    mod._onUpdate = model.OnUpdate
    return mod
end

function Mod:initialize()
    Api.Mod.Initialize(self.Name)
end

function Mod:setEnabled(isEnabled)
    Api.Interface.SaveBoolean("Mongbat.Mods." .. self.Name .. ".Enabled", isEnabled)
end

function Mod:isEnabled()
    return Api.Interface.LoadBoolean("Mongbat.Mods." .. self.Name .. ".Enabled", true)
end

function Mod:loadResources()
    Utils.Array.ForEach(
        self.Files,
        function(file)
            Api.Mod.LoadResources(
                "Data/Interface/Default/project-mongbat" .. self.Path,
                SystemData.Directories.Interface .. "/" .. SystemData.Settings.Interface.customUiName .. self.Path,
                file
            )
        end
    )
end

function Mod:onInitialize()
    if self:isEnabled() ~= nil and self:isEnabled() == false then
        return
    end

    self:loadResources()
    self._onInitialize()
end

function Mod:onShutdown()
    self._onShutdown()
end

function Mod:onUpdate(timePassed)
    if self._onUpdate ~= nil then
        self._onUpdate(timePassed)
    end
end

-- ========================================================================== --
-- Mongbat
-- ========================================================================== --

Mongbat = {}

---@type table<string, Mod>
local Mods = {}

Mongbat.ModManager = {}

Mongbat.ModManager.Mods = {}

function Mongbat.ModManager.Window()
    return Components.Scaffold {
        Name = "MongbatModManagerWindow",
        OnInitialize = function(self)
            self:setDimensions(400, 300)
            self:setChildren(
                Utils.Table.MapToArray(
                    Mods,
                    function(name, mod)
                        return Components.Button {
                            OnInitialize = function(button)
                                local status = mod:isEnabled() == nil or mod:isEnabled()
                                local statusText = "Disabled"
                                if status then
                                    statusText = "Enabled"
                                end
                                button:setText("Enable " .. name .. " (" .. statusText .. ")")
                            end,
                            OnLButtonUp = function(button)
                                local status = mod:isEnabled() == nil or mod:isEnabled()
                                mod:setEnabled(not status)
                                Api.InterfaceCore.ReloadUI()
                            end
                        }
                    end
                )
            )
        end
    }
end

Mongbat.EventHandler = EventHandler

---@param model ModModel
---@return Mod
function Mongbat.Mod(model)
    local mod = Mod:new(model)
    Mods[model.Name] = mod
    if mod:isEnabled() == nil then
        mod:setEnabled(true)
    end
    Mongbat.ModManager[mod.Name] = {
        OnInitialize = function()
            mod:onInitialize()
        end,
        OnShutdown = function()
            mod:onShutdown()
        end,
        OnUpdate = function(timePassed)
            mod:onUpdate(timePassed)
        end
    }
    return mod
end

--Init the mod
local mod = Mod:new {
    Name = "Mongbat",
    Path = "/src/lib",
    Files = {
        "Mongbat.xml"
    },
    OnInitialize = function()
        local register = {
            Constants.DataEvents.OnUpdatePlayerStatus,
            Constants.DataEvents.OnUpdateRadar,
            Constants.DataEvents.OnUpdatePlayerLocation
        }

        Utils.Array.ForEach(
            register,
            function(dataEvent)
                Api.Window.RegisterData(dataEvent.getType(), 0)
            end
        )

        --- We are using SystemEvents for onLButtonUp and onLButtonDown to facilitate the
        --- dragging and dropping of items onto another window. In this scenario, the onLButtonUp attached
        --- to the window is not activated. For example, if you drag an item from the inventory
        --- to the status window, the onLButtonUp attached to the status window will not be activated.
        Api.Event.RegisterEventHandler(Constants.SystemEvents.OnLButtonUpProcessed.getEvent(),
            "Mongbat.EventHandler.OnLButtonUp")
        Api.Event.RegisterEventHandler(Constants.SystemEvents.OnLButtonDownProcessed.getEvent(),
            "Mongbat.EventHandler.OnLButtonDown")
    end,
    OnShutdown = function()
        Api.Window.UnregisterData(Constants.DataEvents.OnUpdatePlayerStatus.getType(), 0)
        Api.Event.UnregisterEventHandler(Constants.SystemEvents.OnLButtonUpProcessed.getEvent(),
            "Mongbat.EventHandler.OnLButtonUp")
        Api.Event.UnregisterEventHandler(Constants.SystemEvents.OnLButtonDownProcessed.getEvent(),
            "Mongbat.EventHandler.OnLButtonDown")
        SnappableWindows = {}
        destroySnapPreview()
        Cache = {}
    end
}

Mongbat.Api = Api
Mongbat.Data = Data
Mongbat.Utils = Utils
Mongbat.Constants = Constants
Mongbat.Components = Components

_Mongbat = {}

function _Mongbat.OnInitialize()
    mod:onInitialize()
end

function _Mongbat.OnShutdown()
    mod:onShutdown()

    -- Restore all proxied globals to their originals
    for _, default in pairs(Components.Defaults) do
        if type(default) == "table" and default.restoreGlobal then
            default:restoreGlobal()
        end
    end
end

