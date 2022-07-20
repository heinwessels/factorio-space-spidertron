
-- Here we create the recipe for the space spider.
-- We do it in updates because we base in on what the 
-- normal spider costs, and that needs to finish it's
-- creation phase.

----==== Recipes ====--
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
local ingredients = spider_recipe.ingredients 
        or spider_recipe.normal.ingredients
if spider_recipe.result then
    spider_recipe.result = "ss-space-spidertron"
else
    spider_recipe.normal.result = "ss-space-spidertron"
end

-- Remove the gun
for index, ingredient in pairs(ingredients) do
    if ingredient then
        if ingredient[1] == "rocket-launcher" then
            table.remove(ingredients, index)
            
            -- This loop is now broken, 
            --and we got what we're looking for
            break 
        end
    end
end

if mods["space-exploration"] then
    -- The life needs to survice in space somehow
    table.insert(ingredients, {"se-lifesupport-canister", 5})
else
    table.insert(ingredients, {"rocket-fuel", 100})
end

data:extend{spider_recipe}


----==== Technology ====--
-- We will attempt to put the space spidertron
-- at the same technology as the regular spidertron
-- to keep things simple. First we will look
-- for the "spidertron" technology, It might be possible
-- that this tech is a dud, but whatever. If that
-- doesn't exist then we will look for the tech
-- that unlocks the regular "spidertron". And if 
-- we don't find that then it will throw. 


local spider_tech = data.raw.technology.spidertron

for _, technology in pairs(data.raw.technology) do		
    if technology.effects then			
        for _, effect in pairs(technology.effects) do
            if effect.type == "unlock-recipe" then					
                if effect.recipe == "spidertron" then
                    spider_tech = technology
                end
            end
        end
        if spider_tech then break end
    end
end

if not spider_tech then
    error("Could not find technology unlocking spidertron")
end

table.insert(spider_tech.effects, {
    type = "unlock-recipe",
    recipe = "ss-space-spidertron"
})
table.insert(spider_tech.effects, {
    type = "unlock-recipe",
    recipe = "ss-spidertron-dock"
})