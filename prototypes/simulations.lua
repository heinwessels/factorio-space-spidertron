if mods["space-exploration-menu-simulations"] then
    -- Let's sneak in there

    -- Get the simulation I want to tweak
    local menu_simulations = data.raw["utility-constants"]["default"].main_menu_simulations
    local spaceship_dual_shuttles = menu_simulations.spaceship_dual_shuttles
    
    if spaceship_dual_shuttles then
        spaceship_dual_shuttles.init = spaceship_dual_shuttles.init..[[
            local lame_spider = game.surfaces.nauvis.find_entities_filtered{name = "spidertron", limit = 1}[1]
            if lame_spider then
                local surface = lame_spider.surface            
                local position = {-21, -5}
                lame_spider.destroy()

                local dock = surface.create_entity{
                    name="ss-spidertron-dock-active", position=position}

                local spider = game.surfaces.nauvis.create_entity{
                    name="ss-docked-ss-space-spidertron",
                    position = {
                        dock.position.x,
                        dock.position.y + 0.01
                    },
                }
                spider.torso_orientation = 0.58
                spider.color = {1, 1, 1, 0.5}
                
            end
        ]]
        
        -- For debugging
        -- data.raw["utility-constants"]["default"].main_menu_simulations = {spaceship_dual_shuttles}
    end

    
    local space_mat_impact_data_scrap = menu_simulations.space_mat_impact_data_scrap
    if space_mat_impact_data_scrap then
        space_mat_impact_data_scrap.init = space_mat_impact_data_scrap.init..[[
            local space_spidy = game.surfaces.nauvis.create_entity{
                name="ss-space-spidertron",
                position={-21, 4}
            }
            space_spidy.color = {1, 1, 1, 0.5}
        ]]
        -- For debugging
        -- data.raw["utility-constants"]["default"].main_menu_simulations = {space_mat_impact_data_scrap}
    end
end