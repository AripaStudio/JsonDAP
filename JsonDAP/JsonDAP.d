module JsonDAP;

import std.json;
import std.stdio;
import CoreAP;
import FileAP;
import PublicCodeOtherCode;

import std.typecons; 

alias Optional = Nullable;

public class JsonAP
{
	export static Optional!T APreadJsonFile(T)(string filePath) {
        return CL_FileAP.readJsonFile!T(filePath);
    }

    export static bool APwriteJsonFile(T)(string filePath, T data) {
        return CL_FileAP.writeJsonFile!T(filePath, data);
    }

    export static Optional!long APgetJsonFileSize(string filePath) {
        return CL_FileAP.getJsonFileSize(filePath);
    }

    export static Optional!(T[]) APreadJsonArray(T)(string filePath) {
        return CL_FileAP.readJsonArray!T(filePath);
    }

    export static bool APisValidJson(string jsonContent) {
        return CL_CoreAP.isValidJson(jsonContent);
    }

    export static Optional!long APgetJsonItemCount(string jsonContent) {
        return CL_CoreAP.getJsonItemCount(jsonContent);
    }

    export static bool APisJsonNumber(string jsonContent) {
        return CL_CoreAP.isJsonNumber(jsonContent);
    }

    export static bool APisJsonString(string jsonContent) {
        return CL_CoreAP.isJsonString(jsonContent);
    }

    export static Optional!string APprettyPrintJson(string jsonContent) {
        return CL_CoreAP.prettyPrintJson(jsonContent);
    }

    export static Optional!V APgetJsonValue(V)(string jsonContent, string path) {
        return CL_CoreAP.getJsonValue!V(jsonContent, path);
    }

    export static bool APisJsonObject(string jsonContent) {
        return CL_CoreAP.isJsonObject(jsonContent);
    }

    export static bool APisJsonArray(string jsonContent) {
        return CL_CoreAP.isJsonArray(jsonContent);
    }

    export static bool APisDigitAP(dchar c){
        return CL_PublicCodeOtherCode.isDigitAP(c);
    }

    export static bool APisInteger(string s){
        return CL_PublicCodeOtherCode.isInteger(s);
    }
    
    export static bool APexistsFile(string filePath)
	{
     
	    return CL_FileAP.existsFile(filePath);
	}


    //متد های اضافه شده 
    // هنوز کامل نشدن 
    
    //CL_PublicCodeOtherCode:
    export static void APStrIsNUll(string input, string paramName = "input" , out bool outputBool , out string ErrorText) 
	{
        return CL_PublicCodeOtherCode.StrIsNUll(input , out outputBool , out ErrorText);
	}

    //CL_FileAP:
    export static bool APexists(string filePath)
	{
        return CL_FileAP.Exists(filePath);
	}


    // CL_FileAP_Edit : 

    export static bool APupdateJsonValueOBJECT(V)(string filePath , string jsonPath , V value)
	{
        return CL_FileAP_Edit.updateJsonValueOBJECT(filePath , jsonPath , value);
	}

    export static bool APupdateJsonValueARRAY(V)(string filePath , string jsonPath , V value)
	{
        return CL_FileAP_Edit.updateJsonValueARRAY(filePath , jsonPath , value);
	}

    export static bool APaddJsonItem(T)(string filePath , string jsonPath , T item)
	{
        return CL_FileAP_Edit.addJsonItem(filePath , jsonPath , item);
	}

    export static bool APremoveJsonItem(string filePath, string jsonPath)
	{
        return CL_FileAP_Edit.removeJsonItem(filePath , jsonPath);
	}

    export static bool APmergeJson(string filePath, string jsonContentToMerge, bool overwriteExisting = true)
	{
        return CL_FileAP_Edit.mergeJson(filePath , jsonContentToMerge , overwriteExisting);
	}


    //CL_File_JSON:

    export static Optional!(T[]) APdeserializeJsonArray(T)(string jsonContent)
	{
        return CL_File_JSON.deserializeJsonArray!T[](jsonContent);
	}

    export static Optional!(T) APdeserializeJson(T)(string jsonContent)
	{
        return CL_File_JSON.deserializeJson!T(jsonContent);
	}

    export static JSONValue APserializeToJson(T)(T obj)
	{
        return CL_File_JSON.serializeToJson!T(obj);
	}

    export static  JSONValue[] APserializeToJsonArray(T)(T data)
	{
        return CL_File_JSON.serializeToJsonArray!T(data);
	}


    //CL_CoreAP:
    
    export static JSONType APgetJsonValueType(JSONValue jsonValue)
	{
        return CL_CoreAP.getJsonValueType(jsonValue);
	}

    //CL_CoreAP_Conv
    
    export static Optional!T APconvertJsonValueToT(T)(JSONValue jsonValue)
	{
        return CL_CoreAP_Conv.convertJsonValueToT!T(jsonValue);
	}

    export static JSONValue APserializeTToJsonValue(T)(T obj)
	{
        return CL_CoreAP_Conv.serializeTToJsonValue!T(obj);
	}


    //Exceptions : 

    export class APJsonOperationException : Exception {
		this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) pure {
			super(msg, file, line, next);
		}
	}

	export class APFileOperationException : Exception {
		string filePath;
		this(string msg, string filePath, string file = __FILE__, int line = __LINE__, Throwable next = null) {
			super(msg, file, line, next);
			this.filePath = filePath;
		}
	}

	export class APJSONException : Exception {
		this(string msg, string file = __FILE__, int line = __LINE__, Throwable next = null) pure {
			super(msg, file, line, next);
		}
	}

	export class APJSONConvertException : Exception {
		this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) pure {
			super(msg, file, line, next);
		}
	}

    export class APInvalidArgumentException : Exception{
		string parameterName;
		string invalidValue;

		this(string msg, string parameterName , string invalidValue , 
			 string file = __FILE__ , size_t line = __LINE__ , Throwable next = null) pure
			 {
				super(msg,file,line,next);
				this.parameterName = parameterName; 
				this.invalidValue = invalidValue;
			 }

		this(string msg, string parameterName, string invalidValue) pure
		{
			this(msg, parameterName, invalidValue, __FILE__, __LINE__, null);
		}
		override string toString() {
			return super.toString() ~
				"\n Parameter Name : " ~ parameterName ~
				"\n Invalid Value : " ~ invalidValue;
		}

		string getParameterName() const {
			return parameterName;
		}

		string getInvalidValue() const {
			return invalidValue;
		}
	}

    export class APUnknownErrorException : Exception{
		this(string msg , string file = __FILE__ , size_t line = __LINE__ , Throwable next = null ) pure
		{
			super(msg , file , line , next);
		}
	}



    



}