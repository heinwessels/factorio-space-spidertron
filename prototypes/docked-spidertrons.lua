-- When a spidertron is docked the spider will
-- be replaced by a different spider-vehicle entity
-- which is a copy of the original one. This is changed
-- from the sprite system because an entity will have
-- functioning inventory, and logistics.

-- Notes:
--      Might still draw sprite, because spider will always be drawn on top
--      To stop bouncing set entity to active==false
--          Manually charge all equipment then through dock
--          Except automatic-targetting weapons, deplete them of energy
--              Docked spiders shall not be used as defense.
--          Still allows logistic requests to be furfilled

local util = require("__core__/lualib/util")

local spider_black_list = {
    ["se-burbulator"] = true,
    ["companion"] = true,
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

    -- Spider must graphics of course
    if not spider.graphics_set then return end
    if not spider.graphics_set.base_animation then return end
    if not spider.graphics_set.animation then return end
    if not spider.graphics_set.shadow_animation then return end

    -- Good enough to start the construction attempt
    local docked_spider = util.copy(spider)
    docked_spider.name = "ss-docked-"..docked_spider.name
    
    docked_spider.minable.mining_time = 5
    docked_spider.allow_passengers = false

    -- Spider cannot walk, and therefore doesn't need power source
    -- We will have to keep track of docked energy sources
    docked_spider.energy_source = { type = "void" }
    
    -- Spider cannot fire at anything while docked.
    -- We will have to keep track of docked-guns
    docked_spider.guns = {}

    -- Should not show on minimap while docked
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

    -- Remove the base animation layers, and replace
    -- it with our light sprite
    docked_spider.graphics_set.base_animation.layers = {
        {
            filename = "__space-spidertron__/graphics/spidertron-dock/dock-light.png",
            direction_count = "1",
            blend_mode = "additive",
            draw_as_glow = true,    -- Draws a sprite and a light
            width = 19,
            height = 19,
            shift = { -0.42, 0.5 },
            scale = 0.4,
            run_mode = "forward-then-backward",
            frame_count = 16,
            line_length = 8,
            animation_speed = 0.088, -- 3 second loop, meaning 16 frames per 180 ticks

            hr_version =
            {
                filename = "__space-spidertron__/graphics/spidertron-dock/dock-light.png",
                direction_count = "1",
                blend_mode = "additive",
                draw_as_glow = true,    -- Draws a sprite and a light
                width = 19,
                height = 19,
                shift = { -0.42, 0.5 },
                scale = 0.4,
                run_mode = "forward-then-backward",
                frame_count = 16,
                line_length = 8,
                animation_speed = 0.088, -- 3 second loop, meaning 16 frames per 180 ticks
            }
        }
    }

    return docked_spider
end
-- Loop through all spider vehicles
local docked_spiders = {}   -- Cannot insert in the loop, otherwise infinite loop
for _, spider in pairs(data.raw["spider-vehicle"]) do
    if not spider_black_list[spider.name] then
        local docked_spider = attempt_docked_spider(spider)
        if docked_spider then table.insert(docked_spiders, docked_spider) end
    end
end
for _, docked_spider in pairs(docked_spiders) do data:extend{docked_spider} end