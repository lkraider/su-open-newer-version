.DEFAULT_GOAL := package

EXTENSION_NAME := ene_open_newer_version
SRC_DIR := src
VERSION ?= $(shell git describe --tags --always --dirty | sed 's/^v//')
RBZ = $(EXTENSION_NAME)-$(VERSION).rbz

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

.PHONY: package build build-zig build-macos build-zig-macos build-windows build-zig-windows thin version

package:
	git diff --quiet -- "$(SRC_DIR)" || { echo "Refusing to package with unstaged changes under $(SRC_DIR)" >&2; exit 1; }
	git diff --cached --quiet -- "$(SRC_DIR)" || { echo "Refusing to package with staged changes under $(SRC_DIR)" >&2; exit 1; }
	test ! -e "$(RBZ)" || { echo "$(RBZ) already exists" >&2; exit 1; }
	rm -rf .build/package
	mkdir -p .build/package
	git archive --format=zip --output=.build/package.zip HEAD:$(SRC_DIR)
	unzip -qo .build/package.zip -d .build/package
	rm -f .build/package.zip
	echo "VERSION = '$(VERSION)'" > .build/package/$(EXTENSION_NAME)/version.rb
	cd .build/package && python3 -c 'import sys,zipfile,os; z=zipfile.ZipFile(os.path.join("..","..","$(RBZ)"),"w",zipfile.ZIP_DEFLATED); [z.write(os.path.join(r,f)) for r,_,fs in os.walk(".") for f in fs]; z.close()'
	rm -rf .build/package
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
	python3 cpp/thin_macho.py "$$framework/SketchUpAPI" "$$framework"/Frameworks/*.dylib && \
	rm -rf "$$framework/_CodeSignature"

version:
	@echo $(VERSION)
