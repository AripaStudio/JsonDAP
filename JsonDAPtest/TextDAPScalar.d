module TextDAPScalar;

import JsonDAP;
import TextDAPConsole;
import std.array : join;
import std.conv;
import std.format;
import std.json;
import std.string;

public enum scalarKindText = "text";
public enum scalarKindWhole = "whole";
public enum scalarKindNumber = "number";
public enum scalarKindFlag = "flag";

public class CL_TextDap_Scalar
{
    public static string[] kindNames()
    {
        return [scalarKindText, scalarKindWhole, scalarKindNumber, scalarKindFlag];
    }

    public static string unknownKindText(string kind)
    {
        return format!"'%s' is not one of %s."(kind, join(kindNames(), ", "));
    }

    public static bool addValue(bool itemFlag, string filePath, string jsonPath, string kind,
            string raw, out string message)
    {
        if (kind == scalarKindText)
        {
            return addAt!string(itemFlag, filePath, jsonPath, raw, message);
        }
        if (kind == scalarKindWhole)
        {
            Optional!long whole = parseWhole(raw);

            if (whole.isNull)
            {
                message = notWholeText(raw);
                return false;
            }

            return addAt!long(itemFlag, filePath, jsonPath, whole.get, message);
        }
        if (kind == scalarKindNumber)
        {
            Optional!double number = parseNumber(raw);

            if (number.isNull)
            {
                message = notNumberText(raw);
                return false;
            }

            return addAt!double(itemFlag, filePath, jsonPath, number.get, message);
        }
        if (kind == scalarKindFlag)
        {
            Optional!bool flag = parseFlag(raw);

            if (flag.isNull)
            {
                message = notFlagText(raw);
                return false;
            }

            return addAt!bool(itemFlag, filePath, jsonPath, flag.get, message);
        }

        message = unknownKindText(kind);
        return false;
    }

    public static bool updateValue(bool itemFlag, string filePath, string jsonPath, string kind,
            string raw, out string message)
    {
        if (kind == scalarKindText)
        {
            return updateAt!string(itemFlag, filePath, jsonPath, raw, message);
        }
        if (kind == scalarKindWhole)
        {
            Optional!long whole = parseWhole(raw);

            if (whole.isNull)
            {
                message = notWholeText(raw);
                return false;
            }

            return updateAt!long(itemFlag, filePath, jsonPath, whole.get, message);
        }
        if (kind == scalarKindNumber)
        {
            Optional!double number = parseNumber(raw);

            if (number.isNull)
            {
                message = notNumberText(raw);
                return false;
            }

            return updateAt!double(itemFlag, filePath, jsonPath, number.get, message);
        }
        if (kind == scalarKindFlag)
        {
            Optional!bool flag = parseFlag(raw);

            if (flag.isNull)
            {
                message = notFlagText(raw);
                return false;
            }

            return updateAt!bool(itemFlag, filePath, jsonPath, flag.get, message);
        }

        message = unknownKindText(kind);
        return false;
    }

    public static string notWholeText(string raw)
    {
        return format!"'%s' is not a whole number."(raw);
    }

    public static string notNumberText(string raw)
    {
        return format!"'%s' is not a decimal number."(raw);
    }

    public static string notFlagText(string raw)
    {
        return format!"'%s' is neither true nor false."(raw);
    }

    public static Optional!long parseWhole(string raw)
    {
        if (!CL_TextDap_Console.isPlainAsciiDigits(raw) || !JsonAP.APisInteger(raw))
        {
            return Optional!long.init;
        }

        try
        {
            return Optional!long(to!long(raw));
        }
        catch (Exception)
        {
            return Optional!long.init;
        }
    }

    public static Optional!double parseNumber(string raw)
    {
        try
        {
            return Optional!double(to!double(raw));
        }
        catch (Exception)
        {
            return Optional!double.init;
        }
    }

    public static Optional!bool parseFlag(string raw)
    {
        string word = toLower(strip(raw));

        if (word == "true" || word == "yes")
        {
            return Optional!bool(true);
        }
        if (word == "false" || word == "no")
        {
            return Optional!bool(false);
        }

        return Optional!bool.init;
    }

    private static bool addAt(V)(bool itemFlag, string filePath, string jsonPath, V value,
            out string message)
    {
        if (itemFlag)
        {
            return JsonAP.APaddJsonItemARRAYWithMessage!V(filePath, jsonPath, value, message);
        }

        return JsonAP.APaddJsonItemOBJECTWithMessage!V(filePath, jsonPath, value, message);
    }

    private static bool updateAt(V)(bool itemFlag, string filePath, string jsonPath, V value,
            out string message)
    {
        if (itemFlag)
        {
            return JsonAP.APupdateJsonValueARRAYWithMessage!V(filePath, jsonPath, value, message);
        }

        return JsonAP.APupdateJsonValueOBJECTWithMessage!V(filePath, jsonPath, value, message);
    }
}
