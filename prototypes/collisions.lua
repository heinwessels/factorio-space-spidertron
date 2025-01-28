-----------------------------------------------------------------
-- Add a collision between Space Spidertron and `out-of-map` tiles
-- Note:
-- 'out-of-map' also works for original Factorissimo2, because the
-- `out-of-factory` tiles factory-edge is only a few tiles wide, then
-- it turns into `out-of-map`. So all good.
-----------------------------------------------------------------
local out_of_map_layer_name
for _, try_mask_name in pairs({"out-of-map", "out_of_map"}) do
    if data.raw["collision-layer"][try_mask_name] then
        out_of_map_layer_name = try_mask_name
        break
    end
end
if not out_of_map_layer_name then
    data:extend({{
            type = "collision-layer",
            name = "out-of-map",
    }})
    out_of_map_layer_name = "out-of-map"
end

local space_spidertron_leg = data.raw["spider-leg"]["ss-space-spidertron-leg"]
space_spidertron_leg.collision_mask.layers[out_of_map_layer_name] = true

local out_of_map_tile = data.raw["tile"]["out-of-map"]
out_of_map_tile.collision_mask.layers[out_of_map_layer_name] = true

-----------------------------------------------------------------
--  Disable other spiders from walking on spaceships and in space
-----------------------------------------------------------------
if not mods["space-exploration"] then return end

local registry = require("registry")
local collision_mask_util = require("collision-mask-util")

-- Let's use SE's nice tools
local data_util = require("__space-exploration__/data_util")

-- Make sure we care about collision masks
if settings.startup["space-spidertron-allow-other-spiders-in-space"].value then return end

for _, spider in pairs(data.raw["spider-vehicle"]) do
    if spider.name ~= "ss-space-spidertron"
            and not registry.blacklisted_for_collision(spider)
            and not spider.se_allow_in_space then

        -- Add space layer to collision mask
        spider.collision_mask = spider.collision_mask or collision_mask_util.get_default_mask("spider-vehicle")
        spider.collision_mask.layers["space_tile"] = true

        -- Show in entity description
        data_util.collision_description(spider)

        -- Do the same with the spider leg
        for _, spider_leg in pairs(spider.spider_engine.legs) do            
            local leg_proto = data.raw["spider-leg"][spider_leg.leg]
            leg_proto.collision_mask = leg_proto.collision_mask or collision_mask_util.get_default_mask("spider-leg")
            spider.collision_mask.layers["space_tile"] = true
        end
    end
end

