.DEFAULT_GOAL := package

EXTENSION_NAME := ene_open_newer_version
SRC_DIR := src
RBZ = $(EXTENSION_NAME)-$(shell git rev-parse --short HEAD).rbz

ZIG ?= zig
ZIG_TARGET ?= x86_64-macos.13.0
ZIG_CXXFLAGS ?= -std=c++11 -O2
MACOS_FRAMEWORK_ROOT := $(SRC_DIR)/$(EXTENSION_NAME)/bin/SU2026
MACOS_CONVERTER := $(SRC_DIR)/$(EXTENSION_NAME)/bin/ConvertVersion

.PHONY: package build build-zig

package:
	git diff --quiet -- "$(SRC_DIR)" || { echo "Refusing to package with unstaged changes under $(SRC_DIR)" >&2; exit 1; }
	git diff --cached --quiet -- "$(SRC_DIR)" || { echo "Refusing to package with staged changes under $(SRC_DIR)" >&2; exit 1; }
	test ! -e "$(RBZ)" || { echo "$(RBZ) already exists" >&2; exit 1; }
	git archive --format=zip --output="$(RBZ)" HEAD:$(SRC_DIR) $(EXTENSION_NAME).rb $(EXTENSION_NAME)
	@echo "Created $(RBZ)"

build: build-zig

build-zig:
	$(ZIG) c++ -target $(ZIG_TARGET) \
	  -F$(MACOS_FRAMEWORK_ROOT) \
	  $(ZIG_CXXFLAGS) \
	  cpp/main.cpp \
	  -framework SketchUpAPI \
	  -Wl,-rpath,@executable_path/SU2026 \
	  -o $(MACOS_CONVERTER)
	chmod 755 $(MACOS_CONVERTER)
