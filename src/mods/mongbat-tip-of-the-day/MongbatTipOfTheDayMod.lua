local NAME = "TipoftheDayWindow"

Mongbat.Mod {
    Name = "MongbatTipOfTheDay",
    Path = "/src/mods/mongbat-tip-of-the-day",
    OnInitialize = function(context)
        local defaultComponent = context.Components.Defaults.TipoftheDayWindow
        defaultComponent:disable()

        context.Api.CSV.Load("Data/GameData/tipoftheday.csv", "TipoftheDayCSV")

        local settings = context.Data.Settings()
        if not settings.Interface.showTipoftheDay then
            return
        end

        local csv = context.Data.TipoftheDayCSV()
        local tipIndex = context.Api.Math.GetRandomNumber(table.getn(csv)) + 1

        local tipLabel = context.Components.Label {
            Template = "MongbatTipOfTheDayLabel",
            OnInitialize = function(self)
                self:setText(csv[tipIndex].TipTID)
            end,
        }

        local function advanceTip()
            tipIndex = tipIndex + 1
            if tipIndex > table.getn(csv) then
                tipIndex = 1
            end
            tipLabel:setText(csv[tipIndex].TipTID)
        end

        local doNotShowButton = context.Components.Button {
            OnInitialize = function(self)
                self:setStayDown(true)
                self:setChecked(not settings.Interface.showTipoftheDay)
                self:setText(1094690)
            end,
            OnLButtonUp = function(self)
                settings.Interface.showTipoftheDay = not settings.Interface.showTipoftheDay
                self:setChecked(not settings.Interface.showTipoftheDay)
            end,
        }

        local nextButton = context.Components.Button {
            OnInitialize = function(self)
                self:setText(1043353)
            end,
            OnLButtonUp = function()
                advanceTip()
            end,
        }

        local closeButton = context.Components.Button {
            OnInitialize = function(self)
                self:setText(1052061)
            end,
            OnLButtonUp = function()
                context.Api.Window.Destroy(NAME)
            end,
        }

        context.Components.Window {
            Name = NAME,
            Resizable = false,
            OnInitialize = function(self)
                self:setDimensions(540, 240)
                self:anchorToParentCenter()
                self:setChildren {
                    context.Components.Label {
                        OnInitialize = function(self)
                            self:setText(1094689)
                        end,
                    },
                    tipLabel,
                    nextButton,
                    doNotShowButton,
                    closeButton,
                }
            end,
            OnLayout = function(self, children, child, index)
                local dimens = self:getDimensions()
                local contentW = dimens.x - 24
                if index == 1 then
                    -- Title label
                    child:setDimensions(contentW, 20)
                    child:addAnchor("topleft", self:getName(), "topleft", 12, 12)
                elseif index == 2 then
                    -- Tip text: below title
                    child:setDimensions(contentW, 120)
                    child:addAnchor("topleft", children[1]:getName(), "bottomleft", 0, 8)
                elseif index == 3 then
                    -- Next button: bottom right
                    child:setDimensions(80, 28)
                    child:addAnchor("bottomright", self:getName(), "bottomright", -12, -12)
                elseif index == 4 then
                    -- "Do not show" checkbox: bottom left
                    child:setDimensions(200, 28)
                    child:addAnchor("bottomleft", self:getName(), "bottomleft", 12, -12)
                elseif index == 5 then
                    -- Close button: to the left of Next
                    child:setDimensions(80, 28)
                    child:addAnchor("right", children[3]:getName(), "left", -8, 0)
                end
            end,
        }:create(true)
    end,
    OnShutdown = function(context)
        context.Api.Settings.Apply()
        context.Api.CSV.Unload("TipoftheDayCSV")
        context.Components.Defaults.TipoftheDayWindow:restore()
    end,
}
