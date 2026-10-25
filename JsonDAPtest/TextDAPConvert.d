module TextDAPConvert;

import JsonDAP;
import TextDAPConsole;
import TextDAPFrame;
import TextDAPModel;
import std.conv;
import std.format;
import std.json;
import std.string;
import std.utf : decode;

public class CL_TextDap_Convert
{
    public static bool recordRoundTrip(DocumentRecord record)
    {
        try
        {
            JSONValue wire = JsonAP.APserializeTToJsonValue!DocumentRecord(record);

            CL_TextDap_Frame.showFrame("record on the wire", [
                    CL_TextDap_Frame.fieldText("type", to!string(JsonAP.APgetJsonValueType(wire))),
                    CL_TextDap_Frame.fieldText("json", CL_TextDap_Frame.clip(wire.toString(), 54)),
                ]);

            auto readBack = JsonAP.APconvertJsonValueToT!DocumentRecord(wire, false);
            if (readBack.isNull)
            {
                CL_TextDap_Console.sayFail("the record read back as nothing.");
                return false;
            }

            DocumentRecord copy = readBack.get;

            if (copy.filePath != record.filePath || copy.openCount != record.openCount
                    || copy.state != record.state)
            {
                CL_TextDap_Console.sayFail("the record changed during the round trip.");
                return false;
            }

            CL_TextDap_Console.sayDone(format!"the record came back unchanged (%d wire fields)"
                    (wire.object.length));
            CL_TextDap_Console.sayNote("the lookup key is @JsonIgnore, so it never leaves memory.");
            return true;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return false;
        }
    }

    public static bool cursorRoundTrip(CursorTarget target)
    {
        try
        {
            JSONValue envelope = JsonAP.APserializeSumType!CursorTarget(target,
                    (string memberName) => cursorTagName(memberName));

            Optional!CursorTarget readBack = JsonAP.APdeserializeSumType!CursorTarget(envelope,
                    false, (string memberName) => cursorTagName(memberName));

            if (readBack.isNull)
            {
                CL_TextDap_Console.sayFail("the cursor envelope read back as nothing.");
                return false;
            }

            CL_TextDap_Frame.showFrame("cursor envelope", [
                    CL_TextDap_Frame.fieldText("written", CL_TextDap_Frame.clip(envelope.toString(), 54)),
                    CL_TextDap_Frame.fieldText("tag", cursorTagOf(target)),
                    CL_TextDap_Frame.fieldText("read", CL_TextDap_Frame.clip(describeCursor(readBack.get).get, 54)),
                ]);

            return true;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return false;
        }
    }

    public static bool exportHistory(DocumentRecord[] records, string outPath)
    {
        string blankReason;
        bool blankFlag;
        JsonAP.APStrIsNUll(outPath, "export path", blankFlag, blankReason);

        if (blankFlag)
        {
            CL_TextDap_Console.sayFail(blankReason);
            return false;
        }

        try
        {
            JSONValue[] wire;
            foreach (record; records)
            {
                wire ~= JsonAP.APserializeToJsonArray!DocumentRecord(record);
            }

            if (!JsonAP.APwriteJsonFile!JSONValue(outPath, JSONValue(wire)))
            {
                CL_TextDap_Console.sayFail(format!"nothing was written to %s"(outPath));
                return false;
            }

            Optional!(DocumentRecord[]) imported = JsonAP.APreadJsonArray!DocumentRecord(outPath);
            if (imported.isNull)
            {
                CL_TextDap_Console.sayFail("the exported array could not be read back.");
                return false;
            }

            CL_TextDap_Console.sayDone(format!"%s exported to %s and read back"
                    (CL_TextDap_Console.countWord(imported.get.length, "record"), outPath));
            return true;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return false;
        }
    }

    public static bool enumGuardDemo()
    {
        string broken = `{"file_path":"notes.txt","title":"guard","open_count":1,`
                ~ `"line_count":1,"size_bytes":1,"state":9}`;

        if (!JsonAP.APisValidJson(broken))
        {
            CL_TextDap_Console.sayFail("the sample document itself is malformed.");
            return false;
        }

        try
        {
            auto parsed = JsonAP.APdeserializeJsonLenient!DocumentRecord(broken);
            if (!parsed.isNull)
            {
                CL_TextDap_Console.sayNote("state 9 was accepted; this build tightened the guard.");
                return false;
            }

            CL_TextDap_Console.sayFail("the reader returned nothing without raising an error.");
            return false;
        }
        catch (JSONConvertExceptionAP caught)
        {
            CL_TextDap_Frame.showFrame("rejected enum", [
                    CL_TextDap_Frame.fieldText("field", caught.parameterName),
                    CL_TextDap_Frame.fieldText("value", caught.invalidValue),
                    CL_TextDap_Frame.fieldText("code", caught.jsonSpecificError),
                    CL_TextDap_Frame.fieldText("wanted", CL_TextDap_Frame.clip(caught.reasonForFailure, 50)),
                ]);
            return true;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return false;
        }
    }

    public static bool arrayAndMergeDemo()
    {
        string pack = `[{"file_path":"a.txt","title":"first","open_count":2,"line_count":3,`
                ~ `"size_bytes":40,"state":0,"note":null},{"file_path":"b.txt","title":"second",`
                ~ `"open_count":1,"line_count":9,"size_bytes":10,"state":1,"note":null}]`;

        if (!JsonAP.APisValidJson(pack))
        {
            CL_TextDap_Console.sayFail("the sample array itself is not JSON.");
            return false;
        }

        try
        {
            Optional!(DocumentRecord[]) many = JsonAP.APdeserializeJsonArray!DocumentRecord(pack);
            if (many.isNull || many.get.length < 2)
            {
                CL_TextDap_Console.sayFail("the array did not read as two records.");
                return false;
            }

            JSONValue base = JsonAP.APserializeToJson!DocumentRecord(many.get[0]);
            JSONValue added = JsonAP.APserializeToJson!DocumentRecord(many.get[1]);

            string mergeMessage;
            if (!JsonAP.APrecursiveMerge(base, added, true, false, mergeMessage))
            {
                CL_TextDap_Console.sayFail(mergeMessage);
                return false;
            }

            auto merged = JsonAP.APconvertJsonValueToT!DocumentRecord(base, true);

            CL_TextDap_Frame.showFrame("array in, merge, record out", [
                    CL_TextDap_Frame.fieldText("read", format!"%s from text"
                            (CL_TextDap_Console.countWord(many.get.length, "record"))),
                    CL_TextDap_Frame.fieldText("keys", format!"%s after the merge"(base.object.length)),
                    CL_TextDap_Frame.fieldText("title", merged.isNull ? "nothing" : merged.get.title),
                    CL_TextDap_Frame.fieldText("path", merged.isNull ? "nothing" : merged.get.filePath),
                ]);

            return !merged.isNull;
        }
        catch (BaseExceptionAP caught)
        {
            CL_TextDap_Console.sayFail(caught.msg);
            return false;
        }
    }

    public static bool digitGateDemo()
    {
        string[] samples = ["7", "٧", "۵", "x"];
        string[] rows;

        foreach (sample; samples)
        {
            size_t at;
            dchar unit = decode(sample, at);

            rows ~= CL_TextDap_Frame.fieldText(format!"U+%04X"(cast(int) unit),
                    format!"'%s' library %s, ascii %s"(sample,
                    CL_TextDap_Console.yesNo(JsonAP.APisDigitAP(unit)),
                    CL_TextDap_Console.yesNo(CL_TextDap_Console.isPlainAsciiDigits(sample))));
        }

        CL_TextDap_Frame.showFrame("which digits pass", rows);
        CL_TextDap_Console.sayNote("the editor keeps only ASCII digits, so line numbers stay predictable.");
        return true;
    }

    public static bool strictVersusLenient()
    {
        string partial = `{"schema":"` ~ sessionSchema ~ `"}`;
        string readMode;

        try
        {
            auto strict = JsonAP.APdeserializeJson!SessionFile(partial);
            readMode = strict.isNull ? "returned nothing" : "accepted the sparse document";
        }
        catch (JSONConvertExceptionAP caught)
        {
            readMode = format!"refused it (%s)"(firstLine(caught.jsonSpecificError));
        }
        catch (BaseExceptionAP caught)
        {
            readMode = format!"refused it (%s)"(firstLine(caught.msg));
        }

        auto lenient = JsonAP.APdeserializeJsonLenient!SessionFile(partial);

        CL_TextDap_Frame.showFrame("reading the same text", [
                CL_TextDap_Frame.fieldText("strict", readMode),
                CL_TextDap_Frame.fieldText("lenient", lenient.isNull ? "returned nothing"
                        : format!"filled %s with defaults"(TextDapPath.documents)),
            ]);

        return !lenient.isNull;
    }

    private static string firstLine(string message)
    {
        string[] parts = split(message, "\n");
        return parts.empty ? message : parts[0];
    }
}
