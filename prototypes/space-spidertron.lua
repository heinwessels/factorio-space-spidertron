local util = require("__core__/lualib/util")

local spider = util.copy(data.raw["spider-vehicle"]["spidertron"])
spider.name = "space-spidertron"
spider.guns = nil
spider.minable.result = "space-spidertron"
spider.torso_rotation_speed = 0.02
spider.corpse = "medium-remnants"

local torso_bottom_layers = spider.graphics_set.base_animation.layers
torso_bottom_layers[1].filename = "__SpaceSpidertron__/graphics/space-spidertron/space-spidertron-body-bottom.png"
torso_bottom_layers[1].hr_version.filename = "__SpaceSpidertron__/graphics/space-spidertron/hr-space-spidertron-body-bottom.png"

local torso_body_layers = spider.graphics_set.animation.layers
torso_body_layers[1].filename = "__SpaceSpidertron__/graphics/space-spidertron/spidertron-body.png"
torso_body_layers[1].hr_version.filename = "__SpaceSpidertron__/graphics/space-spidertron/hr-space-spidertron-body.png"

-- Recolour eyes 
-- TODO Add highlight
table.insert(torso_body_layers, {
    filename = "__SpaceSpidertron__/graphics/space-spidertron/spidertron-eyes-all-mask.png",
    width = 66,
    height = 70,
    line_length = 8,
    direction_count = 64,
    tint = util.color("0080ff"),
    shift = util.by_pixel(0, -19),
    hr_version = {
        filename = "__SpaceSpidertron__/graphics/space-spidertron/hr-spidertron-eyes-all-mask.png",
        width = 132,
        height = 138,
        line_length = 8,
        direction_count = 64,
        tint = util.color("0080ff"),
        shift = util.by_pixel(0, -19),
        scale = 0.5,
    }
})

-- Change runtime tint to white
-- TODO Doesn't work yet
for _, layer in pairs(torso_body_layers) do
  if layer.apply_runtime_tint then
    layer.tint = {r=1, g=1, b=1, a=1}
  end
end

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

for _, leg in pairs(spider.spider_engine.legs) do
   leg.ground_position = {0, 0}
   leg.leg_hit_the_ground_trigger = nil
--    leg.blocking_legs = {}
end

for _, leg in pairs(data.raw["spider-leg"]) do
    leg.part_length = 0.2
    leg.minimal_step_size = 0.1
    leg.movement_based_position_selection_distance = 0.5
    leg.collision_box = nil
    leg.collision_mask = nil
    leg.initial_movement_speed = 100
    leg.movement_acceleration = 100
    leg.selection_box = {{-0, -0}, {0, 0}}

    leg.graphics_set = {}
    -- leg.graphics_set.joint = nil
    -- leg.graphics_set.joint_shadow = nil
    -- leg.graphics_set.upper_part = nil
    -- leg.graphics_set.upper_part_shadow = nil
    -- leg.graphics_set.lower_part.top_end = nil
    -- leg.graphics_set.lower_part.middle = nil
end


-- Add item
local spider_item = util.copy(data.raw["item-with-entity-data"]["spidertron"])
spider_item.name = "space-spidertron"
spider_item.place_result = "space-spidertron"

data:extend{spider, spider_item}
