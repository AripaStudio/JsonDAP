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
import CheckVariablesAP;


alias Optional = Nullable;
//isSet

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
			throw new JsonOperationExceptionAP("Failed to parse JSON content.", "$", jsonContent, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred during JSON parsing.", __FILE__, __LINE__, e);			
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
			throw new JsonOperationExceptionAP("Error checking if JSON is a number.", "$", jsonContent, __FILE__, __LINE__, e);						
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred while checking JSON number type.", __FILE__, __LINE__, e);						
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
			throw new JsonOperationExceptionAP("Error checking if JSON is a string.", "$", jsonContent, __FILE__, __LINE__, e);
        } catch (Exception e) {
			throw new UnknownErrorexceptionAP("An unexpected error occurred while checking JSON string type.", __FILE__, __LINE__, e);	
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
			throw new JsonOperationExceptionAP("Failed to pretty print JSON content.", "$", jsonContent, __FILE__, __LINE__, e);
        } catch (Exception e) {
			throw new UnknownErrorexceptionAP("An unexpected error occurred during JSON pretty printing.", __FILE__, __LINE__, e);
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
						throw new JSONExceptionAP("JSON path invalid: segment '" ~ segment ~ "' not found.", path, jsonContent, __FILE__, __LINE__); 
					}
				}else if(current.type == JSON_TYPE.ARRAY && CL_PublicCodeOtherCode.isInteger(segment))
				{
					int index = segment.to!int;
					if(index >= 0 && index < current.array.length)
					{
						current = current.array[index];

					}else
					{
						throw new InvalidArgumentExceptionAP("JSON array index out of bounds.", "index", segment, "0-" ~ to!string(current.array.length - 1), __FILE__, __LINE__); 
					}
				}else
				{
					throw new JSONExceptionAP("JSON type unsuitable for path traversal.", path, jsonContent, __FILE__, __LINE__); 
				}
			}


			mixin(q{
				static if (is(V == string)) return Optional!V(current.str);
                else static if (is(V == long) || is(V == int)) return Optional!V(current.integer.to!V());
                else static if (is(V == double) || is(V == float)) return Optional!V(current.floating.to!V());
                else static if (is(V == bool)) return Optional!V(current.boolean);                
                else  throw new ConvertExceptionAP("JSON type conversion not supported.", "current.type", to!string(current.type), to!string(current.type), to!string(V.stringof), "getJsonValue", "Requested type is not supported.", __FILE__, __LINE__); 
			});

		}catch (JSONException e) {            
			throw new JsonOperationExceptionAP("Error parsing JSON while getting value.", "$", jsonContent, __FILE__, __LINE__, e);
        } catch (Exception e) {            
            throw new UnknownErrorexceptionAP("A general error occurred while getting JSON value.", __FILE__, __LINE__, e);			            
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

	public static JSONType getJsonValueType(JSONValue jsonValue)
	{		
	
		return jsonValue.type;
	}
	
	

}


//اضافه شود :

public static class  CL_CoreAP_Conv
{
	public static Optional!T convertJsonValueToT(T)(JSONValue jsonValue) {
	    auto typeJsonValue = CL_CoreAP.getJsonValueType(jsonValue);
		

	    static if (CheckVariablesAP.IsNumberAP!T.value || CheckVariablesAP.isBoolAP!T.value || CheckVariablesAP.isStringAP!T.value) {

				switch(typeJsonValue) {

					case JSONType.INTEGER:
						return Optional!T(jsonValue.integer.to!T());
					case JSONType.FLOAT:
						return Optional!T(jsonValue.floatValue.to!T());
					case JSONType.STRING:
						static if (is(T == string)) {
							return Optional!T(jsonValue.stringValue);
						} else {
						  throw new JSONConvertExceptionAP("Expected numeric or boolean JSON type, but got string.", T.stringof, jsonValue.stringValue, JSONType.STRING.to!string, T.stringof, "TypeMismatch", "Cannot convert string to " ~ T.stringof, __FILE__ , __LINE__);
						}
					case JSONType.TRUE:
					case JSONType.FALSE:
						static if (is(T == bool)) {
							return Optional!T(jsonValue.boolean);
						} else {
						   throw new JSONConvertExceptionAP("Expected numeric or string JSON type, but got boolean.", T.stringof, jsonValue.boolean.to!string, typeJsonValue.to!string, T.stringof, "TypeMismatch", "Cannot convert boolean to " ~ T.stringof, __FILE__ , __LINE__);
						}
					case JSONType.NULL:
						return Optional!T.init;
					default:
					   throw new JSONConvertExceptionAP("Unsupported JSON type for primitive conversion.", T.stringof, typeJsonValue.to!string, typeJsonValue.to!string, T.stringof, "UnsupportedType", "Cannot convert " ~ typeJsonValue.to!string ~ " to " ~ T.stringof, __FILE__ , __LINE__);
				}
	    } else static if (CheckVariablesAP.IsArrayAP!T.value) {


				alias ElementType = ElementType!T;

				if (typeJsonValue == JSONType.ARRAY) {
					T result;
					foreach (itemJson; jsonValue.array) {
						auto convertedItem = convertJsonValueToT!ElementType(itemJson);
						if (!convertedItem.isNull) {
							result ~= convertedItem.get;
						} else {
							static if (!is(ElementType : Optional!U, U)) {
								throw new JSONConvertExceptionAP("Failed to convert array element.", ElementType.stringof, itemJson.to!string, itemJson.type.to!string, ElementType.stringof, "ElementConversionFailed", "Could not convert JSON array element to " ~ ElementType.stringof, __FILE__ , __LINE__);
							}
						}
					}
					return Optional!T(result);
				} else {
					throw new JSONConvertExceptionAP("Expected array JSON type for target type " ~ T.stringof ~ ", but got " ~ typeJsonValue.to!string , T.stringof, typeJsonValue.to!string, typeJsonValue.to!string, T.stringof, "TypeMismatch", "JSON is not an array for array conversion.", __FILE__ , __LINE__);
				}


	    } else static if (CheckVariablesAP.IsStructAP!T.value || CheckVariablesAP.IsClassAP!T.value) {
				if (typeJsonValue == JSONType.OBJECT) {
					T obj = T.init;

					foreach (memberName; __traits(allMembers, T)) {
						static if (__traits(isField, T, memberName)) {
							string fieldName = memberName;
							alias FieldType = typeof(__traits(getField, obj, memberName));

							if (fieldName in jsonValue.object) {
								auto memberJsonValue = jsonValue.object[fieldName];
								auto convertedMember = convertJsonValueToT!FieldType(memberJsonValue);

								if (!convertedMember.isNull) {
									mixin("obj." ~ fieldName ~ " = convertedMember.get;");
								} else {
									static if (!is(FieldType : Optional!U, U)) {
										throw new JSONConvertExceptionAP("Failed to convert field '" ~ fieldName ~ "' to " ~ FieldType.stringof , fieldName, memberJsonValue.to!string, memberJsonValue.type.to!string, FieldType.stringof, "FieldConversionFailed", "Could not convert JSON field to " ~ FieldType.stringof, __FILE__ , __LINE__);
									}
								}
							} else {
								static if (!is(FieldType : Optional!U, U)) {
									throw new JSONConvertExceptionAP("Required field '" ~ fieldName ~ "' not found in JSON object.", fieldName, "Not Found", "N/A", FieldType.stringof, "MissingField", "Mandatory field missing for object conversion.", __FILE__ , __LINE__);
								}
							}
						}
					}
					return Optional!T(obj);
				} else {
					throw new JSONConvertExceptionAP("Expected object JSON type for target type " ~ T.stringof ~ ", but got " ~ typeJsonValue.to!string , T.stringof, typeJsonValue.to!string, typeJsonValue.to!string, T.stringof, "TypeMismatch", "JSON is not an object for struct/class conversion.", __FILE__ , __LINE__);
				}
	    } else {
	        static assert(0, "Unsupported type " ~ T.stringof ~ " for JSON conversion.");			
			//throw new UnknownErrorexceptionAP("Unsuppoted type : "~ T.type.toString() ~ "for Json Conversion." );
	    }
	}


	public static JSONValue serializeTToJsonValue(T)(T obj){
		try{			
			static if(CheckVariablesAP.IsNumberAP!T.value || CheckVariablesAP.isBoolAP!T.value)
			{
				return JSONValue(obj);
			}else static if(CheckVariablesAP.IsStringAP!T.value)
			{
				return JSONvalue(obj);
			}else static if(is(T : Optional!U , U))
			{
				if(obj.isNull)
				{
					return JSONValue.init;					
				}else
				{
					return serializeTToJsonValue!U(obj.get);
				}
			}else static if (CheckVariablesAP.IsArrayAP!T.value)
			{
				alias ElementType = ElementType!T;
				JSONValue[] jsonArray;
				foreach(o; obj)
				{
					jsonArray ~= serializeTToJsonValue!ElementType(o);
				}
				return JSONValue(jsonArray);
			}else static if(CheckVariablesAP.IsStructAP!T.value || CheckVariablesAP.IsClassAP!T.value)
			{
				JSONValue jsonObject;
				jsonObject.object = new JSONValue.Object;			

				static foreach(i , memberName; FieldNameTuple!T)
				{
					alias Field = FieldNameTuple!T[i];
					
					auto fieldValue = mixin("obj." ~ memberName);

					JSONValue memberJsonValue = serializeTToJsonValue!Fields(fieldValue);

					jsonobject[memberName] = memberJsonValue;
				}
			}else static if(CheckVariablesAP.IsEnumAP!T.value)
			{
				static if(is(typeof(T.init) : int))
				{
					return JSONValue(cast(int)obj);
				}else{
					return JSONValue(obj.toString());
				}
			}
			else
			{
				static assert(0, "Unsupported type " ~ T.stringof ~ " for JSON serialization.");
			}

		}catch(JSONException e)
		{	
			throw new JsonOperationExceptionAP("Error during JSON serialization.", null, obj.to!string, __FILE__, __LINE__, e);
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred during object to JSON conversion.", __FILE__, __LINE__, e);
		}
	}	
}

