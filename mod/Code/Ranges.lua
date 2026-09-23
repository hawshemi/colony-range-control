LocalRangeExtenderActive = true

local defaults = {
    Domes = 10, Hubs = 2, Commanders = 2, Rockets = 2, Extenders = 2,
    Scrubbers = 2, Heaters = 2, Lasers = 2, Extractors = 2, Sensors = 2,
    Forestation = 2, Mohole = 2, Stirling = 2, Suns = 2, Struts = 2, SafariSights = 2, SafariRoutes = 2,
}

local function Factor(key)
    local options = CurrentModOptions or empty_table
    if options.Enabled == false then return 1 end
    local preset = ({Normal = 1, ["2x"] = 2, ["5x"] = 5})[options.Preset]
    return Clamp(preset or tonumber(options[key]) or defaults[key], 1, 10)
end

local function Scaled(obj, prop, factor, base)
    local state = obj.range_extender_factors
    if not state then
        state = {}
        obj.range_extender_factors = state
    end
    local old = state[prop] or 1
    local value = obj[base and ("base_" .. prop) or prop]
    state[prop] = factor
    return MulDivRound(value, factor, old)
end

local function ScaleProperty(obj, prop, factor)
    local base = type(obj["base_" .. prop]) == "number"
    local value = Scaled(obj, prop, factor, base)
    if base then
        obj:SetBase(prop, value)
    else
        obj[prop] = value
    end
end

local function DroneCategory(obj)
    if IsKindOf(obj, "DroneHubBase") then return "Hubs" end
    if IsKindOf(obj, "RCRover") then return "Commanders" end
    if IsKindOfClasses(obj, "RocketBase", "UniversalRocket") then return "Rockets" end
    if IsKindOf(obj, "DroneHubExtenderBase") then return "Extenders" end
end

local function MigrateDrone(obj)
    if not obj.local_drone_range_2x then return end
    obj.work_radius = MulDivRound(obj.work_radius, 1, 2)
    obj.UIWorkRadius = obj.work_radius
    if IsKindOf(obj, "DroneHubBase") then
        obj:SetModifier("service_area_max", "LocalDroneRange2x", 0, 0)
    elseif obj.service_area_max then
        obj.service_area_max = MulDivRound(obj.service_area_max, 1, 2)
    end
    obj.local_drone_range_2x = false
end

local function ApplyObject(obj)
    if not IsValid(obj) then return end
    local category = DroneCategory(obj)
    if category then
        MigrateDrone(obj)
        local factor = Factor(category)
        local radius = Scaled(obj, "work_radius", factor)
        if obj.service_area_max then ScaleProperty(obj, "service_area_max", factor) end
        if category == "Extenders" then
            obj.work_radius = radius
            obj:UpdateUplinkRequesters()
        else
            obj:SetUIWorkRadius(Min(radius, obj.service_area_max))
        end
    end

    if IsKindOfClasses(obj, "TriboelectricScrubberBase", "SubsurfaceHeaterBase") then
        local key = IsKindOf(obj, "SubsurfaceHeaterBase") and "Heaters" or "Scrubbers"
        local radius = Scaled(obj, "UIRange", Factor(key))
        if radius ~= obj.UIRange then
            obj:OnPreChangeRange(radius)
            obj.UIRange = radius
            obj:OnPostChangeRange()
        end
    end
    if IsKindOf(obj, "MDSLaserBase") then
        ScaleProperty(obj, "protect_range", Factor("Lasers"))
        ScaleProperty(obj, "shoot_range", Factor("Lasers"))
    end
    if IsKindOf(obj, "BuildingDepositExploiterComponent") then
        ScaleProperty(obj, "exploitation_radius", Factor("Extractors"))
        obj:GatherNearbyDeposits(function(deposit, exploiter) return deposit:IsExploitableBy(exploiter) end)
        obj:OnDepositsLoaded()
        obj:UpdateWorking()
    end
    if IsKindOf(obj, "ArtificialSunBase") then
        ScaleProperty(obj, "effect_range", Factor("Suns"))
        obj:LinkPanelsInRange()
        obj:ApplyHeat(obj.working)
    end
    if IsKindOf(obj, "SupportStruts") then
        ScaleProperty(obj, "work_radius", Factor("Struts"))
    end
    if IsKindOf(obj, "RCSafari") then
        ScaleProperty(obj, "sight_range", Factor("SafariSights"))
    end
    if IsKindOf(obj, "ForestationPlantBase") then
        ScaleProperty(obj, "UIRange", Factor("Forestation"))
        obj.plant_hexes = false
        obj.range_prev = obj.UIRange
    end
    if IsKindOf(obj, "MoholeMineBase") then obj:ApplyHeat(obj.working) end
    if IsKindOf(obj, "AdvancedStirlingGeneratorBase") then obj:UpdateHeat() end
    if obj == SelectedObj then ChangeHexRanges(obj) end
end

DefineClass.LocalRangeExtenderObject = {
    __parents = { "Object" },
    range_extender_factors = false,
    GameInit = function(self)
        -- Apply after the building's own initialization has set its defaults.
        DelayedCall(0, ApplyObject, self)
    end,
}

function OnMsg.ClassesGenerate(classdefs)
    for _, name in ipairs({
        "DroneNode", "RangeElConsumer", "MDSLaserBase", "BuildingDepositExploiterComponent",
        "ArtificialSunBase", "SupportStruts", "RCSafari",
        "ForestationPlantBase", "MoholeMineBase", "AdvancedStirlingGeneratorBase",
    }) do
        table.insert_unique(classdefs[name].__parents, "LocalRangeExtenderObject")
    end
    for _, entry in ipairs({
        {"DroneHubBase", "Hubs", "work_radius"}, {"RCRover", "Commanders", "work_radius"},
        {"RocketBase", "Rockets", "work_radius"}, {"UniversalRocket", "Rockets", "work_radius"},
        {"DroneHubExtenderBase", "Extenders", "work_radius"},
        {"MDSLaserBase", "Lasers", "protect_range"},
        {"BuildingDepositExploiterComponent", "Extractors", "exploitation_radius"},
        {"ArtificialSunBase", "Suns", "effect_range"}, {"SupportStruts", "Struts", "work_radius"},
    }) do
        local class = classdefs[entry[1]]
        local original = class.GetSelectionRadiusScale
        if original then
            class.GetSelectionRadiusScale = function(self, ...)
                local state = self.range_extender_factors
                return original(self, ...) * (state and state[entry[3]] and 1 or Factor(entry[2]))
            end
        end
    end
    local exploiter = classdefs.BuildingDepositExploiterComponent
    local gather = exploiter.GatherNearbyDeposits
    exploiter.GatherNearbyDeposits = function(self, ...)
        local state = self.range_extender_factors
        local radius = self.exploitation_radius
        if not (state and state.exploitation_radius) then
            self.exploitation_radius = radius * Factor("Extractors")
        end
        gather(self, ...)
        self.exploitation_radius = radius
    end
end

local slider_maxima = {}
local function UpdateSliders()
    for _, entry in ipairs({{"SubsurfaceHeaterBase", "Heaters"}, {"TriboelectricScrubberBase", "Scrubbers"}, {"ForestationPlantBase", "Forestation"}}) do
        local names = ClassDescendantsList(entry[1])
        names[#names + 1] = entry[1]
        for _, name in ipairs(names) do
            local class = g_Classes[name]
            local properties = table.copy(class.properties)
            for i, meta in ipairs(properties) do
                if meta.id == "UIRange" then
                    slider_maxima[name] = slider_maxima[name] or meta.max
                    meta = table.copy(meta)
                    meta.max = slider_maxima[name] * Factor(entry[2])
                    properties[i] = meta
                end
            end
            class.properties = properties
        end
    end
end

local function ApplyConstants()
    local drone = Max(Factor("Hubs"), Factor("Commanders"), Factor("Rockets"), Factor("Extenders"))
    const.MoholeMineHeatRadius = 8 * Factor("Mohole")
    const.AdvancedStirlingGeneratorHeatRadius = 6 * Factor("Stirling")
    const.CommandCenterMaxRadius = 50 * drone
    const.DroneRestrictRadius = 100 * const.GridSpacing * drone
    const.DroneRestrictRadiusUnderground = 150 * const.GridSpacing * drone
    const.RangeToCheckForExploitersOnDepositReveal = 10 * Factor("Extractors")
    const.SensorTowerScanBoostMinRange = 200 * guim * Factor("Sensors")
    const.SensorTowerScanBoostMaxRange = 1200 * guim * Factor("Sensors")
    const.SafariMaxRouteLength = 300 * const.GridSpacing * Factor("SafariRoutes")
    if g_Consts then
        g_Consts:SetModifier("DefaultOutsideWorkplacesRadius", "LocalDomeRange10x", 0, 0)
        g_Consts:SetModifier("DefaultOutsideWorkplacesRadius", "LocalRangeExtender", 0, (Factor("Domes") - 1) * 100)
    end
end

local function Conflicts()
    local names = {}
    for _, mod in ipairs(ModsLoaded or empty_table) do
        local title = tostring(mod.title or mod.id)
        local text = string.lower(title .. " " .. mod.id)
        if mod.id ~= CurrentModId and (text:find("range", 1, true) or text:find("radius", 1, true)) then
            names[#names + 1] = title
        end
    end
    table.sort(names)
    return #names > 0 and ("Possible range conflicts: " .. table.concat(names, ", ") ..
        ". Disable overlapping mods. Detection uses loaded mod names and IDs and cannot find every conflict.") or ""
end

local warned_conflicts = ""
local function WarnConflicts()
    local warning = Conflicts()
    if warning ~= "" and warning ~= warned_conflicts then
        CreateMessageBox(nil, Untranslated("Colony Range Control"), Untranslated(warning))
    end
    warned_conflicts = warning
end

local report_fields = {
    {"DroneHubBase", "Hubs", "work_radius", "Drone Hubs", "hexes"},
    {"RCRover", "Commanders", "work_radius", "RC Commanders", "hexes"},
    {"RocketBase", "Rockets", "work_radius", "Rockets", "hexes"},
    {"UniversalRocket", "Rockets", "work_radius", "Rockets", "hexes"},
    {"DroneHubExtenderBase", "Extenders", "work_radius", "Drone extenders", "hexes"},
    {"TriboelectricScrubberBase", "Scrubbers", "UIRange", "Scrubbers", "m", 10},
    {"SubsurfaceHeaterBase", "Heaters", "UIRange", "Heaters", "m", 10},
    {"ForestationPlantBase", "Forestation", "UIRange", "Forestation", "m", 10},
    {"MDSLaserBase", "Lasers", "protect_range", "Laser protection", "hexes"},
    {"MDSLaserBase", "Lasers", "shoot_range", "Laser interception", "hexes"},
    {"BuildingDepositExploiterComponent", "Extractors", "exploitation_radius", "Extractors", "hexes"},
    {"ArtificialSunBase", "Suns", "effect_range", "Sun illumination", "hexes"},
    {"SupportStruts", "Struts", "work_radius", "Strut work radius", "hexes"},
    {"RCSafari", "SafariSights", "sight_range", "Safari attractions", "hexes"},
}

local function ShowRangeReport()
    local lines = {"Normal-equivalent → applied range. Building entries show the ranges currently found in your colony."}
    local seen = {}
    local function add(label, base, value, unit)
        local line = string.format("%s: %g → %g %s", label, base, value, unit)
        if not seen[line] then lines[#lines + 1] = line seen[line] = true end
    end
    if g_Consts then
        add("Domes and stations", g_Consts.DefaultOutsideWorkplacesRadius / Factor("Domes"), g_Consts.DefaultOutsideWorkplacesRadius, "hexes")
    end
    for _, city in ipairs(Cities or empty_table) do
        city:MapForEach("map", "LocalRangeExtenderObject", function(obj)
            for _, entry in ipairs(report_fields) do
                if IsKindOf(obj, entry[1]) then
                    local value = obj[entry[3]] * (entry[6] or 1)
                    add(entry[4], value / Factor(entry[2]), value, entry[5])
                end
            end
        end)
    end
    add("Mohole heat", 80, const.MoholeMineHeatRadius * 10, "m")
    add("Advanced Stirling heat (open and working)", 60, const.AdvancedStirlingGeneratorHeatRadius * 10, "m")
    add("Sensor full boost distance", 200, const.SensorTowerScanBoostMinRange / guim, "m")
    add("Sensor maximum boost distance", 1200, const.SensorTowerScanBoostMaxRange / guim, "m")
    add("Safari route limit", 300, const.SafariMaxRouteLength / const.GridSpacing, "grid spacings")
    lines[#lines + 1] = "Struts retain their fixed extra protection margin. Custom multipliers are used only with the Custom preset."
    local warning = Conflicts()
    if warning ~= "" then lines[#lines + 1] = warning end
    CreateMessageBox(nil, Untranslated("Colony Range Control"), Untranslated(table.concat(lines, "\n")))
end

local function ApplyAll()
    ApplyConstants()
    UpdateSliders()
    for _, city in ipairs(Cities or empty_table) do
        city:MapForEach("map", "LocalRangeExtenderObject", ApplyObject)
        city:MapForEach("map", "DomeOutskirtBld", function(building)
            if building.dome_label and not IsObjInDome(building) then
                for _, workforce in ipairs(city.labels.Workforce or empty_table) do
                    if not workforce:IsBuildingInWorkRange(building) then
                        building:RemoveFromDomeLabels(workforce)
                    end
                end
            end
        end)
        for _, workforce in ipairs(city.labels.Workforce or empty_table) do
            workforce:AddOutskirtBuildings()
        end
        city:MapForEach("map", "Building", function(building)
            if building.connected_stations then building:LinkToStation(false, true) end
        end)
        for _, station in ipairs(city.labels.Station or empty_table) do
            station:AddNearbyBuildingsToLabels()
        end
    end
    if g_DomeVersion then g_DomeVersion = g_DomeVersion + 1 end
    if g_WorkforceVersion then g_WorkforceVersion = g_WorkforceVersion + 1 end
    if g_ClusterWorkplacesVersion then g_ClusterWorkplacesVersion = g_ClusterWorkplacesVersion + 1 end
end

OnMsg.ClassesPostprocess = UpdateSliders
OnMsg.ModsReloaded = ApplyConstants
OnMsg.NewMap = ApplyConstants
function OnMsg.PostLoadGame()
    ApplyAll()
    DelayedCall(0, WarnConflicts)
end

function OnMsg.ApplyModOptions(mod_id)
    if mod_id == CurrentModId then
        DelayedCall(0, function()
            ApplyAll()
            if #(Cities or empty_table) > 0 then ShowRangeReport() end
        end)
    end
end

function OnMsg.ModsUnloaded()
    LocalRangeExtenderActive = false
end
