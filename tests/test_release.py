from pathlib import Path
import sys
import re
from PIL import Image
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('mod', type=Path)
parser.add_argument('--game-source', type=Path, required=True)
args = parser.parse_args()
from lupa import LuaRuntime

root = args.mod
l = LuaRuntime(unpack_returned_tuples=True)
l.execute('''
function PlaceObj(class, props)
    local result={class=class}
    for i=1,#props,2 do result[props[i]]=props[i+1] end
    return result
end
function Untranslated(value) return value end
g_Pdx={account={}}
''')
metadata = l.execute((root/'metadata.lua').read_text(encoding='utf-8'))
assert metadata['title'] == 'Colony Range Control'
assert metadata['author'] == 'hawshemi'
assert metadata['id'] == 'LocalRangeExtender'
assert len(metadata['title']) <= 60
assert len(metadata['short_description']) <= 200
assert len(metadata['description']) <= 8000
assert metadata['lua_revision'] == 403908
image_path = root/metadata['image'].removeprefix('Mod/LocalRangeExtender/')
assert image_path.stat().st_size < 2*1024*1024
with Image.open(image_path) as image:
    image.verify()
for _, relative in metadata['code'].items():
    assert (root/relative).is_file()
options = l.execute((root/'items.lua').read_text(encoding='utf-8'))
assert len(options) == 20
names = [item['name'] for _,item in options.items() if item['class'].startswith('ModItemOption')]
assert len(set(names)) == 19
item_source = (args.game_source/'CommonLua/Modding/ModItem.lua').read_text(encoding='utf-8')
l.execute('ModItemCode = {}')
l.execute(re.search(r'^function ModItemCode:GetCodeFileName\(.*?^end', item_source, re.M|re.S)[0])
for _, item in options.items():
    if item['class'] == 'ModItemCode':
        # The editor rebuilds filenames from the item name when saving.
        item['name'] = item['name'] or 'Script'
        relative = l.globals().ModItemCode.GetCodeFileName(item)
        assert relative == item['CodeFileName'], f'Editor saves {relative}, not {item["CodeFileName"]}'
        assert (root/relative).is_file()
        assert relative in list(metadata['code'].values())
source = (args.game_source/'CommonLua/Libs/Paradox/ParadoxMods.lua').read_text(encoding='utf-8')
preflight = re.search(r'^function PDX_PrepareForUpload\(.*?^end', source, re.M|re.S)[0]
l.execute(preflight)
assert l.globals().PDX_PrepareForUpload(None, metadata, None) is True
print('Passed real publisher metadata preflight with a simulated account, field limits, thumbnail limit, code paths, and all option definitions. No network operation was performed.')
