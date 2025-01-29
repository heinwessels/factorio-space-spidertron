local recycling = mods["quality"] and require("__quality__.prototypes.recycling")

if mods["aai-programmable-vehicles"] then
    -- See comment about AAI in data.lua
    data.raw["recipe"]["ss-space-spidertron"] = nil
end


local recipe = util.table.deepcopy(data.raw["recipe"]["spidertron"])
if not recipe then error("No spider recipe found! Should I handle this? Probably.") end
recipe.name = "ss-space-spidertron"
recipe.results = {{type = "item", name = "ss-space-spidertron", amount = 1}}

local function remove_ingredient(ingredients, ingredient_name)
    for index, ingredient in pairs(recipe.ingredients) do
        if ingredient.name == ingredient_name then
            table.remove(ingredients, index)

            -- This loop is now broken, 
            -- and we got what we're looking for
            return true
        end
    end
    return false
end

remove_ingredient(recipe.ingredients, "rocket-launcher")
remove_ingredient(recipe.ingredients, "exoskeleton-equipment")

if mods["jetpack"] then
    table.insert(recipe.ingredients, {type = "item", name = "jetpack-1", amount = 4})
else
    table.insert(recipe.ingredients, {type = "item", name = "belt-immunity-equipment", amount = 4})
end

if mods["space-exploration"] then
    -- Move to Beryl tech. TODO Add custom tech?
    remove_ingredient(recipe.ingredients, "se-heavy-girder")
    table.insert(recipe.ingredients, {type = "item", name = "se-aeroframe-pole", amount = 16})

    -- The life needs to survice in space somehow
    table.insert(recipe.ingredients, {type = "item", name = "se-lifesupport-canister", amount = 5})
else
    table.insert(recipe.ingredients, {type = "item", name = "rocket-fuel", amount = 100})
end

data:extend{recipe}

-- Running into this issue: https://forums.factorio.com/124656
if recycling then
    recycling.generate_recycling_recipe(recipe)
end