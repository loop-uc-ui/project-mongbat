local NAME = "MongbatPetWindow"
local ROW_HEIGHT = 28
local ROW_WIDTH = 200
local HEADER_HEIGHT = 24
local ROW_GAP = 2

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
                self:setDimensions(ROW_WIDTH - 4, 14)
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
                    self:setDimensions(ROW_WIDTH - 4, 12)
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
    --- The window is a root-level window; after create() the caller is
    --- responsible for clearing anchors and positioning the row.
    ---@param petId integer
    ---@return Window
    local function PetRow(petId)
        return Components.Window {
            Name = NAME .. "Row" .. petId,
            Resizable = false,
            Snappable = false,
            OnInitialize = function(self)
                self:setDimensions(ROW_WIDTH + 16, ROW_HEIGHT)
                self:setChildren {
                    PetNameLabel(petId),
                    PetHealthBar(petId)
                }
            end,
            OnLButtonUp = function()
                Api.Target.LeftClick(petId)
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
            row:addAnchor("topleft", prevAnchor, "bottomleft", 0, ROW_GAP)
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
                self:setDimensions(ROW_WIDTH - 30, HEADER_HEIGHT)
                self:centerText()
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
        local btn = Components.Button {
            Name = NAME .. "Toggle",
            Template = "MongbatButton18",
            OnInitialize = function(self)
                self:setDimensions(22, HEADER_HEIGHT)
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
        return btn
    end

    --- The main pet window containing the header and toggle button.
    local function Window()
        return Components.Window {
            Name = NAME,
            Resizable = false,
            OnInitialize = function(self)
                self:setDimensions(ROW_WIDTH + 16, HEADER_HEIGHT + 16)
                self:setChildren {
                    HeaderLabel(),
                    ToggleButton()
                }
            end,
            OnUpdatePets = function(_, pets)
                RebuildPetRows(pets)
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
