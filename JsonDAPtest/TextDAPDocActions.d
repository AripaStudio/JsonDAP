module TextDAPDocActions;

import JsonDAP;
import TextDAPConsole;
import TextDAPFrame;
import TextDAPDocument;
import TextDAPModel;
import TextDAPJsonTools;
import TextDAPState;
import TextDAPStats;
import std.array : join;
import std.conv;
import std.format;
import std.string;

public enum screenLines = 40;

public class CL_TextDap_DocActions
{
    public static void openFile(CL_TextDap_State state)
    {
        Optional!string asked = CL_TextDap_Console.askText("path of the file to open: ");
        if (!asked.isNull)
        {
            openPath(state, asked.get);
        }
    }

    public static bool openPath(CL_TextDap_State state, string path)
    {
        if (!JsonAP.APexistsFile(path))
        {
            CL_TextDap_Console.sayFail(format!"there is no file at %s; use 'n' to start one."(path));
            return false;
        }

        CL_TextDap_Document opened = new CL_TextDap_Document(path);
        if (!opened.load())
        {
            return false;
        }

        state.document = opened;
        state.noteOpened("");
        readBuffer(state);
        return true;
    }

    public static void startFile(CL_TextDap_State state)
    {
        Optional!string asked = CL_TextDap_Console.askText("path for the new file: ");
        if (asked.isNull)
        {
            return;
        }

        CL_TextDap_Document started = new CL_TextDap_Document("");
        if (!started.startEmpty(asked.get))
        {
            return;
        }

        state.document = started;
        CL_TextDap_Console.sayDone(format!"a new document was started at %s"(asked.get));
    }

    public static void readBuffer(CL_TextDap_State state)
    {
        CL_TextDap_Document document = state.document;

        if (!document.open)
        {
            CL_TextDap_Console.sayFail("no document is open.");
            return;
        }

        string[] lines = document.lines;
        if (lines.empty)
        {
            CL_TextDap_Console.sayNote("the buffer is empty.");
            return;
        }

        int shown = lines.length < screenLines ? cast(int) lines.length : screenLines;

        foreach (index; 0 .. shown)
        {
            CL_TextDap_Console.sayLine(lineLabel(index + 1, state.options.showLineNumbers)
                    ~ CL_TextDap_Frame.clip(lines[index], 60));
        }

        if (shown < cast(int) lines.length)
        {
            CL_TextDap_Console.sayNote(format!"%d of %d lines shown; 'f' finds text anywhere in the file"
                    (shown, lines.length));
        }
    }

    public static void writeFile(CL_TextDap_State state)
    {
        if (!state.document.save())
        {
            return;
        }

        state.noteSaved();
    }

    public static void writeUnder(CL_TextDap_State state)
    {
        Optional!string asked = CL_TextDap_Console.askText("write this document to: ");
        if (asked.isNull)
        {
            return;
        }

        if (state.document.saveAs(asked.get))
        {
            state.noteSaved();
        }
    }

    public static void discardEdits(CL_TextDap_State state)
    {
        if (!state.document.edited)
        {
            CL_TextDap_Console.sayNote("the buffer already matches the file.");
            return;
        }

        if (!CL_TextDap_Console.askYes("discard every unsaved change? (y/n) "))
        {
            CL_TextDap_Console.sayNote("nothing was discarded.");
            return;
        }

        state.document.reload();
    }

    public static void inspectDocument(CL_TextDap_State state)
    {
        CL_TextDap_Document document = state.document;

        if (!document.open)
        {
            CL_TextDap_Console.sayFail("no document is open.");
            return;
        }

        DocumentStats stats = document.collectStats();

        CL_TextDap_Frame.showFrame("document details", [
                CL_TextDap_Frame.fieldText("file", document.path),
                CL_TextDap_Frame.fieldText("kind", stats.kind),
                CL_TextDap_Frame.fieldText("on disk", stats.existsOnDisk ? "yes" : "no"),
                CL_TextDap_Frame.fieldText("bytes", CL_TextDap_JsonTools.sizeText(document.path)),
                CL_TextDap_Frame.fieldText("lines", to!string(stats.lineCount)),
                CL_TextDap_Frame.fieldText("words", to!string(stats.wordCount)),
                CL_TextDap_Frame.fieldText("chars", to!string(stats.charCount)),
                CL_TextDap_Frame.fieldText("longest", to!string(stats.longestLine)),
                CL_TextDap_Frame.fieldText("state", describeState(stateOf(stats.existsOnDisk, document.edited))),
                CL_TextDap_Frame.fieldText("undo", format!"%d steps back"(document.undoDepth)),
                CL_TextDap_Frame.fieldText("json", stats.jsonDocument ? "a JSON document" : "not JSON"),
            ]);
    }

    public static void replaceLine(CL_TextDap_State state)
    {
        if (!hasLines(state))
        {
            return;
        }

        Optional!int asked = CL_TextDap_Console.askNumber("which line to replace: ", 1,
                state.document.lineCount);

        if (asked.isNull)
        {
            return;
        }

        Optional!string text = CL_TextDap_Console.askText("new content for that line: ");
        if (text.isNull)
        {
            return;
        }

        if (state.document.replaceLine(asked.get, text.get))
        {
            CL_TextDap_Console.sayDone(format!"line %d now reads: %s"(asked.get, text.get));
        }
    }

    public static void appendLine(CL_TextDap_State state)
    {
        Optional!string text = CL_TextDap_Console.askText("line to append: ");
        if (text.isNull)
        {
            return;
        }

        if (state.document.appendLine(text.get))
        {
            CL_TextDap_Console.sayDone(format!"the buffer now holds %s"(CL_TextDap_Console.countWord(state.document.lineCount, "line")));
        }
    }

    public static void deleteLine(CL_TextDap_State state)
    {
        if (!hasLines(state))
        {
            return;
        }

        Optional!int asked = CL_TextDap_Console.askNumber("which line to delete: ", 1,
                state.document.lineCount);

        if (asked.isNull)
        {
            return;
        }

        if (state.document.deleteLine(asked.get))
        {
            CL_TextDap_Console.sayDone(format!"line %d is gone; 'z' brings it back"(asked.get));
        }
    }

    public static void undoLastEdit(CL_TextDap_State state)
    {
        if (state.document.undo())
        {
            CL_TextDap_Console.sayDone(format!"the buffer is back to %s"(CL_TextDap_Console.countWord(state.document.lineCount, "line")));
        }
    }

    public static void findText(CL_TextDap_State state)
    {
        Optional!string needle = CL_TextDap_Console.askText("text to look for: ");
        if (needle.isNull)
        {
            return;
        }

        int[] hits = state.document.findLines(needle.get);

        if (hits.empty)
        {
            CL_TextDap_Console.sayNote(format!"'%s' was not found."(needle.get));
            return;
        }

        string[] numbers;
        foreach (hit; hits)
        {
            numbers ~= to!string(hit);
        }

        CL_TextDap_Console.sayDone(format!"'%s' appears on lines %s"(needle.get, join(numbers, ", ")));

        Optional!int wanted = CL_TextDap_Console.askNumber("show one of them? type its number: ",
                hits[0], hits[$ - 1]);

        if (!wanted.isNull)
        {
            CL_TextDap_Console.sayLine(state.document.textAt(wanted.get));
        }
    }

    private static bool hasLines(CL_TextDap_State state)
    {
        if (state.document.lineCount > 0)
        {
            return true;
        }

        CL_TextDap_Console.sayFail("the buffer holds no lines yet; append one with 'a'.");
        return false;
    }

    private static string lineLabel(int number, bool showNumbers)
    {
        if (!showNumbers)
        {
            return "";
        }

        return format!"%3d | "(number);
    }
}
