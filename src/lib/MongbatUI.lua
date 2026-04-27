---@diagnostic disable: undefined-global
-- ========================================================================== --
-- MongbatUI: Object-oriented widget wrappers
-- ========================================================================== --
--
-- Thin OO facade over the procedural `Mongbat.Api.*` namespace. Wraps an
-- existing engine window by name; does NOT create or destroy windows
-- (use Mongbat.CreateWindow / Mongbat.DestroyWindow for that).
--
-- Pattern: wrap-by-name + fluent setters.
--
--     local lbl = Mongbat.UI.Label("MyMod_NameLabel")
--     lbl:setText("Hello"):setTextColor(0xFFFFFF)
--     local txt = lbl:getText()
--
-- All widget classes inherit basic Window methods (setShowing, setDimensions,
-- setColor, anchors, etc.) via metatable chaining off `Window`.
-- ========================================================================== --

local UI = {}
local Api = Mongbat.Api

-- -------------------------------------------------------------------------- --
-- Window (base class for all widgets)
-- -------------------------------------------------------------------------- --

local Window = {}
Window.__index = Window

function UI.Window(name)
    return setmetatable({ name = name }, Window)
end

-- Identity / lifecycle
function Window:getName() return self.name end
function Window:exists() return Api.Window.DoesExist(self.name) end
function Window:destroy() Mongbat.DestroyWindow(self.name) end

-- Visibility / focus
function Window:setShowing(s) Api.Window.SetShowing(self.name, s); return self end
function Window:isShowing() return Api.Window.IsShowing(self.name) end
function Window:show() Api.Window.SetShowing(self.name, true); return self end
function Window:hide() Api.Window.SetShowing(self.name, false); return self end
function Window:assignFocus(f) Api.Window.AssignFocus(self.name, f); return self end
function Window:hasFocus() return Api.Window.HasFocus(self.name) end

-- Geometry (note: GetDimensions returns { x, y } table per engine convention)
function Window:setDimensions(w, h) Api.Window.SetDimensions(self.name, w, h); return self end
function Window:getDimensions() return Api.Window.GetDimensions(self.name) end
function Window:setPosition(x, y) Api.Window.SetPosition(self.name, x, y); return self end
function Window:getPosition() return Api.Window.GetPosition(self.name) end
function Window:setScale(s) Api.Window.SetScale(self.name, s); return self end
function Window:getScale() return Api.Window.GetScale(self.name) end

-- Appearance
function Window:setColor(c) Api.Window.SetColor(self.name, c); return self end
function Window:getColor() return Api.Window.GetColor(self.name) end
function Window:setAlpha(a) Api.Window.SetAlpha(self.name, a); return self end
function Window:getAlpha() return Api.Window.GetAlpha(self.name) end

-- Identity / layering
function Window:setId(id) Api.Window.SetId(self.name, id); return self end
function Window:getId() return Api.Window.GetId(self.name) end
function Window:setLayer(l) Api.Window.SetLayer(self.name, l); return self end
function Window:getLayer() return Api.Window.GetLayer(self.name) end

-- Movement
function Window:setMoving(m) Api.Window.SetMoving(self.name, m); return self end
function Window:isMoving() return Api.Window.IsMoving(self.name) end

-- Anchors / parent
function Window:clearAnchors() Api.Window.ClearAnchors(self.name); return self end
function Window:addAnchor(point, rel, relPoint, x, y)
    Api.Window.AddAnchor(self.name, point, rel, relPoint, x, y); return self
end
function Window:setParent(p) Api.Window.SetParent(self.name, p); return self end
function Window:getParent() return Api.Window.GetParent(self.name) end
function Window:setOffsetFromParent(x, y) Api.Window.SetOffsetFromParent(self.name, x, y); return self end
function Window:getOffsetFromParent() return Api.Window.GetOffsetFromParent(self.name) end

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
function UI.Label(name) return setmetatable({ name = name }, Label) end

function Label:setText(t) Api.Label.SetText(self.name, t); return self end
function Label:getText() return Api.Label.GetText(self.name) end
function Label:setTextColor(c) Api.Label.SetTextColor(self.name, c); return self end
function Label:setTextAlignment(a) Api.Label.SetTextAlignment(self.name, a); return self end
function Label:setWordWrap(w) Api.Label.SetWordWrap(self.name, w); return self end

-- -------------------------------------------------------------------------- --
-- Button
-- -------------------------------------------------------------------------- --

local Button = inheritWindow({})
function UI.Button(name) return setmetatable({ name = name }, Button) end

function Button:setText(t) Api.Button.SetText(self.name, t); return self end
function Button:getText() return Api.Button.GetText(self.name) end
function Button:setTextColor(r, g, b, a) Api.Button.SetTextColor(self.name, r, g, b, a); return self end
function Button:getTextDimensions() return Api.Button.GetTextDimensions(self.name) end
function Button:setDisabled(d) Api.Button.SetDisabled(self.name, d); return self end
function Button:isDisabled() return Api.Button.IsDisabled(self.name) end
function Button:setEnabled(e) Api.Button.SetEnabled(self.name, e); return self end
function Button:setChecked(c) Api.Button.SetChecked(self.name, c); return self end
function Button:isChecked() return Api.Button.IsChecked(self.name) end
function Button:setTexture(...) Api.Button.SetTexture(self.name, ...); return self end
function Button:setHighlight(h) Api.Button.SetHighlight(self.name, h); return self end
function Button:setStayDown(s) Api.Button.SetStayDown(self.name, s); return self end
function Button:isStayDown() return Api.Button.IsStayDown(self.name) end

-- -------------------------------------------------------------------------- --
-- DynamicImage
-- -------------------------------------------------------------------------- --

local DynamicImage = inheritWindow({})
function UI.DynamicImage(name) return setmetatable({ name = name }, DynamicImage) end

function DynamicImage:setTexture(...) Api.DynamicImage.SetTexture(self.name, ...); return self end
function DynamicImage:hasTexture() return Api.DynamicImage.HasTexture(self.name) end
function DynamicImage:setTextureScale(s) Api.DynamicImage.SetTextureScale(self.name, s); return self end
function DynamicImage:setTextureDimensions(w, h) Api.DynamicImage.SetTextureDimensions(self.name, w, h); return self end
function DynamicImage:setTextureOrientation(o) Api.DynamicImage.SetTextureOrientation(self.name, o); return self end
function DynamicImage:setTextureSlice(s) Api.DynamicImage.SetTextureSlice(self.name, s); return self end
function DynamicImage:setRotation(r) Api.DynamicImage.SetRotation(self.name, r); return self end
function DynamicImage:setCustomShader(...) Api.DynamicImage.SetCustomShader(self.name, ...); return self end

-- -------------------------------------------------------------------------- --
-- EditBox (engine namespace: EditTextBox)
-- -------------------------------------------------------------------------- --

local EditBox = inheritWindow({})
function UI.EditBox(name) return setmetatable({ name = name }, EditBox) end

function EditBox:setText(t) Api.EditTextBox.SetText(self.name, t); return self end
function EditBox:getText() return Api.EditTextBox.GetText(self.name) end
function EditBox:getTextLines() return Api.EditTextBox.GetTextLines(self.name) end
function EditBox:insertText(t) Api.EditTextBox.InsertText(self.name, t); return self end
function EditBox:clear() Api.EditTextBox.Clear(self.name); return self end
function EditBox:setTextColor(r, g, b) Api.EditTextBox.SetTextColor(self.name, r, g, b); return self end
function EditBox:getTextColor() return Api.EditTextBox.GetTextColor(self.name) end
function EditBox:selectAll() Api.EditTextBox.SelectAll(self.name); return self end
function EditBox:setFont(fontName, lineSpacing) Api.EditTextBox.SetFont(self.name, fontName, lineSpacing); return self end
function EditBox:getFont() return Api.EditTextBox.GetFont(self.name) end
function EditBox:getHistory() return Api.EditTextBox.GetHistory(self.name) end
function EditBox:setHistory(h) Api.EditTextBox.SetHistory(self.name, h); return self end
function EditBox:handleKeyDown(...) return Api.EditTextBox.HandleKeyDown(self.name, ...) end

-- -------------------------------------------------------------------------- --
-- TextLog
-- -------------------------------------------------------------------------- --

local TextLog = inheritWindow({})
function UI.TextLog(name) return setmetatable({ name = name }, TextLog) end

function TextLog:create(...) Api.TextLog.Create(self.name, ...); return self end
function TextLog:destroyLog() Api.TextLog.Destroy(self.name); return self end
function TextLog:addFilterType(...) Api.TextLog.AddFilterType(self.name, ...); return self end
function TextLog:setEnabled(e) Api.TextLog.SetEnabled(self.name, e); return self end
function TextLog:isEnabled() return Api.TextLog.IsEnabled(self.name) end
function TextLog:clear() Api.TextLog.Clear(self.name); return self end
function TextLog:setIncrementalSaving(doSave, path) Api.TextLog.SetIncrementalSaving(self.name, doSave, path); return self end
function TextLog:getNumEntries() return Api.TextLog.GetNumEntries(self.name) end
function TextLog:getEntry(i) return Api.TextLog.GetEntry(self.name, i) end
function TextLog:addEntry(...) Api.TextLog.AddEntry(self.name, ...); return self end
function TextLog:getUpdateEventId() return Api.TextLog.GetUpdateEventId(self.name) end

-- -------------------------------------------------------------------------- --
-- StatusBar (composite: container window + fill DynamicImage + optional label)
-- -------------------------------------------------------------------------- --
--
-- Wraps an EXISTING composite (does not create the children). Pass the names
-- of the three child windows the mod has already created via Mongbat.CreateWindow:
--
--     local hpBar = Mongbat.UI.StatusBar {
--         container = "MyMod_HpBar",
--         fill      = "MyMod_HpBarFill",
--         label     = "MyMod_HpBarLabel",   -- optional
--     }
--     hpBar:setValue(currentHp, maxHp, 0xFF0000)
--     hpBar:setLabel(string.format("%d / %d", currentHp, maxHp))
--
-- The container name is the StatusBar's `.name`, so it inherits all Window
-- methods (setShowing, setDimensions, anchors, etc.).
-- -------------------------------------------------------------------------- --

local StatusBar = inheritWindow({})

function UI.StatusBar(opts)
    assert(type(opts) == "table" and opts.container and opts.fill,
        "Mongbat.UI.StatusBar requires { container, fill, label? }")
    return setmetatable({
        name      = opts.container,
        container = opts.container,
        fill      = opts.fill,
        label     = opts.label,
    }, StatusBar)
end

-- Set the fill ratio. `current`/`max` clamp to [0,1]; the fill DynamicImage
-- is resized to that fraction of the container's width. If `color` is given,
-- the fill is tinted; pass nil to leave the existing color alone.
function StatusBar:setValue(current, max, color)
    local dims = Api.Window.GetDimensions(self.container)
    local w = dims and dims.x or 0
    local h = dims and dims.y or 0
    local ratio = 0
    if max and max > 0 then
        ratio = current / max
        if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
    end
    Api.Window.SetDimensions(self.fill, math.floor(w * ratio + 0.5), h)
    if color ~= nil then
        Api.Window.SetColor(self.fill, color)
    end
    return self
end

-- Set the label text (no-op if the bar was constructed without a `label`).
function StatusBar:setLabel(text)
    if self.label then
        Api.Label.SetText(self.label, text)
    end
    return self
end

function StatusBar:setLabelColor(c)
    if self.label then
        Api.Label.SetTextColor(self.label, c)
    end
    return self
end

-- Override: showing/hiding the bar shows/hides all child windows together.
function StatusBar:setShowing(s)
    Api.Window.SetShowing(self.container, s)
    Api.Window.SetShowing(self.fill, s)
    if self.label then Api.Window.SetShowing(self.label, s) end
    return self
end

-- ========================================================================== --
-- Expose
-- ========================================================================== --
Mongbat.UI = UI
