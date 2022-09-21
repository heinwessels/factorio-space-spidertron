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

    -- AAI Programmable Vehicles compatability:
    -- We don't display the AI version of the spider. Such spiders usually
    -- end with "-rocket-1" or something. This is a silly check, but should
    -- be good enough for now.
    "-[0-9]+$",
}
    
-- Will not touch these entities collision boxes
local collision_black_list = {
    
    -- Constructron-Continued
    -- This mod handles it's own collision masks for space.
    ["constructron"] = true,
    ["constructron-rocket-powered"] = true,
}

function registry.is_blacklisted(spider_name)
    for _, r in pairs(black_list_regex) do
        if string.match(spider_name, r) then return true end
    end
    return black_list[spider_name]
end

function registry.blacklisted_for_collision(spider_name)
    return registry.is_blacklisted(spider_name) or collision_black_list[spider_name]
end

return registry