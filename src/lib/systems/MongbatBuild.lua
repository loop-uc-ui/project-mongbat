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

-- [modName] = { [key] = { engineName, template, parentKey, rootKey, id, widget, savePosition, snappable, cache? } }
---@type table<string, table>
local BuildState = {}

-- engineName -> { modName, key, rootKey } for O(1) router lookup.
---@type table<string, { modName: string, key: string, rootKey: string }>
local EngineLookup = {}

-- Dismissed root keys per mod. A dismissed (modName, rootKey) skips all
-- emits whose chain root is `rootKey`. Auto-cleared at the end of a frame
-- when the mod did not re-attempt the rootKey emit (i.e. the mod has
-- stopped wanting that subtree at all).
---@type table<string, table<string, true>>
local Dismissed = {}

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
    Systems.Resize.Teardown(entry.engineName)
    Systems.DataReg.Detach(entry.id)
    if entry.savePosition and Mongbat.Api.Window.DoesExist(entry.engineName) then
        Mongbat.Api.Window.SavePosition(entry.engineName, true)
    end
    Systems.Snap.Unregister(entry.engineName)
    Systems.Registry.Remove(entry.engineName)
    EngineLookup[entry.engineName] = nil
    if Mongbat.Api.Window.DoesExist(entry.engineName) then
        Mongbat.Api.Window.Destroy(entry.engineName)
    end
end

--- Applies resize state for one frame: ensures a grip exists (and is
--- registered) when `spec.resizable` is set, or tears the grip down when
--- the spec dropped the resizable flag.
---@param engineName string
---@param spec table
local function ensureResizeGrip(engineName, spec)
    local Resize = Systems.Resize
    if spec.resizable then
        local r = spec.resizable
        Resize.SetConfig(engineName, { minW = r.minW, minH = r.minH, state = r.state })
        Resize.EnsureGrip(engineName)
    elseif Resize.IsConfigured(engineName) then
        Resize.Teardown(engineName)
    end
end

--- Re-applies widget ops + per-frame routing fields to an existing window.
--- Called when the key was present last frame with the same engineName + template.
---@param engineName string
---@param spec table
---@param entry table        new BuildState entry for this frame
---@param prevEntry table    BuildState entry from prior frame (cache source)
---@param resolveKey fun(key: string): string?
---@param draggableRoot string?
---@param snappable boolean
local function reapplyExistingWindow(engineName, spec, entry, prevEntry, resolveKey, draggableRoot, snappable)
    entry.cache = prevEntry.cache or {}
    if spec.widget then spec.widget:_apply(engineName, resolveKey, false, entry.cache) end
    local winEntry = Systems.Registry.Get(engineName)
    if winEntry then
        winEntry.draggableRoot = draggableRoot
        winEntry.snappable     = snappable
    end
    ensureResizeGrip(engineName, spec)
end

--- Creates a new engine window, registers it, attaches data + events,
--- applies widget ops, and restores persisted position / snap registration.
--- Called when the key is new this frame, or when its engineName/template changed.
---@param modName string
---@param module ModModule
---@param key string
---@param spec table
---@param engineName string
---@param parentEngine string
---@param id number
---@param rootKey string
---@param draggableRoot string?
---@param savePosition boolean
---@param snappable boolean
---@param entry table         new BuildState entry to populate with cache
---@param prevEntry table?    BuildState entry from prior frame (destroyed when engineName/template changed)
---@param resolveKey fun(key: string): string?
local function createNewWindow(modName, module, key, spec, engineName, parentEngine,
                               id, rootKey, draggableRoot, savePosition, snappable,
                               entry, prevEntry, resolveKey)
    if prevEntry then destroyBuiltEntry(prevEntry) end
    if spec.replacesDefault then
        if Mongbat.Api.Window.DoesExist(engineName) then
            Mongbat.Api.Window.Destroy(engineName)
        end
        Mongbat.UI.Defaults.Suppress(engineName)
    end

    EngineLookup[engineName] = { modName = modName, key = key, rootKey = rootKey }
    Systems.Registry.Set(engineName, {
        module        = module,
        key           = key,
        id            = id,
        engineName    = engineName,
        draggableRoot = draggableRoot,
        savePosition  = savePosition,
        snappable     = snappable,
    })
    Mongbat.Api.Window.CreateFromTemplate(engineName, spec.template, parentEngine, spec.showing ~= false)
    Systems.Registry.AttachEvents(engineName)
    Systems.DataReg.Attach(id)
    entry.cache = {}
    if spec.widget then spec.widget:_apply(engineName, resolveKey, true, entry.cache) end
    if savePosition then Mongbat.Api.Window.RestorePosition(engineName, false) end
    if snappable then Systems.Snap.Register(engineName) end
    ensureResizeGrip(engineName, spec)
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

    -- Tracks keys the mod attempted to emit but were skipped because their
    -- root is dismissed. Used so children of a dismissed parent skip
    -- silently (no "unknown parent key" error) and so end-of-frame
    -- auto-clear knows the mod still wants the root.
    local skipped = {}

    local Registry = Systems.Registry

    -- key -> engineName lookup spanning both prior and current frame so
    -- widget _apply can resolve sibling-key parent references.
    local function resolveKey(k)
        local e = current[k] or prev[k]
        return e and e.engineName or nil
    end

    -- Builds a "valid keys this frame" hint for parent-resolution errors.
    -- Lists keys emitted before the failing call plus prior-frame keys
    -- carried over.
    local function knownKeys()
        local seen, names = {}, {}
        for _, k in ipairs(order) do
            if not seen[k] then seen[k] = true; names[#names + 1] = k end
        end
        for k in pairs(prev) do
            if k ~= "_order" and not seen[k] then seen[k] = true; names[#names + 1] = k end
        end
        if #names == 0 then return "(none yet)" end
        table.sort(names)
        return table.concat(names, ", ")
    end

    local dismissedForMod = Dismissed[modName]

    local function emit(key, spec)
        if current[key] then
            error("Mongbat.Build [" .. modName .. "]: duplicate emit key '" .. tostring(key)
                .. "'. Each window needs a unique key per frame.")
        end

        local parentKey = spec.parent

        -- Resolve parent's rootKey so we know which subtree we're in.
        -- If parent was already skipped this frame, cascade-skip silently.
        local rootKey
        local parentEntry
        if parentKey then
            if skipped[parentKey] then
                skipped[key] = true
                return
            end
            parentEntry = current[parentKey] or prev[parentKey]
            if not parentEntry then
                error("Mongbat.Build [" .. modName .. "]: unknown parent key '" .. tostring(parentKey)
                    .. "' for '" .. tostring(key) .. "'. Emit the parent key before its children, "
                    .. "or set parent=nil to root the window. Known keys: " .. knownKeys() .. ".")
            end
            rootKey = parentEntry.rootKey
        else
            rootKey = key
        end

        if dismissedForMod and dismissedForMod[rootKey] then
            skipped[key] = true
            return
        end

        local engineName = spec.name or defaultEngineName(modName, key)
        local id         = spec.id or 0
        local parentEngine

        if parentKey then
            parentEngine = resolveKey(parentKey)
            if not parentEngine then
                error("Mongbat.Build [" .. modName .. "]: unknown parent key '" .. tostring(parentKey)
                    .. "' for '" .. tostring(key) .. "'. Emit the parent key before its children, "
                    .. "or set parent=nil to root the window. Known keys: " .. knownKeys() .. ".")
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
            rootKey      = rootKey,
            id           = id,
            widget       = spec.widget,
            savePosition = savePosition,
            snappable    = snappable,
        }
        current[key] = entry
        order[#order + 1] = key

        local prevEntry = prev[key]
        if prevEntry and prevEntry.engineName == engineName and prevEntry.template == spec.template then
            reapplyExistingWindow(engineName, spec, entry, prevEntry, resolveKey, draggableRoot, snappable)
        else
            createNewWindow(modName, module, key, spec, engineName, parentEngine,
                            id, rootKey, draggableRoot, savePosition, snappable,
                            entry, prevEntry, resolveKey)
        end
    end

    module.Build(emit)

    -- Destroy keys present last frame but not this frame.
    for k, prevEntry in pairs(prev) do
        if k ~= "_order" and not current[k] then
            destroyBuiltEntry(prevEntry)
        end
    end

    -- Auto-clear dismissed root keys the mod stopped trying to emit. A
    -- root is still "wanted" if the mod called emit(rootKey, ...) this
    -- frame, regardless of whether the emit was accepted (current) or
    -- skipped because of dismiss (skipped).
    if dismissedForMod then
        for rootKey in pairs(dismissedForMod) do
            if not current[rootKey] and not skipped[rootKey] then
                dismissedForMod[rootKey] = nil
            end
        end
        if next(dismissedForMod) == nil then
            Dismissed[modName] = nil
        end
    end

    current._order = order
end

--- Destroys every built entry in `modName` whose chain root is `rootKey`
--- and marks the root as dismissed. The dismissal is auto-cleared at
--- end of frame if the mod stops calling `emit(rootKey, ...)`; if the
--- mod keeps emitting it, the dismissal stays in effect (and the emits
--- are silently skipped) until the mod stops.
---@param modName string
---@param rootKey string
function Build.Dismiss(modName, rootKey)
    local state = BuildState[modName]
    if state then
        Mongbat.Utils.Table.ForEach(state, function(k, entry)
            if k ~= "_order" and entry.rootKey == rootKey then
                destroyBuiltEntry(entry)
                state[k] = nil
            end
        end)
    end
    Dismissed[modName] = Dismissed[modName] or {}
    Dismissed[modName][rootKey] = true
end

--- Returns the routing context for `engineName`: which mod owns it,
--- the per-mod key, and the chain-root key (the parent-chain top).
--- Nil when the window is not a Build-owned window.
---@param engineName string
---@return { modName: string, key: string, rootKey: string }?
function Build.GetRoot(engineName)
    return EngineLookup[engineName]
end

--- Tears down all windows emitted by this mod's Build. Called on mod unload.
---@param modName string
function Build.TeardownMod(modName)
    local prev = BuildState[modName]
    if not prev then return end
    Mongbat.Utils.Table.ForEach(prev, function(k, entry)
        if k ~= "_order" then destroyBuiltEntry(entry) end
    end)
    BuildState[modName] = nil
end
