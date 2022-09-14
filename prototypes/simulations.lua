if mods["space-exploration-menu-simulations"] then
    -- Let's sneak in there

    -- Get the simulation I want to tweak
    local menu_simulations = data.raw["utility-constants"]["default"].main_menu_simulations
    local spaceship_dual_shuttles = menu_simulations.spaceship_dual_shuttles
    if not spaceship_dual_shuttles then return end

    spaceship_dual_shuttles.init = spaceship_dual_shuttles.init..[[
        local lame_spider = game.surfaces.nauvis.find_entities_filtered{name = "spidertron", limit = 1}[1]
        if lame_spider then
            local surface = lame_spider.surface            
            local position = {-21, -5}

            local dock = surface.create_entity{
                name="ss-spidertron-dock", position=position}

            local offset = {0, -0.35}    
            local render_layer = "object"
            rendering.draw_sprite{
                sprite = "ss-docked-spidertron-shadow", 
                target = dock, 
                surface = dock.surface,
                target_offset = offset,
                render_layer = render_layer,
            }
            rendering.draw_sprite{
                sprite = "ss-docked-spidertron-main", 
                target = dock, 
                surface = dock.surface,
                target_offset = offset,
                render_layer = render_layer,
            }
        
            rendering.draw_sprite{
                sprite = "ss-docked-spidertron-tint", 
                target = dock, 
                surface = dock.surface,
                tint = {a=0.5, b=0, g=1, r=0},
                target_offset = offset,
                render_layer = render_layer,
            }
            rendering.draw_animation{
                animation = "ss-docked-light", 
                target = dock, 
                surface = dock.surface,
                target_offset = offset,
                animation_offset = math.random(15),
                render_layer = render_layer,
            }
            
            lame_spider.destroy()
        end
    ]]

    -- For debugging
    -- data.raw["utility-constants"]["default"].main_menu_simulations = {spaceship_dual_shuttles}
end