-- We change space-spider to be able to walk
-- in space, and disable regular spider to walk
-- in space by default

if not mods["space-exploration"] then return end

-- Let's use SE's nice tool
local collision_mask_util_extended = require("lib.collision-mask-util-extended")

local space_layer = 
        collision_mask_util_extended.get_make_named_collision_mask("space-tile")

for _, spider in pairs(data.raw["spider-vehicle"]) do
    if spider.name ~= "space-spidertron" and spider.name ~= "se-burbulator" then 
        spider.collision_mask = spider.collision_mask or {}
        collision_mask_util_extended.add_layer(spider.collision_mask, space_layer)
        
        -- Show in entity description
        spider.localised_description = spider.localised_description or {""}
        table.insert(spider.localised_description, 
            {"space-exploration.placement_restriction_line", {"space-exploration.collision_mask_space_platform"}, ""})
        table.insert(spider.localised_description, 
            {"space-exploration.placement_restriction_line", 
            {"space-exploration.collision_mask_spaceship"},
            {"space-spidertron.regular-description-se"}}) -- Hacky place to put description.

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

