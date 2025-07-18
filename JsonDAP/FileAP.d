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

alias Optional = Nullable;

public static class CL_FileAP
{
	//Fix Deserialization and serialize and Other
	//Error : 
	// Fix writeJsonFile , CL_File_JSON and updateJsonValueOBJECT

	public static Optional!T readJsonFile(string filePath)(){
		try{
			enforce(exists(filePath)) , new FileException("File not found.",filePath);
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
			enforce(exists(filePath)) , new FileException("File not found.",filePath);
			string jsonContent = serializeToJson(data);
			writeText(filePath , jsonContent);
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
			enforce(exists(filePath), new FileException("File not found for size.", filePath));
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

	public static Optional!(T[]) readJsonArray(string filepath)()
	{
		try{
			enforce(exists(filePath)) , new FileException("File not found." , filePath);
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

	//اضافه شود :
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



	//not Complete : 
	public static bool updateJsonValueOBJECT(V)(string filePath , string jsonPath , V value)
	{
		if(!existsFile(filePath))
		{
			return false;
		}
		auto readFile = readJsonFile!JSONValue(filePath);
		if(!readFile.isSet)
		{
			return false;
		}

		string[] ways  = jsonPath.split(".");
		if(ways.length == 0)
		{
			return false;
		}
		int intWays = ways.length;

		JSONValue rootJson = readFile.get;		
		JSONValue currentJsonNodeToTraverse = rootJson;
		
		if(rootJson.type != JSONType.OBJECT)
		{
			return false;	
		}
		
		string finalKey = ways[intWays - 1];
		byte checkComplete = 1;

		for(int i = 0; i < intway - 1; i++)
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
			
			if(i == finalKey && currentJsonNodeToTraverse[finalKey].type == JSONType.OBJECT)
			{
				auto convertValue = serializeToJson(value);
				currentJsonNodeToTraverse[intWays] = convertValue;
								
				
				auto writeFile = writeJsonFile(filePath , rootJson);
				if(!writeFile)
				{
					return false;
				}


				checkComplete = 0;
				
			}
			


		}
		if(checkComplete == 0)
		{
			return true;
		}else{
			return false;
		}
						
		return false;
	}


	public static bool updateJsonValueARRAY(V)(string filePath , string jsonPath , V value)
	{
		return false;
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