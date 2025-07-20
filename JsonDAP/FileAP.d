module FileAP;


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

alias Optional = Nullable;

public static class CL_FileAP
{

	public static Optional!T readJsonFile(T)(string filePath){
		try{			
			string errorTextStrIsNull;
			bool CheckStrIsNull;
			
			CL_PublicCodeOtherCode.StrIsNUll(filePath , "input" ,  CheckStrIsNull ,  errorTextStrIsNull);
			if(CheckStrIsNull)
			{
				throw new UnknownErrorexceptionAP("Unknown error." ~ errorTextStrIsNull ~ " |____|  " , __FILE__ , __LINE__);
			}
			enforce(existsFile(filePath), new FileException("File not found.", filePath));
			string jsonContent = readText(filePath);
			return deserializeJson!T(jsonContent);
		}catch(FileException  e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: File I/O error reading : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(JSONException  e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: Invalid JSON format in :"~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: Unexpected error reading : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}
	}

	public static bool writeJsonFile(T)(string filePath , T data)
	{
		try{
			if(filePath.empty)
			{
				return false;
			}
			enforce(existsFile(filePath), new FileException("File not found.", filePath));
			string jsonContent = serializeToJson(data);
			write(filePath , jsonContent);
			return true;
		}catch(FileException  e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: File I/O error writing to : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(JSONException  e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: Serialization error writing to :"~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: Unexpected error writing to  : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}
	}


	public static Optional!long getJsonFileSize(string filePath)
	{
		try
		{
			if(filePath.empty)
			{
				return Optional!long().init;
			}
			enforce(existsFile(filePath), new FileException("File not found for size.", filePath));
			long fileSize = std.file.getSize(filePath);
			return Optional!long(fileSize);
		}catch(FileException  e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: File I/O error getting size of: "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: Unexpected error getting size of   : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}
	}

	public static Optional!(T[]) readJsonArray(T)(string filepath)
	{
		try{
			string errorTextStrIsNull;
			bool CheckStrIsNull;			
			CL_PublicCodeOtherCode.StrIsNUll(filePath , "input" ,  CheckStrIsNull ,  errorTextStrIsNull);
			if(CheckStrIsNull)
			{
				throw new UnknownErrorexceptionAP("Unknown error." ~ errorTextStrIsNull ~ " |____|  " , __FILE__ , __LINE__);
			}
			enforce(existsFile(filePath)) , new FileException("File not found." , filePath);
			string jsonContent = readText(filePath);
			return deserializeJsonArray!T[](jsonContent);
		}catch(FileException  e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: File I/O error reading array from: "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(JSONException  e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: Invalid JSON format for array in :"~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: Unexpected error reading array from  : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}
	}

	public static bool Exists(string filePath)
	{
		if(filePath.empty)
		{
			return false;
		}		
		if(!exists(filePath))
		{
			return false;
		}
		return true;
	}

	public static bool existsFile(string filePath)
	{
		try
		{
			if(!Exists(filePath))
			{
				return false;
			}
			return true;
		}catch(FileException e)
		{			
			throw new JsonOperationExceptionAP("FileAP Error: File I/O error Exists File from: "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationExceptionAP("FileAP Error: Unexpected error Exists File from  : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}
		

	}




}



//اضافه بشه :

public static class CL_FileAP_Edit
{

	
	public static bool updateJsonValueOBJECT(V)(string filePath , string jsonPath , V value)
	{
		
		string[] checkStrIsNull = [filePath , jsonPath];
		
		if(CL_PublicCodeOtherCode.checkStringIsNull_array(checkStrIsNull))
		{
			return false;
		}

		if(!existsFile(filePath))
		{
			return false;
		}		
		

		auto readFile = readJsonFile!JSONValue(filePath);
		if(!readFile.isSet)
		{
			return false;
		}		

		JSONValue rootJson = readFile.get;		
		
		
		if(rootJson.type != JSONType.OBJECT)
		{
			return false;	
		}

		//For example for jsonPath: main.name.khashayar
		string[] ways  = jsonPath.split(".");
		if(ways.length == 0)
		{
			return false;
		}
		int intWays = ways.length;

		
		
		string finalKey = ways[intWays - 1];

		JSONValue currentJsonNodeToTraverse = rootJson;

		byte checkComplete = 1;

		for(int i = 0; i < intWays - 1; i++)
		{
			string currentKey = ways[i];

			if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}

			if(!(currentKey in currentJsonNodeToTraverse.object))
			{
				return false;
			}

			currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentKey];

			

			if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}
			
			

		}
		
			auto convertValue = serializeToJson(value);				
			currentJsonNodeToTraverse[finalKey] = convertValue;


			auto writeFile = writeJsonFile(filePath , rootJson);
			if(!writeFile)
			{
				return false;
			}


			return true;		
	}


	//not Complete



	public static bool updateJsonValueARRAY(V)(string filePath , string jsonPath , V value)
	{
		string[] checkStrIsNull = [filePath , jsonPath];

		if(CL_PublicCodeOtherCode.checkStringIsNull_array(checkStrIsNull))
		{
			return false;
		}

		if(!existsFile(filePath))
		{
			return false;
		}




		auto readFile = readJsonArray!JSONValue(filePath);
		if(!readFile.isSet)
		{
			return false;
		}		

		JSONValue rootJson = readFile.get;		


		if(rootJson.type != JSONType.ARRAY)
		{
			return false;	
		}

		
		//کامل شود 






		return true;
	}

	public static bool addJsonItem(T)(string filePath , string jsonPath , T item)
	{
		return false;
	}

	public static bool removeJsonItem(string filePath, string jsonPath)
	{
		return false;
	}

	public static bool mergeJson(string filePath, string jsonContentToMerge, bool overwriteExisting = true)
	{
		return false;
	}

}

//اضافه شود :

public static class CL_File_JSON
{
	public static Optional!(T[]) deserializeJsonArray(T)(string jsonContent)
	{
		try{
			JSONValue val = parseJsonString(jsonContent);
			if(val.type == JSONType.ARRAY)
			{
					T[] arr;
					foreach(item; val.array)
					{
						auto convertedItemOptional = convertJsonValueToT!T(item);
							
						if(convertedItemOptional.isSet)
						{
							arr ~= convertedItemOptional.get;
						}else{
							throw new JSONConvertExceptionAP("Failed to convert array element from JSON to type " ~ T.stringof , __FILE__ , __LINE__);
						}
					}
					return Optional!(T[])(arr);
			}else
			{
                throw new JSONConvertExceptionAP("Expected a JSON array, but got type: " ~ val.type.to!string , __FILE__ , __LINE__);
			}
		}catch(JSONException e)
		{
			throw new JSONExceptionAP("Failed to deseralize JSON Array : " ~ e.msg);
		}catch(Exception e)
		{
			throw new JSONExceptionAP("Error during JSON array element conversion: " ~ e.msg);
		}
		return Optional!(T[]).init;
	}

	public static Optional!(T) deserializeJson(T)(string jsonContent)
	{
		try{		
			JSONValue val = parseJsonString(jsonContent);
			if(val.type == JSONType.OBJECT)
			{
				T obj;
				auto convertedItemOptional = convertJsonValueToT!T(val);
				if(convertedItemOptional.isSet)
				{
					obj ~= convertedItemOptional.get;
				}else
				{
					throw new JSONConvertExceptionAP("Failed to convert  element from JSON to type " ~ T.stringof , __FILE__ , __LINE__);
				}
				return Optional!(T)(obj);
			}
		}catch(JSONException e)
		{
			throw new JSONExceptionAP("Failed to deseralize JSON  : " ~ e.msg);
		}catch(Exception e)
		{
			throw new JSONExceptionAP("Error during JSON  element conversion: " ~ e.msg);
		}
		return Optional!(T).init;
	}


	public static JSONValue serializeToJson(T)(T obj)
	{
		try{
			JSONValue jsonVal = serializeTToJsonValue!T(obj);
			return jsonVal.toString();
		}catch (Exception e) {
            throw new JsonOperationExceptionAP("Failed to serialize object to JSON string: " ~ e.msg, __FILE__, __LINE__, e);
        }
	}

	public static  JSONValue[] serializeToJsonArray(T)(T data)
	{
		try{
			JSONValue jsonVal = serializeTToJsonValue!T(obj);
			return jsonVal.toPrettyString();
		}catch (Exception e) {
            throw new JsonOperationExceptionAP("Failed to serialize object to pretty JSON string: " ~ e.msg, __FILE__, __LINE__, e);
        }
	}

}