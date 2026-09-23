return PlaceObj('ModDef', {
    'title', "Colony Range Control",
    'short_description', "Control 17 colony ranges from 1x to 10x, with quick presets, actual range reports, and possible range-mod conflict warnings. Includes forestation and heat ranges.",
    'description', [=[Adjust 17 colony ranges from 1x to 10x in Surviving Mars: Relaunched.

Covers domes and stations, Drone Hubs, RC Commanders, rockets, drone extenders, scrubbers, heaters, meteor lasers, extractors, sensors, Artificial Suns, support struts, safari attraction detection and route length, forestation, Mohole heat, and Advanced Stirling heat.

Choose Normal, 2x, 5x, or Custom in Mod Options. Custom preserves individual settings and defaults to 10x for domes and 2x for everything else. Apply to update existing buildings and see their current ranges.

Disable other mods that change the same ranges. Warnings identify possible conflicts by mod name and may not detect every conflict. Heaters and scrubbers retain their range-based power costs. Sensors change scanning reach, not law effects. Struts retain their fixed extra protection margin.

To install, copy this folder into your local Mods directory, enable the mod, and restart. Keep only one copy of this mod enabled.

To remove, turn off Enable range changes in a loaded colony and apply. Save, disable the mod, and restart. Existing safari routes remain unchanged.

For Surviving Mars: Relaunched 1.1.0.403908.
Author: hawshemi
License: MIT
]=],
    'image', "Mod/LocalRangeExtender/preview.png",
    'id', "LocalRangeExtender",
    'author', "hawshemi",
    'version_major', 1,
    'version_minor', 1,
    'version', 3,
    'last_changes', "Adds forestation, Mohole heat, Advanced Stirling heat, presets, actual range reports, and possible conflict warnings.",
    'lua_revision', 403908,
    'saved_with_revision', 403908,
    'restart_on_unload', true,
    'code', { "Code/Ranges.lua" },
    'has_data', true,
})
