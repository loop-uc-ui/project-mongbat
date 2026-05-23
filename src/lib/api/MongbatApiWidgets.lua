---@diagnostic disable: undefined-global
---@class Api
local Api = Mongbat.Api

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
---@param text string|number|wstring The text to set.
function Api.Button.SetText(id, text)
    ButtonSetText(id, Mongbat.Utils.String.ToWString(text))
end

---
--- Gets the text of a button.
---@param id string The ID of the button.
---@return wstring The text of the button.
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

---
--- Sets the fill parameters for a circle image.
---@param name string The name of the circle image.
---@param startAngle number The start angle in degrees.
---@param fillAngle number The fill angle in degrees.
function Api.CircleImage.SetFillParams(name, startAngle, fillAngle)
    CircleImageSetFillParams(name, startAngle, fillAngle)
end

---
--- Sets the texture slice for a circle image.
---@param name string The name of the circle image.
---@param sliceName string The name of the texture slice.
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
--- Clears the text of an edit box.
---@param editBoxName string The name of the edit box.
function Api.EditTextBox.Clear(editBoxName)
    TextEditBoxSetText(editBoxName, L "")
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
---@param text string|wstring|number The text to set.
function Api.Label.SetText(name, text)
    if text == nil then
        return
    end
    LabelSetText(name, Mongbat.Utils.String.ToWString(text))
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
---@param color Color The color to set.
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
---@param color Color The color to set.
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
---@param color Color The color to set.
function Api.StatusBar.SetForegroundTint(id, color)
    StatusBarSetForegroundTint(id, color.r, color.g, color.b)
end

---
--- Sets the background tint of a status bar.
---@param id string The ID of the status bar.
---@param color Color The color to set.
function Api.StatusBar.SetBackgroundTint(id, color)
    StatusBarSetBackgroundTint(id, color.r, color.g, color.b)
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
    TextLogAddFilterType(name, filterId, prefix or L "")
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
-- Api - Window
-- ========================================================================== --

Api.Window = {}


---
--- Gets the current state of a window.
---@param windowName string The name of the window.
---@return any The window state.
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
---@return Dimensions The dimensions of the window.
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
--- Sets the resizing state of a window. When `isResizing` is true the
--- engine grows the window each frame from the cursor's distance to
--- `anchorCorner`, properly reflowing FullResizeImage children. Pair with
--- a clear-anchors + add-anchor at `anchorCorner` so the opposite corner
--- stays pinned.
---@param windowName string The name of the window.
---@param isResizing boolean Whether the window is resizing.
---@param anchorCorner string? The fixed corner (e.g. "topleft"). Required when starting a resize.
---@param lockRatio boolean? Lock aspect ratio.
function Api.Window.SetResizing(windowName, isResizing, anchorCorner, lockRatio)
    WindowSetResizing(windowName, isResizing, anchorCorner or "", lockRatio == true)
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
---@param color Color The color to set.
function Api.Window.SetColor(windowName, color)
    WindowSetTintColor(windowName, color.r, color.g, color.b)
end

---
--- Gets the color of a window.
---@param windowName string The name of the window.
---@return Color The color of the window.
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
--- Gets the name of the currently-active window (the window receiving the
--- in-flight engine event).
---@return string
function Api.Window.GetActiveName()
    return SystemData.ActiveWindow.name
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
---@param event number The event to register.
---@param callback string The callback function.
function Api.Window.RegisterEventHandler(windowName, event, callback)
    WindowRegisterEventHandler(windowName, event, callback)
end

---
--- Unregisters an event handler for a window.
---@param windowName string The name of the window.
---@param event number The event to unregister.
function Api.Window.UnregisterEventHandler(windowName, event)
    WindowUnregisterEventHandler(windowName, event)
end

---
--- Registers a core event handler for a window.
---@param windowName string The name of the window.
---@param event string The event to register.
---@param callback string The callback function.
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
---@param closing boolean? Whether the window is closing (default true).
---@param alias string? An alias for the window.
function Api.Window.SavePosition(window, closing, alias)
    WindowUtils.SaveWindowPosition(window, closing, alias)
end

---
--- Restores the position of a window.
---@param window string The name of the window.
---@param trackSize boolean? Whether to track the size of the window.
---@param alias string? An alias for the window.
---@param ignoreBounds boolean? Whether to ignore the bounds of the window.
function Api.Window.RestorePosition(window, trackSize, alias, ignoreBounds)
    WindowUtils.RestoreWindowPosition(window, trackSize, alias, ignoreBounds)
end

---
--- Begins a resize operation on a window using the engine's ResizingWindowFrame.
--- The anchorCorner is the corner that stays fixed during the resize (typically
--- "topleft"). The resize ends on the next L_BUTTON_UP_PROCESSED event, at which
--- point endCallback is called with the window name.
---@param windowName string The name of the window to resize.
---@param anchorCorner string The fixed corner during resize (e.g. "topleft").
---@param minWidth number Minimum allowed width.
---@param minHeight number Minimum allowed height.
---@param lockRatio boolean Whether to lock the aspect ratio.
---@param endCallback fun(windowName: string)? Called when the resize ends.
function Api.Window.BeginResize(windowName, anchorCorner, minWidth, minHeight, lockRatio, endCallback)
    WindowUtils.BeginResize(windowName, anchorCorner, minWidth, minHeight, lockRatio, endCallback)
end

