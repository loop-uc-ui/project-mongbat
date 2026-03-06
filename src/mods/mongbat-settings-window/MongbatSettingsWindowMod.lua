local NAME = "SettingsWindow"

-- ========================================================================== --
-- Layout constants
-- ========================================================================== --

local WIDTH        = 750
local HEIGHT       = 540
local MARGIN       = 8
local TAB_H        = 28
local ROW_H        = 32
local ROW_GAP      = 2
local ACTION_H     = 34
local NUM_TABS     = 11

local TAB_W        = math.floor((WIDTH - MARGIN * 2) / NUM_TABS)
local CONTENT_TOP  = MARGIN + TAB_H + MARGIN
local CONTENT_H    = HEIGHT - CONTENT_TOP - MARGIN - ACTION_H - MARGIN
local CONTENT_W    = WIDTH - MARGIN * 2
local ACTION_BTN_W = 82

local TAB_LABELS = {
    L"Graphics",
    L"Sound",
    L"Options",
    L"Key Bindings",
    L"Legacy",
    L"Profanity",
    L"Key Default",
    L"Overhead",
    L"Containers",
    L"Healthbars",
    L"Mobiles",
}

-- Key binding definitions (display name + action type string)
local KEYBINDINGS = {
    { name = L"Move Up",           atype = "FORWARD" },
    { name = L"Move Down",         atype = "BACKWARD" },
    { name = L"Move Left",         atype = "LEFT" },
    { name = L"Move Right",        atype = "RIGHT" },
    { name = L"Attack Mode",       atype = "MELEE_ATTACK" },
    { name = L"Primary Attack",    atype = "USE_PRIMARY_ATTACK" },
    { name = L"Secondary Attack",  atype = "USE_SECONDARY_ATTACK" },
    { name = L"Next Enemy",        atype = "NEXT_ENEMY_TARGET" },
    { name = L"Next Friend",       atype = "NEXT_FRIENDLY_TARGET" },
    { name = L"Nearest Enemy",     atype = "NEAREST_ENEMY_TARGET" },
    { name = L"Nearest Friend",    atype = "NEAREST_FRIENDLY_TARGET" },
    { name = L"Target Self",       atype = "TARGET_SELF" },
    { name = L"Target Group 1",    atype = "TARGET_GROUP_MEMBER_1" },
    { name = L"Target Group 2",    atype = "TARGET_GROUP_MEMBER_2" },
    { name = L"Target Group 3",    atype = "TARGET_GROUP_MEMBER_3" },
    { name = L"Paperdoll",         atype = "PAPERDOLL_CHARACTER_WINDOW" },
    { name = L"Backpack",          atype = "BACKPACK_WINDOW" },
    { name = L"Skills",            atype = "SKILLS_WINDOW" },
    { name = L"World Map",         atype = "WORLD_MAP_WINDOW" },
    { name = L"Toggle Run",        atype = "TOGGLE_ALWAYS_RUN" },
    { name = L"Zoom In",           atype = "ZOOM_IN" },
    { name = L"Zoom Out",          atype = "ZOOM_OUT" },
    { name = L"Zoom Reset",        atype = "ZOOM_RESET" },
    { name = L"Screenshot",        atype = "SCREENSHOT" },
    { name = L"Toggle UI",         atype = "TOGGLE_UI" },
    { name = L"Log Out",           atype = "LOG_OUT" },
}

-- Show-names combo options (index 1-3 stored in pending.showNamesIdx)
local SHOWNAMES_LABELS = { L"None", L"Approaching", L"All" }

-- Framerate combo options (index stored in pending.framerateIdx)
local FPS_LABELS = { L"20", L"30", L"40", L"50", L"60", L"70", L"80", L"100", L"120", L"150", L"200" }
local FPS_VALUES = { 20,   30,   40,   50,   60,   70,   80,   100,   120,   150,   200 }

-- Overhead chat fade options (index 1-5 stored in pending.overheadChatFade as 1-5)
local FADE_LABELS = { L"1s", L"2s", L"3s", L"4s", L"5s" }

-- ========================================================================== --
-- OnInitialize
-- ========================================================================== --

---@param context Context
local function OnInitialize(context)
    local Api        = context.Api
    local Components = context.Components
    local Constants  = context.Constants
    local Utils      = context.Utils

    -- SHOWNAMES engine integer values: populated once from engine constants.
    local SHOWNAMES_IDS = {}

    -- Snapshot SHOWNAMES constants via framework wrappers
    SHOWNAMES_IDS[1] = Constants.Settings.ShowNames.None()
    SHOWNAMES_IDS[2] = Constants.Settings.ShowNames.Approaching()
    SHOWNAMES_IDS[3] = Constants.Settings.ShowNames.All()

    -- Disable the default settings window and destroy the existing XML window
    local settingsDefault = Components.Defaults.SettingsWindow
    settingsDefault:disable()
    settingsDefault:asComponent():destroy()

    -- ======================================================================
    -- Pending settings
    --   Sliders with float system values are stored as integer × 100 to avoid
    --   floating-point drift during increment/decrement.
    --   Combo values use 1-based index keys (e.g. showNamesIdx, framerateIdx).
    -- ======================================================================
    local pending = {}

    -- Pending key binding changes: atype -> newValue wstring
    local pendingBindings = {}

    -- Index of the keybinding currently being recorded (nil = none)
    local recordingIndex = nil

    -- Control references for refreshAll()
    local checkboxRefs = {}   -- { view = Button, key = string }
    local sliderRefs   = {}   -- { label = Label, key = string, fmt = fun }
    local comboRefs    = {}   -- { label = Label, key = string, getLabel = fun }
    local bindingRefs  = {}   -- { label = Label, index = int }

    -- -----------------------------------------------------------------------
    -- loadSettings(): snapshot Data.Settings() -> pending, then refresh
    -- -----------------------------------------------------------------------
    local function loadSettings()
        local s = context.Data.Settings()
        -- Graphics (gamma stored as integer 0-200 = float×100)
        pending.useFullScreen   = s:getUseFullScreen()
        pending.gamma           = math.floor(s:getGamma() * 100 + 0.5)
        pending.showShadows     = s:getShowShadows()
        pending.enableVSync     = s:getEnableVSync()
        pending.showWindowFrame = s:getShowWindowFrame()
        pending.displayFoliage  = s:getDisplayFoliage()
        pending.circleOfTrans   = s:getCircleOfTrans()
        pending.idleAnimation   = s:getIdleAnimation()
        pending.framerateMax    = s:getFramerateMax()
        local framerateMax      = pending.framerateMax
        pending.framerateIdx    = Utils.Array.IndexOfOrDefault(FPS_VALUES, function(v) return v == framerateMax end, 1)

        -- Sound
        pending.masterEnabled   = s:getMasterEnabled()
        pending.masterVolume    = s:getMasterVolume()
        pending.effectsEnabled  = s:getEffectsEnabled()
        pending.effectsVolume   = s:getEffectsVolume()
        pending.musicEnabled    = s:getMusicEnabled()
        pending.musicVolume     = s:getMusicVolume()
        pending.footsteps       = s:getFootsteps()

        -- Options
        pending.alwaysRun            = s:getAlwaysRun()
        pending.enableAutorun        = s:getEnableAutorun()
        pending.enablePathfinding    = s:getEnablePathfinding()
        pending.queryBeforeCriminal  = s:getQueryBeforeCriminal()
        pending.ignoreMouseOnSelf    = s:getIgnoreMouseOnSelf()
        pending.holdShiftToUnstack   = s:getHoldShiftToUnstack()
        pending.shiftRightClick      = s:getShiftRightClick()
        pending.targetQueueing       = s:getTargetQueueing()
        pending.alwaysAttack         = s:getAlwaysAttack()
        pending.showCorpseNames      = s:getShowCorpseNames()
        pending.showTooltips         = s:getShowTooltips()
        pending.overheadChat         = s:getOverheadChat()
        pending.enableChatLog        = s:getEnableChatLog()
        pending.noWarOnPets          = s:getNoWarOnPets()
        pending.noWarOnParty         = s:getNoWarOnParty()

        -- Legacy
        pending.legacyContainers = s:getLegacyContainers()
        pending.legacyPaperdolls = s:getLegacyPaperdolls()
        pending.legacyChat       = s:getLegacyChat()
        pending.legacyTargeting  = s:getLegacyTargeting()

        -- Profanity
        pending.badWordFilter    = s:getBadWordFilter()
        pending.ignoreListFilter = s:getIgnoreListFilter()
        pending.ignoreConfFilter = s:getIgnoreConfFilter()

        -- Overhead Text (fade delay index 1-5)
        local fadeDelay = s:getOverheadChatFadeDelay() or 1
        if fadeDelay < 1 then fadeDelay = 1 end
        if fadeDelay > 5 then fadeDelay = 5 end
        pending.overheadChatFade = fadeDelay
        pending.partyInvitePopUp = s:getPartyInvitePopUp()

        -- Containers
        pending.showStrLabel = s:getShowStrLabel()

        -- Healthbars (UI scale stored as integer 50-150 = float×100)
        local rawScale = s:getCustomUiScale() or 1.0
        pending.uiScale = math.floor(rawScale * 100 + 0.5)

        -- Mobiles on Screen (show names, stored as 1-based index)
        local showNames = s:getShowNames() or SHOWNAMES_IDS[1]
        pending.showNamesIdx = Utils.Array.IndexOfOrDefault(SHOWNAMES_IDS, function(v) return v == showNames end, 1)

        -- Reset pending bindings
        pendingBindings = {}
    end

    -- -----------------------------------------------------------------------
    -- applySettings(): write pending -> Data.Settings(), call engine
    -- -----------------------------------------------------------------------
    local function applySettings()
        local s = context.Data.Settings()
        -- Graphics
        s:setUseFullScreen(pending.useFullScreen)
        s:setGamma(pending.gamma / 100)
        s:setShowShadows(pending.showShadows)
        s:setEnableVSync(pending.enableVSync)
        s:setShowWindowFrame(pending.showWindowFrame)
        s:setDisplayFoliage(pending.displayFoliage)
        s:setCircleOfTrans(pending.circleOfTrans)
        s:setIdleAnimation(pending.idleAnimation)
        s:setFramerateMax(FPS_VALUES[pending.framerateIdx])

        -- Sound
        s:setMasterEnabled(pending.masterEnabled)
        s:setMasterVolume(pending.masterVolume)
        s:setEffectsEnabled(pending.effectsEnabled)
        s:setEffectsVolume(pending.effectsVolume)
        s:setMusicEnabled(pending.musicEnabled)
        s:setMusicVolume(pending.musicVolume)
        s:setFootsteps(pending.footsteps)

        -- Options
        s:setAlwaysRun(pending.alwaysRun)
        s:setEnableAutorun(pending.enableAutorun)
        s:setEnablePathfinding(pending.enablePathfinding)
        s:setQueryBeforeCriminal(pending.queryBeforeCriminal)
        s:setIgnoreMouseOnSelf(pending.ignoreMouseOnSelf)
        s:setHoldShiftToUnstack(pending.holdShiftToUnstack)
        s:setShiftRightClick(pending.shiftRightClick)
        s:setTargetQueueing(pending.targetQueueing)
        s:setAlwaysAttack(pending.alwaysAttack)
        s:setShowCorpseNames(pending.showCorpseNames)
        s:setShowTooltips(pending.showTooltips)
        s:setOverheadChat(pending.overheadChat)
        s:setEnableChatLog(pending.enableChatLog)
        s:setNoWarOnPets(pending.noWarOnPets)
        s:setNoWarOnParty(pending.noWarOnParty)

        -- Legacy
        s:setLegacyContainers(pending.legacyContainers)
        s:setLegacyPaperdolls(pending.legacyPaperdolls)
        s:setLegacyChat(pending.legacyChat)
        s:setLegacyTargeting(pending.legacyTargeting)

        -- Profanity
        s:setBadWordFilter(pending.badWordFilter)
        s:setIgnoreListFilter(pending.ignoreListFilter)
        s:setIgnoreConfFilter(pending.ignoreConfFilter)

        -- Overhead Text
        s:setOverheadChatFadeDelay(pending.overheadChatFade)
        s:setPartyInvitePopUp(pending.partyInvitePopUp)

        -- Containers
        s:setShowStrLabel(pending.showStrLabel)

        -- Healthbars / UI Scale
        s:setCustomUiScale(pending.uiScale / 100)

        -- Mobiles
        s:setShowNames(SHOWNAMES_IDS[pending.showNamesIdx])

        -- Key bindings
        Utils.Table.ForEach(pendingBindings, function(atype, key)
            Api.Settings.SetKeybinding(atype, key)
        end)
        pendingBindings = {}

        Api.Settings.UserSettingsChanged()
    end

    -- -----------------------------------------------------------------------
    -- refreshAll(): push pending values into control views
    -- -----------------------------------------------------------------------
    local function refreshAll()
        Utils.Array.ForEach(checkboxRefs, function(c)
            if c.view then c.view:setChecked(pending[c.key]) end
        end)
        Utils.Array.ForEach(sliderRefs, function(c)
            if c.label then c.label:setText(c.fmt(pending[c.key])) end
        end)
        Utils.Array.ForEach(comboRefs, function(c)
            if c.label then c.label:setText(c.getLabel(pending[c.key])) end
        end)
        Utils.Array.ForEach(bindingRefs, function(c)
            if c.label then
                local b = pendingBindings[KEYBINDINGS[c.index].atype] or Api.Settings.GetKeybinding(KEYBINDINGS[c.index].atype)
                c.label:setText(b)
            end
        end)
    end

    -- ======================================================================
    -- Display formatters
    -- ======================================================================

    local function fmtPercent(v)
        return towstring(v) .. L"%"
    end

    local function fmtDecimal(v)
        -- Format integer/100 as "X.XX"
        local whole = math.floor(v / 100)
        local frac  = v - whole * 100
        if frac < 0 then frac = -frac end
        if frac < 10 then
            return towstring(whole) .. L".0" .. towstring(frac)
        end
        return towstring(whole) .. L"." .. towstring(frac)
    end

    -- ======================================================================
    -- Layout helpers
    -- ======================================================================

    local function NoOpLayout() end

    -- Stack rows vertically with a fixed per-row height.
    local function StackRows(window, children, child, index)
        local y = (index - 1) * (ROW_H + ROW_GAP)
        child:clearAnchors()
        child:addAnchor("topleft", window:getName(), "topleft", 0, y)
    end

    -- ======================================================================
    -- Control row factories
    -- ======================================================================

    -- Checkbox row: [label text ................... [X]]
    local function Checkbox(labelText, key)
        local btn
        local ctrl = { key = key }
        checkboxRefs[#checkboxRefs + 1] = ctrl

        return Components.Window {
            Resizable = false,
            OnLayout  = NoOpLayout,
            OnInitialize = function(self)
                local parent = self:getName()
                self:setDimensions(CONTENT_W, ROW_H)
                btn = Components.Button {
                    Template = "MongbatButton18",
                    OnInitialize = function(s)
                        s:setCheckButton(true)
                        s:setChecked(pending[key])
                        s:setDimensions(ROW_H, ROW_H)
                        s:addAnchor("topright", parent, "topright", -MARGIN, 0)
                    end,
                    OnLButtonUp = function(s)
                        pending[key] = not pending[key]
                        s:setChecked(pending[key])
                    end,
                }
                ctrl.view = btn
                self:setChildren({
                    Components.Label {
                        OnInitialize = function(s)
                            s:setText(labelText)
                            s:setDimensions(CONTENT_W - ROW_H - MARGIN * 2, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", MARGIN, 4)
                        end,
                    },
                    btn,
                })
            end,
        }
    end

    -- Slider row: [label .....] [-] [value] [+]
    -- pending[key] is always an integer matching the display units.
    local function SliderRow(labelText, key, minVal, maxVal, step, fmtFn)
        local valLabel
        local ctrl = { key = key, fmt = fmtFn }
        sliderRefs[#sliderRefs + 1] = ctrl

        return Components.Window {
            Resizable = false,
            OnLayout  = NoOpLayout,
            OnInitialize = function(self)
                local parent = self:getName()
                local labelW = math.floor(CONTENT_W * 0.55)
                local btnW   = ROW_H
                local valW   = 60
                local ctrlX  = labelW + MARGIN
                self:setDimensions(CONTENT_W, ROW_H)

                valLabel = Components.Label {
                    OnInitialize = function(s)
                        s:setText(fmtFn(pending[key]))
                        s:setDimensions(valW, ROW_H)
                        s:centerText()
                        s:addAnchor("topleft", parent, "topleft", ctrlX + btnW, 4)
                    end,
                }
                ctrl.label = valLabel

                local function clamp(v)
                    if v < minVal then return minVal end
                    if v > maxVal then return maxVal end
                    return v
                end

                self:setChildren({
                    Components.Label {
                        OnInitialize = function(s)
                            s:setText(labelText)
                            s:setDimensions(labelW, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", MARGIN, 4)
                        end,
                    },
                    Components.Button {
                        Template = "MongbatButton18",
                        OnInitialize = function(s)
                            s:setText(L"-")
                            s:setDimensions(btnW, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", ctrlX, 0)
                        end,
                        OnLButtonUp = function()
                            local v = clamp(pending[key] - step)
                            pending[key] = v
                            if valLabel then valLabel:setText(fmtFn(v)) end
                        end,
                    },
                    valLabel,
                    Components.Button {
                        Template = "MongbatButton18",
                        OnInitialize = function(s)
                            s:setText(L"+")
                            s:setDimensions(btnW, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", ctrlX + btnW + valW, 0)
                        end,
                        OnLButtonUp = function()
                            local v = clamp(pending[key] + step)
                            pending[key] = v
                            if valLabel then valLabel:setText(fmtFn(v)) end
                        end,
                    },
                })
            end,
        }
    end

    -- Combo row: [label ........] [<] [current] [>]
    -- pending[key] is a 1-based index into options.
    local function ComboRow(labelText, key, options, getLabelFn)
        local valLabel
        local n    = #options
        local ctrl = { key = key, getLabel = getLabelFn }
        comboRefs[#comboRefs + 1] = ctrl

        return Components.Window {
            Resizable = false,
            OnLayout  = NoOpLayout,
            OnInitialize = function(self)
                local parent = self:getName()
                local labelW = math.floor(CONTENT_W * 0.55)
                local btnW   = ROW_H
                local valW   = 100
                local ctrlX  = labelW + MARGIN
                self:setDimensions(CONTENT_W, ROW_H)

                valLabel = Components.Label {
                    OnInitialize = function(s)
                        s:setText(getLabelFn(pending[key]))
                        s:setDimensions(valW, ROW_H)
                        s:centerText()
                        s:addAnchor("topleft", parent, "topleft", ctrlX + btnW, 4)
                    end,
                }
                ctrl.label = valLabel

                self:setChildren({
                    Components.Label {
                        OnInitialize = function(s)
                            s:setText(labelText)
                            s:setDimensions(labelW, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", MARGIN, 4)
                        end,
                    },
                    Components.Button {
                        Template = "MongbatButton18",
                        OnInitialize = function(s)
                            s:setText(L"<")
                            s:setDimensions(btnW, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", ctrlX, 0)
                        end,
                        OnLButtonUp = function()
                            local v = pending[key] - 1
                            if v < 1 then v = n end
                            pending[key] = v
                            if valLabel then valLabel:setText(getLabelFn(v)) end
                        end,
                    },
                    valLabel,
                    Components.Button {
                        Template = "MongbatButton18",
                        OnInitialize = function(s)
                            s:setText(L">")
                            s:setDimensions(btnW, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", ctrlX + btnW + valW, 0)
                        end,
                        OnLButtonUp = function()
                            local v = pending[key] + 1
                            if v > n then v = 1 end
                            pending[key] = v
                            if valLabel then valLabel:setText(getLabelFn(v)) end
                        end,
                    },
                })
            end,
        }
    end

    -- Section header label row (cosmetic separator)
    local function SectionLabel(text)
        return Components.Window {
            Resizable = false,
            OnLayout  = NoOpLayout,
            OnInitialize = function(self)
                local parent = self:getName()
                self:setDimensions(CONTENT_W, ROW_H)
                self:setChildren({
                    Components.Label {
                        OnInitialize = function(s)
                            s:setText(text)
                            s:setDimensions(CONTENT_W - MARGIN * 2, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", MARGIN, 4)
                            s:setTextColor({ r = 206, g = 217, b = 242 })
                        end,
                    },
                })
            end,
        }
    end

    -- Tab panel wrapper: positions rows with StackRows layout, hidden by default.
    local function TabPanel(rows)
        return Components.Window {
            Resizable = false,
            OnLayout  = StackRows,
            OnInitialize = function(self)
                self:setDimensions(CONTENT_W, CONTENT_H)
                self:setShowing(false)
                self:setChildren(rows)
            end,
        }
    end

    -- ======================================================================
    -- Tab 1: Graphics
    -- ======================================================================
    local graphicsPanel = TabPanel({
        SectionLabel(L"-- Display --"),
        Checkbox(L"Use Fullscreen",          "useFullScreen"),
        Checkbox(L"Show Window Frame",        "showWindowFrame"),
        Checkbox(L"Enable VSync",             "enableVSync"),
        ComboRow(L"Max Framerate", "framerateIdx", FPS_LABELS,
            function(idx) return FPS_LABELS[idx] or L"60" end),
        SectionLabel(L"-- Environment --"),
        Checkbox(L"Show Shadows",             "showShadows"),
        Checkbox(L"Show Foliage",             "displayFoliage"),
        Checkbox(L"Circle of Transparency",   "circleOfTrans"),
        Checkbox(L"Idle Animations",          "idleAnimation"),
        SectionLabel(L"-- Brightness --"),
        -- gamma stored as integer 0-200 (= float×100); display as X.XX
        SliderRow(L"Gamma", "gamma", 0, 200, 5, fmtDecimal),
    })

    -- ======================================================================
    -- Tab 2: Sound
    -- ======================================================================
    local soundPanel = TabPanel({
        SectionLabel(L"-- Master --"),
        Checkbox(L"Master Sound Enabled",  "masterEnabled"),
        SliderRow(L"Master Volume",        "masterVolume",  0, 100, 5, fmtPercent),
        SectionLabel(L"-- Effects --"),
        Checkbox(L"Effects Enabled",       "effectsEnabled"),
        SliderRow(L"Effects Volume",       "effectsVolume", 0, 100, 5, fmtPercent),
        SectionLabel(L"-- Music --"),
        Checkbox(L"Music Enabled",         "musicEnabled"),
        SliderRow(L"Music Volume",         "musicVolume",   0, 100, 5, fmtPercent),
        SectionLabel(L"-- Other --"),
        Checkbox(L"Play Footsteps",        "footsteps"),
    })

    -- ======================================================================
    -- Tab 3: Options
    -- ======================================================================
    local optionsPanel = TabPanel({
        SectionLabel(L"-- Movement --"),
        Checkbox(L"Always Run",                    "alwaysRun"),
        Checkbox(L"Enable Autorun",                "enableAutorun"),
        Checkbox(L"Enable Pathfinding",            "enablePathfinding"),
        SectionLabel(L"-- Combat --"),
        Checkbox(L"Query Before Criminal Actions", "queryBeforeCriminal"),
        Checkbox(L"Always Attack",                 "alwaysAttack"),
        Checkbox(L"Target Queueing",               "targetQueueing"),
        Checkbox(L"No War on Pets",                "noWarOnPets"),
        Checkbox(L"No War on Party",               "noWarOnParty"),
        SectionLabel(L"-- Interaction --"),
        Checkbox(L"Ignore Mouse Actions on Self",  "ignoreMouseOnSelf"),
        Checkbox(L"Hold Shift to Unstack",         "holdShiftToUnstack"),
        Checkbox(L"Shift Right-Click Menus",       "shiftRightClick"),
    })

    -- ======================================================================
    -- Tab 4: Key Bindings
    -- ======================================================================
    local bindingRows = {}

    -- Column header
    bindingRows[1] = Components.Window {
        Resizable = false,
        OnLayout  = NoOpLayout,
        OnInitialize = function(self)
            local parent = self:getName()
            self:setDimensions(CONTENT_W, ROW_H)
            local colW = math.floor(CONTENT_W / 2) - MARGIN
            self:setChildren({
                Components.Label {
                    OnInitialize = function(s)
                        s:setText(L"Action")
                        s:setDimensions(colW, ROW_H)
                        s:addAnchor("topleft", parent, "topleft", MARGIN, 4)
                        s:setTextColor({ r = 206, g = 217, b = 242 })
                    end,
                },
                Components.Label {
                    OnInitialize = function(s)
                        s:setText(L"Key (click Set to rebind)")
                        s:setDimensions(colW, ROW_H)
                        s:addAnchor("topleft", parent, "topleft", colW + MARGIN * 2, 4)
                        s:setTextColor({ r = 206, g = 217, b = 242 })
                    end,
                },
            })
        end,
    }

    Utils.Array.ForEach(KEYBINDINGS, function(binding, bIdx)
        local bRef = { index = bIdx }
        Utils.Array.Add(bindingRefs, bRef)

        Utils.Array.Add(bindingRows, Components.Window {
            Resizable = false,
            OnLayout  = NoOpLayout,
            OnInitialize = function(self)
                local parent = self:getName()
                self:setDimensions(CONTENT_W, ROW_H)
                local colW   = math.floor(CONTENT_W / 2) - MARGIN
                local setW   = ROW_H * 2
                local keyVal = pendingBindings[binding.atype] or Api.Settings.GetKeybinding(binding.atype)

                local keyLabel = Components.Label {
                    OnInitialize = function(s)
                        s:setText(keyVal)
                        s:setDimensions(colW - setW - MARGIN, ROW_H)
                        s:addAnchor("topleft", parent, "topleft", colW + MARGIN * 2, 4)
                    end,
                }
                bRef.label = keyLabel

                self:setChildren({
                    Components.Label {
                        OnInitialize = function(s)
                            s:setText(binding.name)
                            s:setDimensions(colW, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", MARGIN, 4)
                        end,
                    },
                    keyLabel,
                    Components.Button {
                        Template = "MongbatButton18",
                        OnInitialize = function(s)
                            s:setText(L"Set")
                            s:setDimensions(setW, ROW_H)
                            s:addAnchor("topright", parent, "topright", -MARGIN, 0)
                        end,
                        OnLButtonUp = function()
                            recordingIndex = bIdx
                            Api.Settings.StartRecordKey()
                        end,
                    },
                })
            end,
        })
    end)

    local keyBindPanel = TabPanel(bindingRows)

    -- ======================================================================
    -- Tab 5: Legacy
    -- ======================================================================
    local legacyPanel = TabPanel({
        SectionLabel(L"-- Legacy UI Options --"),
        Checkbox(L"Legacy Containers",  "legacyContainers"),
        Checkbox(L"Legacy Paperdolls",  "legacyPaperdolls"),
        Checkbox(L"Legacy Chat",        "legacyChat"),
        Checkbox(L"Legacy Targeting",   "legacyTargeting"),
    })

    -- ======================================================================
    -- Tab 6: Profanity
    -- ======================================================================
    local profanityPanel = TabPanel({
        SectionLabel(L"-- Word Filters --"),
        Checkbox(L"Bad Word Filter",           "badWordFilter"),
        Checkbox(L"Ignore List Filter",        "ignoreListFilter"),
        Checkbox(L"Ignore Conf List Filter",   "ignoreConfFilter"),
    })

    -- ======================================================================
    -- Tab 7: Key Default (reset bindings to engine defaults)
    -- ======================================================================
    local keyDefaultPanel = TabPanel({
        SectionLabel(L"-- Reset Key Bindings --"),
        Components.Window {
            Resizable = false,
            OnLayout  = NoOpLayout,
            OnInitialize = function(self)
                local parent = self:getName()
                self:setDimensions(CONTENT_W, ROW_H)
                self:setChildren({
                    Components.Label {
                        OnInitialize = function(s)
                            s:setText(L"Reset all key bindings to MMO (standard) defaults.")
                            s:setDimensions(CONTENT_W - 130 - MARGIN * 2, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", MARGIN, 4)
                        end,
                    },
                    Components.Button {
                        Template = "MongbatButton18",
                        OnInitialize = function(s)
                            s:setText(L"Reset MMO")
                            s:setDimensions(130, ROW_H)
                            s:addAnchor("topright", parent, "topright", -MARGIN, 0)
                        end,
                        OnLButtonUp = function()
                            Api.Event.Broadcast(Constants.Broadcasts.ResetMmoKeyBindings())
                            pendingBindings = {}
                            refreshAll()
                        end,
                    },
                })
            end,
        },
        Components.Window {
            Resizable = false,
            OnLayout  = NoOpLayout,
            OnInitialize = function(self)
                local parent = self:getName()
                self:setDimensions(CONTENT_W, ROW_H)
                self:setChildren({
                    Components.Label {
                        OnInitialize = function(s)
                            s:setText(L"Reset all key bindings to Legacy defaults.")
                            s:setDimensions(CONTENT_W - 130 - MARGIN * 2, ROW_H)
                            s:addAnchor("topleft", parent, "topleft", MARGIN, 4)
                        end,
                    },
                    Components.Button {
                        Template = "MongbatButton18",
                        OnInitialize = function(s)
                            s:setText(L"Reset Legacy")
                            s:setDimensions(130, ROW_H)
                            s:addAnchor("topright", parent, "topright", -MARGIN, 0)
                        end,
                        OnLButtonUp = function()
                            Api.Event.Broadcast(Constants.Broadcasts.ResetLegacyKeyBindings())
                            pendingBindings = {}
                            refreshAll()
                        end,
                    },
                })
            end,
        },
    })

    -- ======================================================================
    -- Tab 8: Overhead Text
    -- ======================================================================
    local overheadPanel = TabPanel({
        SectionLabel(L"-- Overhead Text --"),
        Checkbox(L"Show Overhead Chat",    "overheadChat"),
        ComboRow(L"Chat Fade Delay", "overheadChatFade", FADE_LABELS,
            function(idx) return FADE_LABELS[idx] or L"1s" end),
        Checkbox(L"Party Invite Pop-Up",   "partyInvitePopUp"),
        Checkbox(L"Show Tooltips",         "showTooltips"),
        Checkbox(L"Enable Chat Log",       "enableChatLog"),
    })

    -- ======================================================================
    -- Tab 9: Containers
    -- ======================================================================
    local containersPanel = TabPanel({
        SectionLabel(L"-- Container Display --"),
        Checkbox(L"Show Strength / Dex / Int Labels", "showStrLabel"),
    })

    -- ======================================================================
    -- Tab 10: Health Bars / UI Scale
    -- ======================================================================
    local healthbarsPanel = TabPanel({
        SectionLabel(L"-- UI Scale --"),
        -- uiScale stored as integer 50-150 (= float×100); display as X.XX
        SliderRow(L"UI Scale", "uiScale", 50, 150, 5, fmtDecimal),
    })

    -- ======================================================================
    -- Tab 11: Mobiles on Screen
    -- ======================================================================
    local mobilesPanel = TabPanel({
        SectionLabel(L"-- Mobile Names --"),
        ComboRow(L"Show Names", "showNamesIdx", SHOWNAMES_LABELS,
            function(idx) return SHOWNAMES_LABELS[idx] or L"None" end),
    })

    -- ======================================================================
    -- Tab panels array (must match TAB_LABELS order)
    -- ======================================================================
    local tabPanels = {
        graphicsPanel,
        soundPanel,
        optionsPanel,
        keyBindPanel,
        legacyPanel,
        profanityPanel,
        keyDefaultPanel,
        overheadPanel,
        containersPanel,
        healthbarsPanel,
        mobilesPanel,
    }

    -- ======================================================================
    -- Active tab tracking + ShowTab helper
    -- ======================================================================
    local activeTab    = 1
    local tabBtnRefs   = {}

    local function ShowTab(index)
        for i = 1, NUM_TABS do
            if tabPanels[i] then
                tabPanels[i]:setShowing(i == index)
            end
            if tabBtnRefs[i] then
                tabBtnRefs[i]:setChecked(i == index)
            end
        end
        activeTab = index
    end

    -- ======================================================================
    -- Custom window layout
    -- ======================================================================
    -- Children [1..NUM_TABS]            = tab buttons (horizontal row at top)
    -- Children [NUM_TABS+1..NUM_TABS*2] = content panels (overlapping, toggled)
    -- Children [NUM_TABS*2+1..+3]       = OK, Apply, Cancel action buttons
    local function SettingsLayout(window, children, child, index)
        local wName = window:getName()
        if index <= NUM_TABS then
            local col = index - 1
            child:clearAnchors()
            child:addAnchor("topleft", wName, "topleft", MARGIN + col * TAB_W, MARGIN)
        elseif index <= NUM_TABS * 2 then
            child:clearAnchors()
            child:addAnchor("topleft", wName, "topleft", MARGIN, CONTENT_TOP)
        else
            local ai    = index - NUM_TABS * 2   -- 1 = OK, 2 = Apply, 3 = Cancel
            local rightX = WIDTH - MARGIN - ACTION_BTN_W
            local x      = rightX - (3 - ai) * (ACTION_BTN_W + MARGIN)
            child:clearAnchors()
            child:addAnchor("topleft", wName, "topleft", x, HEIGHT - MARGIN - ACTION_H)
        end
    end

    -- ======================================================================
    -- Build the flat children array
    -- ======================================================================
    local allChildren = {}

    -- Tab buttons (indices 1..NUM_TABS)
    for i = 1, NUM_TABS do
        local ti = i
        local btn = Components.Button {
            Template = "MongbatButton18",
            OnInitialize = function(s)
                s:setCheckButton(true)
                s:setChecked(ti == activeTab)
                s:setDimensions(TAB_W, TAB_H)
                s:setText(TAB_LABELS[ti])
            end,
            OnLButtonUp = function()
                ShowTab(ti)
            end,
        }
        tabBtnRefs[i]   = btn
        allChildren[i]  = btn
    end

    -- Content panels (indices NUM_TABS+1..NUM_TABS*2)
    for i = 1, NUM_TABS do
        allChildren[NUM_TABS + i] = tabPanels[i]
    end

    -- Action buttons (indices NUM_TABS*2+1..NUM_TABS*2+3)
    local okBtn = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(s)
            s:setText(L"OK")
            s:setDimensions(ACTION_BTN_W, ACTION_H)
        end,
        OnLButtonUp = function()
            applySettings()
            Api.Window.SetShowing(NAME, false)
        end,
    }
    local applyBtn = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(s)
            s:setText(L"Apply")
            s:setDimensions(ACTION_BTN_W, ACTION_H)
        end,
        OnLButtonUp = function()
            applySettings()
        end,
    }
    local cancelBtn = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(s)
            s:setText(L"Cancel")
            s:setDimensions(ACTION_BTN_W, ACTION_H)
        end,
        OnLButtonUp = function()
            loadSettings()
            refreshAll()
            Api.Window.SetShowing(NAME, false)
        end,
    }
    allChildren[NUM_TABS * 2 + 1] = okBtn
    allChildren[NUM_TABS * 2 + 2] = applyBtn
    allChildren[NUM_TABS * 2 + 3] = cancelBtn

    -- ======================================================================
    -- Main window
    -- ======================================================================
    local function MainWindow()
        return Components.Window {
            Name      = NAME,
            Resizable = false,
            OnLayout  = SettingsLayout,
            OnInitialize = function(self)
                self:setDimensions(WIDTH, HEIGHT)
                self:anchorToParentCenter()
                self:setChildren(allChildren)
            end,
            -- Suppress the Window default which destroys on right-click; we keep the window alive
            OnRButtonUp = function() end,
            OnShown = function()
                loadSettings()
                refreshAll()
                ShowTab(activeTab)
            end,
            -- Reload settings when the engine broadcasts an external settings change
            OnUserSettingsUpdated = function()
                loadSettings()
                refreshAll()
            end,
            -- Toggle window visibility when the settings hotkey is pressed
            OnToggleUserPreference = function(self)
                local isShowing = Api.Window.IsShowing(NAME)
                self:setShowing(not isShowing)
            end,
            -- Cancel key recording when the player presses Escape
            OnKeyCancelRecord = function()
                Api.Settings.CancelRecordKey()
                recordingIndex = nil
            end,
            -- Fired by the engine when key recording completes
            OnKeyRecorded = function()
                if recordingIndex == nil then return end
                local recorded = Api.Settings.GetRecordedKey()
                Api.Settings.CancelRecordKey()
                if recorded ~= L"" then
                    local atype = KEYBINDINGS[recordingIndex].atype
                    pendingBindings[atype] = recorded
                    Utils.Array.ForEach(bindingRefs, function(ref)
                        if ref.index == recordingIndex and ref.label then
                            ref.label:setText(recorded)
                        end
                    end)
                end
                recordingIndex = nil
            end,
        }
    end

    -- Snapshot settings before first show, then create the window hidden.
    loadSettings()
    MainWindow():create(false)
end

-- ========================================================================== --
-- OnShutdown
-- ========================================================================== --

---@param context Context
local function OnShutdown(context)
    context.Api.Window.Destroy(NAME)
    context.Components.Defaults.SettingsWindow:restore()
end

-- ========================================================================== --
-- Mod registration
-- ========================================================================== --

Mongbat.Mod {
    Name         = "MongbatSettingsWindow",
    Path         = "/src/mods/mongbat-settings-window",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown,
}
