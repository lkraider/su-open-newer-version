This is my first real C++ project, so please bare with me :P .

This directory contains the C++ part of this extension. If you don't know how to
code or compile C++, and just want to update the Ruby code, feel free to ignore
it and just focus on the SketchUp Ruby extension.

# Set Up Guide

## Windows

1. Open the Visual Studio solution (ConvertVersion.sln).

2. Open properties of the ConvertVersion project (right click > Properties).

3. Make sure _All Configurations_ is selected in the Configurations drop down.

4. Update _Configuration Properties > C/C++ > Include Directories_ to refer
to where the
[SketchUp SDK](https://extensions.sketchup.com/en/developer_center/sketchup_sdk)
headers are located on your machine.

5. Update _Configuration Properties > Linker > Additional Library
Directories_ to refer to where the SketchUp SDK binaries are located on your
machine.

6. Update _Configuration Properties > Build Events > Post-Build Events > Command
line_ to refer to where the Sketchup SDK binaries are on your machine.

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

The remaining unavoidable native dependency is SketchUp's C API framework. The
converter's rpath points at `@executable_path/SU2026`, so keep
`SU2026/SketchUpAPI.framework` next to the built `ConvertVersion` executable.

# Use updated program in SketchUp Ruby Extension

After building a new Windows `ConvertVersion.exe`, copy it into
`src/ene_open_newer_version/bin/` to make it a part of the Ruby extension. Also
copy the most recent `SketchUpAPI.dll` and `SketchUpCommonPreferences.dll` to
this directory.

After building a new macOS `ConvertVersion`, copy it into
`src/ene_open_newer_version/bin/` and make it executable. Keep the SU2026
framework directory at `src/ene_open_newer_version/bin/SU2026/` so the
converter's `@executable_path/SU2026` rpath can resolve it.
