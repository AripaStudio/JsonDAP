module TextDAPSession;

import JsonDAP;
import TextDAPConsole;
import TextDAPHistory;
import TextDAPModel;
import std.conv;
import std.file;
import std.format;
import std.json;
import std.string;
import std.typecons;

alias Optional = Nullable;

public class CL_TextDap_Session
{
    public static Optional!SessionFile load(string filePath)
    {
        string blankReason;
        bool blankFlag;
        JsonAP.APstrIsNil(filePath, "session path", blankFlag, blankReason);

        if (blankFlag)
        {
            CL_TextDap_Console.sayFail(blankReason);
            return Optional!SessionFile.init;
        }

        if (!JsonAP.APexistsFile(filePath))
        {
            CL_TextDap_Console.sayNote(format!"no session file at %s; a new one will be created."(filePath));
            return Optional!SessionFile.init;
        }

        string text = readWholeFile(filePath);
        if (text is null)
        {
            return Optional!SessionFile.init;
        }

        if (!JsonAP.APisValidJson(text))
        {
            Optional!long count = JsonAP.APgetJsonItemCount(text);
            CL_TextDap_Console.sayFail(count.isNull
                    ? format!"%s is not readable as JSON."(filePath)
                    : format!"%s holds %d items but is not a JSON object."(filePath, count.get));
            return Optional!SessionFile.init;
        }

        try
        {
            auto parsed = JsonAP.APdeserializeJsonLenient!SessionFile(text);
            if (parsed.isNull)
            {
                CL_TextDap_Console.sayFail("the session document read back as empty.");
                return Optional!SessionFile.init;
            }

            SessionFile session = parsed.get;

            if (session.schema != sessionSchema)
            {
                CL_TextDap_Console.sayNote(format!"the file was written with schema '%s'; this build uses '%s'."
                        (session.schema, sessionSchema));
            }

            repair(session.documents);
            return Optional!SessionFile(session);
        }
        catch (JSONExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return Optional!SessionFile.init;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return Optional!SessionFile.init;
        }
    }

    public static bool save(ref SessionFile session, string filePath, out string message)
    {
        message = "";
        session.schema = sessionSchema;
        repair(session.documents);

        try
        {
            JSONValue wire = JsonAP.APserializeToJson!SessionFile(session);

            if (JsonAP.APexistsFile(filePath))
            {
                if (JsonAP.APmergeJsonWithMessage(filePath, wire, true, false, message))
                {
                    return verify(filePath, message);
                }

                CL_TextDap_Console.sayNote(message);
            }

            if (!JsonAP.APwriteJsonFile!JSONValue(filePath, wire))
            {
                message = format!"nothing was written to %s."(filePath);
                return false;
            }
        }
        catch (BaseExceptionAP caught)
        {
            message = caught.msg;
            return false;
        }

        return verify(filePath, message);
    }

    public static bool writeValue(V)(string filePath, string jsonPath, V value, out string message)
    {
        message = "";

        string[] blankInputs = [filePath, jsonPath];
        if (JsonAP.APCheckStringIsNullArray(blankInputs))
        {
            message = "the session path and the file path must both hold text.";
            return false;
        }

        bool added = JsonAP.APaddJsonItemOBJECTWithMessage!V(filePath, jsonPath, value, message);
        if (added)
        {
            return true;
        }

        return JsonAP.APupdateJsonValueOBJECTWithMessage!V(filePath, jsonPath, value, message);
    }

    public static bool writeDocumentValue(V)(string filePath, int index, string memberPath,
            V value, out string message)
    {
        return writeValue(filePath, CL_TextDap_History.documentPath(index) ~ "." ~ memberPath,
                value, message);
    }

    public static bool writeCursor(string filePath, CursorTarget target, out string message)
    {
        JSONValue envelope = JsonAP.APserializeSumTypeWithHandlers!CursorTarget(target,
                (CursorTarget held) => cursorTagOf(held), (CursorTarget held) => cursorPayloadOf(held));

        return writeValue!JSONValue(filePath, TextDapPath.cursor, envelope, message);
    }

    public static Optional!CursorTarget readCursor(string filePath)
    {
        Optional!CursorTarget noCursor;

        try
        {
            auto read = JsonAP.APreadJsonFile!JSONValue(filePath);
            if (read.isNull || read.get.type != JSONType.OBJECT)
            {
                return noCursor;
            }

            JSONValue* stored = TextDapPath.cursor in read.get.object;
            if (stored is null)
            {
                CL_TextDap_Console.sayNote("the session holds no cursor yet.");
                return noCursor;
            }

            return JsonAP.APdeserializeSumTypeWithHandlers!CursorTarget(*stored,
                    (string tag, JSONValue payload) => resolveCursor(tag, payload));
        }
        catch (JSONExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return noCursor;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return noCursor;
        }
    }

    private static string readWholeFile(string filePath)
    {
        try
        {
            Optional!long size = JsonAP.APgetJsonFileSize(filePath);
            if (size.isNull)
            {
                CL_TextDap_Console.sayFail(format!"the size of %s could not be measured."(filePath));
                return null;
            }

            if (size.get == 0)
            {
                CL_TextDap_Console.sayNote(format!"%s is an empty file; starting fresh."(filePath));
                return null;
            }

            return readText(filePath);
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return null;
        }
    }

    private static bool verify(string filePath, ref string message)
    {
        if (!JsonAP.APexistsFile(filePath))
        {
            message = format!"%s was written but cannot be found again."(filePath);
            return false;
        }

        string text = readWholeFile(filePath);
        if (text is null)
        {
            message = format!"%s was written but cannot be read back."(filePath);
            return false;
        }

        if (!JsonAP.APisValidJson(text))
        {
            message = format!"%s was written but is no longer valid JSON."(filePath);
            return false;
        }

        message = format!"%s holds the session."(filePath);
        return true;
    }

    private static void repair(ref DocumentRecord[] records)
    {
        foreach (ref record; records)
        {
            record.lookupKey = makeLookupKey(record.filePath);

            if (record.title.empty)
            {
                record.title = shortTitleOf(record.filePath);
            }

            if (record.openCount < 1)
            {
                record.openCount = 1;
            }
        }
    }
}
