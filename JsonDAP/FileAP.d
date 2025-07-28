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
import jsonOtherCodeAP;

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
				throw new InvalidArgumentExceptionAP("Input file path cannot be empty or null.", "filePath", filePath, "Non-empty string expected", null, 0);
			}

			
			enforce(existsFile(filePath),throw new FileOperationExceptionAP("File not found for reading.", filePath, "read", 0, null, 0));
			auto jsonContent = readText(filePath);
			static if(is(T == JSONValue))
			{
				return Optional!T(parseJSON(jsonContent));
			}else
			{				
				return CL_File_JSON.deserializeJson!T(jsonContent);
			}		
		}catch(FileException  e)
		{
			throw new FileOperationExceptionAP("File I/O error reading file.", filePath, "read", 0, null, 0, e);
		}catch(JSONException  e)
		{
			throw new JsonOperationExceptionAP("Invalid JSON format in file.", filePath, null, null, 0, e);
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred while reading JSON file.", null, 0, e);
		}
	}

	public static bool writeJsonFile(T)(string filePath , T data)
	{
		try{
			if(filePath.empty)
			{
				throw new InvalidArgumentExceptionAP("Output file path cannot be empty.", "filePath", filePath, "Non-empty string expected", null, 0);
			}
			enforce(existsFile(filePath), throw new FileOperationExceptionAP("Target file not found for writing.", filePath, "write", 0, null, 0));
			auto jsonContent = CL_File_JSON.serializeToJson(data);
			std.file.write(filePath , jsonContent.toString());
			return true;
		}catch(FileException  e)
		{
			throw new FileOperationExceptionAP("File I/O error writing to file.", filePath, "write", 0, null, 0, e);
		}catch(JSONException  e)
		{
			throw new JsonOperationExceptionAP("Serialization error while writing JSON to file.", filePath, null, null, 0, e);
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred while writing JSON file.", null, 0, e);
		}
	}


	public static Optional!long getJsonFileSize(string filePath)
	{
		try
		{
			if(filePath.empty)
			{
				throw new InvalidArgumentExceptionAP("File path cannot be empty when getting file size.", "filePath", filePath, "Non-empty string expected", null, 0);
			}
			enforce(existsFile(filePath),throw new FileOperationExceptionAP("File not found for size check.", filePath, "get size", 0, null, 0));
			long fileSize = std.file.getSize(filePath);
			return Optional!long(fileSize);
		}catch(FileException  e)
		{
			throw new FileOperationExceptionAP("File I/O error getting size of file.", filePath, "get size", 0, null, 0, e);
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred while getting file size.", null, 0, e);
		}
	}

	public static Optional!(T[]) readJsonArray(T)(string filepath){
		try{
			string errorTextStrIsNull;
			bool CheckStrIsNull;			
			CL_PublicCodeOtherCode.StrIsNUll(filePath , "input" ,  CheckStrIsNull ,  errorTextStrIsNull);
			if(CheckStrIsNull)
			{
				throw new InvalidArgumentExceptionAP("Input file path cannot be empty or null.", "filePath", filePath, "Non-empty string expected", null, 0);
			}
			enforce(existsFile(filePath)) , throw new FileOperationExceptionAP("File not found for reading array.", filePath, "read array", 0, null, 0);
			string jsonContent = readText(filePath);
			return deserializeJsonArray!T[](jsonContent);
		}catch(FileException  e)
		{
			throw new FileOperationExceptionAP("File I/O error reading array from file.", filePath, "read array", 0, null, 0, e);
		}catch(JSONException  e)
		{
			throw new JsonOperationExceptionAP("Invalid JSON format for array in file.", filePath, null, null, 0, e);
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred while reading JSON array from file.", null, 0, e);
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
			throw new FileOperationExceptionAP("File I/O error during existence check.", filePath, "check existence", 0, null, 0, e);
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred during file existence check.", null, 0, e);
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

		if(!CL_FileAP.existsFile(filePath))
		{
			return false;
		}		
		

		auto readFile = readJsonFile!JSONValue(filePath);
		if(readFile.isNull)
		{
			return false;
		}		

		JSONValue rootJson = readFile.get;		
		
		
		if(rootJson.type != JSONType.OBJECT)
		{
			return false;	
		}

		PathStep[] parsedSteps;
		parsedSteps = CL_JsonOtherCode.JsonPathParserAP(jsonPath);
			
		if(parsedSteps.length == 0)
		{
			return false;
		}

		//For example for jsonPath: main.name.khashayar		

		JSONValue currentJsonNodeToTraverse = rootJson;
			
		for(int i = 0 ; i < parsedSteps.length - 1; i++ )
		{
			auto currentStep = parsedSteps[i];
			if(currentStep.type == PathStepType.ObjectKey)
			{
				if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
				{
					return false;
				}
				if(!currentStep.key in currentJsonNodeToTraverse.object)
				{
					return false;
				}
				currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentStep.key];

			}else if(currentStep.type == PathStepType.ArrayIndex)
			{
				return false;
			}else
			{
				return false;
			}

			if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}
		}

		PathStep  finalStep = parsedSteps[parsedSteps.length - 1];

		
		auto convertValue = serializeToJson(value);				
		if(finalStep.type == PathStepType.ObjectKey)
		{
			if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}
			currentJsonNodeToTraverse[finalStep.key] = convertValue;
		}else {
			return false;
		}

		auto writeFile = writeJsonFile(filePath , rootJson);
		if(!writeFile)
		{
			return false;
		}


		return true;		
	}


	public static bool updateJsonValueARRAY(V)(string filePath , string jsonPath , V value)
	{
		string[] checkStrIsNull = [filePath , jsonPath];

		if(CL_PublicCodeOtherCode.checkStringIsNull_array(checkStrIsNull))
		{
			return false;
		}

		if(!CL_FileAP.existsFile(filePath))
		{
			return false;
		}






		auto readFile = readJsonFile!JSONValue(filePath);
		if(readFile.isNull)
		{
			return false;
		}		

		JSONValue rootJson = readFile.get;		



		PathStep[] parsedSteps;
		parsedSteps = CL_JsonOtherCode.JsonPathParserAP(jsonPath);

		if(parsedSteps.length  == 0)
		{
			return false;
		}

		auto currentJsonNodeToTraverse = rootJson;
		
		for(int i = 0; i < parsedSteps.length  - 1 ; i++)
		{
			auto currentStep = parsedSteps[i];
			if(currentStep.type == PathStepType.ObjectKey)
			{
				if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
				{
					return false;
				}
				if(!currentStep.key in currentJsonNodeToTraverse.object)
				{
					return false;
				}
				currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentStep.key];
			}else if(currentStep.type == PathStepType.ArrayIndex)
			{
				if(currentJsonNodeToTraverse.type != JSONType.ARRAY)
				{
					return false;
				}
				if(currentStep.index >= currentJsonNodeToTraverse.length )
				{
					return false;
				}
				currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentStep.index];

			}


			if(currentJsonNodeToTraverse.type != JSONType.OBJECT && currentJsonNodeToTraverse.type != JSONType.ARRAY)
			{
				return false;
			}
		}

		PathStep finalStep = parsedSteps[parsedSteps.length  - 1];

		JSONValue convertValue = serializeToJson(value);

		if(finalStep.type == PathStepType.ObjectKey)
		{
			if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}
			currentJsonNodeToTraverse[finalStep.key] = convertValue;


			
		}else if(finalStep.type == PathStepType.ArrayIndex)
		{
			if(currentJsonNodeToTraverse.type != JSONType.ARRAY)
			{
				return false;
			}
			if(finalStep.index >= currentJsonNodeToTraverse.array.length)
			{
				return false;
			}
			currentJsonNodeToTraverse[finalStep.index] = convertValue;

		}else{
			return false;
		}

		auto writeFile = writeJsonFile(filePath , rootJson);
		if(!writeFile)
		{
			return false;
		}

		return true;
	}

	public static bool addJsonItemOBJECT(T)(string filePath , string jsonPath , T item)
	{
		//Example : a.d.NewKey 
		// NewKey : T item
		string[] checkStrIsNull = [filePath , jsonPath];
		if(CL_PublicCodeOtherCode.checkStringIsNull_array(checkStrIsNull))
		{
			return false;
		}

		if(!CL_FileAP.existsFile(filePath))
		{
			return false;
		}    

		auto readFile = readJsonFile!JSONValue(filePath);
		if(readFile.isNull)
		{
			return false;
		}

		JSONValue rootJson = readFile.get;

		if(rootJson.type != JSONType.OBJECT)
		{
			return false;
		}

		PathStep[] parsedSteps;
		parsedSteps = CL_JsonOtherCode.JsonPathParserAP(jsonPath);

		if(parsedSteps.length == 0)
		{
			return false;
		}


		JSONValue currentJsonNodeToTraverse = rootJson;
		
		for(int i = 0; i < parsedSteps.length - 1 ; i++)
		{
			auto currentStep = parsedSteps[i];
			if(currentStep.type == PathStepType.ObjectKey)
			{
				if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
				{
					return false;
				}

				if(!currentStep.key in currentJsonNodeToTraverse.object)
				{
					return false;
				}

				currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentStep.key];
			}else if(currentStep.type == PathStepType.ArrayIndex)
			{
				return false;
			}else 
			{
				return false;
			}

			if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}
			



		}

		PathStep finalStep = parsedSteps[parsedSteps.length - 1];

			
		JSONValue convertedValue = serializeToJson(item);

		if(finalStep.type != PathStepType.ObjectKey)
		{
			return false;
		}
		if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
		{
			return false;
		}

		if(finalStep.key in currentJsonNodeToTraverse.object)
		{
			return false;
		}

		currentJsonNodeToTraverse[finalStep.key] = convertValue;

		if(!writeJsonFile(filePath,  rootJson))
		{
			return false;
		}

		return true;


	}

	public static bool addJsonItemARRAY(T)(string filePath , string jsonPath , T item){
		string[] checkStrIsNull = [filePath , jsonPath];

		if(CL_PublicCodeOtherCode.checkStringIsNull_array(checkStrIsNull))
		{
			return false;
		}

		if(!CL_FileAP.existsFile(filePath))
		{
			return false;
		}


		auto readFile = readJsonFile!JSONValue(filePath);
		if(readFile.isNull)
		{
			return false;
		}

		JSONValue rootJson = readFile.get;

		PathStep[] parsedSteps;
		parsedSteps = CL_JsonOtherCode.JsonPathParserAP(jsonPath);

		if(parsedSteps.length == 0)
		{
			return false;
		}
	
		auto currentJsonNodeToTraverse = rootJson;
		for(int i = 0 ; i < parsedSteps.length - 1; i++)
		{
			auto currentStep = parsedSteps[i];
			if(currentStep.type == PathStepType.ObjectKey)
			{
				if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
				{
					return false;
				}
				if(!currentStep.key in currentJsonNodeToTraverse.object)
				{
					return false;
				}
				currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentStep.key];
			}else if(currentStep.type == PathStepType.ArrayIndex)
			{
				if(currentJsonNodeToTraverse.type != JSONType.ARRAY)
				{
					return false;
				}
				if(currentStep.index >= currentJsonNodeToTraverse.length)
				{
					return false;
				}
				currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentStep.index];
			}else
			{
				return false;
			}

			if(currentJsonNodeToTraverse.type != JSONType.ARRAY && currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}
		}

		PathStep finalStep = parsedSteps[parsedSteps.length - 1];


		JSONValue convertValue = serializeToJson(value);
		
		if(finalStep.type == PathStepType.ObjectKey)
		{
			if(finalStep.key in currentJsonNodeToTraverse.object)
			{
				return false;
			}
			if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}
			currentJsonNodeToTraverse = currentJsonNodeToTraverse[finalStep.key] = convertValue;
		}else if(finalStep.type == PathStepType.ArrayIndex)
		{
			if(currentJsonNodeToTraverse.type != JSONType.ARRAY)
			{
				return false;
			}
			if(finalStep.index >= currentJsonNodeToTraverse.length)
			{
				return false;
			}

			currentJsonNodeToTraverse[finalStep.key].array ~= convertValue;
		}else
		{
			return false;
		}

		auto writeFile = writeJsonFile(filePath , rootJson);
		if(!writeFile)
		{
			return false;
		}

		return true;
		
	}

	public static bool removeJsonItemOBJECT(string filePath, string jsonPath)
	{
		string[] checkStrIsNull = [filePath , jsonPath];

		if(CL_PublicCodeOtherCode.checkStringIsNull_array(checkStrIsNull))
		{
			return false;
		}

		if(!CL_FileAP.existsFile(filePath))
		{
			return false;
		}

		auto readFile = CL_FileAP.readJsonFile!JSONValue(filePath);
		if(readFile.isNull){
			return false;
		}


		JSONValue rootJson = readFile.get;

		if(rootJson.type != JSONType.OBJECT)
		{
			return false;
		}

		PathStep[] parsedSteps;
		parsedSteps = CL_JsonOtherCode.JsonPathParserAP(jsonPath);
		
		if(parsedSteps.length <= 1)
		{
			return false;
		}

		JSONValue currentJsonNodeToTraverse = rootJson;

		for (int i = 0; i < parsedSteps.length - 1; i++)
		{
			PathStep currentStep = parsedSteps[i];
			if(currentStep.type == PathStepType.ObjectKey)
			{
				if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
				{
					return false;
				}
				if(currentStep.key !in currentJsonNodeToTraverse.object)
				{
					return false;
				}
				currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentStep.key];

			}else if(currentStep.type == PathStepType.ArrayIndex)
			{
				return false;
			}else
			{
				return false;
			}

			if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}
		}

		PathStep finalStep = parsedSteps[parsedSteps.length - 1];

		if(finalStep.type != PathStepType.ObjectKey)
		{
			return false;
		}
		if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
		{
			return false;
		}
		bool returnBool = false;
		if(finalStep.key in currentJsonNodeToTraverse.object){
			returnBool = true;
			currentJsonNodeToTraverse.object.remove(finalStep.key);
		}		


		bool writeFile = CL_FileAP.writeJsonFile(filePath , rootJson);
		if(!writeFile)
		{
			return false;
		}
		if(returnBool)
		{
			return true;
		}
		return false;

	}

	public static bool removeJsonItemARRAY(string filePath , string jsonPath)
	{
		string[] checkStrIsNull = [filePath , jsonPath];

		if(CL_PublicCodeOtherCode.checkStringIsNull_array(checkStrIsNull))
		{
			return false;
		}

		if(!CL_FileAP.existsFile(filePath))
		{
			return false;
		}

		auto readFile = CL_FileAP.readJsonFile!JSONValue(filePath);
		if(readFile.isNull)
		{
			return false;
		}

		JSONValue rootJson = readFile.get;
		
		PathStep[] parsedSteps;
		parsedSteps = CL_JsonOtherCode.JsonPathParserAP(jsonPath);

		if(parsedSteps.length <= 1)
		{
			return false;
		}

		JSONValue currentJsonNodeToTraverse = rootJson;

		for(int i = 0; i < parsedSteps.length - 1; i++ )
		{
			PathStep currentStep = parsedSteps[i];
			if(currentStep.type == PathStepType.ObjectKey)
			{
				if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
				{
					 return false;
				}
				if(currentStep.key !in currentJsonNodeToTraverse[currentStep.key])
				{
					return false;
				}

				currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentStep.key];

			}else if(currentStep.type == PathStepType.ArrayIndex)
			{
				if(currentJsonNodeToTraverse.type != JSONType.ARRAY)
				{
					return false;
				}		

				if(currentStep.index >= currentJsonNodeToTraverse.length )
				{
					return false;
				}

				currentJsonNodeToTraverse = currentJsonNodeToTraverse[currentStep.index];
			}else{
				return false;
			}

			if(currentJsonNodeToTraverse.type != JSONType.OBJECT || currentJsonNodeToTraverse.type != JSONType.ARRAY)
			{
				return false;
			}
		}


		PathStep finalStep = parsedSteps[parsedSteps.length - 1];

		if(finalStep.type == PathStepType.ObjectKey)
		{
			if(finalStep.key in currentJsonNodeToTraverse.object)
			{
				return false;
			}
			if(currentJsonNodeToTraverse.type != JSONType.OBJECT)
			{
				return false;
			}

			if(finalStep.key in currentJsonNodeToTraverse.object)
			{
				currentJsonNodeToTraverse.object.remove(finalStep.key);
			}else{
				return false;
			}


		}else if(finalStep.type == PathStepType.ArrayIndex)
		{
			if(currentJsonNodeToTraverse.type != JSONType.ARRAY)
			{
				return false;
			}
			if(finalStep.index >= currentJsonNodeToTraverse.length)
			{
				return false;
			}

			currentJsonNodeToTraverse[finalStep.key].array = //error//
			

		}else
		{
			return false;
		}



		bool writeFile = CL_FileAP.writeJsonFile(filePath , rootJson);
		if(!writeFile)
		{
			return false;
		}	

		return true;

	}

	public static bool mergeJson(string filePath, string jsonContentToMerge, bool overwriteExisting = true)
	{
		return false;
	}

}

//اضافه شود :

public class CL_File_JSON
{
	public static Optional!(T[]) deserializeJsonArray(T)(string jsonContent){
		try{
			JSONValue val = parseJSON(jsonContent);
			if(val.type == JSONType.ARRAY)
			{
					T[] arr;
					foreach(item; val.array)
					{
						auto convertedItemOptional = CL_CoreAP_Conv.convertJsonValueToT!T(item);
							
						if(!convertedItemOptional.isNull)
						{
							arr ~= convertedItemOptional.get;
						}else{
							throw new JSONConvertExceptionAP("Failed to convert array element from JSON.", T.ToString(), item.ToString(), item.GetType().Name, T.ToString(), "ElementConversionFailed", "Could not convert JSON array element to " ~ T.ToString(), null, 0, null);
						}
					}
					return Optional!(T[])(arr);
			}else
			{
               throw new JSONConvertExceptionAP("Expected a JSON array, but got an unexpected type.", T.ToString(), val.ToString(), val.GetType().Name, T.ToString(), "TypeMismatch", "JSON content is not an array.", null, 0, null);
			}
		}catch(JSONException e)
		{
			throw new JsonOperationExceptionAP("Failed to deserialize JSON array.", null, jsonContent, null, 0, e);
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred during JSON array element conversion.", null, 0, e);
		}
		return Optional!(T[]).init;
	}

	public static Optional!(T) deserializeJson(T)(string jsonContent)
	{
		try{		
			JSONValue val = parseJSON(jsonContent);			
			if(val.type == JSONType.OBJECT)
			{
				T obj;
					auto convertedItemOptional = CL_CoreAP_Conv.convertJsonValueToT!T(val);
					if(!convertedItemOptional.isNull)
					{
						obj = convertedItemOptional.get;
					}else
					{
						throw new JSONConvertExceptionAP("Failed to convert element from JSON.", T.toString(), val.toString(), val.type, T.toString(), "ObjectConversionFailed", "Could not convert JSON object to  |__|  Error in ( auto convertedItemOptional = convertJsonValueToT!T(val); ) " ~ T.ToString(), null, 0, null);
					}
					return Optional!(T)(obj);
							
			}else
			{
				throw new JSONConvertExceptionAP("Failed to convert element from JSON.", T.toString(), val.toString(), val.type , T.toString(), "ObjectConversionFailed", "Could not convert JSON object to " ~ T.toString(), null, 0, null);
			}
		}catch(JSONException e)
		{
			throw new JsonOperationExceptionAP("Failed to deserialize JSON.", null, jsonContent, null, 0, e);
		}catch(Exception e)
		{
			throw new UnknownErrorexceptionAP("An unexpected error occurred during JSON element conversion.", null, 0, e);
		}
		return Optional!(T).init;
	}


	public static JSONValue serializeToJson(T)(T obj)
	{
		try{
			
			static if(is(T == JSONValue))
			{				
				return obj;
			}else{
				auto jsonVal = CL_CoreAP_Conv.serializeTToJsonValue!T(obj);
				return jsonVal;
			}		
		}catch (Exception e) {
           throw new JsonOperationExceptionAP("Failed to serialize object to JSON string.", null, obj.toString(), null, 0, e);
        }
	}

	public static  JSONValue[] serializeToJsonArray(T)(T data)
	{
		try{
			static if(is(T == JSONValue[]))
			{
				return data;
			}else static if(is (T == JSONValue))
			{
				JSONValue[] output = [data];
				return output;

			}else
			{
				JSONValue jsonVal = CL_CoreAP_Conv.serializeTToJsonValue!T(obj);
				return jsonVal;
			}			
		}catch (Exception e) {
            throw new JsonOperationExceptionAP("Failed to serialize object to JSON array string.", null, data.toString(), null, 0, e);
        }
	}

}