require("prototypes.spidertron-sprites")

----==== Recipes ====--
local spider_recipe = util.merge{
    data.raw["recipe"]["spidertron"],
    {
        name = "space-spidertron",
        result = "space-spidertron",
    }
}

local dock_recipe = util.merge{
    data.raw["recipe"]["spidertron"],
    {
        name = "spidertron-dock",
        result = "spidertron-dock",
    }
}

if mods["space-exploration"] then
    table.insert(
        spider_recipe.ingredients,
        -- The fish needs to survice in space somehow
        {"se-lifesupport-canister", 5}
    )
end

data:extend{spider_recipe, dock_recipe}


----==== Technology ====--
local technology_unlocks_spidertron = false
for _, technology in pairs(data.raw.technology) do		
    if not technology.enabled and technology.effects then			
        for _, effect in pairs(technology.effects) do
            if effect.type == "unlock-recipe" then					
                if effect.recipe == "spidertron" then
                    technology_unlocks_spidertron = true
                end
            end
        end
        if technology_unlocks_spidertron then
            table.insert(technology.effects, {
                type = "unlock-recipe",
                recipe = "space-spidertron"
            })
            table.insert(technology.effects, {
                type = "unlock-recipe",
                recipe = "spidertron-dock"
            })
            break
        end
    end
end
if not technology_unlocks_spidertron then
    error("Could not find technology unlocking spidertron")
end