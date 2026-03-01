# Building Lumars with Different Lua Versions

This guide explains how to build Lumars with support for Lua 5.1 through Lua 5.5.
The wrapper is designed to compile against any of those versions; when using 5.2+
some older API calls are emulated or replaced (see "Version compatibility" below).

Please note that while most of the core Lua API is usable through Lumars, some
of the newer features introduced in 5.2–5.5 (integer‑specific helpers, extended
garbage‑collector controls, `lua_newuserdatauv`, coroutine resume/yield, etc.)
are **not** wrapped and must be accessed manually via the raw Lua stack.  The
bindings currently treat all numbers as `double` so integer behaviour is not
fully exploited; this is documented in the README under "Missing features".

## Quick Start

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

## Version compatibility

Because the bundled `bindbc-lua` package only understands Lua versions up to
5.4, the `lua55` configurations define **both** `LUA_55` and `LUA_54`.  This
causes bindbc-lua to fall back to its 5.4 API definitions while the project can
still be conditionally compiled with `version(LUA_55)` guards.  No Lua 5.5‑only
functions are currently available until bindbc-lua adds explicit support.

When compiling for Lua 5.1 the code paths use the original 5.1 constants
(`LUA_GLOBALSINDEX`, `lua_setfenv`, `luaL_register`); these are replaced with
compatible alternatives (`lua_pushglobaltable`, upvalue `_ENV`, `luaL_newlib`)
in later versions, so most code is shared.

### New binding helpers added

To reduce the amount of manual stack work required, Lumars now wraps a few
additional Lua 5.x features:

* **Integer support** – `LuaInteger` alias plus `pushInteger`, `toInteger`, and
  `isInteger` helpers.  Generic `push` and `get` functions detect integral types
  and use `lua_pushinteger`/`lua_tointeger` when appropriate.
* **Input range conversion** – any D input range (including strings) may be
  pushed as a sequential Lua table automatically.  This makes it easy to pass
  `std.range` results directly to Lua.
* **LuaState indexing** – you can now use `state["var"]` to get or set globals,
  mirroring normal array syntax.
* **Table iteration via `foreach`** – `LuaTable` implements `opApply` so you can
  write `foreach(k, v; tbl) { ... }` instead of calling `pairs` manually.
* **Garbage collector control** – call `state.gc(op, data)` with any `LUA_GC*`
  constant.
* **Coroutines** – `state.newThread()` creates a child thread; the returned
  `LuaState` can be resumed via `resume(nargs)` and yields via `yield(nresults)`.
* **Uservalues / newuserdatauv** – `setUserValue`, `getUserValue`, and
  `newUserdataUV` are available on Lua 5.2+.

These wrappers are exercised by the unit tests (see `state.d`) but still work
when building against Lua 5.1 because they are guarded behind version checks.

### Running unit tests

The test suite exercises a bunch of library helpers and therefore requires a
valid Lua binary to link against.  If `dub test --config=lua55` fails with a
linker error like `cannot open input file "deps\win64\lua55.lib"` then you
must first build or copy the Lua 5.5 library into `deps/` using one of the
methods described above.  The same applies to the dynamic configuration – the
shared object must be discoverable at runtime.

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

## Known API limitations

The following Lua features are either not wrapped or only partially supported
in the current version of Lumars.  You can still use them by pushing values and
calling the appropriate `lua_*` functions via the raw API (e.g. `lua_gc`,
`lua_integer`, `lua_newuserdatauv`, etc.).  Patches are welcome!

* integer‑specific functions (`lua_isinteger`, `lua_tointeger`, `lua_pushinteger`)
* garbage collector control and the 5.4 `lua_gc` modes
* `luaL_setmetatable`, `lua_setuservalue` / `lua_getuservalue`, `lua_resetthread`
* coroutine helpers (`lua_newthread`, `lua_resume`, `lua_yield`) – only status
  codes appear in `LuaStatus`
* library registration helpers beyond `luaL_newlib`/`luaL_register`
* additional 5.4/5.5 APIs (bitwise ops, `lua_checkversion`, `lua_len`, etc.)

Refer to the README's "Missing/Coverage" section for more details if needed.

## References

- [Lua Official Website](https://www.lua.org/)
- [DUB Build Tool](https://dub.io/)
- [bindbc-lua Documentation](https://github.com/BindBC/bindbc-lua)
