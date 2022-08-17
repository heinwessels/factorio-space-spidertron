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


-- Hardcoded blacklist. Can possibly make this more dynamic in the future
local SPIDER_BLACK_LIST = {
    -- Space Exploration
    ["se-burbulator"] = true,

    -- Companions
    ["companion"] = true,

    -- Combat Mechanics Overhaul
    ["defender-unit"] = true,
    ["destroyer-unit"] = true,
}

-- This function will dictate if a spider is
-- dockable or not. If we can build a sprite
-- for it to show during docking, then it's
-- dockable. If we find anything that we don't
-- expect, then we abort the spider, and it won't
-- be dockable. This will be checked during runtime
-- by checking if a sprite exists for the spider
-- attempting to dock
function attempt_build_sprite(spider)
    local main_layers = {}
    local shadow_layers = {}
    local tint_layers = {}

    -- Try to build the sprite. We will only care about
    --  Base: The stationary frame at the bottom
    --      Here will will remove any potential layers with the
    --      word "flame" in the file name. Flames will burn the dock
    --  Animation: The part that turns
    --  Shadow: It's shadow
    --      Only here will we not expect layers
    --      What if it is though? FAIL!

    -- Using these sprites we will build our own three sprites
    -- that we layer during runtime. This will be:
    --      Main: The body, essentially a single rotation of the animation
    --      Tint: Only the tinted layers to give the docked spider the correct colours
    --      Shadow: Yup...

    if not spider.minable then return end -- Might help out filter composite spider things
    
    if not spider.graphics_set then return end
    if not spider.graphics_set.base_animation then return end
    if not spider.graphics_set.animation then return end
    if not spider.graphics_set.shadow_animation then return end

    local torso_bottom_layers = util.copy(spider.graphics_set.base_animation.layers)
    local torso_body_layers = util.copy(spider.graphics_set.animation.layers)
    local torso_body_shadow = util.copy(spider.graphics_set.shadow_animation)

    if not torso_bottom_layers or not torso_body_layers or not torso_body_shadow then return end

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

        -- Rudemental sanity check to see if this is a
        -- normal-ish spidertron
        if layer.direction_count ~= 64 then return end

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

        -- Rudemental sanity check to see if this is a
        -- normal-ish spidertron
        if layer.direction_count ~= 64 then return end

        -- The body layer contains animations for all rotations,
        -- So change {x,y} to a nice looking one
        -- TODO This can be smarter
        layer.x = layer.width * 4
        layer.y = layer.height * 4
        layer.hr_version.x = layer.hr_version.width * 4
        layer.hr_version.y = layer.hr_version.height * 4
        
        table.insert(shadow_layers, layer)
    end

    if not next(shadow_layers) or not next(main_layers) or not next(tint_layers) then return end

    -- Add the sprites
    data:extend{
        {
            type = "sprite",
            name = "ss-docked-"..spider.name.."-shadow",
            layers = shadow_layers,
            flags = {"shadow"},
            draw_as_shadow = true,
        },
        {
            type = "sprite",
            name = "ss-docked-"..spider.name.."-main",
            layers = main_layers,
        },
        {
            type = "sprite",
            name = "ss-docked-"..spider.name.."-tint",
            layers = tint_layers,
        },
    }

    return true
end

-- Loop through all spider vehicles
local found_at_least_one = false
local dock_description = data.raw.accumulator["ss-spidertron-dock"].localised_description
for _, spider in pairs(data.raw["spider-vehicle"]) do
    if not SPIDER_BLACK_LIST[spider.name] then
        if attempt_build_sprite(spider) then
            found_at_least_one = true

            -- Update dock description to show supported 
            -- This will update both the entity and the item
            -- because they use the same table
            table.insert(dock_description, 
                {"", {"space-spidertron-dock.supported-spider", spider.name}})
        end
    end
end

if not found_at_least_one then
    error("Could not find any spiders that can dock")
end

-- Create the docking light. Not strictly a _spidertron_
-- sprite, but it's declared here anyway
data:extend{
    {
        -- We declare it as an animation because that can
        -- animate and have act as a light as well
        type = "animation",
        name = "ss-docked-light",
        layers = {
            {
                filename = "__space-spidertron__/graphics/spidertron-dock/dock-light.png",
                blend_mode = "additive",
                draw_as_glow = true,    -- Draws a sprite and a light
                width = 19,
                height = 19,
                shift = { -0.42, 0.5 },
                scale = 0.4,
                run_mode = "forward-then-backward",
                frame_count = 16,
                line_length = 8,
                -- 3 second loop, meaning 16 frames per 180 ticks
                animation_speed = 0.088, -- frames per tick

                hr_version =
                {
                    filename = "__space-spidertron__/graphics/spidertron-dock/dock-light.png",
                    blend_mode = "additive",
                    draw_as_glow = true,    -- Draws a sprite and a light
                    width = 19,
                    height = 19,
                    shift = { -0.42, 0.5 },
                    scale = 0.4,
                    run_mode = "forward-then-backward",
                    frame_count = 16,
                    line_length = 8,

                    -- 3 second loop, meaning 16 frames per 180 ticks
                    animation_speed = 0.088, -- frames per tick
                }
            }
        }
    }
}