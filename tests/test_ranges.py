from pathlib import Path
import re
import sys
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('mod', type=Path)
parser.add_argument('--game-source', type=Path, required=True)
args = parser.parse_args()
from lupa import LuaRuntime

root = args.mod
game = args.game_source/'Lua'
l = LuaRuntime()
for path in root.rglob('*.lua'):
    l.execute('assert(load(...))', path.read_text(encoding='utf-8'))
l.execute('''
function Untranslated(s) return s end
messages={}
function CreateMessageBox(host,title,text) messages[#messages+1]=text end
OnMsg={} DefineClass={} Modifiable={} DroneControl={} RCRover={} empty_table={}
CurrentModId="LocalRangeExtender" CurrentModOptions={} const={GridSpacing=1000} guim=1000
g_HexRanges={} pending={} min_int64=-1e18 max_int64=1e18
function Min(a,b) return math.min(a,b) end
function Max(...) return math.max(...) end
function Clamp(n,a,b) return math.max(a,math.min(n,b)) end
function MulDivRound(a,b,c) return math.floor(a*b/c+0.5) end
function table.copy(t) local n={} for k,v in pairs(t) do n[k]=v end return n end
function table.find_value(t,key,value) for _,v in ipairs(t or {}) do if v[key]==value then return v end end end
function table.remove_entry(t,v) for i,x in ipairs(t) do if x==v then table.remove(t,i) return end end end
function table.insert_unique(t,v) for _,x in ipairs(t) do if x==v then return end end t[#t+1]=v end
function DirectlyModifiedConstValue() end
function IsValid(o) return o and not o.deleted end
function IsKindOf(o,c) return o.kinds and o.kinds[c] end
function IsKindOfClasses(o,...) for _,c in ipairs({...}) do if IsKindOf(o,c) then return true end end return false end
function IsObjInDome() return false end
function ChangeHexRanges() end
function ripairs(t) return ipairs(t) end
function DelayedCall(ms,fn,...) pending[#pending+1]={fn,{...}} end
function flush() while #pending>0 do local q=pending pending={} for _,c in ipairs(q) do c[1](table.unpack(c[2])) end end end
g_Classes={
 ForestationPlantBase={properties={{id="UIRange",min=10,max=25}}},
 SubsurfaceHeaterBase={properties={{id="UIRange",min=3,max=15}}},
 TriboelectricScrubberBase={properties={{id="UIRange",min=3,max=8}}},
}
function ClassDescendantsList() return {} end
function node(kind,props)
 local o=props or {} o.kinds={[kind]=true} o.linked_extenders={} o.working=true
 o.HasMember=function(self,k) return self[k]~=nil end
 o.GetPropertyMetadata=function() return nil end
 o.OnModifiableValueChanged=function() end
 for k,v in pairs(Modifiable) do o[k]=v end
 o.SetWorkRadius=kind=="RCRover" and RCRover.SetWorkRadius or DroneControl.SetWorkRadius
 o.SetUIWorkRadius=DroneControl.SetUIWorkRadius
 o.ReconnectTaskRequesters=DroneControl.ReconnectTaskRequesters
 o.DisconnectTaskRequesters=function(self) self.disconnected=true end
 o.ConnectTaskRequesters=function(self) self.connected=true end
 o.GatherOrphanedDrones=function() end
 o.UpdateUplinkRequesters=function(self) self.refreshed=true end
 o.OnPreChangeRange=function() end
 o.OnPostChangeRange=function(self) self.refreshed=true end
 o.GatherNearbyDeposits=function(self,filter) assert(filter) self.gathered=self.exploitation_radius end
 o.OnDepositsLoaded=function() end
 o.UpdateWorking=function() end
 o.LinkPanelsInRange=function(self) self.linked=self.effect_range end
 o.ApplyHeat=function(self,working) self.heat_applied=working end
 return o
end
''')

def method(path, name):
    return re.search(r'^function '+re.escape(name)+r'\([^\n]*\).*?^end', path.read_text(encoding='utf-8'), re.M|re.S)[0]

for name in ['SetBase','SetModifier','FindModifier','UpdateModifier','ModifyValue']:
    l.execute(method(game/'Modifiers.lua','Modifiable:'+name))
for name in ['SetWorkRadius','SetUIWorkRadius','ReconnectTaskRequesters']:
    l.execute(method(game/'Buildings/DroneControl.lua','DroneControl:'+name))
l.execute(method(game/'Units/RCRover.lua','RCRover:SetWorkRadius'))
l.execute((root/'Code/Ranges.lua').read_text(encoding='utf-8'))
l.execute('''
g_Consts=node("Consts",{DefaultOutsideWorkplacesRadius=20,base_DefaultOutsideWorkplacesRadius=20})
g_Consts:SetModifier("DefaultOutsideWorkplacesRadius","LocalDomeRange10x",0,900)
hub=node("DroneHubBase",{work_radius=35,service_area_max=35,base_service_area_max=35})
rc=node("RCRover",{work_radius=20,service_area_max=20})
rocket=node("UniversalRocket",{work_radius=35,service_area_max=35})
ext=node("DroneHubExtenderBase",{work_radius=35})
scrubber=node("TriboelectricScrubberBase",{UIRange=5})
heater=node("SubsurfaceHeaterBase",{UIRange=5})
laser=node("MDSLaserBase",{protect_range=20,shoot_range=30})
extractor=node("BuildingDepositExploiterComponent",{exploitation_radius=4})
sun=node("ArtificialSunBase",{effect_range=8,base_effect_range=8}) sun.working=false
strut=node("SupportStruts",{work_radius=16,base_work_radius=16})
safari=node("RCSafari",{sight_range=8})
legacyhub=node("DroneHubBase",{work_radius=70,service_area_max=35,base_service_area_max=35,local_drone_range_2x=true})
legacyhub:SetModifier("service_area_max","LocalDroneRange2x",0,100)
legacyrc=node("RCRover",{work_radius=40,service_area_max=40,local_drone_range_2x=true})
nodes={hub,rc,rocket,ext,scrubber,heater,laser,extractor,sun,strut,safari,legacyhub,legacyrc}
Cities={{labels={},MapForEach=function(self,scope,class,fn)
 if class=="LocalRangeExtenderObject" then for _,o in ipairs(nodes) do fn(o) end end
end}}
OnMsg.PostLoadGame() flush()
assert(g_Consts.DefaultOutsideWorkplacesRadius==200)
assert(hub.work_radius==70 and hub.service_area_max==70 and hub.UIWorkRadius==70 and hub.connected)
assert(rc.work_radius==40 and rocket.work_radius==70 and ext.work_radius==70)
assert(scrubber.UIRange==10 and heater.UIRange==10 and heater.refreshed)
assert(g_Classes.SubsurfaceHeaterBase.properties[1].max==30)
assert(g_Classes.TriboelectricScrubberBase.properties[1].max==16)
assert(g_Classes.SubsurfaceHeaterBase.properties[1].min==3)
assert(laser.protect_range==40 and laser.shoot_range==60)
assert(extractor.exploitation_radius==8 and extractor.gathered==8)
assert(sun.effect_range==16 and sun.linked==16 and sun.heat_applied==false)
assert(strut.work_radius==32 and safari.sight_range==16)
assert(const.SensorTowerScanBoostMaxRange==2400000 and const.SafariMaxRouteLength==600000)
assert(legacyhub.work_radius==70 and legacyhub.service_area_max==70 and legacyrc.work_radius==40)
assert(not legacyhub:FindModifier("LocalDroneRange2x","service_area_max"))
for i=1,3 do OnMsg.PostLoadGame() flush() end
assert(hub.work_radius==70 and scrubber.UIRange==10 and legacyrc.work_radius==40)
CurrentModOptions.Hubs=3 CurrentModOptions.Domes=2 CurrentModOptions.Lasers=1
OnMsg.ApplyModOptions(CurrentModId) flush()
assert(hub.work_radius==105 and hub.service_area_max==105 and g_Consts.DefaultOutsideWorkplacesRadius==40)
assert(laser.protect_range==20 and laser.shoot_range==30 and rc.work_radius==40)
hub:SetUIWorkRadius(60)
OnMsg.PostLoadGame() flush() assert(hub.work_radius==60)
CurrentModOptions.Enabled=false
OnMsg.ApplyModOptions(CurrentModId) flush()
assert(hub.work_radius==20 and hub.service_area_max==35)
assert(rc.work_radius==20 and rocket.work_radius==35 and ext.work_radius==35)
assert(scrubber.UIRange==5 and heater.UIRange==5 and sun.effect_range==8)
assert(extractor.exploitation_radius==4 and safari.sight_range==8 and strut.work_radius==16)
assert(g_Consts.DefaultOutsideWorkplacesRadius==20)
assert(const.CommandCenterMaxRadius==50 and const.SensorTowerScanBoostMaxRange==1200000)
assert(g_Classes.SubsurfaceHeaterBase.properties[1].max==15)
CurrentModOptions={}
OnMsg.ApplyModOptions(CurrentModId) flush()
assert(rc.work_radius==40 and g_Consts.DefaultOutsideWorkplacesRadius==200)
local newhub=node("DroneHubBase",{work_radius=35,service_area_max=35,base_service_area_max=35})
DefineClass.LocalRangeExtenderObject.GameInit(newhub)
assert(newhub.work_radius==35) flush() assert(newhub.work_radius==70)
local definitions={}
for _,name in ipairs({"ForestationPlantBase","MoholeMineBase","AdvancedStirlingGeneratorBase","DroneNode","RangeElConsumer","MDSLaserBase","BuildingDepositExploiterComponent","ArtificialSunBase","SupportStruts","RCSafari","DroneHubBase","RCRover","RocketBase","UniversalRocket","DroneHubExtenderBase"}) do definitions[name]={__parents={"Object"}} end
definitions.DroneHubBase.GetSelectionRadiusScale=function(self) return self.work_radius end
definitions.BuildingDepositExploiterComponent.GatherNearbyDeposits=function(self) self.preview_radius=self.exploitation_radius end
OnMsg.ClassesGenerate(definitions)
assert(definitions.DroneNode.__parents[2]=="LocalRangeExtenderObject")
assert(definitions.DroneHubBase.GetSelectionRadiusScale({work_radius=35})==70)
assert(definitions.DroneHubBase.GetSelectionRadiusScale(newhub)==70)
local preview={exploitation_radius=4}
definitions.BuildingDepositExploiterComponent.GatherNearbyDeposits(preview)
assert(preview.preview_radius==8 and preview.exploitation_radius==4)
definitions.BuildingDepositExploiterComponent.GatherNearbyDeposits(extractor)
assert(extractor.preview_radius==8 and extractor.exploitation_radius==8)
''')
print('Passed syntax, all 14 settings, independent overrides, real game modifier/radius methods, legacy migration, repeat loads, new units, slider limits, master restore, and class hooks')
print('Engine maps and UI are stubbed. Full in-game verification remains.')

l.execute('''
forest=node("ForestationPlantBase",{UIRange=25,plant_hexes={1}})
mohole=node("MoholeMineBase",{})
stirling=node("AdvancedStirlingGeneratorBase",{opened=false})
stirling.UpdateHeat=function(self) self:ApplyHeat(self.working and self.opened) end
nodes[#nodes+1]=forest nodes[#nodes+1]=mohole nodes[#nodes+1]=stirling
CurrentModOptions={Forestation=3,Mohole=5,Stirling=3,Hubs=3}
OnMsg.PostLoadGame() flush()
assert(forest.UIRange==75 and forest.plant_hexes==false and forest.range_prev==75)
assert(const.MoholeMineHeatRadius==40 and const.AdvancedStirlingGeneratorHeatRadius==18)
assert(mohole.heat_applied and stirling.heat_applied==false)
for _,preset in ipairs({"Normal","2x","5x","Custom"}) do
 CurrentModOptions.Preset=preset
 OnMsg.ApplyModOptions(CurrentModId) flush()
 local factor=({Normal=1,["2x"]=2,["5x"]=5,Custom=3})[preset]
 assert(forest.UIRange==25*factor and hub.service_area_max==35*factor)
 assert(CurrentModOptions.Hubs==3)
 OnMsg.PostLoadGame() flush() assert(forest.UIRange==25*factor)
end
CurrentModOptions.Enabled=false
OnMsg.ApplyModOptions(CurrentModId) flush()
assert(forest.UIRange==25 and const.MoholeMineHeatRadius==8 and const.AdvancedStirlingGeneratorHeatRadius==6)
assert(g_Classes.ForestationPlantBase.properties[1].max==25)
CurrentModOptions={Preset="2x"}
stirling.opened=true
OnMsg.ApplyModOptions(CurrentModId) flush()
assert(stirling.heat_applied and forest.UIRange==50)
assert(messages[#messages]:find("Forestation: 250 → 500 m",1,true))
local count=#messages
ModsLoaded={{id="LocalRangeExtender",title="Colony Range Control"},{id="other",title="Drone range mod"},{id="unrelated",title="New paint"}}
OnMsg.PostLoadGame() flush()
assert(#messages==count+1 and messages[#messages]:find("Drone range mod",1,true))
assert(not messages[#messages]:find("New paint",1,true))
OnMsg.PostLoadGame() flush() assert(#messages==count+1)
OnMsg.ApplyModOptions("another") flush() assert(#messages==count+1)
''')
print('Passed new range settings, presets, custom preservation, cache invalidation, heat state, reports, conflict filtering and warning deduplication')
