---@diagnostic disable: undefined-global
---@class Utils
local Utils = {}

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

--- Returns true if `table` is nil or has no iteration entries.
---@param table table? The table to check.
---@return boolean
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

--- Converts a wstring to a plain Lua string. If `text` is already a
--- plain string, returns it unchanged.
---@param text string|wstring The value to convert.
---@return string The plain string.
function Utils.String.FromWString(text)
    if type(text) == "string" then
        return text
    else
        return Mongbat.Api.String.WStringToString(text)
    end
end

---@param text string|wstring|number|nil
---@return wstring
function Utils.String.ToWString(text)
    if text == nil then return L "" end
    if type(text) == "number" then
        return Mongbat.Api.String.GetStringFromTid(text)
    elseif type(text) == "wstring" then
        return text
    elseif type(text) == "string" then
        return Mongbat.Api.String.StringToWString(text)
    else
        return Mongbat.Api.String.StringToWString(tostring(text))
    end
end

--- Converts a string or wstring to lowercase, preserving the input type.
---@param text string|wstring The value to convert.
---@return string|wstring The lowercased value.
function Utils.String.Lower(text)
    if type(text) == "wstring" then
        return wstring.lower(text)
    end
    return string.lower(text)
end

--- Converts a string or wstring to uppercase, preserving the input type.
---@param text string|wstring The value to convert.
---@return string|wstring The uppercased value.
function Utils.String.Upper(text)
    if type(text) == "wstring" then
        return wstring.upper(text)
    end
    return string.upper(text)
end

---@param text string|wstring
---@return integer
function Utils.String.Len(text)
    if type(text) == "wstring" then
        return wstring.len(text)
    end
    return string.len(text)
end

---@param text string|wstring?
---@return boolean
function Utils.String.IsEmpty(text)
    if text == nil then return true end
    return Utils.String.Len(text) <= 0
end

---@param haystack string|wstring
---@param needle string|wstring
---@return integer?
function Utils.String.Find(haystack, needle)
    if type(haystack) == "wstring" then
        return wstring.find(haystack, needle)
    end
    return string.find(haystack, needle)
end

---@param fmt string
---@param ... any
---@return string
function Utils.String.Format(fmt, ...)
    return string.format(fmt, ...)
end


Mongbat.Utils = Utils
