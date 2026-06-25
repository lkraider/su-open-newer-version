This is my first real C++ project, so please bare with me :P .

This directory contains the C++ part of this extension. If you don't know how to
code or compile C++, and just want to update the Ruby code, feel free to ignore
it and just focus on the SketchUp Ruby extension.

# Set Up Guide

## Windows with Zig

The Windows converter is a standalone x64 console executable. It builds
without SketchUp SDK headers or `.lib` files by declaring only the small C
API surface used in `cpp/main.cpp` and linking against the checked-in
`src/ene_open_newer_version/bin/SketchUpAPI.dll`.

Required inputs:

- Zig 0.16.0 with `zig c++` available on `PATH`.
- The checked-in `src/ene_open_newer_version/bin/SketchUpAPI.dll`.
- The checked-in `src/ene_open_newer_version/bin/SketchUpCommonPreferences.dll`,
  which is loaded by `SketchUpAPI.dll` at runtime.

From the repository root:

```sh
make build-windows
```

Equivalent Zig command:

```sh
zig c++ -target x86_64-windows-gnu \
  -std=c++11 \
  -O2 \
  -DWIN32 -DNDEBUG -D_CONSOLE \
  cpp/main.cpp \
  src/ene_open_newer_version/bin/SketchUpAPI.dll \
  -o src/ene_open_newer_version/bin/ConvertVersion.exe
```

## macOS with Zig

The macOS converter is a standalone x86_64 executable. It currently builds
without SketchUp SDK headers by declaring only the small C API surface used in
`cpp/main.cpp`. This is intentionally narrow and must be rechecked if new C API
functions or structs are added.

The checked-in `src/ene_open_newer_version/bin/SU2026/SketchUpAPI.framework`
exports the required converter symbols, including `SUModelCreateFromFileWithStatus`
and `SUModelSaveToFileWithVersion`. It targets macOS 13.0, so it is acceptable
for the stated macOS 15.7.7 runtime, but it is not a general SketchUp 2017-era
compatibility build for older macOS releases.

Required inputs:

- Zig 0.16.0 with `zig c++` available on `PATH`.
- The checked-in `src/ene_open_newer_version/bin/SU2026/SketchUpAPI.framework`.

From the repository root:

```sh
make build-macos
```

Equivalent Zig command:

```sh
zig c++ -target x86_64-macos.13.0 \
  -Fsrc/ene_open_newer_version/bin/SU2026 \
  -std=c++11 \
  -O2 \
  cpp/main.cpp \
  -framework SketchUpAPI \
  -Wl,-rpath,@executable_path/SU2026 \
  -o src/ene_open_newer_version/bin/ConvertVersion

chmod 755 src/ene_open_newer_version/bin/ConvertVersion
```

### Prepare the packaged framework

Static linking is not used because the SU2026 input is a dynamic
`SketchUpAPI.framework`, not a static library.

`SketchUpAPI.framework/Versions/A/SketchUpAPI` directly declares loads for all
seven nested dylibs, so all seven must remain packaged:

- `libCommonUnits.dylib`
- `libCommonGeometry.dylib`
- `libCommonGeoutils.dylib`
- `libCommonImage.dylib`
- `libCommonUtils.dylib`
- `libCommonZip.dylib`
- `libCommonPreferences.dylib`

The supported size reduction is thinning every framework Mach-O binary to
`x86_64`, because SketchUp 2017 Make is x86_64-only.

```sh
framework=src/ene_open_newer_version/bin/SU2026/SketchUpAPI.framework/Versions/A
for binary in "$framework/SketchUpAPI" "$framework"/Frameworks/*.dylib; do
  tmp="$binary.thin"
  lipo "$binary" -thin x86_64 -output "$tmp"
  mv "$tmp" "$binary"
  codesign --remove-signature "$binary" 2>/dev/null || true
done
```

Verify the packaged framework after thinning:

```sh
python3 - <<'PY'
from pathlib import Path
import struct
base = Path('src/ene_open_newer_version/bin/SU2026/SketchUpAPI.framework/Versions/A')
expected = {
    'libCommonUnits.dylib', 'libCommonGeometry.dylib', 'libCommonGeoutils.dylib',
    'libCommonImage.dylib', 'libCommonUtils.dylib', 'libCommonZip.dylib',
    'libCommonPreferences.dylib'
}
binaries = [base / 'SketchUpAPI'] + sorted((base / 'Frameworks').glob('*.dylib'))
seen_nested = {p.name for p in (base / 'Frameworks').glob('*.dylib')}
assert expected == seen_nested
for p in binaries:
    data = p.read_bytes()
    assert struct.unpack_from('<I', data, 0)[0] == 0xfeedfacf, p
    assert struct.unpack_from('<I', data, 4)[0] == 0x1000007, p
print('SU2026 packaged framework is thin x86_64 with required dylibs')
PY
```

The remaining unavoidable native dependency is SketchUp's C API framework. The
converter's rpath points at `@executable_path/SU2026`, so keep
`SU2026/SketchUpAPI.framework` next to the built `ConvertVersion` executable.

# Use updated program in SketchUp Ruby Extension

`make build-windows` writes `src/ene_open_newer_version/bin/ConvertVersion.exe`.
Keep the checked-in `SketchUpAPI.dll` and `SketchUpCommonPreferences.dll` in
the same directory so Windows can resolve the runtime dependency.

`make build-macos` writes `src/ene_open_newer_version/bin/ConvertVersion` and
makes it executable. Keep the SU2026 framework directory at
`src/ene_open_newer_version/bin/SU2026/` so the converter's
`@executable_path/SU2026` rpath can resolve it.
