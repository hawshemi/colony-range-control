return PlaceObj('ModDef', {
    'title', "Colony Range Control",
    'short_description', "Control 17 colony ranges from 1x to 10x, with quick presets, actual range reports, and possible range-mod conflict warnings. Includes forestation and heat ranges.",
    'description', [=[<p>Adjust 17 colony ranges from 1x to 10x in Surviving Mars: Relaunched.</p>
<p><strong>Features</strong><br>2x, 5x, 10x, and Custom presets. Individual range controls, range reports, and possible conflict warnings.</p>
<p><strong>Use</strong><br>Subscribe, enable the mod, and restart. Choose a preset in Mod Options and apply. The default is 2x. Disable other mods that change the same ranges. Larger heater and scrubber ranges still use more power.</p>
<p><strong>Remove</strong><br>In a loaded colony, turn off Enable range changes and apply. Save, disable the mod, and restart. Existing safari routes remain unchanged.</p>]=],
    'external_links', { "https://github.com/hawshemi/colony-range-control" },
    'image', "Mod/LocalRangeExtender/preview.jpg",
    'screenshot1', "Mod/LocalRangeExtender/options.jpg",
    'id', "LocalRangeExtender",
    'author', "hawshemi",
    'version_major', 1,
    'version_minor', 1,
    'version', 10,
    'last_changes', "Simplifies the description, cover, and options gallery.",
    'pdx_id', 160315,
    'lua_revision', 403908,
    'saved_with_revision', 403908,
    'restart_on_unload', true,
    'code', { "Code/Ranges.lua" },
    'has_data', true,
})
