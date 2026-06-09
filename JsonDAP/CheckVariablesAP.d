module CheckVariablesAP;

import std.traits;


public struct IsIntAP(T)
{
    enum bool value = is(T == int) || is(T == long) || is(T == byte)
        || is(T == ulong) || is(T == uint) || is(T == short) || is(T == ushort) || is(T == ubyte);
}

public struct IsFloatAP(T)
{
    enum bool value = is(T == float) || is(T == double) || is(T == real);
}

public struct IsBoolAP(T)
{
    enum bool value = is(T == bool);
}

public struct IsStringAP(T)
{
    enum bool value = is(T == string) || is(T == wstring) || is(T == dstring);
}

public struct IsArrayAP(T)
{
    enum bool value = std.traits.isArray!T || std.traits.isDynamicArray!T
        || std.traits.isStaticArray!T;
}

public struct IsClassAP(T)
{
    enum bool value = is(T == class);
}

public struct IsEnumAP(T)
{
    enum bool value = is(T == enum);
}

public struct IsStructAP(T)
{
    enum bool value = is(T == struct);
}

public struct IsNumberAP(T)
{
    enum bool value = IsIntAP!T.value || IsFloatAP!T.value;
}
