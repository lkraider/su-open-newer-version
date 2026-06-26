"""Extract the x86_64 slice from universal (FAT) Mach-O binaries in-place.

Removes LC_CODE_SIGNATURE from the resulting thin binary to avoid
invalid-signature warnings.
"""
import os
import struct
import sys
from pathlib import Path

FAT_MAGIC = 0xCAFEBABE
FAT_MAGIC_64 = 0xCAFEBABF
MH_MAGIC_64 = 0xFEEDFACF
CPU_X86_64 = 0x01000007
LC_CODE_SIGNATURE = 0x1D


def thin_one(path: Path) -> bool:
    data = path.read_bytes()
    magic = struct.unpack_from(">I", data, 0)[0]
    if magic in (FAT_MAGIC, FAT_MAGIC_64):
        nfat = struct.unpack_from(">I", data, 4)[0]
        fat_archs = []
        for i in range(nfat):
            cputype, cpusubtype, offset, size = struct.unpack_from(
                ">IIII", data, 8 + i * 20
            )
            fat_archs.append((cputype, offset, size))
        x86 = [(off, sz) for cpu, off, sz in fat_archs if cpu == CPU_X86_64]
        if not x86:
            print(f"{path.name}: no x86_64 slice", file=sys.stderr)
            sys.exit(1)
        off, sz = x86[0]
        thin = data[off : off + sz]
        ncmds = struct.unpack_from("<I", thin, 16)[0]
        cmds_off = 32
        new_ncmds = ncmds
        for _ in range(ncmds):
            cmd, cmdsize = struct.unpack_from("<II", thin, cmds_off)
            if cmd == LC_CODE_SIGNATURE:
                thin = (
                    thin[:cmds_off]
                    + b"\x00" * cmdsize
                    + thin[cmds_off + cmdsize :]
                )
                new_ncmds -= 1
                break
            cmds_off += cmdsize
        if new_ncmds != ncmds:
            thin = thin[:16] + struct.pack("<I", new_ncmds) + thin[20:]
        path.write_bytes(thin)
        return True
    elif struct.unpack_from("<I", data, 0)[0] == MH_MAGIC_64:
        return False
    else:
        print(f"{path.name}: unknown format {hex(magic)}", file=sys.stderr)
        sys.exit(1)


def main():
    changed = 0
    for arg in sys.argv[1:]:
        p = Path(arg)
        if thin_one(p):
            print(f"Thinned: {p.name}")
            changed += 1
        else:
            print(f"Already thin: {p.name}")
    if changed:
        print(f"Thinned {changed} file(s)")


if __name__ == "__main__":
    main()