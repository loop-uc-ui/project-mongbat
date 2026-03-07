local NAME = "MongbatUserWaypointWindow"
local Api = Mongbat.Api
local Components = Mongbat.Components
local Utils = Mongbat.Utils

-- Window layout constants
local WIN_W = 460
local WIN_H = 360
local MARGIN = 12
local LABEL_W = 72
local INPUT_W = 140
local SMALL_BTN_W = 40
local SMALL_BTN_H = 24
local ICON_PREVIEW_W = 50
local ICON_PREVIEW_H = 50

-- Row Y positions (from top of window, below the frame header area)
local ROW1_Y = 36   -- Name
local ROW2_Y = 72   -- Icon selector
local ROW3_Y = 136  -- Scale (below icon preview area)
local ROW4_Y = 170  -- Facet
local ROW5_Y = 206  -- Coord toggle
local ROW6_Y = 242  -- Lat / X
local ROW7_Y = 278  -- Long / Y
local BTN_Y  = WIN_H - 44  -- OK / Cancel buttons

-- TIDs used by UserWaypointWindow
local TID = {
    Okay           = 3000093,
    Cancel         = 1006045,
    CreateWaypoint = 1155145,
    EditWaypoint   = 1155146,
    ViewWaypoint   = 1155147,
    Lat            = 1154915,
    Long           = 1154916,
    X              = 1155148,
    Y              = 1155149,
}

-- 61 predefined icon types (id + display name)
local ICONS = {
    { id = 100022, name = L"Custom" },
    { id = 100000, name = L"Danger" },
    { id = 100042, name = L"City" },
    { id = 100045, name = L"Dungeon" },
    { id = 100043, name = L"Bones" },
    { id = 100010, name = L"Yellow Dot" },
    { id = 100012, name = L"Healer" },
    { id = 100053, name = L"Moongate" },
    { id = 100018, name = L"Cross Weapons" },
    { id = 100059, name = L"Shop" },
    { id = 100060, name = L"Shrine" },
    { id = 100030, name = L"Flag" },
    { id = 100033, name = L"Alchemy" },
    { id = 100034, name = L"Baker" },
    { id = 100035, name = L"Bank" },
    { id = 100036, name = L"Barber" },
    { id = 100037, name = L"Bard" },
    { id = 100038, name = L"Blacksmith" },
    { id = 100039, name = L"Bowyer" },
    { id = 100040, name = L"Butcher" },
    { id = 100041, name = L"Carpenter" },
    { id = 100046, name = L"Fletcher" },
    { id = 100047, name = L"Guild" },
    { id = 100048, name = L"Healer Shop" },
    { id = 100049, name = L"Inn" },
    { id = 100050, name = L"Jeweler" },
    { id = 100051, name = L"Landmark" },
    { id = 100052, name = L"Mage" },
    { id = 100054, name = L"Painter" },
    { id = 100056, name = L"Provisioner" },
    { id = 100057, name = L"Reagents" },
    { id = 100058, name = L"Shipwright" },
    { id = 100061, name = L"Stables" },
    { id = 100062, name = L"Tailor" },
    { id = 100063, name = L"Tavern" },
    { id = 100064, name = L"Theater" },
    { id = 100065, name = L"Tinker" },
    { id = 100083, name = L"Black Pin" },
    { id = 100084, name = L"Blue Pin" },
    { id = 100085, name = L"Gold Skull Pin" },
    { id = 100086, name = L"Green Pin" },
    { id = 100087, name = L"Pink Pin" },
    { id = 100088, name = L"Purple Pin" },
    { id = 100089, name = L"Red Pin" },
    { id = 100090, name = L"Yellow Pin" },
    { id = 100106, name = L"Boat" },
    { id = 100107, name = L"Cemetery" },
    { id = 100108, name = L"Customs" },
    { id = 100109, name = L"Dock" },
    { id = 100110, name = L"Eye" },
    { id = 100111, name = L"Gate" },
    { id = 100112, name = L"Leather" },
    { id = 100113, name = L"Mark" },
    { id = 100114, name = L"Party" },
    { id = 100115, name = L"Pillar" },
    { id = 100116, name = L"Sink" },
    { id = 100117, name = L"Stairs" },
    { id = 100118, name = L"Target" },
    { id = 100119, name = L"Teleporter" },
    { id = 100120, name = L"Waves" },
    { id = 100121, name = L"X" },
}

local SCALE_MIN  = 0.2
local SCALE_MAX  = 2.0
local SCALE_STEP = 0.2

-- WaypointCustomType from MapCommon (= 15)
local WAYPOINT_CUSTOM_TYPE = 15

-- Saved original functions for restore on shutdown
local savedFunctions = {}

--- Rounds a number to one decimal place.
---@param v number
---@return number
local function roundScale(v)
    return math.floor(v * 10 + 0.5) / 10
end

--- Creates and shows the User Waypoint window.
---@param context Context The Mongbat context object.
---@param params table  Params table from the map context menu.
---@param isViewMode boolean True for view/edit mode, false for create mode.
local function createWaypointWindow(params, isViewMode)
    local Components = Components
    local Api        = Api
    local Utils      = Utils

    --- Finds the icon index in ICONS for a given icon ID.
    ---@param iconId number The icon ID to search for.
    ---@return number index 1-based index into ICONS, or 1 if not found.
    local function findIconIndex(iconId)
        local idx = Utils.Array.IndexOf(ICONS, function(icon) return icon.id == iconId end)
        if idx == -1 then return 1 end
        return idx
    end

    --- Extracts the display name from an encoded waypoint name string.
    --- Strips _ICON_, _SCALE_, _DUNG_, _ABYSS_ metadata suffixes.
    ---@param encodedName wstring The encoded name from the engine.
    ---@return wstring The display name without metadata.
    local function extractDisplayName(encodedName)
        if not encodedName or encodedName == L"" then
            return L""
        end
        local s = Api.String.WStringToString(encodedName)
        -- Strip everything from _ICON_ onwards
        local displayPart = string.match(s, "^(.-)_ICON_") or s
        return Api.String.StringToWString(displayPart)
    end

    --- Parses the icon ID from an encoded waypoint name string.
    ---@param encodedName wstring The encoded name.
    ---@return number|nil The icon ID, or nil if not found.
    local function parseIconId(encodedName)
        if not encodedName or encodedName == L"" then
            return nil
        end
        local s = Api.String.WStringToString(encodedName)
        local idStr = string.match(s, "_ICON_(%d+)")
        if idStr then
            return tonumber(idStr)
        end
        return nil
    end

    -- Per-window state
    local iconIndex = 1
    local iconScale = 1.0
    local useXY     = false
    local latDir    = L"N"
    local longDir   = L"W"

    -- Resolve initial state from params
    if isViewMode then
        iconScale = params.scale or 1.0
        local iconId = parseIconId(params.name)
        if iconId then
            iconIndex = findIconIndex(iconId)
        elseif params.type then
            -- Fall back: treat params.type as icon index when in range
            if params.type >= 1 and params.type <= #ICONS then
                iconIndex = params.type
            end
        end
    end

    -- Determine initial coordinate mode based on area and facet
    local facetId = params.facet or params.facetId or Api.Radar.GetFacet()
    local radarArea = Api.Radar.GetArea() or 0
    -- Use X/Y mode for non-standard areas (lost lands, custom facets)
    -- mirrors default UI: show X/Y when area > 0 and not Felucca/Trammel standard
    local isFeluccaLostLand = (facetId == 0 and radarArea == 14)
    local isTrammelLostLand = (facetId == 1 and radarArea == 13)
    useXY = radarArea > 0 and not isFeluccaLostLand and not isTrammelLostLand and facetId > 1

    -- Child view references populated during OnInitialize callbacks
    local titleLbl
    local nameInput
    local nameDisp
    local iconNameLbl
    local iconPreview
    local scaleValueLbl
    local facetValueLbl
    local coordToggleBtn
    local latPromptLbl
    local latInput
    local latDirBtn
    local longPromptLbl
    local longInput
    local longDirBtn
    local xPromptLbl
    local xInput
    local yPromptLbl
    local yInput
    local okBtn
    local cancelBtn

    -- Child indices
    local IDX_TITLE        = 1
    local IDX_NAME_INPUT   = 2
    local IDX_NAME_DISP    = 3
    local IDX_ICON_LABEL   = 4
    local IDX_ICON_PREV    = 5
    local IDX_ICON_NAME    = 6
    local IDX_ICON_NEXT    = 7
    local IDX_ICON_PREVIEW = 8
    local IDX_SCALE_LABEL  = 9
    local IDX_SCALE_VALUE  = 10
    local IDX_SCALE_UP     = 11
    local IDX_SCALE_DOWN   = 12
    local IDX_FACET_LABEL  = 13
    local IDX_FACET_VALUE  = 14
    local IDX_COORD_TOGGLE = 15
    local IDX_LAT_PROMPT   = 16
    local IDX_LAT_INPUT    = 17
    local IDX_LAT_DIR      = 18
    local IDX_LONG_PROMPT  = 19
    local IDX_LONG_INPUT   = 20
    local IDX_LONG_DIR     = 21
    local IDX_X_PROMPT     = 22
    local IDX_X_INPUT      = 23
    local IDX_Y_PROMPT     = 24
    local IDX_Y_INPUT      = 25
    local IDX_OK           = 26
    local IDX_CANCEL       = 27
    local IDX_NAME_LABEL   = 28

    --- Updates the icon DynamicImage and name label to reflect the current iconIndex.
    local function updateIconDisplay()
        if not iconPreview or not iconNameLbl then return end
        local icon = ICONS[iconIndex]
        iconNameLbl:setText(icon.name)
        local tex, tx, ty = Api.Icon.GetIconData(icon.id)
        local iconW, iconH = Api.Icon.GetTextureSize("icon" .. icon.id)
        if tex and iconW and iconH then
            iconPreview:setTextureDimensions(iconW, iconH)
            iconPreview:setDimensions(iconW * iconScale, iconH * iconScale)
            iconPreview:setTexture(tex, tx, ty)
        end
    end

    --- Updates scale value label text.
    local function updateScaleLabel()
        if scaleValueLbl then
            scaleValueLbl:setText(tostring(roundScale(iconScale)))
        end
    end

    --- Fills coordinate input fields from x, y, facet values.
    ---@param x number
    ---@param y number
    ---@param facet number
    local function fillCoordFields(x, y, facet)
        local latStr, longStr, ld, lgd =
            Api.Coord.GetSextantLocationStrings(x, y, facet)
        latDir  = ld  or L"N"
        longDir = lgd or L"W"
        if latInput  then latInput:setText(latStr) end
        if longInput then longInput:setText(longStr) end
        if latDirBtn  then latDirBtn:setText(latDir) end
        if longDirBtn then longDirBtn:setText(longDir) end
        if xInput then
            xInput:setText(tostring(math.floor(x + 0.5)))
        end
        if yInput then
            yInput:setText(tostring(math.floor(y + 0.5)))
        end
    end

    --- Shows/hides the coordinate rows based on the current useXY flag.
    local function applyCoordMode()
        local showLatLong = not useXY
        local showXY      = useXY
        if latPromptLbl  then latPromptLbl:setShowing(showLatLong) end
        if latInput      then latInput:setShowing(showLatLong) end
        if latDirBtn     then latDirBtn:setShowing(showLatLong and not isViewMode) end
        if longPromptLbl then longPromptLbl:setShowing(showLatLong) end
        if longInput     then longInput:setShowing(showLatLong) end
        if longDirBtn    then longDirBtn:setShowing(showLatLong and not isViewMode) end
        if xPromptLbl    then xPromptLbl:setShowing(showXY) end
        if xInput        then xInput:setShowing(showXY) end
        if yPromptLbl    then yPromptLbl:setShowing(showXY) end
        if yInput        then yInput:setShowing(showXY) end
    end

    --- Toggles between Lat/Long and X/Y coordinate display, converting values.
    local function toggleCoordMode()
        local area = Api.Radar.GetArea() or 0
        if not useXY then
            -- Convert current Lat/Long inputs to X/Y
            local latVal  = tonumber(Api.String.WStringToString(latInput:getText()))  or 0
            local longVal = tonumber(Api.String.WStringToString(longInput:getText())) or 0
            local nx, ny = Api.Coord.ConvertToXYMinutes(
                latVal, longVal, latDir, longDir, facetId, area
            )
            params.x = nx
            params.y = ny
            if xInput then xInput:setText(tostring(math.floor(nx + 0.5))) end
            if yInput then yInput:setText(tostring(math.floor(ny + 0.5))) end
            useXY = true
        else
            -- Convert current X/Y inputs to Lat/Long
            local x = tonumber(Api.String.WStringToString(xInput:getText())) or 0
            local y = tonumber(Api.String.WStringToString(yInput:getText())) or 0
            params.x = x
            params.y = y
            fillCoordFields(x, y, facetId)
            useXY = false
        end
        applyCoordMode()
    end

    --- Handles OK button: encodes name + metadata and creates waypoint.
    local function onOkay()
        if isViewMode then
            Api.Window.Destroy(NAME)
            return
        end

        local name = nameInput:getText()
        if not name or name == L"" then return end

        local x, y
        local area = Api.Radar.GetArea() or 0
        if useXY then
            x = tonumber(Api.String.WStringToString(xInput:getText())) or 0
            y = tonumber(Api.String.WStringToString(yInput:getText())) or 0
        else
            local latVal  = tonumber(Api.String.WStringToString(latInput:getText()))  or 0
            local longVal = tonumber(Api.String.WStringToString(longInput:getText())) or 0
            x, y = Api.Coord.ConvertToXYMinutes(
                latVal, longVal, latDir, longDir, facetId, area
            )
        end

        local icon     = ICONS[iconIndex]
        local scaleInt = math.floor(iconScale * 10 + 0.5)

        -- Build encoded name: WaypointName_ICON_xxx_SCALE_yyy[_DUNG_][_ABYSS_]
        local nameStr = Api.String.WStringToString(name)
        nameStr = nameStr .. "_ICON_" .. tostring(icon.id)
        nameStr = nameStr .. "_SCALE_" .. tostring(scaleInt)
        if params.isDungeon then
            nameStr = nameStr .. "_DUNG_"
        end
        if params.isAbyss then
            nameStr = nameStr .. "_ABYSS_"
        end

        Api.Waypoint.Create(
            params.type or WAYPOINT_CUSTOM_TYPE,
            facetId,
            x,
            y,
            Api.String.StringToWString(nameStr)
        )

        Api.Window.Destroy(NAME)
    end

    --- Custom layout: positions each child by its index.
    ---@param win Window
    ---@param _ table
    ---@param child View
    ---@param index number
    local function layoutChild(win, _, child, index)
        local wn = win:getName()
        child:clearAnchors()

        -- Helper: anchor top-left relative to the window
        local function tl(x, y)
            child:addAnchor("topleft", wn, "topleft", x, y)
        end

        if index == IDX_TITLE then
            tl(MARGIN, MARGIN)

        elseif index == IDX_NAME_INPUT or index == IDX_NAME_DISP then
            tl(MARGIN + LABEL_W, ROW1_Y)

        elseif index == IDX_ICON_LABEL then
            tl(MARGIN, ROW2_Y + 4)

        elseif index == IDX_ICON_PREV then
            tl(MARGIN + LABEL_W, ROW2_Y)

        elseif index == IDX_ICON_NAME then
            tl(MARGIN + LABEL_W + SMALL_BTN_W + 4, ROW2_Y + 4)

        elseif index == IDX_ICON_NEXT then
            tl(MARGIN + LABEL_W + SMALL_BTN_W + 100 + 4, ROW2_Y)

        elseif index == IDX_ICON_PREVIEW then
            tl(WIN_W - MARGIN - ICON_PREVIEW_W - 20, ROW2_Y)

        elseif index == IDX_SCALE_LABEL then
            tl(MARGIN, ROW3_Y + 4)

        elseif index == IDX_SCALE_DOWN then
            tl(MARGIN + LABEL_W, ROW3_Y)

        elseif index == IDX_SCALE_VALUE then
            tl(MARGIN + LABEL_W + SMALL_BTN_W + 4, ROW3_Y + 4)

        elseif index == IDX_SCALE_UP then
            tl(MARGIN + LABEL_W + SMALL_BTN_W + 40 + 4, ROW3_Y)

        elseif index == IDX_FACET_LABEL then
            tl(MARGIN, ROW4_Y + 4)

        elseif index == IDX_FACET_VALUE then
            tl(MARGIN + LABEL_W, ROW4_Y + 4)

        elseif index == IDX_COORD_TOGGLE then
            tl(MARGIN, ROW5_Y)

        elseif index == IDX_LAT_PROMPT then
            tl(MARGIN, ROW6_Y + 4)

        elseif index == IDX_LAT_INPUT then
            tl(MARGIN + LABEL_W, ROW6_Y)

        elseif index == IDX_LAT_DIR then
            tl(MARGIN + LABEL_W + INPUT_W + 4, ROW6_Y)

        elseif index == IDX_LONG_PROMPT then
            tl(MARGIN, ROW7_Y + 4)

        elseif index == IDX_LONG_INPUT then
            tl(MARGIN + LABEL_W, ROW7_Y)

        elseif index == IDX_LONG_DIR then
            tl(MARGIN + LABEL_W + INPUT_W + 4, ROW7_Y)

        elseif index == IDX_X_PROMPT then
            tl(MARGIN, ROW6_Y + 4)

        elseif index == IDX_X_INPUT then
            tl(MARGIN + LABEL_W, ROW6_Y)

        elseif index == IDX_Y_PROMPT then
            tl(MARGIN, ROW7_Y + 4)

        elseif index == IDX_Y_INPUT then
            tl(MARGIN + LABEL_W, ROW7_Y)

        elseif index == IDX_OK then
            tl(MARGIN, BTN_Y)

        elseif index == IDX_CANCEL then
            tl(WIN_W - MARGIN - 100, BTN_Y)

        elseif index == IDX_NAME_LABEL then
            tl(MARGIN, ROW1_Y + 4)
        end
    end

    -- Build all children
    local children = {}

    -- [1] Title label
    titleLbl = Components.Label {
        Template = "MongbatLabel",
        OnInitialize = function(self)
            titleLbl = self
            self:setDimensions(WIN_W - MARGIN * 2 - 20, 20)
            self:centerText()
        end,
    }
    children[IDX_TITLE] = titleLbl

    -- [2] Name EditTextBox (create mode)
    nameInput = Components.EditTextBox {
        OnInitialize = function(self)
            nameInput = self
            self:setDimensions(INPUT_W, SMALL_BTN_H)
        end,
        OnKeyEnter = function(self)
            onOkay()
        end,
        OnKeyEscape = function(self)
            Api.Window.Destroy(NAME)
        end,
    }
    children[IDX_NAME_INPUT] = nameInput

    -- [3] Name Label (view mode)
    nameDisp = Components.Label {
        Template = "MongbatLabel",
        OnInitialize = function(self)
            nameDisp = self
            self:setDimensions(INPUT_W, SMALL_BTN_H)
        end,
    }
    children[IDX_NAME_DISP] = nameDisp

    -- [4] "Icon" prompt
    children[IDX_ICON_LABEL] = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            self:setDimensions(LABEL_W, 16)
            self:setText(L"Icon")
        end,
    }

    -- [5] Icon Prev button
    children[IDX_ICON_PREV] = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            self:setDimensions(SMALL_BTN_W, SMALL_BTN_H)
            self:setText(L"<")
        end,
        OnLButtonUp = function(self)
            iconIndex = iconIndex - 1
            if iconIndex < 1 then iconIndex = #ICONS end
            updateIconDisplay()
        end,
    }

    -- [6] Icon name label
    iconNameLbl = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            iconNameLbl = self
            self:setDimensions(96, 16)
        end,
    }
    children[IDX_ICON_NAME] = iconNameLbl

    -- [7] Icon Next button
    children[IDX_ICON_NEXT] = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            self:setDimensions(SMALL_BTN_W, SMALL_BTN_H)
            self:setText(L">")
        end,
        OnLButtonUp = function(self)
            iconIndex = iconIndex + 1
            if iconIndex > #ICONS then iconIndex = 1 end
            updateIconDisplay()
        end,
    }

    -- [8] Icon preview DynamicImage
    iconPreview = Components.DynamicImage {
        OnInitialize = function(self)
            iconPreview = self
            self:setDimensions(ICON_PREVIEW_W, ICON_PREVIEW_H)
        end,
    }
    children[IDX_ICON_PREVIEW] = iconPreview

    -- [9] "Scale" prompt
    children[IDX_SCALE_LABEL] = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            self:setDimensions(LABEL_W, 16)
            self:setText(L"Scale")
        end,
    }

    -- [10] Scale value label
    scaleValueLbl = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            scaleValueLbl = self
            self:setDimensions(36, 16)
        end,
    }
    children[IDX_SCALE_VALUE] = scaleValueLbl

    -- [11] Scale Up (+) button
    children[IDX_SCALE_UP] = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            self:setDimensions(SMALL_BTN_W, SMALL_BTN_H)
            self:setText(L"+")
        end,
        OnLButtonUp = function(self)
            iconScale = math.min(roundScale(iconScale + SCALE_STEP), SCALE_MAX)
            updateScaleLabel()
            updateIconDisplay()
        end,
    }

    -- [12] Scale Down (-) button
    children[IDX_SCALE_DOWN] = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            self:setDimensions(SMALL_BTN_W, SMALL_BTN_H)
            self:setText(L"-")
        end,
        OnLButtonUp = function(self)
            iconScale = math.max(roundScale(iconScale - SCALE_STEP), SCALE_MIN)
            updateScaleLabel()
            updateIconDisplay()
        end,
    }

    -- [13] Facet prompt label
    children[IDX_FACET_LABEL] = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            self:setDimensions(LABEL_W, 16)
            self:setText(L"Facet")
        end,
    }

    -- [14] Facet value label
    facetValueLbl = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            facetValueLbl = self
            self:setDimensions(WIN_W - MARGIN * 2 - LABEL_W, 16)
        end,
    }
    children[IDX_FACET_VALUE] = facetValueLbl

    -- [15] Coord toggle button (hidden when only X/Y is available)
    coordToggleBtn = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            coordToggleBtn = self
            self:setDimensions(140, SMALL_BTN_H)
            self:setText(L"Lat/Long \xab\xbb X/Y")
        end,
        OnLButtonUp = function(self)
            toggleCoordMode()
        end,
    }
    children[IDX_COORD_TOGGLE] = coordToggleBtn

    -- [16] Lat prompt label
    latPromptLbl = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            latPromptLbl = self
            self:setDimensions(LABEL_W, 16)
            self:setText(Api.String.GetStringFromTid(TID.Lat))
        end,
    }
    children[IDX_LAT_PROMPT] = latPromptLbl

    -- [17] Lat input / display
    latInput = Components.EditTextBox {
        OnInitialize = function(self)
            latInput = self
            self:setDimensions(INPUT_W, SMALL_BTN_H)
        end,
        OnKeyEnter = function(self)
            onOkay()
        end,
    }
    children[IDX_LAT_INPUT] = latInput

    -- [18] Lat direction toggle button (N/S)
    latDirBtn = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            latDirBtn = self
            self:setDimensions(SMALL_BTN_W, SMALL_BTN_H)
            self:setText(latDir)
        end,
        OnLButtonUp = function(self)
            if Api.String.WStringToString(latDir) == "N" then
                latDir = L"S"
            else
                latDir = L"N"
            end
            self:setText(latDir)
        end,
    }
    children[IDX_LAT_DIR] = latDirBtn

    -- [19] Long prompt label
    longPromptLbl = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            longPromptLbl = self
            self:setDimensions(LABEL_W, 16)
            self:setText(Api.String.GetStringFromTid(TID.Long))
        end,
    }
    children[IDX_LONG_PROMPT] = longPromptLbl

    -- [20] Long input / display
    longInput = Components.EditTextBox {
        OnInitialize = function(self)
            longInput = self
            self:setDimensions(INPUT_W, SMALL_BTN_H)
        end,
        OnKeyEnter = function(self)
            onOkay()
        end,
    }
    children[IDX_LONG_INPUT] = longInput

    -- [21] Long direction toggle button (E/W)
    longDirBtn = Components.Button {
        Template = "MongbatButton18",
        OnInitialize = function(self)
            longDirBtn = self
            self:setDimensions(SMALL_BTN_W, SMALL_BTN_H)
            self:setText(longDir)
        end,
        OnLButtonUp = function(self)
            if Api.String.WStringToString(longDir) == "W" then
                longDir = L"E"
            else
                longDir = L"W"
            end
            self:setText(longDir)
        end,
    }
    children[IDX_LONG_DIR] = longDirBtn

    -- [22] X prompt label
    xPromptLbl = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            xPromptLbl = self
            self:setDimensions(LABEL_W, 16)
            self:setText(Api.String.GetStringFromTid(TID.X))
        end,
    }
    children[IDX_X_PROMPT] = xPromptLbl

    -- [23] X input
    xInput = Components.EditTextBox {
        OnInitialize = function(self)
            xInput = self
            self:setDimensions(INPUT_W, SMALL_BTN_H)
        end,
        OnKeyEnter = function(self)
            onOkay()
        end,
    }
    children[IDX_X_INPUT] = xInput

    -- [24] Y prompt label
    yPromptLbl = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            yPromptLbl = self
            self:setDimensions(LABEL_W, 16)
            self:setText(Api.String.GetStringFromTid(TID.Y))
        end,
    }
    children[IDX_Y_PROMPT] = yPromptLbl

    -- [25] Y input
    yInput = Components.EditTextBox {
        OnInitialize = function(self)
            yInput = self
            self:setDimensions(INPUT_W, SMALL_BTN_H)
        end,
        OnKeyEnter = function(self)
            onOkay()
        end,
    }
    children[IDX_Y_INPUT] = yInput

    -- [26] OK button
    okBtn = Components.Button {
        Template = "MongbatButton",
        OnInitialize = function(self)
            okBtn = self
            self:setDimensions(100, 28)
            self:setText(Api.String.GetStringFromTid(TID.Okay))
        end,
        OnLButtonUp = function(self)
            onOkay()
        end,
    }
    children[IDX_OK] = okBtn

    -- [27] Cancel button
    cancelBtn = Components.Button {
        Template = "MongbatButton",
        OnInitialize = function(self)
            cancelBtn = self
            self:setDimensions(100, 28)
            self:setText(Api.String.GetStringFromTid(TID.Cancel))
        end,
        OnLButtonUp = function(self)
            Api.Window.Destroy(NAME)
        end,
    }
    children[IDX_CANCEL] = cancelBtn

    -- [28] Name prompt label
    children[IDX_NAME_LABEL] = Components.Label {
        Template = "MongbatLabelSmall",
        OnInitialize = function(self)
            self:setDimensions(LABEL_W, 16)
            self:setText(L"Name")
        end,
    }

    -- Build and create the window
    local window = Components.Window {
        Name = NAME,
        Resizable = false,
        OnInitialize = function(self)
            self:setDimensions(WIN_W, WIN_H)
            self:setChildren(children)
        end,
        OnLayout = layoutChild,
    }
    window:create(true)

    -- Post-creation setup: initialise display state
    -- Title
    local titleTid
    if isViewMode then
        titleTid = TID.ViewWaypoint
    else
        titleTid = TID.CreateWaypoint
    end
    titleLbl:setText(Api.String.GetStringFromTid(titleTid))

    -- Name field: show/hide based on mode
    nameInput:setShowing(not isViewMode)
    nameDisp:setShowing(isViewMode)
    if isViewMode then
        nameDisp:setText(extractDisplayName(params.name))
    end

    -- In view mode hide icon Prev/Next and scale +/- buttons
    if isViewMode then
        children[IDX_ICON_PREV]:setShowing(false)
        children[IDX_ICON_NEXT]:setShowing(false)
        children[IDX_SCALE_UP]:setShowing(false)
        children[IDX_SCALE_DOWN]:setShowing(false)
        okBtn:setShowing(false)
    end

    -- Facet label
    local facetTid = Api.Radar.GetFacetLabel(facetId)
    if facetTid then
        facetValueLbl:setText(Api.String.GetStringFromTid(facetTid))
    else
        facetValueLbl:setText(L"")
    end

    -- Icon display
    updateIconDisplay()

    -- Scale label
    updateScaleLabel()

    -- Coordinate toggle: always show (allows switching between Lat/Long and X/Y)
    coordToggleBtn:setShowing(true)

    -- Apply initial coord mode and fill fields
    applyCoordMode()
    if params.x and params.y then
        fillCoordFields(params.x, params.y, facetId)
    end
end

-- ============================================================
-- OnInitialize / OnShutdown
-- ============================================================

local function OnInitialize()
    local proxy = Components.Defaults.UserWaypointWindow:getDefault()

    -- Save originals for symmetric restore
    savedFunctions = {
        Initialize                 = proxy.Initialize,
        Shutdown                   = proxy.Shutdown,
        InitializeCreateWaypointData = proxy.InitializeCreateWaypointData,
        InitializeViewWaypointData   = proxy.InitializeViewWaypointData,
    }

    -- Suppress default window lifecycle (Initialize/Shutdown set up the raw
    -- XML window; our mod does not load that XML so these become no-ops anyway,
    -- but overriding them avoids unintended side-effects on hot-reload).
    proxy.Initialize = function() end
    proxy.Shutdown   = function() end

    -- Override the two entry-points the map calls to open the window
    proxy.InitializeCreateWaypointData = function(params)
        Api.Window.Destroy(NAME)
        createWaypointWindow(params, false)
    end

    proxy.InitializeViewWaypointData = function(params)
        Api.Window.Destroy(NAME)
        createWaypointWindow(params, true)
    end

    -- Hide the original XML window if the engine created it at startup
    if Api.Window.DoesExist("UserWaypointWindow") then
        Api.Window.SetShowing("UserWaypointWindow", false)
    end
end

local function OnShutdown()
    Api.Window.Destroy(NAME)

    -- Restore all overridden functions so the default UI can work again
    local proxy = Components.Defaults.UserWaypointWindow:getDefault()
    proxy.Initialize                   = savedFunctions.Initialize
    proxy.Shutdown                     = savedFunctions.Shutdown
    proxy.InitializeCreateWaypointData = savedFunctions.InitializeCreateWaypointData
    proxy.InitializeViewWaypointData   = savedFunctions.InitializeViewWaypointData
    savedFunctions = {}
end

Mongbat.Mod {
    Name         = "MongbatUserWaypoint",
    Path         = "/src/mods/mongbat-user-waypoint",
    OnInitialize = OnInitialize,
    OnShutdown   = OnShutdown,
}
