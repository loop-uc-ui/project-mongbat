-- Replaces the default MainMenuWindow with a Mongbat-styled vertical button
-- stack. The engine still toggles "MainMenuWindow" via the Escape key; we
-- override the engine name with `name = NAME` and `replacesDefault = true`
-- so the lib destroys the default UI's window once before recreating ours.
--
-- Pattern: declarative. M.Build(emit) runs every frame. The lib diffs the
-- emitted window set vs prior frame and creates / updates / destroys engine
-- windows accordingly. Mods route engine click events on `key`.

local UI    = Mongbat.UI
local Api   = Mongbat.Api
local Utils = Mongbat.Utils

local NAME = "MainMenuWindow"

-- Vertical layout constants matched to MongbatWindow padding / button size.
local PAD_X       = 17
local PAD_Y       = 17
local BTN_W       = 180
local BTN_H       = 40
local BTN_SPACING = 4

local M = {}

local function close()
    Api.Window.SetShowing(NAME, false)
end

-- Buttons in display order. `text` may be a string or a numeric clilocId.
local BUTTONS = {
    { key = "logout",   text = 3000128,  click = function() Api.Event.Logout() end },
    { key = "exit",     text = 1077859,  click = function() Api.Event.ExitGame() end },
    { key = "settings", text = "Settings",
                         click = function() Api.Window.ToggleWindow("SettingsWindow"); close() end },
    { key = "store",    text = "Store",
                         click = function() Api.Event.OpenStore(); close() end },
    { key = "agents",   text = "Agents",
                         click = function() Api.Window.ToggleWindow("OrganizerWindow"); close() end },
    { key = "macros",   text = 3000172,
                         click = function() Api.Window.ToggleWindow("MacroWindow"); close() end },
    { key = "actions",  text = 1079812,
                         click = function() Api.Window.ToggleWindow("ActionsWindow"); close() end },
    { key = "mods",     text = 1061037,
                         click = function() --[[ TODO: open mod manager ]] end },
    { key = "debug",    text = "Debug",
                         click = function() Api.Window.ToggleWindow("MongbatDebugWindow"); close() end },
}

function M.Build(emit)
    emit("menu", {
        name            = NAME,
        template        = "MongbatWindow",
        replacesDefault = true,
        draggable       = true,
        showing         = false,
        widget          = UI.Window():setDimensions(
            BTN_W + 2 * PAD_X,
            BTN_H * #BUTTONS + (#BUTTONS - 1) * BTN_SPACING + 2 * PAD_Y),
    })

    Utils.Array.ForEach(BUTTONS, function(b, i)
        emit(b.key, {
            template = "MongbatButton",
            parent   = "menu",
            widget   = UI.Button()
                :setDimensions(BTN_W, BTN_H)
                :setOffsetFromParent(PAD_X, PAD_Y + (i - 1) * (BTN_H + BTN_SPACING))
                :setText(b.text),
        })
    end)
end

function M.OnLButtonUp(window)
    if window.key == "menu" then return end
    local hit = Utils.Array.Find(BUTTONS, function(b) return b.key == window.key end)
    if hit then hit.click() end
end

function M.OnRButtonUp(window)
    if window.key == "menu" then close() end
end

Mongbat.Mod {
    Name   = "MongbatMainMenu",
    Path   = "/src/mods/mongbat-main-menu",
    Module = M,
}
