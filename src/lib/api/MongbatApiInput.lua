---@diagnostic disable: undefined-global
---@class Api
local Api = Mongbat.Api

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
---@param dragSource number The drag source.
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
-- Api - Event
-- ========================================================================== --

Api.Event = {}

---
--- Broadcasts an event.
---@param event number The event to broadcast.
function Api.Event.Broadcast(event)
    BroadcastEvent(event)
end

--- Broadcasts the `REQUEST_OPEN_HELP_MENU` system event.
function Api.Event.OpenHelpMenu()
    Api.Event.Broadcast(SystemData.Events.REQUEST_OPEN_HELP_MENU)
end

--- Broadcasts the `UO_STORE_REQUEST` system event.
function Api.Event.OpenStore()
    Api.Event.Broadcast(SystemData.Events.UO_STORE_REQUEST)
end

--- Broadcasts the `LOG_OUT` system event.
function Api.Event.Logout()
    Api.Event.Broadcast(SystemData.Events.LOG_OUT)
end

--- Broadcasts the `EXIT_GAME` system event.
function Api.Event.ExitGame()
    Api.Event.Broadcast(SystemData.Events.EXIT_GAME)
end

---
--- Registers a persistent global event handler.
---@param event number The event ID to listen for.
---@param callback string The name of the global handler function.
function Api.Event.RegisterEventHandler(event, callback)
    RegisterEventHandler(event, callback)
end

---
--- Unregisters a persistent global event handler.
---@param event number The event ID to stop listening for.
---@param callback string The name of the global handler function.
function Api.Event.UnregisterEventHandler(event, callback)
    UnregisterEventHandler(event, callback)
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

