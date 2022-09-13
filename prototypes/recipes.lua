local spider_recipe = util.merge{
    data.raw["recipe"]["spidertron"],
    {
        name = "ss-space-spidertron"
    }
}

-- It's really stupid that ingredients can be in 
-- two different places. I guess they can't change
-- it now though cause it would break sooooo
-- many mods.
local spider_ingredients = spider_recipe.ingredients 
        or spider_recipe.normal.ingredients
if spider_recipe.result then
    spider_recipe.result = "ss-space-spidertron"
else
    spider_recipe.normal.result = "ss-space-spidertron"
end

local function remove_ingredient(ingredients, ingredient_name)
    for index, ingredient in pairs(spider_ingredients) do
        if ingredient then
            if (ingredient[1] == ingredient_name) or (ingredient.name == ingredient_name) then
                table.remove(ingredients, index)
                
                -- This loop is now broken, 
                --and we got what we're looking for
                return true
            end
        end
    end
    return false
end

remove_ingredient(spider_ingredients, "rocket-launcher")
remove_ingredient(spider_ingredients, "exoskeleton-equipment")

if mods["jetpack"] then
    table.insert(spider_ingredients, {"jetpack-1", 4})
else
    table.insert(spider_ingredients, {"belt-immunity-equipment", 4})
end

if mods["space-exploration"] then
    -- Move to Beryl tech. TODO Use 'Aeroframe Pole' maybe, but then we need an extra tech
    remove_ingredient(spider_ingredients, "se-heavy-girder")
    table.insert(spider_ingredients, {"se-beryllium-plate", 50})
    
    -- The life needs to survice in space somehow
    table.insert(spider_ingredients, {"se-lifesupport-canister", 5})
else
    table.insert(spider_ingredients, {"rocket-fuel", 100})
end

data:extend{spider_recipe}