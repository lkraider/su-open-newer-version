.DEFAULT_GOAL := package

EXTENSION_NAME := ene_open_newer_version
SRC_DIR := src
RBZ = $(EXTENSION_NAME)-$(shell git rev-parse --short HEAD).rbz

ZIG ?= zig
ZIG_CXXFLAGS ?= -std=c++11 -O2
MACOS_ZIG_TARGET ?= x86_64-macos.13.0
WINDOWS_ZIG_TARGET ?= x86_64-windows-gnu
BIN_DIR := $(SRC_DIR)/$(EXTENSION_NAME)/bin
MACOS_FRAMEWORK_ROOT := $(BIN_DIR)/SU2026
MACOS_CONVERTER := $(BIN_DIR)/ConvertVersion
WINDOWS_CONVERTER := $(BIN_DIR)/ConvertVersion.exe
WINDOWS_SKETCHUP_API_DLL := $(BIN_DIR)/SketchUpAPI.dll
WINDOWS_COMMON_PREFS_DLL := $(BIN_DIR)/SketchUpCommonPreferences.dll

.PHONY: package build build-zig build-macos build-zig-macos build-windows build-zig-windows thin

package:
	git diff --quiet -- "$(SRC_DIR)" || { echo "Refusing to package with unstaged changes under $(SRC_DIR)" >&2; exit 1; }
	git diff --cached --quiet -- "$(SRC_DIR)" || { echo "Refusing to package with staged changes under $(SRC_DIR)" >&2; exit 1; }
	test ! -e "$(RBZ)" || { echo "$(RBZ) already exists" >&2; exit 1; }
	git archive --format=zip --output="$(RBZ)" HEAD:$(SRC_DIR) $(EXTENSION_NAME).rb $(EXTENSION_NAME)
	@echo "Created $(RBZ)"

build: build-zig

build-zig: build-zig-macos build-zig-windows

build-macos: build-zig-macos

build-zig-macos:
	$(ZIG) c++ -target $(MACOS_ZIG_TARGET) \
	  -F$(MACOS_FRAMEWORK_ROOT) \
	  $(ZIG_CXXFLAGS) \
	  cpp/main.cpp \
	  -framework SketchUpAPI \
	  -Wl,-rpath,@executable_path/SU2026 \
	  -o $(MACOS_CONVERTER)
	chmod 755 $(MACOS_CONVERTER)

build-windows: build-zig-windows

build-zig-windows:
	test -f "$(WINDOWS_SKETCHUP_API_DLL)" || { echo "Missing $(WINDOWS_SKETCHUP_API_DLL)" >&2; exit 1; }
	test -f "$(WINDOWS_COMMON_PREFS_DLL)" || { echo "Missing $(WINDOWS_COMMON_PREFS_DLL)" >&2; exit 1; }
	$(ZIG) c++ -target $(WINDOWS_ZIG_TARGET) \
	  $(ZIG_CXXFLAGS) \
	  -DWIN32 -DNDEBUG -D_CONSOLE \
	  cpp/main.cpp \
	  "$(WINDOWS_SKETCHUP_API_DLL)" \
	  -o "$(WINDOWS_CONVERTER)"

thin:
	framework="$(MACOS_FRAMEWORK_ROOT)/SketchUpAPI.framework/Versions/A"; \
	python3 cpp/thin_macho.py "$$framework/SketchUpAPI" "$$framework"/Frameworks/*.dylib
