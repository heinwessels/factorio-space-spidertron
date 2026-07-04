script.on_configuration_changed(function (event)
    -- Spidertron Dock was split off from Space Spidertron, so we need to move
    -- the global dock data from this mod to Spidertron Dock, which is also
    -- why this mod is dependent on that mod.
    if not next(storage) then return end -- Return early if there's no data anyway
    if script.active_mods["spidertron-dock"] then
        remote.call("spidertron-dock", "migrate_data",  storage)
    else
        -- There is dock data contained in this mod, but the Spidertron Dock
        -- mod is not installed to offload the dock data. The player will lose
        -- all docks. Do I do a warning or an error?
        -- I'm going to print a big red error, just like SE does. Maybe the player
        -- just doesn't want to play with the docks.
        game.print({"space-spidertron.warning-docks-removed"})
    end
    for k, _ in pairs(storage) do storage[k] = nil end -- Clear global
end)