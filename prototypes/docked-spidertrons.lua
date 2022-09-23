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

local registry = require("registry")

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
    if not spider.minable then return end    
    if not spider.graphics_set then return end
    if not spider.graphics_set.base_animation then return end
    if not spider.graphics_set.animation then return end
    if not spider.graphics_set.shadow_animation then return end

    -- Good enough to start the construction attempt
    local docked_spider = util.copy(spider)
    docked_spider.name = "ss-docked-"..spider.name
    docked_spider.localised_name = {"space-spidertron-dock.docked-spider", spider.name}
    
    docked_spider.minable = {result = nil, mining_time = 1}
    docked_spider.torso_bob_speed = 0
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
    docked_spider.graphics_set.base_animation = {layers={
        -- Will also remove flames
        {
            filename = "__space-spidertron__/graphics/spidertron-dock/dock-light.png",
            blend_mode = "additive",
            direction_count = 1,
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
                direction_count = 1,
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
    }}
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
    if not registry.is_blacklisted(spider.name) then
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
