from pathlib import Path
import argparse
import re
from lupa import LuaRuntime

parser = argparse.ArgumentParser()
parser.add_argument('--game-source', type=Path, required=True)
args = parser.parse_args()
lua = LuaRuntime()
lua.execute('''
BaseHeater={} AdvancedStirlingGeneratorBase={} MoholeMineBase={}
ForestationPlantBase={} const={MoholeMineHeatRadius=8,AdvancedStirlingGeneratorHeatRadius=6} guim=1000
function table.iequals(a,b) for i,v in ipairs(a) do if v~=b[i] then return false end end return true end
function GetHexesInCircle(obj,radius) return {radius} end
''')
for file, names in {
    'Heater.lua': ['BaseHeater:ApplyHeat'],
    'Buildings/MoholeMine.lua': ['MoholeMineBase:GetHeatRange'],
    'Buildings/AdvancedStirlingGenerator.lua': ['AdvancedStirlingGeneratorBase:GetHeatRange', 'AdvancedStirlingGeneratorBase:UpdateHeat'],
    'Buildings/TerraformingBuilding.lua': ['ForestationPlantBase:GetForestationRange', 'ForestationPlantBase:GetPlantHexes'],
}.items():
    source = (args.game_source/'Lua'/file).read_text(encoding='utf-8')
    for name in names:
        lua.execute(re.search(r'^function '+re.escape(name)+r'\([^\n]*\).*?^end', source, re.M|re.S)[0])
lua.execute('''
local grid={heaters={},calls={}}
function grid:ApplyHeatForm(obj,heat,x,y,radius) self.calls[#self.calls+1]={heat,radius} end
function grid:OnHeatGridChanged() end
local o={heat=100,working=true,opened=true}
o.GetMap=function() return {heat_grid=grid} end
o.GetHeatCenter=function() return 0,0 end
o.GetHeatBorder=function() return 0 end
o.ApplyHeat=BaseHeater.ApplyHeat
o.GetHeatRange=MoholeMineBase.GetHeatRange
o:ApplyHeat(true)
const.MoholeMineHeatRadius=16
o:ApplyHeat(true)
assert(#grid.calls==3)
assert(grid.calls[2][1]==-100 and grid.calls[2][2]==80000)
assert(grid.calls[3][1]==100 and grid.calls[3][2]==160000)
o:ApplyHeat(false)
assert(grid.heaters[o]==nil)
o.GetHeatRange=AdvancedStirlingGeneratorBase.GetHeatRange
o.UpdateHeat=AdvancedStirlingGeneratorBase.UpdateHeat
o:UpdateHeat()
const.AdvancedStirlingGeneratorHeatRadius=30
o:UpdateHeat()
assert(grid.heaters[o][4]==300000)
o.opened=false o:UpdateHeat() assert(grid.heaters[o]==nil)
o.opened=true o.working=false o:UpdateHeat() assert(grid.heaters[o]==nil)
local forest={UIRange=25,range_prev=25,plant_hexes={250000}}
forest.GetForestationRange=ForestationPlantBase.GetForestationRange
forest.GetPlantHexes=ForestationPlantBase.GetPlantHexes
forest.UIRange=50 forest.plant_hexes=false forest.range_prev=50
assert(forest:GetPlantHexes()[1]==500000)
''')
print('Passed real game heat removal/reapplication, closed and stopped Stirling states, and forestation cache rebuilding. Engine grid operations are stubbed.')
