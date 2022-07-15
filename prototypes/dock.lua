local sounds = require("__base__.prototypes.entity.sounds")

local localised_description = {"", 
  {"space-spidertron-dock.description"}, 
  {"space-spidertron-dock.description-use"}
}
if mods["space-exploration"] then
  localised_description = {"", 
    {"space-spidertron-dock.description-se"}, 
    {"space-spidertron-dock.description-use"}
  }
end

local dock = {
    -- Type radar so that we have an animation to work with
    type = "accumulator",
    name = "ss-spidertron-dock",
    icon = "__space-spidertron__/graphics/spidertron-dock/dock-icon.png",
    localised_description = localised_description,
    minable = {mining_time = 0.1, result = "ss-spidertron-dock"},
    icon_size = 64, icon_mipmaps = 4,
    flags = {"placeable-player", "player-creation"},
    max_health = 250,
    corpse = "medium-remnants",
    dying_explosion = "medium-explosion",
    collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
    selection_box = {{-1, -1}, {1, 1}},
    charge_cooldown = 30,
    discharge_cooldown = 60,
    energy_per_nearby_scan = "1J",
    energy_source = {
      type = "void",
      buffer_capacity = "1J",
      usage_priority = "tertiary",
      input_flow_limit = "1W",
      output_flow_limit = "1W",
      render_no_network_icon = false,
      render_no_power_icon = false,
    },
    picture =
    {
      layers =
      {
        {
              -- Using "HR" for both, since it's more like halfway between
              -- high and normal resolution
              filename = "__space-spidertron__/graphics/spidertron-dock/hr-dock.png",
              priority = "low",
              width = 113,
              height = 120,
              direction_count = 1,
              shift = util.by_pixel(0, -4),
              scale = 0.6,
              hr_version = {
                  filename = "__space-spidertron__/graphics/spidertron-dock/hr-dock.png",
                  priority = "low",
                  width = 113,
                  height = 120,
                  direction_count = 1,
                  shift = util.by_pixel(0, -4),
                  scale = 0.6,
              }
          },
          {
            -- Using "HR" for both, since it's more like halfway between
            -- high and normal resolution
            filename = "__space-spidertron__/graphics/spidertron-dock/dock-shadow.png",
            priority = "low",
            width = 126,
            height = 80,
            direction_count = 1,
            shift = util.by_pixel(20, 6),
            scale = 0.6,
            draw_as_shadow = true,
            hr_version = {
                filename = "__space-spidertron__/graphics/spidertron-dock/dock-shadow.png",
                priority = "low",
                width = 126,
                height = 80,
                direction_count = 1,
                shift = util.by_pixel(20, 6),
                scale = 0.6,
                draw_as_shadow = true,
            }
          },
      }
    },
    vehicle_impact_sound = sounds.generic_impact,
    working_sound =
    {
      sound =
      {
        {
          filename = "__base__/sound/accumulator-working.ogg",
          volume = 0.8
        }
      },
      --persistent = true,
      max_sounds_per_type = 3,
      audible_distance_modifier = 0.5,
      fade_in_ticks = 4,
      fade_out_ticks = 20
    },
    radius_minimap_visualisation_color = { r = 0.059, g = 0.092, b = 0.235, a = 0.275 },
    rotation_speed = 0.01,
    water_reflection =
    {
      pictures =
      {
        filename = "__base__/graphics/entity/radar/radar-reflection.png",
        priority = "extra-high",
        width = 28,
        height = 32,
        shift = util.by_pixel(5, -15),
        variation_count = 1,
        scale = 5
      },
      rotate = false,
      orientation_to_variation = false
    }
}

local dock_item = {
    type = "item",
    name = "ss-spidertron-dock",
    icon = "__space-spidertron__/graphics/spidertron-dock/dock-icon.png",
    localised_description = localised_description,
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "transport",
    order = "b[personal-transport]-c[spidertron]-d[spidertron-dock]",
    place_result = "ss-spidertron-dock",
    stack_size = 20
}

local dock_recipe = {
    type = "recipe",
    name = "ss-spidertron-dock",
    enabled = false,
    energy_required = 10,
    ingredients = {
        {"steel-plate", 20},
        {"low-density-structure", 10},
        {"engine-unit", 10},        
        {"rocket-control-unit", 5},
    },
    result = "ss-spidertron-dock"
}

data:extend{dock, dock_item, dock_recipe}