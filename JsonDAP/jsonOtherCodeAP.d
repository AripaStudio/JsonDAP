module jsonOtherCodeAP;

import ExceptionAP;
import std.stdio;
import std.string;
import std.algorithm;
import std.range;
import std.array;
import PublicCodeOtherCode;
import std.conv;
import std.exception;
import std.json;
import CheckVariablesAP;

public static enum PathStepType
{
    ObjectKey,
    ArrayIndex
}

public static struct PathStep
{
    PathStepType type;
    union
    {
        string key;
        int index;
    }
}

public class CL_JsonOtherCode
{

    public static PathStep[] JsonPathParserAP(string input)
    {
        string errorTextStrIsNull;
        bool CheckStrIsNull;
        CL_PublicCodeOtherCode.StrIsNUll(input, "input", CheckStrIsNull, errorTextStrIsNull);
        if (CheckStrIsNull)
        {
            throw new UnknownErrorexceptionAP("Unknown error." ~ errorTextStrIsNull ~ " |____|  ",
                    __FILE__, __LINE__);
        }

        PathStep[] pathSteps;
        int currentIndex = 0;

        foreach (part; input.splitter('.'))
        {
            if (part.empty)
                continue;

            auto bracketPos = part.indexOf('[');

            if (bracketPos == -1)
            {
                PathStep newStep;
                newStep.type = PathStepType.ObjectKey;
                newStep.key = part;
                pathSteps ~= newStep;
            }
            else
            {
                string keyPart = part[0 .. bracketPos];
                if (!keyPart.empty)
                {
                    PathStep keyStep;
                    keyStep.type = PathStepType.ObjectKey;
                    keyStep.key = keyPart;
                    pathSteps ~= keyStep;
                }

                string remaining = part[bracketPos .. $];
                while (remaining.startsWith('['))
                {
                    auto closing = remaining.indexOf(']');
                    if (closing == -1)
                        throw new UnknownErrorexceptionAP("Syntax Error: Missing closing bracket.",
                                __FILE__, __LINE__);

                    string indexStr = remaining[1 .. closing];

                    PathStep indexStep;
                    indexStep.type = PathStepType.ArrayIndex;
                    try
                    {
                        indexStep.index = to!int(CL_PublicCodeOtherCode.normalizeDigitsAP(indexStr));
                    }
                    catch (Exception e)
                    {
                        throw new ConvertExceptionAP("Failed to convert index.", "indexStr", indexStr,
                                "string", "int", "to!int", e.msg, __FILE__, __LINE__, e);
                    }
                    pathSteps ~= indexStep;

                    remaining = remaining[closing + 1 .. $];
                }
            }
        }

        return pathSteps;
    }

    public static bool recursiveMerge(ref JSONValue target, ref JSONValue source,
            bool overwrite, bool mergeArrays, out string message)
    {
        if (source == JSONValue.init)
        {
            return false;
        }
        if (target == JSONValue.init)
        {
            if (overwrite)
            {
                message = "Target is uninitialized, overwriting with source.";
                target = source;
                return true;
            }
            else
            {
                return false;
            }
        }

        if (source.type == JSONType.TRUE || source.type == JSONType.FALSE
                || source.type == JSONType.INTEGER
                || source.type == JSONType.STRING || source.type == JSONType.NULL)
        {
            if (overwrite)
            {
                message = "Source is a primitive type, overwriting target.";
                target = source;
                return true;
            }
            else
            {
                return false;
            }
        }

        if (source.type == JSONType.OBJECT && target.type == JSONType.OBJECT)
        {
            foreach (key, value; source.object)
            {
                if (key in target.object)
                {
                    string msg;
                    recursiveMerge(target.object[key], value, overwrite, mergeArrays, msg);
                }
                else
                {
                    target.object[key] = value;
                }
            }
            return true;
        }
        else if (source.type == JSONType.ARRAY && target.type == JSONType.ARRAY)
        {
            if (mergeArrays)
            {
                size_t newSize = target.array.length + source.array.length;
                target.array.reserve(newSize);
                target.array ~= source.array;
                return true;
            }
            else
            {
                message = "Target and source are arrays, but array merging is disabled. Overwriting target.";
                target = source;
                return true;
            }
        }
        else if (target.type == JSONType.ARRAY && source.type != JSONType.ARRAY)
        {
            if (overwrite)
            {
                message = "Target is an array, source is not. Overwriting target with source.";
                target = source;
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            if (overwrite)
            {
                message = "Target and source types are incompatible. Overwriting target with source.";
                target = source;
                return true;
            }
            else
            {
                return false;
            }
        }
    }
}
