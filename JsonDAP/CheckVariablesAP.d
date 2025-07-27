module CheckVariablesAP;

import std.traits;

public struct IsIntAP(T){
	enum bool value = is(T == int) || is(T == long) || is(T == byte) || is(T == ulong) ||
		is(T == uint) || is(T == short) || is(T == ushort) || is(T == ubyte);
}

public struct IsFloatAP(T){
	enum bool value = is(T == float) || is(T == double) || is(T == real);
}

public struct IsBoolAP(T){
	enum bool value = is(T == bool);
}

public struct IsStringAP(T){
	enum bool value = is(T == string) || is(T == wstring) || is(T == dstring);
}

public struct IsArrayAP(T){
enum bool value = __traits(isArray , T) || __traits(isDynamicArray, T) || __traits(isStaticArray, T);
}

public struct IsClassAP(T){
	enum bool value = is(T : Object) && !is(T == typeof(null));
}

public struct IsEnumAP(T){	 	
	enum bool value = std.traits.isEnum!T;
}

public struct IsStructAP(T){
	enum bool value = !IsClassAP!T.value &&
		!IsIntAP!T.value &&
		!IsFloatAP!T.value &&
		!IsBoolAP!T.value &&
		!IsStringAP!T.value &&
		!IsArrayAP!T.value &&
		!IsEnumAP!T.value &&
		!is(T == void) && 
		!is(T == typeof(null)) &&
		!__traits(isPointer , T) &&
		!__traits(isFunction , T) &&
		!__traits(isDelegate , T );		
}

public struct IsNumberAP(T){
	enum bool value = IsIntAP!T.value || IsFloatAP!T.value;
}



