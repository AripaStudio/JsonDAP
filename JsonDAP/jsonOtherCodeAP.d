module jsonOtherCodeAP;

import ExceptionAP;
import ExceptionJsonAP;
import std.stdio;
import std.string;
import std.algorithm;
import std.range;
import std.array;
import PublicCodeOtherCode;
import std.conv;
import std.exception;
import std.json;
import CheckVariablesAP;

public static enum PathStepType
{
    ObjectKey,
    ArrayIndex
}

public static struct PathStep
{
    PathStepType type;
    union
    {
        string key;
        int index;
    }
}

public class CL_JsonOtherCode
{

    public static PathStep[] JsonPathParserAP(string input)
    {
        return CL_PublicCodeOtherCode.parsePath(input);
    }

    public static bool recursiveMerge(ref JSONValue target, ref JSONValue source,
            bool overwrite, bool mergeArrays, out string message)
    {
        if (source == JSONValue.init)
        {
            return false;
        }
        if (target == JSONValue.init)
        {
            if (overwrite)
            {
                message = "Target is uninitialized, overwriting with source.";
                target = source;
                return true;
            }
            else
            {
                return false;
            }
        }

        if (source.type == JSONType.TRUE || source.type == JSONType.FALSE
                || source.type == JSONType.INTEGER
                || source.type == JSONType.STRING || source.type == JSONType.NULL)
        {
            if (overwrite)
            {
                message = "Source is a primitive type, overwriting target.";
                target = source;
                return true;
            }
            else
            {
                return false;
            }
        }

        if (source.type == JSONType.OBJECT && target.type == JSONType.OBJECT)
        {
            foreach (key, value; source.object)
            {
                if (key in target.object)
                {
                    string msg;
                    recursiveMerge(target.object[key], value, overwrite, mergeArrays, msg);
                }
                else
                {
                    target.object[key] = value;
                }
            }
            return true;
        }
        else if (source.type == JSONType.ARRAY && target.type == JSONType.ARRAY)
        {
            if (mergeArrays)
            {
                size_t newSize = target.array.length + source.array.length;
                target.array.reserve(newSize);
                target.array ~= source.array;
                return true;
            }
            else
            {
                message = "Target and source are arrays, but array merging is disabled. Overwriting target.";
                target = source;
                return true;
            }
        }
        else if (target.type == JSONType.ARRAY && source.type != JSONType.ARRAY)
        {
            if (overwrite)
            {
                message = "Target is an array, source is not. Overwriting target with source.";
                target = source;
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            if (overwrite)
            {
                message = "Target and source types are incompatible. Overwriting target with source.";
                target = source;
                return true;
            }
            else
            {
                return false;
            }
        }
    }

    public static JSONValue deepCopy(JSONValue v)
    {
        try
        {
            return parseJSON(v.toString());
        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("deep copy failed.", "$", "", __FILE__, __LINE__, e);
        }
    }
}
