------------------------
-- Compatibility
------------------------

if mods["Constructron-Continued"] then
    -- Constructron Continued
    -- This has a space version of the constructron which is disabled by default
    -- We like space versions of spiders, so we will change the default to true
    local setting = data.raw["bool-setting"]["enable_rocket_powered_constructron"]
    if setting then
        setting.forced_value = true
        setting.hidden = true
    end
end
