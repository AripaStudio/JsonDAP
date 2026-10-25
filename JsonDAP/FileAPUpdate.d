module FileAPUpdate;

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

public static class CL_FileAP_Update
{
    public static bool updateJsonValueOBJECT(V)(string filePath, string jsonPath, V value)
    {
        string ignoredMessage;
        return updateJsonValueOBJECT!V(filePath, jsonPath, value, ignoredMessage);
    }

    public static bool updateJsonValueOBJECT(V)(string filePath, string jsonPath, V value,
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

            //For example for jsonPath: main.name.khashayar\t\t
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
                        return fail(message, format!"the path '%s' does not exist: key '%s' is missing."
                                (jsonPath, currentStep.key));
                    }
                    currentJsonNodeToTraverse = &(*currentJsonNodeToTraverse).object[currentStep.key];
                }
                else if (currentStep.type == PathStepType.ArrayIndex)
                {
                    return fail(message, format!"the path '%s' steps into an array; use APupdateJsonValueARRAY."
                            (jsonPath));
                }
                else
                {
                    return fail(message, format!"the path '%s' contains a step this overload cannot follow."
                            (jsonPath));
                }

                if (currentJsonNodeToTraverse.type != JSONType.OBJECT)
                {
                    return fail(message, format!"'%s' is not an object, so '%s' cannot be reached."
                            (currentStep.key, jsonPath));
                }
            }

            PathStep finalStep = parsedSteps[parsedSteps.length - 1];

            auto convertValue = CL_File_JSON.serializeToJson(value);
            if (finalStep.type != PathStepType.ObjectKey)
            {
                return fail(message, format!"the path '%s' must end with an object key."(jsonPath));
            }
            if (currentJsonNodeToTraverse.type != JSONType.OBJECT)
            {
                return fail(message, format!"the parent of '%s' is not an object."(finalStep.key));
            }
            (*currentJsonNodeToTraverse).object[finalStep.key] = convertValue;

            auto writeFile = CL_FileAP.writeJsonFile(filePath, rootJson);
            if (!writeFile)
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

    public static bool updateJsonValueARRAY(V)(string filePath, string jsonPath, V value)
    {
        string ignoredMessage;
        return updateJsonValueARRAY!V(filePath, jsonPath, value, ignoredMessage);
    }

    public static bool updateJsonValueARRAY(V)(string filePath, string jsonPath, V value,
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
                        return fail(message, format!"the path '%s' does not exist: key '%s' is missing."
                                (jsonPath, currentStep.key));
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

                if (currentJsonNodeToTraverse.type != JSONType.OBJECT
                        && currentJsonNodeToTraverse.type != JSONType.ARRAY)
                {
                    return fail(message, format!"'%s' is neither an object nor an array."(jsonPath));
                }
            }

            PathStep finalStep = parsedSteps[parsedSteps.length - 1];

            JSONValue convertValue = CL_File_JSON.serializeToJson(value);

            if (finalStep.type == PathStepType.ObjectKey)
            {
                if (currentJsonNodeToTraverse.type != JSONType.OBJECT)
                {
                    return fail(message, format!"the parent of '%s' is not an object."(finalStep.key));
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
                if (finalStep.index >= (*currentJsonNodeToTraverse).array.length)
                {
                    return fail(message, format!"array index %s is out of range (length %s)."
                            (finalStep.index, (*currentJsonNodeToTraverse).array.length));
                }
                (*currentJsonNodeToTraverse).array[finalStep.index] = convertValue;
            }
            else
            {
                return fail(message, format!"the path '%s' ends with a step this overload cannot use."
                        (jsonPath));
            }

            auto writeFile = CL_FileAP.writeJsonFile(filePath, rootJson);
            if (!writeFile)
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
