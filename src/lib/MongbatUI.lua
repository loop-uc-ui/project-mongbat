---@diagnostic disable: undefined-global
-- ========================================================================== --
-- MongbatUI: Declarative widget builders + bound widget handles
-- ========================================================================== --
--
-- Two modes:
--
-- 1. UNBOUND BUILDER (used inside M.Build(emit) factories):
--      UI.Label():setText("Hi"):addAnchor("topleft", "panel", "topleft", 0, 0)
--    The widget has no engine name yet. Setters record operations into
--    `widget._ops`. The lib calls `widget:_apply(engineName, resolveKey)`
--    after creating the engine window; this walks _ops, substituting any
--    sibling-key references in anchor/parent positions to engine names.
--
-- 2. BOUND HANDLE (used for ad-hoc reads/writes against an existing window):
--      UI.Label("MyMod_NameLabel"):getText()
--    Setters push to the engine immediately. This is the original mode.
--
-- Sibling-key references: in unbound mode, addAnchor's `rel` argument and
-- setParent's argument may name a SIBLING KEY in the same mod's Build().
-- The lib resolves the string to an engine name during _apply.
-- ========================================================================== --

local UI = {}
local Api = Mongbat.Api

-- -------------------------------------------------------------------------- --
-- Op-list machinery
-- -------------------------------------------------------------------------- --
-- Each widget records calls as { method, args... } tuples in self._ops.
-- _apply walks _ops; any arg that the lib should resolve as a sibling-key
-- string is wrapped in a tiny `{ keyref = "X" }` table by the helper below.

local function isUnbound(self) return self.name == nil end

-- Record an op when unbound, push directly when bound.
local function record(self, fn, ...)
    if isUnbound(self) then
        self._ops[#self._ops + 1] = { fn = fn, args = { ... }, n = select("#", ...) }
    else
        fn(self.name, ...)
    end
    return self
end

-- Wrap a string arg that should be resolved as a sibling-key during apply.
-- Used for addAnchor's relativeTo and setParent's parent name.
local function asKeyRef(s) return { _keyref = s } end

-- Unwrap a value: if it's a keyref table, resolve via the lookup; else pass through.
local function resolveArg(v, resolveKey)
    if type(v) == "table" and v._keyref then
        local resolved = resolveKey(v._keyref)
        return resolved or v._keyref
    end
    return v
end

-- -------------------------------------------------------------------------- --
-- Window (base class for all widgets)
-- -------------------------------------------------------------------------- --

local Window = {}
Window.__index = Window

--- Construct a Window handle. Pass `name` to bind to an existing engine
--- window (setters push immediately). Omit `name` to create an unbound
--- builder for use inside M.Build(emit) (setters record into _ops).
function UI.Window(name)
    return setmetatable({ name = name, _ops = name and nil or {} }, Window)
end

-- Identity / lifecycle (only meaningful for bound handles)
function Window:getName() return self.name end
function Window:exists() return self.name and Api.Window.DoesExist(self.name) or false end

-- Visibility / focus
function Window:setShowing(s) return record(self, Api.Window.SetShowing, s) end
function Window:isShowing() return Api.Window.IsShowing(self.name) end
function Window:show() return record(self, Api.Window.SetShowing, true) end
function Window:hide() return record(self, Api.Window.SetShowing, false) end
function Window:assignFocus(f) return record(self, Api.Window.AssignFocus, f) end
function Window:hasFocus() return Api.Window.HasFocus(self.name) end

-- Geometry
function Window:setDimensions(w, h) return record(self, Api.Window.SetDimensions, w, h) end
function Window:getDimensions() return Api.Window.GetDimensions(self.name) end
function Window:setPosition(x, y) return record(self, Api.Window.SetPosition, x, y) end
function Window:getPosition() return Api.Window.GetPosition(self.name) end
function Window:setScale(s) return record(self, Api.Window.SetScale, s) end
function Window:getScale() return Api.Window.GetScale(self.name) end

-- Appearance
function Window:setColor(c) return record(self, Api.Window.SetColor, c) end
function Window:getColor() return Api.Window.GetColor(self.name) end
function Window:setAlpha(a) return record(self, Api.Window.SetAlpha, a) end
function Window:getAlpha() return Api.Window.GetAlpha(self.name) end

-- Identity / layering
function Window:setId(id) return record(self, Api.Window.SetId, id) end
function Window:getId() return Api.Window.GetId(self.name) end
function Window:setLayer(l) return record(self, Api.Window.SetLayer, l) end
function Window:getLayer() return Api.Window.GetLayer(self.name) end

-- Movement
function Window:setMoving(m) return record(self, Api.Window.SetMoving, m) end
function Window:isMoving() return Api.Window.IsMoving(self.name) end
function Window:setMovable(m) return record(self, Api.Window.SetMovable, m) end

-- Input / world attachment
function Window:setHandleInput(b) return record(self, Api.Window.SetHandleInput, b) end
function Window:attachToWorldObject(objectId)
    -- AttachToWorldObject takes (objectId, windowName) — flipped, so don't use
    -- record(); apply manually.
    if isUnbound(self) then
        self._ops[#self._ops + 1] = { fn = function(name, id) Api.Window.AttachToWorldObject(id, name) end, args = { objectId }, n = 1 }
    else
        Api.Window.AttachToWorldObject(objectId, self.name)
    end
    return self
end

-- Escape hatch: apply an arbitrary function to the bound name. Useful for
-- engine APIs that don't fit the setter pattern (e.g. Equipment.UpdateItemIcon).
function Window:tap(fn) return record(self, fn) end

-- Anchors / parent. `rel` and `parent` may be sibling keys when unbound.
function Window:clearAnchors() return record(self, Api.Window.ClearAnchors) end
function Window:addAnchor(point, rel, relPoint, x, y)
    return record(self, Api.Window.AddAnchor, point, asKeyRef(rel), relPoint, x, y)
end
function Window:setParent(p) return record(self, Api.Window.SetParent, asKeyRef(p)) end
function Window:getParent() return Api.Window.GetParent(self.name) end
function Window:setOffsetFromParent(x, y) return record(self, Api.Window.SetOffsetFromParent, x, y) end
function Window:getOffsetFromParent() return Api.Window.GetOffsetFromParent(self.name) end

--- Walk recorded ops, binding to `engineName`. `resolveKey` is a function
--- (string) -> string|nil that maps a sibling key to its engine name.
--- Bound widgets ignore _apply (no _ops).
function Window:_apply(engineName, resolveKey)
    if not self._ops then return end
    for i = 1, #self._ops do
        local op = self._ops[i]
        local args = op.args
        -- Walk to op.n so trailing nils are preserved on engine calls
        -- that take fixed-arity arguments.
        if op.n == 0 then
            op.fn(engineName)
        elseif op.n == 1 then
            op.fn(engineName, resolveArg(args[1], resolveKey))
        elseif op.n == 2 then
            op.fn(engineName, resolveArg(args[1], resolveKey), resolveArg(args[2], resolveKey))
        elseif op.n == 3 then
            op.fn(engineName,
                resolveArg(args[1], resolveKey), resolveArg(args[2], resolveKey),
                resolveArg(args[3], resolveKey))
        elseif op.n == 4 then
            op.fn(engineName,
                resolveArg(args[1], resolveKey), resolveArg(args[2], resolveKey),
                resolveArg(args[3], resolveKey), resolveArg(args[4], resolveKey))
        elseif op.n == 5 then
            op.fn(engineName,
                resolveArg(args[1], resolveKey), resolveArg(args[2], resolveKey),
                resolveArg(args[3], resolveKey), resolveArg(args[4], resolveKey),
                resolveArg(args[5], resolveKey))
        else
            -- Fallback: build a resolved table and unpack.
            local resolved = {}
            for j = 1, op.n do resolved[j] = resolveArg(args[j], resolveKey) end
            op.fn(engineName, table.unpack(resolved, 1, op.n))
        end
    end
end

-- Allow other widget classes to inherit Window's surface.
local function inheritWindow(klass)
    setmetatable(klass, { __index = Window })
    klass.__index = klass
    return klass
end

-- -------------------------------------------------------------------------- --
-- Label
-- -------------------------------------------------------------------------- --

local Label = inheritWindow({})
function UI.Label(name)
    return setmetatable({ name = name, _ops = name and nil or {} }, Label)
end

function Label:setText(t) return record(self, Api.Label.SetText, t) end
function Label:getText() return Api.Label.GetText(self.name) end
function Label:setTextColor(c) return record(self, Api.Label.SetTextColor, c) end
function Label:setTextAlignment(a) return record(self, Api.Label.SetTextAlignment, a) end
function Label:setWordWrap(w) return record(self, Api.Label.SetWordWrap, w) end

-- -------------------------------------------------------------------------- --
-- Button
-- -------------------------------------------------------------------------- --

local Button = inheritWindow({})
function UI.Button(name)
    return setmetatable({ name = name, _ops = name and nil or {} }, Button)
end

function Button:setText(t) return record(self, Api.Button.SetText, t) end
function Button:getText() return Api.Button.GetText(self.name) end
function Button:setTextColor(r, g, b, a) return record(self, Api.Button.SetTextColor, r, g, b, a) end
function Button:getTextDimensions() return Api.Button.GetTextDimensions(self.name) end
function Button:setDisabled(d) return record(self, Api.Button.SetDisabled, d) end
function Button:isDisabled() return Api.Button.IsDisabled(self.name) end
function Button:setEnabled(e) return record(self, Api.Button.SetEnabled, e) end
function Button:setChecked(c) return record(self, Api.Button.SetChecked, c) end
function Button:isChecked() return Api.Button.IsChecked(self.name) end
function Button:setTexture(...) return record(self, Api.Button.SetTexture, ...) end
function Button:setHighlight(h) return record(self, Api.Button.SetHighlight, h) end
function Button:setStayDown(s) return record(self, Api.Button.SetStayDown, s) end
function Button:isStayDown() return Api.Button.IsStayDown(self.name) end

-- -------------------------------------------------------------------------- --
-- DynamicImage
-- -------------------------------------------------------------------------- --

local DynamicImage = inheritWindow({})
function UI.DynamicImage(name)
    return setmetatable({ name = name, _ops = name and nil or {} }, DynamicImage)
end

function DynamicImage:setTexture(...) return record(self, Api.DynamicImage.SetTexture, ...) end
function DynamicImage:hasTexture() return Api.DynamicImage.HasTexture(self.name) end
function DynamicImage:setTextureScale(s) return record(self, Api.DynamicImage.SetTextureScale, s) end
function DynamicImage:setTextureDimensions(w, h) return record(self, Api.DynamicImage.SetTextureDimensions, w, h) end
function DynamicImage:setTextureOrientation(o) return record(self, Api.DynamicImage.SetTextureOrientation, o) end
function DynamicImage:setTextureSlice(s) return record(self, Api.DynamicImage.SetTextureSlice, s) end
function DynamicImage:setRotation(r) return record(self, Api.DynamicImage.SetRotation, r) end
function DynamicImage:setCustomShader(...) return record(self, Api.DynamicImage.SetCustomShader, ...) end

-- -------------------------------------------------------------------------- --
-- EditBox (engine namespace: EditTextBox)
-- -------------------------------------------------------------------------- --

local EditBox = inheritWindow({})
function UI.EditBox(name)
    return setmetatable({ name = name, _ops = name and nil or {} }, EditBox)
end

function EditBox:setText(t) return record(self, Api.EditTextBox.SetText, t) end
function EditBox:getText() return Api.EditTextBox.GetText(self.name) end
function EditBox:getTextLines() return Api.EditTextBox.GetTextLines(self.name) end
function EditBox:insertText(t) return record(self, Api.EditTextBox.InsertText, t) end
function EditBox:clear() return record(self, Api.EditTextBox.Clear) end
function EditBox:setTextColor(r, g, b) return record(self, Api.EditTextBox.SetTextColor, r, g, b) end
function EditBox:getTextColor() return Api.EditTextBox.GetTextColor(self.name) end
function EditBox:selectAll() return record(self, Api.EditTextBox.SelectAll) end
function EditBox:setFont(fontName, lineSpacing) return record(self, Api.EditTextBox.SetFont, fontName, lineSpacing) end
function EditBox:getFont() return Api.EditTextBox.GetFont(self.name) end
function EditBox:getHistory() return Api.EditTextBox.GetHistory(self.name) end
function EditBox:setHistory(h) return record(self, Api.EditTextBox.SetHistory, h) end
function EditBox:handleKeyDown(...) return Api.EditTextBox.HandleKeyDown(self.name, ...) end

-- -------------------------------------------------------------------------- --
-- TextLog
-- -------------------------------------------------------------------------- --

local TextLog = inheritWindow({})
function UI.TextLog(name)
    return setmetatable({ name = name, _ops = name and nil or {} }, TextLog)
end

function TextLog:create(...) return record(self, Api.TextLog.Create, ...) end
function TextLog:destroyLog() return record(self, Api.TextLog.Destroy) end
function TextLog:addFilterType(...) return record(self, Api.TextLog.AddFilterType, ...) end
function TextLog:setEnabled(e) return record(self, Api.TextLog.SetEnabled, e) end
function TextLog:isEnabled() return Api.TextLog.IsEnabled(self.name) end
function TextLog:clearLog() return record(self, Api.TextLog.Clear) end
function TextLog:setIncrementalSaving(doSave, path) return record(self, Api.TextLog.SetIncrementalSaving, doSave, path) end
function TextLog:getNumEntries() return Api.TextLog.GetNumEntries(self.name) end
function TextLog:getEntry(i) return Api.TextLog.GetEntry(self.name, i) end
function TextLog:addEntry(...) return record(self, Api.TextLog.AddEntry, ...) end
function TextLog:getUpdateEventId() return Api.TextLog.GetUpdateEventId(self.name) end

-- ========================================================================== --
-- Expose
-- ========================================================================== --
Mongbat.UI = UI
