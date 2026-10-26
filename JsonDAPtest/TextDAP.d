module TextDAP;

import TextDAPConsole;
import TextDAPCursorActions;
import TextDAPFrame;
import TextDAPDocActions;
import TextDAPJsonActions;
import TextDAPModel;
import TextDAPSetActions;
import TextDAPState;
import std.algorithm : canFind;
import std.conv;
import std.format;
import std.path : baseName;
import std.stdio;
import std.string;

alias Action = void function(CL_TextDap_State state);

struct Command
{
    string key;
    string label;
    string section;
    Action action;
}

enum string[] helpKeys = ["?", "help"];
enum string[] quitKeys = ["q", "exit", "quit"];

void main()
{
    CL_TextDap_Frame.showBanner("TextDAP", "a console text editor written on top of JsonDAP");

    CL_TextDap_State state = new CL_TextDap_State(defaultSessionPath);

    showMenu(state);

    while (true)
    {
        string raw = CL_TextDap_Console.ask(promptOf(state));
        if (raw is null)
        {
            break;
        }

        string choice = toLower(strip(raw));

        if (choice.empty)
        {
            continue;
        }
        if (helpKeys.canFind(choice))
        {
            showMenu(state);
            continue;
        }
        if (quitKeys.canFind(choice))
        {
            break;
        }

        runChoice(state, choice);
    }

    leave(state);
}

Command[] commands()
{
    return [
        Command("o", "open a file", "document", &CL_TextDap_DocActions.openFile),
        Command("n", "start a new file", "document", &CL_TextDap_DocActions.startFile),
        Command("r", "read the buffer", "document", &CL_TextDap_DocActions.readBuffer),
        Command("w", "write the buffer", "document", &CL_TextDap_DocActions.writeFile),
        Command("s", "write under a name", "document", &CL_TextDap_DocActions.writeUnder),
        Command("i", "inspect the buffer", "document", &CL_TextDap_DocActions.inspectDocument),
        Command("d", "discard the edits", "document", &CL_TextDap_DocActions.discardEdits),
        Command("e", "replace one line", "edit", &CL_TextDap_DocActions.replaceLine),
        Command("x", "delete one line", "edit", &CL_TextDap_DocActions.deleteLine),
        Command("a", "append a line", "edit", &CL_TextDap_DocActions.appendLine),
        Command("z", "undo the last edit", "edit", &CL_TextDap_DocActions.undoLastEdit),
        Command("f", "find text in the buffer", "edit", &CL_TextDap_DocActions.findText),
        Command("j", "validate the buffer", "json", &CL_TextDap_JsonActions.validateBuffer),
        Command("v", "describe this JSON file", "json", &CL_TextDap_JsonActions.describeCurrent),
        Command("g", "read a path", "json", &CL_TextDap_JsonActions.getValueAt),
        Command("u", "write a path", "json", &CL_TextDap_JsonActions.updateValueAt),
        Command("k", "add a key", "json", &CL_TextDap_JsonActions.addValueAt),
        Command("-", "remove a key or item", "json", &CL_TextDap_JsonActions.removeValueAt),
        Command("p", "explain a path", "json", &CL_TextDap_JsonActions.explainAPath),
        Command("m", "merge another file", "json", &CL_TextDap_JsonActions.mergeAnotherFile),
        Command("c", "the session cursor", "json", &CL_TextDap_CursorActions.work),
        Command("h", "files opened before", "history and settings", &CL_TextDap_SetActions.showHistory),
        Command("t", "settings", "history and settings", &CL_TextDap_SetActions.showSettings),
        Command("y", "conversion demos", "history and settings", &CL_TextDap_SetActions.runConversionDemos),
    ];
}

void runChoice(CL_TextDap_State state, string choice)
{
    foreach (command; commands())
    {
        if (command.key != choice)
        {
            continue;
        }

        command.action(state);
        return;
    }

    CL_TextDap_Console.sayFail(format!"'%s' is not on the menu; type ? for the list."(choice));
}

void showMenu(CL_TextDap_State state)
{
    Command[] table = commands();
    size_t walk;

    while (walk < table.length)
    {
        string section = table[walk].section;
        size_t end = walk;

        while (end < table.length && table[end].section == section)
        {
            end++;
        }

        string[] rows;
        size_t at = walk;

        while (at < end)
        {
            if (end - at > 1)
            {
                rows ~= cellPair(table[at], table[at + 1]);
                at += 2;
            }
            else
            {
                rows ~= CL_TextDap_Frame.cell(table[at].key, table[at].label);
                at++;
            }
        }

        CL_TextDap_Frame.showFrame(walk is 0 ? titleOf(state) : section, rows);
        walk = end;
    }

    CL_TextDap_Frame.showFrame("help and exit", [
            CL_TextDap_Frame.cell(helpKeys[0], "show this menu")
            ~ CL_TextDap_Frame.cell(quitKeys[0], "quit and save"),
        ]);
}

string promptOf(CL_TextDap_State state)
{
    if (!state.document.open)
    {
        return "TextDAP> ";
    }

    return format!"%s%s> "(CL_TextDap_Frame.clip(baseName(state.document.path), 28),
            state.document.edited ? "*" : "");
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

string cellPair(Command first, Command second)
{
    return CL_TextDap_Frame.cell(first.key, first.label)
            ~ CL_TextDap_Frame.cell(second.key, second.label);
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
