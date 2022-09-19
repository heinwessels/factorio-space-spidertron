local registry = { }

-- This mod will not touch these spider-prototypes
-- and not attempt to make them dockable.
registry.black_list = {
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
    
-- Will not touch these entities collision boxes
registry.collision_black_list = {
    
    -- Constructron-Continued
    -- This mod handles it's own collision masks for space.
    ["constructron"] = true,
    ["constructron-rocket-powered"] = true,
}

function registry.blacklisted_for_collision(spider_name)
    return registry.black_list[spider_name] or registry.collision_black_list[spider_name]
end

return registry