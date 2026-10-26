module PublicCodeOtherCode;

import std.json;
import std.typecons;
import std.stdio;
import std.conv;
import std.string;
import std.array;
import std.exception;
import ExceptionAP;
import jsonOtherCodeAP;


alias Optional = Nullable;

public class CL_PublicCodeOtherCode
{
    public static dchar toAsciiDigit(dchar c) @safe pure nothrow
    {
        if (c >= '0' && c <= '9')
            return c;
        if (c >= '۰' && c <= '۹')
            return cast(dchar)('0' + (c - '۰')); // Persian Unicode 
        if (c >= '٠' && c <= '٩')
            return cast(dchar)('0' + (c - '٠')); // Arabic Unicode 
        return c;
    }

    public static dchar normalizeSymbolAP(dchar c) @safe pure nothrow
    {
        if (c == '٫')
            return '.';
        if (c == '−')
            return '-';
        return c;
    }

    public static string normalizeDigitsAP(string s) @safe pure
    {
        import std.array : appender;

        auto result = appender!string();
        foreach (dchar c; s)
        {
              result.put(toAsciiDigit(normalizeSymbolAP(c)));
        }
        return result.data;
    }

    public static bool isDigitAP(dchar c) @safe pure nothrow
    {
        dchar a = toAsciiDigit(c);
        return a >= '0' && a <= '9';
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

    public static bool isSignedInteger(string s) @safe pure
    {
        string t = normalizeDigitsAP(s);
        if (t.empty)
            return false;
        if (t[0] == '+' || t[0] == '-')
            t = t[1 .. $];
        return isInteger(t);
    }

    public static bool isDecimal(string s) @safe pure
    {
        import std.array : split;

        string t = normalizeDigitsAP(s);
        if (t.length > 0 && (t[0] == '+' || t[0] == '-'))
            t = t[1 .. $];

        auto parts = t.split('.');
        if (parts.length != 2)
            return false;
        return isInteger(parts[0]) && isInteger(parts[1]);
    }

    public static void strIsNil(string input, string paramName = "input",
            out bool outputBool, out string reason)
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
            reason = "";
        }
        catch (Exception e)
        {
            outputBool = true;
            reason = e.msg;
        }
    }

    deprecated("Use strIsNil; the old spelling mixed the case of Null and named its message PascalCase.")
    public static void StrIsNUll(string input, string paramName = "input",
            out bool outputBool, out string errorText)
    {
        strIsNil(input, paramName, outputBool, errorText);
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
        foreach (index, input; inputs)
        {
            string errorText;
            bool isNull;
            string paramName = "input[" ~ to!string(index) ~ "]";
            CL_PublicCodeOtherCode.strIsNil(input, paramName, isNull, errorText);
            if (isNull)
            {
                paramNames.put(format!" -- New ParamName : %s -- "(paramName));
                errorTexts.put(format!"-- New ErrorText : %s --"(errorText));
                foundError = true;
            }
        }
        if (foundError)
        {
            throw new UnknownErrorExceptionAP(
                    "Unknown error: " ~ errorTexts.data ~ " |__| Like input : ~ " ~ paramNames.data ~ " |____| ",
                    __FILE__, __LINE__);
        }
        return false;

    }

    public static PathStep[] parsePath(string path)
    {
        import std.array : appender;
        import std.string : strip;

        if (path is null || path.strip.empty)
        {
            throw new InvalidArgumentExceptionAP("JSON path is empty.", "path", path,
                    "non-empty path", __FILE__, __LINE__);
        }

        dchar[] cs = path.to!(dchar[]);
        PathStep[] steps;
        auto key = appender!(dchar[])();
        bool afterIndex = false;

        void endKey(bool allowEmpty)
        {
            if (key.data.length == 0)
            {
                if (allowEmpty)
                {
                    return;
                }
                throw new InvalidArgumentExceptionAP("JSON path contains an empty key.",
                        "path", path, "non-empty key", __FILE__, __LINE__);
            }
            PathStep step;
            step.type = PathStepType.ObjectKey;
            step.key = key.data.to!string;
            steps ~= step;
            key = appender!(dchar[])();
        }

        size_t i = 0;
        while (i < cs.length)
        {
            dchar c = cs[i];

            if (c == '\\')
            {
                if (i + 1 >= cs.length)
                {
                    throw new InvalidArgumentExceptionAP("JSON path ends with an incomplete escape.",
                            "path", path, "escape followed by a character", __FILE__, __LINE__);
                }
                key.put(cs[i + 1]);
                afterIndex = false;
                i += 2;
            }
            else if (c == '.')
            {
                if (!afterIndex)
                {
                    endKey(false);
                }
                afterIndex = false;
                i++;
            }
            else if (c == '[')
            {
                endKey(true);
                size_t close = i + 1;
                while (close < cs.length && cs[close] != ']')
                {
                    close++;
                }
                if (close >= cs.length)
                {
                    throw new InvalidArgumentExceptionAP("JSON path has a missing closing bracket.",
                            "path", path, "]", __FILE__, __LINE__);
                }

                steps ~= makeIndexStep(cs[i + 1 .. close].to!string, path);
                i = close + 1;
                afterIndex = true;

                if (i < cs.length && cs[i] != '.' && cs[i] != '[')
                {
                    throw new InvalidArgumentExceptionAP("Unexpected character after ']'.",
                            "path", path, ". or [", __FILE__, __LINE__);
                }
            }
            else if (c == ']')
            {
                throw new InvalidArgumentExceptionAP("JSON path has a ']' without '['.",
                        "path", path, "[", __FILE__, __LINE__);
            }
            else
            {
                key.put(c);
                afterIndex = false;
                i++;
            }
        }

        endKey(afterIndex);
        return steps;
    }

    private static PathStep makeIndexStep(string text, string path)
    {
        string norm = normalizeDigitsAP(text);
        if (!isInteger(norm))
        {
            throw new InvalidArgumentExceptionAP("array index must be a non-negative integer.",
                    "index", text, "0, 1, 2, ...", __FILE__, __LINE__);
        }

        PathStep step;
        step.type = PathStepType.ArrayIndex;
        try
        {
            step.index = norm.to!int;
        }
        catch (ConvException e)
        {
            throw new ConvertExceptionAP("Array index is too large.", "index", text,
                    "string", "int", "parsePath", e.msg, __FILE__, __LINE__, e);
        }
        return step;
    }

}
