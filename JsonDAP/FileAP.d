module FileAP;


import std.file;
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
			throw new JsonOperationException("FileAP Error: File I/O error reading : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(JSONException  e)
		{
			throw new JsonOperationException("FileAP Error: Invalid JSON format in :"~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationException("FileAP Error: Unexpected error reading : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
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
			throw new JsonOperationException("FileAP Error: File I/O error writing to : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(JSONException  e)
		{
			throw new JsonOperationException("FileAP Error: Serialization error writing to :"~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationException("FileAP Error: Unexpected error writing to  : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
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
			throw new JsonOperationException("FileAP Error: File I/O error getting size of: "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationException("FileAP Error: Unexpected error getting size of   : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}
	}

	public static Optional!(T[]) readJsonArray(string filepath)()
	{
		try{

		}catch(FileException  e)
		{
			throw new JsonOperationException("FileAP Error: File I/O error reading array from: "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(JSONException  e)
		{
			throw new JsonOperationException("FileAP Error: Invalid JSON format for array in :"~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}catch(Exception e)
		{
			throw new JsonOperationException("FileAP Error: Unexpected error reading array from  : "~ filePath ~ "Error : " ~ e.msg, __FILE__, __LINE__, e);			
		}
	}




}