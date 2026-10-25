module TextDAPFrame;

import std.format;
import std.stdio;

public enum innerWidth = 70;
public enum menuColumnWidth = 34;
public enum keyColumnWidth = 6;
public enum labelColumnWidth = 14;

public class CL_TextDap_Frame
{
    public static void showBanner(string appName, string tagline)
    {
        writeln(edge('='));
        writeln(centered(appName));
        writeln(centered(tagline));
        writeln(edge('='));
    }

    public static void showFrame(string title, string[] rows)
    {
        writeln(titleEdge(title));

        foreach (row; rows)
        {
            writeln(bodyRow(row));
        }

        writeln(edge('-'));
    }

    public static string cell(string key, string label)
    {
        return padRight("  " ~ key, keyColumnWidth) ~ padRight(label, menuColumnWidth - keyColumnWidth);
    }

    public static string fieldText(string label, string value)
    {
        return "  " ~ padRight(label, labelColumnWidth) ~ clip(value, innerWidth - labelColumnWidth - 4);
    }

    public static string clip(string text, int width)
    {
        if (text is null || width <= 0)
        {
            return "";
        }

        if (cast(int) text.length <= width)
        {
            return text;
        }

        int cut = width - 1;
        while (cut > 0 && isUtf8Tail(text[cut]))
        {
            cut--;
        }

        return text[0 .. cut] ~ "~";
    }

    public static string padRight(string text, int width)
    {
        string clipped = clip(text, width);
        return clipped ~ spaces(width - cast(int) clipped.length);
    }

    private static string edge(char fill)
    {
        return "+" ~ fillLine(fill, innerWidth) ~ "+";
    }

    private static string titleEdge(string title)
    {
        string label = "-- " ~ clip(title, innerWidth - 4) ~ " ";
        return "+" ~ label ~ fillLine('-', innerWidth - cast(int) label.length) ~ "+";
    }

    private static string bodyRow(string text)
    {
        return "|" ~ padRight("  " ~ text, innerWidth) ~ "|";
    }

    private static string centered(string text)
    {
        string clipped = clip(text, innerWidth);
        int gap = innerWidth - cast(int) clipped.length;
        int left = gap / 2;

        return "|" ~ spaces(left) ~ clipped ~ spaces(gap - left) ~ "|";
    }

    private static string fillLine(char fill, int count)
    {
        if (count <= 0)
        {
            return "";
        }

        char[] line;
        line.length = count;
        line[] = fill;
        return cast(string) line;
    }

    private static string spaces(int count)
    {
        return fillLine(' ', count);
    }

    private static bool isUtf8Tail(char unit)
    {
        return (cast(ubyte) unit & 0xC0) == 0x80;
    }
}
