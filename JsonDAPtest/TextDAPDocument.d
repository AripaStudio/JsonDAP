module TextDAPDocument;

import JsonDAP;
import TextDAPConsole;
import TextDAPFileStore;
import TextDAPStats;
import std.algorithm : canFind;
import std.format;
import std.path : dirName;
import std.string;
import std.typecons;

alias Optional = Nullable;

public enum maxSnapshots = 20;

public class CL_TextDap_Document
{
    private string m_path;
    private string[] m_lines;
    private bool m_edited;
    private string[][] m_snapshots;

    public this(string path)
    {
        m_path = path;
        m_lines = [];
        m_edited = false;
        m_snapshots = [];
    }

    @property string path()
    {
        return m_path;
    }

    @property bool edited()
    {
        return m_edited;
    }

    @property bool open()
    {
        return !m_path.empty;
    }

    @property int lineCount()
    {
        return cast(int) m_lines.length;
    }

    @property int undoDepth()
    {
        return cast(int) m_snapshots.length;
    }

    public string[] lines()
    {
        return m_lines;
    }

    public string textAt(int oneBased)
    {
        return m_lines[oneBased - 1];
    }

    public string joinedText()
    {
        return textOf(m_lines);
    }

    public bool startEmpty(string path)
    {
        string blankReason;
        bool blankFlag;
        JsonAP.APstrIsNil(path, "new file path", blankFlag, blankReason);

        if (blankFlag)
        {
            CL_TextDap_Console.sayFail(blankReason);
            return false;
        }

        if (JsonAP.APexistsFile(path))
        {
            CL_TextDap_Console.sayFail(format!"%s already exists; open it instead."(path));
            return false;
        }

        string folder = dirName(path);
        if (!folder.empty && !JsonAP.APexists(folder))
        {
            CL_TextDap_Console.sayFail(format!"there is no folder at %s."(folder));
            return false;
        }

        m_path = path;
        m_lines = [];
        m_snapshots = [];
        m_edited = true;
        return true;
    }

    public bool load()
    {
        Optional!(string[]) read = CL_TextDap_Store.readLines(m_path);
        if (read.isNull)
        {
            return false;
        }

        m_lines = read.get;
        m_edited = false;
        m_snapshots = [];

        CL_TextDap_Console.sayDone(format!"loaded %s (%s, %d bytes)"(m_path, CL_TextDap_Console.countWord(lineCount, "line"),
                CL_TextDap_Store.measuredOrZero(m_path)));
        return true;
    }

    public bool reload()
    {
        if (!open)
        {
            CL_TextDap_Console.sayFail("no document is open.");
            return false;
        }

        return load();
    }

    public bool save()
    {
        if (!open)
        {
            CL_TextDap_Console.sayFail("no document is open.");
            return false;
        }

        if (!CL_TextDap_Store.writeLines(m_path, m_lines))
        {
            return false;
        }

        m_edited = false;
        reportSaved();
        return true;
    }

    public bool saveAs(string newPath)
    {
        string blankReason;
        bool blankFlag;
        JsonAP.APstrIsNil(newPath, "target file path", blankFlag, blankReason);

        if (blankFlag)
        {
            CL_TextDap_Console.sayFail(blankReason);
            return false;
        }

        m_path = newPath;
        return save();
    }

    public bool replaceLine(int oneBased, string content)
    {
        if (!checkLineIndex(oneBased, "replace"))
        {
            return false;
        }

        pushSnapshot();
        m_lines[oneBased - 1] = content;
        m_edited = true;
        return true;
    }

    public bool insertAfterLine(int oneBased, string content)
    {
        if (!checkLineIndex(oneBased, "insert after"))
        {
            return false;
        }

        pushSnapshot();
        int insertAt = oneBased;
        m_lines = m_lines[0 .. insertAt] ~ [content] ~ m_lines[insertAt .. $];
        m_edited = true;
        return true;
    }

    public bool appendLine(string content)
    {
        pushSnapshot();
        m_lines ~= content;
        m_edited = true;
        return true;
    }

    public bool deleteLine(int oneBased)
    {
        if (!checkLineIndex(oneBased, "delete"))
        {
            return false;
        }

        pushSnapshot();
        int at = oneBased - 1;
        m_lines = m_lines[0 .. at] ~ m_lines[at + 1 .. $];
        m_edited = true;
        return true;
    }

    public bool undo()
    {
        if (m_snapshots.length == 0)
        {
            CL_TextDap_Console.sayFail("there is nothing to undo.");
            return false;
        }

        m_lines = m_snapshots[$ - 1];
        m_snapshots = m_snapshots[0 .. $ - 1];
        m_edited = true;
        return true;
    }

    public int[] findLines(string needle)
    {
        int[] matches;

        foreach (index, line; m_lines)
        {
            if (line.canFind(needle))
            {
                matches ~= cast(int) index + 1;
            }
        }

        return matches;
    }

    public bool isJsonDocument()
    {
        return kindOf(m_path) == "json";
    }

    public DocumentStats collectStats()
    {
        return gather(m_path, m_lines, JsonAP.APexistsFile(m_path));
    }

    private void reportSaved()
    {
        CL_TextDap_Console.sayDone(format!"saved %s (%s, %d bytes)"(m_path, CL_TextDap_Console.countWord(lineCount, "line"),
                CL_TextDap_Store.measuredOrZero(m_path)));

        if (!isJsonDocument())
        {
            return;
        }

        if (JsonAP.APisValidJson(joinedText()))
        {
            CL_TextDap_Console.sayNote("the saved document is valid JSON.");
            return;
        }

        CL_TextDap_Console.sayFail("the saved document is not valid JSON; the JSON tools will refuse it.");
    }

    private bool checkLineIndex(int oneBased, string action)
    {
        if (!open)
        {
            CL_TextDap_Console.sayFail("no document is open.");
            return false;
        }

        if (oneBased < 1 || oneBased > lineCount)
        {
            CL_TextDap_Console.sayFail(format!"cannot %s line %d: the document has %d lines."(
                    action, oneBased, lineCount));
            return false;
        }

        return true;
    }

    private void pushSnapshot()
    {
        if (m_snapshots.length >= maxSnapshots)
        {
            m_snapshots = m_snapshots[1 .. $];
        }

        m_snapshots ~= m_lines.dup;
    }
}
