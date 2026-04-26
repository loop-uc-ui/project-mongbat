---@diagnostic disable: undefined-global
---@class Constants
local Constants = {}

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

---@return integer
function Constants.DragSource.Object()
    return SystemData.DragSource["SOURCETYPE_OBJECT"]
end

---@return integer
function Constants.DragSource.Paperdoll()
    return SystemData.DragSource["SOURCETYPE_PAPERDOLL"]
end

Constants.Broadcasts = {}

---@return integer
function Constants.Broadcasts.Help()
    return SystemData.Events["REQUEST_OPEN_HELP_MENU"]
end

---@return integer
function Constants.Broadcasts.BeginHealthBarDrag()
    return SystemData.Events["BEGIN_DRAG_HEALTHBAR_WINDOW"]
end

---@return integer
function Constants.Broadcasts.EscapeKeyProcessed()
    return SystemData.Events["ESCAPE_KEY_PROCESSED"]
end

---@return integer
function Constants.Broadcasts.ExitGame()
    return SystemData.Events["EXIT_GAME"]
end

---@return integer
function Constants.Broadcasts.BugReport()
    return SystemData.Events["BUG_REPORT_SCREEN"]
end

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



Mongbat.Constants = Constants
