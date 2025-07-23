module CoreAP;



import std.string;
import std.conv;
import std.json;
import std.stdio;
import std.array;
import std.string;
import std.traits;
import std.exception;
import std.typecons;
import PublicCodeOtherCode;
import ExceptionAP;


alias Optional = Nullable;


public class CL_CoreAP
{
	public static bool isValidJson(string jsonContent)
	{
		try
		{
			if(jsonContent.empty)
			{
				return false;
			}
			parseJSON(jsonContent);
			return true;
		}catch(JSONException e)
		{			
			throw new JsonOperationExceptionAP("Failed to parse JSON: " ~ e.msg, "jsonContent : " ~ jsonContent , __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationExceptionAP("An unexpected error occurred during JSON parsing: " ~ e.msg, __FILE__, __LINE__, e);			
		}
	}

	public static Optional!long getJsonItemCount(string jsonContent)
	{
		try
		{
			if(jsonContent.empty)
			{
				return Optional!long.init;
			}
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
			if(jsonContent.empty)
			{
				return false;
			}
			JSONValue val = parseJSON(jsonContent);
			return val.type == JSONType.INTEGER || val.type == JSONType.FLOAT;
		}catch(JSONException e)
		{
			throw new JsonOperationExceptionAP("Error Message(JSONException) :" ~ e.msg, __FILE__, __LINE__, e);						
		}catch(Exception e)
		{
			throw new JsonOperationExceptionAP("Error Message(Exception) :" ~ e.msg, __FILE__, __LINE__, e);						
		}
	}


	public static bool isJsonString(string jsonContent)
	{
		try {
			if(jsonContent.empty)
			{
				return false;
			}
            JSONValue val = parseJSON(jsonContent);
            return val.type == JSONType.STRING;
        } catch (JSONException e) {
			throw new JsonOperationExceptionAP("Error Message(JSONException) :" ~ e.msg, __FILE__, __LINE__, e);			            
        } catch (Exception e) {
			throw new JsonOperationExceptionAP("Error Message(Exception) :" ~ e.msg, __FILE__, __LINE__, e);		            
        }
	}

	public static Optional!string prettyPrintJson(string jsonContent)
	{
		try{
			if(jsonContent.empty)
			{
				return Optional!string.init;
			}

			JSONValue val = parseJSON(jsonContent);
			return Optional!string(val.toPrettyString());
		}catch (JSONException e) {
			throw new JsonOperationExceptionAP("Error Message(JSONException) :" ~ e.msg, __FILE__, __LINE__, e);			            
        } catch (Exception e) {
			throw new JsonOperationExceptionAP("Error Message(Exception) :" ~ e.msg, __FILE__, __LINE__, e);		            
        }
	}

	public static Optional!V getJsonValue(V)(string jsonContent , string path){

		try{
			if(jsonContent.empty || path.empty)
			{
				return false;
			}

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
			if(jsonContent.empty)
			{
				return false;
			}
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
			if(jsonContent.empty)
			{
				return false;
			}
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


	//اضافه شود :

	public static JSONType getJsonValueType(JSONValue jsonValue)
	{		
	
		return jsonValue.type;
	}
	
	

}


//اضافه شود :

public static class  CL_CoreAP_Conv
{
	public static Optional!T convertJsonValueToT(T)(JSONValue jsonValue) {
	    auto typeJsonValue = getJsonValueType(jsonValue);
		

	    static if (isIntegral!T || isFloating!T || isBoolean!T || is(T == string)) {
	        switch(typeJsonValue) {
	            case JSONType.INTEGER:
	                return Optional!T(jsonValue.integer.to!T());
	            case JSONType.FLOAT:
	                return Optional!T(jsonValue.floatValue.to!T());
	            case JSONType.STRING:
	                static if (is(T == string)) {
	                    return Optional!T(jsonValue.stringValue);
	                } else {
	                    throw new JSONConvertExceptionAP("Expected numeric/boolean JSON type for " ~ T.stringof ~ ", got string", __FILE__ , __LINE__ , e);
	                }
	            case JSONType.TRUE:
	            case JSONType.FALSE:
	                static if (is(T == bool)) {
	                    return Optional!T(jsonValue.boolean);
	                } else {
	                    throw new JSONConvertExceptionAP("Expected numeric/string JSON type for " ~ T.stringof ~ ", got boolean", __FILE__ , __LINE__ , e);
	                }
	            case JSONType.NULL:
	                return Optional!T.init;
	            default:
	                throw new JSONConvertExceptionAP("Unsupported JSON type for primitive conversion: " ~ typeJsonValue.to!string , __FILE__ , __LINE__ , e);
	        }
	    } else static if (isArray!T) {
	        alias ElementType = ElementType!T;
	        if (typeJsonValue == JSONType.ARRAY) {
	            T result;
	            foreach (itemJson; jsonValue.array) {
	                auto convertedItem = convertJsonValueToT!ElementType(itemJson);
	                if (convertedItem.isSet) {
	                    result ~= convertedItem.get;
	                } else {
	                    static if (!is(ElementType : Optional!U, U)) {
							throw new JSONConvertException("Failed to convert array element to " ~ ElementType.stringof , __FILE__ , __LINE__ ,e);
                        }
	                }
	            }
	            return Optional!T(result);
	        } else {
	            throw new JSONConvertExceptionAP("Expected array JSON type for " ~ T.stringof ~ ", got " ~ typeJsonValue.to!string , __FILE__ , __LINE__ , e);
	        }
	    } else static if (isStruct!T || isClass!T) {
	        if (typeJsonValue == JSONType.OBJECT) {
	            T obj = T.init;

	            foreach (memberName; __traits(allMembers, T)) {
	                static if (__traits(isField, T, memberName)) {
	                    string fieldName = memberName;
	                    alias FieldType = typeof(__traits(getField, obj, memberName));

	                    if (fieldName in jsonValue.object) {
	                        auto memberJsonValue = jsonValue.object[fieldName];
	                        auto convertedMember = convertJsonValueToT!FieldType(memberJsonValue);

	                        if (convertedMember.isSet) {
	                            mixin("obj." ~ fieldName ~ " = convertedMember.get;");
	                        } else {
	                            static if (!is(FieldType : Optional!U, U)) {
	                                throw new JSONConvertExceptionAP("Failed to convert field '" ~ fieldName ~ "' to " ~ FieldType.stringof , __FILE__ , __LINE__ , e);
	                            }
	                        }
	                    } else {
	                        static if (!is(FieldType : Optional!U, U)) {
	                        }
	                    }
	                }
	            }
	            return Optional!T(obj);
	        } else {
	            throw new JSONConvertExceptionAP("Expected object JSON type for " ~ T.stringof ~ ", got " ~ typeJsonValue.to!string , __FILE__ , __LINE__ , e);
	        }
	    } else {
	        static assert(0, "Unsupported type " ~ T.stringof ~ " for JSON conversion.");
	    }
	}


	public static JSONValue serializeTToJsonValue(T)(T obj){
		try{			
			static if(isIntegral!T || isFloating!T || isBoolean!T)
			{
				return JSONValue(obj);
			}else static if(is(T == string))
			{
				return JSONvalue(obj);
			}else static if(is(T : Optional!U , U))
			{
				if(obj.isSet)
				{
					return serializeTToJsonValue!U(obj.get);
				}else
				{
					return JSONValue.init;
				}
			}else static if (isArray!T)
			{
				alias ElementType = ElementType!T;
				JSONValue[] jsonArray;
				foreach(o; obj)
				{
					jsonArray ~= serializeTToJsonValue!ElementType(o);
				}
				return JSONValue(jsonArray);
			}else static if(isClass!T || isStruct!T)
			{
			    JSONValue jsonobject;
				jsonobject.object = new JSONValue.Object;

				foreach(memeber; __traits(allMembers , T))
				{
					string fieldName = member;
					auto fieldValue = __traits(getField , obj , member);

					JSONValue memeberJsonValue = serializeTToJsonValue!(typeof(fieldValue)(fieldValue));

					jsonobject[fieldName] = memeberJsonValue;
				}
			}
			else
			{
				static assert(0, "Unsupported type " ~ T.stringof ~ " for JSON serialization.");
			}

		}catch(JSONException e)
		{	
			throw new JSONExcptionAP("Error to Seralization JSON : " ~ e.msg);
		}catch(Exception e)
		{
			throw new JSONExcptionAP("Error during data = T  element conversion : " ~ e.msg);
		}
	}	
}

