local util = require("__core__/lualib/util")
local spidertron_lib = require("lib.spidertron_lib")

local function name_is_dock(name)
    return not (string.match(name, "ss[-]spidertron[-]dock") == nil)
end

local function name_is_docked_spider(name)
    return not (string.match(name, "ss[-]docked[-]") == nil)
end

function create_dock_data(dock_entity)
    return {
        occupied = false,

        -- Remember the normal type of the spider docked here
        spider_name = nil,

        -- Keep a reference to the docked spider
        -- Only used when in `active` mode
        docked_spider = nil,

        -- Keep track of sprites drawed so we
        -- can pop them out later.
        docked_sprites = {},

        -- Keeps a serialised version of the spider
        -- Only used when in `passive` mode
        serialised_spider = nil,

        -- Can be nil when something goes wrong
        dock_entity = dock_entity,

        -- Keep this in here so that it's easy to
        -- find this entry in global
        unit_number = dock_entity.unit_number,

        -- 'active' or `passive`. 
        -- Dictates if an actual spider is placed
        -- while docking, or only a sprite.
        mode = string.find(dock_entity.name, "passive") and "passive" or "active",
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
    if not name_is_dock(dock.name) then return end
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

local function draw_docked_spider(dock, spider_name, color)
    local dock_data = get_dock_data_from_entity(dock)
    dock_data.docked_sprites = dock_data.docked_sprites or {}

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
            animation_offset = math.random(15) -- Not sure how to start at frame 0
        }
    )
end

-- Destroys sprites from a dock and also removes
-- their entries in it's data
local function pop_dock_sprites(dock_data)
    for _, sprite in pairs(dock_data.docked_sprites) do
        rendering.destroy(sprite)
    end
    dock_data.docked_sprites = {}
end

-- A regular spider turns into a serialised version ready
-- for docking. This will remove the spider entity and is
-- the first step of the actual docking procedure
local function dock_from_spider_to_serialised(dock, spider)
    local dock_data = get_dock_data_from_entity(dock)
    dock_data.spider_name = spider.name
    local serialised_spider = spidertron_lib.serialise_spidertron(spider)    
    spider.destroy{raise_destroy=true}  -- This will clean the spider data in the destroy event
    dock_data.occupied = true
    return serialised_spider
end

-- A serialised spider turns back into the regular spider
-- This is the last step of the actual undocking procedure
local function dock_from_serialised_to_spider(dock, serialised_spider)
    local dock_data = get_dock_data_from_entity(dock)
    local spider = dock.surface.create_entity{
        name = dock_data.spider_name,
        position = dock.position,
        force = dock.force,
        create_build_effect_smoke = false,
        raise_built = true,                 -- Regular spider it is
    }
    spidertron_lib.deserialise_spidertron(spider, serialised_spider)
    spider.torso_orientation = 0.58 -- orientation of sprite
    local spider_data = get_spider_data_from_entity(spider)
    spider_data.last_used_dock = dock
    dock_data.occupied = false
    return spider
end

-- Dock a spider passively to a dock. This means that
-- spider-sprites are drawn and the serialization info 
-- is stored in the dock
local function dock_from_serialised_to_passive(dock, serialised_spider)
    local dock_data = get_dock_data_from_entity(dock)
    dock_data.serialised_spider = serialised_spider
    draw_docked_spider(dock, dock_data.spider_name, serialised_spider.color)
end

-- Returns the serialised version of a passively docked spider
-- this will also pop the sprites
local function dock_from_passive_to_serialised(dock)
    local dock_data = get_dock_data_from_entity(dock)
    pop_dock_sprites(dock_data)
    local serialised_spider = dock_data.serialised_spider
    dock_data.serialised_spider = nil
    return serialised_spider
end

-- Dock a spider actively to a dock. This means a docked-version
-- of the spider is placed on the dock
local function dock_from_serialised_to_active(dock, serialised_spider)
    local dock_data = get_dock_data_from_entity(dock)
    local docked_spider = dock.surface.create_entity{
        name = "ss-docked-"..dock_data.spider_name,
        position = {
            dock.position.x,
            dock.position.y + 0.004 -- To draw spidertron over dock entity
        },
        force = dock.force,
        create_build_effect_smoke = false,
        raise_built = false, -- Because it's not a real spider
    }
    docked_spider.destructible = false -- Only dock can be attacked
    spidertron_lib.deserialise_spidertron(docked_spider, serialised_spider)
    docked_spider.torso_orientation = 0.58 -- Looks nice
    local docked_spider_data = get_spider_data_from_entity(docked_spider)
    docked_spider_data.original_spider_name = serialised_spider.name
    docked_spider_data.armed_for = dock
    dock_data.docked_spider = docked_spider
end

-- Retreives the serialised version of an actively docked spider
-- this will remove the docked spider version
local function dock_from_active_to_serialised(dock)
    local dock_data = get_dock_data_from_entity(dock)
    local docked_spider = dock_data.docked_spider
    if not docked_spider or not docked_spider.valid then return end
    local serialised_spider = spidertron_lib.serialise_spidertron(docked_spider)
    global.spiders[docked_spider.unit_number] = nil -- Because no destroy event will be called
    docked_spider.destroy{raise_destroy=false}      -- False because it's not a real spider
    dock_data.docked_spider = nil
    return serialised_spider
end

-- This will dock a spider, and not
-- do any checks.
function dock_spider(dock, spider)
    local dock_data = get_dock_data_from_entity(dock)

    -- Some smoke and mirrors
    dock.create_build_effect_smoke()
    dock.surface.play_sound{path="ss-spidertron-dock-1", position=dock.position}
    dock.surface.play_sound{path="ss-spidertron-dock-2", position=dock.position}
    
    -- Docking procedure
    local serialised_spider = dock_from_spider_to_serialised(dock, spider)
    if dock_data.mode == "passive" then
        dock_from_serialised_to_passive(dock, serialised_spider)
    else
        dock_from_serialised_to_active(dock, serialised_spider)
    end
end

-- This will undock a spider, and not
-- do any checks.
function undock_spider(dock)
    local dock_data = get_dock_data_from_entity(dock)

    -- Some smoke and mirrors
    dock.surface.play_sound{path="ss-spidertron-undock-1", position=dock.position}
    dock.surface.play_sound{path="ss-spidertron-undock-2", position=dock.position}

    -- Undocking procedure
    local serialised_spider = nil
    if dock_data.mode == "passive" then
        serialised_spider = dock_from_passive_to_serialised(dock)
    else
        serialised_spider = dock_from_active_to_serialised(dock)
    end
    return dock_from_serialised_to_spider(dock, serialised_spider)
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
        name = {"ss-spidertron-dock-active", "ss-spidertron-dock-passive"},
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
    dock_spider(dock, spider)

    -- Update GUI's for all players
    for _, player in pairs(game.players) do
        update_spider_gui_for_player(player)
        update_dock_gui_for_player(player, dock)
    end
end

function attempt_undock(dock_data, player, force)
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
    local spider = undock_spider(dock)

    -- close the gui since player likely just wanted to undock he spider
    if player then
        player.opened = nil
    end

    -- Destroy GUI for all players
    for _, player in pairs(game.players) do
        update_spider_gui_for_player(player, spider)
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

script.on_event(defines.events.on_player_used_spider_remote,
    function (event)
        local spider = event.vehicle
        if spider and spider.valid then
            local spider_data = get_spider_data_from_entity(spider)

            -- First check if this is a docked spider. If it is, then
            -- will attempt an undock.
            if name_is_docked_spider(spider.name) then
                local dock = spider_data.armed_for
                if not dock or not dock.valid then return end
                local dock_data = get_dock_data_from_entity(dock)
                local player = game.get_player(event.player_index)
                attempt_undock(dock_data, player, player.force)
                return
            end
            
            -- Now we know the current spider is not a docked version. Check if the player
            -- is directing a spider to a dock to dock the spider
            local dock = spider.surface.find_entity("ss-spidertron-dock-active", event.position)
            if not dock then
                dock = spider.surface.find_entity("ss-spidertron-dock-passive", event.position)
            end
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
    local player = event.player_index and game.get_player(event.player_index) or nil
    if entity and entity.valid then
        if name_is_dock(entity.name) then
            attempt_undock(get_dock_data_from_entity(entity), player, true)
            global.docks[entity.unit_number] = nil
        elseif entity.type == "spider-vehicle" then
            if name_is_docked_spider(entity.name) then
                local spider_data = get_spider_data_from_entity(entity)
                local dock = spider_data.armed_for
                if not dock or not dock.valid then return end
                local dock_data = get_dock_data_from_entity(dock)
                attempt_undock(dock_data, player, true)
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

-- This will toggle the dock between active and passive mode.
-- This will change the actual dock entity below so that
-- it's easy to copy-paste with settings. And have better tooltips
script.on_event("ss-spidertron-dock-toggle", function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local dock = player.selected
    if not dock or not dock.valid then return end
    if dock.force ~= player.force then return end
    if not name_is_dock(dock.name) then return end
    
    -- By this point we know that this is a dock the player can toggle
    -- We need to be careful with the data
    local dock_data = get_dock_data_from_entity(dock)

    -- Toggle the mode
    local new_mode = dock_data.mode == "active" and "passive" or "active"

    -- Create the new entity
    local new_dock = dock.surface.create_entity{
        name = "ss-spidertron-dock-"..new_mode,
        position = dock.position,
        force = dock.force,
        create_build_effect_smoke = false,
        raise_built = true,
        player = player,
    } -- Will set the mode correctly
    new_dock.health = dock.health
    new_dock.energy = dock.energy

    -- Transfer the data
    local key_blacklist = {
        ["mode"]=true,
        ["dock_entity"]=true,
        ["unit_number"]=true,
        ["dock_unit_number"]=true}
    local new_dock_data = get_dock_data_from_entity(new_dock)
    for key, value in pairs(dock_data) do
        if not key_blacklist[key] then
            new_dock_data[key] = value
        end
    end

    -- Process the docking procedure
    if new_dock_data.occupied then        
        if new_dock_data.mode == "active" then
            -- Dock was passive, so now we need to create a spider entity
            local serialised_spider = dock_from_passive_to_serialised(new_dock)
            dock_from_serialised_to_active(new_dock, serialised_spider)
        else
            -- Dock was active, so now we remove a spider entity
            local serialised_spider = dock_from_active_to_serialised(new_dock)
            dock_from_serialised_to_passive(new_dock, serialised_spider)
        end
        
        -- Play nice sound if dock is occupied
        dock.surface.play_sound{
            path="ss-spidertron-dock-mode-"..new_dock_data.mode, 
            position=new_dock.position
        }
    end

    dock.surface.create_entity{
        name = "flying-text",
        position = dock.position,
        text = {"space-spidertron-dock.mode-to-"..new_dock_data.mode},
        color = {r=1,g=1,b=1,a=1},
    }

    -- Remove the old dock data first otherwise the deconstrcut handler
    -- will think the dock is still occupied
    global.docks[dock_data.unit_number] = nil
    dock.destroy{raise_destroy=true}
end)

-- We can move docks with picker dollies, regardless
-- of if it contains a spider or not. We do not allow
-- moving the spiders though 
function picker_dollies_move_event(event)
    local entity = event.moved_entity
    if entity.name == "ss-spidertron-dock-active" then
        local dock_data = get_dock_data_from_entity(entity)
        if dock_data.occupied then
            dock_data.docked_spider.teleport({
                entity.position.x,
                entity.position.y + 0.01 -- To draw spidertron over dock entity
            }, entity.surface)
        end
    elseif entity.name == "ss-spidertron-dock-passive" then
        -- This event should handle itself, because the
        -- sprites are attached to the dock
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
        if name_is_dock(source.name) then
            local source_dock_data = get_dock_data_from_entity(source)
            if source_dock_data.occupied then
                local destination_dock_data = get_dock_data_from_entity(destination)

                -- First transfer all saved data. And then remove what we don't need
                -- Doing this funky transfer to also include whatever new fields we might add
                local key_blacklist = {
                    ["dock_entity"]=true, 
                    ["unit_number"]=true, 
                    ["dock_unit_number"]=true}
                for key, value in pairs(source_dock_data) do
                    if not key_blacklist[key] then
                        destination_dock_data[key] = value
                    end
                end
                
                if source_dock_data.mode == "active" then
                    local docked_spider = source_dock_data.docked_spider
                    local spider_data = get_spider_data_from_entity(docked_spider)
                    spider_data.armed_for = destination 

                    -- Move spider entity
                    docked_spider.teleport({
                        destination.position.x,
                        destination.position.y + 0.01 -- To draw spidertron over dock entity
                    }, destination.surface)

                else
                    -- 'passive' mode
                    pop_dock_sprites(source_dock_data)
                    draw_docked_spider(
                        destination,
                        destination_dock_data.spider_name,
                        destination_dock_data.serialised_spider.color
                    )
                end

                -- Remove the old dock data entry
                global.docks[source.unit_number] = nil -- Reset old dock
            end
        elseif name_is_docked_spider(source.name) then
            -- Destroy cloned docked spiders. We just move the old one
            -- The data will be destroyed with the dock transfer
            destination.destroy{raise_destroy=false}
        end
    end
end)

function update_spider_gui_for_player(player, spider)
    
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
    -- Now redraw it if we're looking at a docked spider
    
    if not spider then return end
    local spider_data = get_spider_data_from_entity(spider)
    if not name_is_docked_spider(spider.name) then return end

    -- Decide if we should rebuild. We will only build
    -- if the player is currently looking at this docked spider
    if player.opened 
            and (player.opened == spider) 
            and spider_data.armed_for.valid then
        -- Build a new gui!

        -- Build starting frame
        local anchor = {
            gui=defines.relative_gui_type.spider_vehicle_gui, 
            position=defines.relative_gui_position.top
        }
        local invisible_frame = player.gui.relative.add{
            name="ss-docked-spider", 
            type="frame", 
            style="ss_invisible_frame",
            anchor=anchor,

            tags = {spider_unit_number = spider.unit_number}
        }

        -- Add button
        invisible_frame.add{
            type = "button",
            name = "spidertron-undock-button",
            caption = {"space-spidertron-dock.undock"},
            style = "ss_undock_button",
        }
    end
end

function update_dock_gui_for_player(player, dock)
    
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
    local dock_data = get_dock_data_from_entity(dock)
    if not dock_data then return end -- Other accumulator type
    if not dock_data.occupied then return end

    -- Decide if we should rebuild. We will only build
    -- if the player is currently looking at this dock
    if player.opened and (player.opened == dock) then
        -- Build a new gui!

        -- Build starting frame
        local anchor = {
            gui=defines.relative_gui_type.accumulator_gui, 
            position=defines.relative_gui_position.top
        }
        local invisible_frame = player.gui.relative.add{
            name="ss-spidertron-dock", 
            type="frame", 
            style="ss_invisible_frame",
            anchor=anchor,

            tags = {dock_unit_number = dock.unit_number}
        }

        -- Add button
        invisible_frame.add{
            type = "button",
            name = "spidertron-undock-button",
            caption = {"space-spidertron-dock.undock"},
            style = "ss_undock_button",
        }
    end
end

script.on_event(defines.events.on_gui_opened, function(event)
    local entity = event.entity
    if not entity then return end
    if event.gui_type == defines.gui_type.entity then
        -- Need to check all versions of specific entity
        -- type. Otherwise it will draw it for those too.
        if entity.type == "spider-vehicle" then
            update_spider_gui_for_player(
                game.get_player(event.player_index),
                event.entity
            )
        elseif entity.type == "accumulator" then
            update_dock_gui_for_player(
                game.get_player(event.player_index),
                event.entity
            )
        end
    end
end)

-- This event is called from both the dock gui and the
-- spidertron gui
script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    local player = game.get_player(event.player_index)
    if element.name == "spidertron-undock-button" then
        local parent = element.parent 
        local dock_data = nil        
        if parent.name == "ss-spidertron-dock" then
            dock_data = global.docks[parent.tags.dock_unit_number]
        elseif parent.name == "ss-docked-spider" then
            local spider_data = get_spider_data_from_unit_number(
                element.parent.tags.spider_unit_number)
            if not spider_data then return end
            if not spider_data.armed_for.valid then return end
            dock_data = get_dock_data_from_entity(spider_data.armed_for)
        end
        if not dock_data then return end
        attempt_undock(dock_data, player)
    end
end)

-- It might be that some docks had their docked
-- spidey removed because mods changed. Clean them up
local function sanitize_docks()
    local marked_for_deletion = {}
    for unit_number, dock_data in pairs(global.docks) do
        local dock = dock_data.dock_entity
        if dock and dock.valid then
            if dock_data.occupied then
                if dock_data.mode == "active" then
                    if dock_data.docked_spider and not dock_data.docked_spider.valid then
                        -- This spider entity is no longer supported for docking. In this
                        -- case the data will be lost
                        table.insert(marked_for_deletion, unit_number)
                    end
                elseif dock_data.mode == "passive" then
                    if not global.spider_whitelist[dock_data.spider_name] then
                        -- This spider is no longer supported. We can undock the spider though
                        -- because we still have the serialized information
                        attempt_undock(dock_data, nil, true)
                        table.insert(marked_for_deletion, unit_number)
                    end
                end
            end
        else
            -- TODO There is some unhandled edge cases here, but
            -- I'll fix them later. This will only occur if a script
            -- destroys a dock without an event, which should not happen.
            table.insert(marked_for_deletion, unit_number)
        end
    end

    -- Clean up docks I marked for deletion
    for _, unit_number in pairs(marked_for_deletion) do
        global.docks[unit_number] = nil
    end
end

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
            if name_is_docked_spider(spider.name) then
                remote.call("PickerDollies", "add_blacklist_name",  spider.name)
            end
        end
    end
end

if script.active_mods["SpidertronEnhancements"] then
    -- This event fires when Spidertron Enhancements is used
    -- and a waypoint-with-pathfinding is created. This mod
    -- has a check ignore docked spidertrons, but we still
    -- want to send a message.
    script.on_event("spidertron-enhancements-use-alt-spidertron-remote", function(event)
        local player = game.get_player(event.player_index)
        if not player then return end
        local cursor_item = player.cursor_stack
        if cursor_item and cursor_item.valid_for_read and (cursor_item.type == "spidertron-remote" and cursor_item.name ~= "sp-spidertron-patrol-remote") then
            local spider = cursor_item.connected_entity
            if spider and string.match(spider.name, "ss[-]docked[-]") then            
                -- Prevent the auto pilot in case, but shouldn't be required
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
            end
        end
    end
    )
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
    
    picker_dollies_blacklist_docked_spiders()
    sanitize_docks()

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
