-- We change space-spider to be able to walk
-- in space, and disable regular spider to walk
-- in space by default

if not mods["space-exploration"] then return end
if settings.startup["space-spidertron-allow-other-spiders-in-space"].value then return end

local SPIDER_BLACK_LIST = require("registry").spider_black_list

-- Let's use SE's nice tools
local collision_mask_util_extended 
        = require("__space-exploration__/collision-mask-util-extended/data/collision-mask-util-extended")
local data_util = require("__space-exploration__/data_util")

local space_layer = 
        collision_mask_util_extended.get_make_named_collision_mask("space-tile")

for _, spider in pairs(data.raw["spider-vehicle"]) do
    if spider.name ~= "ss-space-spidertron" and not SPIDER_BLACK_LIST[spider.name] then 
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

