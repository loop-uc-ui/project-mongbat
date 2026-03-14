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
    old_InterfaceCoreUpdate(elapsedTime)
end

local old_HotbarSystemUpdate = HotbarSystem.Update

function HotbarSystem.Update(elapsedTime)
    old_HotbarSystemUpdate(elapsedTime)
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

--- Returns true if text is nil, empty string "", or empty wstring L"".
--- @param text string|wstring|nil
--- @return boolean
function Utils.String.IsEmpty(text)
    if text == nil then return true end
    if text == "" then return true end
    if text == L"" then return true end
    return false
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

--- Searches for a pattern in text.
--- @param text string|wstring The text to search in.
--- @param pattern string The pattern to search for.
--- @param plain boolean? If true, pattern is a literal string.
--- @param caseInsensitive boolean? If true, search is case-insensitive.
--- @return number|nil startIndex
--- @return number|nil endIndex
function Utils.String.Find(text, pattern, plain, caseInsensitive)
    local s = Utils.String.FromWString(text) or ""
    local p = Utils.String.FromWString(pattern) or ""
    if caseInsensitive then
        s = string.lower(s)
        p = string.lower(p)
    end
    return string.find(s, p, 1, plain)
end

--- Returns true if text contains the given pattern.
--- @param text string|wstring The text to search in.
--- @param pattern string The pattern to search for.
--- @param plain boolean? If true, pattern is a literal string.
--- @param caseInsensitive boolean? If true, search is case-insensitive.
--- @return boolean
function Utils.String.Contains(text, pattern, plain, caseInsensitive)
    return Utils.String.Find(text, pattern, plain, caseInsensitive) ~= nil
end

--- Replaces occurrences of pattern in text with replacement.
--- @param text string|wstring
--- @param pattern string
--- @param replacement string
--- @return string|wstring result
function Utils.String.Replace(text, pattern, replacement)
    local isW = type(text) == "wstring"
    local s = Utils.String.FromWString(text) or ""
    local result = string.gsub(s, pattern, replacement)
    if isW then
        return Api.String.StringToWString(result)
    end
    return result
end

--- Concatenates multiple values into a single wstring.
--- @vararg string|number|wstring
--- @return wstring
function Utils.String.Concat(...)
    local result = L""
    local args = { ... }
    for i = 1, #args do
        local v = args[i]
        if v ~= nil then
            if type(v) == "number" then
                result = result .. towstring(v)
            elseif type(v) == "string" then
                result = result .. Api.String.StringToWString(v)
            else
                result = result .. v
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

function Constants.Broadcasts.ShopCancelOffer()
    return SystemData.Events["SHOP_CANCEL_OFFER"]
end

function Constants.Broadcasts.ShopOfferAccept()
    return SystemData.Events["SHOP_OFFER_ACCEPT"]
end

---@class DataEvent
---@field getType fun(): integer
---@field getEvent fun(): integer
---@field name string

---@type table<string, DataEvent>
Constants.DataEvents = {}

---@param key string The key into WindowData (e.g. "PlayerStatus")
---@param name string The event name
---@return table DataEvent with lazy-cached getType/getEvent
local function DataEvent(key, name)
    local cachedType, cachedEvent
    return {
        getType = function()
            if not cachedType then cachedType = WindowData[key].Type end
            return cachedType
        end,
        getEvent = function()
            if not cachedEvent then cachedEvent = WindowData[key].Event end
            return cachedEvent
        end,
        name = name
    }
end

Constants.DataEvents.OnUpdatePlayerStatus = DataEvent("PlayerStatus", "OnUpdatePlayerStatus")
Constants.DataEvents.OnUpdateMobileName = DataEvent("MobileName", "OnUpdateMobileName")
Constants.DataEvents.OnUpdateHealthBarColor = DataEvent("HealthBarColor", "OnUpdateHealthBarColor")
Constants.DataEvents.OnUpdateMobileStatus = DataEvent("MobileStatus", "OnUpdateMobileStatus")
Constants.DataEvents.OnUpdateRadar = DataEvent("Radar", "OnUpdateRadar")
Constants.DataEvents.OnUpdatePlayerLocation = DataEvent("PlayerLocation", "OnUpdatePlayerLocation")
Constants.DataEvents.OnUpdatePaperdoll = DataEvent("Paperdoll", "OnUpdatePaperdoll")
Constants.DataEvents.OnUpdateShopData = DataEvent("ShopData", "OnUpdateShopData")
Constants.DataEvents.OnUpdateContainerWindow = DataEvent("ContainerWindow", "OnUpdateContainerWindow")
Constants.DataEvents.OnUpdateObjectInfo = DataEvent("ObjectInfo", "OnUpdateObjectInfo")
Constants.DataEvents.OnUpdateItemProperties = DataEvent("ItemProperties", "OnUpdateItemProperties")

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
Constants.CoreEvents.OnLButtonDown = "OnLButtonDown"
Constants.CoreEvents.OnLButtonUp = "OnLButtonUp"
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
-- Property System
-- ========================================================================== --

--- @type table<table, table>
local classMetatables = {}

--- Merges _ownProperties from a class and all its parents into a single
--- _properties table on the class. Must be called after all metatables are set.
---@param class table
local function mergeProperties(class)
    local merged = {}
    local cls = class
    while cls do
        local own = rawget(cls, '_ownProperties')
        if own then
            for k, v in pairs(own) do
                if merged[k] == nil then
                    merged[k] = v
                end
            end
        end
        local mt = getmetatable(cls)
        if mt then
            local parent = rawget(mt, '__index')
            if type(parent) == "table" then
                cls = parent
            else
                break
            end
        else
            break
        end
    end
    rawset(class, '_properties', merged)
end

--- Gets or creates a shared metatable for instances of the given class.
--- The metatable intercepts property access via __index and __newindex.
---@param class table
---@return table
local function getClassMetatable(class)
    local mt = classMetatables[class]
    if mt then return mt end
    mt = {
        __index = function(_, k)
            local properties = rawget(class, '_properties')
            if properties then
                local prop = properties[k]
                if prop then
                    if prop.get then return prop.get(_) end
                    return nil
                end
            end
            return class[k]
        end,
        __newindex = function(_, k, v)
            local properties = rawget(class, '_properties')
            if properties then
                local prop = properties[k]
                if prop and prop.set then
                    prop.set(_, v)
                    return
                end
            end
            rawset(_, k, v)
        end,
    }
    classMetatables[class] = mt
    return mt
end


-- ========================================================================== --
-- Data
-- ========================================================================== --

-- ========================================================================== --
-- Data - Active Mobile
-- ========================================================================== --

---@class SystemData.ActiveMobile
---@field Id number

---@class ActiveMobileWrapper
---@field id number
local ActiveMobile = {}

function ActiveMobile:new()
    return setmetatable({}, getClassMetatable(self))
end

---@return SystemData.ActiveMobile
function ActiveMobile:getData()
    return SystemData.ActiveMobile
end

ActiveMobile._ownProperties = {
    id = {
        get = function(self) return self:getData().Id end,
        set = function(self, v) self:getData().Id = v end,
    },
}

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
---@field hasTarget boolean
---@field mobile boolean
---@field corpse boolean
---@field object boolean
---@field id number
local CurrentTarget = {}

function CurrentTarget:new()
    return setmetatable({}, getClassMetatable(self))
end

---@return WindowData.CurrentTarget
function CurrentTarget:getData()
    return WindowData.CurrentTarget
end

CurrentTarget._ownProperties = {
    hasTarget = {
        get = function(self) return self:getData().HasTarget end,
    },
    mobile = {
        get = function(self) return self:getData().TargetType == 2 end,
    },
    corpse = {
        get = function(self) return self:getData().TargetType == 4 end,
    },
    object = {
        get = function(self) return self:getData().TargetType == 3 end,
    },
    id = {
        get = function(self) return self:getData().TargetId end,
    },
}

function Data.CurrentTarget()
    return CurrentTarget:new()
end

-- ========================================================================== --
-- Data - Cursor
-- ========================================================================== --

---@class WindowData.Cursor
---@field target boolean

---@class CursorDataWrapper
---@field target boolean
local Cursor = {}

function Cursor:new()
    return setmetatable({}, getClassMetatable(self))
end

---@return WindowData.Cursor
function Cursor:getData()
    return WindowData.Cursor
end

Cursor._ownProperties = {
    target = {
        get = function(self)
            local data = self:getData()
            if data == nil then return false end
            return data.target == true
        end,
    },
}

function Data.Cursor()
    return Cursor:new()
end

-- ========================================================================== --
-- Data - Drag
-- ========================================================================== --

---@class DragDataWrapper
---@field dragItemData table<string, number>
---@field dragSourceData table<string, number>
---@field draggingItem boolean
---@field draggingObject number
local Drag = {}

function Drag:new()
    return setmetatable({}, getClassMetatable(self))
end

Drag._ownProperties = {
    dragItemData = {
        get = function(_) return SystemData.DragItem end,
    },
    dragSourceData = {
        get = function(_) return SystemData.DragSource end,
    },
    draggingItem = {
        get = function(self) return self.dragItemData.DragType == SystemData.DragItem.TYPE_ITEM end,
    },
    draggingObject = {
        get = function(self) return self.dragSourceData["SOURCETYPE_OBJECT"] end,
    },
}

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
---@field visualStateId number
---@field visualStateColor Color
local HealthBarColor = {}

function HealthBarColor:new(id)
    local instance = setmetatable({}, getClassMetatable(self))
    rawset(instance, '_id', id)
    return instance
end

---@return WindowData.HealthBarColor
function HealthBarColor:getData()
    return WindowData.HealthBarColor[self._id]
end

HealthBarColor._ownProperties = {
    visualStateId = {
        get = function(self) return self:getData().VisualStateId end,
    },
    visualStateColor = {
        get = function(self) return Constants.Colors.HealhBar[self.visualStateId + 1] end,
    },
}

function Data.HealthBarColor(id)
    return HealthBarColor:new(id)
end

-- ========================================================================== --
-- Data - Mobile Name
-- ========================================================================== --

---@class MobileNameWrapper
---@field _id number
---@field name wstring
local MobileName = {}

function MobileName:new(id)
    local instance = setmetatable({}, getClassMetatable(self))
    rawset(instance, '_id', id)
    return instance
end

---@return MobileName
function MobileName:getData()
    return WindowData.MobileName[self._id]
end

MobileName._ownProperties = {
    name = {
        get = function(self) return self:getData().MobName end,
    },
}

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
---@field name string
---@field notoriety number
---@field notorietyColor Color
local MobileStatus = {}

function MobileStatus:new(id)
    local instance = setmetatable({}, getClassMetatable(self))
    rawset(instance, '_id', id)
    return instance
end

---@return WindowData.MobileStatus
function MobileStatus:getData()
    return WindowData.MobileStatus[self._id]
end

MobileStatus._ownProperties = {
    name = {
        get = function(self) return self:getData().MobName end,
    },
    notoriety = {
        get = function(self) return self:getData().Notoriety end,
    },
    notorietyColor = {
        get = function(self) return Constants.Colors.Notoriety[self.notoriety + 1] end,
    },
}

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
---@field valid boolean
---@field mobile boolean
local Object = {}

function Object:new(id)
    local instance = setmetatable({}, getClassMetatable(self))
    rawset(instance, '_id', id)
    return instance
end

Object._ownProperties = {
    valid = {
        get = function(self) return Api.Object.IsValid(self._id) end,
    },
    mobile = {
        get = function(self) return Api.Object.IsMobile(self._id) end,
    },
}

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
---@field handles table<number, ObjectHandle>
local ObjectHandles = {}

function ObjectHandles:new()
    return setmetatable({}, getClassMetatable(self))
end

---@return WindowData.ObjectHandle
function ObjectHandles:getData()
    return WindowData.ObjectHandle
end

ObjectHandles._ownProperties = {
    handles = {
        ---@return table<number, ObjectHandle>
        get = function(self)
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
                            return Data.Object(item).valid
                                and Utils.Array.Find(windowData.ObjectId, function(id)
                                    return id == item
                                end)
                        end
                    }
                end
            )
        end,
    },
}

function ObjectHandles:getHandle(id)
    return self.handles[id]
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
---@field x number
---@field y number
---@field z number
---@field facet number
local PlayerLocation = {}

function PlayerLocation:new()
    return setmetatable({}, getClassMetatable(self))
end

---@return WindowData.PlayerLocation
function PlayerLocation:getData()
    return WindowData.PlayerLocation
end

PlayerLocation._ownProperties = {
    x = {
        get = function(self) return self:getData().x or 0 end,
    },
    y = {
        get = function(self) return self:getData().y or 0 end,
    },
    z = {
        get = function(self) return self:getData().z or 0 end,
    },
    facet = {
        get = function(self) return self:getData().facet or 0 end,
    },
}

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
---@field statCap number
---@field currentMana number
---@field maxMana number
---@field currentHealth number
---@field maxHealth number
---@field currentStamina number
---@field maxStamina number
---@field inWarMode boolean
---@field gold number
---@field id number
---@field event integer
---@field type integer
local PlayerStatus = {}

function PlayerStatus:new()
    return setmetatable({}, getClassMetatable(self))
end

---@return WindowData.PlayerStatus
function PlayerStatus:getData()
    return WindowData.PlayerStatus or { PlayerId = 0 }
end

PlayerStatus._ownProperties = {
    statCap = {
        get = function(self) return self:getData().StatCap or 0 end,
    },
    currentMana = {
        get = function(self) return self:getData().CurrentMana or 0 end,
    },
    maxMana = {
        get = function(self) return self:getData().MaxMana or 0 end,
    },
    currentHealth = {
        get = function(self) return self:getData().CurrentHealth or 0 end,
    },
    maxHealth = {
        get = function(self) return self:getData().MaxHealth or 0 end,
    },
    currentStamina = {
        get = function(self) return self:getData().CurrentStamina or 0 end,
    },
    maxStamina = {
        get = function(self) return self:getData().MaxStamina or 0 end,
    },
    inWarMode = {
        get = function(self) return self:getData().InWarMode or false end,
    },
    gold = {
        get = function(self) return self:getData().Gold or 0 end,
    },
    id = {
        get = function(self) return self:getData().PlayerId or 0 end,
    },
    event = {
        get = function(self) return self:getData().Event end,
    },
    type = {
        get = function(self) return self:getData().Type end,
    },
}

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
---@field id integer
---@field numSlots integer
local PaperdollData = {}

function PaperdollData:new(id)
    return setmetatable({ _id = id }, getClassMetatable(self))
end

---@return table|nil
function PaperdollData:getData()
    if WindowData.Paperdoll then
        return WindowData.Paperdoll[self._id]
    end
    return nil
end

PaperdollData._ownProperties = {
    id = {
        get = function(self) return self._id end,
    },
    numSlots = {
        get = function(self)
            local data = self:getData()
            if data then return data.numSlots or 0 end
            return 0
        end,
    },
}

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
---@field hasData boolean
---@field width number
---@field height number
---@field xOffset number
---@field yOffset number
---@field legacy boolean
---@field textureName string
local PaperdollTexture = {}

function PaperdollTexture:new(id)
    return setmetatable({ _id = id }, getClassMetatable(self))
end

---@return table|nil Raw SystemData.PaperdollTexture entry
function PaperdollTexture:getData()
    return SystemData.PaperdollTexture[self._id]
end

PaperdollTexture._ownProperties = {
    hasData = {
        get = function(self) return self:getData() ~= nil end,
    },
    width = {
        get = function(self)
            local data = self:getData()
            if not data then return 0 end
            local w = data.Width
            if data.IsLegacy == 1 then w = w * 2 end
            return w
        end,
    },
    height = {
        get = function(self)
            local data = self:getData()
            if not data then return 0 end
            local h = data.Height
            if data.IsLegacy == 1 then h = h * 2 end
            return h
        end,
    },
    xOffset = {
        get = function(self)
            local data = self:getData()
            if not data then return 0 end
            return data.xOffset
        end,
    },
    yOffset = {
        get = function(self)
            local data = self:getData()
            if not data then return 0 end
            return data.yOffset
        end,
    },
    legacy = {
        get = function(self)
            local data = self:getData()
            if not data then return false end
            return data.IsLegacy == 1
        end,
    },
    textureName = {
        get = function(self) return "paperdoll_texture" .. self._id end,
    },
}

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
-- Data - Shop Data
-- ========================================================================== --

---@class ShopDataBuyEntry
---@field objectId integer
---@field objectType integer
---@field hue integer

---@class ShopDataSellEntry
---@field id integer
---@field name wstring
---@field price integer
---@field quantity integer
---@field objType integer

---@class ShopDataWrapper
---@field _id number
---@field selling boolean
---@field buyCount integer
---@field sellCount integer
---@field buyNames table
---@field sellNames table
---@field buyPrices table
---@field sellPrices table
---@field buyQuantities table
---@field sellQuantities table
---@field buyObjectIds table
---@field sellObjectIds table
---@field buyObjectTypes table
---@field sellObjectTypes table
---@field buyHues table
---@field sellHues table
---@field sellContainerId integer
local ShopData = {}

function ShopData:new()
    return setmetatable({}, getClassMetatable(self))
end

---@return table|nil
function ShopData:getData()
    return WindowData.ShopData
end

ShopData._ownProperties = {
    selling = {
        get = function(self) local d = self:getData() return d and d.IsSelling == true end,
    },
    buyCount = {
        get = function(self) local d = self:getData() return d and d.BuyListCount or 0 end,
    },
    sellCount = {
        get = function(self) local d = self:getData() return d and d.SellListCount or 0 end,
    },
    buyNames = {
        get = function(self) local d = self:getData() return d and d.Buy and d.Buy.Names or {} end,
    },
    sellNames = {
        get = function(self) local d = self:getData() return d and d.Sell and d.Sell.Names or {} end,
    },
    buyPrices = {
        get = function(self) local d = self:getData() return d and d.Buy and d.Buy.Prices or {} end,
    },
    sellPrices = {
        get = function(self) local d = self:getData() return d and d.Sell and d.Sell.Prices or {} end,
    },
    buyQuantities = {
        get = function(self) local d = self:getData() return d and d.Buy and d.Buy.Quantities or {} end,
    },
    sellQuantities = {
        get = function(self) local d = self:getData() return d and d.Sell and d.Sell.Quantities or {} end,
    },
    buyObjectIds = {
        get = function(self) local d = self:getData() return d and d.Buy and d.Buy.ObjectIds or {} end,
    },
    sellObjectIds = {
        get = function(self) local d = self:getData() return d and d.Sell and d.Sell.ObjectIds or {} end,
    },
    buyObjectTypes = {
        get = function(self) local d = self:getData() return d and d.Buy and d.Buy.ObjectTypes or {} end,
    },
    sellObjectTypes = {
        get = function(self) local d = self:getData() return d and d.Sell and d.Sell.ObjectTypes or {} end,
    },
    buyHues = {
        get = function(self) local d = self:getData() return d and d.Buy and d.Buy.Hues or {} end,
    },
    sellHues = {
        get = function(self) local d = self:getData() return d and d.Sell and d.Sell.Hues or {} end,
    },
    sellContainerId = {
        get = function(self) local d = self:getData() return d and d.SellContainerId or 0 end,
    },
}

--- Returns all sell items as an array, skipping entries with zero quantity.
---@return ShopDataSellEntry[]
function ShopData:getSellItems()
    local d = self:getData()
    local sell = d and d.Sell
    if not sell then return {} end
    local count = d.SellListCount or 0
    local result = {}
    for i = 1, count do
        if sell.Quantities[i] ~= 0 then
            Utils.Array.Add(result, {
                id       = sell.Ids[i],
                name     = sell.Names[i],
                price    = sell.Prices[i],
                quantity = sell.Quantities[i],
                objType  = sell.Types[i]
            })
        end
    end
    return result
end

--- Writes the buy/sell offer into ShopData for the engine to process.
---@param offerIds integer[]
---@param offerQuantities integer[]
function ShopData:setOffer(offerIds, offerQuantities)
    local d = self:getData()
    if not d then return end
    Utils.Array.ForEach(offerIds, function(id, i)
        d.OfferIds[i] = id
        d.OfferQuantities[i] = offerQuantities[i]
    end)
end

---@return ShopDataWrapper
function Data.ShopData()
    return ShopData:new()
end

-- ========================================================================== --
-- Data - Container Window
-- ========================================================================== --

--- Returns the raw ContainerWindow data for the given container ID, or nil.
---@param id integer
---@return table|nil
function Data.ContainerWindow(id)
    if not WindowData.ContainerWindow or not WindowData.ContainerWindow[id] then
        return nil
    end
    return WindowData.ContainerWindow[id]
end

-- ========================================================================== --
-- Data - Object Info
-- ========================================================================== --

---@class ObjectInfoWrapper
---@field _id number
---@field objectType integer
---@field hueId integer
---@field shopValue integer
---@field shopQuantity integer
local ObjectInfoData = {}

function ObjectInfoData:new(id)
    return setmetatable({ _id = id }, getClassMetatable(self))
end

---@return table|nil
function ObjectInfoData:getData()
    if not WindowData.ObjectInfo or not WindowData.ObjectInfo[self._id] then
        return nil
    end
    return WindowData.ObjectInfo[self._id]
end

ObjectInfoData._ownProperties = {
    objectType = {
        get = function(self) local d = self:getData() return d and d.objectType or 0 end,
    },
    hueId = {
        get = function(self) local d = self:getData() return d and d.hueId or 0 end,
    },
    shopValue = {
        get = function(self) local d = self:getData() return d and d.shopValue or 0 end,
    },
    shopQuantity = {
        get = function(self) local d = self:getData() return d and d.shopQuantity or 0 end,
    },
}

---@return ObjectInfoWrapper
function Data.ObjectInfo(id)
    return ObjectInfoData:new(id)
end

-- ========================================================================== --
-- Data - Item Properties
-- ========================================================================== --

--- Returns the raw ItemProperties data for the given item ID, or nil.
---@param id integer
---@return table|nil
function Data.ItemProperties(id)
    if not WindowData.ItemProperties or not WindowData.ItemProperties[id] then
        return nil
    end
    return WindowData.ItemProperties[id]
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

--- Per-frame marker: the view name that already handled OnLButtonUp via
--- CoreEvent this frame.  Prevents the SystemEvent fallback from double-firing.
---@type string?
local lbuttonUpHandledView = nil

--- Module-level resize tracking
---@type Window?
local resizingWindow = nil
---@type { startMouseX: number, startMouseY: number, startWidth: number, startHeight: number, minWidth: number, minHeight: number }?
local resizeState = nil
--- The original OnUpdate handler saved before resize injected its own
---@type fun(timePassed: integer)?
local resizeOriginalOnUpdate = nil
--- Whether we dynamically registered OnUpdate (it wasn't already present)
local resizeRegisteredOnUpdate = false

--- Window snapping: registry of snappable window names for edge detection
---@type table<string, boolean>
local SnappableWindows = {}
local SNAP_THRESHOLD = 20

---@class ButtonModel : ViewModel
---@field OnInitialize fun(self: Button)?

---@class Button: View
---@field text string|wstring
---@field checked boolean
---@field stayDown boolean
---@field textDimensions any
---@field checkButton boolean
local Button = {}
Button.__index = Button

---@class CheckBoxModel : ViewModel
---@field OnInitialize fun(self: CheckBox)?
---@field OnShutdown fun(self: CheckBox)?

---@class CheckBox: View
---@field label Label?
---@field checked boolean
local CheckBox = {}
CheckBox.__index = CheckBox

---@class ComboBoxModel : ViewModel
---@field OnInitialize fun(self: ComboBox)?
---@field OnShutdown fun(self: ComboBox)?

---@class ComboBox: View
---@field selectedItem wstring
local ComboBox = {}
ComboBox.__index = ComboBox

---@class SliderBarModel : ViewModel
---@field OnInitialize fun(self: SliderBar)?
---@field OnShutdown fun(self: SliderBar)?

---@class SliderBar: View
---@field currentPosition number
local SliderBar = {}
SliderBar.__index = SliderBar

---@class AnimatedImageModel : ViewModel
---@field OnInitialize fun(self: AnimatedImage)?
---@field OnShutdown fun(self: AnimatedImage)?

---@class AnimatedImage: View
---@field texture string
---@field playSpeed number
local AnimatedImage = {}
AnimatedImage.__index = AnimatedImage

---@class ActionButtonModel : ViewModel
---@field OnInitialize fun(self: ActionButton)?
---@field OnShutdown fun(self: ActionButton)?

---@class ActionButton: Button
---@field action any
---@field gameActionTrigger any
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
---@field buttonCount number
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
---@field activePage number
---@field numPages number
local PageWindow = {}
PageWindow.__index = PageWindow

---@class DefaultComponent : Component
---@field _original table The original global table
---@field _saved table<string, function>? Saved functions from disable(), restored by restore()
---@field default table The original global table (read-only)
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




---@class CircleImageModel : ViewModel
---@field OnInitialize fun(self: CircleImage)?
---@field OnShutdown fun(self: CircleImage)?

---@class CircleImage : View
---@field textureSlice string
---@field textureScale number
---@field rotation number
local CircleImage = {}
CircleImage.__index = CircleImage

---@class Component
---@field name string
local Component = {}
Component.__index = Component

---@class DynamicImageModel : ViewModel
---@field OnInitialize fun(self: DynamicImage)?
---@field OnShutdown fun(self: DynamicImage)?

---@class DynamicImage: View
---@field hasTexture boolean
---@field texture {[1]: string, [2]: number, [3]: number}
---@field textureSlice string
---@field textureScale number
---@field rotation number
---@field textureDimensions {[1]: number, [2]: number}
---@field textureOrientation boolean
local DynamicImage = {}
DynamicImage.__index = DynamicImage

---@class EditTextBoxModel : ViewModel
---@field OnInitialize fun(self: EditTextBox)?
---@field OnShutdown fun(self: EditTextBox)?

---@class EditTextBox: View
---@field text string|wstring
---@field textColor Color
---@field font string
local EditTextBox = {}
EditTextBox.__index = EditTextBox

---@class FilterInputModel : EditTextBoxModel
---@field OnInitialize fun(self: FilterInput)?
---@field OnShutdown fun(self: FilterInput)?

---@class FilterInput: EditTextBox
---@field filterText wstring
local FilterInput = {}
FilterInput.__index = FilterInput



---@class WindowModel : ViewModel
---@field Name string? The name of the window. If not provided, a random name will be generated.
---@field Id integer?
---@field Template string? The template to use for the window. Defaults to "MongbatWindow"
---@field OnInitialize fun(self: Window)?
---@field OnShutdown fun(self: Window)?
---@field OnLayout fun(self: Window, children: View[], child: View, index: integer)?
---@field Resizable boolean? Whether the window can be resized by dragging the corner grip. Defaults to true for root windows.
---@field Snappable boolean? Whether the window snaps to edges of other windows and the screen. Defaults to true for root windows.
---@field MinWidth number? Minimum width when resizing. Defaults to 100.
---@field MinHeight number? Minimum height when resizing. Defaults to 100.

---@class LabelModel : ViewModel
---@field OnInitialize fun(self: Label)?
---@field OnShutdown fun(self: Label)?

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
---@field vendorSearch boolean
---@field jewelryBox boolean
---@field _id integer The unique ID of the gump window.
local Gump = {}
Gump.__index = Gump

---@class Label: View
---@field text string|wstring
---@field textColor Color
---@field textAlignment integer
local Label = {}
Label.__index = Label

---@class LogDisplayModel : ViewModel
---@field OnInitialize fun(self: LogDisplay)?
---@field OnShutdown fun(self: LogDisplay)?

---@class LogDisplay: View
---@field timestampVisible boolean
---@field logNameVisible boolean
---@field filterNameVisible boolean
local LogDisplay = {}
LogDisplay.__index = LogDisplay

---@class ViewModel
---@field Name string?
---@field Template string?
---@field Id integer?
---@field OnInitialize fun(self: View)?
---@field OnShutdown fun(self: View)?

---@class StatusBarModel : ViewModel
---@field OnInitialize fun(self: StatusBar)?
---@field OnShutdown fun(self: StatusBar)?

---@class ScrollWindowModel : ViewModel
---@field ItemHeight number? Height per item row used for vertical stacking and content container sizing. Defaults to 50.
---@field ItemWidth number? Width per item column used for horizontal stacking (only when Horizontal is true). Defaults to 50.
---@field Horizontal boolean? When true, the scroll window scrolls horizontally instead of vertically. Defaults to false.
---@field OnInitialize fun(self: ScrollWindow)?
---@field OnShutdown fun(self: ScrollWindow)?

---@class ScrollWindow : View
---@field horizontal boolean
---@field itemCount number
---@field offset number
---@field _items View[] Views added as rows into the scroll content area.
local ScrollWindow = {}
ScrollWindow.__index = ScrollWindow

---@class StatusBar: View
---@field label Label?
---@field maxValue number
---@field currentValue number
---@field foregroundTint Color
---@field backgroundTint Color
local StatusBar = {}
StatusBar.__index = StatusBar

-- ========================================================================== --
-- Components - Internal Builders - Binding Factory
-- ========================================================================== --

---@class BindingSpec
---@field name string
---@field fn function
---@field kind "core"|"data"|"system"|nil
---@field event DataEvent|nil
---@field entity boolean|nil

---@class BindingFactory
---@field _specs BindingSpec[]
local BindingFactory = {}
BindingFactory.__index = BindingFactory

---@return BindingFactory
function BindingFactory:new()
    return setmetatable({ _specs = {} }, self)
end

---@return BindingSpec[]
function BindingFactory:build()
    return self._specs
end

-- Data Events

---@param fn fun(playerStatus: PlayerStatusWrapper)
---@return BindingFactory
function BindingFactory:onPlayerStatus(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdatePlayerStatus", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdatePlayerStatus, entity = false }
    return self
end

---@param fn fun(mobileName: MobileNameWrapper)
---@return BindingFactory
function BindingFactory:onMobileName(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdateMobileName", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdateMobileName, entity = true }
    return self
end

---@param fn fun(mobileStatus: MobileStatusWrapper)
---@return BindingFactory
function BindingFactory:onMobileStatus(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdateMobileStatus", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdateMobileStatus, entity = true }
    return self
end

---@param fn fun(healthBarColor: HealthBarColorWrapper)
---@return BindingFactory
function BindingFactory:onHealthBarColor(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdateHealthBarColor", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdateHealthBarColor, entity = true }
    return self
end

---@param fn fun(paperdoll: PaperdollWrapper)
---@return BindingFactory
function BindingFactory:onPaperdoll(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdatePaperdoll", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdatePaperdoll, entity = true }
    return self
end

---@param fn fun(instanceId: number, containerWindow: ContainerWindowData)
---@return BindingFactory
function BindingFactory:onContainerWindow(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdateContainerWindow", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdateContainerWindow, entity = false }
    return self
end

---@param fn fun(instanceId: number, objectInfo: ObjectInfoWrapper)
---@return BindingFactory
function BindingFactory:onObjectInfo(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdateObjectInfo", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdateObjectInfo, entity = false }
    return self
end

---@param fn fun(instanceId: number, itemProperties: table)
---@return BindingFactory
function BindingFactory:onItemProperties(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdateItemProperties", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdateItemProperties, entity = false }
    return self
end

---@param fn fun(data: WindowData.Radar)
---@return BindingFactory
function BindingFactory:onRadar(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdateRadar", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdateRadar, entity = false }
    return self
end

---@param fn fun(data: table)
---@return BindingFactory
function BindingFactory:onPlayerLocation(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdatePlayerLocation", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdatePlayerLocation, entity = false }
    return self
end

---@param fn fun()
---@return BindingFactory
function BindingFactory:onShopData(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdateShopData", fn = fn, kind = "data", event = Constants.DataEvents.OnUpdateShopData, entity = false }
    return self
end

-- Core Events

---@param fn fun(timePassed: number)
---@return BindingFactory
function BindingFactory:onUpdate(fn)
    self._specs[#self._specs + 1] = { name = "OnUpdate", fn = fn, kind = "core" }
    return self
end

---@param fn fun()
---@return BindingFactory
function BindingFactory:onShown(fn)
    self._specs[#self._specs + 1] = { name = "OnShown", fn = fn, kind = "core" }
    return self
end

---@param fn fun()
---@return BindingFactory
function BindingFactory:onHidden(fn)
    self._specs[#self._specs + 1] = { name = "OnHidden", fn = fn, kind = "core" }
    return self
end

---@param fn fun()
---@return BindingFactory
function BindingFactory:onMouseOver(fn)
    self._specs[#self._specs + 1] = { name = "OnMouseOver", fn = fn, kind = "core" }
    return self
end

---@param fn fun()
---@return BindingFactory
function BindingFactory:onMouseOverEnd(fn)
    self._specs[#self._specs + 1] = { name = "OnMouseOverEnd", fn = fn, kind = "core" }
    return self
end

---@param fn fun(x: number, y: number, delta: number)
---@return BindingFactory
function BindingFactory:onMouseWheel(fn)
    self._specs[#self._specs + 1] = { name = "OnMouseWheel", fn = fn, kind = "core" }
    return self
end

---@param fn fun(flags: number, x: number, y: number)
---@return BindingFactory
function BindingFactory:onLButtonDown(fn)
    self._specs[#self._specs + 1] = { name = "OnLButtonDown", fn = fn, kind = "core" }
    return self
end

---@param fn fun(flags: number, x: number, y: number)
---@return BindingFactory
function BindingFactory:onLButtonUp(fn)
    self._specs[#self._specs + 1] = { name = "OnLButtonUp", fn = fn, kind = "core" }
    return self
end

---@param fn fun(flags: number, x: number, y: number)
---@return BindingFactory
function BindingFactory:onLButtonDblClk(fn)
    self._specs[#self._specs + 1] = { name = "OnLButtonDblClk", fn = fn, kind = "core" }
    return self
end

---@param fn fun(flags: number, x: number, y: number)
---@return BindingFactory
function BindingFactory:onRButtonUp(fn)
    self._specs[#self._specs + 1] = { name = "OnRButtonUp", fn = fn, kind = "core" }
    return self
end

---@param fn fun(flags: number, x: number, y: number)
---@return BindingFactory
function BindingFactory:onRButtonDown(fn)
    self._specs[#self._specs + 1] = { name = "OnRButtonDown", fn = fn, kind = "core" }
    return self
end

---@param fn fun(position: number)
---@return BindingFactory
function BindingFactory:onSlide(fn)
    self._specs[#self._specs + 1] = { name = "OnSlide", fn = fn, kind = "core" }
    return self
end

---@param fn fun()
---@return BindingFactory
function BindingFactory:onSelChanged(fn)
    self._specs[#self._specs + 1] = { name = "OnSelChanged", fn = fn, kind = "core" }
    return self
end

-- System Events

---@param fn fun()
---@return BindingFactory
function BindingFactory:onEndHealthBarDrag(fn)
    self._specs[#self._specs + 1] = { name = "OnEndHealthBarDrag", fn = fn, kind = "system", event = Constants.SystemEvents.OnEndHealthBarDrag }
    return self
end

-- Custom Events (framework-dispatched, no engine registration)

---@param fn fun(text: wstring)
---@return BindingFactory
function BindingFactory:onTextChanged(fn)
    self._specs[#self._specs + 1] = { name = "OnTextChanged", fn = fn }
    return self
end

---@param fn fun()
---@return BindingFactory
function BindingFactory:onKeyEnter(fn)
    self._specs[#self._specs + 1] = { name = "OnKeyEnter", fn = fn }
    return self
end

---@param fn fun()
---@return BindingFactory
function BindingFactory:onKeyEscape(fn)
    self._specs[#self._specs + 1] = { name = "OnKeyEscape", fn = fn }
    return self
end

---@param fn fun(width: number, height: number)
---@return BindingFactory
function BindingFactory:onDimensionsChanged(fn)
    self._specs[#self._specs + 1] = { name = "OnDimensionsChanged", fn = fn }
    return self
end

---@class View : Component
---@field _model ViewModel
---@field _bindings table<string, function>
---@field _entityBindings table<string, DataEvent>
---@field exists boolean
---@field parentRoot boolean
---@field alpha number
---@field scale number
---@field showing boolean
---@field popable boolean
---@field movable boolean
---@field moving boolean
---@field color Color
---@field id integer
---@field parent string
---@field dimensions {x: number, y: number}
---@field offsetFromParent {x: number, y: number}
---@field position {x: number, y: number}
---@field handleInput boolean
---@field resizing boolean
---@field focused boolean
---@field relativeScale number
---@field sticky boolean
local View = {}
View.__index = View

---@class Window : View
---@field _model WindowModel?
---@field _children Window[] A list of child windows.
---@field _frame string The name of the window's frame component.
---@field _background string The name of the window's background component.
---@field _startDrag SystemData.Position x, y coordinates for tracking how far the window was dragged
---@field _endDrag SystemData.Position x, y coordinates for tracking how far the window was dragged
---@field frame Window The frame sub-window (read-only, lazy)
---@field background Window The background sub-window (read-only, lazy)
---@field children Window[] Set the children array
local Window = {}
Window.__index = Window

-- ========================================================================== --
-- Components - Internal Builders
-- ========================================================================== --

-- ========================================================================== --
-- Components - Internal Builders - Layer Builder
-- ========================================================================== --

---@class LayerFactory
local LayerFactory = {}
LayerFactory.__index = LayerFactory

---@return number
function LayerFactory:default()
    return Constants.WindowLayers.Default
end

---@return number
function LayerFactory:overlay()
    return Constants.WindowLayers.Overlay
end

---@return number
function LayerFactory:popup()
    return Constants.WindowLayers.Popup
end

---@return number
function LayerFactory:background()
    return Constants.WindowLayers.Background
end

-- ========================================================================== --
-- Components - Internal Builders - Anchor Builder
-- ========================================================================== --

---@class AnchorFactory
---@field _parent string
local AnchorFactory = {}
AnchorFactory.__index = AnchorFactory

---@param parent string
---@return AnchorFactory
function AnchorFactory:new(parent)
    local instance = setmetatable({}, self)
    instance._parent = parent
    return instance
end

--- Returns an anchor spec.
---@param point string The anchor point on this view.
---@param relativeTo string The name of the window to anchor to.
---@param relativePoint string The anchor point on the relative window.
---@param x number? X offset (default 0).
---@param y number? Y offset (default 0).
---@return table
function AnchorFactory:add(point, relativeTo, relativePoint, x, y)
    return {point, relativeTo, relativePoint, x or 0, y or 0}
end

--- Convenience: centers the view in a target window.
---@param windowName string? The window to center in (defaults to parent).
---@param x number? X offset (default 0).
---@param y number? Y offset (default 0).
---@return table
function AnchorFactory:centerIn(windowName, x, y)
    return self:add("center", windowName or self._parent, "center", x, y)
end

--- Convenience: centers the view in its parent.
---@param x number? X offset (default 0).
---@param y number? Y offset (default 0).
---@return table
function AnchorFactory:toParentCenter(x, y)
    return self:centerIn(self._parent, x, y)
end

--- Convenience: anchors to the top of the parent.
---@param x number? X offset (default 0).
---@param y number? Y offset (default 0).
---@return table
function AnchorFactory:toParentTop(x, y)
    return self:add("top", self._parent, "top", x, y)
end

-- ========================================================================== --
-- Components - Internal Builders - Log Display Builder
-- ========================================================================== --

---@class LogEntryBuilder
---@field name string
---@field displayPreviousEntry boolean
---@field _filters table[]
local LogEntryBuilder = {}
LogEntryBuilder.__index = LogEntryBuilder

---@param name string
---@param displayPreviousEntry boolean?
---@return LogEntryBuilder
function LogEntryBuilder:new(name, displayPreviousEntry)
    local instance = setmetatable({}, self)
    instance.name = name
    instance.displayPreviousEntry = displayPreviousEntry or false
    instance._filters = {}
    return instance
end

--- Adds a filter color to this log entry.
---@param filterId number
---@param color Color
---@return LogEntryBuilder
function LogEntryBuilder:filterColor(filterId, color)
    table.insert(self._filters, { filterId = filterId, color = color })
    return self
end

--- Adds a filter state to this log entry.
---@param filterId number
---@param enabled boolean
---@return LogEntryBuilder
function LogEntryBuilder:filterState(filterId, enabled)
    table.insert(self._filters, { filterId = filterId, enabled = enabled })
    return self
end

-- ========================================================================== --
-- Components - Internal Builders - Layout Builder
-- ========================================================================== --

local Layouts = {}

Layouts.StackAndFill = function(window, children, child, index)
    if index > 1 then
        child.anchors = child:anchorBuilder(function(a)
            return { a:add("bottomleft", children[index - 1].name, "topleft", 0, 8) }
        end)
    else
        child.anchors = child:anchorBuilder(function(a)
            return { a:add("topleft", window.name, "topleft", 12, 12) }
        end)
    end

    local parentDimens = window.dimensions
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

    child.dimensions = { childWidth, childHeight }
end

-- ========================================================================== --
-- Components - Button
-- ========================================================================== --

---@param model ButtonModel?
---@return Button
function Button:new(model)
    model = model or {}
    model.Template = model.Template or "MongbatButton"
    local instance = View.new(self, model)
    return instance --[[@as Button]]
end

---@param model ButtonModel?
---@return Button
function Components.Button(model)
    local button = Button:new(model)
    Cache[button.name] = button
    return button
end

Button._ownProperties = {
    text = {
        get = function(self) return Api.Button.GetText(self.name) end,
        set = function(self, v)
            if v == nil then return end
            Api.Button.SetText(self.name, Utils.String.ToWString(v))
        end,
    },
    checked = {
        get = function(self) return Api.Button.IsChecked(self.name) end,
        set = function(self, v) Api.Button.SetChecked(self.name, v) end,
    },
    stayDown = {
        set = function(self, v) Api.Button.SetStayDown(self.name, v) end,
    },
    textDimensions = {
        get = function(self) return Api.Button.GetTextDimensions(self.name) end,
    },
    checkButton = {
        set = function(self, v) Api.Button.SetEnabled(self.name, v) end,
    },
}

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
    Api.CircleImage.SetTexture(self.name, texture, x, y)
end

function CircleImage:SetFillParams(startAngle, fillAngle)
    Api.CircleImage.SetFillParams(self.name, startAngle, fillAngle)
end

CircleImage._ownProperties = {
    textureSlice = {
        set = function(self, v) Api.CircleImage.SetTextureSlice(self.name, v) end,
    },
    textureScale = {
        set = function(self, v) Api.CircleImage.SetTextureScale(self.name, v) end,
    },
    rotation = {
        set = function(self, v) Api.CircleImage.SetRotation(self.name, v) end,
    },
}

---@param model CircleImageModel?
---@return CircleImage
function Components.CircleImage(model)
    local circleImage = CircleImage:new(model)
    Cache[circleImage.name] = circleImage
    return circleImage
end

-- ========================================================================== --
-- Components - Component
-- ========================================================================== --

---@param name string
---@return Component
function Component:new(name)
    local instance = setmetatable({}, getClassMetatable(self))
    rawset(instance, 'name', name)
    return instance
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

--- Disables the default component by saving all functions on the original
--- global table and replacing them with no-ops.  Mod code can then write
--- specific overrides directly to the original table (via getDefault()),
--- and those overrides will execute normally because they replace the no-ops.
--- restore() puts back every saved function, wiping any overrides too.
function DefaultComponent:disable()
    local saved = {}
    for k, v in pairs(self._original) do
        if type(v) == "function" then
            saved[k] = v
            self._original[k] = function() end
        end
    end
    self._saved = saved
end

--- Restores all functions saved by disable(), reverting the original global
--- table to its pre-disable state and clearing any mod overrides.
function DefaultComponent:restore()
    if self._saved then
        for k, v in pairs(self._saved) do
            self._original[k] = v
        end
        self._saved = nil
    end
end

DefaultComponent._ownProperties = {
    default = {
        get = function(self) return self._original end,
    },
}

--- Returns a Window wrapping this default component's engine window.
---@return Window
function DefaultComponent:asComponent()
    return Window:new { Name = self.name }
end

--- Factory: creates a DefaultComponent that wraps the given global table.
---@param name string        Display/lookup name (e.g. "StatusWindow")
---@param globalKey string   The key in _G (unused now, kept for clarity in call sites)
---@param original table     The original global table
---@param opts { init: fun(original: table)?, methods: table<string, function>? }?
---@return DefaultComponent
function DefaultComponent.create(name, globalKey, original, opts)
    local instance = DefaultComponent:new(name)
    instance._original = original

    if opts then
        if opts.init then
            opts.init(original)
        end
        if opts.methods then
            for k, v in pairs(opts.methods) do
                instance[k] = v
            end
        end
    end

    return instance
end

-- ========================================================================== --
-- Components - Default - Type Annotations
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

---@class DefaultShopkeeper
---@field Initialize fun(mobileId: integer)
---@field Shutdown fun()

---@class DefaultHealthBarManager
---@field OnBeginDragHealthBar fun(objectId: integer)

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

---@class DefaultMapCommon
---@class DefaultMapWindow
---@class DefaultObjectHandle
---@field CreateObjectHandles fun()
---@field DestroyObjectHandles fun()

---@class DefaultWarShield

---@class DefaultPaperdollWindow
---@field Initialize fun()
---@field Shutdown fun()
---@field UpdatePaperdoll fun(windowName: string, paperdollId: integer)
---@field HandleUpdatePaperdollEvent fun()

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

---@param model DynamicImageModel?
---@return DynamicImage
function Components.DynamicImage(model)
    local dynamicImage = DynamicImage:new(model)
    Cache[dynamicImage.name] = dynamicImage
    return dynamicImage
end

DynamicImage._ownProperties = {
    hasTexture = {
        get = function(self) return Api.DynamicImage.HasTexture(self.name) end,
    },
    texture = {
        set = function(self, v)
            Api.DynamicImage.SetTexture(self.name, v[1], v[2], v[3])
        end,
    },
    textureSlice = {
        set = function(self, v) Api.DynamicImage.SetTextureSlice(self.name, v) end,
    },
    textureScale = {
        set = function(self, v) Api.DynamicImage.SetTextureScale(self.name, v) end,
    },
    rotation = {
        set = function(self, v) Api.DynamicImage.SetRotation(self.name, v) end,
    },
    textureDimensions = {
        set = function(self, v)
            Api.DynamicImage.SetTextureDimensions(self.name, v[1] or v.x, v[2] or v.y)
        end,
    },
    textureOrientation = {
        set = function(self, v) Api.DynamicImage.SetTextureOrientation(self.name, v) end,
    },
}

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

function EditTextBox:selectAll()
    Api.EditTextBox.SelectAll(self.name)
end

function EditTextBox:clear()
    Api.EditTextBox.SetText(self.name, L"")
end

---@param model EditTextBoxModel?
---@return EditTextBox
function Components.EditTextBox(model)
    local editTextBox = EditTextBox:new(model)
    Cache[editTextBox.name] = editTextBox
    return editTextBox
end

EditTextBox._ownProperties = {
    text = {
        get = function(self) return Api.EditTextBox.GetText(self.name) end,
        set = function(self, v)
            if v == nil then return end
            Api.EditTextBox.SetText(self.name, Utils.String.ToWString(v))
        end,
    },
    textColor = {
        set = function(self, v) Api.EditTextBox.SetTextColor(self.name, v.r, v.g, v.b) end,
    },
    font = {
        set = function(self, v) Api.EditTextBox.SetFont(self.name, v) end,
    },
}

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

FilterInput._ownProperties = {
    filterText = {
        get = function(self) return self.text end,
    },
}

---@param model FilterInputModel?
---@return FilterInput
function Components.FilterInput(model)
    local filterInput = FilterInput:new(model)
    Cache[filterInput.name] = filterInput
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

--- Dispatches an event to the active window via Active.window().
---@param callback fun(window: View)
local function withActiveView(_, callback)
    local window = Cache[Active.window()]
    if window == nil then return end
    callback(window)
end

--- Dispatches an event to the mouse-over window.
---@param callback fun(window: View)
local function withMouseOverView(_, callback)
    local mouseOverWindow = SystemData.MouseOverWindow
    if mouseOverWindow == nil then return end

    local name = mouseOverWindow.name
    if name == nil or name == "" then return end

    local window = Cache[name]
    if window == nil then return end

    callback(window)
end

function EventHandler.OnInitialize()
    withActiveView("OnInitialize", function(window)
        window:onInitialize()
    end)
end

function EventHandler.OnShutdown()
    local activeWindowName = Active.window()
    local window = Cache[activeWindowName]
    Cache[activeWindowName] = nil
    if window == nil then return end
    window:onShutdown()
end

--- Stops an active resize and re-layouts children.
local function stopResize()
    if resizingWindow == nil then return end
    local window = resizingWindow
    resizingWindow = nil
    resizeState = nil

    -- Restore the original OnUpdate binding
    window._bindings.OnUpdate = resizeOriginalOnUpdate

    -- If we dynamically registered OnUpdate, unregister it
    if resizeRegisteredOnUpdate then
        window:unregisterCoreEventHandler(Constants.CoreEvents.OnUpdate)
        resizeRegisteredOnUpdate = false
    end

    resizeOriginalOnUpdate = nil

    -- Re-layout children
    if window._model.OnLayout then
        Utils.Array.ForEach(window._children, function(child, index)
            window._model.OnLayout(window, window._children, child, index)
        end)
    end

    -- Ensure the window is no longer in a moving state
    Api.Window.SetMoving(window.name, false)
end

--- Begins a live resize for the given window. Injects a per-frame OnUpdate
--- handler on the window itself, chaining any existing OnUpdate.
---@param window Window
local function startResize(window)
    -- Cancel any in-progress resize first
    if resizingWindow ~= nil then stopResize() end

    resizingWindow = window
    local mousePos = SystemData.MousePosition
    local dimens = window.dimensions
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

    -- Save the original OnUpdate binding and inject our resize handler
    resizeOriginalOnUpdate = window._bindings.OnUpdate

    window._bindings.OnUpdate = function(timePassed)
        -- Perform resize calculations
        if resizingWindow ~= nil and resizeState ~= nil then
            local mPos = SystemData.MousePosition
            local scale = InterfaceCore.scale
            local dx = (mPos.x - resizeState.startMouseX) / scale
            local dy = (mPos.y - resizeState.startMouseY) / scale
            local newW = math.max(resizeState.startWidth + dx, resizeState.minWidth)
            local newH = math.max(resizeState.startHeight + dy, resizeState.minHeight)
            resizingWindow.dimensions = { newW, newH }

            -- Re-layout children each frame so content tracks the new size
            if resizingWindow._model.OnLayout then
                Utils.Array.ForEach(resizingWindow._children, function(child, index)
                    resizingWindow._model.OnLayout(resizingWindow, resizingWindow._children, child, index)
                end)
            end
        end

        -- Chain the original OnUpdate if it existed
        if resizeOriginalOnUpdate ~= nil then
            resizeOriginalOnUpdate(timePassed)
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
    withActiveView("OnLButtonUp", function(window)
        lbuttonUpHandledView = window.name
        window:onLButtonUp(flags, x, y)
    end)
end

--- SystemEvent fallback for L_BUTTON_UP_PROCESSED.  Handles two cases:
--- 1) Resize termination when the cursor is not over any Mongbat view.
--- 2) Cross-window drag-and-drop: the drop target (MouseOverWindow) differs
---    from the CoreEvent's ActiveWindow, so the CoreEvent handler above
---    never dispatches to it.
function EventHandler.OnLButtonUpProcessed(flags, x, y)
    if resizingWindow ~= nil then
        stopResize()
    end
    withMouseOverView("OnLButtonUp", function(window)
        -- Skip if the CoreEvent already dispatched to this exact view
        if window.name ~= lbuttonUpHandledView then
            window:onLButtonUp(flags, x, y)
        end
    end)
    lbuttonUpHandledView = nil
end

function EventHandler.OnLButtonDown(flags, x, y)
    withActiveView("OnLButtonDown", function(window)
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
    withActiveView("OnUpdatePlayerStatus", function(view)
        view:onUpdatePlayerStatus()
    end)
end

function EventHandler.OnUpdateMobileName()
    withActiveView("OnUpdateMobileName", function(view)
        view:onUpdateMobileName()
    end)
end

function EventHandler.OnUpdateHealthBarColor()
    withActiveView("OnUpdateHealthBarColor", function(view)
        view:onUpdateHealthBarColor()
    end)
end

function EventHandler.OnUpdateMobileStatus()
    withActiveView("OnUpdateMobileStatus", function(view)
        view:onUpdateMobileStatus()
    end)
end

function EventHandler.OnUpdatePaperdoll()
    withActiveView("OnUpdatePaperdoll", function(view)
        view:onUpdatePaperdoll()
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
    withActiveView("OnUpdateRadar", function(view)
        view:onUpdateRadar(WindowData.Radar)
    end)
end

function EventHandler.OnUpdatePlayerLocation()
    withActiveView("OnUpdatePlayerLocation", function(view)
        view:onUpdatePlayerLocation(WindowData.PlayerLocation)
    end)
end

function EventHandler.OnUpdateShopData()
    withActiveView("OnUpdateShopData", function(view)
        view:onUpdateShopData()
    end)
end

function EventHandler.OnUpdateContainerWindow()
    withActiveView("OnUpdateContainerWindow", function(view)
        view:onUpdateContainerWindow()
    end)
end

function EventHandler.OnUpdateObjectInfo()
    withActiveView("OnUpdateObjectInfo", function(view)
        view:onUpdateObjectInfo()
    end)
end

function EventHandler.OnUpdateItemProperties()
    withActiveView("OnUpdateItemProperties", function(view)
        view:onUpdateItemProperties()
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

Gump._ownProperties = {
    vendorSearch = {
        get = function(self) return self._id == 999112 end,
    },
    jewelryBox = {
        get = function(self) return self._id == 999143 end,
    },
}

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

function Label:centerText()
    self.textAlignment = Constants.TextAlignment.Center
end

---@param model LabelModel?
---@return Label
function Components.Label(model)
    local label = Label:new(model)
    Cache[label.name] = label
    return label
end

Label._ownProperties = {
    text = {
        set = function(self, v)
            if v == nil then return end
            Api.Label.SetText(self.name, Utils.String.ToWString(v))
        end,
    },
    textColor = {
        set = function(self, v) Api.Label.SetTextColor(self.name, v) end,
    },
    textAlignment = {
        set = function(self, v) Api.Label.SetTextAlignment(self.name, v) end,
    },
}

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

--- Builds log entries via a callback that receives a factory.
--- The callback should return an array of LogEntryBuilder objects.
---@param fn fun(log: { newLog: fun(self: any, name: string, displayPreviousEntry: boolean?): LogEntryBuilder }): LogEntryBuilder[]
---@return LogEntryBuilder[]
function LogDisplay:logBuilder(fn)
    local factory = {}
    function factory:newLog(name, displayPreviousEntry)
        return LogEntryBuilder:new(name, displayPreviousEntry)
    end
    return fn(factory)
end

LogDisplay._ownProperties = {
    logs = {
        set = function(self, v)
            for i = 1, #v do
                local entry = v[i]
                Api.LogDisplay.AddLog(self.name, entry.name, entry.displayPreviousEntry)
                for j = 1, #entry._filters do
                    local filter = entry._filters[j]
                    if filter.color then
                        Api.LogDisplay.SetFilterColor(self.name, entry.name, filter.filterId, filter.color)
                    end
                    if filter.enabled ~= nil then
                        Api.LogDisplay.SetFilterState(self.name, entry.name, filter.filterId, filter.enabled)
                    end
                end
            end
        end,
    },
    timestampVisible = {
        set = function(self, v) Api.LogDisplay.ShowTimestamp(self.name, v) end,
    },
    logNameVisible = {
        set = function(self, v) Api.LogDisplay.ShowLogName(self.name, v) end,
    },
    filterNameVisible = {
        set = function(self, v) Api.LogDisplay.ShowFilterName(self.name, v) end,
    },
}

---@param model LogDisplayModel?
---@return LogDisplay
function Components.LogDisplay(model)
    local logDisplay = LogDisplay:new(model)
    Cache[logDisplay.name] = logDisplay
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
    local instance = View.new(self, model) --[[@as ScrollWindow]]
    instance._items = {}
    return instance
end

---@return string
function ScrollWindow:_getContainerName()
    -- Must be "Cont" to match XML template's $parentCont variable expansion
    return self.name .. "Cont"
end

function ScrollWindow:onInitialize()
    View.onInitialize(self)
end

function ScrollWindow:onShutdown()
    self:clearItems()
    View.onShutdown(self)
end

function ScrollWindow:onDimensionsChanged(width, height)
    self:_updateLayout()
    View.onDimensionsChanged(self, width, height)
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
    view.parent = contName
    if self.horizontal then
        local itemWidth = self:_getItemWidth()
        local xOffset = #self._items * itemWidth
        view.anchors = view:anchorBuilder(function(a)
            return { a:add("topleft", contName, "topleft", xOffset, 0) }
        end)
    else
        local itemHeight = self:_getItemHeight()
        local yOffset = #self._items * itemHeight
        view.anchors = view:anchorBuilder(function(a)
            return { a:add("topleft", contName, "topleft", 0, yOffset) }
        end)
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
    view:destroy()
    Utils.Array.Remove(self._items, idx)
    self:_updateLayout()
end

--- Destroys all items and resets the scroll offset.
function ScrollWindow:clearItems()
    Utils.Array.ForEach(self._items, function(item)
        item:destroy()
    end)
    self._items = {}
    self:_updateLayout()
    self.offset = 0
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
    if self.horizontal then
        local itemWidth = self:_getItemWidth()
        Utils.Array.ForEach(self._items, function(item, index)
            item.anchors = item:anchorBuilder(function(a)
                return { a:add("topleft", contName, "topleft", (index - 1) * itemWidth, 0) }
            end)
        end)
        local dims = self.dimensions
        local totalWidth = #self._items * itemWidth
        Api.Window.SetDimensions(contName, totalWidth, dims.y)
        Api.HorizontalScrollWindow.UpdateScrollRect(self.name)
    else
        local itemHeight = self:_getItemHeight()
        Utils.Array.ForEach(self._items, function(item, index)
            local yOffset = (index - 1) * itemHeight
            item.anchors = item:anchorBuilder(function(a)
                return {
                    a:add("topleft", contName, "topleft", 0, yOffset),
                    a:add("topright", contName, "topright", 0, yOffset),
                }
            end)
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

ScrollWindow._ownProperties = {
    horizontal = {
        get = function(self) return self._model.Horizontal == true end,
    },
    itemCount = {
        get = function(self) return #self._items end,
    },
    offset = {
        set = function(self, v)
            if self.horizontal then
                Api.HorizontalScrollWindow.SetOffset(self.name, v)
            else
                Api.ScrollWindow.SetOffset(self.name, v)
            end
        end,
    },
}

--- Manually triggers a scroll rect update. Call this if the items in the
--- scroll area are resized externally.
---@return ScrollWindow
function ScrollWindow:updateScrollRect()
    if self.horizontal then
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
    Cache[scrollWindow.name] = scrollWindow
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
    local name = self.name
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
    local dims = self.dimensions
    Api.Window.SetDimensions(fillName, 0, dims.y)
    self._fillChild = fillName

    local label = self.label
    if label ~= nil then
        label:create(true)
        label:onInitialize()
        label._parentWindow = self
        label.parent = self.parent

        local dimens = self.dimensions
        label.dimensions = dimens
        label:centerText()

        label.anchors = label:anchorBuilder(function(a)
            return { a:add("center", self.name, "center", 0, 0) }
        end)
    end
end

function StatusBar:_updateFill()
    if not self._fillChild then return end
    local maxVal = self._maxValue or 0
    local curVal = self._currentValue or 0
    local dims = self.dimensions
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
        self.label.dimensions = { width, height }
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

---@param model StatusBarModel?
---@param labelModel LabelModel?
---@return StatusBar
function Components.StatusBar(model, labelModel)
    local label

    if labelModel ~= nil then
        label = Components.Label(labelModel)
    end

    local statusBar = StatusBar:new(model, label)
    Cache[statusBar.name] = statusBar
    return statusBar
end

StatusBar._ownProperties = {
    maxValue = {
        get = function(self) return rawget(self, '_maxValue') end,
        set = function(self, v)
            rawset(self, '_maxValue', v)
            Api.StatusBar.SetMaxValue(self.name, v)
            self:_updateFill()
        end,
    },
    currentValue = {
        get = function(self) return rawget(self, '_currentValue') end,
        set = function(self, v)
            rawset(self, '_currentValue', v)
            Api.StatusBar.SetCurrentValue(self.name, v)
            self:_updateFill()
        end,
    },
    foregroundTint = {
        set = function(self, v)
            local fill = rawget(self, '_fillChild')
            if fill then Api.Window.SetColor(fill, v) end
        end,
    },
    backgroundTint = {
        set = function(self, v) Api.StatusBar.SetBackgroundTint(self.name, v) end,
    },
    color = {
        set = function(self, v)
            local fill = rawget(self, '_fillChild')
            if fill then Api.Window.SetColor(fill, v) end
        end,
    },
}

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

SliderBar._ownProperties = {
    currentPosition = {
        get = function(self) return Api.Slider.GetCurrentPosition(self.name) end,
        set = function(self, v) Api.Slider.SetCurrentPosition(self.name, v) end,
    },
}

---@param model SliderBarModel?
---@return SliderBar
function Components.SliderBar(model)
    local sliderBar = SliderBar:new(model)
    Cache[sliderBar.name] = sliderBar
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
    Api.ComboBox.AddItem(self.name, item)
    return self
end

---@return ComboBox
function ComboBox:clearItems()
    Api.ComboBox.ClearItems(self.name)
    return self
end

ComboBox._ownProperties = {
    selectedItem = {
        get = function(self) return Api.ComboBox.GetSelectedItem(self.name) end,
        set = function(self, v) Api.ComboBox.SetSelectedItem(self.name, v) end,
    },
}

---@param model ComboBoxModel?
---@return ComboBox
function Components.ComboBox(model)
    local comboBox = ComboBox:new(model)
    Cache[comboBox.name] = comboBox
    return comboBox
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

    Api.Button.SetEnabled(self.name, true)
    Api.Button.SetStayDown(self.name, true)

    local label = self.label
    if label ~= nil then
        local checkBox = self

        label:create(true)
        label:onInitialize()
        label._parentWindow = checkBox

        -- Always toggle the checkbox when the label is clicked
        label.bindings = BindingFactory:new()
            :onLButtonDown(function()
                checkBox.checked = not checkBox.checked
            end)
            :build()

        label.parent = self.parent

        local dims = self.dimensions
        label.anchors = label:anchorBuilder(function(a)
            return { a:add("left", self.name, "right", 4, 0) }
        end)
        label.dimensions = { label.dimensions.x, dims.y }
        label:centerText()
    end
end

function CheckBox:onShutdown()
    if self.label ~= nil then
        self.label:destroy()
    end
    View.onShutdown(self)
end

--- Toggles the checked state.
---@return CheckBox
function CheckBox:toggle()
    self.checked = not self.checked
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
    Cache[checkBox.name] = checkBox
    return checkBox
end

CheckBox._ownProperties = {
    checked = {
        get = function(self) return Api.Button.IsChecked(self.name) end,
        set = function(self, v) Api.Button.SetChecked(self.name, v) end,
    },
}

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
    Api.AnimatedImage.SetTexture(self.name, texture)
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
        self.name,
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
    Api.AnimatedImage.StopAnimation(self.name)
    return self
end

AnimatedImage._ownProperties = {
    texture = {
        set = function(self, v) Api.AnimatedImage.SetTexture(self.name, v) end,
    },
    playSpeed = {
        set = function(self, v) Api.AnimatedImage.SetPlaySpeed(self.name, v) end,
    },
}

---@param model AnimatedImageModel?
---@return AnimatedImage
function Components.AnimatedImage(model)
    local animatedImage = AnimatedImage:new(model)
    Cache[animatedImage.name] = animatedImage
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
    Api.ActionButton.SetAction(self.name, actionType, actionId)
    return self
end

ActionButton._ownProperties = {
    action = {
        get = function(self) return Api.ActionButton.GetAction(self.name) end,
    },
    gameActionTrigger = {
        set = function(self, v) Api.ActionButton.SetGameActionTrigger(self.name, v) end,
    },
}

---@param model ActionButtonModel?
---@return ActionButton
function Components.ActionButton(model)
    local actionButton = ActionButton:new(model)
    Cache[actionButton.name] = actionButton
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
            Name = self.name .. "Button" .. i,
            Id = i,
        }
        button:create(true)
        button:onInitialize()

        local specs = BindingFactory:new()
            :onLButtonDown(function(flags, x, y)
                if group._model.OnButtonLButtonDown then
                    group._model.OnButtonLButtonDown(group, button, i, flags, x, y)
                end
            end)
            :onLButtonUp(function(flags, x, y)
                if group._model.OnButtonLButtonUp then
                    group._model.OnButtonLButtonUp(group, button, i, flags, x, y)
                end
            end)
        if group._model.OnButtonRButtonUp then
            specs:onRButtonUp(function(flags, x, y)
                group._model.OnButtonRButtonUp(group, button, i, flags, x, y)
            end)
        end
        if group._model.OnButtonMouseOver then
            specs:onMouseOver(function()
                group._model.OnButtonMouseOver(group, button, i)
            end)
        end
        if group._model.OnButtonMouseOverEnd then
            specs:onMouseOverEnd(function()
                group._model.OnButtonMouseOverEnd(group, button, i)
            end)
        end
        button.bindings = specs:build()

        button.parent = self.name
        button.dimensions = { buttonSize, buttonSize }
        if i == 1 then
            button.anchors = button:anchorBuilder(function(a)
                return { a:add("topleft", self.name, "topleft", 0, 0) }
            end)
        else
            button.anchors = button:anchorBuilder(function(a)
                return { a:add("topleft", self._buttons[i - 1].name, "topright", spacing, 0) }
            end)
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

ActionButtonGroup._ownProperties = {
    buttonCount = {
        get = function(self) return #self._buttons end,
    },
}

---@param model ActionButtonGroupModel?
---@return ActionButtonGroup
function Components.ActionButtonGroup(model)
    local group = ActionButtonGroup:new(model)
    Cache[group.name] = group
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
    Cache[cooldownDisplay.name] = cooldownDisplay
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
    Api.Window.SavePosition(self.name, true, self.name)
    Window.onShutdown(self)
end

--- Restores a previously saved position.
---@param trackSize boolean? Whether to also restore size (default false).
---@return DockableWindow
function DockableWindow:restorePosition(trackSize)
    Api.Window.RestorePosition(self.name, trackSize or false, self.name)
    return self
end

---@param model DockableWindowModel?
---@return DockableWindow
function Components.DockableWindow(model)
    local dockableWindow = DockableWindow:new(model)
    Cache[dockableWindow.name] = dockableWindow
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
    Api.PageWindow.SetActivePage(self.name, pageNumber)
    return self
end

PageWindow._ownProperties = {
    activePage = {
        get = function(self) return Api.PageWindow.GetActivePage(self.name) end,
        set = function(self, v) Api.PageWindow.SetActivePage(self.name, v) end,
    },
    numPages = {
        get = function(self) return Api.PageWindow.GetNumPages(self.name) end,
    },
}

--- Advances to the next page. Wraps around to the first page when at the end.
---@return PageWindow
function PageWindow:nextPage()
    local current = self.activePage
    local total = self.numPages
    if current < total then
        self.activePage = current + 1
    else
        self.activePage = 1
    end
    return self
end

--- Goes to the previous page. Wraps around to the last page when at the start.
---@return PageWindow
function PageWindow:previousPage()
    local current = self.activePage
    local total = self.numPages
    if current > 1 then
        self.activePage = current - 1
    else
        self.activePage = total
    end
    return self
end

---@param model PageWindowModel?
---@return PageWindow
function Components.PageWindow(model)
    local pageWindow = PageWindow:new(model)
    Cache[pageWindow.name] = pageWindow
    return pageWindow
end


---@param model ViewModel
---@return View
function View:new(model)
    local name = model.Name or Utils.String.Random()
    local instance = Component.new(self, name) --[[@as View]]
    instance._model = model
    instance._bindings = {}
    instance._entityBindings = {}
    instance._bindingSpecs = {}
    return instance
end

function View:onInitialize()
    local id = self._model.Id or Utils.String.ExtractNumber(self.name)
    self.id = id

    local prefix = "Mongbat.EventHandler."

    self:registerCoreEventHandler(
        Constants.CoreEvents.OnShutdown,
        prefix .. Constants.CoreEvents.OnShutdown
    )

    -- Always register OnLButtonDown and OnLButtonUp as CoreEvents so the
    -- engine tracks input state per-window.  This is required for buttons,
    -- resize grips, and to prevent movable MaskWindows from auto-starting
    -- movement without going through the framework's handler.
    self:registerCoreEventHandler(
        Constants.CoreEvents.OnLButtonDown,
        prefix .. Constants.CoreEvents.OnLButtonDown
    )
    self:registerCoreEventHandler(
        Constants.CoreEvents.OnLButtonUp,
        prefix .. Constants.CoreEvents.OnLButtonUp
    )

    if self._model.OnInitialize ~= nil then
        self._model.OnInitialize(self)
    end
end

function View:onShutdown()
    if self._model.OnShutdown ~= nil then
        self._model.OnShutdown(self)
    end

    self.id = 0

    -- Unregister all bindings
    for i = 1, #self._bindingSpecs do
        local spec = self._bindingSpecs[i]
        if spec.kind == "core" then
            self:unregisterCoreEventHandler(spec.name)
        elseif spec.kind == "data" then
            self:unregisterEventHandler(spec.event.getEvent())
        elseif spec.kind == "system" then
            self:unregisterEventHandler(spec.event.getEvent())
        end
    end

    self._bindings = {}
    self._entityBindings = {}
    self._bindingSpecs = {}
end

function View:onLButtonUp(flags, x, y)
    local fn = self._bindings.OnLButtonUp
    if fn then
        fn(flags, x, y)
        return true
    end
    if self._parentWindow then
        return self._parentWindow:onLButtonUp(flags, x, y)
    end
    return false
end

function View:onMouseWheel(x, y, delta)
    local fn = self._bindings.OnMouseWheel
    if fn then
        fn(x, y, delta)
        return true
    end
    return false
end

function View:onLButtonDown(flags, x, y)
    local fn = self._bindings.OnLButtonDown
    if fn then
        fn(flags, x, y)
        return true
    end
    if self._parentWindow then
        return self._parentWindow:onLButtonDown(flags, x, y)
    end
    return false
end

function View:onRButtonUp(flags, x, y)
    local fn = self._bindings.OnRButtonUp
    if fn then
        fn(flags, x, y)
        return true
    end
    if self._parentWindow then
        return self._parentWindow:onRButtonUp(flags, x, y)
    end
    return false
end

function View:onRButtonDown(flags, x, y)
    local fn = self._bindings.OnRButtonDown
    if fn then
        fn(flags, x, y)
        return true
    end
    return false
end

function View:onHidden()
    local fn = self._bindings.OnHidden
    if fn then
        fn()
        return true
    end
    return false
end

function View:onShown()
    local fn = self._bindings.OnShown
    if fn then
        fn()
        return true
    end
    return false
end

function View:onUpdate(timePassed, windowData)
    local fn = self._bindings.OnUpdate
    if fn then
        fn(timePassed, windowData)
        return true
    end
    return false
end

function View:onUpdatePlayerStatus()
    local fn = self._bindings.OnUpdatePlayerStatus
    if fn then
        fn(Data.PlayerStatus())
        return true
    end
    return false
end

function View:onUpdateMobileName()
    local fn = self._bindings.OnUpdateMobileName
    if fn then
        fn(Data.MobileName(self.id))
        return true
    end
    return false
end

function View:onUpdateHealthBarColor()
    local fn = self._bindings.OnUpdateHealthBarColor
    if fn then
        fn(Data.HealthBarColor(self.id))
        return true
    end
    return false
end

function View:onUpdateMobileStatus()
    local fn = self._bindings.OnUpdateMobileStatus
    if fn then
        fn(Data.MobileStatus(self.id))
        return true
    end
    return false
end

function View:onUpdatePaperdoll()
    local fn = self._bindings.OnUpdatePaperdoll
    if fn then
        fn(Data.Paperdoll(self.id))
        return true
    end
    return false
end

function View:onUpdateContainerWindow()
    local fn = self._bindings.OnUpdateContainerWindow
    if fn then
        local instanceId = Api.Window.GetUpdateInstanceId()
        fn(instanceId, Data.ContainerWindow(instanceId))
        return true
    end
    return false
end

function View:onUpdateObjectInfo()
    local fn = self._bindings.OnUpdateObjectInfo
    if fn then
        local instanceId = Api.Window.GetUpdateInstanceId()
        fn(instanceId, Data.ObjectInfo(instanceId))
        return true
    end
    return false
end

function View:onUpdateItemProperties()
    local fn = self._bindings.OnUpdateItemProperties
    if fn then
        local instanceId = Api.Window.GetUpdateInstanceId()
        fn(instanceId, Data.ItemProperties(instanceId))
        return true
    end
    return false
end

function View:onLButtonDblClk(flags, x, y)
    local fn = self._bindings.OnLButtonDblClk
    if fn then
        fn(flags, x, y)
        return true
    end
    if self._parentWindow then
        return self._parentWindow:onLButtonDblClk(flags, x, y)
    end
    return false
end

function View:onMouseOver()
    local fn = self._bindings.OnMouseOver
    if fn then
        fn()
        return true
    end
    if self._parentWindow then
        return self._parentWindow:onMouseOver()
    end
    return false
end

function View:onMouseOverEnd()
    local fn = self._bindings.OnMouseOverEnd
    if fn then
        fn()
        return true
    end
    if self._parentWindow then
        return self._parentWindow:onMouseOverEnd()
    end
    return false
end

function View:onEndHealthBarDrag()
    local fn = self._bindings.OnEndHealthBarDrag
    if fn then
        fn()
        return true
    end
    return false
end

---@param data WindowData.Radar
function View:onUpdateRadar(data)
    local fn = self._bindings.OnUpdateRadar
    if fn then
        fn(data)
        return true
    end
    return false
end

function View:onUpdatePlayerLocation(data)
    local fn = self._bindings.OnUpdatePlayerLocation
    if fn then
        fn(data)
        return true
    end
    return false
end

function View:onUpdateShopData()
    local fn = self._bindings.OnUpdateShopData
    if fn then
        fn()
        return true
    end
    return false
end



function View:onTextChanged(text)
    local fn = self._bindings.OnTextChanged
    if fn then
        fn(text)
        return true
    end
    return false
end

function View:onKeyEnter()
    local fn = self._bindings.OnKeyEnter
    if fn then
        fn()
        return true
    end
    return false
end

function View:onKeyEscape()
    local fn = self._bindings.OnKeyEscape
    if fn then
        fn()
        return true
    end
    return false
end

function View:onSlide()
    local fn = self._bindings.OnSlide
    if fn then
        fn(Api.Slider.GetCurrentPosition(self.name))
        return true
    end
    return false
end

function View:onSelChanged()
    local fn = self._bindings.OnSelChanged
    if fn then
        fn()
        return true
    end
    return false
end



function View:setId(id)
    id = id or 0
    local oldId = self.id

    if oldId == id then
        return
    end

    if oldId ~= 0 then
        for _, dataEvent in pairs(self._entityBindings) do
            Api.Window.UnregisterData(dataEvent.getType(), oldId)
        end
    end

    if id ~= 0 then
        for _, dataEvent in pairs(self._entityBindings) do
            Api.Window.RegisterData(dataEvent.getType(), id)
        end
    end

    Api.Window.SetId(self.name, id)
end

function View:matchParentWidth(percent)
    local parentDimen = Api.Window.GetDimensions(self.parent)
    local dimen = self.dimensions
    self.dimensions = { parentDimen.x * percent, dimen.y }
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

--- Called whenever this view's dimensions are set. Override in subclasses to
--- propagate size changes to internal sub-components (e.g. StatusBar's label).
---@param width number
---@param height number
function View:onDimensionsChanged(width, height)
    local fn = self._bindings.OnDimensionsChanged
    if fn then
        fn(width, height)
    end
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
    Api.Window.RegisterData(type, self.id)
end

function View:unregisterData(type)
    Api.Window.UnregisterData(type, self.id)
end

--- Builds anchor specs via a callback that receives an AnchorFactory.
---@param fn fun(anchor: AnchorFactory): table[]
---@return table[]
function View:anchorBuilder(fn)
    return fn(AnchorFactory:new(self.parent))
end

--- Builds a layer value via a callback that receives a LayerFactory.
---@param fn fun(layer: LayerFactory): number
---@return number
function View:layerBuilder(fn)
    return fn(LayerFactory)
end

--- Builds binding specs via a callback that receives a BindingFactory.
--- Returns the specs array for assignment to `self.bindings`.
---@param fn fun(bind: BindingFactory)
---@return BindingSpec[]
function View:bindingsBuilder(fn)
    local factory = BindingFactory:new()
    fn(factory)
    return factory:build()
end

View._ownProperties = {
    bindings = {
        set = function(self, specs)
            local prefix = "Mongbat.EventHandler."
            for i = 1, #specs do
                local spec = specs[i]
                self._bindings[spec.name] = spec.fn
                if spec.kind == "core" then
                    self:registerCoreEventHandler(spec.name, prefix .. spec.name)
                elseif spec.kind == "data" then
                    self:registerEventHandler(spec.event.getEvent(), prefix .. spec.name)
                    if spec.entity then
                        self._entityBindings[spec.name] = spec.event
                    end
                elseif spec.kind == "system" then
                    self:registerEventHandler(spec.event.getEvent(), prefix .. spec.name)
                end
            end
            for i = 1, #specs do
                self._bindingSpecs[#self._bindingSpecs + 1] = specs[i]
            end
        end,
    },
    exists = {
        get = function(self) return Api.Window.DoesExist(self.name) end,
    },
    parentRoot = {
        get = function(self) return self.parent == "Root" end,
    },
    alpha = {
        get = function(self) return Api.Window.GetAlpha(self.name) end,
        set = function(self, v) Api.Window.SetAlpha(self.name, v) end,
    },
    scale = {
        get = function(self) return Api.Window.GetScale(self.name) end,
        set = function(self, v) Api.Window.SetScale(self.name, v) end,
    },
    showing = {
        get = function(self) return Api.Window.IsShowing(self.name) end,
        set = function(self, v) Api.Window.SetShowing(self.name, v) end,
    },
    popable = {
        get = function(self) return Api.Window.IsPopable(self.name) end,
        set = function(self, v) Api.Window.SetPopable(self.name, v) end,
    },
    movable = {
        get = function(self) return Api.Window.IsMovable(self.name) end,
        set = function(self, v) Api.Window.SetMovable(self.name, v) end,
    },
    moving = {
        get = function(self) return Api.Window.IsMoving(self.name) end,
        set = function(self, v) Api.Window.SetMoving(self.name, v) end,
    },
    color = {
        get = function(self) return Api.Window.GetColor(self.name) end,
        set = function(self, v) Api.Window.SetColor(self.name, v) end,
    },
    id = {
        get = function(self) return Api.Window.GetId(self.name) end,
        set = function(self, v) View.setId(self, v) end,
    },
    parent = {
        get = function(self) return Api.Window.GetParent(self.name) end,
        set = function(self, v) Api.Window.SetParent(self.name, v) end,
    },
    dimensions = {
        get = function(self) return Api.Window.GetDimensions(self.name) end,
        set = function(self, v)
            local x = v.x or v[1]
            local y = v.y or v[2]
            local current = Api.Window.GetDimensions(self.name)
            if current.x == x and current.y == y then return end
            Api.Window.SetDimensions(self.name, x, y)
            self:onDimensionsChanged(x, y)
        end,
    },
    offsetFromParent = {
        get = function(self) return Api.Window.GetOffsetFromParent(self.name) end,
        set = function(self, v)
            Api.Window.SetOffsetFromParent(self.name, v.x or v[1], v.y or v[2])
        end,
    },
    position = {
        get = function(self) return Api.Window.GetPosition(self.name) end,
    },
    handleInput = {
        set = function(self, v) Api.Window.SetHandleInput(self.name, v) end,
    },
    resizing = {
        get = function(self) return Api.Window.IsResizing(self.name) end,
        set = function(self, v) Api.Window.SetResizing(self.name, v) end,
    },
    focused = {
        get = function(self) return Api.Window.HasFocus(self.name) end,
        set = function(self, v) Api.Window.AssignFocus(self.name, v) end,
    },
    relativeScale = {
        set = function(self, v) Api.Window.SetRelativeScale(self.name, v) end,
    },
    sticky = {
        get = function(self) return Api.Window.IsSticky(self.name) end,
    },
    anchors = {
        set = function(self, v)
            Api.Window.ClearAnchors(self.name)
            for i = 1, #v do
                local a = v[i]
                Api.Window.AddAnchor(self.name, a[1], a[2], a[3], a[4] or 0, a[5] or 0)
            end
        end,
    },
    layer = {
        set = function(self, v) Api.Window.SetLayer(self.name, v) end,
    },
}

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

--- Sets up a child view for event propagation and layout within a parent Window.
--- Sets _parentWindow for event bubbling and wraps OnInitialize for parenting/layout.
---@param parent Window
---@param child View
---@param index integer
local function wrapChildForParent(parent, child, index)
    if child._parentWrapped then return end
    child._parentWrapped = true
    child._parentWindow = parent

    local onChildInitialize = child._model.OnInitialize
    child._model.OnInitialize = function(c)
        c.parent = parent.name
        parent._model.OnLayout(parent, parent._children, c, index)
        if onChildInitialize ~= nil then
            onChildInitialize(c)
        end
    end
end

--- Creates and attaches a resize grip Button to the bottom-right corner of a Window.
---@param window Window
---@return Button
local function createResizeGrip(window)
    local grip = Components.Button { Template = "MongbatResizeGrip" }
    grip:create()
    grip:onInitialize()
    grip.bindings = BindingFactory:new()
        :onLButtonDown(function()
            startResize(window)
        end)
        :build()
    grip.parent = window.name
    grip.anchors = grip:anchorBuilder(function(a)
        return { a:add("bottomright", window.name, "bottomright", 0, 0) }
    end)
    grip.layer = grip:layerBuilder(function(l) return l:overlay() end)
    return grip
end

--- Registers a Window for edge-snapping with other snappable windows.
--- Sets up snap tracking state and ensures OnUpdate is registered.
---@param window Window
local function registerWindowSnap(window)
    SnappableWindows[window.name] = true
    window._wasMoving = false
    window._isSnapped = false
    if not window._bindings.OnUpdate then
        window._snapRegisteredOnUpdate = true
        window:registerCoreEventHandler(
            Constants.CoreEvents.OnUpdate,
            "Mongbat.EventHandler.OnUpdate"
        )
    end
end

--- Unregisters a Window from the snap system and cleans up tracking state.
---@param window Window
local function unregisterWindowSnap(window)
    SnappableWindows[window.name] = nil
    if window._snapRegisteredOnUpdate then
        window:unregisterCoreEventHandler(Constants.CoreEvents.OnUpdate)
        window._snapRegisteredOnUpdate = false
    end
    window._wasMoving = nil
end

--- Per-frame snap + group-drag logic. Called from Window:onUpdate when the
--- window is registered for snapping (_wasMoving ~= nil).
---@param window Window
local function updateWindowSnap(window)
    local isMoving = window.moving

    -- Drag start: compute the joined group and save offsets
    if isMoving and not window._wasMoving then
        local group = findJoinedGroup(window.name)
        local myRect = getWindowRect(window.name)
        local dragGroup = {}
        local exclude = { [window.name] = true }
        if myRect then
            for _, name in ipairs(group) do
                exclude[name] = true
                if name ~= window.name then
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
        window._dragGroup = dragGroup
        window._dragExclude = exclude
    end

    if isMoving then
        -- Move group members to maintain their offsets from the dragged window
        local myRect = getWindowRect(window.name)
        if myRect and window._dragGroup then
            for _, member in ipairs(window._dragGroup) do
                WindowClearAnchors(member.name)
                WindowAddAnchor(member.name, "topleft", "Root", "topleft",
                    myRect.x + member.offsetX, myRect.y + member.offsetY)
            end
        end

        -- Show snap preview for window-to-window only (skip screen edges)
        local dx, dy = findSnap(window.name, window._dragExclude, true)
        if dx ~= 0 or dy ~= 0 then
            if myRect then
                showSnapPreview(myRect.x + dx, myRect.y + dy, myRect.w, myRect.h)
            end
        else
            hideSnapPreview()
        end
    elseif window._wasMoving then
        -- Just stopped moving: apply snap to dragged window and shift group
        local isGroupDrag = window._dragGroup and #window._dragGroup > 0
        local dx, dy = findSnap(window.name, window._dragExclude, isGroupDrag)
        applySnap(window.name, dx, dy)
        if window._dragGroup then
            for _, member in ipairs(window._dragGroup) do
                applySnap(member.name, dx, dy)
            end
        end
        window._dragGroup = nil
        window._dragExclude = nil
        hideSnapPreview()

        -- Update _isSnapped: true if this window is now adjacent to another
        local postGroup = findJoinedGroup(window.name)
        window._isSnapped = #postGroup > 1
    end

    window._wasMoving = isMoving
end

function Window:onInitialize()
    local isParentRoot = self.parentRoot
    self:toggleBackground(isParentRoot)
    self:toggleFrame(isParentRoot)
    View.onInitialize(self)

    -- Set default OnRButtonUp (close window) if not already bound
    if not self._bindings.OnRButtonUp then
        self.bindings = BindingFactory:new()
            :onRButtonUp(function()
                if self.parentRoot then
                    self:destroy()
                end
            end)
            :build()
    end

    -- Re-check parent after View.onInitialize, which may reparent this window
    isParentRoot = self.parentRoot

    if isParentRoot then
        Api.Window.RestorePosition(self.name)
    end

    if isParentRoot and self._model.Resizable ~= false then
        self._resizeGrip = createResizeGrip(self)
    end

    if isParentRoot and self._model.Snappable ~= false then
        registerWindowSnap(self)
    end

    Utils.Array.ForEach(self._children, function(child, index)
        wrapChildForParent(self, child, index)
        child:create()
        child:onInitialize()
    end)
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

    -- Registering OnLButtonDown as a CoreEvent prevents the engine from
    -- auto-starting movement for movable MaskWindows.  Explicitly start it.
    if self.parentRoot then
        Api.Window.SetMoving(self.name, true)
    end
end

function Window:onLButtonUp(flags, x, y)
    local moved = (self._startDrag.x >= 0 and self._startDrag.x ~= x) or
        (self._startDrag.y >= 0 and self._startDrag.y ~= y)
    local isDraggingItem = Data.Drag().draggingItem
    local shouldFire = (not moved) or isDraggingItem
    if shouldFire then
        View.onLButtonUp(self, flags, x, y)
    end
    self._startDrag = { x = -1, y = -1 }
end

function Window:onUpdate(timePassed)
    if self._wasMoving ~= nil then
        updateWindowSnap(self)
    end

    local fn = self._bindings.OnUpdate
    if fn then
        fn(timePassed)
    end
end

function Window:onShutdown()
    if resizingWindow == self then
        stopResize()
    end

    if self._resizeGrip then
        self._resizeGrip:destroy()
        self._resizeGrip = nil
    end

    unregisterWindowSnap(self)

    if self.parentRoot then
        Api.Window.SavePosition(self.name)
    end

    Utils.Array.ForEach(self._children, function(item)
        item:destroy()
    end)
    View.onShutdown(self)
end

Window._ownProperties = {
    frame = {
        get = function(self)
            if self._frameWindow == nil then
                self._frameWindow = Window:new { Name = self._frame }
            end
            return self._frameWindow
        end,
    },
    background = {
        get = function(self)
            if self._backgroundWindow == nil then
                self._backgroundWindow = Window:new { Name = self._background }
            end
            return self._backgroundWindow
        end,
    },
    children = {
        set = function(self, v) self._children = v end,
    },
}

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
    Api.Window.AttachToWorldObject(self.id, self.name)
    return self
end

---@param model WindowModel?
---@return Window
function Components.Window(model)
    local window = Window:new(model)
    Cache[window.name] = window
    return window
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
    Cache[view.name] = view
    return view
end

setmetatable(View, { __index = Component })
setmetatable(Window, { __index = View })
setmetatable(Button, { __index = View })
setmetatable(EditTextBox, { __index = View })
setmetatable(Label, { __index = View })
setmetatable(LogDisplay, { __index = View })
setmetatable(ScrollWindow, { __index = View })
setmetatable(StatusBar, { __index = View })
setmetatable(Gump, { __index = Window })
setmetatable(CircleImage, { __index = View })
setmetatable(DynamicImage, { __index = View })
setmetatable(DefaultComponent, { __index = Component })
setmetatable(SliderBar, { __index = View })
setmetatable(ComboBox, { __index = View })
setmetatable(CheckBox, { __index = View })
setmetatable(AnimatedImage, { __index = View })
setmetatable(ActionButton, { __index = Button })
setmetatable(ActionButtonGroup, { __index = Window })
setmetatable(CooldownDisplay, { __index = AnimatedImage })
setmetatable(DockableWindow, { __index = Window })
setmetatable(PageWindow, { __index = View })

-- Build merged property tables for all classes with _ownProperties.
-- Parents must be merged before children so inherited properties resolve.
mergeProperties(Component)
mergeProperties(View)
mergeProperties(Window)
mergeProperties(Button)
mergeProperties(EditTextBox)
mergeProperties(FilterInput)
mergeProperties(Label)
mergeProperties(LogDisplay)
mergeProperties(ScrollWindow)
mergeProperties(StatusBar)
mergeProperties(Gump)
mergeProperties(CircleImage)
mergeProperties(DynamicImage)
mergeProperties(SliderBar)
mergeProperties(ComboBox)
mergeProperties(CheckBox)
mergeProperties(AnimatedImage)
mergeProperties(ActionButton)
mergeProperties(ActionButtonGroup)
mergeProperties(CooldownDisplay)
mergeProperties(DockableWindow)
mergeProperties(PageWindow)
mergeProperties(DefaultComponent)

-- Build merged property tables for data wrapper classes.
mergeProperties(ActiveMobile)
mergeProperties(CurrentTarget)
mergeProperties(Cursor)
mergeProperties(Drag)
mergeProperties(HealthBarColor)
mergeProperties(MobileName)
mergeProperties(MobileStatus)
mergeProperties(Object)
mergeProperties(ObjectHandles)
mergeProperties(PlayerLocation)
mergeProperties(PlayerStatus)
mergeProperties(PaperdollData)
mergeProperties(PaperdollTexture)
mergeProperties(ShopData)
mergeProperties(ObjectInfoData)

Components.Defaults.Actions = DefaultComponent.create("Actions", "Actions", Actions)
Components.Defaults.MainMenuWindow = DefaultComponent.create("MainMenuWindow", "MainMenuWindow", MainMenuWindow)
Components.Defaults.StatusWindow = DefaultComponent.create("StatusWindow", "StatusWindow", StatusWindow)
Components.Defaults.WarShield = DefaultComponent.create("WarShield", "WarShield", WarShield)
Components.Defaults.PaperdollWindow = DefaultComponent.create("PaperdollWindow", "PaperdollWindow", PaperdollWindow)
Components.Defaults.Interface = DefaultComponent.create("Interface", "Interface", Interface)
Components.Defaults.ObjectHandle = DefaultComponent.create("ObjectHandle", "ObjectHandleWindow", ObjectHandleWindow)
Components.Defaults.Shopkeeper = DefaultComponent.create("Shopkeeper", "Shopkeeper", Shopkeeper)
Components.Defaults.HealthBarManager = DefaultComponent.create("HealthBarManager", "HealthBarManager", HealthBarManager)
Components.Defaults.GumpsParsing = DefaultComponent.create("GumpsParsing", "GumpsParsing", GumpsParsing, {
    methods = {
        getVendorSearch = function(self)
            return self.default.GumpMaps[Constants.GumpIds.VendorSearch]
        end,
    },
})
Components.Defaults.GenericGump = DefaultComponent.create("GenericGump", "GenericGump", GenericGump, {
    init = function(original)
        original.OnShown = function() end
    end,
})
Components.Defaults.MapWindow = DefaultComponent.create("MapWindow", "MapWindow", MapWindow)
Components.Defaults.MapCommon = DefaultComponent.create("MapCommon", "MapCommon", MapCommon)
Components.Defaults.DebugWindow = DefaultComponent.create("DebugWindow", "DebugWindow", DebugWindow)

-- ========================================================================== --
-- Mod
-- ========================================================================== --

---@class ModInitializer
---@field OnInitialize fun(): Mod Initializes the mod

---@class Mod
---@field Name string Name of the mod
---@field Path string Path to the mod resources
---@field Files string[]? list of files to load
---@field enabled boolean Whether the mod is enabled
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
    local mod = setmetatable({}, getClassMetatable(self))
    rawset(mod, 'Name', model.Name)
    rawset(mod, 'Path', model.Path)
    rawset(mod, 'Files', model.Files or {})
    rawset(mod, '_onInitialize', model.OnInitialize or function() end)
    rawset(mod, '_onShutdown', model.OnShutdown or function() end)
    rawset(mod, '_onUpdate', model.OnUpdate)
    return mod
end

function Mod:initialize()
    Api.Mod.Initialize(self.Name)
end

Mod._ownProperties = {
    enabled = {
        get = function(self) return Api.Interface.LoadBoolean("Mongbat.Mods." .. self.Name .. ".Enabled", true) end,
        set = function(self, v) Api.Interface.SaveBoolean("Mongbat.Mods." .. self.Name .. ".Enabled", v) end,
    },
}

mergeProperties(Mod)

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
    if not self.enabled then
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
    return Components.Window {
        Name = "MongbatModManagerWindow",
        OnInitialize = function(self)
            self.dimensions = { 400, 300 }
            self.children =
                Utils.Table.MapToArray(
                    Mods,
                    function(name, mod)
                        return Components.Button {
                            OnInitialize = function(button)
                                local status = mod.enabled
                                local statusText = "Disabled"
                                if status then
                                    statusText = "Enabled"
                                end
                                button.text = "Enable " .. name .. " (" .. statusText .. ")"
                                button.bindings = button:bindingsBuilder(function(bind)
                                    bind:onLButtonUp(function()
                                        local s = mod.enabled
                                        mod.enabled = not s
                                        Api.InterfaceCore.ReloadUI()
                                    end)
                                end)
                            end,
                        }
                    end
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
            Constants.DataEvents.OnUpdatePlayerLocation,
            Constants.DataEvents.OnUpdateShopData
        }

        Utils.Array.ForEach(
            register,
            function(dataEvent)
                Api.Window.RegisterData(dataEvent.getType(), 0)
            end
        )

        --- SystemEvent fallbacks for cross-window drag-and-drop.  CoreEvents
        --- fire on the window that originated the click; the drop *target*
        --- (a different Mongbat window) only receives L_BUTTON_UP_PROCESSED.
        Api.Event.RegisterEventHandler(Constants.SystemEvents.OnLButtonUpProcessed.getEvent(),
            "Mongbat.EventHandler.OnLButtonUpProcessed")
    end,
    OnShutdown = function()
        Api.Window.UnregisterData(Constants.DataEvents.OnUpdatePlayerStatus.getType(), 0)
        Api.Event.UnregisterEventHandler(Constants.SystemEvents.OnLButtonUpProcessed.getEvent(),
            "Mongbat.EventHandler.OnLButtonUpProcessed")
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
end

