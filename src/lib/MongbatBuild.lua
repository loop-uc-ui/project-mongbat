---@diagnostic disable: undefined-global
-- ========================================================================== --
-- _Mongbat.Systems.Build: Declarative window reconciler
-- ========================================================================== --
--
-- Mods implement M.Build(emit). The lib calls Build every frame; the mod
-- calls emit(key, spec) once per window it wants this frame. The lib
-- diffs the emitted set against the prior frame: new keys -> create +
-- register, existing keys -> re-apply widget ops, missing keys -> destroy.
--
-- spec fields:
--   template        string            engine template name (required)
--   widget          MongbatUI widget  recorded ops, applied after create
--   parent          string?           sibling key in this mod, or nil (-> Root)
--   name            string?           override engine name (default-UI hijack)
--   id              number?           WindowData id (default 0)
--   showing         boolean?          initial visibility (default true)
--   replacesDefault boolean?          destroy engine name once before first create
--   draggable       boolean?          makes this window the drag root
--   savePosition    boolean?          override position persistence (default true for root)
--   snappable       boolean?          override snap registration (default true for root)
--   resizable       { minW, minH, state }?  enables bottom-right grip resize
--
-- Engine name = spec.name or "<modName>_<key>" (sanitized).
--
-- Public surface: _Mongbat.Systems.Build
--   .RunMod(modName, module)   reconcile one mod's Build output (called per-frame)
--   .TeardownMod(modName)      destroy all windows for a mod (called on unload)

local Systems = _Mongbat.Systems

---@class Build
local Build = {}
Systems.Build = Build

-- [modName] = { [key] = { engineName, template, parentKey, id, widget, savePosition, snappable, cache? } }
---@type table<string, table>
local BuildState = {}

-- ----- Helpers -------------------------------------------------------------

local function sanitizeKey(key)
    return (tostring(key):gsub("[^%w_]", "_"))
end

local function defaultEngineName(modName, key)
    return modName .. "_" .. sanitizeKey(key)
end

--- Destroys a single window entry: tears down grip, detaches data,
--- saves position, unregisters from snap, removes from registry, destroys engine window.
---@param entry table
local function destroyBuiltEntry(entry)
    local Resize   = Systems.Resize
    local Registry = Systems.Registry
    Registry.Remove(Resize.GripNameFor(entry.engineName))
    Resize.Teardown(entry.engineName)
    Systems.DataReg.Detach(entry.id)
    if entry.savePosition and Mongbat.Api.Window.DoesExist(entry.engineName) then
        Mongbat.Api.Window.SavePosition(entry.engineName, true)
    end
    Systems.Snap.Unregister(entry.engineName)
    Registry.Remove(entry.engineName)
    if Mongbat.Api.Window.DoesExist(entry.engineName) then
        Mongbat.Api.Window.Destroy(entry.engineName)
    end
end

-- ----- Public API ----------------------------------------------------------

--- Reconciles one frame of M.Build for a single mod. Creates new windows,
--- re-applies widgets on existing ones, and destroys windows no longer emitted.
---@param modName string
---@param module ModModule
function Build.RunMod(modName, module)
    if not module.Build then return end
    local prev    = BuildState[modName] or {}
    local current = {}
    local order   = {}
    BuildState[modName] = current

    local Registry = Systems.Registry
    local Resize   = Systems.Resize

    -- key -> engineName lookup spanning both prior and current frame so
    -- widget _apply can resolve sibling-key parent references.
    local function resolveKey(k)
        local e = current[k] or prev[k]
        return e and e.engineName or nil
    end

    local function emit(key, spec)
        if current[key] then
            error("Mongbat.Build [" .. modName .. "]: duplicate emit key '" .. tostring(key) .. "'")
        end

        local engineName = spec.name or defaultEngineName(modName, key)
        local id         = spec.id or 0
        local parentKey  = spec.parent
        local parentEngine

        if parentKey then
            parentEngine = resolveKey(parentKey)
            if not parentEngine then
                error("Mongbat.Build [" .. modName .. "]: unknown parent key '" .. tostring(parentKey)
                    .. "' for '" .. tostring(key) .. "'. Emit the parent first.")
            end
        else
            parentEngine = "Root"
        end

        -- draggable: this window is the drag root; children inherit it.
        local draggableRoot
        if spec.draggable then
            draggableRoot = engineName
        else
            draggableRoot = Registry.GetDraggableRoot(parentEngine)
        end

        -- savePosition: defaults true for root-level windows.
        local savePosition
        if spec.savePosition ~= nil then
            savePosition = spec.savePosition
        else
            savePosition = (parentEngine == "Root")
        end

        -- snappable: defaults true for root-level windows.
        local snappable
        if spec.snappable ~= nil then
            snappable = spec.snappable
        else
            snappable = (parentEngine == "Root")
        end

        local entry = {
            engineName   = engineName,
            template     = spec.template,
            parentKey    = parentKey,
            id           = id,
            widget       = spec.widget,
            savePosition = savePosition,
            snappable    = snappable,
        }
        current[key] = entry
        order[#order + 1] = key

        local prevEntry = prev[key]
        if prevEntry and prevEntry.engineName == engineName and prevEntry.template == spec.template then
            -- Existing window: re-apply widget ops; update live registry entry.
            entry.cache = prevEntry.cache or {}
            if spec.widget then spec.widget:_apply(engineName, resolveKey, false, entry.cache) end
            local winEntry = Registry.Get(engineName)
            if winEntry then
                winEntry.draggableRoot = draggableRoot
                winEntry.snappable     = snappable
            end
            if spec.resizable then
                local r = spec.resizable
                Resize.SetConfig(engineName, { minW = r.minW, minH = r.minH, state = r.state })
                local gripName = Resize.EnsureGrip(engineName)
                if gripName then
                    Registry.Set(gripName, { module = Resize.GripModule, key = engineName, id = 0, engineName = gripName })
                    Registry.AttachEvents(gripName)
                end
                Resize.EnsureGlobalUpHandler()
            elseif Resize.IsConfigured(engineName) then
                Registry.Remove(Resize.GripNameFor(engineName))
                Resize.Teardown(engineName)
            end
            return
        end

        -- New (or template/name changed): create from scratch.
        if prevEntry then destroyBuiltEntry(prevEntry) end
        if spec.replacesDefault and Mongbat.Api.Window.DoesExist(engineName) then
            Mongbat.Api.Window.Destroy(engineName)
        end

        Registry.Set(engineName, {
            module        = module,
            key           = key,
            id            = id,
            engineName    = engineName,
            draggableRoot = draggableRoot,
            savePosition  = savePosition,
            snappable     = snappable,
        })
        Mongbat.Api.Window.CreateFromTemplate(engineName, spec.template, parentEngine, spec.showing ~= false)
        Registry.AttachEvents(engineName)
        Systems.DataReg.Attach(id)
        entry.cache = {}
        if spec.widget then spec.widget:_apply(engineName, resolveKey, true, entry.cache) end
        if savePosition then Mongbat.Api.Window.RestorePosition(engineName, false) end
        if snappable then Systems.Snap.Register(engineName) end
        if spec.resizable then
            local r = spec.resizable
            Resize.SetConfig(engineName, { minW = r.minW, minH = r.minH, state = r.state })
            local gripName = Resize.EnsureGrip(engineName)
            if gripName then
                Registry.Set(gripName, { module = Resize.GripModule, key = engineName, id = 0, engineName = gripName })
                Registry.AttachEvents(gripName)
            end
            Resize.EnsureGlobalUpHandler()
        elseif Resize.IsConfigured(engineName) then
            Registry.Remove(Resize.GripNameFor(engineName))
            Resize.Teardown(engineName)
        end
    end

    module.Build(emit)

    -- Destroy keys present last frame but not this frame.
    for k, prevEntry in pairs(prev) do
        if k ~= "_order" and not current[k] then
            destroyBuiltEntry(prevEntry)
        end
    end

    current._order = order
end

--- Tears down all windows emitted by this mod's Build. Called on mod unload.
---@param modName string
function Build.TeardownMod(modName)
    local prev = BuildState[modName]
    if not prev then return end
    for k, entry in pairs(prev) do
        if k ~= "_order" then destroyBuiltEntry(entry) end
    end
    BuildState[modName] = nil
end
