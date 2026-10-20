#!/usr/bin/env python3
"""Patch the ProRWTS loader (U4) in ultima4_hd1440_iic_mb.po so that every
block it writes goes through a buffer in main RAM ($BC00-$BDFF).

Why: the game saves with BSAVE PRTY,A$0 / ROST,A$EC00 / LIST,A$EE00 and the
loader hands those addresses straight to the SmartPort firmware as the
512-byte buffer. A buffer on page 0/1 changes while the firmware (which uses
zero page and the stack) is sending it, and $D000-$FFFF is language-card RAM
the firmware cannot see, so a real IIc + Floppy Emu reports CHECKSUM ERROR.

The patch:
  * a 44-byte routine at $B700 (the start of the loader's $B700 page is a
    leftover copy of $B935-$B9E9 that nothing calls; checked by snapshotting
    RAM at the title, in play and after a save):
    when the call is the last block of a write, copy the block to $BC00 and
    point the buffer there, then go on to the original $BFB0 block call;
  * the write loop's JSR $BFB0 (at $BF45) is redirected to it;
  * a small installer at $1100, reached from the loader's JSR $B9AF at $0990,
    copies the routine into place after the loader has relocated its pages.
"""
import struct
import sys

BLOCK = 512


def blk(img, n):
    return img[n * BLOCK:(n + 1) * BLOCK]


def find_entry(img, name):
    """Return (dir block, entry offset) of a file in the volume directory."""
    b = 2
    first = True
    while b:
        d = blk(img, b)
        for i in range(13):
            if first and i == 0:
                continue
            off = 4 + i * 39
            e = d[off:off + 39]
            if e[0] >> 4 and e[1:1 + (e[0] & 15)].decode() == name:
                return b, off
        first = False
        b = struct.unpack('<H', d[2:4])[0]
    raise SystemExit(f'{name} not found')


def free_block(img):
    """First free block from the volume bitmap; marks it used."""
    vol = blk(img, 2)
    bitmap_ptr = struct.unpack('<H', vol[4 + 0x23:4 + 0x25])[0]
    total = struct.unpack('<H', vol[4 + 0x25:4 + 0x27])[0]
    for n in range(total):
        byte = bitmap_ptr * BLOCK + n // 8
        bit = 0x80 >> (n % 8)
        if img[byte] & bit:          # 1 = free
            img[byte] &= ~bit & 0xFF
            return n
    raise SystemExit('volume full')


ORG = 0x0800

# The routine copied to $B700. Only 6502 opcodes; branches are relative.
ROUTINE = bytes([
    0xA4, 0x53,             # B700 LDY $53      pages left to write
    0xC4, 0x54,             # B702 CPY $54      2 = last block of a write
    0xD0, 0x23,             # B704 BNE $B729    no: plain call
    0xA4, 0x52,             # B706 LDY $52
    0xD0, 0x1F,             # B708 BNE $B729
    0x48,                   # B70A PHA          block number hi
    0x8A,                   # B70B TXA
    0x48,                   # B70C PHA          block number lo
    0xB1, 0x44,             # B70D LDA ($44),Y  copy 512 bytes -> $BC00
    0x99, 0x00, 0xBC,       # B70F STA $BC00,Y
    0xE6, 0x45,             # B712 INC $45
    0xB1, 0x44,             # B714 LDA ($44),Y
    0x99, 0x00, 0xBD,       # B716 STA $BD00,Y
    0xC6, 0x45,             # B719 DEC $45
    0xC8,                   # B71B INY
    0xD0, 0xEF,             # B71C BNE $B70D
    0x84, 0x44,             # B71E STY $44      buffer = $BC00
    0xA9, 0xBC,             # B720 LDA #$BC
    0x85, 0x45,             # B722 STA $45
    0x68,                   # B724 PLA
    0xAA,                   # B725 TAX
    0x68,                   # B726 PLA
    0xEA, 0xEA,             # B727 NOP NOP      (keeps BNE targets on the JMP)
    0x4C, 0xB0, 0xBF,       # B729 JMP $BFB0
])
assert len(ROUTINE) == 0x2C
ROUTINE_AT = 0xB700

INSTALL_AT = 0x1100
INSTALLER = bytes([
    0xA0, len(ROUTINE) - 1,         # LDY #$2B
    0xB9, 0x1A, 0x11,               # LDA $111A,Y
    0x99, 0x00, 0xB7,               # STA $B700,Y
    0x88,                           # DEY
    0x10, 0xF7,                     # BPL *-9
    0xA9, 0x00,                     # LDA #$00
    0x8D, 0x46, 0xBF,               # STA $BF46     JSR $BFB0 -> JSR $B700
    0xA9, 0xB7,                     # LDA #$B7
    0x8D, 0x47, 0xBF,               # STA $BF47
    0xA0, 0x00,                     # LDY #$00      the loader goes on with Y=0
    0x4C, 0xAF, 0xB9,               # JMP $B9AF     what the loader called
])
ROUTINE_SRC = INSTALL_AT + len(INSTALLER)
assert ROUTINE_SRC == 0x111A


def main(src, dst):
    img = bytearray(open(src, 'rb').read())
    dirblk, off = find_entry(img, 'U4')
    e = dirblk * BLOCK + off
    storage = img[e] >> 4
    key = struct.unpack('<H', img[e + 0x11:e + 0x13])[0]
    eof = img[e + 0x15] | img[e + 0x16] << 8 | img[e + 0x17] << 16
    if storage != 2:
        raise SystemExit('U4 is not a sapling file; unexpected layout')

    index = blk(img, key)
    data = bytearray()
    for i in range(4):
        n = index[i] | index[256 + i] << 8
        data += blk(img, n) if n else bytes(BLOCK)
    data = data[:eof]

    # Sanity checks: the bytes this patch expects to change.
    def at(addr, n):
        return bytes(data[addr - ORG:addr - ORG + n])
    if at(0x0990, 3) == bytes([0x20, 0x00, 0x11]):
        raise SystemExit('already patched')
    assert at(0x0990, 3) == bytes([0x20, 0xAF, 0xB9]), at(0x0990, 3).hex()
    assert at(0x0B08, 3) == bytes([0x20, 0xB0, 0xBF]), 'JSR $BFB0 at $BF45'

    data[0x0990 - ORG:0x0993 - ORG] = bytes([0x20, 0x00, 0x11])
    new_eof = ROUTINE_SRC + len(ROUTINE) - ORG
    data += bytes(new_eof - len(data))
    data[INSTALL_AT - ORG:INSTALL_AT - ORG + len(INSTALLER)] = INSTALLER
    data[ROUTINE_SRC - ORG:ROUTINE_SRC - ORG + len(ROUTINE)] = ROUTINE

    # Write back: blocks 0..2 in place, block 3 (offset $600) stays sparse,
    # block 4 (offset $800, holds $1000-$11FF) is new.
    ib = bytearray(index)
    for i in range(5):
        chunk = bytes(data[i * BLOCK:(i + 1) * BLOCK])
        chunk += bytes(BLOCK - len(chunk))
        n = ib[i] | ib[256 + i] << 8
        if not any(chunk):
            continue
        if not n:
            n = free_block(img)
            ib[i], ib[256 + i] = n & 0xFF, n >> 8
            used = struct.unpack('<H', img[e + 0x13:e + 0x15])[0] + 1
            img[e + 0x13:e + 0x15] = struct.pack('<H', used)
        img[n * BLOCK:(n + 1) * BLOCK] = chunk
    img[key * BLOCK:(key + 1) * BLOCK] = ib
    img[e + 0x15:e + 0x18] = bytes([new_eof & 0xFF, (new_eof >> 8) & 0xFF, 0])

    open(dst, 'wb').write(img)
    print(f'U4: eof {eof} -> {new_eof}, written {dst}')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
