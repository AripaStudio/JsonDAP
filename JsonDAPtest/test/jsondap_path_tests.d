module jsondap_path_tests;

import JsonDAP;

import std.algorithm : canFind;
import std.conv : to;
import std.file : exists, readText, remove, write;
import std.json : JSONValue, JSONType, parseJSON;
import std.stdio : writeln;

private string seed(string name, string content)
{
    write(name, content);
    return name;
}

private void discard(string path)
{
    if (exists(path))
    {
        remove(path);
    }
}

unittest
{
    writeln("==================================================");
    writeln("STARTING 2.4.1 INDEX, PATH AND COPY TESTS");
    writeln("==================================================");

    string path = seed("jsondap_240_items.json", `{"items":[10,20,30]}`);

    bool added;
    string reason;

    added = JsonAP.APaddJsonItemARRAYWithMessage!int(path, "items[0]", 99, reason);
    assert(added, reason);
    assert(reason.length == 0, "a successful add must not report anything");
    assert(readText(path) == `{"items":[99,10,20,30]}`, readText(path));

    added = JsonAP.APaddJsonItemARRAYWithMessage!int(path, "items[3]", 1, reason);
    assert(added, reason);
    assert(readText(path) == `{"items":[99,10,20,1,30]}`, readText(path));

    added = JsonAP.APaddJsonItemARRAYWithMessage!int(path, "items[5]", 7, reason);
    assert(added, reason);
    assert(readText(path) == `{"items":[99,10,20,1,30,7]}`, readText(path));

    added = JsonAP.APaddJsonItemARRAYWithMessage!int(path, "items[9]", 2, reason);
    assert(!added, "an index past the end must be refused");
    assert(canFind(reason, "out of range"), reason);
    assert(!canFind(reason, "appended"), reason);
    assert(readText(path) == `{"items":[99,10,20,1,30,7]}`, "a refused add must leave the file alone");

    added = JsonAP.APaddJsonItemARRAYWithMessage!int(path, "items[-1]", 3, reason);
    assert(!added, "a negative index must be refused");
    assert(canFind(reason, "non-negative"), reason);
    assert(readText(path) == `{"items":[99,10,20,1,30,7]}`, readText(path));

    bool updated;
    updated = JsonAP.APupdateJsonValueARRAYWithMessage!int(path, "items[1]", 77, reason);
    assert(updated, reason);
    assert(readText(path) == `{"items":[99,77,20,1,30,7]}`, readText(path));

    updated = JsonAP.APupdateJsonValueARRAYWithMessage!int(path, "items[6]", 77, reason);
    assert(!updated, "updating an index past the end must be refused");
    assert(canFind(reason, "out of range"), reason);

    updated = JsonAP.APupdateJsonValueARRAYWithMessage!int(path, "items[-2]", 77, reason);
    assert(!updated, "a negative index must be refused");
    assert(canFind(reason, "non-negative"), reason);

    discard(path);

    PathStep[] steps = JsonAP.APJsonPathParser("a.b[2].c");
    assert(steps.length == 4, to!string(steps.length));
    assert(steps[0].type == PathStepType.ObjectKey && steps[0].key == "a");
    assert(steps[1].type == PathStepType.ObjectKey && steps[1].key == "b");
    assert(steps[2].type == PathStepType.ArrayIndex && steps[2].index == 2);
    assert(steps[3].type == PathStepType.ObjectKey && steps[3].key == "c");

    PathStep[] escaped = JsonAP.APJsonPathParser("weird\\.key.next");
    assert(escaped.length == 2, to!string(escaped.length));
    assert(escaped[0].key == "weird.key", escaped[0].key);
    assert(escaped[1].key == "next", escaped[1].key);

    PathStep[] persian = JsonAP.APJsonPathParser("items[۲]");
    assert(persian.length == 2);
    assert(persian[1].type == PathStepType.ArrayIndex && persian[1].index == 2);

    PathStep[] chained = JsonAP.APJsonPathParser("rows[0][1]");
    assert(chained.length == 3, to!string(chained.length));
    assert(chained[1].index == 0 && chained[2].index == 1);

    string[] badPaths = ["", "   ", "a..b", "items[3", "items]", "items[0]x", "items[abc]"];
    foreach (bad; badPaths)
    {
        bool threw;
        try
        {
            JsonAP.APJsonPathParser(bad);
        }
        catch (BaseExceptionAP caught)
        {
            threw = true;
            assert(caught.msg.length > 0, bad);
        }
        assert(threw, "the parser must refuse " ~ bad);
    }

    assert(JsonAP.APgetJsonValue!int(`{"items":[10,20,30]}`, "items[1]") == 20);
    assert(JsonAP.APgetJsonValue!int(`{"a":{"b":[1,2,3]}}`, "a.b[2]") == 3);
    assert(JsonAP.APgetJsonValue!int(`{"items":[10,20,30]}`, "items[0]") == 10);

    assert(JsonAP.APgetJsonValue!double(`{"items":[10,20,30]}`, "items[1]") == 20,
            "an integer node read as double must convert, not crash");
    assert(JsonAP.APgetJsonValue!float(`{"a":{"b":1.5}}`, "a.b") == 1.5f);
    assert(JsonAP.APgetJsonValue!double(`{"a":{"b":1.5}}`, "a.b") == 1.5);

    bool refused;
    try
    {
        JsonAP.APgetJsonValue!int(`{"items":[10]}`, "items[5]");
    }
    catch (BaseExceptionAP caught)
    {
        refused = true;
        assert(canFind(caught.msg, "out of bounds"), caught.msg);
    }
    assert(refused, "an index past the end must be refused by the getter too");

    JSONValue target = parseJSON(`{"keep":1,"shared":{"deep":1}}`);
    JSONValue source = parseJSON(`{"shared":{"deep":2,"added":3},"fresh":true}`);

    bool merged = JsonAP.APrecursiveMerge(target, parseJSON(`{"shared":{"deep":9}}`),
            true, false, reason);
    assert(merged, reason);
    assert(target.object["shared"].object["deep"] == JSONValue(9));

    JSONValue untouched = parseJSON(`{"keep":1,"shared":{"deep":1}}`);
    JSONValue result;
    merged = JsonAP.APrecursiveMergeCopy(untouched, source, true, false, result, reason);
    assert(merged, reason);
    assert(!("fresh" in untouched.object), "the copy form must not write into its target");
    assert(result.object["fresh"].type == JSONType.TRUE);
    assert(result.object["shared"].object["added"] == JSONValue(3));

    JSONValue original = parseJSON(`{"list":[1,2,{"k":"v"}]}`);
    JSONValue copy = JsonAP.APdeepCopy(original);
    copy.object["list"].array[0] = JSONValue(99);
    copy.object["list"].array[2].object["k"] = JSONValue("changed");
    assert(original.object["list"].array[0] == JSONValue(1), "a deep copy must not share the array");
    assert(original.object["list"].array[2].object["k"] == JSONValue("v"),
            "a deep copy must not share nested objects");

    assert(JsonAP.APisInteger("12345"));
    assert(!JsonAP.APisInteger("-12"), "a sign is not a digit");
    assert(!JsonAP.APisInteger("1.2"));
    assert(JsonAP.APisInteger("۱۲۳"));
    assert(JsonAP.APisSignedInteger("-12"));
    assert(!JsonAP.APisSignedInteger("1.2"));
    assert(JsonAP.APisDecimal("12.5"));
    assert(!JsonAP.APisDecimal("12"), "a whole number is not a decimal");
    assert(!JsonAP.APisDecimal("1.2.3"));
    assert(JsonAP.APnormalizeDigitsAP("۱۲٫۵") == "12.5", JsonAP.APnormalizeDigitsAP("۱۲٫۵"));
    assert(JsonAP.APnormalizeDigitsAP("−7") == "-7", JsonAP.APnormalizeDigitsAP("−7"));

    writeln("2.4.1 INDEX, PATH AND COPY TESTS PASSED");
}
