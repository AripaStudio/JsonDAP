module CoreAPConv;

import std.string;
import std.conv;
import std.json;
import std.traits;
import std.typecons;
import std.exception;
import std.sumtype : isSumType, get;
import PublicCodeOtherCode;
import ExceptionAP;
import ExceptionJsonAP;
import CheckVariablesAP;
import CoreAPSerialize;
import CoreAP;
import CoreAPConvObject;

alias Optional = Nullable;

public static class CL_CoreAP_Conv
{
    public static Optional!T convertJsonValueToT(T)(JSONValue jsonValue, bool lenient = false)
    {
        static assert(!is(T == JSONValue),
                "Converting JSONValue to JSONValue is redundant. Please ensure T is not JSONValue.");
        try
        {
            return convertByTargetType!T(jsonValue, lenient);
        }
        catch (BaseExceptionAP e)
        {
            throw e;
        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("Error during JSON conversion.",
                    null, jsonValue.to!string, __FILE__, __LINE__, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorExceptionAP("An unexpected error occurred during JSON to object conversion.",
                    __FILE__, __LINE__, e);
        }
    }

    private static Optional!T convertByTargetType(T)(JSONValue jsonValue, bool lenient)
    {
        auto jsonValueType = CL_CoreAP.getJsonValueType(jsonValue);

        static if (isPrimitiveTarget!T)
        {
            return convertPrimitive!T(jsonValue, jsonValueType);
        }
        else static if (CheckVariablesAP.IsArrayAP!T.value)
        {
            return convertArray!T(jsonValue, jsonValueType, lenient);
        }
        else static if (is(T : Optional!U, U))
        {
            return convertNullable!T(jsonValue, jsonValueType, lenient);
        }
        else static if (isSumType!T)
        {
            return CL_CoreAP_Serialize.deserializeSumType!T(jsonValue, lenient);
        }
        else static if (CheckVariablesAP.IsStructAP!T.value
                || CheckVariablesAP.IsClassAP!T.value)
        {
            return CL_CoreAP_Conv_Object.convertAggregate!T(jsonValue, jsonValueType, lenient);
        }
        else static if (CheckVariablesAP.IsEnumAP!T.value)
        {
            return convertEnum!T(jsonValue, jsonValueType);
        }
        else
        {
            static assert(0, "Unsupported type " ~ T.stringof ~ " for JSON conversion.");
        }
    }

    private template isPrimitiveTarget(T)
    {
        enum bool isPrimitiveTarget = CheckVariablesAP.IsNumberAP!T.value
                || CheckVariablesAP.IsBoolAP!T.value
                || CheckVariablesAP.IsStringAP!T.value;
    }

    private static Optional!T convertPrimitive(T)(JSONValue jsonValue, JSONType jsonValueType)
    {
        switch (jsonValueType)
        {
        case JSONType.INTEGER:
            return Optional!T(jsonValue.integer.to!T());

        case JSONType.FLOAT:
            return Optional!T(jsonValue.floating.to!T());

        case JSONType.STRING:
            static if (is(T == string))
            {
                return Optional!T(jsonValue.str);
            }
            else
            {
                throw new JSONConvertExceptionAP("Cannot convert JSON string to target type.",
                        T.stringof, jsonValue.str,
                        JSONType.STRING.to!string,
                        T.stringof, "TypeMismatch", null,
                        "Cannot convert string to " ~ T.stringof, __FILE__, __LINE__);
            }

        case JSONType.TRUE:
        case JSONType.FALSE:
            static if (is(T == bool))
            {
                return Optional!T(jsonValue.boolean);
            }
            else
            {
                throw new JSONConvertExceptionAP("Cannot convert JSON boolean to target type.",
                        T.stringof, jsonValue.boolean.to!string,
                        jsonValueType.to!string, T.stringof, "TypeMismatch", null,
                        "Cannot convert boolean to " ~ T.stringof, __FILE__, __LINE__);
            }

        case JSONType.NULL:
            return Optional!T.init;

        default:
            throw new JSONConvertExceptionAP("Unsupported JSON type for primitive conversion.",
                    T.stringof, jsonValue.to!string,
                    jsonValueType.to!string,
                    T.stringof, "UnsupportedType", null,
                    "Cannot convert " ~ jsonValueType.to!string ~ " to " ~ T.stringof,
                    __FILE__, __LINE__);
        }
    }

    private static Optional!T convertArray(T)(JSONValue jsonValue, JSONType jsonValueType,
            bool lenient)
    {
        alias ElementType = typeof(T.init[0]);

        if (jsonValueType == JSONType.NULL)
        {
            return Optional!T.init;
        }

        if (jsonValueType != JSONType.ARRAY)
        {
            throw new JSONConvertExceptionAP("Expected array JSON type for target type.",
                    T.stringof, jsonValue.type.to!string,
                    jsonValue.type.to!string,
                    T.stringof, "TypeMismatch", null,
                    "JSON is not an array for array conversion.", __FILE__, __LINE__);
        }

        T result;
        foreach (itemJson; jsonValue.array)
        {
            auto convertedItem = convertJsonValueToT!ElementType(itemJson, lenient);
            if (!convertedItem.isNull)
            {
                result ~= convertedItem.get;
                continue;
            }

            static if (!is(ElementType : Optional!U, U))
            {
                throw new JSONConvertExceptionAP("Failed to convert array element.",
                        ElementType.stringof, itemJson.to!string,
                        itemJson.type.to!string, ElementType.stringof,
                        "ElementConversionFailed",
                        null, "Could not convert JSON array element to " ~ ElementType.stringof,
                        __FILE__, __LINE__);
            }
        }
        return Optional!T(result);
    }

    private static Optional!T convertNullable(T)(JSONValue jsonValue, JSONType jsonValueType,
            bool lenient)
    {
        if (jsonValueType == JSONType.NULL)
        {
            return Optional!T.init;
        }

        static if (is(T : Optional!U, U))
        {
            auto convertedInner = convertJsonValueToT!U(jsonValue, lenient);
            if (convertedInner.isNull)
            {
                return Optional!T.init;
            }

            // T is itself Optional!U here, so the converted inner Optional is the
            // payload; wrapping .get would demand a U -> T conversion that does
            // not exist for nested Nullable fields.
            return Optional!T(convertedInner);
        }
        else
        {
            static assert(0, "convertNullable requires a Nullable target, got " ~ T.stringof ~ ".");
        }
    }

    private static Optional!T convertEnum(T)(JSONValue jsonValue, JSONType jsonValueType)
    {
        if (jsonValueType == JSONType.NULL)
        {
            return Optional!T.init;
        }

        if (jsonValueType == JSONType.STRING)
        {
            return convertEnumFromString!T(jsonValue.str);
        }

        if (jsonValueType == JSONType.INTEGER)
        {
            return convertEnumFromInteger!T(jsonValue.integer);
        }

        throw new JSONConvertExceptionAP("Unsupported JSON type for enum conversion.",
                T.stringof, jsonValue.to!string,
                jsonValueType.to!string,
                T.stringof, "UnsupportedType", null,
                "Cannot convert " ~ jsonValueType.to!string ~ " to enum " ~ T.stringof ~ ".",
                __FILE__, __LINE__);
    }

    private static Optional!T convertEnumFromString(T)(string value)
    {
        foreach (enumMember; EnumMembers!T)
        {
            if (value == enumMember.to!string())
            {
                return Optional!T(enumMember);
            }
        }

        throw new JSONConvertExceptionAP("String value is not a valid enum member.",
                T.stringof, value, JSONType.STRING.to!string,
                T.stringof, "EnumValueMismatch", null,
                "String is not a valid enum for " ~ T.stringof ~ ". Valid members: "
                ~ CL_CoreAP.enumMemberNames!T() ~ ".",
                __FILE__, __LINE__);
    }

    private static Optional!T convertEnumFromInteger(T)(long value)
    {
        static if (is(T : int))
        {
            foreach (enumMember; EnumMembers!T)
            {
                if (cast(long) enumMember == value)
                {
                    return Optional!T(enumMember);
                }
            }

            throw new JSONConvertExceptionAP("Integer value is not a valid enum member.",
                    T.stringof, value.to!string, JSONType.INTEGER.to!string,
                    T.stringof, "EnumValueMismatch", null,
                    "Integer is not a valid enum for " ~ T.stringof ~ ". Valid members: "
                    ~ CL_CoreAP.enumMemberNames!T() ~ ".",
                    __FILE__, __LINE__);
        }
        else
        {
            throw new JSONConvertExceptionAP("Expected string value for enum, but got integer.",
                    T.stringof, value.to!string,
                    JSONType.INTEGER.to!string,
                    T.stringof, "TypeMismatch", null,
                    "Cannot convert integer to string-based enum.", __FILE__, __LINE__);
        }
    }
}
