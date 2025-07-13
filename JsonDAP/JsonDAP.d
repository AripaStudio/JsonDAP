module JsonDAP;

import std.stdio;
import CoreAP;
import FileAP;
import PublicCodeOtherCode;

import std.typecons; 

alias Optional = Nullable;

public class JsonAP
{
	export static Optional!T APreadJsonFile(string filePath)() {
        return CL_FileAP.readJsonFile!T(filePath);
    }

    export static bool APwriteJsonFile(T)(string filePath, T data) {
        return CL_FileAP.writeJsonFile!T(filePath, data);
    }

    export static Optional!long APgetJsonFileSize(string filePath) {
        return CL_FileAP.getJsonFileSize(filePath);
    }

    export static Optional!(T[]) APreadJsonArray(string filePath)() {
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

    export static Optional!V APgetJsonValue(string jsonContent, string path)() {
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
}