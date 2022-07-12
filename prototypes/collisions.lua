-- We change space-spider to be able to walk
-- in space, and disable regular spider to walk
-- in space by default

if not mods["space-exploration"] then return end
if settings.startup["space-spidertron-allow-other-spiders-in-space"].value then return end

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
            {"space-exploration.placement_restriction_line", {"space-exploration.collision_mask_spaceship"}, ""})

        -- Assume all spider legs are the same type. Can it even be different?
        local leg = data.raw["spider-leg"][spider.spider_engine.legs[1].leg]
        leg.collision_mask = leg.collision_mask or {}
        collision_mask_util_extended.add_layer(leg.collision_mask, space_layer)
    end
end

