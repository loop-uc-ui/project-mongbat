local NAME = "MongbatDistanceCounterLabel"
local CAL_WINDOW = "MongbatDistCalProbe"

----------------------------------------------------------------
-- Configuration
----------------------------------------------------------------

-- Divisor that converts screen-pixel offsets to world-tile Chebyshev
-- distance in a 2:1 isometric projection.  Equals 4 × half-tile-height
-- in pixels at the current 3-D camera zoom.  The calibration loop
-- measures this from a visible mobile; the default is a rough guess.
local DEFAULT_K = 48
local CALIBRATION_INTERVAL = 0.5    -- seconds between recalibrations
local SMOOTHING_FACTOR = 0.3        -- exponential smoothing (0 = ignore new, 1 = instant)
local MIN_REF_TILES = 3             -- minimum tile distance for a reference mobile
local MAX_REF_TILES = 18            -- maximum tile distance for a reference mobile

-- Pixel offset from the cursor where the label is drawn
local CURSOR_OFFSET_X = 16
local CURSOR_OFFSET_Y = -16

----------------------------------------------------------------
-- Calibration state
----------------------------------------------------------------

local K = DEFAULT_K                 -- current effective divisor
local calTimer = 0                  -- time since last calibration
local calMobileId = nil             -- mobile the probe is attached to

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function hasTarget()
    return WindowData.Cursor ~= nil and WindowData.Cursor.target == true
end

--- 2:1 isometric pixel metric.
-- Given screen-pixel offsets (dx, dy) from the viewport centre, returns a
-- value that, divided by K (= 4 × half-tile-height), yields the exact
-- world-tile Chebyshev distance.  Direction-independent.
local function isoMetric(dx, dy)
    return math.max(math.abs(dx + 2 * dy), math.abs(2 * dy - dx))
end

--- Find the best on-screen mobile for calibration.
-- Prefers the farthest mobile within the allowed range.
local function findCalibrationMobile()
    local targets = GetAllMobileTargets()
    if targets == nil then return nil end

    local playerId = WindowData.PlayerStatus.PlayerId
    local bestId = nil
    local bestDist = 0

    for _, id in pairs(targets) do
        if id ~= playerId then
            local d = GetDistanceFromPlayer(id)
            if d >= MIN_REF_TILES and d <= MAX_REF_TILES and d > bestDist then
                bestDist = d
                bestId = id
            end
        end
    end

    return bestId
end

--- Ensure the 1×1 calibration probe window exists.
local function ensureProbeWindow()
    if not DoesWindowNameExist(CAL_WINDOW) then
        CreateWindowFromTemplate(CAL_WINDOW, "MongbatWindow", "Root")
        WindowSetDimensions(CAL_WINDOW, 1, 1)
        WindowSetAlpha(CAL_WINDOW, 0)
        WindowSetHandleInput(CAL_WINDOW, false)
    end
end

--- Attach the probe to a new mobile, detaching from the previous one.
local function attachProbe(mobileId)
    if calMobileId == mobileId then return end
    if calMobileId ~= nil then
        DetachWindowFromWorldObject(calMobileId, CAL_WINDOW)
    end
    AttachWindowToWorldObject(mobileId, CAL_WINDOW)
    calMobileId = mobileId
end

--- Recalibrate K from a visible mobile's screen position.
local function recalibrate(centerX, centerY)
    local refId = findCalibrationMobile()
    if refId == nil then return end

    ensureProbeWindow()
    attachProbe(refId)

    local refX, refY = WindowGetScreenPosition(CAL_WINDOW)
    local dx = refX - centerX
    local dy = refY - centerY

    local metric = isoMetric(dx, dy)
    local tileDist = GetDistanceFromPlayer(refId)

    if metric > 10 and tileDist > 0 then
        local measured = metric / tileDist
        -- Exponential smoothing to avoid jitter
        K = K * (1 - SMOOTHING_FACTOR) + measured * SMOOTHING_FACTOR
    end
end

--- Clean up the probe window and detach from any mobile.
local function destroyProbe()
    if calMobileId ~= nil and DoesWindowNameExist(CAL_WINDOW) then
        DetachWindowFromWorldObject(calMobileId, CAL_WINDOW)
        calMobileId = nil
    end
    if DoesWindowNameExist(CAL_WINDOW) then
        DestroyWindow(CAL_WINDOW)
    end
end

----------------------------------------------------------------
-- Mod
----------------------------------------------------------------

Mongbat.Mod {
    Name = "MongbatDistanceCounter",
    Path = "/src/mods/mongbat-distance-counter",
    OnInitialize = function(context)
        local label = context.Components.Label {
            Name = NAME,
            OnInitialize = function(self)
                self:setDimensions(60, 20)
                self:setHandleInput(false)
                self:setLayer():overlay()
            end,
            OnUpdate = function(self, timePassed)
                if not hasTarget() then
                    self:setText("")
                    return
                end

                local scaleFactor = InterfaceCore.scale

                -- Viewport bounds
                local vpX, vpY = WindowGetScreenPosition("ResizeWindow")
                local vpW, vpH = WindowGetDimensions("ResizeWindow")
                vpW = vpW / scaleFactor
                vpH = vpH / scaleFactor

                local borderX = vpX + vpW
                local borderY = vpY + vpH

                -- Mouse position (screen pixels)
                local mx = SystemData.MousePosition.x
                local my = SystemData.MousePosition.y

                -- If cursor is outside the game viewport, clear
                if mx < vpX or mx > borderX or my < vpY or my > borderY then
                    self:setText("")
                    return
                end

                -- Viewport centre (where the player character is)
                local centerX = vpX + vpW / 2
                local centerY = vpY + vpH / 2

                -- Periodically recalibrate pixels-per-tile from a nearby mobile
                calTimer = calTimer + timePassed
                if calTimer >= CALIBRATION_INTERVAL then
                    calTimer = 0
                    recalibrate(centerX, centerY)
                end

                -- Pixel delta from player to cursor
                local dx = mx - centerX
                local dy = my - centerY

                -- 2:1 isometric inverse → world-tile Chebyshev distance
                local distance = math.floor(isoMetric(dx, dy) / K)

                -- Position the label near the cursor
                self:setOffsetFromParent(
                    mx + CURSOR_OFFSET_X,
                    my + CURSOR_OFFSET_Y
                )
                self:setText(tostring(distance))
            end
        }

        label:create(true)
        label:onInitialize()
    end,
    OnShutdown = function(context)
        destroyProbe()
        if DoesWindowExist(NAME) then
            DestroyWindow(NAME)
        end
    end
}
