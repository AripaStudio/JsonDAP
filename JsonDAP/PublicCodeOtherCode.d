module PublicCodeOtherCode;

import std.json;
import std.typecons;
import std.stdio;
import std.conv;
import std.string;
import std.array;
import std.exception;
import ExceptionAP;

alias Optional = Nullable;

public class CL_PublicCodeOtherCode
{
    public static bool isDigitAP(dchar c) @safe pure nothrow
    {
        return (c >= '0' && c <= '9') || (c >= '۰' && c <= '۹');
    }

    public static bool isInteger(string s) @safe pure
    {
        if (s.empty)
            return false;

        foreach (dchar c; s)
        {
            if (!isDigitAP(c))
            {
                return false;
            }
        }
        return true;
    }

    public static void StrIsNUll(string input, string paramName = "input",
            out bool outputBool, out string ErrorText)
    {
        try
        {
            if (input is null)
            {
                throw new InvalidArgumentExceptionAP("Parameter '" ~ paramName ~ "' cannot be null.",
                        paramName, "null");
            }
            if (input.empty)
            {
                throw new InvalidArgumentExceptionAP("Parameter '" ~ paramName ~ "' cannot be empty.",
                        paramName, "''");
            }
            if (input.strip.empty)
            {
                throw new InvalidArgumentExceptionAP("Parameter '" ~ paramName ~ "' cannot be just whitespace.",
                        paramName, "'" ~ input ~ "'");
            }
            outputBool = false;
            ErrorText = "";
        }
        catch (Exception e)
        {
            outputBool = true;
            ErrorText = e.msg;
        }
    }

    public static bool checkStringIsNull_array(string[] inputs)
    {

        if (inputs.length == 0)
        {
            return true;
        }
        auto paramNames = appender!string();
        auto errorTexts = appender!string();
        bool foundError = false;
        foreach (input; inputs)
        {
            string errorText;
            bool isNull;
            string paramName;
            CL_PublicCodeOtherCode.StrIsNUll(input, paramName, isNull, errorText);
            if (isNull)
            {
                paramNames.put(format!" -- New ParamName : %s -- "(paramName));
                errorTexts.put(format!"-- New ErrorText : %s --"(errorText));
                foundError = true;
            }
        }
        if (foundError)
        {
            throw new UnknownErrorexceptionAP(
                    "Unknown error: " ~ errorTexts.data ~ " |__| Like input : ~ " ~ paramNames.data ~ " |____| ",
                    __FILE__, __LINE__);
        }
        return false;

    }

}
