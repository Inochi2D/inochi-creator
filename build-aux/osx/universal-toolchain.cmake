# Inochi Creator's macOS dependencies are built as universal binaries. Optional
# libraries installed by Homebrew or MacPorts are commonly host-architecture
# only and must not leak into that build.
set(CMAKE_IGNORE_PREFIX_PATH "/opt/homebrew;/usr/local;/opt/local" CACHE STRING "" FORCE)
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "" FORCE)
set(FT_DISABLE_PNG ON CACHE BOOL "" FORCE)
set(FT_DISABLE_HARFBUZZ ON CACHE BOOL "" FORCE)
set(FT_DISABLE_BROTLI ON CACHE BOOL "" FORCE)
