local NAME = "MongbatPetWindow"
local ROW_WIDTH = 200
local PADDING = 8
local HEADER_HEIGHT = 24
local TOGGLE_W = 22
local LABEL_HEIGHT = 14
local BAR_HEIGHT = 12
local ROW_HEIGHT = 2 + LABEL_HEIGHT + 2 + BAR_HEIGHT + 2
local ROW_GAP = 4

--- Layout for the main window: HeaderLabel at top-left, ToggleButton at top-right.
local function MainLayout(window, _, child, index)
    child:clearAnchors()
    local winName = window:getName()
    if index == 1 then
        child:addAnchor("topleft", winName, "topleft", PADDING, PADDING)
    elseif index == 2 then
        local w = window:getDimensions().x
        child:addAnchor("topleft", winName, "topleft", w - PADDING - TOGGLE_W, PADDING)
    end
end

--- Layout for a pet row: PetNameLabel at top, PetHealthBar below it.
local function PetRowLayout(window, _, child, index)
    child:clearAnchors()
    local winName = window:getName()
    if index == 1 then
        child:addAnchor("topleft", winName, "topleft", PADDING, 2)
    elseif index == 2 then
        child:addAnchor("topleft", winName, "topleft", PADDING, 2 + LABEL_HEIGHT + 2)
    end
end

---@param context Context
local function OnInitialize(context)
    local Api = context.Api
    local Data = context.Data
    local Constants = context.Constants
    local Components = context.Components

    local petRowsByPetId = {}
    local isExpanded = true

    local petWindowDefault = Components.Defaults.PetWindow
    petWindowDefault:asComponent():setShowing(false)
    petWindowDefault:disable()

    --- Destroys all current pet row windows and clears the tracking table.
    local function DestroyPetRows()
        for _, row in pairs(petRowsByPetId) do
            row:destroy()
        end
        petRowsByPetId = {}
    end

    --- Creates the Label (pet name) component for a pet row.
    ---@param petId integer
    ---@return Label
    local function PetNameLabel(petId)
        return Components.Label {
            Name = NAME .. "Name" .. petId,
            OnInitialize = function(self)
                self:setDimensions(ROW_WIDTH, LABEL_HEIGHT)
                self:setId(petId)
            end,
            OnUpdateMobileName = function(self, mobileName)
                self:setText(mobileName:getName())
            end,
            OnUpdateMobileStatus = function(self, mobileStatus)
                self:setTextColor(mobileStatus:getNotorietyColor())
            end
        }
    end

    --- Creates the StatusBar (pet health) component for a pet row.
    ---@param petId integer
    ---@return StatusBar
    local function PetHealthBar(petId)
        return Components.StatusBar(
            {
                Name = NAME .. "Health" .. petId,
                OnInitialize = function(self)
                    self:setDimensions(ROW_WIDTH, BAR_HEIGHT)
                    self:setId(petId)
                    self:setColor(Constants.Colors.HealhBar[1])
                end,
                OnUpdateMobileStatus = function(self, mobileStatus)
                    self:setCurrentValue(mobileStatus:getCurrentHealth())
                    self:setMaxValue(mobileStatus:getMaxHealth())
                end,
                OnUpdateHealthBarColor = function(self, healthBarColor)
                    self:setColor(healthBarColor:getVisualStateColor())
                end
            },
            {
                Name = NAME .. "HealthLabel" .. petId,
                OnUpdateMobileStatus = function(self, mobileStatus)
                    self:setText(
                        string.format(
                            "%d / %d",
                            mobileStatus:getCurrentHealth(),
                            mobileStatus:getMaxHealth()
                        )
                    )
                end
            }
        )
    end

    --- Creates and returns a pet row Window for the given pet ID.
    ---@param petId integer
    ---@return Window
    local function PetRow(petId)
        return Components.Window {
            Name = NAME .. "Row" .. petId,
            Resizable = false,
            Snappable = false,
            OnLayout = PetRowLayout,
            OnInitialize = function(self)
                self:setDimensions(ROW_WIDTH + PADDING * 2, ROW_HEIGHT)
                self:setChildren {
                    PetNameLabel(petId),
                    PetHealthBar(petId)
                }
            end,
            OnLButtonUp = function()
                if Data.Drag():isDraggingItem() then
                    Api.Drag.DragToObject(petId)
                else
                    Api.Target.LeftClick(petId)
                end
            end,
            OnRButtonUp = function() end
        }
    end

    --- Rebuilds all pet row windows from the current pet list.
    --- Destroys existing rows first, then creates a new row per pet.
    ---@param pets PetsWrapper
    local function RebuildPetRows(pets)
        DestroyPetRows()
        if not isExpanded then return end

        local petIds = pets:getPetIds()
        local count = table.getn(petIds)
        local prevAnchor = NAME

        for i = 1, count do
            local petId = petIds[i]
            local row = PetRow(petId)
            row:create(false)
            row:clearAnchors()
            row:addAnchor("bottomleft", prevAnchor, "topleft", 0, ROW_GAP)
            row:setShowing(true)
            petRowsByPetId[petId] = row
            prevAnchor = row:getName()
        end
    end

    --- The header label showing "Pets [x/y]".
    local function HeaderLabel()
        return Components.Label {
            Name = NAME .. "Header",
            OnInitialize = function(self)
                self:setDimensions(ROW_WIDTH - TOGGLE_W, HEADER_HEIGHT)
                self:setText(L"Pets")
            end,
            OnUpdatePlayerStatus = function(self, playerStatus)
                local data = playerStatus:getData()
                local followers = data.Followers or 0
                local maxFollowers = data.MaxFollowers or 0
                self:setText(
                    L"Pets [" .. towstring(followers) .. L"/" .. towstring(maxFollowers) .. L"]"
                )
            end
        }
    end

    --- The toggle button for expanding/collapsing the pet list.
    local function ToggleButton()
        return Components.Button {
            Name = NAME .. "Toggle",
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(TOGGLE_W, HEADER_HEIGHT)
                self:setText(L"-")
            end,
            OnLButtonUp = function(self)
                isExpanded = not isExpanded
                if isExpanded then
                    self:setText(L"-")
                    RebuildPetRows(Data.Pets())
                else
                    self:setText(L"+")
                    DestroyPetRows()
                end
            end
        }
    end

    --- The main pet window containing the header and toggle button.
    local function Window()
        return Components.Window {
            Name = NAME,
            Resizable = false,
            OnLayout = MainLayout,
            OnInitialize = function(self)
                self:setDimensions(ROW_WIDTH + PADDING * 2, HEADER_HEIGHT + PADDING * 2)
                self:setChildren {
                    HeaderLabel(),
                    ToggleButton()
                }
            end,
            OnUpdatePets = function(_, pets)
                RebuildPetRows(pets)
            end,
            OnShutdown = function()
                DestroyPetRows()
            end,
            OnRButtonUp = function() end
        }
    end

    Window():create(true)
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.Destroy(NAME)
    local petWindowDefault = context.Components.Defaults.PetWindow
    petWindowDefault:restore()
    petWindowDefault:asComponent():setShowing(true)
end

Mongbat.Mod {
    Name = "MongbatPetWindow",
    Path = "/src/mods/mongbat-pet-window",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
