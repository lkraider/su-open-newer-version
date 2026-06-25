# Eneroth Open Newer Version

SketchUp plugin for converting and opening models made in a newer version of
SketchUp.

For more info about the C++ programs used in this extension, see cpp/README.md.

Requirements:
SketchUp 2014+
Windows 64-bit or macOS

macOS support targets SketchUp 2017 Make on macOS 15.7.7 with the bundled SU2026 converter framework.

Supported source model versions depend on the native converter library bundled for each platform. The macOS converter is linked against the bundled SU2026 `SketchUpAPI.framework` and saves output to the running SketchUp version, e.g. SketchUp 2017 when run from SketchUp 2017 Make.
