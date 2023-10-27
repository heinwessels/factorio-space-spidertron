if mods["aai-programmable-vehicles"] then
    -- See comment about AAI in data.lua
    data.raw["recipe"]["ss-space-spidertron"] = nil
end


local spider_recipe = util.table.deepcopy(data.raw["recipe"]["spidertron"])
if not spider_recipe then error("No spider recipe found! Should I handle this? Probably.") end
spider_recipe.name = "ss-space-spidertron"

-- It's really stupid that ingredients can be in 
-- two different places. I guess they can't change
-- it now though cause it would break sooooo
-- many mods.
-- Update a year later: Don't forget, products are 
-- twice as annoying as ingredients!
local spider_ingredients = spider_recipe.ingredients or spider_recipe.normal.ingredients
if spider_recipe.results then
    spider_recipe.results = {{type = "item", name = "ss-space-spidertron", amount = 1}}
elseif spider_recipe.result then
    spider_recipe.result = "ss-space-spidertron"
elseif spider_recipe.normal.results then
    spider_recipe.normal.results = {{type = "item", name = "ss-space-spidertron", amount = 1}}
else
    spider_recipe.normal.result = "ss-space-spidertron"
end

local function remove_ingredient(ingredients, ingredient_name)
    for index, ingredient in pairs(spider_ingredients) do
        if ingredient then
            if (ingredient[1] == ingredient_name) or (ingredient.name == ingredient_name) then
                table.remove(ingredients, index)
                
                -- This loop is now broken, 
                -- and we got what we're looking for
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
    -- Move to Beryl tech. TODO Add custom tech?
    remove_ingredient(spider_ingredients, "se-heavy-girder")
    table.insert(spider_ingredients, {"se-aeroframe-pole", 16})
    
    -- The life needs to survice in space somehow
    table.insert(spider_ingredients, {"se-lifesupport-canister", 5})
else
    table.insert(spider_ingredients, {"rocket-fuel", 100})
end

data:extend{spider_recipe}