-- MADpilot OEM Boot Self-Announcer
-- Fleet: Foam-trainer test plane fleet
-- Purpose: Announces OEM identity and battery voltage to GCS at 1 Hz once booted, then terminates.

local SCRIPT_NAME = "madpilot_announce.lua"
local announced = false
local attempts = 0
local MAX_ATTEMPTS = 30 -- Stop checking after 30 seconds to conserve flight controller resources

function update()
    if announced then
        return nil
    end

    attempts = attempts + 1

    -- Defensive check: ensure GCS subsystem is available
    if not gcs or not gcs.send_text then
        if attempts < MAX_ATTEMPTS then
            return update, 1000
        end
        return nil
    end

    local batt_info = "Battery: N/A"

    -- Defensive check: guard against missing or uninitialized battery monitor
    if battery and battery.num_instances and battery:num_instances() > 0 then
        local volt = battery:voltage(0)
        if volt and volt > 0.0 then
            batt_info = string.format("Batt: %.2fV", volt)
            if battery.capacity_remaining_pct then
                local has_pct, pct = battery:capacity_remaining_pct(0)
                if has_pct and pct then
                    batt_info = batt_info .. string.format(" (%d%%)", pct)
                end
            end
        end
    end

    -- MAV_SEVERITY_INFO is 6
    gcs:send_text(6, string.format("MADpilot OEM online [%s]", batt_info))
    announced = true

    -- Do not reschedule once successfully announced
    return nil
end

return update()
