module JsonDAP;

import std.json;
import std.stdio;
import CoreAP;
public import CoreAP : JsonName, JsonIgnore;
import FileAP;
import FileAPAdd;
import FileAPJson;
import FileAPRemove;
import FileAPMerge;
import FileAPUpdate;
import CoreAPConv;
import CoreAPPath;
import CoreAPSerialize;
import JsonAPMessages;
import PublicCodeOtherCode;

import std.typecons;

alias Optional = Nullable;

//CL_JsonOtherCode :
export import jsonOtherCodeAP;

//Exceptions : 
export import ExceptionAP;
export import ExceptionJsonAP;

//CheckVariablesAP :
export import CheckVariablesAP;

public class JsonAP : APEditMessages
{
    export static Optional!T APreadJsonFile(T)(string filePath)
    {
        return CL_FileAP.readJsonFile!T(filePath);
    }

    export static bool APwriteJsonFile(T)(string filePath, T data)
    {
        return CL_FileAP.writeJsonFile!T(filePath, data);
    }

    export static Optional!long APgetJsonFileSize(string filePath)
    {
        return CL_FileAP.getJsonFileSize(filePath);
    }

    export static Optional!(T[]) APreadJsonArray(T)(string filePath)
    {
        return CL_FileAP.readJsonArray!T(filePath);
    }

    export static bool APisValidJson(string jsonContent)
    {
        return CL_CoreAP.isValidJson(jsonContent);
    }

    export static Optional!long APgetJsonItemCount(string jsonContent)
    {
        return CL_CoreAP.getJsonItemCount(jsonContent);
    }

    export static bool APisJsonNumber(string jsonContent)
    {
        return CL_CoreAP.isJsonNumber(jsonContent);
    }

    export static bool APisJsonString(string jsonContent)
    {
        return CL_CoreAP.isJsonString(jsonContent);
    }

    export static Optional!string APprettyPrintJson(string jsonContent)
    {
        return CL_CoreAP.prettyPrintJson(jsonContent);
    }

    export static Optional!V APgetJsonValue(V)(string jsonContent, string path)
    {
        return CL_CoreAP_Path.getJsonValue!V(jsonContent, path);
    }

    export static bool APisJsonObject(string jsonContent)
    {
        return CL_CoreAP.isJsonObject(jsonContent);
    }

    export static bool APisJsonArray(string jsonContent)
    {
        return CL_CoreAP.isJsonArray(jsonContent);
    }

    export static bool APisDigitAP(dchar c)
    {
        return CL_PublicCodeOtherCode.isDigitAP(c);
    }

    export static bool APisInteger(string s)
    {
        return CL_PublicCodeOtherCode.isInteger(s);
    }

    export static bool APexistsFile(string filePath)
    {

        return CL_FileAP.existsFile(filePath);
    }

    //CL_JsonOtherCode
    export static PathStep[] APJsonPathParser(string input)
    {
        return CL_JsonOtherCode.JsonPathParserAP(input);
    }

    export static bool APrecursiveMerge(ref JSONValue target, ref JSONValue source,
            bool overwrite, bool mergeArrays, out string message)
    {
        return CL_JsonOtherCode.recursiveMerge(target, source, overwrite, mergeArrays, message);
    }

    //CL_PublicCodeOtherCode:
    export static void APStrIsNUll(string input, string paramName = "input",
            out bool outputBool, out string ErrorText)
    {
        return CL_PublicCodeOtherCode.StrIsNUll(input, paramName, outputBool, ErrorText);
    }

    export static bool APCheckStringIsNullArray(string[] inputs)
    {
        return CL_PublicCodeOtherCode.checkStringIsNull_array(inputs);
    }

    //CL_FileAP:
    export static bool APexists(string filePath)
    {
        return CL_FileAP.Exists(filePath);
    }

    // CL_FileAP_Edit : 

    export static bool APupdateJsonValueOBJECT(V)(string filePath, string jsonPath, V value)
    {
        return CL_FileAP_Update.updateJsonValueOBJECT(filePath, jsonPath, value);
    }

    export static bool APupdateJsonValueARRAY(V)(string filePath, string jsonPath, V value)
    {
        return CL_FileAP_Update.updateJsonValueARRAY(filePath, jsonPath, value);
    }

    export static bool APaddJsonItemOBJECT(T)(string filePath, string jsonPath, T item)
    {
        return CL_FileAP_Add.addJsonItemOBJECT(filePath, jsonPath, item);
    }

    export static bool APaddJsonItemARRAY(T)(string filePath, string jsonPath, T item)
    {
        return CL_FileAP_Add.addJsonItemARRAY(filePath, jsonPath, item);
    }

    export static bool APremoveJsonItemARRAY(string filePath, string jsonPath)
    {
        return CL_FileAP_Remove.removeJsonItemARRAY(filePath, jsonPath);
    }

    export static bool APremoveJsonItemOBJECT(string filePath, string jsonPath)
    {
        return CL_FileAP_Remove.removeJsonItemOBJECT(filePath, jsonPath);
    }

    export static bool APmergeJson(string filePath, JSONValue jsonContentToMerge,
            bool overwriteExisting = true, bool mergeArrays = false)
    {
        return CL_FileAP_Merge.mergeJson(filePath, jsonContentToMerge,
                overwriteExisting, mergeArrays);
    }

    //CL_File_JSON:

    export static Optional!(T[]) APdeserializeJsonArray(T)(string jsonContent)
    {
        return CL_File_JSON.deserializeJsonArray!T(jsonContent);
    }

    export static Optional!(T) APdeserializeJson(T)(string jsonContent)
    {
        return CL_File_JSON.deserializeJson!T(jsonContent);
    }

    /**
     * Deserializes a JSON object into T, tolerating fields that are absent from
     * the JSON. Missing fields keep the default value of their type instead of
     * raising an error, which is what schema evolution needs.
     */
    export static Optional!(T) APdeserializeJsonLenient(T)(string jsonContent)
    {
        return CL_File_JSON.deserializeJson!T(jsonContent, true);
    }

    export static JSONValue APserializeToJson(T)(T obj)
    {
        return CL_File_JSON.serializeToJson!T(obj);
    }

    export static JSONValue[] APserializeToJsonArray(T)(T data)
    {
        return CL_File_JSON.serializeToJsonArray!T(data);
    }

    //CL_CoreAP:

    export static JSONType APgetJsonValueType(JSONValue jsonValue)
    {
        return CL_CoreAP.getJsonValueType(jsonValue);
    }

    //CL_CoreAP_Conv

    export static Optional!T APconvertJsonValueToT(T)(JSONValue jsonValue, bool lenient = false)
    {
        return CL_CoreAP_Conv.convertJsonValueToT!T(jsonValue, lenient);
    }

    export static JSONValue APserializeTToJsonValue(T)(T obj)
    {
        return CL_CoreAP_Serialize.serializeTToJsonValue!T(obj);
    }

    /**
     * Serializes a std.sumtype.SumType value into a tagged envelope:
     * {"tag": "<member name>", "value": <payload>}. The tag is the short name
     * of the active member type; pass tagOf to rename the tags on the wire.
     */
    export static JSONValue APserializeSumType(T)(T value,
            string delegate(string memberName) tagOf = null)
    {
        return CL_CoreAP_Serialize.serializeSumType(value, tagOf);
    }

    /**
     * Reads a tagged envelope produced by APserializeSumType and rebuilds the
     * member type that the tag names.
     */
    export static Optional!T APdeserializeSumType(T)(JSONValue jsonValue,
            bool lenient = false, string delegate(string memberName) tagOf = null)
    {
        return CL_CoreAP_Serialize.deserializeSumType!T(jsonValue, lenient, tagOf);
    }

    /**
     * Same as APdeserializeSumType, but takes the JSON document as text.
     */
    export static Optional!T APdeserializeSumTypeFromString(T)(string jsonContent,
            bool lenient = false, string delegate(string memberName) tagOf = null)
    {
        return CL_CoreAP_Serialize.deserializeSumType!T(parseJSON(jsonContent), lenient, tagOf);
    }

    /**
     * Same wire format as APserializeSumType, but the tag and the payload of
     * every member are decided by the caller, usually with match!.
     */
    export static JSONValue APserializeSumTypeWithHandlers(T)(T value,
            string delegate(T) tagOf, JSONValue delegate(T) payloadOf)
    {
        return CL_CoreAP_Serialize.serializeSumTypeWithHandlers(value, tagOf, payloadOf);
    }

    /**
     * Reads an envelope whose tag and payload are interpreted by the caller;
     * the resolver throws for a tag it does not know.
     */
    export static Optional!T APdeserializeSumTypeWithHandlers(T)(JSONValue jsonValue,
            T delegate(string tag, JSONValue payload) resolver)
    {
        return CL_CoreAP_Serialize.deserializeSumTypeWithHandlers!T(jsonValue, resolver);
    }
}
