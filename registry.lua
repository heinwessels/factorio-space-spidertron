local registry = { }

-- This mod will not touch these spider-prototypes
-- and not attempt to make them dockable.
local black_list = {
    -- Space Exploration
    ["se-burbulator"] = true,

    -- Companions
    ["companion"] = true,

    -- Combat Robots Overhaul
    ["defender-unit"] = true,
    ["destroyer-unit"] = true,

    -- Lex's Aircraft
    ["lex-flying-cargo"] = true,
    ["lex-flying-gunship"] = true,
    ["lex-flying-heavyship"] = true,
}

local black_list_regex = {
    -- Spidertron Enhancements also has dummy spiders
    "spidertron[-]enhancements[-]dummy[-]",
}
    
-- Will not touch these entities collision boxes
local collision_black_list = {
    
    -- Constructron-Continued
    -- This mod handles it's own collision masks for space.
    ["constructron"] = true,
    ["constructron-rocket-powered"] = true,
}

function registry.is_blacklisted(spider)
    for _, r in pairs(black_list_regex) do
        if string.match(spider.name, r) then return true end
    end

    -- Special check for AAI Programmable vehicles because the naming
    -- is hard to decern whether it's AI or not.
    if spider.localised_name then
        for _, key in pairs(spider.localised_name) do
            if key == "split-vehicle" or key == "split-vehicle-with" then
                return true
            end
        end
    end

    return black_list[spider.name]
end

function registry.blacklisted_for_collision(spider)
    return registry.is_blacklisted(spider) or collision_black_list[spider.name]
end

return registry