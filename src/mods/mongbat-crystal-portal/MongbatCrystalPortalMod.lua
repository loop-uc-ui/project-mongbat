local NAME = "MongbatCrystalPortal"

-- ========================================================================== --
-- Destination Tables
-- (Mirrors CrystalPortal.Trammel / CrystalPortal.Felucca from default UI)
-- ========================================================================== --

local Destinations = {
    Trammel = {
        Dungeons = {
            { name = L"Blighted Grove",        command = L"grove"      },
            { name = L"Covetous",              command = L"covetous"   },
            { name = L"Deceit",                command = L"deceit"     },
            { name = L"Despise",               command = L"despise"    },
            { name = L"Destard",               command = L"destard"    },
            { name = L"Ice",                   command = L"ice"        },
            { name = L"Fire",                  command = L"fire"       },
            { name = L"Hythloth",              command = L"hythloth"   },
            { name = L"Orc Cave",              command = L"orc"        },
            { name = L"Painted Caves",         command = L"caves"      },
            { name = L"Palace of Paroxysmus",  command = L"palace"     },
            { name = L"Prism of Light",        command = L"prism"      },
            { name = L"Sanctuary",             command = L"sanctuary"  },
            { name = L"Shame",                 command = L"shame"      },
            { name = L"Wind",                  command = L"wind"       },
            { name = L"Wrong",                 command = L"wrong"      },
            { name = L"Doom",                  command = L"doom"       },
            { name = L"The Citadel",           command = L"citadel"    },
            { name = L"Fan Dancer Dojo",       command = L"fandancer"  },
            { name = L"Yomotsu Mines",         command = L"mines"      },
            { name = L"Bedlam",                command = L"bedlam"     },
            { name = L"The Labyrinth",         command = L"labyrinth"  },
            { name = L"Underworld",            command = L"underworld" },
            { name = L"Tomb of the Kings",     command = L"abyss"      },
        },
        Moongates = {
            { name = L"Britain",               command = L"britain"      },
            { name = L"Haven",                 command = L"haven"        },
            { name = L"Jhelom",                command = L"jhelom"       },
            { name = L"Magincia",              command = L"magincia"     },
            { name = L"Minoc",                 command = L"minoc"        },
            { name = L"Moonglow",              command = L"moonglow"     },
            { name = L"Skara Brae",            command = L"skara"        },
            { name = L"Trinsic",               command = L"trinsic"      },
            { name = L"Yew",                   command = L"yew"          },
            { name = L"Compassion",            command = L"compassion"   },
            { name = L"Honesty",               command = L"honesty"      },
            { name = L"Honor",                 command = L"honor"        },
            { name = L"Humility",              command = L"humility"     },
            { name = L"Justice",               command = L"justice"      },
            { name = L"Sacrifice",             command = L"sacrifice"    },
            { name = L"Spirituality",          command = L"spirituality" },
            { name = L"Valor",                 command = L"valor"        },
            { name = L"Chaos",                 command = L"chaos"        },
            { name = L"Luna",                  command = L"luna"         },
            { name = L"Umbra",                 command = L"umbra"        },
            { name = L"Isamu Jima",            command = L"isamu"        },
            { name = L"Makoto Jima",           command = L"makoto"       },
            { name = L"Homare Jima",           command = L"homare"       },
            { name = L"Royal City",            command = L"termur"       },
            { name = L"Valley of Eodon",       command = L"eodon"        },
        },
        Banks = {
            { name = L"Britain",               command = L"britain"  },
            { name = L"Buccaneer's Den",       command = L"bucs"     },
            { name = L"Cove",                  command = L"cove"     },
            { name = L"Delucia",               command = L"delucia"  },
            { name = L"Haven",                 command = L"haven"    },
            { name = L"Jhelom",                command = L"jhelom"   },
            { name = L"Magincia",              command = L"magincia" },
            { name = L"Minoc",                 command = L"minoc"    },
            { name = L"Moonglow",              command = L"moonglow" },
            { name = L"Nujel'm",               command = L"nujelm"   },
            { name = L"Papua",                 command = L"papua"    },
            { name = L"Serpent's Hold",        command = L"serpent"  },
            { name = L"Skara Brae",            command = L"skara"    },
            { name = L"Trinsic",               command = L"trinsic"  },
            { name = L"Vesper",                command = L"vesper"   },
            { name = L"Wind",                  command = L"wind"     },
            { name = L"Yew",                   command = L"yew"      },
            { name = L"Luna",                  command = L"luna"     },
            { name = L"Umbra",                 command = L"umbra"    },
            { name = L"Zento",                 command = L"zento"    },
            { name = L"Royal City",            command = L"termur"   },
            { name = L"Gypsy Bank",            command = L"ilshenar" },
        },
    },
    Felucca = {
        Dungeons = {
            { name = L"Blighted Grove",        command = L"grove"     },
            { name = L"Covetous",              command = L"covetous"  },
            { name = L"Deceit",                command = L"deceit"    },
            { name = L"Despise",               command = L"despise"   },
            { name = L"Destard",               command = L"destard"   },
            { name = L"Ice",                   command = L"ice"       },
            { name = L"Fire",                  command = L"fire"      },
            { name = L"Hythloth",              command = L"hythloth"  },
            { name = L"Orc Cave",              command = L"orc"       },
            { name = L"Painted Caves",         command = L"caves"     },
            { name = L"Prism of Light",        command = L"prism"     },
            { name = L"Shame",                 command = L"shame"     },
            { name = L"Sanctuary",             command = L"sanctuary" },
            { name = L"Wind",                  command = L"wind"      },
            { name = L"Wrong",                 command = L"wrong"     },
        },
        Moongates = {
            { name = L"Britain",               command = L"britain"  },
            { name = L"Buccaneer's Den",       command = L"bucs"     },
            { name = L"Jhelom",                command = L"jhelom"   },
            { name = L"Magincia",              command = L"magincia" },
            { name = L"Minoc",                 command = L"minoc"    },
            { name = L"Moonglow",              command = L"moonglow" },
            { name = L"Skara Brae",            command = L"skara"    },
            { name = L"Trinsic",               command = L"trinsic"  },
            { name = L"Yew",                   command = L"yew"      },
        },
        Banks = {
            { name = L"Britain",               command = L"britain"  },
            { name = L"Buccaneer's Den",       command = L"bucs"     },
            { name = L"Cove",                  command = L"cove"     },
            { name = L"Jhelom",                command = L"jhelom"   },
            { name = L"Magincia",              command = L"magincia" },
            { name = L"Minoc",                 command = L"minoc"    },
            { name = L"Moonglow",              command = L"moonglow" },
            { name = L"Nujel'm",               command = L"nujelm"   },
            { name = L"Ocllo",                 command = L"ocllo"    },
            { name = L"Serpent's Hold",        command = L"serpent"  },
            { name = L"Skara Brae",            command = L"skara"    },
            { name = L"Trinsic",               command = L"trinsic"  },
            { name = L"Vesper",                command = L"vesper"   },
            { name = L"Wind",                  command = L"wind"     },
            { name = L"Yew",                   command = L"yew"      },
        },
    },
}

-- Magery skill CSV index (1-based) — matches WindowData.SkillsCSV[32]
local MAGERY_SKILL_CSV_INDEX = 32
local MAGERY_REQUIRED        = 71.5

-- Persistence keys
local KEY_MAP       = "CrystalPortalMap"
local KEY_AREA      = "CrystalPortalArea"
local KEY_SELECTION = "CrystalPortalSelection"

-- Layout constants
local WINDOW_W = 320
local WINDOW_H = 260
local ROW_H    = 32
local BTN_H    = 28
local MARGIN   = 12
local GAP      = 8

-- Original Toggle saved for shutdown restoration.
-- Must survive across OnInitialize and OnShutdown, so file-scope state is used.
local originalCrystalPortalToggle = nil

---@param context Context
local function OnInitialize(context)
    local Api        = context.Api
    local Data       = context.Data
    local Components = context.Components
    local Constants  = context.Constants

    -- Intercept CrystalPortal.Toggle via the DefaultComponent proxy.
    -- We do NOT call disable() because that would also suppress our own Toggle
    -- replacement (the proxy no-ops all functions when disabled, including
    -- those we write to the underlying _original table).
    local crystalPortalDefault = Components.Defaults.CrystalPortal
    local cpProxy = crystalPortalDefault:getDefault()

    -- Per-session state (scoped to OnInitialize; captured by closures)
    local facet         = Api.Interface.LoadNumber(KEY_MAP,       1)
    local category      = Api.Interface.LoadNumber(KEY_AREA,      3)
    local selectedIndex = Api.Interface.LoadNumber(KEY_SELECTION, 1)
    local currentList   = {}

    -- Button references updated each time the window is built
    local trammelBtn  = nil
    local feluccaBtn  = nil
    local dungeonBtn  = nil
    local moongateBtn = nil
    local bankBtn     = nil
    local destLabel   = nil

    -- ====================================================================== --
    -- Helpers
    -- ====================================================================== --

    --- Returns true when the player has at least MAGERY_REQUIRED Magery skill.
    local function hasMagery()
        local skillsCSV = Data.SkillsCSV()
        local skillData = Data.SkillDynamicData()
        if skillsCSV == nil or skillData == nil then return false end
        local row = skillsCSV[MAGERY_SKILL_CSV_INDEX]
        if row == nil then return false end
        local entry = skillData[row.ServerId]
        if entry == nil then return false end
        return (entry.TempSkillValue / 10) >= MAGERY_REQUIRED
    end

    --- Builds the filtered destination list for the current facet/category.
    ---@return table
    local function buildList()
        local facetData
        if facet == 1 then
            facetData = Destinations.Trammel
        else
            facetData = Destinations.Felucca
        end

        local pool
        if category == 1 then
            pool = facetData.Dungeons
        elseif category == 2 then
            pool = facetData.Moongates
        else
            pool = facetData.Banks
        end

        local result = {}
        local mage   = hasMagery()
        for i = 1, #pool do
            local entry = pool[i]
            if entry.name == L"Wind" and not mage then
                -- Wind requires Magery >= 71.5
            else
                result[#result + 1] = entry
            end
        end
        return result
    end

    --- Clamps selectedIndex into [1, #currentList].
    local function clampSelection()
        if #currentList == 0 then
            selectedIndex = 1
            return
        end
        if selectedIndex < 1 then
            selectedIndex = 1
        elseif selectedIndex > #currentList then
            selectedIndex = #currentList
        end
    end

    --- Updates the destination label text with the current selection.
    --- Safe to call only after the window is fully initialized.
    local function refreshDestDisplay()
        if destLabel == nil then return end
        if #currentList == 0 then
            destLabel:setText(L"--")
        else
            destLabel:setText(currentList[selectedIndex].name)
        end
    end

    --- Applies the pressed/unpressed visual state to a toggle button.
    ---@param btn Button
    ---@param active boolean
    local function setActive(btn, active)
        if btn == nil then return end
        btn:setChecked(active)
    end

    --- Rebuilds the destination list and updates all toggle-button and label
    --- visuals. Safe to call only after all window children are initialized.
    local function onSelectionChanged()
        currentList   = buildList()
        clampSelection()
        refreshDestDisplay()
        setActive(trammelBtn,  facet == 1)
        setActive(feluccaBtn,  facet == 2)
        setActive(dungeonBtn,  category == 1)
        setActive(moongateBtn, category == 2)
        setActive(bankBtn,     category == 3)
    end

    -- ====================================================================== --
    -- Window factory (created on demand, destroyed on close)
    -- ====================================================================== --

    --- Builds the portal window component tree.
    --- currentList and selectedIndex must be up-to-date before calling.
    local function buildWindow()
        -- ------------------------------------------------------------------ --
        -- Row layout functions
        -- ------------------------------------------------------------------ --

        -- Facet row: two equal-width buttons side by side
        local function facetRowLayout(window, children, child, index)
            local dims = window:getDimensions()
            local btnW = (dims.x - GAP) / 2
            child:setDimensions(btnW, ROW_H)
            if index == 1 then
                child:addAnchor("topleft", window:getName(), "topleft", 0, 0)
            else
                child:addAnchor("topleft", children[1]:getName(), "topright", GAP, 0)
            end
        end

        -- Category row: three equal-width buttons side by side
        local function categoryRowLayout(window, children, child, index)
            local dims = window:getDimensions()
            local btnW = (dims.x - GAP * 2) / 3
            child:setDimensions(btnW, ROW_H)
            if index == 1 then
                child:addAnchor("topleft", window:getName(), "topleft", 0, 0)
            elseif index == 2 then
                child:addAnchor("topleft", children[1]:getName(), "topright", GAP, 0)
            else
                child:addAnchor("topleft", children[2]:getName(), "topright", GAP, 0)
            end
        end

        -- Destination row: [◄] | destination label | [►]
        local function destRowLayout(window, children, child, index)
            local dims   = window:getDimensions()
            local arrowW = 32
            local labelW = dims.x - (arrowW + GAP) * 2
            if index == 1 then
                child:setDimensions(arrowW, ROW_H)
                child:addAnchor("topleft", window:getName(), "topleft", 0, 0)
            elseif index == 2 then
                child:setDimensions(labelW, ROW_H)
                child:addAnchor("topleft", children[1]:getName(), "topright", GAP, 0)
            else
                child:setDimensions(arrowW, ROW_H)
                child:addAnchor("topleft", children[2]:getName(), "topright", GAP, 0)
            end
        end

        -- Root layout: title label + 4 rows stacked vertically
        local function rootLayout(_, children, child, index)
            if index == 1 then
                child:setDimensions(WINDOW_W - MARGIN * 2, 24)
                child:addAnchor("topleft", NAME, "topleft", MARGIN, MARGIN)
            elseif index == 2 then
                child:setDimensions(WINDOW_W - MARGIN * 2, ROW_H)
                child:addAnchor("topleft", children[1]:getName(), "bottomleft", 0, GAP)
            elseif index == 3 then
                child:setDimensions(WINDOW_W - MARGIN * 2, ROW_H)
                child:addAnchor("topleft", children[2]:getName(), "bottomleft", 0, GAP)
            elseif index == 4 then
                child:setDimensions(WINDOW_W - MARGIN * 2, ROW_H)
                child:addAnchor("topleft", children[3]:getName(), "bottomleft", 0, GAP)
            elseif index == 5 then
                child:setDimensions(WINDOW_W - MARGIN * 2, BTN_H)
                child:addAnchor("topleft", children[4]:getName(), "bottomleft", 0, GAP)
            end
        end

        -- ------------------------------------------------------------------ --
        -- Facet row (Trammel / Felucca)
        -- ------------------------------------------------------------------ --

        local facetRow = Components.Window {
            Resizable   = false,
            Snappable   = false,
            OnLayout    = facetRowLayout,
            OnRButtonUp = function() end,
        }

        trammelBtn = Components.Button {
            OnInitialize = function(self)
                self:setText(L"Trammel")
                self:setCheckButton(true)
                self:setChecked(facet == 1)
            end,
            OnLButtonUp = function()
                facet = 1
                onSelectionChanged()
            end,
        }

        feluccaBtn = Components.Button {
            OnInitialize = function(self)
                self:setText(L"Felucca")
                self:setCheckButton(true)
                self:setChecked(facet == 2)
            end,
            OnLButtonUp = function()
                facet = 2
                onSelectionChanged()
            end,
        }

        facetRow:setChildren { trammelBtn, feluccaBtn }

        -- ------------------------------------------------------------------ --
        -- Category row (Dungeons / Moongates / Banks)
        -- ------------------------------------------------------------------ --

        local categoryRow = Components.Window {
            Resizable   = false,
            Snappable   = false,
            OnLayout    = categoryRowLayout,
            OnRButtonUp = function() end,
        }

        dungeonBtn = Components.Button {
            OnInitialize = function(self)
                self:setText(L"Dungeons")
                self:setCheckButton(true)
                self:setChecked(category == 1)
            end,
            OnLButtonUp = function()
                category = 1
                onSelectionChanged()
            end,
        }

        moongateBtn = Components.Button {
            OnInitialize = function(self)
                self:setText(L"Moongates")
                self:setCheckButton(true)
                self:setChecked(category == 2)
            end,
            OnLButtonUp = function()
                category = 2
                onSelectionChanged()
            end,
        }

        bankBtn = Components.Button {
            OnInitialize = function(self)
                self:setText(L"Banks")
                self:setCheckButton(true)
                self:setChecked(category == 3)
            end,
            OnLButtonUp = function()
                category = 3
                onSelectionChanged()
            end,
        }

        categoryRow:setChildren { dungeonBtn, moongateBtn, bankBtn }

        -- ------------------------------------------------------------------ --
        -- Destination selector row: [◄]  Name  [►]
        -- ------------------------------------------------------------------ --

        local destRow = Components.Window {
            Resizable   = false,
            Snappable   = false,
            OnLayout    = destRowLayout,
            OnRButtonUp = function() end,
        }

        local prevBtn = Components.Button {
            OnInitialize = function(self)
                self:setText(L"<")
            end,
            OnLButtonUp = function()
                if #currentList == 0 then return end
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then selectedIndex = #currentList end
                refreshDestDisplay()
            end,
        }

        destLabel = Components.Label {
            OnInitialize = function(self)
                self:centerText()
                if #currentList > 0 then
                    self:setText(currentList[selectedIndex].name)
                else
                    self:setText(L"--")
                end
            end,
        }

        local nextBtn = Components.Button {
            OnInitialize = function(self)
                self:setText(L">")
            end,
            OnLButtonUp = function()
                if #currentList == 0 then return end
                selectedIndex = selectedIndex + 1
                if selectedIndex > #currentList then selectedIndex = 1 end
                refreshDestDisplay()
            end,
        }

        destRow:setChildren { prevBtn, destLabel, nextBtn }

        -- ------------------------------------------------------------------ --
        -- GO! button
        -- ------------------------------------------------------------------ --

        local goBtn = Components.Button {
            OnInitialize = function(self)
                self:setText(L"GO!")
            end,
            OnLButtonUp = function()
                if #currentList == 0 or selectedIndex < 1 or selectedIndex > #currentList then
                    return
                end

                local selection = currentList[selectedIndex]
                local cmd       = L""

                if facet == 2 then
                    cmd = L"fel "
                end

                if category == 1 then
                    cmd = cmd .. L"dungeon " .. selection.command
                elseif category == 2 then
                    cmd = cmd .. selection.command .. L" moongate"
                else
                    cmd = cmd .. selection.command .. L" mint"
                end

                Api.Interface.SaveNumber(KEY_MAP,       facet)
                Api.Interface.SaveNumber(KEY_AREA,      category)
                Api.Interface.SaveNumber(KEY_SELECTION, selectedIndex)

                Api.Chat.Send(cmd)
                Api.Window.Destroy(NAME)
            end,
        }

        -- ------------------------------------------------------------------ --
        -- Root window
        -- ------------------------------------------------------------------ --

        local titleLabel = Components.Label {
            OnInitialize = function(self)
                self:setText(Api.String.GetStringFromTid(1113945))
                self:centerText()
                self:setTextColor(Constants.Colors.YellowDark)
            end,
        }

        local window = Components.Window {
            Name      = NAME,
            Resizable = false,
            OnInitialize = function(self)
                self:setDimensions(WINDOW_W, WINDOW_H)
            end,
            OnLayout  = rootLayout,
        }

        window:setChildren {
            titleLabel,
            facetRow,
            categoryRow,
            destRow,
            goBtn,
        }

        return window
    end

    -- ====================================================================== --
    -- Toggle handler: intercept CrystalPortal.Toggle called by GumpsParsing
    -- when TID 1113945 is detected (gump ID 9083, label TID 1113945).
    -- ====================================================================== --

    -- Save the original Toggle for clean restoration on shutdown.
    -- getOriginalTable() exposes the raw table the proxy wraps.
    local originalTable = crystalPortalDefault:getOriginalTable()
    originalCrystalPortalToggle = originalTable and originalTable.Toggle or nil

    cpProxy.Toggle = function()
        if Api.Window.DoesExist(NAME) then
            -- Portal is open — persist state and close it
            Api.Interface.SaveNumber(KEY_MAP,       facet)
            Api.Interface.SaveNumber(KEY_AREA,      category)
            Api.Interface.SaveNumber(KEY_SELECTION, selectedIndex)
            Api.Window.Destroy(NAME)
        else
            -- Build the destination list and create the window on demand
            currentList   = buildList()
            clampSelection()
            buildWindow():create(true)
        end
    end
end

---@param context Context
local function OnShutdown(context)
    local Api        = context.Api
    local Components = context.Components

    -- Destroy our window if it is open
    Api.Window.Destroy(NAME)

    -- Restore the original CrystalPortal.Toggle so the default behavior
    -- works correctly if this mod is later re-enabled.
    if originalCrystalPortalToggle ~= nil then
        local cpProxy = Components.Defaults.CrystalPortal:getDefault()
        cpProxy.Toggle = originalCrystalPortalToggle
    end
end

Mongbat.Mod {
    Name         = "MongbatCrystalPortal",
    Path         = "/src/mods/mongbat-crystal-portal",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown,
}
