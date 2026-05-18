---@diagnostic disable: undefined-global
-- ========================================================================== --
-- _Mongbat.Systems.DataReg: WindowData registration ref-counter
-- ========================================================================== --
--
-- Manages RegisterWindowData / UnregisterWindowData calls so the same
-- (dataType, id) pair is only registered once even when multiple windows
-- share the same id. Unregistration fires only when the last window for
-- that pair is destroyed.
--
-- Public surface: _Mongbat.Systems.DataReg
--   .Attach(id)   register all DataTypes for this id (ref-counted)
--   .Detach(id)   decrement ref-count; unregister when it reaches zero

local Systems = _Mongbat.Systems

---@class DataReg
local DataReg = {}
Systems.DataReg = DataReg

--- WindowData type names the lib auto-registers per window. Names absent
--- from the engine's WindowData table at registration time are silently
--- skipped (different EC builds expose different surfaces).
local DataTypes = {
    "PlayerStatus", "MobileName", "HealthBarColor", "MobileStatus",
    "Radar", "PlayerLocation", "Paperdoll", "ObjectHandle",
}

--- Ref-count per (typeName .. ":" .. tostring(id)).
---@type table<string, number>
local DataRegistered = {}

--- Registers all DataTypes for `id`. Safe to call multiple times for the
--- same id — a ref-count ensures the engine call is only made once.
---@param id number
function DataReg.Attach(id)
    Mongbat.Utils.Array.ForEach(DataTypes, function(name)
        local entry = WindowData[name]
        if not entry or entry.Type == nil then return end
        local refKey = name .. ":" .. tostring(id)
        if not DataRegistered[refKey] then
            DataRegistered[refKey] = 0
            Mongbat.Api.Window.RegisterData(entry.Type, id)
        end
        DataRegistered[refKey] = DataRegistered[refKey] + 1
    end)
end

--- Decrements the ref-count for all DataTypes registered for `id` and
--- calls UnregisterWindowData when the count reaches zero.
---@param id number?
function DataReg.Detach(id)
    if id == nil then return end
    Mongbat.Utils.Array.ForEach(DataTypes, function(typeName)
        local refKey = typeName .. ":" .. tostring(id)
        local count = DataRegistered[refKey]
        if not count then return end
        count = count - 1
        if count <= 0 then
            DataRegistered[refKey] = nil
            local wd = WindowData[typeName]
            if wd and wd.Type ~= nil then
                Mongbat.Api.Window.UnregisterData(wd.Type, id)
            end
        else
            DataRegistered[refKey] = count
        end
    end)
end
