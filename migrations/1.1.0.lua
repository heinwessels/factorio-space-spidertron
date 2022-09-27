-- Changed docked spiders from being sprites to 
-- actual spidertron entities. This script should
-- update all existing docked spiders

local spidertron_lib = require("lib.spidertron_lib")
global.docks = global.docks or {}
global.spiders = global.spiders or {}

-- There's some docks that needs to be removed from storage
-- because I made a booboo.
local mark_for_deletion = {}

for unit_number, dock_data in pairs(global.docks) do
    local dock = dock_data.dock_entity
    if not dock or not dock.valid then
        -- This is harsh, but should never happen.
        table.insert(mark_for_deletion, unit_number)
    else
        -- All docks are active at this point
        dock_data = "active"

        if dock_data.occupied then
            -- First change the data to reflect an actively docked 
            -- spider, because that's the state we should find it in.
            dock_dat




            -- This will only occur if a game was updated now
            -- from pre-1.0. This is so their docks will be
            -- passive.
            if dock_data.was_passive then
                -- TODO Set to active mode

                -- Remove the flag
                dock_data.was_passive = nil
            end
        end
    end
end

-- Clean up docks I marked for deletion
for _, unit_number in pairs(mark_for_deletion) do
    global.docks[unit_number] = nil
end