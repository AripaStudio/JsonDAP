module TextDAPFileStore;

import JsonDAP;
import TextDAPConsole;
import std.array : join;
import std.conv;
import std.file;
import std.format;
import std.string : splitLines;
import std.typecons;

alias Optional = Nullable;

public class CL_TextDap_Store
{
    public static Optional!(string[]) readLines(string path)
    {
        string blankReason;
        bool blankFlag;
        JsonAP.APstrIsNil(path, "file path", blankFlag, blankReason);

        if (blankFlag)
        {
            CL_TextDap_Console.sayFail(blankReason);
            return Optional!(string[]).init;
        }

        if (!exists(path))
        {
            return Optional!(string[]).init;
        }

        try
        {
            return Optional!(string[])(splitLines(readText(path)));
        }
        catch (Exception caught)
        {
            CL_TextDap_Console.sayFail(format!"the file could not be read: %s"(caught.msg));
            return Optional!(string[]).init;
        }
    }

    public static bool writeLines(string path, string[] lines)
    {
        string blankReason;
        bool blankFlag;
        JsonAP.APstrIsNil(path, "target file path", blankFlag, blankReason);

        if (blankFlag)
        {
            CL_TextDap_Console.sayFail(blankReason);
            return false;
        }

        try
        {
            std.file.write(path, join(lines, "\n"));
            return true;
        }
        catch (Exception caught)
        {
            CL_TextDap_Console.sayFail(format!"the file could not be written: %s"(caught.msg));
            return false;
        }
    }

    public static bool exists(string path)
    {
        if (JsonAP.APexistsFile(path))
        {
            return true;
        }

        CL_TextDap_Console.sayFail(format!"there is no file at %s"(path));
        return false;
    }

    public static Optional!long measureBytes(string path)
    {
        try
        {
            Optional!long bytes = JsonAP.APgetJsonFileSize(path);

            if (bytes.isNull)
            {
                CL_TextDap_Console.sayFail(format!"the library returned no size for %s"(path));
            }

            return bytes;
        }
        catch (FileOperationExceptionAP raised)
        {
            CL_TextDap_Console.sayFail(format!"size check failed for %s: %s"(path, raised.msg));
            return Optional!long.init;
        }
        catch (BaseExceptionAP raised)
        {
            CL_TextDap_Console.sayFail(format!"size check failed for %s: %s"(path, raised.msg));
            return Optional!long.init;
        }
    }

    public static long measuredOrZero(string path)
    {
        Optional!long bytes = measureBytes(path);
        return bytes.isNull ? 0 : bytes.get;
    }
}
