local util = require("__core__/lualib/util")

local localised_description = nil
if mods["space-exploration"] then
  localised_description = {"", {"space-spidertron.description-se"}}
end

local spider = {
  type = "spider-vehicle",
  name = "ss-space-spidertron",
  icon = "__space-spidertron__/graphics/space-spidertron/space-spidertron-icon.png",
  localised_description = localised_description,
  icon_size = 64, icon_mipmaps = 4,
  collision_box = {{-1, -1}, {1, 1}},
  sticker_box = {{-1.5, -1.5}, {1.5, 1.5}},
  selection_box = {{-1, -1}, {1, 1}},
  drawing_box = {{-3, -4}, {3, 2}},
  mined_sound = {filename = "__core__/sound/deconstruct-large.ogg",volume = 0.8},
  open_sound = { filename = "__base__/sound/spidertron/spidertron-door-open.ogg", volume= 0.35 },
  close_sound = { filename = "__base__/sound/spidertron/spidertron-door-close.ogg", volume = 0.4 },
  sound_minimum_speed = 0.1,
  sound_scaling_ratio = 0.6,
  allow_passengers = true,   -- It's a nice space vehicle
  working_sound =
  {
    sound =
    {
      filename = "__base__/sound/spidertron/spidertron-vox.ogg",
      volume = 0.35
    },
    activate_sound =
    {
      filename = "__base__/sound/spidertron/spidertron-activate.ogg",
      volume = 0.5
    },
    deactivate_sound =
    {
      filename = "__base__/sound/spidertron/spidertron-deactivate.ogg",
      volume = 0.5
    },
    match_speed_to_activity = true
  },
  weight = 1,
  braking_force = 1,
  friction_force = 1,
  torso_bob_speed = 0.1,
  flags = {"placeable-neutral", "player-creation", "placeable-off-grid"},
  collision_mask = {},
  minable = {result = "ss-space-spidertron", mining_time = 1},
  max_health = 250,
  resistances =
  {
    {
      type = "fire",
      decrease = 15,
      percent = 60
    },
    {
      type = "physical",
      decrease = 15,
      percent = 60
    },
    {
      type = "impact",
      decrease = 50,
      percent = 80
    },
    {
      type = "explosion",
      decrease = 20,
      percent = 75
    },
    {
      type = "acid",
      decrease = 0,
      percent = 70
    },
    {
      type = "laser",
      decrease = 0,
      percent = 70
    },
    {
      type = "electric",
      decrease = 0,
      percent = 70
    }
  },
  minimap_representation =
  {
    filename = "__space-spidertron__/graphics/space-spidertron/space-spidertron-map.png",
    flags = {"icon"},
    size = {128, 128},
    scale = 0.5
  },
  corpse = "medium-remnants",
  energy_per_hit_point = 1,
  guns = {},
  inventory_size = 100, -- Vanilla is 80
  equipment_grid = "spidertron-equipment-grid",
  trash_inventory_size = 20,
  height = 1.5,
  torso_rotation_speed = 0.02,
  chunk_exploration_radius = 3,
  selection_priority = 51,
  graphics_set = spidertron_torso_graphics_set(1),
  energy_source =
  {
    type = "void"
  },
  movement_energy_consumption = "250kW",
  automatic_weapon_cycling = true,
  chain_shooting_cooldown_modifier = 0.5,
  spider_engine =
  {
    legs =
    {
      { -- 1
        leg = "space-spidertron-leg",
        mount_position = {0, -1},
        ground_position = {0, -1},
        blocking_legs = {1},
        leg_hit_the_ground_trigger = nil
      }
    },
    military_target = "spidertron-military-target"
  },
}

if mods["Krastorio2"] then
  -- K2 does some custom things to all spidertrons.
  -- Redo them all here. I could simply take them from
  -- the spidertron prototype, but I don't want to rely
  -- on it existing. And I'd rather have fine control
  -- over what's happening.
  -- Note: Migrating equipment to a new grid type happens automatically.
  spider.equipment_grid = "kr-spidertron-equipment-grid"
  spider.movement_energy_consumption = "3MW"
  spider.energy_source = {
    type = "burner",
    emissions_per_minute = 0,
    effectivity = 1,
    render_no_power_icon = true,
    render_no_network_icon = false,
    fuel_inventory_size = 1,
    burnt_inventory_size = 1,
    fuel_categories = {"fusion-fuel"},
  }

  -- However, if SE is also installed then it's changed again
  if mods["space-exploration"] then
    table.insert(spider.energy_source.fuel_categories, "nuclear")
  end
end

local torso_bottom_layers = spider.graphics_set.base_animation.layers
torso_bottom_layers[1].filename = "__space-spidertron__/graphics/space-spidertron/space-spidertron-body-bottom.png"
torso_bottom_layers[1].hr_version.filename = "__space-spidertron__/graphics/space-spidertron/hr-space-spidertron-body-bottom.png"

local torso_body_layers = spider.graphics_set.animation.layers
torso_body_layers[1].filename = "__space-spidertron__/graphics/space-spidertron/spidertron-body.png"
torso_body_layers[1].hr_version.filename = "__space-spidertron__/graphics/space-spidertron/hr-space-spidertron-body.png"

-- Recolour eyes 
-- TODO Add highlight
table.insert(torso_body_layers, {
    filename = "__space-spidertron__/graphics/space-spidertron/spidertron-eyes-all-mask.png",
    width = 66,
    height = 70,
    line_length = 8,
    direction_count = 64,
    tint = util.color("0080ff"),
    shift = util.by_pixel(0, -19),
    hr_version = {
        filename = "__space-spidertron__/graphics/space-spidertron/hr-spidertron-eyes-all-mask.png",
        width = 132,
        height = 138,
        line_length = 8,
        direction_count = 64,
        tint = util.color("0080ff"),
        shift = util.by_pixel(0, -19),
        scale = 0.5,
    }
})

-- Add flame
local flame_scale = 2
for k, layer in pairs (torso_bottom_layers) do
  layer.repeat_count = 8
  layer.hr_version.repeat_count = 8
end
table.insert(torso_bottom_layers, 1, {
  filename = "__base__/graphics/entity/rocket-silo/10-jet-flame.png",
  priority = "medium",
  blend_mode = "additive",
  draw_as_glow = true,
  width = 87,
  height = 128,
  frame_count = 8,
  line_length = 8,
  animation_speed = 0.5,
  scale = flame_scale/4,
  tint = util.color("0080ff"),
  shift = util.by_pixel(-0.5, 30),
  direction_count = 1,
  hr_version = {
    filename = "__base__/graphics/entity/rocket-silo/hr-10-jet-flame.png",
    priority = "medium",
    blend_mode = "additive",
    draw_as_glow = true,
    width = 172,
    height = 256,
    frame_count = 8,
    line_length = 8,
    animation_speed = 0.5,
    scale = flame_scale/8,
    tint = util.color("0080ff"),
    shift = util.by_pixel(-1, 30),
    direction_count = 1,
  }
})

-- Add leg
for _, leg in pairs(spider.spider_engine.legs) do
   leg.ground_position = {0, 0}
   leg.leg_hit_the_ground_trigger = nil
end

local spider_leg = {
    type = "spider-leg",
    name = "space-spidertron-leg",

    localised_name = {"entity-name.spidertron-leg"},
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
    initial_movement_speed = 100,
    movement_acceleration = 100,
    max_health = 100,
    movement_based_position_selection_distance = 3,
    selectable_in_game = false,
    graphics_set = create_spidertron_leg_graphics_set(0, 1)
}

-- Add item
local spider_item =   {
    type = "item-with-entity-data",
    name = "ss-space-spidertron",
    localised_description = localised_description,
    icon = "__space-spidertron__/graphics/space-spidertron/space-spidertron-icon.png",
    icon_tintable = "__space-spidertron__/graphics/space-spidertron/space-spidertron-icon.png",
    icon_tintable_mask = "__space-spidertron__/graphics/space-spidertron/space-spidertron-icon-tintable-mask.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "transport",
    order = "b[personal-transport]-c[spidertron]-a[zspace-spider]", -- "z" to be placed after normal spider
    place_result = "ss-space-spidertron",
    stack_size = 1
}

data:extend{spider, spider_leg, spider_item}
