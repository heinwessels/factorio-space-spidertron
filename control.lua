local spidertron_lib = require("script.lib.spidertron_lib")

script.on_configuration_changed(function (event)
    global.docks = global.docs or {}
end)

function area_around_position(position, width, height)
    height = height or width
    return {
        left_top = { 
            x = position.x - width / 2, 
            y = position.y - height / 2
        },
        right_bottom = {
            x = position.x + width / 2, 
            y = position.y + height / 2
        }
    }
end

function create_dock_data(dock_entity)
    return {
        occupied = false,
        serialized_spider = nil,
        docked_sprites = {},

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

function draw_docked_spider(dock_data, spider)
    local dock = dock_data.dock_entity

    -- Offset to place sprite at correct location
    -- This assumes we're not drawing the bottom
    local offset = {-0.1, -0.3}
    
    -- Draw shadows
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "docked-"..spider.name.."-shadow", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
        }
    )

    -- First draw main layer
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "docked-"..spider.name.."-main", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
        }
    )

    -- Then draw tinted layer
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "docked-"..spider.name.."-tint", 
            target = dock, 
            surface = dock.surface,
            tint = spider.color,
            target_offset = offset,
        }
    )
end

-- This function will attempt the dock
-- of a spider. It will only work if
-- it's above a valid dock, etc.
function attempt_dock(spider)

    -- Check if there's a dock below
    -- TODO this functionality
    --  Maybe spider can stop closer?
    local dock = spider.surface.find_entities_filtered{
        name = "spidertron-dock",
        area = area_around_position(spider.position, 3, 3),
        force = spider.force
    }[1]
    if not dock then return end
    if dock.force ~= spider.force then return end

    -- Check if dock is occupied
    local dock_data = get_dock_data_from_entity(dock)
    if dock_data.occupied then return end

    -- Dock the spider!
    draw_docked_spider(dock_data, spider)
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

function on_built(event)
    -- If it's a space spidertron, set it to white as default
    local entity = event.created_entity
    if entity and entity.valid then
        if entity.name == "space-spidertron" then
            entity.color = {1, 1, 1, 0.5} -- White
        end
    end
end

function update_dock_gui_for_player(player, dock)
    -- Get dock data
    local dock_data = get_dock_data_from_entity(dock)
    
    -- Destroy whatever is there currently
    for _, elem in pairs(player.gui.relative.children) do
        if elem.name == "dock-frame" then elem.destroy() end
    end
    
    if dock_data.occupied then
        -- Build a new gui!
        -- TODO Need to update this when something docks

        -- Build starting frame
        local anchor = {
            gui=defines.relative_gui_type.accumulator_gui, 
            position=defines.relative_gui_position.right
        }
        local frame = player.gui.relative.add{name="dock-frame", type="frame", anchor=anchor}

        -- Add button
        frame.add{
            type = "button",
            name = "spidertron-undock-button",
            caption = {"space-spidertron-dock.undock"},
            style = "green_button",
            tags = {
                dock_unit_number = dock.unit_number
            }
        }
    end

end

script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_built_entity, on_built)

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
                element.tags.dock_unit_number))
    end
end)