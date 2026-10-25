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
            JSONValue current = root;

            foreach (segment; path.split('.'))
            {
                if (current.type == JSONType.OBJECT)
                {
                    if (segment in current.object)
                    {
                        current = current.object[segment];
                    }
                    else
                    {
                        throw new JSONExceptionAP("JSON path invalid: segment '" ~ segment ~ "' not found.",
                                path, jsonContent, __FILE__, __LINE__);
                    }
                }
                else if (current.type == JSONType.ARRAY
                        && CL_PublicCodeOtherCode.isInteger(segment))
                {
                    int index = segment.to!int;
                    if (index >= 0 && index < current.array.length)
                    {
                        current = current.array[index];

                    }
                    else
                    {
                        throw new InvalidArgumentExceptionAP("JSON array index out of bounds.", "index", segment,
                                "0-" ~ to!string(current.array.length - 1), __FILE__, __LINE__);
                    }
                }
                else
                {
                    throw new JSONExceptionAP("JSON type unsuitable for path traversal.",
                            path, jsonContent, __FILE__, __LINE__);
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
                    if (current.type != JSONType.INTEGER && current.type != JSONType.FLOAT)
                    {
                        throw new ConvertExceptionAP("JSON value is not a number.",
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
                    return Optional!V(current.floating.to!V());
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
        catch (Exception e)
        {
            throw new UnknownErrorexceptionAP("A general error occurred while getting JSON value.",
                    __FILE__, __LINE__, e);
        }

    }
}
