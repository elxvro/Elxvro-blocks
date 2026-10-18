#!/usr/bin/env python3
"""Reject deprecated Window bar-color invocations in the compiled MainActivity."""
from pathlib import Path
import struct
import sys
import zipfile

apk = Path(sys.argv[1])
with zipfile.ZipFile(apk) as archive:
    dex = archive.read('classes.dex')

def u16(offset): return struct.unpack_from('<H', dex, offset)[0]
def u32(offset): return struct.unpack_from('<I', dex, offset)[0]
def uleb(offset):
    value = shift = 0
    while True:
        byte = dex[offset]
        offset += 1
        value |= (byte & 127) << shift
        if not byte & 128:
            return value, offset
        shift += 7

strings = []
for index in range(u32(0x38)):
    address = u32(u32(0x3c) + 4 * index)
    _, address = uleb(address)
    strings.append(dex[address:dex.index(b'\x00', address)].decode('utf-8', 'replace'))

types = [strings[u32(u32(0x44) + i * 4)] for i in range(u32(0x40))]
methods = []
for i in range(u32(0x58)):
    owner, _, name = struct.unpack_from('<HHI', dex, u32(0x5c) + i * 8)
    methods.append((types[owner], strings[name]))

name = 'Lcom/elxvro/elxvro_blocks/MainActivity;'
count = 0
for index in range(u32(0x60)):
    offset = u32(0x64) + index * 32
    if types[u32(offset)] != name:
        continue
    data_offset = u32(offset + 24)
    lengths = []
    for _ in range(4):
        length, data_offset = uleb(data_offset)
        lengths.append(length)
    for _ in range(lengths[0] + lengths[1]):
        _, data_offset = uleb(data_offset)
        _, data_offset = uleb(data_offset)
    for length in lengths[2:]:
        method_id = 0
        for _ in range(length):
            increment, data_offset = uleb(data_offset)
            method_id += increment
            _, data_offset = uleb(data_offset)
            code_offset, data_offset = uleb(data_offset)
            if methods[method_id][1] != 'onCreate' or not code_offset:
                continue
            count += 1
            size = u32(code_offset + 12)
            instructions = dex[code_offset + 16:code_offset + 16 + size * 2]
            forbidden = {'setStatusBarColor', 'setNavigationBarColor'}
            for position in range(0, len(instructions) - 3, 2):
                op = instructions[position]
                if op in {0x6e, 0x6f, 0x70, 0x71, 0x72, 0x74, 0x75, 0x76, 0x77, 0x78}:
                    ref = struct.unpack_from('<H', instructions, position + 2)[0]
                    if ref < len(methods) and methods[ref][0] == 'Landroid/view/Window;' and methods[ref][1] in forbidden:
                        raise SystemExit('Disallowed API in MainActivity.onCreate: ' + methods[ref][1])
if count != 1:
    raise SystemExit('Unable to verify MainActivity.onCreate dex code.')
print('PASS: compiled MainActivity.onCreate has no deprecated bar-color invocations.')
