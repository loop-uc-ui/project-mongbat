---@diagnostic disable: undefined-global
---@class Api
local Api = Mongbat.Api

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

---
--- Sets the window offset for the radar display.
---@param x number The x offset.
---@param y number The y offset.
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

---
--- Gets the current saved radar zoom level.
---@return number The current zoom level.
function Api.Radar.GetCurrentZoom()
    return Api.Interface.LoadNumber("MapZoom", 0) or 0
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

