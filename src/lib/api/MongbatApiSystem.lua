---@diagnostic disable: undefined-global
---@class Api
local Api = Mongbat.Api

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
-- Api - Interface Core
-- ========================================================================== --


Api.InterfaceCore = {}

---
--- Gets the scale factor of the interface.
---@return number The scale factor.
function Api.InterfaceCore.GetScaleFactor()
    return 1 / InterfaceCore.scale
end

---
--- Gets the raw UI scale (screen pixels per logical pixel).
---@return number The UI scale.
function Api.InterfaceCore.GetScale()
    return InterfaceCore.scale
end

--- Triggers a full UI reload.
function Api.InterfaceCore.ReloadUI()
    InterfaceCore.ReloadUI()
end


-- ========================================================================== --
-- Api - Interface
-- ========================================================================== --

Api.Interface = {}

---
--- Saves a string value to persistent Interface storage.
---@param key string The storage key.
---@param value string The value to save.
function Api.Interface.SaveString(key, value)
    Interface.SaveString(key, value)
end

---
--- Loads a string value from persistent Interface storage.
---@param key string The storage key.
---@param default string? The default value if the key is not found.
---@return string? The stored value, or `default`.
function Api.Interface.LoadString(key, default)
    return Interface.LoadString(key, default)
end

---
--- Saves a number value to persistent Interface storage.
---@param key string The storage key.
---@param value number The value to save.
function Api.Interface.SaveNumber(key, value)
    Interface.SaveNumber(key, value)
end

---
--- Loads a number value from persistent Interface storage.
---@param key string The storage key.
---@param default number? The default value if the key is not found.
---@return number? The stored value, or `default`.
function Api.Interface.LoadNumber(key, default)
    return Interface.LoadNumber(key, default)
end

---
--- Saves a boolean value to persistent Interface storage.
---@param key string The storage key.
---@param value boolean The value to save.
function Api.Interface.SaveBoolean(key, value)
    Interface.SaveBoolean(key, value)
end

---
--- Loads a boolean value from persistent Interface storage.
---@param key string The storage key.
---@param default boolean? The default value if the key is not found.
---@return boolean? The stored value, or `default`.
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
-- Api - String
-- ========================================================================== --

Api.String = {}

---
--- Gets a string from a TID.
---@param tid number The TID.
---@return wstring The string.
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
-- Api - Time
-- ========================================================================== --

Api.Time = {}

---
--- Gets the current date and time.
---@return any The current date and time.
function Api.Time.GetCurrentDateTime()
    return GetCurrentDateTime()
end

