local NAME = "MongbatSkillsInfoWindow"

-- Derived child window names from the XML template ($parent = NAME)
local SCROLL_VIEW    = NAME .. "ScrollView"
local SCROLL_CHILD   = SCROLL_VIEW .. "ScrollChild"
local SCROLL_CONTENT = SCROLL_CHILD .. "Content"

-- Saved SkillsInfo function references, captured during OnInitialize so that
-- OnShutdown can restore the original DefaultSkillsInfo behaviour.
local origInitialize
local origShutdown
local origUpdateGump
local origClearGump

-- ========================================================================== --
-- Skill Data
-- ========================================================================== --
-- 58 skill data arrays indexed [1..8]:
--   [1] titleTID    Skill name TID (used as the window title)
--   [2] descTID     Description TID
--   [3] reqTID      Requirements TID  (0 = use "no requirements" fallback TID)
--   [4] directTID   Direct usage TID  (0 = section omitted)
--   [5] interTID    Interactive usage TID (0 = section omitted)
--   [6] autoTID     Automatic usage TID  (0 = section omitted)
--   [7] moreTID     "More info" TID  (0 = section omitted)
--   [8] className   Character title wstring (e.g. L"warrior")

local SKILL_DATA = {
    {1002000, 1078612, 1078613,       0, 1078614, 1078615, 1078616, L"Alchemist"},       -- 01 Alchemy
    {1002004, 1078623,       0, 1078624,       0, 1078625, 1078626, L"Biologist"},       -- 02 Anatomy
    {1002007, 1078627,       0, 1078628,       0, 1078629, 1078630, L"Naturalist"},      -- 03 Animal Lore
    {1002010, 1078631,       0, 1078632,       0,       0, 1078633, L"Tamer"},           -- 04 Animal Taming
    {1002029, 1078634, 1078635,       0, 1078636,       0, 1078637, L"Archer"},          -- 05 Archery
    {1002034, 1078638,       0, 1078639,       0, 1078640, 1078641, L"Weapon Master"},   -- 06 Arms Lore
    {1002040, 1078642,       0, 1078643,       0,       0, 1078644, L"Beggar"},          -- 07 Begging
    {1044296, 1078645, 1078646,       0, 1078647,       0, 1078648, L"Blacksmith"},      -- 08 Blacksmithy
    {1044112, 1078649, 1078650,       0, 1078651,       0, 1078652, L"Samurai"},         -- 09 Bushido
    {1002050, 1078653, 1078654,       0, 1078655,       0, 1078656, L"Explorer"},        -- 10 Camping
    {1002054, 1078657, 1078658,       0, 1078659,       0, 1078660, L"Carpenter"},       -- 11 Carpentry
    {1002057, 1078661, 1078662,       0, 1078663,       0, 1078664, L"Cartographer"},    -- 12 Cartography
    {1044111, 1078665, 1078666,       0, 1078667,       0, 1078668, L"Paladin"},         -- 13 Chivalry
    {1002063, 1078669, 1078670,       0, 1078671,       0, 1078672, L"Chef"},            -- 14 Cooking
    {1002065, 1078673,       0, 1078674,       0,       0, 1078675, L"Scout"},           -- 15 Detecting Hidden
    {1044075, 1078676, 1078677, 1078678,       0,       0, 1078679, L"Demoralizer"},     -- 16 Discordance
    {1044076, 1078680,       0, 1078681,       0, 1078682, 1078683, L"Scholar"},         -- 17 Evaluating Intelligence
    {1002073, 1002074, 1078685,       0, 1078686,       0, 1078687, L"Fencer"},          -- 18 Fencing
    {1002076, 1078692, 1078693,       0, 1078694,       0, 1078695, L"Fisherman"},       -- 19 Fishing
    {1015156, 1078688, 1078689,       0, 1078690,       0, 1078691, L"Bowyer"},          -- 20 Fletching
    {1044110, 1078696,       0,       0,       0, 1078697, 1078698, L"Driven"},          -- 21 Focus
    {1002078, 1078699,       0, 1078700,       0,       0, 1078701, L"Detective"},       -- 22 Forensic Evaluation
    {1002082, 1078702,       0,       0, 1078703,       0, 1078704, L"Healer"},          -- 23 Healing
    {1002086, 1078705, 1078706,       0, 1078707,       0, 1078708, L"Shepherd"},        -- 24 Herding
    {1002088, 1078709,       0, 1078710,       0,       0, 1078711, L"Shade"},           -- 25 Hiding
    {1079712, 1079715, 1095248,       0, 1079720,       0, 1079723, L"Artificer"},       -- 26 Imbuing
    {1002090, 1078712, 1078713, 1078714, 1078715, 1078716, 1078717, L"Scribe"},          -- 27 Inscription
    {1002094, 1078718,       0, 1078719,       0,       0, 1078720, L"Merchant"},        -- 28 Item Identification
    {1002097, 1078721, 1078722,       0, 1078723,       0, 1078724, L"Infiltrator"},     -- 29 Lockpicking
    {1002100, 1078725, 1078726,       0, 1078727, 1078728, 1078729, L"Lumberjack"},      -- 30 Lumberjacking
    {1002102, 1078730, 1078731,       0, 1078732,       0, 1078733, L"Armsman"},         -- 31 Mace Fighting
    {1002106, 1078734, 1078735,       0, 1078736,       0, 1078737, L"Mage"},            -- 32 Magery
    {1044086, 1078742,       0,       0,       0, 1078743, 1078744, L"Warder"},          -- 33 Resisting Spells
    {1044106, 1078738,       0, 1078739,       0, 1078740, 1078741, L"Stoic"},           -- 34 Meditation
    {1002111, 1078745, 1078746,       0, 1078747,       0, 1078748, L"Miner"},           -- 35 Mining
    {1002116, 1078749, 1078750,       0, 1078751,       0, 1078752, L"Bard"},            -- 36 Musicianship
    {1079711, 1079714, 1095247,       0, 1079719,       0, 1079722, L"Mystic"},          -- 37 Mysticism
    {1044109, 1078753, 1078754,       0, 1078755,       0, 1078756, L"Necromancer"},     -- 38 Necromancy
    {1044113, 1078757, 1078758,       0, 1078759,       0, 1078760, L"Ninja"},           -- 39 Ninjitsu
    {1002118, 1078761, 1078762,       0, 1078763,       0, 1078764, L"Duelist"},         -- 40 Parrying
    {1002120, 1078765, 1078766, 1078767,       0,       0, 1078768, L"Pacifier"},        -- 41 Peacemaking
    {1002122, 1078769, 1078770, 1078771,       0, 1078772, 1078773, L"Assassin"},        -- 42 Poisoning
    {1002125, 1078774, 1078775, 1078776,       0,       0, 1078777, L"Rouser"},          -- 43 Provocation
    {1002136, 1078778,       0, 1078779,       0,       0, 1078780, L"Trap Specialist"}, -- 44 Remove Trap
    {1002138, 1078781,       0,       0, 1078782,       0, 1078783, L"Spy"},             -- 45 Snooping
    {1044114, 1078784, 1078785,       0, 1078786,       0, 1078787, L"Arcanist"},        -- 46 Spellweaving
    {1002140, 1078788,       0, 1078789,       0, 1078790, 1078791, L"Medium"},          -- 47 Spirit Speak
    {1002142, 1078792,       0, 1078793,       0,       0, 1078794, L"Pickpocket"},      -- 48 Stealing
    {1044107, 1078795, 1078856, 1078796,       0, 1078805, 1078797, L"Rogue"},           -- 49 Stealth
    {1002151, 1078798, 1078799,       0, 1078800,       0, 1078801, L"Swordsman"},       -- 50 Swordsmanship
    {1044087, 1078802,       0,       0,       0, 1078803, 1078804, L"Tactician"},       -- 51 Tactics
    {1002155, 1078806, 1078807,       0, 1078808,       0, 1078809, L"Tailor"},          -- 52 Tailoring
    {1002160, 1078810,       0, 1078811,       0,       0, 1078812, L"Preagustator"},    -- 53 Taste Identification
    {1079713, 1079716, 1095249,       0, 1079721,       0, 1079724, L"Bladeweaver"},     -- 54 Throwing
    {1002162, 1078813, 1078814,       0, 1078815,       0, 1078816, L"Tinker"},          -- 55 Tinkering
    {1002165, 1078817,       0, 1078818,       0,       0, 1078819, L"Ranger"},          -- 56 Tracking
    {1002167, 1078820, 1078821,       0, 1078822,       0, 1078823, L"Veterinarian"},    -- 57 Veterinary
    {1002169, 1078824,       0,       0, 1078825,       0, 1078826, L"Wrestler"},        -- 58 Wrestling
}

-- TID for the "No requirements" fallback text
local TID_REQ_NOTHING = 1078611

-- TIDs for section header labels
local TID_REQUIRES    = 1078597
local TID_DIRECT      = 1078598
local TID_INTERACTIVE = 1078599
local TID_AUTOMATIC   = 1078600

-- TIDs used by the default UpdateGump for Title and Training section headers
local TID_TITLE_UNLOCKED = 1155271
local TID_TRAINING       = 1155272

-- TID for the "More" section header
local TID_MORE = 1078601

-- Layout constants
local WINDOW_WIDTH    = 400
local WINDOW_HEIGHT   = 500
local SCROLL_PADDING  = 40

-- Locale placeholder token present in certain TID strings (e.g. Requirements)
local MARKUP_PLACEHOLDER = L" ~1_val~"

-- Filesystem filename prefix for skill training text files
local TRAINING_FILE_PREFIX = "uo-skillinfo-training-"

-- ========================================================================== --
-- Mod
-- ========================================================================== --

Mongbat.Mod {
    Name = "MongbatSkillsInfo",
    Path = "/src/mods/mongbat-skills-info",
    OnInitialize = function(context)
        local Api        = context.Api
        local Data       = context.Data
        local Components = context.Components

        -- Obtain the proxy for the SkillsInfo global table.  We intentionally
        -- do NOT call disable() here; disable() replaces every function with a
        -- no-op, which would prevent our overrides from being visible to
        -- SkillsWindow.ToggleHelpButton when it calls SkillsInfo.UpdateGump.
        local skillsInfoDefault = Components.Defaults.SkillsInfo:getDefault()

        -- Save original function references before overriding them so that
        -- OnShutdown can cleanly restore the default SkillsInfo behaviour.
        origInitialize = skillsInfoDefault.Initialize
        origShutdown   = skillsInfoDefault.Shutdown
        origUpdateGump = skillsInfoDefault.UpdateGump
        origClearGump  = skillsInfoDefault.ClearGump

        -- Replace Initialize so the default SkillsInfo window cannot appear.
        -- SkillsWindow calls WindowSetShowing("SkillsInfo", true) after
        -- UpdateGump; by shrinking the default window to 0×0, that call is
        -- effectively harmless.
        skillsInfoDefault.Initialize = function()
            Api.Window.SetShowing("SkillsInfo", false)
            Api.Window.SetDimensions("SkillsInfo", 0, 0)
        end
        skillsInfoDefault.Shutdown = function() end

        -- ------------------------------------------------------------------ --
        -- Dynamic section label management
        -- ------------------------------------------------------------------ --

        -- Running counter used to generate unique, sequential label names.
        local labelSeq = 0

        -- Names of all label windows created for the current skill view;
        -- destroyed when the skill selection changes.
        local sectionLabels = {}

        --- Destroys all label windows from the current skill view.
        local function clearSections()
            for _, labelName in ipairs(sectionLabels) do
                Api.Window.Destroy(labelName)
            end
            sectionLabels = {}
            labelSeq = 0
        end

        --- Creates a single label window and anchors it to the content area.
        ---@param template string   Template name: "SkillsInfoLabelHeader" or "SkillsInfoLabelBody".
        ---@param text wstring      Text to display.
        ---@param prevLabel string  Name of the window to anchor below, or SCROLL_CONTENT for first.
        ---@param topGap integer    Vertical offset above this label.
        ---@return string           The created window name.
        local function addLabel(template, text, prevLabel, topGap)
            labelSeq = labelSeq + 1
            local labelName = SCROLL_CONTENT .. "L" .. labelSeq
            Api.Window.CreateFromTemplate(labelName, template, SCROLL_CONTENT)
            Api.Label.SetText(labelName, text)
            Api.Window.ClearAnchors(labelName)
            if prevLabel == SCROLL_CONTENT then
                Api.Window.AddAnchor(labelName, "topleft", SCROLL_CONTENT, "topleft", 0, 0)
            else
                Api.Window.AddAnchor(labelName, "topleft", prevLabel, "bottomleft", 0, topGap)
            end
            sectionLabels[#sectionLabels + 1] = labelName
            return labelName
        end

        --- Adds a titled section (header + body) to the scroll view.
        ---@param headerText wstring  Section title.
        ---@param bodyText wstring    Section body.
        ---@param prevLabel string    Previous label name (or SCROLL_CONTENT for first).
        ---@param topGap integer      Gap above the header label.
        ---@return string             Name of the body label (for anchor chaining).
        local function addSection(headerText, bodyText, prevLabel, topGap)
            local headLabel = addLabel("SkillsInfoLabelHeader", headerText, prevLabel, topGap)
            return addLabel("SkillsInfoLabelBody", bodyText, headLabel, 4)
        end

        --- Updates the scroll child dimensions and resets the scroll position.
        local function refreshScroll()
            local totalH = 0
            for _, labelName in ipairs(sectionLabels) do
                local dims = Api.Window.GetDimensions(labelName)
                totalH = totalH + dims.y
            end
            -- Add padding to account for inter-section gap offsets.
            Api.Window.SetDimensions(SCROLL_CHILD, 350, totalH + SCROLL_PADDING)
            Api.ScrollWindow.UpdateScrollRect(SCROLL_VIEW)
            Api.ScrollWindow.SetOffset(SCROLL_VIEW, 0)
        end

        -- ------------------------------------------------------------------ --
        -- Window definition
        -- ------------------------------------------------------------------ --

        ---@type Window
        local window = Components.Window {
            Name     = NAME,
            Template = "MongbatSkillsInfoTemplate",
            OnInitialize = function(self)
                self:setDimensions(WINDOW_WIDTH, WINDOW_HEIGHT)
                Api.Window.ClearAnchors(NAME)
                Api.Window.AddAnchor(NAME, "topright", "SkillsWindow", "topleft", 0, 0)
                Api.Window.RestorePosition(NAME)
            end,
        }

        -- ------------------------------------------------------------------ --
        -- UpdateGump — replaces SkillsInfo.UpdateGump
        -- ------------------------------------------------------------------ --

        ---@param skillIndex integer 1-based index into SKILL_DATA (matches SkillsWindow's skillId)
        local function updateGump(skillIndex)
            local info = SKILL_DATA[skillIndex]
            if not info then return end

            clearSections()

            local titleTid  = info[1]
            local descTid   = info[2]
            local reqTid    = info[3]
            local directTid = info[4]
            local interTid  = info[5]
            local autoTid   = info[6]
            local moreTid   = info[7]
            local className = info[8]

            -- Update the window chrome title bar to the skill name
            Api.Window.SetTitle(
                NAME,
                Api.String.TranslateMarkup(Api.String.GetStringFromTid(titleTid))
            )

            -- 1. Description (body only — no section header label)
            local lastLabel = addLabel(
                "SkillsInfoLabelBody",
                Api.String.TranslateMarkup(Api.String.GetStringFromTid(descTid)),
                SCROLL_CONTENT, 0
            )

            -- 2. Requirements (always shown; fall back to "no requirements" text when reqTid == 0)
            local reqBodyTid = (reqTid ~= 0) and reqTid or TID_REQ_NOTHING
            -- The engine's Requirements TID contains a " ~1_val~" placeholder;
            -- strip it for a clean header.
            local reqHeader  = wstring.gsub(
                Api.String.GetStringFromTid(TID_REQUIRES), MARKUP_PLACEHOLDER, L""
            )
            lastLabel = addSection(
                reqHeader,
                Api.String.TranslateMarkup(Api.String.GetStringFromTid(reqBodyTid)),
                lastLabel, 10
            )

            -- 3. Direct Usage (optional)
            if directTid ~= 0 then
                lastLabel = addSection(
                    Api.String.TranslateMarkup(Api.String.GetStringFromTid(TID_DIRECT)),
                    Api.String.TranslateMarkup(Api.String.GetStringFromTid(directTid)),
                    lastLabel, 10
                )
            end

            -- 4. Interactive Usage (optional)
            if interTid ~= 0 then
                lastLabel = addSection(
                    Api.String.TranslateMarkup(Api.String.GetStringFromTid(TID_INTERACTIVE)),
                    Api.String.TranslateMarkup(Api.String.GetStringFromTid(interTid)),
                    lastLabel, 10
                )
            end

            -- 5. Automatic Usage (optional)
            if autoTid ~= 0 then
                lastLabel = addSection(
                    Api.String.TranslateMarkup(Api.String.GetStringFromTid(TID_AUTOMATIC)),
                    Api.String.TranslateMarkup(Api.String.GetStringFromTid(autoTid)),
                    lastLabel, 10
                )
            end

            -- 6. Title Unlocked (shown for every skill since each skill grants a character title)
            lastLabel = addSection(
                Api.String.GetStringFromTid(TID_TITLE_UNLOCKED),
                className,
                lastLabel, 10
            )

            -- 7. Training Methods (loaded from the filesystem; omitted if file is absent)
            local classNameStr = Api.String.WStringToString(className)
            Api.File.LoadTextFile(TRAINING_FILE_PREFIX .. classNameStr .. ".txt")
            local trainText = Data.LoadedTextFile()
            if trainText and wstring.len(trainText) > 0 then
                lastLabel = addSection(
                    Api.String.GetStringFromTid(TID_TRAINING),
                    trainText,
                    lastLabel, 20
                )
            end

            -- 8. More (optional)
            if moreTid ~= 0 then
                lastLabel = addSection(
                    Api.String.TranslateMarkup(Api.String.GetStringFromTid(TID_MORE)),
                    Api.String.TranslateMarkup(Api.String.GetStringFromTid(moreTid)),
                    lastLabel, 10
                )
            end

            refreshScroll()
            Api.Window.SetShowing(NAME, true)
        end

        -- Override SkillsInfo.UpdateGump on the proxy so that SkillsWindow's
        -- call `SkillsInfo.UpdateGump(skillId)` routes to our implementation.
        -- Writing via the proxy's __newindex stores the function in _original,
        -- which is read back by __index when the engine/callers access it.
        skillsInfoDefault.UpdateGump = function(skillIndex)
            updateGump(skillIndex)
        end

        skillsInfoDefault.ClearGump = function()
            clearSections()
        end

        -- Create the window hidden; it becomes visible when UpdateGump is called.
        window:create(false)
    end,

    OnShutdown = function(context)
        -- Restore the original SkillsInfo functions so SkillsWindow continues
        -- to work if this mod is disabled or reloaded.
        local skillsInfoDefault = context.Components.Defaults.SkillsInfo:getDefault()
        skillsInfoDefault.Initialize = origInitialize
        skillsInfoDefault.Shutdown   = origShutdown
        skillsInfoDefault.UpdateGump = origUpdateGump
        skillsInfoDefault.ClearGump  = origClearGump
        context.Api.Window.Destroy(NAME)
    end,
}
