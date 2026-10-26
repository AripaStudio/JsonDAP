module TextDAPFrame;

import std.conv : to;
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

        if (displayWidth(text) <= width)
        {
            return text;
        }

        dchar[] units = to!(dchar[])(text);
        return cast(string) units[0 .. width - 1] ~ "~";
    }

    public static string padRight(string text, int width)
    {
        string clipped = clip(text, width);
        return clipped ~ spaces(width - displayWidth(clipped));
    }

    public static int displayWidth(string text)
    {
        return text is null ? 0 : cast(int) to!(dchar[])(text).length;
    }

    private static string edge(char fill)
    {
        return "+" ~ fillLine(fill, innerWidth) ~ "+";
    }

    private static string titleEdge(string title)
    {
        string label = "-- " ~ clip(title, innerWidth - 4) ~ " ";
        return "+" ~ label ~ fillLine('-', innerWidth - displayWidth(label)) ~ "+";
    }

    private static string bodyRow(string text)
    {
        return "|" ~ padRight("  " ~ text, innerWidth) ~ "|";
    }

    private static string centered(string text)
    {
        string clipped = clip(text, innerWidth);
        int gap = innerWidth - displayWidth(clipped);
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
}
