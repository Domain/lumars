#!/bin/bash

# Build Lua 5.5 binaries for multiple platforms
# This script downloads the Lua 5.5 source and builds it for different architectures

set -e

LUA_VERSION="5.5.0"
LUA_URL="https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz"
WORK_DIR=$(mktemp -d)
DEPS_DIR="$(dirname "$0")/deps"

echo "Building Lua 5.5 from source..."
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
    build_platform "linux" "gcc" "-O2 -fPIC" "$DEPS_DIR/linux64" "lua55"
fi

# Build for macOS x86_64
if command -v clang &> /dev/null && [[ "$OSTYPE" == "darwin"* ]]; then
    build_platform "macosx" "clang" "-O2 -fPIC" "$DEPS_DIR/macx64" "lua55"
fi

# Build for macOS ARM64 (Apple Silicon)
if command -v clang &> /dev/null && [[ "$OSTYPE" == "darwin"* ]]; then
    CFLAGS="-O2 -fPIC -arch arm64" make macosx CC="clang" -j$(nproc)
    cp src/liblua.a "$DEPS_DIR/macamd/lua55.a"
    echo "✓ Built for macOS ARM64: $DEPS_DIR/macamd/lua55.a"
    make clean || true
fi

# Build for Windows (requires MinGW)
if command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo "Building for Windows x86_64..."
    make clean || true
    make mingw CC="x86_64-w64-mingw32-gcc" AR="x86_64-w64-mingw32-ar rcu" RANLIB="x86_64-w64-mingw32-ranlib" -j$(nproc)
    cp src/liblua.a "$DEPS_DIR/win64/lua55.lib"
    echo "✓ Built for Windows: $DEPS_DIR/win64/lua55.lib"
    make clean || true
fi

# Cleanup
cd /
rm -rf "$WORK_DIR"

echo ""
echo "========================================="
echo "Lua 5.5 build complete!"
echo "========================================="
echo "Binaries have been placed in $DEPS_DIR"
echo ""
echo "To use Lua 5.5, add to your project configuration:"
echo "  dub build --config=lua55"
echo ""
