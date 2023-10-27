require("prototypes.space-spidertron")
require("prototypes.simulations")

if mods["aai-programmable-vehicles"] then
    -- Create a dummy recipe for the because AAI creates the AI
    -- versions already in data-updates, which is always _before_ we generate
    -- the real recipe. This then means the AI entity is generated, but has no recipe
    -- We will delete this recipe later.
    data:extend{{
        type = "recipe",
        name = "ss-space-spidertron",
        ingredients = { },
        result = "ss-space-spidertron"
    }}
end
