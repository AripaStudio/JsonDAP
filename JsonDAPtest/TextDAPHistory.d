module TextDAPHistory;

import JsonDAP;
import TextDAPModel;
import std.format;

public class CL_TextDap_History
{
    public static string documentPath(int index)
    {
        return format!"%s[%d]"(TextDapPath.documents, index);
    }

    public static DocumentRecord[] touchHistory(DocumentRecord[] records, DocumentRecord opened,
            int maxHistory)
    {
        DocumentRecord[] kept;

        foreach (record; records)
        {
            if (record.lookupKey != opened.lookupKey)
            {
                kept ~= record;
            }
            else
            {
                opened.openCount = record.openCount + 1;
            }
        }

        kept ~= opened;

        return trimHistory(kept, maxHistory);
    }

    public static DocumentRecord[] trimHistory(DocumentRecord[] records, int maxHistory)
    {
        if (!isHistoryLimitAllowed(maxHistory) || cast(int) records.length <= maxHistory)
        {
            return records;
        }

        return records[records.length - maxHistory .. $];
    }

    public static int historyIndexOf(DocumentRecord[] records, string filePath)
    {
        string wanted = makeLookupKey(filePath);

        foreach (index, record; records)
        {
            if (record.lookupKey == wanted)
            {
                return cast(int) index;
            }
        }

        return -1;
    }

    public static bool dropDocumentAt(string filePath, int index, out string message)
    {
        message = "";

        if (index < 0)
        {
            message = "a history entry needs a position of zero or more.";
            return false;
        }

        return JsonAP.APremoveJsonItemARRAYWithMessage(filePath, documentPath(index), message);
    }
}
