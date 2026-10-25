module TextDAPJsonTools;

import JsonDAP;
import TextDAPConsole;
import TextDAPFrame;
import TextDAPScalar;
import std.array : array;
import std.conv;
import std.file;
import std.format;
import std.json;
import std.string;

public class CL_TextDap_JsonTools
{
    public static bool describeFile(string filePath)
    {
        string text;
        if (!readDocument(filePath, text))
        {
            return false;
        }

        Optional!long items = JsonAP.APgetJsonItemCount(text);

        CL_TextDap_Frame.showFrame("JSON document", [
                CL_TextDap_Frame.fieldText("file", filePath),
                CL_TextDap_Frame.fieldText("bytes", sizeText(filePath)),
                CL_TextDap_Frame.fieldText("shape", shapeOf(text)),
                CL_TextDap_Frame.fieldText("items", items.isNull ? "unknown" : to!string(items.get)),
            ]);

        return inspectRoot(filePath);
    }

    public static bool validateText(string jsonContent)
    {
        string blankReason;
        bool blankFlag;
        JsonAP.APStrIsNUll(jsonContent, "json", blankFlag, blankReason);

        if (blankFlag)
        {
            CL_TextDap_Console.sayFail(blankReason);
            return false;
        }

        if (!JsonAP.APisValidJson(jsonContent))
        {
            CL_TextDap_Console.sayFail("this text is not valid JSON.");
            return false;
        }

        Optional!long items = JsonAP.APgetJsonItemCount(jsonContent);
        Optional!string pretty = JsonAP.APprettyPrintJson(jsonContent);

        CL_TextDap_Frame.showFrame("valid JSON", [
                CL_TextDap_Frame.fieldText("shape", shapeOf(jsonContent)),
                CL_TextDap_Frame.fieldText("items", items.isNull ? "none" : to!string(items.get)),
                CL_TextDap_Frame.fieldText("pretty", pretty.isNull ? "not produced"
                        : CL_TextDap_Frame.clip(replace(pretty.get, "\n", " "), 52)),
            ]);

        return true;
    }

    public static bool explainPath(string jsonPath)
    {
        string blankReason;
        bool blankFlag;
        JsonAP.APStrIsNUll(jsonPath, "path", blankFlag, blankReason);

        if (blankFlag)
        {
            CL_TextDap_Console.sayFail(blankReason);
            return false;
        }

        if (!CL_TextDap_Console.holdsIndexBrackets(jsonPath))
        {
            CL_TextDap_Console.sayFail(format!"'%s' has a broken index, a bracket needs ASCII digits inside."
                    (jsonPath));
            return false;
        }

        try
        {
            PathStep[] steps = JsonAP.APJsonPathParser(jsonPath);

            if (steps.length == 0)
            {
                CL_TextDap_Console.sayFail(format!"'%s' resolved to no steps."(jsonPath));
                return false;
            }

            string[] rows;
            foreach (index, step; steps)
            {
                rows ~= format!"%d. %s"(index + 1, stepText(step));
            }

            CL_TextDap_Frame.showFrame(format!"path '%s'"(jsonPath), rows);
            return true;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return false;
        }
    }

    public static bool readValueAt(string filePath, string dotPath, string kind)
    {
        if (!CL_TextDap_Console.holdsIndexBrackets(dotPath))
        {
            CL_TextDap_Console.sayFail(format!"'%s' has a broken index, a bracket needs ASCII digits inside."
                    (dotPath));
            return false;
        }

        string text;
        if (!readDocument(filePath, text))
        {
            return false;
        }

        try
        {
            if (kind == scalarKindText)
            {
                reportValue(JsonAP.APgetJsonValue!string(text, dotPath), dotPath);
                return true;
            }
            if (kind == scalarKindWhole)
            {
                reportValue(JsonAP.APgetJsonValue!long(text, dotPath), dotPath);
                return true;
            }
            if (kind == scalarKindNumber)
            {
                reportValue(JsonAP.APgetJsonValue!double(text, dotPath), dotPath);
                return true;
            }
            if (kind == scalarKindFlag)
            {
                reportValue(JsonAP.APgetJsonValue!bool(text, dotPath), dotPath);
                return true;
            }

            CL_TextDap_Console.sayFail(CL_TextDap_Scalar.unknownKindText(kind));
            return false;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return false;
        }
    }

    public static string sizeText(string filePath)
    {
        try
        {
            Optional!long size = JsonAP.APgetJsonFileSize(filePath);
            return size.isNull ? "unknown" : to!string(size.get);
        }
        catch (BaseExceptionAP)
        {
            return "unknown";
        }
    }

    private static bool inspectRoot(string filePath)
    {
        try
        {
            auto read = JsonAP.APreadJsonFile!JSONValue(filePath);
            if (read.isNull)
            {
                CL_TextDap_Console.sayFail("the document could not be opened for reading.");
                return false;
            }

            if (read.get.type != JSONType.OBJECT)
            {
                CL_TextDap_Console.sayNote(format!"the root is %s, so there are no member names to list."
                        (JsonAP.APgetJsonValueType(read.get)));
                return true;
            }

            foreach (key; read.get.object.byKey.array)
            {
                CL_TextDap_Console.sayLine(CL_TextDap_Frame.fieldText(key,
                        to!string(JsonAP.APgetJsonValueType(read.get.object[key]))));
            }

            return true;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return false;
        }
    }

    private static bool readDocument(string filePath, out string text)
    {
        string blankReason;
        bool blankFlag;
        JsonAP.APStrIsNUll(filePath, "file path", blankFlag, blankReason);

        if (blankFlag)
        {
            CL_TextDap_Console.sayFail(blankReason);
            return false;
        }

        if (!JsonAP.APexistsFile(filePath))
        {
            CL_TextDap_Console.sayFail(format!"there is no file at %s"(filePath));
            return false;
        }

        try
        {
            text = readText(filePath);
        }
        catch (Exception caught)
        {
            CL_TextDap_Console.sayFail(format!"%s could not be read: %s"(filePath, caught.msg));
            return false;
        }

        if (!JsonAP.APisValidJson(text))
        {
            CL_TextDap_Console.sayFail(format!"%s is not a JSON document."(filePath));
            return false;
        }

        return true;
    }

    private static string shapeOf(string jsonContent)
    {
        if (JsonAP.APisJsonObject(jsonContent))
        {
            return "object";
        }
        if (JsonAP.APisJsonArray(jsonContent))
        {
            return "array";
        }
        if (JsonAP.APisJsonNumber(jsonContent))
        {
            return "number";
        }
        if (JsonAP.APisJsonString(jsonContent))
        {
            return "string";
        }

        return "other";
    }

    private static string stepText(PathStep step)
    {
        if (step.type == PathStepType.ObjectKey)
        {
            return format!"object key '%s'"(step.key);
        }

        return format!"array index %d"(step.index);
    }

    private static void reportValue(V)(Optional!V found, string dotPath)
    {
        if (found.isNull)
        {
            CL_TextDap_Console.sayFail(format!"'%s' holds no %s value."(dotPath, V.stringof));
            return;
        }

        CL_TextDap_Console.sayDone(format!"%s = %s"(dotPath, to!string(found.get)));
    }
}
