local util = require("__core__/lualib/util")
local spidertron_lib = require("script.lib.spidertron_lib")

script.on_configuration_changed(function (event)
    global.docks = global.docks or {}

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
                    force.recipes["space-spidertron"].enabled = technology.researched
                    force.recipes["spidertron-dock"].enabled = technology.researched
                    break
                end
            end
        end
    end
end)

function create_dock_data(dock_entity)
    return {
        occupied = false,
        serialized_spider = nil,
        docked_sprites = {},

        -- A dock will only allow a dock if
        -- it's armed for a specific spidertron
        -- This is because the spider doesn't always
        -- stop on the dock itself. So rather when
        -- the waypoint is added using a remote, 
        -- then the dock is armed.
        armed_for = nil,

        -- Can be nil when something goes wrong
        dock_entity = dock_entity,
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

function draw_docked_spider(dock_data, spider_name, color)
    local dock = dock_data.dock_entity

    -- Offset to place sprite at correct location
    -- This assumes we're not drawing the bottom
    local offset = {-0.1, -0.35}
    
    -- Draw shadows
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "docked-"..spider_name.."-shadow", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
        }
    )

    -- First draw main layer
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "docked-"..spider_name.."-main", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
        }
    )

    -- Then draw tinted layer
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "docked-"..spider_name.."-tint", 
            target = dock, 
            surface = dock.surface,
            tint = color,
            target_offset = offset,
        }
    )
end

-- This function will attempt the dock
-- of a spider. It will only work if
-- it's above a valid dock, etc.
function attempt_dock(spider)

    -- Find the dock armed for this spider in the region
    -- If none of the docks are armed for this spider then
    -- ignore the command. This will likely happen when
    --      - Dock was allocated for other spider
    local dock = nil
    for _, potential_dock in pairs(spider.surface.find_entities_filtered{
        name = "spidertron-dock",
        position = spider.position,
        radius = 3,
        force = spider.force
    }) do
        local potential_dock_data = get_dock_data_from_entity(potential_dock)
        if potential_dock_data.armed_for == spider then
            dock = potential_dock
            break
        end
    end
    if not dock then return end

    -- Check if dock is occupied
    local dock_data = get_dock_data_from_entity(dock)
    if dock_data.occupied then return end

    -- Dock the spider!
    draw_docked_spider(dock_data, spider.name, spider.color)
    dock_data.serialized_spider = spidertron_lib.serialise_spidertron(spider)
    spider.destroy()
    dock_data.occupied = true

    -- Update GUI's for all players
    for _, player in pairs(game.players) do
        update_dock_gui_for_player(player, dock)
    end
end

function attempt_undock(dock_data)
    if not dock_data.occupied then return end
    if not dock_data.serialized_spider then return end
    local serialized_spider = dock_data.serialized_spider
    local dock = dock_data.dock_entity
    if not dock then error("dock_data had no associated entity") end

    -- Create a empty spider and apply the
    -- serialized spider onto that spider
    local spider = dock.surface.create_entity{
        name = serialized_spider.name,
        position = dock.position,
        force = dock.force,
        create_build_effect_smoke = true
    }
    if not spider then
        -- TODO Handle this error nicely!
        game.print("Error! Couldn't spawn spider!")
    end
    spidertron_lib.deserialise_spidertron(spider, serialized_spider)
    spider.torso_orientation = 0.6 -- Similar to sprite orientation

    -- Success!
    dock_data.occupied = false
    dock_data.armed_for = nil
    dock_data.serialized_spider = nil
    for _, sprite in pairs(dock_data.docked_sprites) do
        rendering.destroy(sprite)
    end
    dock_data.docked_sprites = {}

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

-- This will remove any previous
-- allocations to this dock
-- It's okay if the spider never reaches the dock
-- When a next spider tries to dock it will simply
-- overwrite the allocation
function dock_arm_for_spider(dock, spider)
    if dock.force ~= spider.force then return end
    local dock_data = get_dock_data_from_entity(dock)
    if dock_data.occupied then return end
    dock_data.armed_for = spider -- Overwrite
end

script.on_event(defines.events.on_player_used_spider_remote , 
    function (event)
        local spider = event.vehicle
        if spider and spider.valid then
            local dock = spider.surface.find_entity("spidertron-dock", event.position)
            if dock then
                -- This waypoint was placed on a valid dock!
                -- Arm the dock so that spider is allowed to dock there
                dock_arm_for_spider(dock, spider)
            end
        end
    end
)

function on_built(event)
    -- If it's a space spidertron, set it to white as default
    local entity = event.created_entity
    if entity and entity.valid then
        if entity.name == "space-spidertron" then
            entity.color = {1, 1, 1, 0.5} -- White
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
        if entity.name == "spidertron-dock" then
            attempt_undock(
                get_dock_data_from_entity(entity))
        end
    end
end

script.on_event(defines.events.on_player_mined_entity, on_deconstructed)
script.on_event(defines.events.on_robot_mined_entity, on_deconstructed)
script.on_event(defines.events.on_entity_died, on_deconstructed)
script.on_event(defines.events.script_raised_destroy, on_deconstructed)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.gui_type == defines.gui_type.entity 
            and event.entity.name == "spidertron-dock" then
        update_dock_gui_for_player(
            game.get_player(event.player_index),
            event.entity
        )
    end
end)


-- This function is called when the spaceship changes
-- surfaces. We need to update our global tables and redraw
-- the sprites.
-- Technically this can be called under different circumstances too
-- but we will assume the spider always need to move to the
-- new location
script.on_event(defines.events.on_entity_cloned , function(event)
    local source = event.source
    local destination = event.destination
    if source and source.valid and destination and destination.valid then
        if source.name == "spidertron-dock" then
            local source_data = get_dock_data_from_entity(source)

            -- If there's nothing docked at the source then we
            -- don't have to do anything
            if not source_data.occupied then return end
            
            -- Move spider to new location
            destination_data = util.copy(source_data)
            destination_data.dock_entity = destination
            destination_data.docked_sprites = {}
            draw_docked_spider(
                destination_data, 
                destination_data.serialized_spider.name,
                destination_data.serialized_spider.color
            )
            global.docks[destination.unit_number] = destination_data

            -- Remove from old location
            for _, sprite in pairs(source_data.docked_sprites) do
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
        if child.name == "spidertron-dock" then
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
    -- if the player is currently looking at this dock
    if player.opened and (player.opened == dock) then
        -- Build a new gui!

        -- Build starting frame
        local anchor = {
            gui=defines.relative_gui_type.accumulator_gui, 
            position=defines.relative_gui_position.right
        }
        local frame = player.gui.relative.add{
            name="spidertron-dock", 
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

script.on_event(defines.events.on_player_mined_entity, on_deconstructed)
script.on_event(defines.events.on_robot_mined_entity, on_deconstructed)
script.on_event(defines.events.on_entity_died, on_deconstructed)
script.on_event(defines.events.script_raised_destroy, on_deconstructed)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.gui_type == defines.gui_type.entity 
            and event.entity.name == "spidertron-dock" then
        update_dock_gui_for_player(
            game.get_player(event.player_index),
            event.entity
        )
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if element.name == "spidertron-undock-button" then
        attempt_undock(
            get_dock_data_from_unit_number(
                element.parent.tags.dock_unit_number))
    end
end)