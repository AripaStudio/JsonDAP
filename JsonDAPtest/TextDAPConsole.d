module TextDAPConsole;

import JsonDAP;
import TextDAPFrame;
import std.conv;
import std.format;
import std.stdio;
import std.string;
import std.typecons;

alias Optional = Nullable;

public class CL_TextDap_Console
{
    public static void sayDone(string message)
    {
        writeln(format!"  [ok] %s"(message));
    }

    public static void sayNote(string message)
    {
        writeln(format!"  -- %s"(message));
    }

    public static void sayFail(string message)
    {
        writeln(format!"  [!!] %s"(message));
    }

    public static void sayLine(string message)
    {
        writeln("   " ~ message);
    }

    public static string ask(string prompt)
    {
        write(prompt);
        stdout.flush();

        string line = readln();
        if (line is null)
        {
            return null;
        }

        return strip(line);
    }

    public static Optional!int askNumber(string prompt, int low, int high)
    {
        string raw = ask(prompt);
        if (raw is null)
        {
            return Optional!int.init;
        }

        bool blankFlag;
        string blankReason;
        JsonAP.APstrIsNil(raw, "number", blankFlag, blankReason);

        if (blankFlag)
        {
            sayFail(blankReason);
            return Optional!int.init;
        }

        if (!JsonAP.APisInteger(raw))
        {
            sayFail(format!"'%s' is not a whole number."(raw));
            return Optional!int.init;
        }

        if (!isPlainAsciiDigits(raw))
        {
            sayFail("Only the ASCII digits 0-9 are accepted here.");
            return Optional!int.init;
        }

        int value;
        try
        {
            value = to!int(raw);
        }
        catch (Exception caught)
        {
            sayFail(format!"'%s' is too large to be a line number."(raw));
            return Optional!int.init;
        }

        if (value < low || value > high)
        {
            sayFail(format!"%s is outside the allowed range %d-%d."(raw, low, high));
            return Optional!int.init;
        }

        return Optional!int(value);
    }

    public static Optional!string askText(string prompt)
    {
        string raw = ask(prompt);
        if (raw is null)
        {
            return Optional!string.init;
        }

        bool blankFlag;
        string blankReason;
        JsonAP.APstrIsNil(raw, "text", blankFlag, blankReason);

        if (blankFlag)
        {
            sayFail(blankReason);
            return Optional!string.init;
        }

        return Optional!string(raw);
    }

    public static bool askYes(string prompt)
    {
        string raw = ask(prompt);
        if (raw is null)
        {
            return false;
        }

        return !raw.empty && (raw[0] == 'y' || raw[0] == 'Y');
    }

    public static string yesNo(bool value)
    {
        return value ? "yes" : "no";
    }

    public static string countWord(long count, string singular)
    {
        return count == 1 ? format!"%d %s"(count, singular) : format!"%d %ss"(count, singular);
    }

    public static bool isPlainAsciiDigits(string text)
    {
        if (text is null || text.empty)
        {
            return false;
        }

        string digits = (text[0] == '-' || text[0] == '+') ? text[1 .. $] : text;

        if (digits.empty)
        {
            return false;
        }

        foreach (unit; digits)
        {
            if (unit < '0' || unit > '9')
            {
                return false;
            }
        }

        return true;
    }
}
