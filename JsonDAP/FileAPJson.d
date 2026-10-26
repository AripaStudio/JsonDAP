module FileAPJson;

import std.file;
import std.string;
import std.json;
import std.typecons;
import std.traits;
import std.conv;
import std.exception;
import CoreAP;
import PublicCodeOtherCode;
import ExceptionAP;
import ExceptionJsonAP;
import CoreAPConv;
import CoreAPSerialize;

alias Optional = Nullable;

public class CL_File_JSON
{
    public static Optional!(T[]) deserializeJsonArray(T)(string jsonContent)
	{
		try
		{
			JSONValue val = parseJSON(jsonContent);
			if (val.type == JSONType.ARRAY)
			{
				T[] arr;
				foreach (item; val.array)
				{
					auto convertedItemOptional = CL_CoreAP_Conv.convertJsonValueToT!T(item);

					if (!convertedItemOptional.isNull)
					{
						arr ~= convertedItemOptional.get;
					}
					else
					{
						throw new JSONConvertExceptionAP("Failed to convert array element from JSON.",
														 T.stringof, item.to!string, item.type.to!string,
														 T.stringof, "ElementConversionFailed",
														 "ArrayConversion",
														 "Could not convert JSON array element to " ~ T.stringof,
														 __FILE__, __LINE__); 
					}
				}
				return Optional!(T[])(arr);
			}
			else
			{
				throw new JSONConvertExceptionAP("Expected a JSON array, but got an unexpected type.",
												 T.stringof, val.to!string,
												 val.type.to!string, T.stringof, "TypeMismatch",
												 "ArrayConversion",
												 "JSON content is not an array.", 
												 __FILE__, __LINE__); 
			}
		}		catch (BaseExceptionAP e)
		{
			throw e;
		}
		catch (JSONException e)
		{
			throw new JsonOperationExceptionAP("Failed to deserialize JSON array.",
					null, jsonContent, null, 0, e);
		}
		catch (Exception e)
		{
			throw new UnknownErrorExceptionAP(
											  "An unexpected error occurred during JSON array element conversion.",
											  null, 0, e);
		}
		return Optional!(T[]).init;
	}

	public static Optional!(T) deserializeJson(T)(string jsonContent, bool lenient = false)
	{
		try
		{
			JSONValue val = parseJSON(jsonContent);
			if (val.type == JSONType.OBJECT)
			{
				T obj;
				auto convertedItemOptional = CL_CoreAP_Conv.convertJsonValueToT!T(val, lenient);
				if (!convertedItemOptional.isNull)
				{
					obj = convertedItemOptional.get;
				}
				else
				{
					throw new JSONConvertExceptionAP("Failed to convert element from JSON.", 
													 T.stringof, val.to!string,
													 val.type.to!string, T.stringof, "ObjectConversionFailed", 
													 "ObjectConversion", 
													 "Could not convert JSON object to  |__|  Error in convertJsonValueToT!T(val)", 
													 __FILE__, __LINE__); 
				}
				return Optional!(T)(obj);
			}
			else
			{
				throw new JSONConvertExceptionAP("Failed to convert element from JSON.",
												 T.stringof, val.to!string, val.type.to!string,
												 T.stringof, "ObjectConversionFailed",
												 "ObjectConversion",
												 "Could not convert JSON object to " ~ T.stringof, 
												 __FILE__, __LINE__); 
			}
		}		catch (BaseExceptionAP e)
		{
			throw e;
		}
		catch (JSONException e)
		{
			throw new JsonOperationExceptionAP("Failed to deserialize JSON.",
					null, jsonContent, null, 0, e);
		}
		catch (Exception e)
		{
			throw new UnknownErrorExceptionAP(
											  "An unexpected error occurred during JSON element conversion.", null, 0, e);
		}
		return Optional!(T).init;
	}

    public static JSONValue serializeToJson(T)(T obj)
    {
        try
        {

            static if (is(T == JSONValue))
            {
                return obj;
            }
            else
            {
                auto jsonVal = CL_CoreAP_Serialize.serializeTToJsonValue!T(obj);
                return jsonVal;
            }
        }
        catch (BaseExceptionAP e)
        {
            throw e;
        }
        catch (Exception e)
        {
            
            throw new JsonOperationExceptionAP("Failed to serialize object to JSON string.",
                    null, T.stringof,  null, 0, e);
        }
    }

    public static JSONValue[] serializeToJsonArray(T)(T data)
    {
        try
        {
            static if (is(T == JSONValue[]))
            {
                return data;
            }
            else static if (is(T == JSONValue))
            {
                JSONValue[] output = [data];
                return output;

            }
            else
            {
                JSONValue jsonVal = CL_CoreAP_Serialize.serializeTToJsonValue!T(data);
                return [jsonVal];
            }
        }
        catch (BaseExceptionAP e)
        {
            throw e;
        }
        catch (Exception e)
        {
            throw new JsonOperationExceptionAP("Failed to serialize object to JSON array string.",
                    null, T.stringof, null, 0, e);
        }
    }

}