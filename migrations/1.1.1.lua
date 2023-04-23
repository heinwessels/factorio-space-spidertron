-- Theres a bug in either 1.0.0 or 1.1.0 migration scripts to results
-- in the dock_data internal unit number becoming out of sync with
-- what it should be. Not sure where this happens, but it doesn't
-- really matter, because anyone that migrated the same way will
-- have the same issue already. Better write a migration that 
-- simply fixes it
-- Reported by Alphaprime

if not global.docks then return end

local marked_for_fixing = {}

-- Find all broken dock data's
for unit_number, dock_data in pairs(global.docks) do
    local dock = dock_data.dock_entity
    if dock.unit_number ~= unit_number or dock.unit_number ~= dock_data.unit_number then
        table.insert(marked_for_fixing, unit_number)
    end
end

-- Fix them by using the entity's unit number
-- as the source of truth
for _, unit_number in pairs(marked_for_fixing) do
    local dock_data = global.docks[unit_number]
    local dock = dock_data.dock_entity
    dock_data.unit_number = dock.unit_number
    global.docks[dock.unit_number] = dock_data
    if unit_number ~= dock.unit_number then
        global.docks[unit_number] = nil
    end
end

-- Clean up GUI's which might still be connected to
-- the old dock number.
for _, player in pairs(game.players) do
    if player.valid and player.gui then  -- I don't know if this is neccesary
        for _, child in pairs(player.gui.relative.children) do
            if child.name == "ss-spidertron-dock" then
                child.destroy() 
            end
        end
    end
end