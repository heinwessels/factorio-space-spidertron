local util = require("__core__/lualib/util")

do return end

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

script.on_configuration_changed(function (event)
    -- Spidertron Dock was split off from Space Spidertron, so we need to move
    -- the global dock data from this mod to Spidertron Dock, which is also
    -- why this mod is dependent on that mod.
    if not next(global) then return end -- Return early if there's no data anyway
    if script.active_mods["spidertron-dock"] then 
        remote.call("spidertron-dock", "migrate_data",  global)
    else
        -- There is dock data contained in this mod, but the Spidertron Dock
        -- mod is not installed to offload the dock data. The player will lose
        -- all docks. Do I do a warning or an error?
        -- I'm going to print a big red error, just like SE does. Maybe the player
        -- just doesn't want to play with the docks.
        game.print({"space-spidertron.warning-docks-removed"})
    end
    for k, _ in pairs(global) do global[k] = nil end -- Clear global
end)