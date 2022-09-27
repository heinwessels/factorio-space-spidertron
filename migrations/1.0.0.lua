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

    -- We had an prior issue where a  bad picker dolly
    -- handler created a bunch of dummy data. Clean
    -- it up.
    -- Edit: Turns out a made a double-boo-boo and my
    -- custom picker dolly handler never functioned, 
    -- and thus never created bad data. I'll leave this
    -- in though.
    if not dock or not dock.valid or dock.name ~= "ss-spidertron-dock" then
        table.insert(mark_for_deletion, unit_number)
    else
        if dock and dock.valid then
            if dock_data.occupied and dock_data.serialized_spider then
                -- Okay, here is a spider that we must update
                
                -- The sprite prototypes no longer exist
                -- so they are removed automatically
                dock_data.docked_sprites = nil

                local docked_name = "ss-docked-"..dock_data.serialized_spider.name

                -- It might be that the docked version no longer exists
                -- because of a mods change or something. Check if it exists!
                if game.entity_prototypes[docked_name] then
                
                    -- Now create the spidertron entity
                    local docked_spider = dock.surface.create_entity{
                        name=docked_name,
                        position = {
                            dock.position.x,
                            dock.position.y + 0.01 -- To draw spidertron over dock entity
                        },
                        force=dock.force,
                        create_build_effect_smoke=false,
                        raise_built=false, --  Not a real spider
                    }
                    if docked_spider then
                        docked_spider.destructible = false -- Only dock can be attacked
                        spidertron_lib.deserialise_spidertron(docked_spider, dock_data.serialized_spider)
                        docked_spider.torso_orientation = 0.6
                        global.spiders[docked_spider.unit_number] = {
                            spider_entity=docked_spider,
                            unit_number=docked_spider.unit_number,
                            original_spider_name=dock_data.serialized_spider.name,
                            armed_for=dock,
                        }
                        
                        dock_data.spider_name = dock_data.serialized_spider.name
                        dock_data.docked_spider = docked_spider
                        
                        -- Clean up what's left
                        dock_data.serialized_spider = nil

                        -- Keep a tag here so that if a player updates straight from 
                        -- < 1.0 to 1.1 then his docks can all be set to `passive` mode
                        -- This is for you Alphaprime
                        dock_data.was_passive = true
                    end
                else
                    -- If the prototype no longer exists then we need to empty this dock's data
                    table.insert(mark_for_deletion, unit_number)
                end
            else
                -- If this doesn't work then a dock will remain that looks empty
                -- but has an spider docked with a serialized spider still in the data
                -- I might be able to fix that if someone complains. But it shouldn't 
                -- happen, so, meh.
            end
        else
            -- This dock entity no longer exists. Odd.
            table.insert(mark_for_deletion, unit_number)
        end
    end
end

-- Clean up docks I marked for deletion
for _, unit_number in pairs(mark_for_deletion) do
    global.docks[unit_number] = nil
end


-- Now clean up existing GUI's for docks for all players
-- The code should create the new dock GUI anyway when opening
-- It has a different name anyway
for _, player in pairs(game.players) do
    if player.valid and player.gui then  -- I don't know if this is neccesary
        for _, child in pairs(player.gui.relative.children) do
            if child.name == "ss-spidertron-dock" then
                child.destroy() 
            end
        end
    end
end