require("prototypes.space-spidertron")
require("prototypes.simulations")

if mods["aai-programmable-vehicles"] then
    -- Create a dummy recipe for the because AAI creates the AI
    -- versions already in data-updates, which is always _before_ we generate
    -- the real recipe. This then means the AI entity is generated, but has no recipe
    -- We will delete this recipe later.
    local spider_recipe = util.merge{
        data.raw["recipe"]["spidertron"],
        {
            name = "ss-space-spidertron"
        }
    }

    -- I hate the recipe API
    if spider_recipe.result then
        spider_recipe.result = "ss-space-spidertron"
    else
        spider_recipe.normal.result = "ss-space-spidertron"
    end

    data:extend{spider_recipe}
end