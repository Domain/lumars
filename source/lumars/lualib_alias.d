module lumars.lualib_alias;

// Compatibility layer for Lua versions
// Lua 5.1: luaL_openlibs is a real function in bindbc-lua, use it directly
// Lua 5.4+: luaL_openlibs is a macro calling luaL_openselectedlibs; we provide wrapper

import bindbc.lua;

version (LUA_55)
{
    // Lua 5.5: luaL_openlibs is a macro, call the real function luaL_openselectedlibs
    extern(C) @trusted nothrow void luaL_openselectedlibs(lua_State* L, int load, int preload);
}
else version (LUA_54)
{
    // Lua 5.4: same as 5.5
    extern(C) @trusted nothrow void luaL_openselectedlibs(lua_State* L, int load, int preload);
}
