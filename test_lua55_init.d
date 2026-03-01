module test_lua55_init;

import lumars;

void main()
{
    auto state = LuaState(null);
    state.push(123);
    auto val = state.get!int(-1);
    assert(val == 123);
    import std.stdio : writeln;
    writeln("Lua 5.5 initialization successful!");
}
