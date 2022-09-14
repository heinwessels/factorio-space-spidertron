-----------------------------------------------------------------
-- Add a collision between Space Spidertron and `out-of-map` tiles
-- Note:
-- 'out-of-map' also works for original Factorissimo2, because the
-- `out-of-factory` tiles factory-edge is only a few tiles wide, then
-- it turns into `out-of-map`. So all good.
-----------------------------------------------------------------
local collision_mask_util = require("__core__.lualib.collision-mask-util")
local out_of_map_layer = collision_mask_util.get_first_unused_layer()
if out_of_map_layer then
    local space_spidertron_leg = data.raw["spider-leg"]["ss-space-spidertron-leg"]
    space_spidertron_leg.collision_mask = {out_of_map_layer}
    space_spidertron_leg.collision_box = {{-0.1, -0.1}, {0.1, 0.1}} -- Can't be zero

    local out_of_map_tile = data.raw["tile"]["out-of-map"]
    local out_of_map_tile_mask = collision_mask_util.get_mask(out_of_map_tile)
    table.insert(out_of_map_tile_mask, out_of_map_layer)
    out_of_map_tile.collision_mask = out_of_map_tile_mask 
end

-----------------------------------------------------------------
--  Disable other spiders from walking on spaceships and in space
-----------------------------------------------------------------
if not mods["space-exploration"] then return end
if settings.startup["space-spidertron-allow-other-spiders-in-space"].value then return end

local registry = require("registry")

-- Let's use SE's nice tools
local collision_mask_util_extended 
        = require("__space-exploration__/collision-mask-util-extended/data/collision-mask-util-extended")
local data_util = require("__space-exploration__/data_util")

local space_layer = 
        collision_mask_util_extended.get_make_named_collision_mask("space-tile")

for _, spider in pairs(data.raw["spider-vehicle"]) do
    if spider.name ~= "ss-space-spidertron" 
            and not registry.blacklisted_for_collision(spider.name)
            and not spider.se_allow_in_space then 
        spider.collision_mask = spider.collision_mask or {}
        collision_mask_util_extended.add_layer(spider.collision_mask, space_layer)
        
        -- Show in entity description
        data_util.collision_description(spider)

        -- Do the same with the spider leg
        for _, spider_leg in pairs(spider.spider_engine.legs) do            
            local leg_proto = data.raw["spider-leg"][spider_leg.leg]
            leg_proto.collision_mask = leg_proto.collision_mask or {
                -- Default layers added by vanilla at some point
                -- It's not added it seems if we add space_layer here,
                -- so just making sure it's there
                "object-layer", 
                "rail-layer",
                "player-layer"
            }
            collision_mask_util_extended.add_layer(leg_proto.collision_mask, space_layer)
        end
    end
end

