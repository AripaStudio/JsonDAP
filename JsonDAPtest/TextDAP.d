module TextDAP;

import TextDAPConsole;
import TextDAPCursorActions;
import TextDAPFrame;
import TextDAPDocActions;
import TextDAPJsonActions;
import TextDAPModel;
import TextDAPSetActions;
import TextDAPState;
import std.conv;
import std.format;
import std.stdio;
import std.string;

void main()
{
    CL_TextDap_Frame.showBanner("TextDAP", "a console text editor written on top of JsonDAP");

    CL_TextDap_State state = new CL_TextDap_State(defaultSessionPath);

    while (true)
    {
        showMenu(state);

        string raw = CL_TextDap_Console.ask("your choice: ");
        if (raw is null)
        {
            break;
        }

        string choice = toLower(strip(raw));
        if (choice == "q" || choice == "exit")
        {
            break;
        }

        runChoice(state, choice);
    }

    leave(state);
}

void runChoice(CL_TextDap_State state, string choice)
{
    if (choice == "o")
    {
        CL_TextDap_DocActions.openFile(state);
        return;
    }
    if (choice == "n")
    {
        CL_TextDap_DocActions.startFile(state);
        return;
    }
    if (choice == "r")
    {
        CL_TextDap_DocActions.readBuffer(state);
        return;
    }
    if (choice == "w")
    {
        CL_TextDap_DocActions.writeFile(state);
        return;
    }
    if (choice == "s")
    {
        CL_TextDap_DocActions.writeUnder(state);
        return;
    }
    if (choice == "i")
    {
        CL_TextDap_DocActions.inspectDocument(state);
        return;
    }
    if (choice == "d")
    {
        CL_TextDap_DocActions.discardEdits(state);
        return;
    }
    if (choice == "e")
    {
        CL_TextDap_DocActions.replaceLine(state);
        return;
    }
    if (choice == "a")
    {
        CL_TextDap_DocActions.appendLine(state);
        return;
    }
    if (choice == "x")
    {
        CL_TextDap_DocActions.deleteLine(state);
        return;
    }
    if (choice == "z")
    {
        CL_TextDap_DocActions.undoLastEdit(state);
        return;
    }
    if (choice == "f")
    {
        CL_TextDap_DocActions.findText(state);
        return;
    }
    if (choice == "j")
    {
        CL_TextDap_JsonActions.validateBuffer(state);
        return;
    }
    if (choice == "v")
    {
        CL_TextDap_JsonActions.describeCurrent(state);
        return;
    }
    if (choice == "g")
    {
        CL_TextDap_JsonActions.getValueAt(state);
        return;
    }
    if (choice == "u")
    {
        CL_TextDap_JsonActions.updateValueAt(state);
        return;
    }
    if (choice == "k")
    {
        CL_TextDap_JsonActions.addValueAt(state);
        return;
    }
    if (choice == "-")
    {
        CL_TextDap_JsonActions.removeValueAt(state);
        return;
    }
    if (choice == "p")
    {
        CL_TextDap_JsonActions.explainAPath(state);
        return;
    }
    if (choice == "m")
    {
        CL_TextDap_JsonActions.mergeAnotherFile(state);
        return;
    }
    if (choice == "c")
    {
        CL_TextDap_CursorActions.work(state);
        return;
    }
    if (choice == "h")
    {
        CL_TextDap_SetActions.showHistory(state);
        return;
    }
    if (choice == "t")
    {
        CL_TextDap_SetActions.showSettings(state);
        return;
    }
    if (choice == "y")
    {
        CL_TextDap_SetActions.runConversionDemos(state);
        return;
    }

    CL_TextDap_Console.sayFail(format!"'%s' is not on the menu."(choice));
}

void showMenu(CL_TextDap_State state)
{
    CL_TextDap_Frame.showFrame(titleOf(state), [
            pair("o", "open a file", "n", "start a new file"),
            pair("r", "read the buffer", "w", "write the buffer"),
            pair("s", "write under a name", "i", "inspect the buffer"),
            CL_TextDap_Frame.cell("d", "discard the edits"),
        ]);

    CL_TextDap_Frame.showFrame("edit", [
            pair("e", "replace one line", "x", "delete one line"),
            pair("a", "append a line", "z", "undo the last edit"),
            CL_TextDap_Frame.cell("f", "find text in the buffer"),
        ]);

    CL_TextDap_Frame.showFrame("json", [
            pair("j", "validate the buffer", "v", "describe this JSON file"),
            pair("g", "read a path", "u", "write a path"),
            pair("k", "add a key", "-", "remove a key or item"),
            pair("p", "explain a path", "m", "merge another file"),
            CL_TextDap_Frame.cell("c", "the session cursor"),
        ]);

    CL_TextDap_Frame.showFrame("history and settings", [
            pair("h", "files opened before", "t", "settings"),
            pair("y", "conversion demos", "q", "quit and save"),
        ]);
}

string titleOf(CL_TextDap_State state)
{
    if (state.document.open)
    {
        return format!"%s   [%s]"(state.options.sessionTitle,
                CL_TextDap_Frame.clip(state.document.path, 34));
    }

    return state.options.sessionTitle;
}

string pair(string firstKey, string firstLabel, string secondKey, string secondLabel)
{
    return CL_TextDap_Frame.cell(firstKey, firstLabel)
            ~ CL_TextDap_Frame.cell(secondKey, secondLabel);
}

void leave(CL_TextDap_State state)
{
    if (!state.document.edited)
    {
        closeSession(state);
        return;
    }

    if (state.options.autosave || CL_TextDap_Console.askYes(
            "the buffer still holds unsaved edits; keep them? (y/n) "))
    {
        CL_TextDap_DocActions.writeFile(state);
        closeSession(state);
        return;
    }

    CL_TextDap_Console.sayNote("the unsaved edits were dropped.");
    closeSession(state);
}

void closeSession(CL_TextDap_State state)
{
    string message;

    if (state.persist(message))
    {
        CL_TextDap_Console.sayDone(message);
    }
    else
    {
        CL_TextDap_Console.sayFail(message);
    }

    writeln("");
    CL_TextDap_Console.sayLine("goodbye.");
}
