# Lua Dependencies

This directory contains precompiled Lua binaries for different platforms and architectures.

## Directory Structure

```
deps/
├── linux64/          # Linux x86_64 binaries
├── macx64/           # macOS x86_64 binaries  
├── macamd/           # macOS ARM64 (Apple Silicon) binaries
└── win64/            # Windows x86_64 binaries
```

## Lua 5.1 Binaries

Pre-built Lua 5.1 binaries are already included in this repository:
- `lua51.a` (static libraries on Linux/macOS)
- `lua51.lib` (static library on Windows)
- `lua51.dll` / `liblua.5.1.dylib` (shared libraries)

## Lua 5.5 Binaries

To add Lua 5.5 support to Lumars, you need to either:

1. **Use the build script** - Run `build_lua55.sh` (Linux/macOS) or `build_lua55.bat` (Windows) from the project root
2. **Add manually** - Place compiled Lua 5.5 binaries with these names:

### Static Libraries
- `linux64/lua55.a` - Linux x86_64
- `win64/lua55.lib` - Windows x86_64
- `macx64/lua55.a` - macOS x86_64
- `macamd/lua55.a` - macOS ARM64

### Shared Libraries (for dynamic linking)
- `linux64/liblua.5.5.so` - Linux x86_64
- `win64/lua55.dll` - Windows x86_64
- `macx64/liblua.5.5.dylib` - macOS x86_64
- `macamd/liblua.5.5.dylib` - macOS ARM64

## Building Lua Binaries

### Using the provided scripts

**Linux/macOS:**
```bash
cd ..  # Go to project root
chmod +x build_lua55.sh
./build_lua55.sh
```

**Windows:**
```cmd
cd ..  # Go to project root
build_lua55.bat
```

### Manual compilation

Download Lua 5.5 source from [lua.org](https://www.lua.org/ftp/) and compile using:

**Linux/macOS:**
```bash
cd lua-5.5.0/src
make linux  # or: make macosx
cp liblua.a ../../lumars/deps/linux64/lua55.a  # or appropriate directory
```

**Windows (with Visual Studio):**
```cmd
cd lua-5.5.0\src
REM Compile all C files with the MSVC compiler
cl /c /O2 *.c
lib /out:lua55.lib *.obj
copy lua55.lib ..\..\lumars\deps\win64\lua55.lib
```

**Windows (with MinGW):**
```bash
cd lua-5.5.0
make mingw
cp src/liblua.a ../lumars/deps/win64/lua55.lib
```

## Testing

After adding Lua 5.5 binaries, you can build Lumars with:

```bash
# Static linking
dub build --config=lua55

# Dynamic linking  
dub build --config=lua55-dynamic
```
