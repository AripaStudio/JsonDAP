module TextDAPSetActions;

import JsonDAP;
import TextDAPConsole;
import TextDAPFrame;
import TextDAPConvert;
import TextDAPDocActions;
import TextDAPModel;
import TextDAPState;
import std.conv;
import std.format;
import std.string;

public class CL_TextDap_SetActions
{
    public static void showHistory(CL_TextDap_State state)
    {
        CL_TextDap_Frame.showFrame("opened before", state.historyRows());

        Optional!string action = CL_TextDap_Console.askText(
                "type 'o' to open one, 'x' to forget one, anything else to go back: ");

        if (action.isNull)
        {
            return;
        }

        string wanted = toLower(strip(action.get));

        if (wanted != "o" && wanted != "x")
        {
            CL_TextDap_Console.sayNote("history left as it was.");
            return;
        }

        Optional!int position = CL_TextDap_Console.askNumber("which position: ", 0,
                cast(int) state.history.length - 1);

        if (position.isNull)
        {
            return;
        }

        if (wanted == "o")
        {
            CL_TextDap_DocActions.openPath(state, state.history[position.get].filePath);
            return;
        }

        string message;
        if (state.forgetAt(position.get, message))
        {
            CL_TextDap_Console.sayDone(message);
            return;
        }

        CL_TextDap_Console.sayFail(message);
    }

    public static void showSettings(CL_TextDap_State state)
    {
        while (true)
        {
            CL_TextDap_Frame.showFrame("settings", settingsRows(state));

            Optional!string choice = CL_TextDap_Console.askText("settings choice: ");
            if (choice.isNull || choice.get == "0")
            {
                return;
            }

            applySetting(state, choice.get);
        }
    }

    public static void runConversionDemos(CL_TextDap_State state)
    {
        DocumentRecord sample = makeDocumentRecord("notes.txt", "notes.txt", 3, 42,
                DocumentState.edited);
        sample.note = Optional!string("written during a demo");

        CL_TextDap_Console.sayLine("one record, serialized and read back");
        CL_TextDap_Convert.recordRoundTrip(sample);

        CL_TextDap_Console.sayLine("a cursor, carried as a tagged SumType envelope");
        CL_TextDap_Convert.cursorRoundTrip(CursorTarget(7));

        CL_TextDap_Console.sayLine("the same text read strictly and leniently");
        CL_TextDap_Convert.strictVersusLenient();

        CL_TextDap_Console.sayLine("an enum value the reader refuses");
        CL_TextDap_Convert.enumGuardDemo();

        CL_TextDap_Console.sayLine("an array of records, merged in memory");
        CL_TextDap_Convert.arrayAndMergeDemo();

        CL_TextDap_Console.sayLine("which digit characters the library accepts");
        CL_TextDap_Convert.digitGateDemo();

        string message;
        if (!state.persist(message))
        {
            CL_TextDap_Console.sayFail(message);
            return;
        }

        CL_TextDap_Console.sayLine("the whole history exported as a JSON array");
        CL_TextDap_Convert.exportHistory(state.history, defaultHistoryPath);
    }

    private static string[] settingsRows(CL_TextDap_State state)
    {
        string[] rows = state.optionRows();

        rows ~= "";
        rows ~= CL_TextDap_Frame.cell("1", "change the session title");
        rows ~= CL_TextDap_Frame.cell("2", "toggle autosave");
        rows ~= CL_TextDap_Frame.cell("3", "toggle line numbers");
        rows ~= CL_TextDap_Frame.cell("4", "set the tab width");
        rows ~= CL_TextDap_Frame.cell("5", "set how much history is kept");
        rows ~= CL_TextDap_Frame.cell("0", "leave the settings");

        return rows;
    }

    private static void applySetting(CL_TextDap_State state, string choice)
    {
        if (choice == "1")
        {
            changeValue!string(state, TextDapPath.sessionTitle,
                    CL_TextDap_Console.askText("new session title: "));
            return;
        }

        if (choice == "2")
        {
            changeValue!bool(state, TextDapPath.autosave, Optional!bool(!state.options.autosave));
            return;
        }

        if (choice == "3")
        {
            changeValue!bool(state, TextDapPath.lineNumbers,
                    Optional!bool(!state.options.showLineNumbers));
            return;
        }

        if (choice == "4")
        {
            changeValue!int(state, TextDapPath.tabWidth,
                    CL_TextDap_Console.askNumber("tab width between 1 and 8: ", 1, 8));
            return;
        }

        if (choice == "5")
        {
            changeValue!int(state, TextDapPath.maxHistory,
                    CL_TextDap_Console.askNumber(
                            format!"how many files to keep (%d-%d): "(minimumHistory, maximumHistory),
                            minimumHistory, maximumHistory));
            return;
        }

        CL_TextDap_Console.sayFail(format!"'%s' is not a settings choice."(choice));
    }

    private static void changeValue(V)(CL_TextDap_State state, string jsonPath, Optional!V asked)
    {
        if (asked.isNull)
        {
            return;
        }

        string message;
        if (state.setOptionValue!V(jsonPath, asked.get, message))
        {
            CL_TextDap_Console.sayDone(format!"%s is now %s"(jsonPath, to!string(asked.get)));
            return;
        }

        CL_TextDap_Console.sayFail(message);
    }
}
