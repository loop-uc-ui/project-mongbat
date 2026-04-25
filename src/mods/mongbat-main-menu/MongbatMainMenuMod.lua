-- Replaces the default MainMenuWindow with a Mongbat-styled vertical button
-- stack. The engine still toggles "MainMenuWindow" via the Escape key; the
-- engine''s WindowSetShowing hits our top-level window because we recreate
-- it under the same name during OnLoad.
--
-- Pattern: Mongbat is a router. The mod registers its main window plus one
-- child window per button, each with a unique key. M.OnLButtonUp dispatches
-- on key.

local Api       = Mongbat.Api
local Utils     = Mongbat.Utils

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

-- Buttons in display order. `text` may be a string or a numeric clilocId;
-- Utils.String.ToWString normalises both into a wstring for the engine.
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

local function buttonName(key)
    return NAME .. "Button" .. key
end

function M.OnLoad()
    -- Destroy the default UI's MainMenuWindow before recreating it under the
    -- same name; the engine still toggles "MainMenuWindow" on Escape.
    Api.Window.Destroy(NAME)
    -- Outer window. Key "menu" so OnRButtonUp/OnShown/OnHidden can be
    -- distinguished from button events.
    Mongbat.CreateWindow {
        name     = NAME,
        template = "MongbatWindow",
        module   = M,
        key      = "menu",
        showing  = false,
    }
    Api.Window.SetDimensions(NAME,
        BTN_W + 2 * PAD_X,
        BTN_H * #BUTTONS + (#BUTTONS - 1) * BTN_SPACING + 2 * PAD_Y)

    Utils.Array.ForEach(BUTTONS, function(b, i)
        local n = buttonName(b.key)
        Mongbat.CreateWindow {
            name     = n,
            template = "MongbatButton",
            parent   = NAME,
            module   = M,
            key      = b.key,
        }
        Api.Window.SetDimensions(n, BTN_W, BTN_H)
        Api.Window.SetOffsetFromParent(n, PAD_X, PAD_Y + (i - 1) * (BTN_H + BTN_SPACING))
        Api.Button.SetText(n, b.text)
    end)
end

function M.OnUnload()
    Utils.Array.ForEach(BUTTONS, function(b)
        Mongbat.DestroyWindow(buttonName(b.key))
    end)
    Mongbat.DestroyWindow(NAME)
end

function M.OnLButtonUp(_name, key)
    if key == "menu" then return end
    local hit = Utils.Array.Find(BUTTONS, function(b) return b.key == key end)
    if hit then hit.click() end
end

function M.OnRButtonUp(_name, key)
    if key == "menu" then close() end
end

Mongbat.Mod {
    Name   = "MongbatMainMenu",
    Path   = "/src/mods/mongbat-main-menu",
    Module = M,
}
