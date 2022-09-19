local util = require("__core__/lualib/util")
local spidertron_lib = require("lib.spidertron_lib")

function create_dock_data(dock_entity)
    return {
        occupied = false,

        -- Remember the normal type of the spider docked here
        spider_name = nil,

        -- Keep a reference to the docked spider
        docked_spider = nil,

        -- Can be nil when something goes wrong
        dock_entity = dock_entity,

        -- Keep this in here so that it's easy to
        -- find this entry in global
        unit_number = dock_entity.unit_number,
    }
end

function create_spider_data(spider_entity)
    return {
        -- A spider will only attempt to dock
        -- if it's armed for that dock in
        -- particular upon reaching it at
        -- the end of the waypoint.
        -- It's attempted to be set when the
        -- player uses the spidertron remote.
        armed_for = nil, -- Dock entity

        -- Can be nil when something goes wrong
        spider_entity = spider_entity,

        -- Keep this in here so that it's easy to
        -- find this entry in global
        unit_number = spider_entity.unit_number,

        -- Store a reference to the last dock this
        -- spider docked to. It's so that you can 
        -- click "return to dock" on a spider.
        -- This system will be dum, so if the dock
        -- is no longer valid then it will do nothing.
        -- If the dock is occupied then it will still return
        -- but simply fail to dock
        last_used_dock = nil,
        
        -- This field will only be true if this spider is
        -- the docked variant. It contains the actual
        -- spider name that is docked.
        original_spider_name = nil,

    }
end

function get_dock_data_from_entity(dock)
    if not dock.name == "ss-spidertron-dock" then return end
    local dock_data = global.docks[dock.unit_number]
    if not dock_data then
        global.docks[dock.unit_number] = create_dock_data(dock)
        dock_data = global.docks[dock.unit_number]
    end
    return dock_data
end

function get_spider_data_from_unit_number(spider_unit_number)
    return global.spiders[spider_unit_number]
end

function get_spider_data_from_entity(spider)
    if not spider.type == "spider-vehicle" then return end
    local spider_data = global.spiders[spider.unit_number]
    if not spider_data then
        global.spiders[spider.unit_number] = create_spider_data(spider)
        spider_data = global.spiders[spider.unit_number]
    end
    return spider_data
end

-- An function to call when an dock action
-- was not allowed. It will play the "no-no"
-- sound and create some flying text
function dock_error(dock, text)
    dock.surface.play_sound{
        path="ss-no-no", 
        position=dock.position
    }
    dock.surface.create_entity{
        name = "flying-text",
        position = dock.position,
        text = text,
        color = {r=1,g=1,b=1,a=1},
    }
end

-- Based on the tool provided by Wube, but that tool
-- does not function during runtime, so I need to redo it
local function collision_masks_collide(mask_1, mask_2)

    local clear_flags = function(map)
        for k, flag in pairs ({
            "consider-tile-transitions",
            "not-colliding-with-itself",
            "colliding-with-tiles-only"
          }) do
            map[flag] = nil
        end
    end

    clear_flags(mask_1)
    clear_flags(mask_2)
  
    for layer, _ in pairs (mask_2) do
      if mask_1[layer] then
        return true
      end
    end
    return false
end

-- Sometimes a dock will not support a specific
-- spider type. Currently this only happens
-- when a normal spider tries to dock to a dock
-- that's placed on a spaceship tile. This is required
-- because if your spaceship is small enough the spider
-- can reach the dock without stepping on restricted
-- spaceship tiles
-- Will return the text to display if there is no support
function dock_does_not_support_spider(dock, spider)

    -- Hacky implementation where spider can be
    -- either the entity or the name of the entity.
    -- So unpack it so we know how to handle it
    local spider_name = nil
    if type(spider) ~= "string" then
        -- It's the entity
        spider_name = spider.name
    else
        -- We just got a spider name. Lame!
        spider_name = spider
        spider = nil
    end
    
    -- Is this spider type supported in the first place?
    if not global.spider_whitelist[spider_name] then
        return {"space-spidertron-dock.spider-not-supported"}
    end

    -- Can the spider dock on this tile? This is to prevent terrestrial spiders
    -- being able to dock to a spaceship they can't walk on because the body
    -- can still reach the dock. We do this by checking if the first leg collides
    -- with a tile underneath the dock
    if game.active_mods["space-exploration"]
            and not settings.startup["space-spidertron-allow-other-spiders-in-space"].value then
        -- Only do it if we care about it though

        local tile_collision_mask = dock.surface.get_tile(dock.position).prototype.collision_mask
        local leg_collision_mask = nil
        if spider then
            leg_collision_mask = util.table.deepcopy(
                spider.get_spider_legs()[1].prototype.collision_mask)
        else
            -- We don't have a valid spider to get the leg-name from. 
            -- So lets create a temporary one
            -- TODO This is so ugly, we need a better way!
            local temporary_spider = dock.surface.create_entity{
                name=spider_name, 
                position=dock.position,
                create_build_effect_smoke=false,
                raise_built=false,
            }
            leg_collision_mask = util.table.deepcopy(
                temporary_spider.get_spider_legs()[1].prototype.collision_mask)
            temporary_spider.destroy() -- Destroy it after looking at it's leg!
        end

        -- If the leg would collide with the tile then it's not supported
        if collision_masks_collide(tile_collision_mask, leg_collision_mask) then
            return {"space-spidertron-dock.spider-not-supported-on-tile"}
        end
    end
end

-- This will dock a spider, and not
-- do any checks.
function dock_spider(dock, spider)
    local spider_data = get_spider_data_from_entity(spider)
    local dock_data = get_dock_data_from_entity(dock)

    -- Some smoke and mirrors
    dock.create_build_effect_smoke()
    dock.surface.play_sound{path="ss-spidertron-dock-1", position=dock.position}
    dock.surface.play_sound{path="ss-spidertron-dock-2", position=dock.position}
    
    -- Create the docked variant
    -- draw_docked_spider(dock_data, spider.name, spider.color) -- TODO Waiting for bounce speed functionality
    local docked_spider = spider.surface.create_entity{
        name = "ss-docked-"..spider.name,
        position = {
            dock.position.x,
            dock.position.y + 0.01 -- To draw spidertron over dock entity
        },
        force = spider.force,
        raise_built = false, -- Because it's not a real spider
    }
    docked_spider.destructible = false -- Only dock can be attacked
    local serialized_spider = spidertron_lib.serialise_spidertron(spider)
    spidertron_lib.deserialise_spidertron(docked_spider, serialized_spider)
    docked_spider.torso_orientation = 0.6 -- Looks nice
    local docked_spider_data = get_spider_data_from_entity(docked_spider)
    docked_spider_data.original_spider_name = spider.name
    docked_spider_data.armed_for = dock
    
    -- Remove
    spider.destroy{raise_destroy=true}  -- This will clean the spider data in the destroy event
    
    -- Keep some notes
    dock_data.spider_name = docked_spider_data.original_spider_name
    dock_data.occupied = true
    dock_data.docked_spider = docked_spider

    return docked_spider
end

-- This will undock a spider, and not
-- do any checks.
function undock_spider(dock, docked_spider)
    local docked_spider_data = get_spider_data_from_entity(docked_spider)
    local dock_data = get_dock_data_from_entity(dock)

    -- Some smoke and mirrors
    dock.surface.play_sound{path="ss-spidertron-undock-1", position=dock.position}
    dock.surface.play_sound{path="ss-spidertron-undock-2", position=dock.position}

    -- Create the regular spider again
    local spider = dock.surface.create_entity{
        name = dock_data.spider_name,
        position = docked_spider.position,
        force = docked_spider.force,
        create_build_effect_smoke = true,   -- Looks nice

        -- To help other mods keep track of this entity
        raise_built = true,
    }
    if not spider then
        -- TODO Handle this error nicely!
        error("Error! Couldn't spawn spider!\n"..serpent.block(dock_data))
    end
    local serialized_spider = spidertron_lib.serialise_spidertron(docked_spider)
    spidertron_lib.deserialise_spidertron(spider, serialized_spider)
    spider.torso_orientation = 0.6 -- orientation it's docked at
    local spider_data = get_spider_data_from_entity(spider)
    spider_data.last_used_dock = dock

    -- Clean up
    global.spiders[docked_spider.unit_number] = nil -- Because no destroy event will be called
    docked_spider.destroy{raise_destroy=false}      -- False because it's not a real spider

    -- Take some notes
    dock_data.docked_spider = nil
    dock_data.occupied = false
    dock_data.serialized_spider = nil

    return spider
end

-- This function will attempt the dock
-- of a spider.
function attempt_dock(spider)
    local spider_data = get_spider_data_from_entity(spider)
    if not spider_data.armed_for then return end

    -- Find the dock this spider armed for in the region
    -- We check the area because spidertrons are innacurate
    -- and will not always stop on top of the dock
    local dock = nil    
    for _, potential_dock in pairs(spider.surface.find_entities_filtered{
        name = "ss-spidertron-dock",
        position = spider.position,
        radius = 3,
        force = spider.force
    }) do
        if spider_data.armed_for == potential_dock then
            dock = potential_dock
            break
        end
    end
    if not dock then return end

    -- Check if dock is occupied
    local dock_data = get_dock_data_from_entity(dock)
    if dock_data.occupied then return end

    -- Check if this spider is allowed to dock here
    local error_msg = dock_does_not_support_spider(dock, spider)
    if error_msg then
        dock_error(dock, error_msg)
        return
    end

    -- Dock the spider!
    local docked_spider = dock_spider(dock, spider)

    -- Update GUI's for all players
    for _, player in pairs(game.players) do
        update_spider_gui_for_player(player, dock)
    end

    return docked_spider
end

function attempt_undock(dock_data, force)
    if not dock_data.occupied then return end
    local dock = dock_data.dock_entity
    if not dock then error("dock_data had no associated entity") end
    
    -- Some sanity check. If this happens, then something bad happens.
    -- Just quitly sweep it under the rug
    if not dock.valid then 
        -- Delete the entry, because it's likely this
        -- dock was deleted
        global.docks[dock_data.unit_number] = nil
        return
    end

    -- When the dock is mined then we will force the
    -- spider to be created so that the player doesn't lose it,
    -- whereas normally we would do some collision checks.
    -- Which might place the spider in an odd position, but oh well
    if force ~= true then

        -- Check if this spider is allowed to dock here
        local error_msg = dock_does_not_support_spider(dock, dock_data.spider_name)
        if error_msg then
            dock_error(dock, error_msg)
            return
        end

        -- We do no collision checks. We prevent normal spiders
        -- from undocking on spaceships by checking the tile
        -- and spider combination. And there *should* always be space
        -- for the legs next to the dock and whatever is next to it
    end

    -- Undock the spider!
    local undocked_spider = undock_spider(dock, dock_data.docked_spider)    

    -- Destroy GUI for all players
    for _, player in pairs(game.players) do
        update_spider_gui_for_player(player, dock)
    end

    return undocked_spider
end

script.on_event(defines.events.on_spider_command_completed, 
    function (event)
        if #event.vehicle.autopilot_destinations == 0 then
            -- Spidertron reached end of waypoints. See if it's above a dock.
            -- Attempt a dock!
            attempt_dock(event.vehicle)
        end
    end
)

script.on_event(defines.events.on_player_used_spider_remote , 
    function (event)
        local spider = event.vehicle
        if spider and spider.valid then

            -- First check if this is a docked spider. If it is, ignore this
            -- spider remote command
            if string.match(spider.name, "ss[-]docked[-]") then
                -- This is a docked spider! Prevent the auto pilot
                spider.follow_target = nil
                spider.autopilot_destination = nil

                -- Let the player know
                spider.surface.play_sound{path="ss-no-no", position=spider.position}
                spider.surface.create_entity{
                    name = "flying-text",
                    position = spider.position,
                    text = {"space-spidertron-dock.cannot-command"},
                    color = {r=1,g=1,b=1,a=1},
                }
                
                -- Don't do anything else
                return
            end

            local dock = spider.surface.find_entity("ss-spidertron-dock", event.position)
            local spider_data = get_spider_data_from_entity(spider)
            if dock then
                -- This waypoint was placed on a valid dock!
                -- Arm the dock so that spider is allowed to dock there
                local dock_data = get_dock_data_from_entity(dock)
                if dock.force ~= spider.force then return end
                if dock_data.occupied then return end
                spider_data.armed_for = dock
            else
                -- The player directed the spider somewhere else
                -- that's not a dock command. So remove any pending
                -- dock arms
                spider_data.armed_for = nil
            end
        end
    end
)

function on_built(event)
    -- If it's a space spidertron, set it to white as default
    local entity = event.created_entity or event.entity
    if entity and entity.valid then
        if entity.name == "ss-space-spidertron" then
            -- We only want to set it when the user has not set it
            -- before. However, there's no way we can determine it.
            -- Usually when it's placed initially the colour is that
            -- orange-ish colour, and then we turn it white. So we
            -- assume if it's the orangy-colour then the user has not
            -- set it, so we turn it to white. 
            if util.table.compare(
                entity.color,
                {r=1, g=0.5, b=0, a=0.5, }
            ) then
                entity.color = {1, 1, 1, 0.5} -- White
            end
        end
    end
end

script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)

function on_deconstructed(event)
    -- When the dock is destroyed then attempt undock the spider
    local entity = event.entity
    if entity and entity.valid then
        if entity.name == "ss-spidertron-dock" then
            attempt_undock(get_dock_data_from_entity(entity), true)
            global.docks[entity.unit_number] = nil
        elseif entity.type == "spider-vehicle" then
            if string.match(entity.name, "ss[-]docked[-]") then
                local spider_data = get_spider_data_from_entity(entity)
                local dock_data = get_dock_data_from_entity(spider_data.armed_for)
                attempt_undock(dock_data, true)
            else
                global.spiders[entity.unit_number] = nil
            end
        end
    end
end

script.on_event(defines.events.on_player_mined_entity, on_deconstructed)
script.on_event(defines.events.on_robot_mined_entity, on_deconstructed)
script.on_event(defines.events.on_entity_died, on_deconstructed)
script.on_event(defines.events.script_raised_destroy, on_deconstructed)

-- We can move docks with picker dollies, regardless
-- of if it contains a spider or not. We do not allow
-- moving the spiders though
function picker_dollies_move_event(event)
    local entity = event.moved_entity
    if entity.name == "ss-spidertron-dock" then
        local dock_data = get_dock_data_from_entity(entity)
        if dock_data.occupied then
            dock_data.docked_spider.teleport({
                entity.position.x,
                entity.position.y + 0.01 -- To draw spidertron over dock entity
            }, entity.surface)
        end
    end
end

-- This function is called when the spaceship changes
-- surfaces.
-- Technically this can be called under different circumstances too
-- but we will assume the spider always need to move to the
-- new location
script.on_event(defines.events.on_entity_cloned , function(event)
    local source = event.source
    local destination = event.destination
    if source and source.valid and destination and destination.valid then
        -- We will undock and redock the spider to not have to duplicate
        -- code. We will only do it relative to the dock, and delete the
        -- cloned spider. That way we have full control of what's happening
        if source.name == "ss-spidertron-dock" then
            local source_dock_data = get_dock_data_from_entity(source)
            if source_dock_data.occupied then
                -- Move the spider digitally to the new dock
                local docked_spider = source_dock_data.docked_spider
                local spider_data = get_spider_data_from_entity(docked_spider)
                local destination_dock_data = get_dock_data_from_entity(destination)
                if destination_dock_data.occupied then return end -- Shouldn't happen
                
                -- Move spider entity
                docked_spider.teleport({
                    destination.position.x,
                    destination.position.y + 0.01 -- To draw spidertron over dock entity
                }, destination.surface)
                
                -- First transfer all saved data. And then remove what we don't need
                -- Doing this funky transfer to also include whatever new fields we might add
                local key_blacklist = {
                    ["dock_entity"]=true, 
                    ["dock_unit_number"]=true}
                for key, value in pairs(source_dock_data) do
                    if not key_blacklist[key] then
                        destination_dock_data[key] = value
                    end
                end
                global.docks[source.unit_number] = nil -- Reset old dock
            end
        elseif string.match(source.name, "ss[-]docked[-]") then
            -- Destroy cloned docked spiders. We create them ourselves
            -- The data will be destroyed with the dock transfer
            destination.destroy{raise_destroy=false}
        end
    end
end)

function update_spider_gui_for_player(player, spider)
    -- Get data
    local spider_data = get_spider_data_from_entity(spider)

    -- Destroy whatever is there currently for
    -- any player. That's so that the player doesn't
    -- look at an outdated GUI
    for _, child in pairs(player.gui.relative.children) do
        if child.name == "ss-docked-spider" then
            -- We destroy all GUIs, not only for this unit-number,
            -- because otherwise they will open for other entities
            child.destroy() 
        end
    end

    -- All spiders have their GUIs destroyed for this player
    -- If this spider is not a docked version then return
    
    if not string.match(spider.name, "ss[-]docked[-]") then return end

    -- Decide if we should rebuild. We will only build
    -- if the player is currently looking at this docked spider
    if player.opened 
            and (player.opened == spider) 
            and spider_data.armed_for.valid then
        -- Build a new gui!

        -- Build starting frame
        local anchor = {
            gui=defines.relative_gui_type.spider_vehicle_gui, 
            position=defines.relative_gui_position.right
        }
        local frame = player.gui.relative.add{
            name="ss-docked-spider", 
            type="frame", 
            anchor=anchor,

            -- The tag associates the GUI with this
            -- specific dock 
            tags = {spider_unit_number = spider.unit_number}
        }

        -- Add button
        frame.add{
            type = "button",
            name = "spidertron-undock-button",
            caption = {"space-spidertron-dock.undock"},
            style = "green_button",
        }
    end
end

script.on_event(defines.events.on_gui_opened, function(event)
    local entity = event.entity
    if not entity then return end
    if event.gui_type == defines.gui_type.entity 
            and entity.type == "spider-vehicle" then
        update_spider_gui_for_player(
            game.get_player(event.player_index),
            event.entity
        )
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if element.name == "spidertron-undock-button" then
        local spider_data = get_spider_data_from_unit_number(
            element.parent.tags.spider_unit_number)
        if not spider_data then return end
        if not spider_data.armed_for.valid then return end
        local dock_data = get_dock_data_from_entity(spider_data.armed_for)
        attempt_undock(dock_data)
    end
end)

function build_spider_whitelist()
    local whitelist = {}
    local spiders = game.get_filtered_entity_prototypes({{filter="type", type="spider-vehicle"}})
    for _, spider in pairs(spiders) do
        local original_spider_name = string.match(spider.name, "ss[-]docked[-](.*)")
        if original_spider_name and spiders[original_spider_name] then
            whitelist[original_spider_name] = true
        end
    end
    return whitelist
end

function picker_dollies_blacklist_docked_spiders()
    if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["add_blacklist_name"] then
        local spiders = game.get_filtered_entity_prototypes({{filter="type", type="spider-vehicle"}})
        for _, spider in pairs(spiders) do
            if string.match(spider.name, "ss[-]docked[-]") then
                remote.call("PickerDollies", "add_blacklist_name",  spider.name)
            end
        end
    end
end

script.on_init(function()
    global.docks = {}
    global.spiders = {}
    global.spider_whitelist = build_spider_whitelist()
    picker_dollies_blacklist_docked_spiders()
    
    -- Add support for picker dollies
    if remote.interfaces["PickerDollies"] 
    and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
        script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), picker_dollies_move_event)
    end
end)

script.on_load(function()
    -- Add support for picker dollies
    if remote.interfaces["PickerDollies"] 
        and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
        script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), picker_dollies_move_event)
    end
end)

script.on_configuration_changed(function (event)
    global.docks = global.docks or {}
    global.spiders = global.spiders or {}
    global.spider_whitelist = build_spider_whitelist()

    redraw_all_docks()
    picker_dollies_blacklist_docked_spiders()

    -- Fix technologies
    local technology_unlocks_spidertron = false
    for index, force in pairs(game.forces) do
        for _, technology in pairs(force.technologies) do		
            if technology.effects then			
                for _, effect in pairs(technology.effects) do
                    if effect.type == "unlock-recipe" then					
                        if effect.recipe == "spidertron" then
                            technology_unlocks_spidertron = true
                        end
                    end
                end
                if technology_unlocks_spidertron then
                    force.recipes["ss-space-spidertron"].enabled = technology.researched
                    force.recipes["ss-spidertron-dock"].enabled = technology.researched
                    break
                end
            end
        end
    end
end)
