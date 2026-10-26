module TextDAPJsonEdit;

import JsonDAP;
import TextDAPConsole;
import TextDAPScalar;
import std.format;
import std.json;
import std.typecons;

alias Optional = Nullable;

public class CL_TextDap_JsonEdit
{
    public static bool addValueAt(string filePath, string jsonPath, string kind, string raw,
            out string message)
    {
        Optional!bool shape = itemShape(jsonPath, message);

        if (shape.isNull)
        {
            return false;
        }

        bool written = CL_TextDap_Scalar.addValue(shape.get, filePath, jsonPath, kind, raw, message);

        if (written)
        {
            CL_TextDap_Console.sayDone(format!"'%s' was added to %s"(jsonPath, filePath));
        }

        return written;
    }

    public static bool updateValueAt(string filePath, string jsonPath, string kind, string raw,
            out string message)
    {
        Optional!bool shape = itemShape(jsonPath, message);

        if (shape.isNull)
        {
            return false;
        }

        bool written = CL_TextDap_Scalar.updateValue(shape.get, filePath, jsonPath, kind, raw, message);

        if (written)
        {
            CL_TextDap_Console.sayDone(format!"'%s' now holds %s"(jsonPath, raw));
        }

        return written;
    }

    public static bool deleteAt(string filePath, string jsonPath, out string message)
    {
        Optional!bool shape = itemShape(jsonPath, message);

        if (shape.isNull)
        {
            return false;
        }

        bool removed;

        if (shape.get)
        {
            removed = JsonAP.APremoveJsonItemARRAYWithMessage(filePath, jsonPath, message);
        }
        else
        {
            removed = JsonAP.APremoveJsonItemOBJECTWithMessage(filePath, jsonPath, message);
        }

        if (removed)
        {
            CL_TextDap_Console.sayDone(format!"'%s' was removed from %s"(jsonPath, filePath));
        }

        return removed;
    }

    public static bool mergeFiles(string targetPath, string sourcePath, bool overwriteExisting,
            bool mergeArrays, out string message)
    {
        message = "";

        try
        {
            auto source = JsonAP.APreadJsonFile!JSONValue(sourcePath);
            if (source.isNull)
            {
                message = format!"%s did not read as a JSON document."(sourcePath);
                return false;
            }

            bool merged = JsonAP.APmergeJsonWithMessage(targetPath, source.get,
                    overwriteExisting, mergeArrays, message);

            if (merged)
            {
                CL_TextDap_Console.sayDone(format!"%s was merged into %s"(sourcePath, targetPath));
            }

            return merged;
        }
        catch (BaseExceptionAP caught)
        {
            message = caught.msg;
            return false;
        }
    }

    private static Optional!bool itemShape(string jsonPath, out string message)
    {
        message = "";

        string blankReason;
        bool blankFlag;
        JsonAP.APstrIsNil(jsonPath, "json path", blankFlag, blankReason);

        if (blankFlag)
        {
            message = blankReason;
            return Optional!bool.init;
        }

        PathStep[] steps;

        try
        {
            steps = JsonAP.APJsonPathParser(jsonPath);
        }
        catch (BaseExceptionAP caught)
        {
            message = caught.msg;
            return Optional!bool.init;
        }

        if (steps.length == 0)
        {
            message = format!"'%s' names no member or item."(jsonPath);
            return Optional!bool.init;
        }

        return Optional!bool(steps[$ - 1].type == PathStepType.ArrayIndex);
    }
}
