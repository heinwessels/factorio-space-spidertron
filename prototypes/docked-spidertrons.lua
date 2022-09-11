-- When a spidertron is docked the spider will
-- be replaced by a different spider-vehicle entity
-- which is a copy of the original one. This is changed
-- from the sprite system because an entity will have
-- functioning inventory, and logistics.

-- Notes:
--      Will still draw sprite, because spider will always be drawn on top
--          and we want the tall entities below the dock to draw over the
--          docked spider
--      To stop bouncing set entity to active==false
--          Manually charge all equipment then through dock
--          Except automatic-targetting weapons, deplete them of energy
--              Docked spiders shall not be used as defense.
--          Still allows logistic requests to be furfilled

local util = require("__core__/lualib/util")

local spider_black_list = {
    -- Space Exploration
    ["se-burbulator"] = true,

    -- Companions
    ["companion"] = true,

    -- Combat Robots Overhaul
    ["defender-unit"] = true,
    ["destroyer-unit"] = true,
}

-- An unmovable leg that will be used for all
-- docked spidertrons
data:extend{{
    type = "spider-leg",
    name = "ss-dead-leg",
    collision_box = nil,
    collision_mask = {},
    selection_box = {{-0, -0}, {0, 0}},
    icon = "__base__/graphics/icons/spidertron.png",
    icon_size = 64, icon_mipmaps = 4,
    walking_sound_volume_modifier = 0,
    target_position_randomisation_distance = 0,
    minimal_step_size = 0,
    working_sound = nil,
    part_length = 1,
    initial_movement_speed = 0,
    movement_acceleration = 0,
    max_health = 1,
    movement_based_position_selection_distance = 0,
    selectable_in_game = false,
    graphics_set = create_spidertron_leg_graphics_set(0, 1)
}}

-- We will create a custom sprite to place when then
-- spider is docked. Using the regular spider sprites
-- will draw them on top of everything, which is not
-- what we want. 
function create_docked_spider_sprite(spider)
    local main_layers = {}
    local shadow_layers = {}
    local tint_layers = {}

    -- Try to build the sprite. We will only care about
    --  Base: The stationary frame at the bottom
    --      Here will will remove any potential layers with the
    --      word "flame" in the file name. Flames will burn the dock
    --  Animation: The part that turns
    --  Shadow: It's shadow
    --      Only here will we not expect layers
    --      What if it is though? FAIL!

    -- Using these sprites we will build our own three sprites
    -- that we layer during runtime. This will be:
    --      Main: The body, essentially a single rotation of the animation
    --      Tint: Only the tinted layers to give the docked spider the correct colours
    --      Shadow: Yup...

    if not spider.minable then return end
    
    if not spider.graphics_set then return end
    if not spider.graphics_set.base_animation then return end
    if not spider.graphics_set.animation then return end
    if not spider.graphics_set.shadow_animation then return end

    local torso_bottom_layers = util.copy(spider.graphics_set.base_animation.layers)
    local torso_body_layers = util.copy(spider.graphics_set.animation.layers)
    local torso_body_shadow = util.copy(spider.graphics_set.shadow_animation)

    if not torso_bottom_layers or not torso_body_layers or not torso_body_shadow then return end

    -- AAI Programmable Vehicles compatability:
    -- We don't display the AI version of the spider. Such spiders usually
    -- end with "-rocket-1" or something. This is a silly check, but should
    -- be good enough for now.
    if string.match(spider.name, "-[0-9]+$") then return end

    -- Sanitize and add the bottom layers
    for index, layer in pairs(torso_bottom_layers) do
        -- Actually, we don't want to draw the bottom.
        -- The spider sits much more snugly if we don't
        -- draw the bottom. Changing this requires 
        -- changing where the sprite is drawn
        break

        -- Only use non-flame layers
        -- Only looking at the bottom because that's likely where they will exist
        if not layer.filename:find("flame") then
            if layer.apply_runtime_tint then
                table.insert(tint_layers, layer)
            else
                table.insert(main_layers, layer)
            end
        end
    end

    -- Sanitize the and add the body layer. 
    for index, layer in pairs(torso_body_layers) do

        -- Rudemental sanity check to see if this is a
        -- normal-ish spidertron
        if layer.direction_count ~= 64 then return end

        -- The body layer contains animations for all rotations,
        -- So change {x,y} to a nice looking one
        -- TODO This can be smarter
        layer.x = layer.width * 4
        layer.y = layer.height * 4
        layer.hr_version.x = layer.hr_version.width * 4
        layer.hr_version.y = layer.hr_version.height * 4
        
        if layer.apply_runtime_tint then
            table.insert(tint_layers, layer)
        else
        table.insert(main_layers, layer)
        end
    end

    -- Sanitize the and add the shadow layers
    -- NB: We're not building the "bottom" shadows,
    -- because the bottom is not currently drawn
    for index, layer in pairs({torso_body_shadow}) do

        -- Rudemental sanity check to see if this is a
        -- normal-ish spidertron
        if layer.direction_count ~= 64 then return end

        -- The body layer contains animations for all rotations,
        -- So change {x,y} to a nice looking one
        -- TODO This can be smarter
        layer.x = layer.width * 4
        layer.y = layer.height * 4
        layer.hr_version.x = layer.hr_version.width * 4
        layer.hr_version.y = layer.hr_version.height * 4
        
        table.insert(shadow_layers, layer)
    end

    if not next(shadow_layers) or not next(main_layers) or not next(tint_layers) then return end

    -- Add the sprites
    data:extend{
        {
            type = "sprite",
            name = "ss-docked-"..spider.name.."-shadow",
            layers = shadow_layers,
            flags = {"shadow"},
            draw_as_shadow = true,
        },
        {
            type = "sprite",
            name = "ss-docked-"..spider.name.."-main",
            layers = main_layers,
        },
        {
            type = "sprite",
            name = "ss-docked-"..spider.name.."-tint",
            layers = tint_layers,
        },
    }

    return true
end

-- This function will dictate if a spider is
-- dockable or not. If we can build a docked-spider
-- for it to show during docking, then it's
-- dockable. If we find anything that we don't
-- expect, then we abort the spider, and it won't
-- be dockable. It will be checked during runtime
-- if this dummy entity exist, which dictates if
-- a spider type is dockable
function attempt_docked_spider(spider)
    
    -- Some basic checks
    if not spider.minable then return end


    -- Create the sprites we will use. If it failed then we assume
    -- the spider is not dockable
    if not create_docked_spider_sprite(spider) then return false end

    -- Good enough to start the construction attempt
    local docked_spider = util.copy(spider)
    docked_spider.name = "ss-docked-"..spider.name
    docked_spider.localised_name = {"space-spidertron-dock.docked-spider", spider.name}
    
    docked_spider.minable.mining_time = 1
    docked_spider.allow_passengers = false
    docked_spider.height = 0.35 -- To place spider on top of dock
    docked_spider.selection_box = {{-1, -1}, {1, 0.5}}
    docked_spider.collision_box = nil
    docked_spider.minimap_representation = nil
    docked_spider.selected_minimap_representation = nil

    -- Replace the leg with the invisible dead one
    docked_spider.spider_engine = {
      legs = {{
          leg = "ss-dead-leg",
          mount_position = {0, 0},
          ground_position = {0, 0},
          blocking_legs = {1},
          leg_hit_the_ground_trigger = nil
        }}
    }

    -- Remove base layers TODO Replace with light layer
    docked_spider.graphics_set.base_animation = util.empty_sprite(1)    -- Will also remove flames
    docked_spider.graphics_set.shadow_base_animation = util.empty_sprite(1)
    -- Change render layer so it's not on top of everything
    docked_spider.graphics_set.render_layer = "object"

    return docked_spider
end

-- Loop through all spider vehicles
local found_at_least_one = false
local docked_spiders = {}   -- Cannot insert in the loop, otherwise infinite loop
local dock_description = data.raw.accumulator["ss-spidertron-dock"].localised_description
for _, spider in pairs(data.raw["spider-vehicle"]) do
    if not spider_black_list[spider.name] then
        local docked_spider = attempt_docked_spider(spider)
        if docked_spider then 
            table.insert(docked_spiders, docked_spider)
            found_at_least_one = true

            -- Update dock description to show supported 
            -- This will update both the entity and the item
            -- because they use the same table
            if (#dock_description + 1) < 20 then -- +1 for the empty "" at the start
                if (#dock_description + 1) < 19 then
                    table.insert(dock_description, 
                        {"space-spidertron-dock.supported-spider", spider.name})
                else
                    table.insert(dock_description, {"space-spidertron-dock.etc"})
                end
            end
        end
    end
end
if not found_at_least_one then
    error("Could not find any spiders that can dock")
end
for _, docked_spider in pairs(docked_spiders) do data:extend{docked_spider} end

-- Create the docking light. Will have to be drawn on top
-- manually too.
data:extend{
    {
        -- We declare it as an animation because that can
        -- animate and have act as a light as well
        type = "animation",
        name = "ss-docked-light",
        layers = {
            {
                filename = "__space-spidertron__/graphics/spidertron-dock/dock-light.png",
                blend_mode = "additive",
                draw_as_glow = true,    -- Draws a sprite and a light
                width = 19,
                height = 19,
                shift = { -0.42, 0.5 },
                scale = 0.4,
                run_mode = "forward-then-backward",
                frame_count = 16,
                line_length = 8,
                -- 3 second loop, meaning 16 frames per 180 ticks
                animation_speed = 0.088, -- frames per tick

                hr_version =
                {
                    filename = "__space-spidertron__/graphics/spidertron-dock/dock-light.png",
                    blend_mode = "additive",
                    draw_as_glow = true,    -- Draws a sprite and a light
                    width = 19,
                    height = 19,
                    shift = { -0.42, 0.5 },
                    scale = 0.4,
                    run_mode = "forward-then-backward",
                    frame_count = 16,
                    line_length = 8,

                    -- 3 second loop, meaning 16 frames per 180 ticks
                    animation_speed = 0.088, -- frames per tick
                }
            }
        }
    }
}
