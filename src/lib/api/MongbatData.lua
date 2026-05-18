---@diagnostic disable: undefined-global
---@class Data
local Data = {}

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

---@return number
function ActiveMobile:getId()
    return self:getData().Id
end

---@param id number
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

---@return boolean
function CurrentTarget:hasTarget()
    return self:getData().HasTarget
end

---@return boolean
function CurrentTarget:isMobile()
    return self:getData().TargetType == 2
end

---@return boolean
function CurrentTarget:isCorpse()
    return self:getData().TargetType == 4
end

---@return boolean
function CurrentTarget:isObject()
    return self:getData().TargetType == 3
end

---@return number
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

---@return boolean
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

---@return boolean
function Drag:isDraggingItem()
    return self:getDragItemData().DragType == SystemData.DragItem.TYPE_ITEM
end

---@return number
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

---@return WindowData.HealthBarColor?
function HealthBarColor:getData()
    return WindowData.HealthBarColor and WindowData.HealthBarColor[self._id]
end

---@return integer?
function HealthBarColor:getVisualStateId()
    local data = self:getData()
    return data and data.VisualStateId
end

---@return Color?
function HealthBarColor:getVisualStateColor()
    local id = self:getVisualStateId()
    if id == nil then return nil end
    return Mongbat.Constants.Colors.HealhBar[id + 1]
end

function Data.HealthBarColor(id)
    return HealthBarColor:new(id)
end

-- ========================================================================== --
-- Data - Mobile Name
-- ========================================================================== --

---@class WindowData.MobileName
---@field MobName string

---@class MobileNameWrapper
---@field _id number
local MobileName = {}
MobileName.__index = MobileName

function MobileName:new(id)
    local instance = setmetatable({}, self)
    instance._id = id
    return instance
end

---@return WindowData.MobileName?
function MobileName:getData()
    return WindowData.MobileName and WindowData.MobileName[self._id]
end

---@return string?
function MobileName:getName()
    local data = self:getData()
    return data and data.MobName
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

---@return WindowData.MobileStatus?
function MobileStatus:getData()
    return WindowData.MobileStatus and WindowData.MobileStatus[self._id]
end

---@return string?
function MobileStatus:getName()
    local data = self:getData()
    return data and data.MobName
end

---@return integer?
function MobileStatus:getNotoriety()
    local data = self:getData()
    return data and data.Notoriety
end

---@return Color?
function MobileStatus:getNotorietyColor()
    local n = self:getNotoriety()
    if n == nil then return nil end
    return Mongbat.Constants.Colors.Notoriety[n + 1]
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
    return flags == Mongbat.Constants.ButtonFlags.Shift
end

--- Checks whether a flags value contains the Control modifier.
---@param flags number
---@return boolean
function Data.IsControl(flags)
    return flags == Mongbat.Constants.ButtonFlags.Control
end

--- Checks whether a flags value contains the Alt modifier.
---@param flags number
---@return boolean
function Data.IsAlt(flags)
    return flags == Mongbat.Constants.ButtonFlags.Alt
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
    return Mongbat.Api.Object.IsValid(self._id)
end

function Object:isMobile()
    return Mongbat.Api.Object.IsMobile(self._id)
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
    if not windowData or not windowData.ObjectId then return {} end

    return Mongbat.Utils.Array.MapToTable(
        windowData.ObjectId,
        function(item)
            return item
        end,
        function(item, index)
            return {
                id = item,
                name = Mongbat.Utils.String.FromWString(windowData.Names[index]),
                notoriety = windowData.Notoriety[index],
                isMobile = windowData.IsMobile[index],
                isValid = function()
                    return Data.Object(item):isValid()
                        and Mongbat.Utils.Array.Find(windowData.ObjectId, function(id)
                            return id == item
                        end)
                end
            }
        end
    )
end

---@param id integer The object ID to look up.
---@return ObjectHandle? The handle entry, or nil if not found.
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

---@return number
function PlayerStatus:getStatCap()
    return self:getData().StatCap or 0
end

---@return number
function PlayerStatus:getCurrentMana()
    return self:getData().CurrentMana or 0
end

---@return number
function PlayerStatus:getMaxMana()
    return self:getData().MaxMana or 0
end

---@return number
function PlayerStatus:getCurrentHealth()
    return self:getData().CurrentHealth or 0
end

---@return number
function PlayerStatus:getMaxHealth()
    return self:getData().MaxHealth or 0
end

---@return number
function PlayerStatus:getCurrentStamina()
    return self:getData().CurrentStamina or 0
end

---@return number
function PlayerStatus:getMaxStamina()
    return self:getData().MaxStamina or 0
end

---@return boolean
function PlayerStatus:isInWarMode()
    return self:getData().InWarMode or false
end

---@return number
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
---@field _id number id of the paperdoll
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
    return (data and data.numSlots) or 0
end

--- Gets the slot data for a given index.
---@param index integer Slot index (1-based)
---@return PaperdollSlot|nil
function PaperdollData:getSlot(index)
    local data = self:getData()
    return data and data[index]
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
    return data.IsLegacy == 1 and data.Width * 2 or data.Width
end

---@return number Texture height (doubled for legacy textures)
function PaperdollTexture:getHeight()
    local data = self:getData()
    if not data then return 0 end
    return data.IsLegacy == 1 and data.Height * 2 or data.Height
end

---@return number X offset for anchoring
function PaperdollTexture:getXOffset()
    local data = self:getData()
    return (data and data.xOffset) or 0
end

---@return number Y offset for anchoring
function PaperdollTexture:getYOffset()
    local data = self:getData()
    return (data and data.yOffset) or 0
end

---@return boolean Whether this is a legacy texture
function PaperdollTexture:isLegacy()
    local data = self:getData()
    return data ~= nil and data.IsLegacy == 1
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

---@class RadarWrapper
local Radar = {}
Radar.__index = Radar

function Radar:new() return setmetatable({}, self) end

---@return WindowData.Radar?
function Radar:getData()
    return WindowData.Radar
end

---@return integer
function Radar:getTexCoordX()
    local d = self:getData()
    return (d and d.TexCoordX) or 0
end

---@return integer
function Radar:getTexCoordY()
    local d = self:getData()
    return (d and d.TexCoordY) or 0
end

---@return number
function Radar:getTexScale()
    local d = self:getData()
    return (d and d.TexScale) or 1
end

---@return RadarWrapper
function Data.Radar() return Radar:new() end

-- ========================================================================== --
-- Data - WindowData (composite)
-- ========================================================================== --

---@class WindowDataWrapper
local WindowDataWrapper = {}
WindowDataWrapper.__index = WindowDataWrapper

function WindowDataWrapper:new() return setmetatable({}, self) end

---@return ActiveMobileWrapper
function WindowDataWrapper:activeMobile() return Data.ActiveMobile() end
---@return CurrentTargetWrapper
function WindowDataWrapper:currentTarget() return Data.CurrentTarget() end
---@return CursorDataWrapper
function WindowDataWrapper:cursor() return Data.Cursor() end
---@return DragDataWrapper
function WindowDataWrapper:drag() return Data.Drag() end
---@return PlayerStatusWrapper
function WindowDataWrapper:playerStatus() return Data.PlayerStatus() end
---@return PlayerLocationWrapper
function WindowDataWrapper:playerLocation() return Data.PlayerLocation() end
---@return ObjectHandleDataWrapper
function WindowDataWrapper:objectHandles() return Data.ObjectHandles() end
---@return RadarWrapper
function WindowDataWrapper:radar() return Data.Radar() end
---@param id integer
---@return HealthBarColorWrapper
function WindowDataWrapper:healthBarColor(id) return Data.HealthBarColor(id) end
---@param id integer
---@return MobileNameWrapper
function WindowDataWrapper:mobileName(id) return Data.MobileName(id) end
---@param id integer
---@return MobileStatusWrapper
function WindowDataWrapper:mobileStatus(id) return Data.MobileStatus(id) end
---@param id integer
---@return PaperdollWrapper
function WindowDataWrapper:paperdoll(id) return Data.Paperdoll(id) end
---@param id integer
---@return PaperdollTextureWrapper
function WindowDataWrapper:paperdollTexture(id) return Data.PaperdollTexture(id) end
---@param id integer
---@return ObjectWrapper
function WindowDataWrapper:object(id) return Data.Object(id) end

---@return WindowDataWrapper
function Data.WindowData() return WindowDataWrapper:new() end



Mongbat.Data = Data
