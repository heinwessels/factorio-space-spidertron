-- Changed docked spiders from being sprites to 
-- actual spidertron entities. This script should
-- update all existing docked spiders

if not global.docks then return end

local spidertron_lib = require("lib.spidertron_lib")
global.docks = global.docks or {}
global.spiders = global.spiders or {}

-- There's some docks that needs to be removed from storage
-- because I made a booboo.
local mark_for_deletion = {}
local for_insertion = {}

-- I really should have put all dock functions in a seperate file
local function draw_docked_spider(dock, spider_name, color)
    local dock_data = global.docks[dock.unit_number] or for_insertion[dock.unit_number]
    dock_data.docked_sprites = dock_data.docked_sprites or {}

    -- Offset to place sprite at correct location
    -- This assumes we're not drawing the bottom
    local offset = {0, -0.35}
    local render_layer = "object"
    
    -- Draw shadows
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "ss-docked-"..spider_name.."-shadow", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
            render_layer = render_layer,
        }
    )

    -- First draw main layer
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "ss-docked-"..spider_name.."-main", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
            render_layer = render_layer,
        }
    )

    -- Then draw tinted layer
    table.insert(dock_data.docked_sprites, 
        rendering.draw_sprite{
            sprite = "ss-docked-"..spider_name.."-tint", 
            target = dock, 
            surface = dock.surface,
            tint = color,
            target_offset = offset,
            render_layer = render_layer,
        }
    )

    -- Finally draw the light animation
    table.insert(dock_data.docked_sprites, 
        rendering.draw_animation{
            animation = "ss-docked-light", 
            target = dock, 
            surface = dock.surface,
            target_offset = offset,
            render_layer = render_layer,
            animation_offset = math.random(15) -- Not sure how to start at frame 0
        }
    )
end

for unit_number, dock_data in pairs(global.docks) do
    -- All docks are active at this point
    dock_data.mode = "active"

    if dock_data.occupied then
        
        -- The dock entity reference is now invalid because
        -- for some reason I decided to change the entity name
        -- Luckily we can find it through the docked spider
        -- which will all be active entities at this point
        local spider = dock_data.docked_spider
        if spider and spider.valid then
            -- HAPPY PATH!

            -- Let's find the actual dock entity and link it
            local dock = spider.surface.find_entity("ss-spidertron-dock-active", spider.position)
            if not dock then error([[
                Could not find dock beneath spider!
                Spider: ]]..spider.name..[[
                Surface: ]]..spider.surface.name..[[
                Position: ]]..serpent.line(spider.position)..[[
            ]]) end
            dock_data.dock_entity = dock
            if dock.unit_number ~= unit_number then
                error("Unit number mismatch")
            end
            
            -- This will only occur if a game was updated now
            -- from pre-1.0. This is so their docks will be
            -- passive.
            -- This is for you Alphaprime
            if dock_data.was_passive then

                -- Transfer the dock data
                local new_dock = dock.surface.create_entity{
                    name = "ss-spidertron-dock-passive",
                    position = dock.position,
                    force = dock.force,
                    create_build_effect_smoke = false,
                    raise_built = true,
                }
                if not new_dock then
                    error([[
                        Could not create new dock version!
                        Dock typer: ss-spidertron-dock-passive
                        Surface: ]]..dock.surface.name..[[
                        Position: ]]..serpent.line(dock.position)..[[
                    ]])
                end
                new_dock.health = dock.health  
                
                -- Transfer the dock data
                local key_blacklist = {
                    ["mode"]=true,
                    ["was_passive"]=true,
                    ["dock_entity"]=true,
                    ["unit_number"]=true,
                    ["dock_unit_number"]=true}                    
                local new_dock_data = {
                    unit_number = new_dock.unit_number,
                    dock_entity = new_dock,
                    mode = "passive",
                }
                for_insertion[new_dock.unit_number] = new_dock_data
                for key, value in pairs(dock_data) do
                    if not key_blacklist[key] then
                        new_dock_data[key] = value
                    end
                end

                -- Transfer the spider from active to passive
                do
                    -- dock_from_active_to_serialised
                    local serialised_spider = spidertron_lib.serialise_spidertron(spider)
                    global.spiders[spider.unit_number] = nil -- Because no destroy event will be called
                    spider.destroy{raise_destroy=false}      -- False because it's not a real spider
                    new_dock_data.docked_spider = nil

                    -- dock_from_serialised_to_passive
                    new_dock_data.serialised_spider = serialised_spider
                    draw_docked_spider(new_dock, new_dock_data.spider_name, serialised_spider.color)
                end
                
                -- Remove the old dock
                dock.destroy{raise_destroy=true}
                table.insert(mark_for_deletion, unit_number)    
            end
        else
            -- The docked spider became invalid. It's likely not supported anymore
            -- Then just delete the dock data. This spider is lost to the player
            -- just like any modded entity
            table.insert(mark_for_deletion, unit_number)
        end
    else
        -- This dock is not occupied. Delete it I guess
        table.insert(mark_for_deletion, unit_number)
    end
end

-- Clean up docks I marked for deletion
for _, unit_number in pairs(mark_for_deletion) do
    global.docks[unit_number] = nil
end

for unit_number, data in pairs(for_insertion) do
    global.docks[unit_number] = data
end