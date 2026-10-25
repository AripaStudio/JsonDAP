module TextDAPJsonActions;

import JsonDAP;
import TextDAPConsole;
import TextDAPFrame;
import TextDAPJsonEdit;
import TextDAPJsonTools;
import TextDAPModel;
import TextDAPScalar;
import TextDAPState;
import std.array : join;
import std.conv;
import std.format;
import std.string;

public class CL_TextDap_JsonActions
{
    public static void validateBuffer(CL_TextDap_State state)
    {
        if (!state.document.open)
        {
            CL_TextDap_Console.sayFail("open or start a document first.");
            return;
        }

        CL_TextDap_JsonTools.validateText(state.document.joinedText());
    }

    public static void describeCurrent(CL_TextDap_State state)
    {
        Optional!string path = currentJsonPath(state);
        if (!path.isNull)
        {
            CL_TextDap_JsonTools.describeFile(path.get);
        }
    }

    public static void explainAPath(CL_TextDap_State state)
    {
        Optional!string asked = CL_TextDap_Console.askText("json path to explain: ");
        if (!asked.isNull)
        {
            CL_TextDap_JsonTools.explainPath(asked.get);
        }
    }

    public static void getValueAt(CL_TextDap_State state)
    {
        Optional!string path = currentJsonPath(state);
        if (path.isNull)
        {
            return;
        }

        Optional!string dotPath = CL_TextDap_Console.askText("dot path to read (options.session_title): ");
        if (dotPath.isNull)
        {
            return;
        }

        Optional!string kind = askKind("type of value expected: ");
        if (!kind.isNull)
        {
            CL_TextDap_JsonTools.readValueAt(path.get, dotPath.get, kind.get);
        }
    }

    public static void updateValueAt(CL_TextDap_State state)
    {
        Optional!string path = currentJsonPath(state);
        if (path.isNull)
        {
            return;
        }

        Optional!string jsonPath = CL_TextDap_Console.askText("path to write (options.max_history): ");
        if (jsonPath.isNull)
        {
            return;
        }

        Optional!string kind = askKind("type of the new value: ");
        if (kind.isNull)
        {
            return;
        }

        Optional!string raw = CL_TextDap_Console.askText(format!"new value as %s: "(kind.get));
        if (raw.isNull)
        {
            return;
        }

        string message;
        if (CL_TextDap_JsonEdit.updateValueAt(path.get, jsonPath.get, kind.get, raw.get, message))
        {
            refreshBuffer(state, path.get);
            return;
        }

        CL_TextDap_Console.sayFail(message);
    }

    public static void addValueAt(CL_TextDap_State state)
    {
        Optional!string path = currentJsonPath(state);
        if (path.isNull)
        {
            return;
        }

        Optional!string jsonPath = CL_TextDap_Console.askText("new key to add (meta.reviewed): ");
        if (jsonPath.isNull)
        {
            return;
        }

        Optional!string kind = askKind("type of the new value: ");
        if (kind.isNull)
        {
            return;
        }

        Optional!string raw = CL_TextDap_Console.askText(format!"value as %s: "(kind.get));
        if (raw.isNull)
        {
            return;
        }

        string message;
        if (CL_TextDap_JsonEdit.addValueAt(path.get, jsonPath.get, kind.get, raw.get, message))
        {
            refreshBuffer(state, path.get);
            return;
        }

        CL_TextDap_Console.sayFail(message);
    }

    public static void removeValueAt(CL_TextDap_State state)
    {
        Optional!string path = currentJsonPath(state);
        if (path.isNull)
        {
            return;
        }

        Optional!string jsonPath = CL_TextDap_Console.askText("key or item to remove (documents[0]): ");
        if (jsonPath.isNull)
        {
            return;
        }

        string message;
        if (CL_TextDap_JsonEdit.deleteAt(path.get, jsonPath.get, message))
        {
            refreshBuffer(state, path.get);
            return;
        }

        CL_TextDap_Console.sayFail(message);
    }

    public static void mergeAnotherFile(CL_TextDap_State state)
    {
        Optional!string path = currentJsonPath(state);
        if (path.isNull)
        {
            return;
        }

        Optional!string source = CL_TextDap_Console.askText("path of the JSON file to merge in: ");
        if (source.isNull)
        {
            return;
        }

        bool overwriteExisting = CL_TextDap_Console.askYes("overwrite keys that already exist? (y/n) ");
        bool mergeArrays = CL_TextDap_Console.askYes("concatenate arrays instead of replacing them? (y/n) ");

        string message;
        if (CL_TextDap_JsonEdit.mergeFiles(path.get, source.get, overwriteExisting, mergeArrays, message))
        {
            refreshBuffer(state, path.get);
            return;
        }

        CL_TextDap_Console.sayFail(message);
    }

    private static Optional!string currentJsonPath(CL_TextDap_State state)
    {
        Optional!string none;

        if (!state.document.open)
        {
            CL_TextDap_Console.sayFail("open or start a document first.");
            return none;
        }

        if (!state.document.isJsonDocument())
        {
            CL_TextDap_Console.sayFail(format!"%s is not a .json file."(state.document.path));
            return none;
        }

        if (!JsonAP.APexistsFile(state.document.path))
        {
            CL_TextDap_Console.sayNote("the file is not on disk yet; write it with 'w' first.");
            return none;
        }

        return Optional!string(state.document.path);
    }

    private static Optional!string askKind(string prompt)
    {
        Optional!string asked = CL_TextDap_Console.askText(prompt
                ~ join(CL_TextDap_Scalar.kindNames(), "/") ~ ": ");

        if (asked.isNull)
        {
            return asked;
        }

        string kind = toLower(strip(asked.get));

        foreach (candidate; CL_TextDap_Scalar.kindNames())
        {
            if (candidate == kind)
            {
                return Optional!string(kind);
            }
        }

        CL_TextDap_Console.sayFail(CL_TextDap_Scalar.unknownKindText(kind));
        return Optional!string.init;
    }

    private static void refreshBuffer(CL_TextDap_State state, string filePath)
    {
        if (state.document.path == filePath)
        {
            state.document.reload();
        }
    }
}
