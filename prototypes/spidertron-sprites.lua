--[[
    Create a Animation for every spidertron body that we will draw on
    the dock with LuaRendering during runtime. We use animations and 
    not sprites because I couldn't get the sprite to look downwards

    This sucks a little because the docked spider won't show
    when opening up the entity. I thought about adding the different
    spiders to the rotations of the dock, but I don't think it's
    possible to do rotations without having it all on a spritesheet.

    This will do for now


    We actually create three sprites:
    - shadow
    - main sprite
    - tint mask
]]

local util = require("__core__/lualib/util")

for _, spider in pairs(data.raw["spider-vehicle"]) do
    if spider.name ~= "se-burbulator" then
        local main_layers = {}
        local shadow_layers = {}
        local tint_layers = {}

        -- Get the spider graphics. We don't draw the legs
        local torso_bottom_layers = util.copy(spider.graphics_set.base_animation.layers)
        local torso_body_layers = util.copy(spider.graphics_set.animation.layers)
        -- TODO What if shadow is also layers?
        local torso_body_shadow = util.copy(spider.graphics_set.shadow_animation)

        -- Sanitize and add the bottom layers
        for index, layer in pairs(torso_bottom_layers) do
            -- Actually, we don't want to draw the bottom.
            -- The spider sits much more snugly if we don't
            -- draw the bottom. Changing this requires 
            -- changing where the sprite is drawn
            break

            -- Only use non-flame layers
            -- Only looking at the bottom because that's likely where they will exist
            if not layer.filename:find("flame") then
                if layer.apply_runtime_tint then
                    table.insert(tint_layers, layer)
                else
                    table.insert(main_layers, layer)
                end

            end
        end

        -- Sanitize the and add the body layer. 
        for index, layer in pairs(torso_body_layers) do

            -- The body layer contains animations for all rotations,
            -- So change {x,y} to a nice looking one
            -- TODO This can be smarter
            layer.x = layer.width * 4
            layer.y = layer.height * 4
            layer.hr_version.x = layer.hr_version.width * 4
            layer.hr_version.y = layer.hr_version.height * 4
            
            if layer.apply_runtime_tint then
                table.insert(tint_layers, layer)
            else
            table.insert(main_layers, layer)
            end
        end

        -- Sanitize the and add the shadow layers
        -- NB: We're not building the "bottom" shadows,
        -- because the bottom is not currently drawn
        for index, layer in pairs({torso_body_shadow}) do

            -- The body layer contains animations for all rotations,
            -- So change {x,y} to a nice looking one
            -- TODO This can be smarter
            layer.x = layer.width * 4
            layer.y = layer.height * 4
            layer.hr_version.x = layer.hr_version.width * 4
            layer.hr_version.y = layer.hr_version.height * 4
            
            table.insert(shadow_layers, layer)
        end

        -- Add the sprites
        data:extend{
            {
                type = "sprite",
                name = "docked-"..spider.name.."-shadow",
                layers = shadow_layers,
                flags = {"shadow"},
                draw_as_shadow = true,
            },
            {
                type = "sprite",
                name = "docked-"..spider.name.."-main",
                layers = main_layers,
            },
            {
                type = "sprite",
                name = "docked-"..spider.name.."-tint",
                layers = tint_layers,
            },
        }
    end
end