module CoreAP;


import std.string;
import std.conv;
import std.json;
import std.stdio;
import std.array;
import std.typecons;
import PublicCodeOtherCode;


alias Optional = Nullable;


public class CL_CoreAP
{
	public static bool isValidJson(string jsonContent)
	{
		try
		{
			parseJSON(jsonContent);
			return true;
		}catch(JSONException e)
		{			
			throw new JsonOperationException("Failed to parse JSON: " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationException("An unexpected error occurred during JSON parsing: " ~ e.msg, __FILE__, __LINE__, e);			
		}
	}

	public static Optional!long getJsonItemCount(string jsonContent)
	{
		try
		{
			JSONValue parsedJson = parseJSON(jsonContent);
			if(parsedJson.type == JSONType.OBJECT)
			{
				return Optional!long(cast(long)parsedJson.object.length);
			}else if (parsedJson.type == JSONType.ARRAY)
			{
				return Optional!long(cast(long)parsedJson.array.length);
			}else
			{
				return Optional!long(1L);
			}
		}catch(JSONException e)
		{
			return Optional!long.init;
		}catch(Exception e)
		{
			return Optional!long.init;
		}
	}

	public static bool isJsonNumber(string jsonContent)
	{
		try
		{
			JSONValue val = parseJSON(jsonContent);
			return val.type == JSONType.INTEGER || val.type == JSONType.FLOAT;
		}catch(JSONException e)
		{
			throw new JsonOperationException("Error Message(JSONException) :" ~ e.msg, __FILE__, __LINE__, e);						
		}catch(Exception e)
		{
			throw new JsonOperationException("Error Message(Exception) :" ~ e.msg, __FILE__, __LINE__, e);						
		}
	}


	public static bool isJsonString(string jsonContent)
	{
		try {
            JSONValue val = parseJSON(jsonContent);
            return val.type == JSONType.STRING;
        } catch (JSONException e) {
			throw new JsonOperationException("Error Message(JSONException) :" ~ e.msg, __FILE__, __LINE__, e);			            
        } catch (Exception e) {
			throw new JsonOperationException("Error Message(Exception) :" ~ e.msg, __FILE__, __LINE__, e);		            
        }
	}

	public static Optional!string prettyPrintJson(string jsonContent)
	{
		try{

			JSONValue val = parseJSON(jsonContent);
			return Optional!string(val.toPrettyString());
		}catch (JSONException e) {
			throw new JsonOperationException("Error Message(JSONException) :" ~ e.msg, __FILE__, __LINE__, e);			            
        } catch (Exception e) {
			throw new JsonOperationException("Error Message(Exception) :" ~ e.msg, __FILE__, __LINE__, e);		            
        }
	}

	public static Optional!V getJsonValue(string jsonContent , string path)(){

		try{

			JSONValue root = parseJSON(jsonContent);
			JSONValue current = root;

			foreach(segment; path.split('.'))
			{
				if(current.type == JSON_TYPE.OBJECT)
				{
					if(segment in current.object)
					{
						current = current.object[segment];
					}else
					{
						return Optional!V.init;
					}
				}else if(current.type == JSON_TYPE.ARRAY && CL_PublicCodeOtherCode.isInteger(segment))
				{
					int index = segment.to!int;
					if(index >= 0 && index < current.array.length)
					{
						current = current.array[index];

					}else
					{
						return Optional!V.init;
					}
				}else
				{
					return Optional!V.init;
				}
			}


			mixin(q{
				static if (is(V == string)) return Optional!V(current.str);
                else static if (is(V == long) || is(V == int)) return Optional!V(current.integer.to!V());
                else static if (is(V == double) || is(V == float)) return Optional!V(current.floating.to!V());
                else static if (is(V == bool)) return Optional!V(current.boolean);                
                else return Optional!V.init; 
			});

		}catch (JSONException e) {            
			throw new JsonOperationException("Error parsing JSON :" ~ e.msg, __FILE__, __LINE__, e);						            
        } catch (Exception e) {            
            throw new JsonOperationException("General error :" ~ e.msg, __FILE__, __LINE__, e);						            
        }

	}

	public static bool isJsonObject(string jsonContent)
	{
		try{
			auto val = parseJSON(jsonContent);
			return val.type == JSONType.OBJECT;
		} catch (JSONException e)
		{
			return false; 
		}catch (Exception e)
		{
			return false; 
		}

	}


	public static bool isJsonArray(string jsonContent)
	{
		try{
			auto val = parseJSON(jsonContent);
			return val.type == JSONType.ARRAY;
		} catch (JSONException e)
		{
			return false; 
		}catch (Exception e)
		{
			return false; 
		}
	}





}
