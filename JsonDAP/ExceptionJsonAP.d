module ExceptionJsonAP;

import std.string;
import std.conv;
import ExceptionAP;

// throw new JSONExceptionAP("Invalid JSON structure.", "$.root.data", "{'badJson':");
public class JSONExceptionAP : BaseExceptionAP
{
    string jsonPath;
    string jsonSnippet;

    this(string msg, string jsonPath = null, string jsonSnippet = null,
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, file, line, next);
        this.jsonPath = jsonPath;
        this.jsonSnippet = jsonSnippet;
    }

    string getJsonPath() const @safe
    {
        return jsonPath;
    }

    string getJsonSnippet() const @safe
    {
        return jsonSnippet;
    }

    override string toString() 
    {
        string baseStr = super.toString();
        if (jsonPath !is null && !jsonPath.empty)
        {
            baseStr ~= "\n JSON Path : " ~ jsonPath;
        }
        if (jsonSnippet !is null && !jsonSnippet.empty)
        {
            baseStr ~= "\n JSON Snippet : " ~ jsonSnippet;
        }
        return baseStr;
    }
}

// throw new JsonOperationExceptionAP("Failed to parse JSON content.", "$.data", "{'invalid_json':}");
public class JsonOperationExceptionAP : JSONExceptionAP
{
    this(string msg, string jsonPath = null, string jsonSnippet = null,
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, jsonPath, jsonSnippet, file, line, next);
    }
}

// throw new JSONConvertExceptionAP("JSON field conversion failed.", "user_id", "abc", "string", "int", "Invalid char in ID.");
public class JSONConvertExceptionAP : ConvertExceptionAP
{
    string jsonSpecificError;

    this(string msg, string parameterName, string invalidValue, string inputType,
            string outputType, string jsonSpecificError,
            string conversionMethod = null, string reasonForFailure = null,
            string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure
    {
        super(msg, parameterName, invalidValue, inputType, outputType,
                conversionMethod, reasonForFailure, file, line, next);
        this.jsonSpecificError = jsonSpecificError;
    }

    override string toString() 
    {
        string baseStr = super.toString();
        if (jsonSpecificError !is null && !jsonSpecificError.empty)
        {
            baseStr ~= "\n JSON Specific Error : " ~ jsonSpecificError;
        }
        return baseStr;
    }
}
