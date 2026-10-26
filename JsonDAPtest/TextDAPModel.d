module TextDAPModel;

import JsonDAP;
import std.conv;
import std.json;
import std.path : baseName;
import std.string;
import std.sumtype;
import std.typecons;

alias Optional = Nullable;

public enum sessionSchema = "textdap.session.1";
public enum defaultSessionPath = "textdap_session.json";
public enum defaultHistoryPath = "textdap_history.json";
public enum defaultMaxHistory = 12;
public enum minimumHistory = 1;
public enum maximumHistory = 200;

public enum DocumentState
{
    saved = 0,
    edited = 1,
    missing = 2
}

public struct DocumentRecord
{
    @JsonName("file_path") string filePath;
    @JsonName("title") string title;
    @JsonName("open_count") int openCount;
    @JsonName("line_count") int lineCount;
    @JsonName("size_bytes") long sizeBytes;
    @JsonName("state") DocumentState state;
    @JsonName("note") Optional!string note;
    @JsonIgnore string lookupKey;
}

public struct EditorOptions
{
    @JsonName("autosave") bool autosave;
    @JsonName("show_line_numbers") bool showLineNumbers;
    @JsonName("max_history") int maxHistory;
    @JsonName("tab_width") int tabWidth;
    @JsonName("session_title") string sessionTitle;
}

public struct SessionFile
{
    @JsonName("schema") string schema;
    @JsonName("options") EditorOptions options;
    @JsonName("current_file") string currentFile;
    @JsonName("documents") DocumentRecord[] documents;
}

public alias CursorTarget = SumType!(int, string);

public struct CursorTag
{
    public enum line = "line";
    public enum search = "search";
}

public struct TextDapPath
{
    public enum schema = "schema";
    public enum currentFile = "current_file";
    public enum options = "options";
    public enum documents = "documents";
    public enum autosave = "options.autosave";
    public enum lineNumbers = "options.show_line_numbers";
    public enum maxHistory = "options.max_history";
    public enum tabWidth = "options.tab_width";
    public enum sessionTitle = "options.session_title";
    public enum cursor = "cursor";
}

public EditorOptions defaultEditorOptions()
{
    EditorOptions options;
    options.autosave = true;
    options.showLineNumbers = true;
    options.maxHistory = defaultMaxHistory;
    options.tabWidth = 4;
    options.sessionTitle = "TextDAP session";
    return options;
}

public SessionFile emptySession()
{
    SessionFile session;
    session.schema = sessionSchema;
    session.options = defaultEditorOptions();
    session.currentFile = "";
    session.documents = [];
    return session;
}

public DocumentRecord makeDocumentRecord(string filePath, string title, int lineCount,
        long sizeBytes, DocumentState state)
{
    DocumentRecord record;
    record.filePath = filePath;
    record.title = title;
    record.openCount = 1;
    record.lineCount = lineCount;
    record.sizeBytes = sizeBytes;
    record.state = state;
    record.note = Optional!string.init;
    record.lookupKey = makeLookupKey(filePath);
    return record;
}

public string makeLookupKey(string filePath)
{
    if (filePath is null)
    {
        return "";
    }
    return toLower(filePath);
}

public string shortTitleOf(string filePath)
{
    if (filePath is null || filePath.empty)
    {
        return "";
    }
    return baseName(filePath);
}

public DocumentState stateOf(bool existsOnDisk, bool editedInMemory)
{
    if (!existsOnDisk)
    {
        return DocumentState.missing;
    }
    if (editedInMemory)
    {
        return DocumentState.edited;
    }
    return DocumentState.saved;
}

public string describeState(DocumentState state)
{
    final switch (state)
    {
    case DocumentState.saved:
        return "saved";
    case DocumentState.edited:
        return "edited";
    case DocumentState.missing:
        return "missing";
    }
}

public bool isHistoryLimitAllowed(int value)
{
    return value >= minimumHistory && value <= maximumHistory;
}

public string cursorTagName(string memberName)
{
    if (memberName == "int")
    {
        return CursorTag.line;
    }
    if (memberName == "string")
    {
        return CursorTag.search;
    }
    return memberName;
}

public string cursorTagOf(CursorTarget target)
{
    return target.match!(
        (int line) => CursorTag.line,
        (string term) => CursorTag.search
    );
}

public JSONValue cursorPayloadOf(CursorTarget target)
{
    return target.match!(
        (int line) => JSONValue(line),
        (string term) => JSONValue(term)
    );
}

public CursorTarget resolveCursor(string tag, JSONValue payload)
{
    if (tag == CursorTag.line)
    {
        requireNodeType(tag, payload, JSONType.INTEGER);
        return CursorTarget(cast(int) payload.integer);
    }

    if (tag == CursorTag.search)
    {
        requireNodeType(tag, payload, JSONType.STRING);
        return CursorTarget(payload.str);
    }

    throw new JsonOperationExceptionAP("Unknown cursor tag in the session document.",
            TextDapPath.cursor, tag ~ " (known tags: " ~ CursorTag.line ~ ", "
            ~ CursorTag.search ~ ")");
}

public Optional!string describeCursor(CursorTarget target)
{
    return target.match!(
        (int line) => Optional!string("line " ~ to!string(line)),
        (string term) => Optional!string("search \"" ~ term ~ "\"")
    );
}

private void requireNodeType(string tag, JSONValue payload, JSONType expected)
{
    if (payload.type == expected)
    {
        return;
    }

    throw new JSONConvertExceptionAP("The cursor payload does not match its tag.",
            tag, payload.to!string(), payload.type.to!string(), expected.to!string(),
            "CursorPayloadMismatch", "resolveCursor",
            "Tag " ~ tag ~ " needs a " ~ expected.to!string() ~ " payload.");
}

static assert(IsStructAP!DocumentRecord.value);
static assert(IsStructAP!EditorOptions.value);
static assert(IsEnumAP!DocumentState.value);
static assert(IsArrayAP!(DocumentRecord[]).value);
static assert(IsStringAP!(typeof(sessionSchema)).value);
static assert(!IsNumberAP!DocumentState.value);
