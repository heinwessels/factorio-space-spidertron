local util = require("__core__/lualib/util")

local function on_built(event)
    -- If it's a space spidertron, set it to white as default
    local entity = event.created_entity or event.entity
    if entity and entity.valid then
        if entity.name == "ss-space-spidertron" then
            -- We only want to set it when the user has not set it
            -- before. However, there's no way we can determine it.
            -- Usually when it's placed initially the colour is that
            -- orange-ish colour, and then we turn it white. So we
            -- assume if it's the orangy-colour then the user has not
            -- set it, so we turn it to white. 
            if util.table.compare(
                entity.color,
                {r=1, g=0.5, b=0, a=0.5, }
            ) then
                entity.color = {1, 1, 1, 0.5} -- White
            end
        end
    end
end

script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)

-- TODO (HW): Verify that the player can only update to this if player was at least on v1.2.