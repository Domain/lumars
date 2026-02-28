# Building Lumars with Different Lua Versions

This guide explains how to build Lumars with support for Lua 5.1 or Lua 5.5.

## Quick Start

Lumars comes pre-configured with Lua 5.1 binaries. To build with Lua 5.1:

```bash
dub build --config=lua51
```

## Selecting Lua Version

### Available Configurations

| Configuration | Lua Version | Linking | Platforms |
|---|---|---|---|
| `lua51` | 5.1 | Static | linux64, win64, macx64, macamd |
| `lua51-dynamic` | 5.1 | Dynamic | linux64, win64, macx64, macamd |
| `lua55` | 5.5 | Static | linux64, win64, macx64, macamd |
| `lua55-dynamic` | 5.5 | Dynamic | linux64, win64, macx64, macamd |

### Build Examples

```bash
# Lua 5.1 with static linking (default)
dub build --config=lua51

# Lua 5.1 with dynamic linking
dub build --config=lua51-dynamic

# Lua 5.5 with static linking
dub build --config=lua55

# Lua 5.5 with dynamic linking
dub build --config=lua55-dynamic
```

## Adding Lua 5.5 Support

Lua 5.5 is not pre-compiled with Lumars. You need to build or obtain the binaries.

> **Note:** bindbc-lua currently only recognises versions up to 5.4. When building
> with Lua 5.5 the project defines both `LUA_55` and `LUA_54` so that bindbc-lua
> falls back to the Lua 5.4 API definitions. This has been tested with Lua 5.5 and
> is expected to remain compatible, but any 5.5‑specific API additions are not yet
> accounted for in bindbc-lua itself.

### Method 1: Automatic Build (Recommended)

Run the provided build script from the project root:

**Linux/macOS:**
```bash
chmod +x build_lua55.sh
./build_lua55.sh
```

**Windows (requires Visual Studio or MinGW):**
```cmd
build_lua55.bat
```

The script will:
1. Download Lua 5.5 source
2. Compile for your platform
3. Place binaries in the `deps/` directory
4. Clean up temporary files

### Method 2: Automatic Build with Docker

For a consistent cross-platform build environment:

```bash
docker run -v $(pwd):/work -w /work -it ubuntu:latest bash -c "
    apt-get update && apt-get install -y build-essential wget tar && ./build_lua55.sh
"
```

### Method 3: Manual Build

1. **Download Lua 5.5:**
   ```bash
   curl -L -O https://www.lua.org/ftp/lua-5.5.0.tar.gz
   tar xzf lua-5.5.0.tar.gz
   cd lua-5.5.0
   ```

2. **Build for Linux x86_64:**
   ```bash
   cd src
   make linux
   cp liblua.a ../../lumars/deps/linux64/lua55.a
   ```

3. **Build for macOS (x86_64):**
   ```bash
   cd src
   make macosx
   cp liblua.a ../../lumars/deps/macx64/lua55.a
   ```

4. **Build for macOS (ARM64):**
   ```bash
   cd src
   CFLAGS="-O2 -fPIC -arch arm64" make macosx CC=clang
   cp liblua.a ../../lumars/deps/macamd/lua55.a
   ```

5. **Build for Windows with Visual Studio:**
   ```cmd
   cd src
   :: Compile all C source files
   cl /c /O2 /W3 *.c
   :: Create static library
   lib /out:lua55.lib *.obj
   copy lua55.lib ..\..\lumars\deps\win64\lua55.lib
   ```

6. **Build for Windows with MinGW:**
   ```bash
   cd src
   make mingw
   cp liblua.a ../../lumars/deps/win64/lua55.lib
   ```

## Verifying Your Build

After setting up the desired Lua version, verify it works:

```bash
# Test building with Lua 5.5
dub build --config=lua55 --verbose

# Run tests if available
dub test --config=lua55
```

## Troubleshooting

### "Lua library is the wrong version" error

This means the Lua binaries in the `deps/` directory don't match the version specified in the configuration. Ensure:
- The correct version binaries are in the `deps/` directory
- The file names match exactly (e.g., `lua55.lib` for Windows, `lua55.a` for Linux/macOS)
- The binaries were compiled for the target architecture

### Build fails with "Linker error: cannot find -llua"

Ensure the static library files exist in the correct `deps/` subdirectory:
```bash
ls -la deps/linux64/lua55.*     # Linux
ls -la deps/win64/lua55.*       # Windows
ls -la deps/macx64/lua55.*      # macOS x86_64
ls -la deps/macamd/lua55.*      # macOS ARM64
```

### Dynamic linking issues

For dynamic linking configurations (`lua55-dynamic`), ensure the shared libraries are in the same directory as the executable, or set the appropriate path variable:
- Linux: `LD_LIBRARY_PATH`
- Windows: `PATH`
- macOS: `DYLD_LIBRARY_PATH`

## Dynamic vs Static Linking

### Static Linking (Recommended)
- **Pros:** Single executable, no external dependencies
- **Cons:** Larger file size
- **Configurations:** `lua51`, `lua55`

### Dynamic Linking
- **Pros:** Smaller executable, can update Lua without recompiling
- **Cons:** Requires Lua shared library to be distributed with executable
- **Configurations:** `lua51-dynamic`, `lua55-dynamic`

## Cross-Compilation

To build for a different target architecture, you can use cross-compilation toolchains:

```bash
# Build for Windows on Linux with MinGW
export CC=x86_64-w64-mingw32-gcc
make mingw
```

For more information on cross-compilation with D, see the [DUB documentation](https://dub.io/package-format).

## References

- [Lua Official Website](https://www.lua.org/)
- [DUB Build Tool](https://dub.io/)
- [bindbc-lua Documentation](https://github.com/BindBC/bindbc-lua)
