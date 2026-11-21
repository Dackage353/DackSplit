# this is an edited copy of aglab's gen_sm64_asl.py
# https://github.com/aglab2/LiveSplitAutoSplitters/blob/master/gen_sm64_asl.py

import sys
from string import Template


if len(sys.argv) != 2:
    print(f"error: missing map")
    sys.exit(1)

map_path = sys.argv[1]
tmpl_path = 'extract.tmpl'
output_path = 'output.txt'


def ptr_swap(ptr, table):
    c = ptr // 4
    o = ptr % 4
    os = table[o]
    assert os != -1, f"Failed to swap 0x{ptr:x} using {table}"
    return (c * 4 + os) & 0xffffff


# All pointers must be aligned on a size it will read
# It is not an x86 requirement but MIPS requirement
def ptr_swap8(ptr):
    return ptr_swap(ptr, [ 3, 2, 1, 0 ])


def ptr_swap16(ptr):
    return ptr_swap(ptr, [ 2, -1, 0, -1 ])


def ptr_swap32(ptr):
    return ptr_swap(ptr, [0, -1, -1, -1])


def get_map():
    map = {}
    with open(map_path) as map_file:
        for map_line in map_file:
            map_line_split = map_line.split()
            if len(map_line_split) != 2:
                continue

            map_addr_str = map_line_split[0]
            map_symbol = map_line_split[1]
            try:
                map_addr = int(map_addr_str, 0)
                map[map_symbol] = map_addr
            except:
                pass

    return map


if __name__ == '__main__':

    map = get_map()

    gMarioStates = map.get('gMarioStates')
    gCurrLevelNum = map.get('gCurrLevelNum')
    gPlayerSpawnInfos = map.get('gPlayerSpawnInfos')
    gNumVblanks = map.get('gNumVblanks')
    gSaveBuffer = map.get('gSaveBuffer')
    gTimerOffset = map.get('gTimerOffset')
    gGlobalTimer = map.get('gGlobalTimer')


    with open(tmpl_path) as file:
        text = file.read()

    text = Template(text).safe_substitute(gMarioStates_numStars = hex(ptr_swap16(gMarioStates + 0xAA)) if gMarioStates else '')
    text = Template(text).safe_substitute(gMarioStates_action = hex(ptr_swap32(gMarioStates + 0xC)) if gMarioStates else '')

    text = Template(text).safe_substitute(gCurrLevelNum = hex(ptr_swap16(gCurrLevelNum)) if gCurrLevelNum else '')
    text = Template(text).safe_substitute(gPlayerSpawnInfos_areaIndex = hex(ptr_swap8(gPlayerSpawnInfos + 0xC)) if gPlayerSpawnInfos else '')

    text = Template(text).safe_substitute(gNumVblanks = hex(ptr_swap32(gNumVblanks)) if gNumVblanks else '')
    text = Template(text).safe_substitute(gSaveBuffer = hex(ptr_swap32(gSaveBuffer)) if gSaveBuffer else '')

    text = Template(text).safe_substitute(gTimerOffset = hex(ptr_swap32(gTimerOffset)) if gTimerOffset else '')
    text = Template(text).safe_substitute(gGlobalTimer = hex(ptr_swap32(gGlobalTimer)) if gGlobalTimer else '')


    with open(output_path, 'w') as file:
        file.write(text)
