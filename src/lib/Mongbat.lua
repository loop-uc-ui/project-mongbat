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

local State = {}
State.ClickTargets = {}
State.TopLevelWindows = {}
State.Updatables = {}
State.LayoutPending = {}
State.CreateQueue = {}

---@type table<number, string[]>
State.Entities = {}
State.Systems = {}
State.DragOrigin = nil

---@param window Window
---@return table
local function createStateProxy(window)
    local values = {}
    local order = {}
    local queued = {}
    local head = 1

    window._stateValues = values
    window._stateOrder = order
    window._stateQueued = queued
    window._stateHead = head

    return setmetatable({}, {
        __index = values,
        __newindex = function(_, key, value)
            values[key] = value

            if window._isInitialized then
                value[1](window._name, unpack(value, 2))
                values[key] = nil
                queued[key] = nil
                return
            end

            if not queued[key] then
                queued[key] = true
                order[#order + 1] = key
            end
        end,
    })
end

---@param window Window
local function registerPendingHandlers(window)
    local registered = window._registered
    for key, entry in pairs(window._registrations) do
        if not registered[key] then
            entry[1](window._name, unpack(entry, 2))
            registered[key] = true
        end
    end
end

---@param window Window
---@param key string
---@param entry table
local function queueRegistration(window, key, entry)
    window._registrations[key] = entry
    if window._isInitialized and not window._registered[key] then
        entry[1](window._name, unpack(entry, 2))
        window._registered[key] = true
    end
end

---@param window Window
local function trackClickTarget(window)
    State.ClickTargets[window:name()] = window
end

---@param window Window
---@return boolean
local function processWindowLayout(window)
    if not window._layout then
        return true
    end

    local layout = window._layout
    for _, child in ipairs(layout.children) do
        if not child._isInitialized then
            return false
        end
    end

    local y = layout.offsetY
    for _, child in ipairs(layout.children) do
        child._state.setOffsetFromParent = { Api.Window.SetOffsetFromParent, layout.offsetX, y }
        local dims = Api.Window.GetDimensions(child._name)
        y = y + dims.y + layout.spacing
    end

    window._layout = nil
    State.LayoutPending[window._name] = nil
    return true
end

---@param window Window
function State.Systems.TrackWindow(window)
    if window._onUpdate then
        State.Updatables[window:name()] = window
    end
end

---@param window Window
local function dispatchWindowMessages(window)
    local order = window._stateOrder
    local values = window._stateValues
    local queued = window._stateQueued
    local head = window._stateHead

    while head <= #order do
        local key = order[head]
        order[head] = nil
        queued[key] = nil

        local entry = values[key]
        values[key] = nil
        if entry then
            entry[1](window._name, unpack(entry, 2))
        end

        head = head + 1
    end

    window._stateHead = 1
    window._stateOrder = {}
end

---@param window Window
local function initializeWindow(window)
    local parent = window._parent or "Root"
    if parent ~= "Root" and not Api.Window.DoesExist(parent) then return false end
    if not Api.Window.CreateFromTemplate(window:name(), window:template(), parent, window._initialShowing) then return false end

    window._isInitialized = true
    window._createQueued = false

    if window._isTopLevel then
        State.TopLevelWindows[window._name] = true
        queueRegistration(window, "OnShown", { Api.Window.RegisterCoreEventHandler, "OnShown", "_Mongbat.OnShown" })
        queueRegistration(window, "OnHidden", { Api.Window.RegisterCoreEventHandler, "OnHidden", "_Mongbat.OnHidden" })
    end

    window:onInitialize()
    registerPendingHandlers(window)
    dispatchWindowMessages(window)
    processWindowLayout(window)

    local id = window:getId()
    if not State.Entities[id] then
        State.Entities[id] = {}
    end
    table.insert(State.Entities[id], window:name())

    for _, dataEvent in pairs(Constants.DataEvents) do
        Api.Window.RegisterData(dataEvent.getType(), id)
    end

    return true
end

---@param window Window
function State.Systems.EnqueueCreate(window)
    if window._createQueued or window._isInitialized then return end
    window._createQueued = true
    State.CreateQueue[#State.CreateQueue + 1] = window
end

function State.Systems.ProcessCreateQueue()
    if #State.CreateQueue == 0 then return end

    local pending = State.CreateQueue
    State.CreateQueue = {}

    for _, window in ipairs(pending) do
        -- This item is now being processed; allow retry enqueue if creation fails.
        window._createQueued = false
        if not window._isInitialized and not initializeWindow(window) then
            State.Systems.EnqueueCreate(window)
        end
    end
end

---@param window Window
function State.Systems.DestroyWindow(window)
    if not window:exists() then return false end
    local name = window:name()
    Debug.Print("Attempting to destroy window: " .. name)
    for i = #window._children, 1, -1 do
        State.Systems.DestroyWindow(window._children[i])
    end
    window._children = {}
    local id = window:getId()
    window:onShutdown()
    window._isInitialized = false
    window._createQueued = false
    window._state = createStateProxy(window)
    window._registrations = {}
    window._registered = {}
    window._handlers = {}
    State.ClickTargets[name] = nil
    State.TopLevelWindows[name] = nil
    State.Updatables[name] = nil
    State.LayoutPending[name] = nil
    if State.Entities[id] then
        local entity = State.Entities[id]
        for i = #entity, 1, -1 do
            if entity[i] == name then
                table.remove(entity, i)
            end
        end
        if #entity == 0 then
            for _, dataEvent in pairs(Constants.DataEvents) do
                Api.Window.UnregisterData(dataEvent.getType(), id)
            end
            State.Entities[id] = nil
        end
    end
    return Api.Window.Destroy(name)
end

function State.Systems.OnUpdate(timePassed)
    State.Systems.ProcessCreateQueue()

    local windowData = Data.WindowData()
    local keys = {}
    for k in pairs(State.Updatables) do
        keys[#keys + 1] = k
    end
    for _, name in ipairs(keys) do
        local component = State.Updatables[name]
        if component and component._isInitialized then
            component._onUpdate(component, timePassed, windowData)
        elseif component then
            State.Systems.EnqueueCreate(component)
        end
    end

    local layoutKeys = {}
    for k in pairs(State.LayoutPending) do
        layoutKeys[#layoutKeys + 1] = k
    end
    for _, name in ipairs(layoutKeys) do
        local component = State.LayoutPending[name]
        if component and component._isInitialized then
            processWindowLayout(component)
        end
    end

    State.Systems.ProcessCreateQueue()
end

function State.Systems.OnClick(handlerKey, flags, x, y)
    local windowName = Data.MouseOverWindow()
    while windowName and windowName ~= "" and windowName ~= "Root" do
        local component = State.ClickTargets[windowName]
        if component and component._handlers[handlerKey] then
            component._handlers[handlerKey](component, flags, x, y)
            return
        end
        windowName = Api.Window.GetParent(windowName)
    end
end

local function findTopLevelWindow(windowName)
    local current = windowName
    while current and current ~= "" and current ~= "Root" do
        if State.TopLevelWindows[current] then
            return current
        end
        current = Api.Window.GetParent(current)
    end
    return nil
end

function State.Systems.OnLButtonDown(flags, x, y)
    local windowName = Data.MouseOverWindow()
    if not windowName or windowName == "" then return end
    local topLevel = findTopLevelWindow(windowName)
    if topLevel then
        local sx, sy = Api.Window.GetPosition(topLevel)
        State.DragOrigin = { window = topLevel, x = sx, y = sy }
        Api.Window.SetMoving(topLevel, true)
    end
    State.Systems.OnClick("onLButtonDown", flags, x, y)
end

function State.Systems.OnLButtonUp(flags, x, y)
    if State.DragOrigin then
        local topLevel = State.DragOrigin.window
        Api.Window.SetMoving(topLevel, false)
        local sx, sy = Api.Window.GetPosition(topLevel)
        local dragged = sx ~= State.DragOrigin.x or sy ~= State.DragOrigin.y
        State.DragOrigin = nil
        if dragged then return end
    end
    State.Systems.OnClick("onLButtonUp", flags, x, y)
end

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
    WindowSetGameActionData(windowName, actionType, actionId, L "")
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
    end
    LabelSetText(name, Utils.String.ToWString(text))
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
    if text == nil then return L "" end
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

Constants.SystemEvents.OnRButtonUpProcessed = {
    getEvent = function()
        return SystemData.Events["R_BUTTON_UP_PROCESSED"]
    end,
    name = "OnRButtonUpProcessed"
}

Constants.SystemEvents.OnRButtonDownProcessed = {
    getEvent = function()
        return SystemData.Events["R_BUTTON_DOWN_PROCESSED"]
    end,
    name = "OnRButtonDownProcessed"
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
-- Data - WindowData (composite)
-- ========================================================================== --

---@class WindowDataWrapper
local WindowDataWrapper = {}
WindowDataWrapper.__index = WindowDataWrapper

function WindowDataWrapper:new() return setmetatable({}, self) end

function WindowDataWrapper:activeMobile() return Data.ActiveMobile() end
function WindowDataWrapper:currentTarget() return Data.CurrentTarget() end
function WindowDataWrapper:cursor() return Data.Cursor() end
function WindowDataWrapper:drag() return Data.Drag() end
function WindowDataWrapper:playerStatus() return Data.PlayerStatus() end
function WindowDataWrapper:playerLocation() return Data.PlayerLocation() end
function WindowDataWrapper:objectHandles() return Data.ObjectHandles() end
---@param id integer
function WindowDataWrapper:healthBarColor(id) return Data.HealthBarColor(id) end
---@param id integer
function WindowDataWrapper:mobileName(id) return Data.MobileName(id) end
---@param id integer
function WindowDataWrapper:mobileStatus(id) return Data.MobileStatus(id) end
---@param id integer
function WindowDataWrapper:paperdoll(id) return Data.Paperdoll(id) end
---@param id integer
function WindowDataWrapper:paperdollTexture(id) return Data.PaperdollTexture(id) end
---@param id integer
function WindowDataWrapper:object(id) return Data.Object(id) end

---@return WindowDataWrapper
function Data.WindowData() return WindowDataWrapper:new() end


-- ========================================================================== --
-- Components
-- ========================================================================== --

-- Window (base class) --------------------------------------------------------

---@class WindowModel
---@field Name string?
---@field Template string?
---@field Parent string?
---@field OnInitialize fun(self: Window)?
---@field OnUpdate fun(self: Window, timePassed: number, windowData: WindowDataWrapper)?
---@field OnShutdown fun(self: Window)?

---@class Window
---@field _name string
---@field _template string
---@field _parent string?
---@field _children Window[]
---@field _layout table?
---@field _isInitialized boolean
---@field _isTopLevel boolean
---@field _topLevel Window
---@field _initialShowing boolean
---@field _createQueued boolean
---@field _state table<string, table>
---@field _stateValues table<string, table>
---@field _stateOrder string[]
---@field _stateQueued table<string, boolean>
---@field _stateHead integer
---@field _registrations table<string, table>
---@field _registered table<string, boolean>
---@field _handlers table<string, fun(self: Window, flags: number, x: number, y: number)>
---@field _onInitialize fun(self: Window)?
---@field _onUpdate fun(self: Window, timePassed: number, windowData: WindowDataWrapper)?
---@field _onShutdown fun(self: Window)?
local Window = {}
Window.__index = Window
Window._defaultTemplate = "MongbatWindow"


---@param model WindowModel?
function Window:new(model)
    local window = setmetatable({ _name = model and model.Name or Utils.String.Random() }, self)
    window._template = model and model.Template or self._defaultTemplate
    window._parent = model and model.Parent or "Root"
    window._isInitialized = window:exists()
    window._isTopLevel = true
    window._initialShowing = false
    window._createQueued = false
    window._children = {}
    window._state = createStateProxy(window)
    window._registrations = {}
    window._registered = {}
    window._handlers = {}
    window._onInitialize = model and model.OnInitialize or nil
    window._onUpdate = model and model.OnUpdate or nil
    window._onShutdown = model and model.OnShutdown or nil
    window._topLevel = window
    return window
end

function Window:template() return self._template end

function Window:name() return self._name end

function Window:exists() return Api.Window.DoesExist(self._name) end

function Window:getState() return Api.Window.GetState(self._name) end

function Window:destroy() State.Systems.DestroyWindow(self) end

function Window:create(doShow, parent)
    if parent then self._parent = parent end
    local show = doShow ~= false
    self._initialShowing = show
    self._state.setShowing = { Api.Window.SetShowing, show }
    State.Systems.EnqueueCreate(self)
end

function Window:onInitialize() if self._onInitialize then self._onInitialize(self) end end

function Window:onShutdown() if self._onShutdown then self._onShutdown(self) end end

function Window:addChild(child)
    State.TopLevelWindows[child._name] = nil
    child._parent = self._name
    child._isTopLevel = false
    child._topLevel = self._topLevel
    child._initialShowing = true
    child._state.setShowing = { Api.Window.SetShowing, true }
    State.Systems.EnqueueCreate(child)
    table.insert(self._children, child)
end

function Window:addChildren(children, layout)
    for _, child in ipairs(children) do
        self:addChild(child)
    end
    if layout then
        self._layout = {
            children = children,
            offsetX = layout.offsetX or 0,
            offsetY = layout.offsetY or 0,
            spacing = layout.spacing or 0,
        }
        State.LayoutPending[self._name] = self
    end
end

function Window:toggle() return Api.Window.ToggleWindow(self._name) end

function Window:setShowing(show)
    self._state.setShowing = { Api.Window.SetShowing, show }
end

function Window:isShowing() return Api.Window.IsShowing(self._name) end

function Window:setLayer(layer) self._state.setLayer = { Api.Window.SetLayer, layer } end

function Window:getLayer() return Api.Window.GetLayer(self._name) end

function Window:setHandleInput(handleInput) self._state.setHandleInput = { Api.Window.SetHandleInput, handleInput } end

function Window:getHandleInput() return Api.Window.GetHandleInput(self._name) end

function Window:setPopable(popable) self._state.setPopable = { Api.Window.SetPopable, popable } end

function Window:isPopable() return Api.Window.IsPopable(self._name) end

function Window:setMovable(movable) self._state.setMovable = { Api.Window.SetMovable, movable } end

function Window:isMovable() return Api.Window.IsMovable(self._name) end

function Window:setOffsetFromParent(x, y) self._state.setOffsetFromParent = { Api.Window.SetOffsetFromParent, x, y } end

function Window:getOffsetFromParent() return Api.Window.GetOffsetFromParent(self._name) end

function Window:setDimensions(w, h) self._state.setDimensions = { Api.Window.SetDimensions, w, h } end

function Window:getDimensions() return Api.Window.GetDimensions(self._name) end

function Window:isSticky() return Api.Window.IsSticky(self._name) end

function Window:clearAnchors()
    if self._isInitialized then Api.Window.ClearAnchors(self._name) end
end

function Window:addAnchor(anchorPoint, relativeTo, relativePoint, x, y)
    if self._isInitialized then Api.Window.AddAnchor(self._name, anchorPoint, relativeTo, relativePoint, x, y) end
end

function Window:getAnchor(anchorId) return Api.Window.GetAnchor(self._name, anchorId) end

function Window:getAnchorCount() return Api.Window.GetAnchorCount(self._name) end

function Window:forceProcessAnchors()
    if self._isInitialized then Api.Window.ForceProcessAnchors(self._name) end
end

function Window:assignFocus(doFocus) return Api.Window.AssignFocus(self._name, doFocus) end

function Window:hasFocus() return Api.Window.HasFocus(self._name) end

function Window:setResizing(isResizing) self._state.setResizing = { Api.Window.SetResizing, isResizing } end

function Window:isResizing() return Api.Window.IsResizing(self._name) end

function Window:startAlphaAnimation(animType, startAlpha, endAlpha, duration, setStartBeforeDelay, delay, numLoop)
    if self._isInitialized then Api.Window.StartAlphaAnimation(self._name, animType, startAlpha, endAlpha, duration,
            setStartBeforeDelay, delay, numLoop) end
end

function Window:stopAlphaAnimation()
    if self._isInitialized then Api.Window.StopAlphaAnimation(self._name) end
end

function Window:startScaleAnimation(animType, startX, startY, endX, endY, duration, setStartBeforeDelay, delay, numLoop)
    if self._isInitialized then Api.Window.StartScaleAnimation(self._name, animType, startX, startY, endX, endY, duration,
            setStartBeforeDelay, delay, numLoop) end
end

function Window:stopScaleAnimation()
    if self._isInitialized then Api.Window.StopScaleAnimation(self._name) end
end

function Window:stopPositionAnimation()
    if self._isInitialized then Api.Window.StopPositionAnimation(self._name) end
end

function Window:setAlpha(alpha) self._state.setAlpha = { Api.Window.SetAlpha, alpha } end

function Window:getAlpha() return Api.Window.GetAlpha(self._name) end

function Window:setColor(color) self._state.setColor = { Api.Window.SetColor, color } end

function Window:getColor() return Api.Window.GetColor(self._name) end

function Window:setId(id) self._state.setId = { Api.Window.SetId, id } end

function Window:getId() return Api.Window.GetId(self._name) end

function Window:setTabOrder(tabOrder) self._state.setTabOrder = { Api.Window.SetTabOrder, tabOrder } end

function Window:getTabOrder() return Api.Window.GetTabOrder(self._name) end

function Window:setMoving(isMoving) self._state.setMoving = { Api.Window.SetMoving, isMoving } end

function Window:isMoving() return Api.Window.IsMoving(self._name) end

function Window:registerEventHandler(event, callback)
    if self._isInitialized then Api.Window.RegisterEventHandler(self._name, event, callback) end
end

function Window:unregisterEventHandler(event)
    if self._isInitialized then Api.Window.UnregisterEventHandler(self._name, event) end
end

function Window:registerCoreEventHandler(event, callback)
    if self._isInitialized then Api.Window.RegisterCoreEventHandler(self._name, event, callback) end
end

function Window:unregisterCoreEventHandler(event)
    if self._isInitialized then Api.Window.UnregisterCoreEventHandler(self._name, event) end
end

function Window:onLButtonUp(fn)
    self._handlers.onLButtonUp = fn
    trackClickTarget(self)
end

function Window:onLButtonDown(fn)
    self._handlers.onLButtonDown = fn
    trackClickTarget(self)
end

function Window:onRButtonUp(fn)
    self._handlers.onRButtonUp = fn
    trackClickTarget(self)
end

function Window:onRButtonDown(fn)
    self._handlers.onRButtonDown = fn
    trackClickTarget(self)
end

function Window:onLButtonDblClk(fn)
    self._handlers.onLButtonDblClk = fn
    trackClickTarget(self)
    queueRegistration(self, "OnLButtonDblClk", { Api.Window.RegisterCoreEventHandler, "OnLButtonDblClk", "_Mongbat.OnLButtonDblClk" })
end

function Window:onMouseOver(fn) queueRegistration(self, "OnMouseOver", { Api.Window.RegisterCoreEventHandler, "OnMouseOver", fn }) end

function Window:onMouseOverEnd(fn) queueRegistration(self, "OnMouseOverEnd", { Api.Window.RegisterCoreEventHandler, "OnMouseOverEnd", fn }) end

function Window:onMouseWheel(fn) queueRegistration(self, "OnMouseWheel", { Api.Window.RegisterCoreEventHandler, "OnMouseWheel", fn }) end

function Window:setParent(parentId) self._state.setParent = { Api.Window.SetParent, parentId } end

function Window:getParent() return Api.Window.GetParent(self._name) end

function Window:setScale(scale) self._state.setScale = { Api.Window.SetScale, scale } end

function Window:getScale() return Api.Window.GetScale(self._name) end

function Window:setRelativeScale(scale) self._state.setRelativeScale = { Api.Window.SetRelativeScale, scale } end

function Window:setResizeOnChildren(isRecursive, borderSpacing) self._state.setResizeOnChildren = { Api.Window.SetResizeOnChildren, isRecursive, borderSpacing } end

function Window:setGameActionTrigger(action) self._state.setGameActionTrigger = { Api.Window.SetGameActionTrigger, action } end

function Window:setGameActionData(actionType, actionId, actionText) self._state.setGameActionData = { Api.Window.SetGameActionData, actionType, actionId, actionText } end

function Window:setGameActionButton(button) self._state.setGameActionButton = { Api.Window.SetGameActionButton, button } end

function Window:getGameActionButton() return Api.Window.GetGameActionButton(self._name) end

function Window:isGameActionLocked() return Api.Window.IsGameActionLocked(self._name) end

function Window:setDrawWhenInterfaceHidden(doDraw) self._state.setDrawWhenInterfaceHidden = { Api.Window.SetDrawWhenInterfaceHidden, doDraw } end

function Window:restoreDefaults()
    if self._isInitialized then Api.Window.RestoreDefaults(self._name) end
end

function Window:setUpdateFrequency(frequency) self._state.setUpdateFrequency = { Api.Window.SetUpdateFrequency, frequency } end

function Window:getPosition() return Api.Window.GetPosition(self._name) end

function Window:attachToWorldObject(objectId)
    if self._isInitialized then Api.Window.AttachToWorldObject(self._name, objectId) end
end

function Window:detachFromWorldObject(objectId)
    if self._isInitialized then Api.Window.DetachFromWorldObject(self._name, objectId) end
end

function Window:savePosition(closing, alias)
    if self._isInitialized then Api.Window.SavePosition(self._name, closing, alias) end
end

function Window:restorePosition(trackSize, alias, ignoreBounds)
    if self._isInitialized then Api.Window.RestorePosition(self._name, trackSize, alias, ignoreBounds) end
end

---@param model WindowModel?
Components.Window = function(model)
    local window = Window:new(model)
    State.Systems.TrackWindow(window)
    return window
end

-- Label ----------------------------------------------------------------------

---@class LabelModel : WindowModel
---@field Name string?
---@field Template string?
---@field OnInitialize fun(label: Label)?
---@field OnUpdate fun(label: Label, timePassed: number)?
---@field OnShutdown fun(label: Label)?

---@class Label : Window
local Label = {}
Label.__index = Label
Label._defaultTemplate = "MongbatLabel"
setmetatable(Label, { __index = Window })

---@param model LabelModel?
function Label:new(model) return Window.new(self, model) end

function Label:setText(text) self._state.setText = { Api.Label.SetText, text } end

function Label:getText() return Api.Label.GetText(self._name) end

function Label:setTextColor(color) self._state.setTextColor = { Api.Label.SetTextColor, color } end

function Label:setTextAlignment(alignment) self._state.setTextAlignment = { Api.Label.SetTextAlignment, alignment } end

function Label:setWordWrap(wordWrap) self._state.setWordWrap = { Api.Label.SetWordWrap, wordWrap } end

---@param model LabelModel?
Components.Label = function(model)
    local label = Label:new(model)
    State.Systems.TrackWindow(label)
    return label
end

-- DynamicImage ---------------------------------------------------------------

---@class DynamicImageModel : WindowModel
---@field Name string?
---@field Template string?
---@field OnInitialize fun(self: DynamicImage)?
---@field OnUpdate fun(self: DynamicImage, timePassed: number, windowData: WindowDataWrapper)?
---@field OnShutdown fun(self: DynamicImage)?

---@class DynamicImage : Window
local DynamicImage = {}
DynamicImage.__index = DynamicImage
DynamicImage._defaultTemplate = "MongbatDynamicImage"
setmetatable(DynamicImage, { __index = Window })

---@param model DynamicImageModel?
---@return DynamicImage
function DynamicImage:new(model) return Window.new(self, model) --[[@as DynamicImage]] end

function DynamicImage:setTexture(texture, x, y) self._state.setTexture = { Api.DynamicImage.SetTexture, texture, x, y } end

function DynamicImage:setTextureScale(scale) self._state.setTextureScale = { Api.DynamicImage.SetTextureScale, scale } end

function DynamicImage:setTextureDimensions(x, y) self._state.setTextureDimensions = { Api.DynamicImage.SetTextureDimensions, x, y } end

function DynamicImage:setTextureOrientation(mirrored) self._state.setTextureOrientation = { Api.DynamicImage.SetTextureOrientation, mirrored } end

function DynamicImage:setTextureSlice(sliceName) self._state.setTextureSlice = { Api.DynamicImage.SetTextureSlice, sliceName } end

function DynamicImage:setRotation(rotation) self._state.setRotation = { Api.DynamicImage.SetRotation, rotation } end

function DynamicImage:hasTexture() return Api.DynamicImage.HasTexture(self._name) end

function DynamicImage:setCustomShader(shader, hue) self._state.setCustomShader = { Api.DynamicImage.SetCustomShader, shader, hue } end

---@param model DynamicImageModel?
Components.DynamicImage = function(model)
    local image = DynamicImage:new(model)
    State.Systems.TrackWindow(image)
    return image
end

-- StatusBar ------------------------------------------------------------------

---@class StatusBarModel : WindowModel
---@field Name string?
---@field Template string?
---@field OnInitialize fun(self: StatusBar)?
---@field OnUpdate fun(self: StatusBar, timePassed: number, windowData: WindowDataWrapper)?
---@field OnShutdown fun(self: StatusBar)?

---@class StatusBar : Window
---@field _maxValue number
---@field _currentValue number
---@field _foregroundColor Color
---@field _background DynamicImage
---@field _fill DynamicImage
local StatusBar = {}
StatusBar.__index = StatusBar
StatusBar._defaultTemplate = "MongbatStatusBar"
setmetatable(StatusBar, { __index = Window })

---@param bar StatusBar
local function updateFill(bar)
    if not bar:exists() or not bar._fill:exists() then return end
    local dims = bar:getDimensions()
    local barWidth = dims.x
    local barHeight = dims.y
    if bar._maxValue > 0 and bar._currentValue > 0 and barWidth > 0 then
        local ratio = math.min(bar._currentValue, bar._maxValue) / bar._maxValue
        local fillWidth = math.max(math.floor(barWidth * ratio), 1)
        bar._fill:setDimensions(fillWidth, barHeight)
        bar._fill:setColor(bar._foregroundColor)
        bar._fill:setShowing(true)
    else
        bar._fill:setShowing(false)
    end
end

---@param model StatusBarModel?
function StatusBar:new(model)
    local instance = Window.new(self, model) --[[@as StatusBar]]
    instance._maxValue = 0
    instance._currentValue = 0
    instance._foregroundColor = Constants.Colors.White

    local background = DynamicImage:new { Name = instance._name .. "Bg", Template = "MongbatStatusBarFill" }
    instance:addChild(background)
    instance._background = background

    local fill = DynamicImage:new { Name = instance._name .. "Fill", Template = "MongbatStatusBarFill" }
    instance:addChild(fill)
    instance._fill = fill

    -- Point both DynamicImages at a 1x1 region of the StatusBar texture so
    -- SetColor tinting produces a flat colored fill.
    background:setTexture("StatusBar", 1, 25)
    background:setTextureDimensions(1, 1)
    background:setColor(Constants.Colors.OffBlack)
    background:setLayer(Constants.WindowLayers.Background)
    fill:setTexture("StatusBar", 1, 25)
    fill:setTextureDimensions(1, 1)
    fill:setLayer(Constants.WindowLayers.Default)

    -- Wrap the user's OnUpdate so the fill is recomputed every frame after
    -- their setMaxValue/setCurrentValue calls.
    local userOnUpdate = instance._onUpdate
    instance._onUpdate = function(self, timePassed, windowData)
        if userOnUpdate then userOnUpdate(self, timePassed, windowData) end
        updateFill(self)
    end

    return instance
end

function StatusBar:setMaxValue(value) self._maxValue = value or 0 end

function StatusBar:setCurrentValue(value) self._currentValue = value or 0 end

function StatusBar:setForegroundTint(color)
    self._foregroundColor = color
end

function StatusBar:setBackgroundTint(color)
    self._background:setColor(color)
end

---@param model StatusBarModel?
Components.StatusBar = function(model)
    local statusBar = StatusBar:new(model)
    State.Systems.TrackWindow(statusBar)
    State.Systems.TrackWindow(statusBar._background)
    State.Systems.TrackWindow(statusBar._fill)
    return statusBar
end

-- Button ---------------------------------------------------------------------

---@class ButtonModel : WindowModel
---@field Name string?
---@field Template string?
---@field OnInitialize fun(self: Button)?
---@field OnUpdate fun(self: Button, timePassed: number)?
---@field OnShutdown fun(self: Button)?

---@class Button : Window
local Button = {}
Button.__index = Button
Button._defaultTemplate = "MongbatButton"
setmetatable(Button, { __index = Window })

---@param model ButtonModel?
function Button:new(model) return Window.new(self, model) end

function Button:getTextDimensions() return Api.Button.GetTextDimensions(self._name) end

function Button:setText(text) self._state.setText = { Api.Button.SetText, Utils.String.ToWString(text) } end

function Button:getText() return Api.Button.GetText(self._name) end

function Button:setDisabled(isDisabled) self._state.setDisabled = { Api.Button.SetDisabled, isDisabled } end

function Button:isDisabled() return Api.Button.IsDisabled(self._name) end

function Button:setEnabled(isEnabled) self._state.setEnabled = { Api.Button.SetEnabled, isEnabled } end

function Button:setChecked(isChecked) self._state.setChecked = { Api.Button.SetChecked, isChecked } end

function Button:isChecked() return Api.Button.IsChecked(self._name) end

function Button:setTexture(state, texture, x, y) self._state["setTexture:" .. tostring(state)] = { Api.Button.SetTexture, state, texture, x, y } end

function Button:setHighlight(doHighlight) self._state.setHighlight = { Api.Button.SetHighlight, doHighlight } end

function Button:setStayDown(stayDown) self._state.setStayDown = { Api.Button.SetStayDown, stayDown } end

function Button:isStayDown() return Api.Button.IsStayDown(self._name) end

function Button:setTextColor(r, g, b, a) self._state.setTextColor = { Api.Button.SetTextColor, r, g, b, a } end

---@param model ButtonModel?
---@return Button
Components.Button = function(model)
    local button = Button:new(model)
    State.Systems.TrackWindow(button)
    return button --[[@as Button]]
end

-- Defaults -------------------------------------------------------------------

---@param name string
---@return Window
local function DefaultWindow(name)
    local window = Window:new({ Name = name })
    window.destroy = function(self)
        Api.Window.Destroy(self._name)
    end
    window.setShowing = function(self, show)
        Api.Window.SetShowing(self._name, show)
    end
    return window
end

Components.Defaults = {
    MainMenuWindow = DefaultWindow("MainMenuWindow"),
    StatusWindow = DefaultWindow("StatusWindow"),
    WarShield = DefaultWindow("WarShield"),
    DebugWindow = DefaultWindow("DebugWindow")
}

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
    return Components.Window {
        Name = "MongbatModManagerWindow",
        OnInitialize = function(self)
            self:setDimensions(400, 300)
            self:addChildren(
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
        -- local register = {
        --     Constants.DataEvents.OnUpdatePlayerStatus,
        --     Constants.DataEvents.OnUpdateRadar,
        --     Constants.DataEvents.OnUpdatePlayerLocation
        -- }

        -- Utils.Array.ForEach(
        --     register,
        --     function(dataEvent)
        --         Api.Window.RegisterData(dataEvent.getType(), 0)
        --     end
        -- )

        -- --- We are using SystemEvents for onLButtonUp and onLButtonDown to facilitate the
        -- --- dragging and dropping of items onto another window. In this scenario, the onLButtonUp attached
        -- --- to the window is not activated. For example, if you drag an item from the inventory
        -- --- to the status window, the onLButtonUp attached to the status window will not be activated.
        Api.Event.RegisterEventHandler(Constants.SystemEvents.OnLButtonUpProcessed.getEvent(),
            "_Mongbat.OnLButtonUp")
        Api.Event.RegisterEventHandler(Constants.SystemEvents.OnLButtonDownProcessed.getEvent(),
            "_Mongbat.OnLButtonDown")
        Api.Event.RegisterEventHandler(Constants.SystemEvents.OnRButtonUpProcessed.getEvent(),
            "_Mongbat.OnRButtonUp")
        Api.Event.RegisterEventHandler(Constants.SystemEvents.OnRButtonDownProcessed.getEvent(),
            "_Mongbat.OnRButtonDown")
    end,
    OnShutdown = function()
        Api.Event.UnregisterEventHandler(Constants.SystemEvents.OnLButtonUpProcessed.getEvent(),
            "_Mongbat.OnLButtonUp")
        Api.Event.UnregisterEventHandler(Constants.SystemEvents.OnLButtonDownProcessed.getEvent(),
            "_Mongbat.OnLButtonDown")
        Api.Event.UnregisterEventHandler(Constants.SystemEvents.OnRButtonUpProcessed.getEvent(),
            "_Mongbat.OnRButtonUp")
        Api.Event.UnregisterEventHandler(Constants.SystemEvents.OnRButtonDownProcessed.getEvent(),
            "_Mongbat.OnRButtonDown")
    end,
    OnUpdate = function(timePassed)
        State.Systems.OnUpdate(timePassed)
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

function _Mongbat.OnUpdate(timePassed)
    mod:onUpdate(timePassed)
end

function _Mongbat.OnLButtonUp(flags, x, y)
    State.Systems.OnLButtonUp(flags, x, y)
end

function _Mongbat.OnLButtonDown(flags, x, y)
    State.Systems.OnLButtonDown(flags, x, y)
end

function _Mongbat.OnRButtonUp(flags, x, y)
    State.Systems.OnClick("onRButtonUp", flags, x, y)
end

function _Mongbat.OnRButtonDown(flags, x, y)
    State.Systems.OnClick("onRButtonDown", flags, x, y)
end

function _Mongbat.OnShown()
    local name = SystemData.ActiveWindow.name
    if State.TopLevelWindows[name] then
        Api.Window.SetShowing(name, true)
    end
end

function _Mongbat.OnHidden()
    local name = SystemData.ActiveWindow.name
    if State.TopLevelWindows[name] then
        Api.Window.SetShowing(name, false)
    end
end

function _Mongbat.OnLButtonDblClk(flags, x, y)
    local name = SystemData.ActiveWindow.name
    local component = State.ClickTargets[name]
    if component then
        local fn = component._handlers.onLButtonDblClk
        if fn then fn(component, flags, x, y) end
    end
end

function _Mongbat.OnShutdown()
    mod:onShutdown()
end
