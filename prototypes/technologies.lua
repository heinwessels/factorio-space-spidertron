-- We will attempt to put the space spidertron
-- at the same technology as the regular spidertron
-- to keep things simple. First we will look
-- for the "spidertron" technology, It might be possible
-- that this tech is a dud, but whatever. If that
-- doesn't exist then we will look for the tech
-- that unlocks the regular "spidertron". And if 
-- we don't find that then it will throw. 

-- The first try
local spider_tech = data.raw.technology.spidertron

-- The second try
if not spider_tech then
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
end

if not spider_tech then
    error("Could not find technology unlocking spidertron")
end

table.insert(spider_tech.effects, {
    type = "unlock-recipe",
    recipe = "ss-space-spidertron"
})
