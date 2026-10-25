module CoreAPConvObject;

import std.conv;
import std.json;
import std.traits;
import std.typecons;
import CheckVariablesAP;
import ExceptionJsonAP;
import CoreAP;
import CoreAPConv;

alias Optional = Nullable;

public static class CL_CoreAP_Conv_Object
{
    public static Optional!T convertAggregate(T)(JSONValue jsonValue, JSONType jsonValueType,
            bool lenient)
    {
        if (jsonValueType == JSONType.NULL)
        {
            return Optional!T.init;
        }

        if (jsonValueType != JSONType.OBJECT)
        {
            throw new JSONConvertExceptionAP("Expected object JSON type for target type.",
                    T.stringof, jsonValue.type.to!string, jsonValue.type.to!string,
                    T.stringof, "TypeMismatch", null,
                    "JSON is not an object for struct/class conversion.",
                    __FILE__, __LINE__);
        }

        T obj = T.init;
        static if (CheckVariablesAP.IsClassAP!T.value)
        {
            // A class reference starts as null, so it must be allocated before field assignment.
            obj = new T;
        }

        static foreach (memberName; jsonFieldNames!T)
        {{
            alias FieldType = typeof(__traits(getMember, T, memberName));
            auto wireName = jsonFieldName!(T, memberName);

            if (wireName in jsonValue.object)
            {
                auto memberJsonValue = jsonValue.object[wireName];
                auto convertedMember = CL_CoreAP_Conv.convertJsonValueToT!FieldType(
                        memberJsonValue, lenient);
                if (!convertedMember.isNull)
                {
                    mixin("obj." ~ memberName ~ " = convertedMember.get;");
                }
                else
                {
                    requireAssignableField!(FieldType, memberName)(memberJsonValue);
                }
            }
            else
            {
                requirePresentField!(FieldType, memberName)(lenient);
            }
        }}

        return Optional!T(obj);
    }

    private static void requireAssignableField(FieldType, string memberName)(JSONValue memberJsonValue)
    {
        static if (!is(FieldType : Optional!U, U))
        {
            // A JSON null maps to a null class/interface reference, so the field
            // keeps its null default; every other failed conversion is reported.
            enum nullFriendlyField = is(FieldType == class) || is(FieldType == interface);
            if (nullFriendlyField && memberJsonValue.type == JSONType.NULL)
            {
                return;
            }

            throw new JSONConvertExceptionAP("Failed to convert field '" ~ memberName ~ "'.",
                    memberName, memberJsonValue.to!string,
                    memberJsonValue.type.to!string,
                    FieldType.stringof,
                    "FieldConversionFailed", null,
                    "Could not convert JSON field to " ~ FieldType.stringof,
                    __FILE__, __LINE__);
        }
    }

    private static void requirePresentField(FieldType, string memberName)(bool lenient)
    {
        static if (!is(FieldType : Optional!U, U))
        {
            if (lenient)
            {
                return;
            }

            throw new JSONConvertExceptionAP(
                    "Required field '" ~ memberName ~ "' not found in JSON object.",
                    memberName, "Not Found", "N/A",
                    FieldType.stringof, "MissingField", null,
                    "Mandatory field missing for object conversion.",
                    __FILE__, __LINE__);
        }
    }
}
