module FileAPMerge;

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
import ExceptionJsonAP;
import jsonOtherCodeAP;
import FileAP;
import FileAPJson;

alias Optional = Nullable;

public static class CL_FileAP_Merge
{
    public static bool mergeJson(string filePath, JSONValue jsonContentToMerge,
            bool overwriteExisting = true, bool mergeArrays = false)
    {
        string ignoredMessage;
        return mergeJsonWithMessage(filePath, jsonContentToMerge, overwriteExisting, mergeArrays,
                ignoredMessage);
    }

    public static bool mergeJsonWithMessage(string filePath, JSONValue jsonContentToMerge,
            bool overwriteExisting, bool mergeArrays, out string message)
    {
        message = "";

        try
        {
            string errorCheck;
            bool outputBoolCheck;
            CL_PublicCodeOtherCode.strIsNil(filePath, "input", outputBoolCheck, errorCheck);
            if (outputBoolCheck)
            {
                return fail(message, "filePath is empty: " ~ errorCheck);
            }

            if (!CL_FileAP.existsFile(filePath))
            {
                return fail(message, format!"the file does not exist: %s"(filePath));
            }

            if (jsonContentToMerge == JSONValue.init)
            {
                return fail(message, "the document to merge is empty.");
            }

            auto ReadFile = CL_FileAP.readJsonFile!JSONValue(filePath);
            if (ReadFile.isNull)
            {
                return fail(message, format!"the file could not be read as JSON: %s"(filePath));
            }

            JSONValue rootJson = ReadFile.get;

            string mergeMessage = "";
            bool mergeResult = CL_JsonOtherCode.recursiveMerge(rootJson,
                    jsonContentToMerge, overwriteExisting, mergeArrays, mergeMessage);
            if (!mergeResult)
            {
                return fail(message, "the merge failed: " ~ mergeMessage);
            }

            if (!CL_FileAP.writeJsonFile(filePath, rootJson))
            {
                return fail(message, format!"the merged document could not be written to %s"(filePath));
            }

            return true;
        }
        catch (BaseExceptionAP e)
        {
            message = e.msg;
            return false;
        }
    }

    private static bool fail(ref string message, string reason)
    {
        message = reason;
        return false;
    }
}
