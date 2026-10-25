module TextDAPStats;

import TextDAPFileStore;
import std.path;
import std.string;

public struct DocumentStats
{
    bool existsOnDisk;
    long bytesOnDisk;
    int lineCount;
    long charCount;
    long wordCount;
    int longestLine;
    string kind;
    bool jsonDocument;
}

public DocumentStats gather(string path, string[] lines, bool existsOnDisk)
{
    DocumentStats stats;
    stats.existsOnDisk = existsOnDisk;
    stats.bytesOnDisk = existsOnDisk ? CL_TextDap_Store.measuredOrZero(path) : 0;
    stats.lineCount = cast(int) lines.length;

    string content = textOf(lines);
    stats.charCount = content.length;
    stats.wordCount = countWords(content);
    stats.longestLine = longestLineWidth(lines);
    stats.kind = kindOf(path);
    stats.jsonDocument = stats.kind == "json";
    return stats;
}

public string textOf(string[] lines)
{
    string content;

    foreach (index, line; lines)
    {
        if (index > 0)
        {
            content ~= "\n";
        }

        content ~= line;
    }

    return content;
}

public long countWords(string content)
{
    long words;
    bool insideWord;

    foreach (dchar unit; content)
    {
        if (isWordBreak(unit))
        {
            insideWord = false;
            continue;
        }

        if (!insideWord)
        {
            words++;
            insideWord = true;
        }
    }

    return words;
}

public int longestLineWidth(string[] lines)
{
    int longest;

    foreach (line; lines)
    {
        if (cast(int) line.length > longest)
        {
            longest = cast(int) line.length;
        }
    }

    return longest;
}

public string kindOf(string path)
{
    if (path.empty)
    {
        return "none";
    }

    string suffix = toLower(extension(path));

    if (suffix.empty || suffix == ".txt")
    {
        return "plain";
    }

    return suffix[1 .. $];
}

private bool isWordBreak(dchar unit)
{
    return unit == ' ' || unit == '\t' || unit == '\r' || unit == '\n'
        || unit == '\v' || unit == '\f';
}
