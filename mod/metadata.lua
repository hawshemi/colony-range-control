return PlaceObj('ModDef', {
    'title', "Colony Range Control",
    'short_description', "Control 17 colony ranges from 1x to 10x, with quick presets, actual range reports, and possible range-mod conflict warnings. Includes forestation and heat ranges.",
    'description', [=[Give your colony more room to work.

Colony Range Control adds 17 independent range settings to Surviving Mars: Relaunched. Choose a multiplier from 1x to 10x for each setting. Use 1x for normal range or turn off the master switch to restore the normal ranges while the mod is loaded.

Range settings
- Domes and train stations
- Drone Hubs
- RC Commanders and their drone-controlling variants
- Rocket drone service areas
- Drone Hub Extenders
- Triboelectric Scrubbers
- Subsurface Heaters
- MDS Laser protection and shooting distances
- Extractor reach to compatible underground deposits
- Sensor Tower scanning-boost distance
- Artificial Sun illumination and associated heat
- Underground Support Strut work radius
- RC Safari attraction detection
- RC Safari maximum route length
- Forestation Plant planting radius
- Mohole heat radius
- Advanced Stirling Generator heat radius

Defaults
The default preset is Custom, preserving existing individual settings. Normal, 2x and 5x override all 17 multipliers without erasing custom values. Switch back to Custom to restore them. Domes use 10x. All other settings use 2x. Open this mod's options to choose your own values. Apply the options in a loaded colony to update existing buildings and vehicles. New units receive the configured ranges after initialization. The mod tracks applied multipliers so repeated loads do not multiply them again.

Range report
Applying Mod Options opens a report with actual ranges found in the colony, such as 35 → 70 hexes for a default Drone Hub at 2x. Normal-equivalent values account for the applied multiplier and current building slider. Distances use hexes or meters according to the game calculation. Buildings absent from the colony are omitted. Heat, sensor and route constants are always listed.

Balance and limits
Heaters and scrubbers retain the game's range-based power costs. Doubling their selected radius normally quadruples that component of power consumption. Drone batteries, drone counts, production rates, laser fire rates, and disaster warning time are unchanged. Longer travel distances can still slow drone deliveries.

The dome setting uses the game's shared outside-workplace radius. It also affects station connections, colonist reach checks, and some nearby-site effects. Sensor settings change scanning-boost distance, not sensor law effects. Support struts retain the game's fixed extra protection margin, so their total protected radius is not an exact multiple. Existing safari routes are not shortened automatically when the limit is reduced.

Compatibility
Prepared against Surviving Mars: Relaunched 1.1.0.403908. No other mod is required. This release candidate has passed source-based automated tests. A complete in-game test across every supported building has not yet been confirmed.

A warning on colony load and in the range report lists loaded mods whose titles or IDs contain range or radius. These are possible conflicts, not proven ones. Detection cannot find every overlapping mod.

Disable other mods that change these same ranges. This includes Dome working range 10x local, Drone control range 2x local, and other dome or drone range extenders. Compatible modded buildings that inherit the supported game classes may also receive the changes, but arbitrary third-party mods are not verified.

Installation
Enable Colony Range Control, restart the game, and load your colony. Adjust its values through Mod Options.

Removing the mod
With your colony loaded, turn off Enable range changes and apply the options. Save the colony, then disable the mod and restart the game. Your existing safari routes remain as drawn.

Version: 1.1, revision 3, release candidate 1
Author: hawshemi
]=],
    'image', "Mod/LocalRangeExtender/preview.png",
    'id', "LocalRangeExtender",
    'author', "hawshemi",
    'version_major', 1,
    'version_minor', 1,
    'version', 3,
    'last_changes', "Adds forestation, Mohole heat, Advanced Stirling heat, presets, actual range reports, and possible conflict warnings. Full in-game validation remains pending.",
    'lua_revision', 403908,
    'saved_with_revision', 403908,
    'restart_on_unload', true,
    'code', { "Code/Ranges.lua" },
    'has_data', true,
})
