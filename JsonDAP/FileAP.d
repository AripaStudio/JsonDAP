module FileAP;


import std.file;
import std.string;
import std.json;
import std.typecons;
import std.exception;
import PublicCodeOtherCode;

alias Optional = Nullable;

public static class CL_FileAP
{
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
	public static bool updateJsonValue(V)(string filePath , string jsonPath , V value)
	{
		if(!existsFile(filePath))
		{
			return false;
		}
		
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
	public static Optional!(T[]) deserializeJsonArray(T)(strign jsonContent)
	{
		try{
			JSONValue val = parseJsonString(jsonContent);
			if(val.type == JSONType.Array)
			{
				T[] arr;
				foreach(item; val.array)
				{
					arr ~= convertJsonValueToT!T(item);
				}
				return arr;
			}
		}catch(JSONException e)
		{
			throw new JSONExceptionAP("Failed to deseralize JSON Array : " ~ e.msg);
		}
	}

}