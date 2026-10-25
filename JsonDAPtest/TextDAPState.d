module TextDAPState;

import JsonDAP;
import TextDAPConsole;
import TextDAPFrame;
import TextDAPHistory;
import TextDAPDocument;
import TextDAPModel;
import TextDAPSession;
import TextDAPStats;
import std.conv;
import std.format;
import std.string;

public class CL_TextDap_State
{
    private SessionFile m_session;
    private CL_TextDap_Document m_document;
    private string m_sessionPath;

    public this(string sessionPath)
    {
        m_sessionPath = sessionPath;
        m_document = new CL_TextDap_Document("");
        start();
    }

    @property string sessionPath()
    {
        return m_sessionPath;
    }

    @property CL_TextDap_Document document()
    {
        return m_document;
    }

    @property void document(CL_TextDap_Document value)
    {
        m_document = value;
    }

    @property EditorOptions options()
    {
        return m_session.options;
    }

    @property DocumentRecord[] history()
    {
        return m_session.documents;
    }

    @property string currentFile()
    {
        return m_session.currentFile;
    }

    public void start()
    {
        Optional!SessionFile found = CL_TextDap_Session.load(m_sessionPath);

        if (found.isNull)
        {
            m_session = emptySession();
        }
        else
        {
            m_session = found.get;
        }

        guardOptions();

        string message;
        if (!CL_TextDap_Session.save(m_session, m_sessionPath, message))
        {
            CL_TextDap_Console.sayFail(message);
            return;
        }

        CL_TextDap_Console.sayNote(format!"the session lives in %s"(m_sessionPath));
        restoreLastFile();
    }

    public bool persist(out string message)
    {
        guardOptions();
        return CL_TextDap_Session.save(m_session, m_sessionPath, message);
    }

    public bool setOptionValue(V)(string jsonPath, V value, out string message)
    {
        if (!CL_TextDap_Session.writeValue!V(m_sessionPath, jsonPath, value, message))
        {
            return false;
        }

        reloadFromDisk();
        return true;
    }

    public bool storeCursor(CursorTarget target, out string message)
    {
        return CL_TextDap_Session.writeCursor(m_sessionPath, target, message);
    }

    public Optional!CursorTarget recallCursor()
    {
        return CL_TextDap_Session.readCursor(m_sessionPath);
    }

    public bool forgetAt(int index, out string message)
    {
        if (!CL_TextDap_History.dropDocumentAt(m_sessionPath, index, message))
        {
            return false;
        }

        reloadFromDisk();
        message = format!"history entry %d was dropped"(index);
        return true;
    }

    public bool noteOpened(string noteText)
    {
        DocumentStats stats = m_document.collectStats();
        DocumentRecord record = makeDocumentRecord(m_document.path,
                shortTitleOf(m_document.path), stats.lineCount, stats.bytesOnDisk,
                stateOf(stats.existsOnDisk, m_document.edited));

        int previous = CL_TextDap_History.historyIndexOf(m_session.documents, record.filePath);
        if (previous >= 0)
        {
            record.note = m_session.documents[previous].note;
        }

        if (!noteText.empty)
        {
            record.note = Optional!string(noteText);
        }

        m_session.currentFile = m_document.path;
        m_session.documents = CL_TextDap_History.touchHistory(m_session.documents, record,
                m_session.options.maxHistory);

        string message;
        if (!persist(message))
        {
            CL_TextDap_Console.sayFail(message);
            return false;
        }

        return true;
    }

    public bool noteSaved()
    {
        return noteOpened("");
    }

    public string[] historyRows()
    {
        string[] rows;

        foreach (index, record; m_session.documents)
        {
            rows ~= CL_TextDap_Frame.cell(to!string(index), record.title)
                    ~ format!" [%s] opens %d, holds %s"(describeState(record.state),
                        record.openCount, CL_TextDap_Console.countWord(record.lineCount, "line"));
        }

        if (rows.empty)
        {
            rows ~= "no file has been opened yet.";
        }

        return rows;
    }

    public string[] optionRows()
    {
        EditorOptions stored = m_session.options;

        return [
                CL_TextDap_Frame.fieldText("title", stored.sessionTitle),
                CL_TextDap_Frame.fieldText("autosave", CL_TextDap_Console.yesNo(stored.autosave)),
                CL_TextDap_Frame.fieldText("numbers", CL_TextDap_Console.yesNo(stored.showLineNumbers)),
                CL_TextDap_Frame.fieldText("tab width", to!string(stored.tabWidth)),
                CL_TextDap_Frame.fieldText("history", format!"%d of %d kept"
                        (m_session.documents.length, stored.maxHistory)),
                CL_TextDap_Frame.fieldText("current", m_session.currentFile),
            ];
    }

    private void reloadFromDisk()
    {
        Optional!SessionFile found = CL_TextDap_Session.load(m_sessionPath);

        if (found.isNull)
        {
            CL_TextDap_Console.sayFail("the session could not be re-read after the edit.");
            return;
        }

        m_session = found.get;
        guardOptions();
    }

    private void restoreLastFile()
    {
        if (m_session.currentFile.empty || !JsonAP.APexistsFile(m_session.currentFile))
        {
            return;
        }

        m_document = new CL_TextDap_Document(m_session.currentFile);

        if (m_document.load())
        {
            CL_TextDap_Console.sayNote("the last file was reopened automatically.");
        }
    }

    private void guardOptions()
    {
        if (!isHistoryLimitAllowed(m_session.options.maxHistory))
        {
            m_session.options.maxHistory = defaultMaxHistory;
        }

        if (m_session.options.tabWidth < 1 || m_session.options.tabWidth > 8)
        {
            m_session.options.tabWidth = 4;
        }

        if (m_session.options.sessionTitle.empty)
        {
            m_session.options.sessionTitle = defaultEditorOptions().sessionTitle;
        }

        m_session.documents = CL_TextDap_History.trimHistory(m_session.documents,
                m_session.options.maxHistory);
    }
}
