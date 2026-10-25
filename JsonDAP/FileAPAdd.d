module FileAPAdd;

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

public static class CL_FileAP_Add
{
    public static bool addJsonItemOBJECT(T)(string filePath, string jsonPath, T item)
    {
        string ignoredMessage;
        return addJsonItemOBJECT!T(filePath, jsonPath, item, ignoredMessage);
    }

    public static bool addJsonItemOBJECT(T)(string filePath, string jsonPath, T item,
            out string message)
    {
        //Example : a.d.NewKey
        // NewKey : T item
        message = "";

        try
        {
            string[] checkStrIsNull = [filePath, jsonPath];
            if (CL_PublicCodeOtherCode.checkStringIsNull_array(checkStrIsNull))
            {
                return fail(message, "filePath and jsonPath cannot be null, empty or whitespace.");
            }

            if (!CL_FileAP.existsFile(filePath))
            {
                return fail(message, format!"the file does not exist: %s"(filePath));
            }

            auto readFile = CL_FileAP.readJsonFile!JSONValue(filePath);
            if (readFile.isNull)
            {
                return fail(message, format!"the file could not be read as JSON: %s"(filePath));
            }

            JSONValue rootJson = readFile.get;

            if (rootJson.type != JSONType.OBJECT)
            {
                return fail(message, format!"the root node is %s, not a JSON object."(rootJson.type));
            }

            PathStep[] parsedSteps;
            parsedSteps = CL_JsonOtherCode.JsonPathParserAP(jsonPath);

            if (parsedSteps.length == 0)
            {
                return fail(message, format!"the JSON path '%s' could not be parsed."(jsonPath));
            }

            JSONValue* currentJsonNodeToTraverse = &rootJson;

            for (int i = 0; i < parsedSteps.length - 1; i++)
            {
                auto currentStep = parsedSteps[i];
                if (currentStep.type == PathStepType.ObjectKey)
                {

                    if (currentJsonNodeToTraverse.type != JSONType.OBJECT)
                    {
                        return fail(message, format!"'%s' is not an object, so '%s' cannot be created."
                                (currentStep.key, jsonPath));
                    }

                    if (currentStep.key !in (*currentJsonNodeToTraverse).object)
                    {
                        (*currentJsonNodeToTraverse).object[currentStep.key] = JSONValue.emptyObject;
                    }

                    currentJsonNodeToTraverse = &(*currentJsonNodeToTraverse).object[currentStep.key];
                }
                else if (currentStep.type == PathStepType.ArrayIndex)
                {
                    return fail(message, format!"the path '%s' steps into an array; use APaddJsonItemARRAY."
                            (jsonPath));
                }
                else
                {
                    return fail(message, format!"the path '%s' contains a step this overload cannot follow."
                            (jsonPath));
                }

                if (currentJsonNodeToTraverse.type != JSONType.OBJECT)
                {
                    return fail(message, format!"'%s' is not an object, so '%s' cannot be created."
                            (currentStep.key, jsonPath));
                }

            }

            PathStep finalStep = parsedSteps[parsedSteps.length - 1];

            JSONValue convertedValue = CL_File_JSON.serializeToJson(item);

            if (finalStep.type != PathStepType.ObjectKey)
            {
                return fail(message, format!"the path '%s' must end with a new object key."(jsonPath));
            }
            if (currentJsonNodeToTraverse.type != JSONType.OBJECT)
            {
                return fail(message, format!"the parent of '%s' is not an object."(finalStep.key));
            }

            if (finalStep.key in (*currentJsonNodeToTraverse).object)
            {
                return fail(message, format!"the key '%s' already exists; use APupdateJsonValueOBJECT."
                        (finalStep.key));
            }

            (*currentJsonNodeToTraverse).object[finalStep.key] = convertedValue;

            if (!CL_FileAP.writeJsonFile(filePath, rootJson))
            {
                return fail(message, format!"the edited document could not be written to %s"(filePath));
            }

            return true;
        }
        catch (BaseExceptionAP e)
        {
            message = e.msg;
            return false;
        }
    }

    public static bool addJsonItemARRAY(T)(string filePath, string jsonPath, T item)
    {
        string ignoredMessage;
        return addJsonItemARRAY!T(filePath, jsonPath, item, ignoredMessage);
    }

    public static bool addJsonItemARRAY(T)(string filePath, string jsonPath, T item,
            out string message)
    {
        message = "";

        try
        {
            string[] checkStrIsNull = [filePath, jsonPath];

            if (CL_PublicCodeOtherCode.checkStringIsNull_array(checkStrIsNull))
            {
                return fail(message, "filePath and jsonPath cannot be null, empty or whitespace.");
            }

            if (!CL_FileAP.existsFile(filePath))
            {
                return fail(message, format!"the file does not exist: %s"(filePath));
            }

            auto readFile = CL_FileAP.readJsonFile!JSONValue(filePath);
            if (readFile.isNull)
            {
                return fail(message, format!"the file could not be read as JSON: %s"(filePath));
            }

            JSONValue rootJson = readFile.get;

            PathStep[] parsedSteps;
            parsedSteps = CL_JsonOtherCode.JsonPathParserAP(jsonPath);

            if (parsedSteps.length == 0)
            {
                return fail(message, format!"the JSON path '%s' could not be parsed."(jsonPath));
            }

            JSONValue* currentJsonNodeToTraverse = &rootJson;
            for (int i = 0; i < parsedSteps.length - 1; i++)
            {
                auto currentStep = parsedSteps[i];
                if (currentStep.type == PathStepType.ObjectKey)
                {
                    if (currentJsonNodeToTraverse.type != JSONType.OBJECT)
                    {
                        return fail(message, format!"'%s' is not an object, so '%s' cannot be reached."
                                (currentStep.key, jsonPath));
                    }
                    if (currentStep.key !in (*currentJsonNodeToTraverse).object)
                    {
                        (*currentJsonNodeToTraverse).object[currentStep.key] = JSONValue.emptyObject;
                    }
                    currentJsonNodeToTraverse = &(*currentJsonNodeToTraverse).object[currentStep.key];
                }
                else if (currentStep.type == PathStepType.ArrayIndex)
                {
                    if (currentJsonNodeToTraverse.type != JSONType.ARRAY)
                    {
                        return fail(message, format!"'%s' is not an array, so index %s is out of reach."
                                (currentStep.key, currentStep.index));
                    }
                    if (currentStep.index >= (*currentJsonNodeToTraverse).array.length)
                    {
                        return fail(message, format!"array index %s is out of range (length %s)."
                                (currentStep.index, (*currentJsonNodeToTraverse).array.length));
                    }
                    currentJsonNodeToTraverse = &(*currentJsonNodeToTraverse).array[currentStep.index];
                }
                else
                {
                    return fail(message, format!"the path '%s' contains a step this overload cannot follow."
                            (jsonPath));
                }

                if (currentJsonNodeToTraverse.type != JSONType.ARRAY
                        && currentJsonNodeToTraverse.type != JSONType.OBJECT)
                {
                    return fail(message, format!"'%s' is neither an object nor an array."(jsonPath));
                }
            }

            PathStep finalStep = parsedSteps[parsedSteps.length - 1];

            JSONValue convertValue = CL_File_JSON.serializeToJson(item);

            if (finalStep.type == PathStepType.ObjectKey)
            {
                // The type guard must run first: JSONValue.object enforces the
                // type itself and would throw out of this bool-returning API.
                if (currentJsonNodeToTraverse.type != JSONType.OBJECT)
                {
                    return fail(message, format!"the parent of '%s' is not an object."(finalStep.key));
                }
                if (finalStep.key in (*currentJsonNodeToTraverse).object)
                {
                    return fail(message, format!"the key '%s' already exists in this object."
                            (finalStep.key));
                }
                (*currentJsonNodeToTraverse).object[finalStep.key] = convertValue;
            }
            else if (finalStep.type == PathStepType.ArrayIndex)
            {
                if (currentJsonNodeToTraverse.type != JSONType.ARRAY)
                {
                    return fail(message, format!"the parent of index %s is not an array."
                            (finalStep.index));
                }
                // index == length is the append position, so "add" can extend
                // the array; only an index past the end is out of range.
                if (finalStep.index > (*currentJsonNodeToTraverse).array.length)
                {
                    return fail(message, format!"array index %s is past the end (length %s); the new item is appended."
                            (finalStep.index, (*currentJsonNodeToTraverse).array.length));
                }

                (*currentJsonNodeToTraverse).array ~= convertValue;
            }
            else
            {
                return fail(message, format!"the path '%s' ends with a step this overload cannot use."
                        (jsonPath));
            }

            if (!CL_FileAP.writeJsonFile(filePath, rootJson))
            {
                return fail(message, format!"the edited document could not be written to %s"(filePath));
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
