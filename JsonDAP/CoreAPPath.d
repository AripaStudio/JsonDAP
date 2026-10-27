module CoreAPPath;

import std.string;
import std.conv;
import std.json;
import std.traits;
import std.typecons;
import std.exception;
import PublicCodeOtherCode;
import ExceptionAP;
import ExceptionJsonAP;
import CheckVariablesAP;
import CoreAP;
import jsonOtherCodeAP;

alias Optional = Nullable;

public static class CL_CoreAP_Path
{
    public static Optional!V getJsonValue(V)(string jsonContent, string path)
    {

        try
        {
            if (jsonContent.empty || path.empty)
            {
                return Optional!V.init;
            }

            JSONValue root = parseJSON(jsonContent);
            auto steps = CL_PublicCodeOtherCode.parsePath(path);
            JSONValue current = root;

            foreach (step; steps)
            {
                if (step.type == PathStepType.ObjectKey)
                {
                    if (current.type != JSONType.OBJECT || step.key !in current.object)
                    {
                        throw new JSONExceptionAP("JSON path invalid: key '" ~ step.key ~ "' not found.",
                                path, jsonContent, __FILE__, __LINE__);
                    }
                    current = current.object[step.key];
                }
                else
                {
                    if (current.type != JSONType.ARRAY)
                    {
                        throw new JSONExceptionAP("JSON path invalid: index used on a non-array.",
                                path, jsonContent, __FILE__, __LINE__);
                    }
                    if (step.index < 0 || step.index >= current.array.length)
                    {
                        throw new InvalidArgumentExceptionAP("JSON array index out of bounds.", "index",
                                step.index.to!string, indexHint(current.array.length),
                                __FILE__, __LINE__);
                    }
                    current = current.array[step.index];
                }
            }

            mixin(q{
                static if (is(V == string))
                {
                    if (current.type != JSONType.STRING)
                    {
                        throw new ConvertExceptionAP("JSON value is not a string.",
                                "path", path, current.type.to!string, "string", "getJsonValue",
                                "Requested type does not match the JSON value type.", __FILE__, __LINE__);
                    }
                    return Optional!V(current.str);
                }
                else static if (is(V == long) || is(V == int))
                {
                    if (current.type != JSONType.INTEGER)
                    {
                        throw new ConvertExceptionAP("JSON value is not an integer.",
                                "path", path, current.type.to!string, V.stringof, "getJsonValue",
                                "Requested type does not match the JSON value type.", __FILE__, __LINE__);
                    }
                    return Optional!V(current.integer.to!V());
                }
                else static if (is(V == double) || is(V == float))
                {
                    if (current.type != JSONType.FLOAT && current.type != JSONType.INTEGER)
                    {
                        throw new ConvertExceptionAP("JSON value is not a number.",
                                "path", path, current.type.to!string, V.stringof, "getJsonValue",
                                "Requested type does not match the JSON value type.", __FILE__, __LINE__);
                    }
                    if (current.type == JSONType.FLOAT)
                    {
                        return Optional!V(current.floating.to!V());
                    }
                    return Optional!V(current.integer.to!V());
                }
                else static if (is(V == bool))
                {
                    if (current.type != JSONType.TRUE && current.type != JSONType.FALSE)
                    {
                        throw new ConvertExceptionAP("JSON value is not a boolean.",
                                "path", path, current.type.to!string, "bool", "getJsonValue",
                                "Requested type does not match the JSON value type.", __FILE__, __LINE__);
                    }
                    return Optional!V(current.boolean);
                }
                else  throw new ConvertExceptionAP("JSON type conversion not supported.", "current.type", to!string(current.type), to!string(current.type), to!string(V.stringof), "getJsonValue", "Requested type is not supported.", __FILE__, __LINE__);
            });

        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("Error parsing JSON while getting value.",
                    "$", jsonContent, __FILE__, __LINE__, e);
        }
        catch (BaseExceptionAP e)
        {
            throw e;
        }
        catch (Exception e)
        {
            throw new UnknownErrorExceptionAP("A general error occurred while getting JSON value.",
                    __FILE__, __LINE__, e);
        }

    }

    private static string indexHint(size_t length)
    {
        return length == 0 ? "the array is empty" : "0-" ~ (length - 1).to!string;
    }
}
