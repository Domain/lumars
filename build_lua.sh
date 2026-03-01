#!/bin/bash

# Build Lua binaries for multiple platforms
# This script downloads the Lua source and builds it for different architectures
# Usage: ./build_lua.sh [version]
#   version: Lua version (e.g., 5.1, 5.2, 5.3, 5.4, 5.5). Default: 5.5.0

set -e

# Parse arguments
LUA_VERSION="${1:-5.5.0}"

# Extract major and minor version for library naming (e.g., 5.5.0 -> 55)
LUA_MAJOR=$(echo "$LUA_VERSION" | cut -d. -f1)
LUA_MINOR=$(echo "$LUA_VERSION" | cut -d. -f2)
LUA_LIB_NAME="lua${LUA_MAJOR}${LUA_MINOR}"

LUA_URL="https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz"
WORK_DIR=$(mktemp -d)
DEPS_DIR="$(dirname "$0")/deps"

echo "Building Lua ${LUA_VERSION} (lib name: ${LUA_LIB_NAME}) from source..."
echo "Working directory: $WORK_DIR"
echo "Dependencies directory: $DEPS_DIR"

# Create deps directories if they don't exist
mkdir -p "$DEPS_DIR/linux64"
mkdir -p "$DEPS_DIR/macx64"
mkdir -p "$DEPS_DIR/macamd"
mkdir -p "$DEPS_DIR/win64"

# Download Lua source
cd "$WORK_DIR"
echo "Downloading Lua ${LUA_VERSION}..."
wget -q "$LUA_URL"
tar xzf "lua-${LUA_VERSION}.tar.gz"
cd "lua-${LUA_VERSION}"

# Function to build for a specific platform
build_platform() {
    local platform=$1
    local cc=$2
    local cflags=$3
    local output_dir=$4
    local output_name=$5
    
    echo "Building for $platform..."
    
    # Clean previous builds
    make clean || true
    
    # Build
    make $platform CC="$cc" CFLAGS="$cflags" -j$(nproc)
    
    # Copy the static library to the deps directory
    cp src/liblua.a "$output_dir/$output_name.a"
    echo "✓ Built for $platform: $output_dir/$output_name.a"
    
    make clean || true
}

# Build for Linux x86_64
if command -v gcc &> /dev/null; then
    build_platform "linux" "gcc" "-O2 -fPIC" "$DEPS_DIR/linux64" "${LUA_LIB_NAME}"
fi

# Build for macOS x86_64
if command -v clang &> /dev/null && [[ "$OSTYPE" == "darwin"* ]]; then
    build_platform "macosx" "clang" "-O2 -fPIC" "$DEPS_DIR/macx64" "${LUA_LIB_NAME}"
fi

# Build for macOS ARM64 (Apple Silicon)
if command -v clang &> /dev/null && [[ "$OSTYPE" == "darwin"* ]]; then
    CFLAGS="-O2 -fPIC -arch arm64" make macosx CC="clang" -j$(nproc)
    cp src/liblua.a "$DEPS_DIR/macamd/${LUA_LIB_NAME}.a"
    echo "✓ Built for macOS ARM64: $DEPS_DIR/macamd/${LUA_LIB_NAME}.a"
    make clean || true
fi

# Build for Windows (requires MinGW)
if command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo "Building for Windows x86_64..."
    make clean || true
    make mingw CC="x86_64-w64-mingw32-gcc" AR="x86_64-w64-mingw32-ar rcu" RANLIB="x86_64-w64-mingw32-ranlib" -j$(nproc)
    cp src/liblua.a "$DEPS_DIR/win64/${LUA_LIB_NAME}.lib"
    echo "✓ Built for Windows: $DEPS_DIR/win64/${LUA_LIB_NAME}.lib"
    make clean || true
fi

# Cleanup
cd /
rm -rf "$WORK_DIR"

echo ""
echo "========================================="
echo "Lua ${LUA_VERSION} build complete!"
echo "========================================="
echo "Binaries have been placed in $DEPS_DIR"
echo ""
echo "To use Lua ${LUA_VERSION}, add to your project configuration:"
echo "  dub build --config=lua${LUA_MAJOR}${LUA_MINOR}"
echo ""
