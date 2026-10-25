module CoreAP;

import std.string;
import std.conv;
import std.json;
import std.stdio;
import std.array;
import std.traits;
import std.exception;
import std.typecons;
import PublicCodeOtherCode;
import ExceptionAP;
import ExceptionJsonAP;
import CheckVariablesAP;
import std.sumtype : isSumType, get;

alias Optional = Nullable;

public struct JsonName
{
    string name;
}

public struct JsonIgnore
{
}

public alias fieldJsonNames(T, string memberName) = std.traits.getUDAs!(
        __traits(getMember, T, memberName), JsonName);

public alias fieldJsonIgnores(T, string memberName) = std.traits.getUDAs!(
        __traits(getMember, T, memberName), JsonIgnore);

public template jsonFieldName(T, string memberName)
{
    static if (fieldJsonNames!(T, memberName).length > 0)
    {
        enum jsonFieldName = fieldJsonNames!(T, memberName)[0].name;
    }
    else
    {
        enum jsonFieldName = memberName;
    }
}

public template isJsonIgnored(T, string memberName)
{
    enum isJsonIgnored = fieldJsonIgnores!(T, memberName).length > 0;
}

public template jsonFieldNames(T)
{
    enum jsonFieldNames = {
        string[] names;
        static foreach (memberName; FieldNameTuple!T)
        {
            static if (!isJsonIgnored!(T, memberName))
            {
                names ~= memberName;
            }
        }
        return names;
    }();
}

public string jsonTypeName(string qualifiedName)
{
    auto dot = qualifiedName.lastIndexOf('.');
    return dot == -1 ? qualifiedName : qualifiedName[dot + 1 .. $];
}

public class CL_CoreAP
{
    public static bool isValidJson(string jsonContent)
    {
        try
        {
            if (jsonContent.empty)
            {
                return false;
            }
            parseJSON(jsonContent);
            return true;
        }
        catch (JSONException e)
        {
           return false;
        }
        catch (Exception e)
        {
            throw new UnknownErrorexceptionAP("An unexpected error occurred during JSON parsing.",
                    __FILE__, __LINE__, e);
        }
    }

    public static Optional!long getJsonItemCount(string jsonContent)
    {
        try
        {
            if (jsonContent.empty)
            {
                return Optional!long.init;
            }
            JSONValue parsedJson = parseJSON(jsonContent);
            if (parsedJson.type == JSONType.OBJECT)
            {
                return Optional!long(cast(long) parsedJson.object.length);
            }
            else if (parsedJson.type == JSONType.ARRAY)
            {
                return Optional!long(cast(long) parsedJson.array.length);
            }
            else
            {
                return Optional!long(1L);
            }
        }
        catch (JSONException e)
        {
            return Optional!long.init;
        }
        catch (Exception e)
        {
            return Optional!long.init;
        }
    }

    public static bool isJsonNumber(string jsonContent)
    {
        try
        {
            if (jsonContent.empty)
            {
                return false;
            }
            JSONValue val = parseJSON(jsonContent);
            return val.type == JSONType.INTEGER || val.type == JSONType.FLOAT;
        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("Error checking if JSON is a number.",
                    "$", jsonContent, __FILE__, __LINE__, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorexceptionAP("An unexpected error occurred while checking JSON number type.",
                    __FILE__, __LINE__, e);
        }
    }

    public static bool isJsonString(string jsonContent)
    {
        try
        {
            if (jsonContent.empty)
            {
                return false;
            }
            JSONValue val = parseJSON(jsonContent);
            return val.type == JSONType.STRING;
        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("Error checking if JSON is a string.",
                    "$", jsonContent, __FILE__, __LINE__, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorexceptionAP("An unexpected error occurred while checking JSON string type.",
                    __FILE__, __LINE__, e);
        }
    }

    public static Optional!string prettyPrintJson(string jsonContent)
    {
        try
        {
            if (jsonContent.empty)
            {
                return Optional!string.init;
            }

            JSONValue val = parseJSON(jsonContent);
            return Optional!string(val.toPrettyString());
        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("Failed to pretty print JSON content.",
                    "$", jsonContent, __FILE__, __LINE__, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorexceptionAP("An unexpected error occurred during JSON pretty printing.",
                    __FILE__, __LINE__, e);
        }
    }

    public static bool isJsonObject(string jsonContent)
    {
        try
        {
            if (jsonContent.empty)
            {
                return false;
            }
            auto val = parseJSON(jsonContent);
            return val.type == JSONType.OBJECT;
        }
        catch (JSONException e)
        {
            return false;
        }
        catch (Exception e)
        {
            return false;
        }

    }

    public static bool isJsonArray(string jsonContent)
    {
        try
        {
            if (jsonContent.empty)
            {
                return false;
            }
            auto val = parseJSON(jsonContent);
            return val.type == JSONType.ARRAY;
        }
        catch (JSONException e)
        {
            return false;
        }
        catch (Exception e)
        {
            return false;
        }
    }

    public static JSONType getJsonValueType(JSONValue jsonValue)
    {

        return jsonValue.type;
    }

    /**
     * Lists the printable members of an enum, used in error messages so the caller
     * can see which values the target enum accepts.
     */
    public static string enumMemberNames(T)()
    {
        string names;
        foreach (enumMember; EnumMembers!T)
        {
            if (!names.empty)
            {
                names ~= ", ";
            }
            names ~= enumMember.to!string();
        }
        return names;
    }
}
