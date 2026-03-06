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

---@class Context
local Context = {
    Api = Api,
    Data = Data,
    Utils = Utils,
    Constants = Constants,
    Components = Components
}

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
--- Sends a /say chat command on the SAY channel.
---@param command wstring The command text to send (without the /say prefix).
function Api.Chat.Send(command)
    local channel = ChatSettings.Channels[SystemData.ChatLogFilters.SAY]
    SendChat(channel, L"/say " .. command)
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
        text = StringFormatter.fromTid(text)
    elseif type(text) == "string" then
        text = StringFormatter.toWString(text)
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
---@param name string The name of the list box.
---@param data table The data table to set.
function Api.ListBox.SetDataTable(name, data)
    ListBoxSetDataTable(name, data)
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
    if type(text) == "string" then
        return string.lower(text)
    elseif type(text) == "wstring" then
        return string.lower(Utils.String.FromWString(text))
    end
end

function Utils.String.Upper(text)
    if type(text) == "string" then
        return string.upper(text)
    elseif type(text) == "wstring" then
        return string.upper(Utils.String.FromWString(text))
    end
end

---@param fmt string
---@param ... any
---@return string
function Utils.String.Format(fmt, ...)
    return string.format(fmt, ...)
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
-- Data - Radar
-- ========================================================================== --

---@class WindowData.Radar
---@field TexCoordX integer
---@field TexCoordY integer
---@field TexScale number

-- ========================================================================== --
-- Data - Skill Dynamic Data
-- ========================================================================== --

---
--- Returns the skill dynamic data table (WindowData.SkillDynamicData).
--- Each entry is indexed by the skill's server ID and has TempSkillValue,
--- RealSkillValue, SkillState, and SkillCap fields.
---@return SkillDynamicData[] The skill dynamic data table.
function Data.SkillDynamicData()
    return WindowData.SkillDynamicData
end


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
---@field OnLayout fun(self: Window, children: View[], child: View, index: integer)?
---@field Resizable boolean? Whether the window can be resized by dragging the corner grip. Defaults to true for root windows.
---@field Snappable boolean? Whether the window snaps to edges of other windows and the screen. Defaults to true for root windows.
---@field MinWidth number? Minimum width when resizing. Defaults to 100.
---@field MinHeight number? Minimum height when resizing. Defaults to 100.

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

---@class GumpWModel : WindowModel
---@field windowName string
---@field TextEntry string[]?
---@field Labels GumpItem[]?
---@field Images string[]?
---@field Buttons string[]?
---@field OnInitialize fun(self: Gump)?
---@field OnShutdown fun(self: Gump)?

---@class Gump : Window
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
--- When disabled, all function calls become no-ops.
---@param original table The original global table to wrap
---@return table proxy The proxy table
function DefaultComponent:_createProxy(original)
    local proxy = {
        _disabled = false,
        _original = original
    }

    setmetatable(proxy, {
        __index = function(self, key)
            -- Don't intercept internal keys
            if key == "_disabled" or key == "_original" then
                return rawget(self, key)
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
            if key == "_disabled" or key == "_original" then
                rawset(self, key, value)
                return
            end
            -- Forward writes to the original
            rawget(self, "_original")[key] = value
        end
    })

    return proxy
end

--- Disables the default component. All function calls become no-ops.
function DefaultComponent:disable()
    local proxy = self._proxy
    if proxy then
        proxy._disabled = true
    end
end

--- Restores the default component. Function calls work normally again.
function DefaultComponent:restore()
    local proxy = self._proxy
    if proxy then
        proxy._disabled = false
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
-- Components - Default - Crystal Portal
-- ========================================================================== --

---@class DefaultCrystalPortal
---@field WindowName string Name of the crystal portal window
---@field Trammel table Trammel facet destination data (Dungeons, Moongates, Banks)
---@field Felucca table Felucca facet destination data (Dungeons, Moongates, Banks)
---@field NoWind boolean Whether wind is disabled due to skill check
---@field LastSelection integer Last selected destination index
---@field LastMap integer Last map (1=Trammel, 2=Felucca)
---@field LastArea integer Last area (1=Dungeons, 2=Moongates, 3=Banks)
---@field currentBase table Current destination list in use
---@field Initialize fun() Initializes the crystal portal window
---@field Shutdown fun() Shuts down the crystal portal window
---@field OnShown fun() Handles the window being shown
---@field CheckEnable fun() Checks and updates UI state based on selection
---@field GO fun() Handles the teleport action
---@field LabelOnMouseOver fun() Handles mouse over on labels
---@field Toggle fun() Toggles the crystal portal window

---@class DefaultCrystalPortalComponent : DefaultComponent
local DefaultCrystalPortalComponent = {}
DefaultCrystalPortalComponent.__index = DefaultCrystalPortalComponent

---@return DefaultCrystalPortalComponent
function DefaultCrystalPortalComponent:new()
    local instance = DefaultComponent.new(self, "CrystalPortal") --[[@as DefaultCrystalPortalComponent]]
    instance._proxy = instance:_createProxy(CrystalPortal)
    instance._globalKey = "CrystalPortal"
    _G.CrystalPortal = instance._proxy
    return instance
end

---@return DefaultCrystalPortal
function DefaultCrystalPortalComponent:getDefault()
    return self._proxy or CrystalPortal --[[@as DefaultCrystalPortal]]
end

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
---@param eventName string The name of the event (for error logging)
---@param callback fun(window: View)
local function withMouseOverView(eventName, callback)
    local success, err = pcall(function()
        local mouseOverWindow = SystemData.MouseOverWindow
        if mouseOverWindow == nil then return end

        local name = mouseOverWindow.name
        if name == nil or name == "" then return end

        local window = Cache[name]
        if window == nil then return end

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



-- ========================================================================== --
-- Components - Gump
-- ========================================================================== --

---@param gump GumpWModel
---@param id integer
---@return Gump
function Gump:new(gump, id)
    local instance = Window.new(self, { Name = gump.windowName }) --[[@as Gump]]

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
-- Components - View
-- ========================================================================== --

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
                    dataEvent == Constants.DataEvents.OnUpdatePlayerLocation

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
                    dataEvent == Constants.DataEvents.OnUpdatePlayerLocation

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

function View:create(doShow)
    doShow = doShow == nil or doShow
    if self._model.Template == nil then
        return Api.Window.Create(self.name, doShow)
    else
        return Api.Window.CreateFromTemplate(self.name, self._model.Template, "Root", doShow)
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

    instance._model.OnRButtonUp = model.OnRButtonUp or function(window)
        if window:isParentRoot() then
            window:destroy()
        end
    end

    instance._model.OnLayout = model.OnLayout or Layouts.StackAndFill

    return instance
end

function Window:onInitialize()
    local isParentRoot = self:isParentRoot()
    self:toggleBackground(isParentRoot)
    self:toggleFrame(isParentRoot)
    View.onInitialize(self)

    -- Re-check parent after View.onInitialize, which may reparent this window
    isParentRoot = self:isParentRoot()

    if isParentRoot then
        Api.Window.RestorePosition(self.name)
    end

    -- Create resize grip for root windows unless explicitly disabled
    if isParentRoot and self._model.Resizable ~= false then
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

    -- Register snappable root windows for edge snapping
    if isParentRoot and self._model.Snappable ~= false then
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

    Utils.Array.ForEach(
        self._children,
        function(item, index)
            -- Guard against double-wrapping if onInitialize is called more than once
            if item._parentWrapped then
                item:create()
                item:onInitialize()
                return
            end
            item._parentWrapped = true

            --- For each child, override its onInitialize to set its parent and anchors
            local onChildInitialize = item._model.OnInitialize

            item._model.OnInitialize = function(child)
                child:setParent(self:getName())
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

            item:create()
            item:onInitialize()
        end
    )
end

local DETACH_NUDGE = 5

function Window:onLButtonDown(flags, x, y)
    -- Ctrl + left-click: detach this window from its snap group
    if self._isSnapped and flags == Constants.ButtonFlags.Control then
        local ox, oy = WindowGetOffsetFromParent(self.name)
        WindowClearAnchors(self.name)
        WindowAddAnchor(self.name, "topleft", "Root", "topleft",
            ox + DETACH_NUDGE, oy + DETACH_NUDGE)
        self._isSnapped = false
        return
    end

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

    -- Chain to model OnUpdate if present
    if self._model.OnUpdate ~= nil then
        self._model.OnUpdate(self, timePassed)
    end
end

function Window:onShutdown()
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

    if self:isParentRoot() then
        Api.Window.SavePosition(self.name)
    end

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

---@param model WindowModel?
---@return Window
function Components.Window(model)
    local window = Window:new(model)
    Cache[window:getName()] = window
    return window
end

setmetatable(View, { __index = Component })
setmetatable(Window, { __index = View })
setmetatable(Button, { __index = Window })
setmetatable(EditTextBox, { __index = View })
setmetatable(Label, { __index = View })
setmetatable(LogDisplay, { __index = View })
setmetatable(StatusBar, { __index = View })
setmetatable(Gump, { __index = Window })
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
setmetatable(DefaultHealthBarManagerComponent, { __index = DefaultComponent })
setmetatable(DefaultGumpsParsingComponent, { __index = DefaultComponent })
setmetatable(DefaultGenericGumpComponent, { __index = DefaultComponent })
setmetatable(DefaultMapWindowComponent, { __index = DefaultComponent })
setmetatable(DefaultMapCommonComponent, { __index = DefaultComponent })
setmetatable(DefaultDebugWindowComponent, { __index = DefaultComponent })
setmetatable(DefaultCrystalPortalComponent, { __index = DefaultComponent })

Components.Defaults.Actions = DefaultActionsComponent:new()
Components.Defaults.MainMenuWindow = DefaultMainMenuWindowComponent:new()
Components.Defaults.StatusWindow = DefaultStatusWindowComponent:new()
Components.Defaults.WarShield = DefaultWarShieldComponent:new()
Components.Defaults.PaperdollWindow = DefaultPaperdollWindowComponent:new()
Components.Defaults.Interface = DefaultInterfaceComponent:new()
Components.Defaults.ObjectHandle = DefaultObjectHandleComponent:new()
Components.Defaults.HealthBarManager = DefaultHealthBarManagerComponent:new()
Components.Defaults.GumpsParsing = DefaultGumpsParsingComponent:new()
Components.Defaults.GenericGump = DefaultGenericGumpComponent:new()
Components.Defaults.MapWindow = DefaultMapWindowComponent:new()
Components.Defaults.MapCommon = DefaultMapCommonComponent:new()
Components.Defaults.DebugWindow = DefaultDebugWindowComponent:new()
Components.Defaults.CrystalPortal = DefaultCrystalPortalComponent:new()

-- ========================================================================== --
-- Mod
-- ========================================================================== --

---@class ModInitializer
---@field OnInitialize fun(): Mod Initializes the mod

---@class Mod
---@field Name string Name of the mod
---@field Path string Path to the mod resources
---@field Files string[]? list of files to load
---@field _onInitialize fun(self: Context) Initializes the mod
---@field _onShutdown fun(self: Context) Shutdown the mod
---@field _onUpdate fun(self: Context, timePassed: number)? Updates the mod
local Mod = {}
Mod.__index = Mod

---@class ModModel
---@field Name string Name of the mod
---@field Path string Path to the mod resources
---@field Files string[]? list of files to load
---@field OnInitialize fun(self: Context) Initializes the mod
---@field OnShutdown fun(self: Context) Shutdown the mod
---@field OnUpdate fun(self: Context, timePassed: number)? Updates the mod

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
    self._onInitialize(Context)
end

function Mod:onShutdown()
    self._onShutdown(Context)
end

function Mod:onUpdate(timePassed)
    if self._onUpdate ~= nil then
        self._onUpdate(Context, timePassed)
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
    return Components.Window {
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

