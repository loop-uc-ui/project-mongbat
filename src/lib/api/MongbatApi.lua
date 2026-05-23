---@diagnostic disable: undefined-global
---@class Api
local Api = {}
Mongbat.Api = Api

---@alias Dimensions { x: number, y: number }

-- ========================================================================== --
-- Mongbat.Api Package
-- ========================================================================== --
--
-- Public engine wrapper surface for Mongbat. The package is split by domain
-- and loaded by MongbatApi.mod in this order:
--
--   MongbatApi.lua             package bootstrap + global safety overrides
--   MongbatApiWidgets.lua      Window/widget wrappers
--   MongbatApiInput.lua        input, target, drag, user action, events
--   MongbatApiWorld.lua        world/object/radar/waypoint wrappers
--   MongbatApiSystem.lua       chat, strings, gumps, mod, interface, time
--   MongbatApiDefaultUI.lua    default-UI lifecycle/chain helpers
--
-- Keep public namespaces compatible: Mongbat.Api.Window, Mongbat.Api.Label,
-- etc. New wrappers should go in the smallest matching domain file.
-- ========================================================================== --
-- ========================================================================== --

--[[
    In order to reduce errors as we override parts of the default UI, we override
    certain global functions to add safety checks.
]] --

-- Save the original function
local old_WindowGetShowing = WindowGetShowing

-- Override the global
function WindowGetShowing(windowName)
    if not DoesWindowNameExist(windowName) then
        return false
    end
    return old_WindowGetShowing(windowName)
end

-- Save the original function
local old_WindowSetShowing = WindowSetShowing

-- Override the global
function WindowSetShowing(windowName, show)
    if DoesWindowNameExist(windowName) then
        old_WindowSetShowing(windowName, show)
    end
end

-- Save the original function
local old_LabelSetText = LabelSetText

-- Override the global
function LabelSetText(labelName, text)
    if DoesWindowNameExist(labelName) then
        old_LabelSetText(labelName, text)
    end
end

-- Save the original function
local old_CircleImageSetTextureScale = CircleImageSetTextureScale

-- Override the global
function CircleImageSetTextureScale(imageName, scale)
    if DoesWindowNameExist(imageName) then
        old_CircleImageSetTextureScale(imageName, scale)
    end
end

-- Save the original function
local old_CircleImageSetTexture = CircleImageSetTexture

-- Override the global
function CircleImageSetTexture(imageName, texture, x, y)
    if DoesWindowNameExist(imageName) then
        old_CircleImageSetTexture(imageName, texture, x, y)
    end
end

local old_RegisterWindowData = RegisterWindowData

function RegisterWindowData(dataType, id)
    old_RegisterWindowData(dataType, id or 0)
end

local old_StatusBarSetMaximumValue = StatusBarSetMaximumValue

function StatusBarSetMaximumValue(barName, maxValue)
    if maxValue ~= nil and DoesWindowNameExist(barName) then
        old_StatusBarSetMaximumValue(barName, maxValue)
    end
end

local old_StatusBarSetCurrentValue = StatusBarSetCurrentValue

function StatusBarSetCurrentValue(barName, currentValue)
    if currentValue ~= nil and DoesWindowNameExist(barName) then
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

local old_WindowGetDimensions = WindowGetDimensions

function WindowGetDimensions(windowName)
    if not DoesWindowNameExist(windowName) then
        return 0, 0
    end
    return old_WindowGetDimensions(windowName)
end

local old_WindowSetDimensions = WindowSetDimensions

function WindowSetDimensions(windowName, width, height)
    if DoesWindowNameExist(windowName) then
        old_WindowSetDimensions(windowName, width, height)
    end
end

local old_WindowSetTintColor = WindowSetTintColor

function WindowSetTintColor(windowName, r, g, b)
    if DoesWindowNameExist(windowName) then
        old_WindowSetTintColor(windowName, r, g, b)
    end
end

local old_WindowSetAlpha = WindowSetAlpha

function WindowSetAlpha(windowName, alpha)
    if DoesWindowNameExist(windowName) then
        old_WindowSetAlpha(windowName, alpha)
    end
end

local old_ButtonSetTexture = ButtonSetTexture

function ButtonSetTexture(buttonName, state, texture, x, y)
    if DoesWindowNameExist(buttonName) then
        old_ButtonSetTexture(buttonName, state, texture, x, y)
    end
end

local old_ButtonSetPressedFlag = ButtonSetPressedFlag

function ButtonSetPressedFlag(buttonName, pressed)
    if DoesWindowNameExist(buttonName) then
        old_ButtonSetPressedFlag(buttonName, pressed)
    end
end

