module TextDAPCursorActions;

import JsonDAP;
import TextDAPConsole;
import TextDAPFrame;
import TextDAPModel;
import TextDAPState;
import std.format;

public class CL_TextDap_CursorActions
{
    public static void work(CL_TextDap_State state)
    {
        CL_TextDap_Frame.showFrame("cursor", [
                CL_TextDap_Frame.cell("l", "remember a line number"),
                CL_TextDap_Frame.cell("s", "remember a search term"),
                CL_TextDap_Frame.cell("r", "recall what the session holds"),
            ]);

        Optional!string choice = CL_TextDap_Console.askText("choice: ");
        if (choice.isNull)
        {
            return;
        }

        if (choice.get == "l")
        {
            Optional!int line = CL_TextDap_Console.askNumber("line number: ", 1, 100000);
            if (!line.isNull)
            {
                storeCursor(state, CursorTarget(line.get));
            }
            return;
        }

        if (choice.get == "s")
        {
            Optional!string term = CL_TextDap_Console.askText("term to remember: ");
            if (!term.isNull)
            {
                storeCursor(state, CursorTarget(term.get));
            }
            return;
        }

        if (choice.get == "r")
        {
            Optional!CursorTarget recalled = state.recallCursor();
            if (recalled.isNull)
            {
                CL_TextDap_Console.sayNote("the session holds no cursor.");
                return;
            }

            CL_TextDap_Console.sayDone(format!"the cursor points at %s"(describeCursor(recalled.get).get));
            return;
        }

        CL_TextDap_Console.sayFail("that is not one of the cursor choices.");
    }

    private static void storeCursor(CL_TextDap_State state, CursorTarget target)
    {
        string message;

        if (state.storeCursor(target, message))
        {
            CL_TextDap_Console.sayDone(format!"the cursor now holds %s"(describeCursor(target).get));
            return;
        }

        CL_TextDap_Console.sayFail(message);
    }
}
