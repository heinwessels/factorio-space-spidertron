local util = require("__core__/lualib/util")
local spidertron_lib = require("lib.spidertron_lib")

function create_dock_data(dock_entity)
    return {
        occupied = false,

        -- Keep track of sprites drawed so we
        -- can pop them out later.
        docked_sprites = {},
        
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

function get_dock_data_from_entity(dock)
    local dock_data = global.docks[dock.unit_number]
    if not dock_data then
        global.docks[dock.unit_number] = create_dock_data(dock)
        dock_data = global.docks[dock.unit_number]
    end
    return dock_data
end

function get_dock_data_from_unit_number(dock_unit_number)
    local dock_data = global.docks[dock_unit_number]
    if not dock_data then
        global.docks[dock_unit_number] = create_dock_data(dock)
        dock_data = global.docks[dock_unit_number]
    end
    return dock_data
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
    }
end

function get_spider_data_from_entity(spider)
    local spider_data = global.spiders[spider.unit_number]
    if not spider_data then
        global.spiders[spider.unit_number] = create_spider_data(spider)
        spider_data = global.spiders[spider.unit_number]
    end
    return spider_data
end

function draw_docked_spider(dock_data, spider_name, color)
    local dock = dock_data.dock_entity

    -- Offset to place sprite at correct location
    -- This assumes we're not drawing the bottom
    local offset = {0, -0.35}
    local render_layer = "object"
    
    -- Draw shadows
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "ss-docked-"..spider_name.."-shadow", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
            render_layer = render_layer,
        }
    )

    -- First draw main layer
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "ss-docked-"..spider_name.."-main", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
            render_layer = render_layer,
        }
    )

    -- Then draw tinted layer
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "ss-docked-"..spider_name.."-tint", 
            target = dock, 
            surface = dock.surface,
            tint = color,
            target_offset = offset,
            render_layer = render_layer,
        }
    )

    -- Finally draw the light animation
    table.insert(dock_data.docked_sprites, 
        rendering.draw_animation{
            animation = "ss-docked-light", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
            render_layer = render_layer,
            animation_offset = math.random(15), -- Not sure how to start at frame 0
        }
    )
end

-- Destroys sprites from a dock and also removes
-- their entries in it's data
function pop_dock_sprites(dock_data)
    for _, sprite in pairs(dock_data.docked_sprites) do
        rendering.destroy(sprite)
    end
    dock_data.docked_sprites = {}
end

-- An function to call when an dock action
-- was not allowed. It will play the "no-no"
-- sound and create some flying text
function dock_error(dock, text)
    -- TODO A future GUI should display the error message.
    -- because the flying text is obscure
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

-- Sometimes a dock will not support a specific
-- spider type. Currently this only happens
-- when a normal spider tries to dock to a dock
-- that's placed on a spaceship tile. This is required
-- because if your spaceship is small enough the spider
-- can reach the dock without stepping on restricted
-- spaceship tiles
-- Will return the text to display if there is no support
function dock_does_not_support_spider(dock, spider_name)
    
    -- Is this spider type supported in the first place?
    -- We check this by looking if a sprite for this spider exists
    -- as a bridge between the data and control stage. If it doesn't
    -- exist then this spider can never dock
    if not game.is_valid_sprite_path("ss-docked-"..spider_name.."-main") then
        return {"space-spidertron-dock.spider-not-supported"}
    end

    -- Is the dock on a tile that does not allow regular spiders to dock?
    if not settings.startup["space-spidertron-allow-other-spiders-in-space"].value then
        -- Space spidertron is always allowed
        if spider_name ~= "ss-space-spidertron" then
            -- Check if the dock is on a spaceship tile
            -- This is not a full-proof check, as we check only one tile under the dock
            -- and there are 4 that can potentially be a spaceship tile. However, in that
            -- case the ship can't launch due to it's mechanics. And if the player really
            -- wants to he can hack the system, so this check is good enough.
            if dock.surface.get_tile(dock.position).name == "se-spaceship-floor" then
                return {"space-spidertron-dock.spider-not-supported-on-tile"}
            end
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
    local serialized_spider = spidertron_lib.serialise_spidertron(spider)
    -- TODO Carefully remove guns
    spidertron_lib.deserialise_spidertron(docked_spider, serialized_spider)
    docked_spider.torso_orientation = 0.6 -- Similar to sprite orientation
    
    -- Remove
    spider.destroy{raise_destroy=true}  -- This will clean the spider data in the destroy event
    
    -- Keep some notes
    dock_data.spider_name = serialized_spider.name
    dock_data.occupied = true
    dock_data.docked_spider = docked_spider
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
    spider.torso_orientation = 0.6 -- Similar to sprite orientation
    local spider_data = get_spider_data_from_entity(spider)
    spider_data.last_used_dock = dock

    -- Clean up
    docked_spider.destroy{raise_destroy=false}  -- False because it's not a real spider
    pop_dock_sprites(dock_data)

    -- Take some notes
    dock_data.docked_spider = nil
    dock_data.occupied = false
    dock_data.serialized_spider = nil
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
    local error_msg = dock_does_not_support_spider(dock, spider.name)
    if error_msg then
        dock_error(dock, error_msg)
        return
    end

    -- Dock the spider!
    dock_spider(dock, spider)

    -- Update GUI's for all players
    for _, player in pairs(game.players) do
        update_dock_gui_for_player(player, dock)
    end
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
    undock_spider(dock, dock_data.docked_spider)    

    -- Destroy GUI for all players
    for _, player in pairs(game.players) do
        update_dock_gui_for_player(player, dock)
    end
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
            global.spiders[entity.unit_number] = nil
        end
    end
end

script.on_event(defines.events.on_player_mined_entity, on_deconstructed)
script.on_event(defines.events.on_robot_mined_entity, on_deconstructed)
script.on_event(defines.events.on_entity_died, on_deconstructed)
script.on_event(defines.events.script_raised_destroy, on_deconstructed)

-- We can move docks with picker dollies, regardless
-- of if it contains a spider or not. All we really
-- have to do is redraw the sprites, because the dock
-- entity remains the same entity. It's only moved.
function picker_dollies_move_event(event)
    local dock = event_moved_entity
    if not dock or dock.valid then return end
    local dock_data = get_dock_data_from_entity(dock)

    -- If there's a spider, then update the sprites
    if dock_data.occupied then
        pop_dock_sprites(dock_data)
        draw_docked_spider(
            dock_data, 
            dock_data.serialized_spider.name,
            dock_data.serialized_spider.color
        )
    end
end

-- This function is called when the spaceship changes
-- surfaces. We need to update our global tables and redraw
-- the sprites.
-- Technically this can be called under different circumstances too
-- but we will assume the spider always need to move to the
-- new locationpotential_dock
script.on_event(defines.events.on_entity_cloned , function(event)
    local source = event.source
    local destination = event.destination
    if source and source.valid and destination and destination.valid then
        if source.name == "ss-spidertron-dock" then
            local source_dock_data = get_dock_data_from_entity(source)

            -- If there's nothing docked at the source then we
            -- don't have to do anything
            if not source_dock_data.occupied then return end
            
            -- Move spider to new location
            destination_dock_data = util.copy(source_dock_data)
            destination_dock_data.dock_entity = destination
            destination_dock_data.docked_sprites = {}
            draw_docked_spider(
                destination_dock_data, 
                destination_dock_data.serialized_spider.name,
                destination_dock_data.serialized_spider.color
            )
            global.docks[destination.unit_number] = destination_dock_data

            -- Remove from old location
            for _, sprite in pairs(source_dock_data.docked_sprites) do
                rendering.destroy(sprite)
            end
            global.docks[source.unit_number] = nil

            -- Update all guis
            for _, player in pairs(game.players) do
                update_dock_gui_for_player(player, source)
                update_dock_gui_for_player(player, destination)
            end
        end
    end
end)

function update_dock_gui_for_player(player, dock)
    -- Get dock data
    local dock_data = get_dock_data_from_entity(dock)

    -- Destroy whatever is there currently for
    -- any player. That's so that the player doesn't
    -- look at an outdated GUI
    for _, child in pairs(player.gui.relative.children) do
        if child.name == "ss-spidertron-dock" then
            -- We destroy all GUIs, not only for this unit-number,
            -- because otherwise they will open for other entities
            child.destroy() 
        end
    end

    -- All docks have their GUIs destroyed for this player
    -- If this dock is not occupied then we don't need
    -- to redraw anything
    if not dock_data.occupied then return end

    -- Decide if we should rebuild. We will only build
    -- if the player is currently looking at this docked spider
    if player.opened and (player.opened == dock_data.docked_spider) then
        -- Build a new gui!

        -- Build starting frame
        local anchor = {
            gui=defines.defines.relative_gui_type.spider_vehicle_gui.accumulator_gui, 
            position=defines.relative_gui_position.right
        }
        local frame = player.gui.relative.add{
            name="ss-spidertron-dock", 
            type="frame", 
            anchor=anchor,

            -- The tag associates the GUI with this
            -- specific dock 
            tags = {dock_unit_number = dock.unit_number}
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
            and entity.type == "spider-vehicle"
            and string.match(entity.name, "ss[-]docked[-]") then
        update_dock_gui_for_player(
            game.get_player(event.player_index),
            event.entity
        )
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if element.name == "spidertron-undock-button" then
        attempt_undock(get_dock_data_from_unit_number(
                element.parent.tags.dock_unit_number))
    end
end)

-- This will be called when something changes
-- to ensure all docks are drawn on the most
-- up-to-date way
function redraw_all_docks()
    for _, surface in pairs(game.surfaces) do
        for _, dock in pairs(surface.find_entities_filtered{
            name = "ss-spidertron-dock"
        }) do
            if global.docks[dock.unit_number] then
                local dock_data = get_dock_data_from_entity(dock)
                if dock_data.occupied then
                    pop_dock_sprites(dock_data)
                    draw_docked_spider(
                        dock_data, 
                        dock_data.serialized_spider.name,
                        dock_data.serialized_spider.color
                    )
                end
            end
        end
    end
end

script.on_init(function()
    global.docks = {}
    global.spiders = {}

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

    redraw_all_docks()

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
