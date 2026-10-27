module jsondap_file_tests;

import std.algorithm.searching : canFind;
import std.exception;
import std.file;
import std.json;
import std.stdio;

import JsonDAP;
import jsondap_test_fixtures;

unittest
{
    writeln("-- 9. array and object file API");

    string path = tempJson("array");
    cleanUp(path);

    Point[] points = [Point(1, 2), Point(3, 4)];
    assert(JsonAP.APwriteJsonFile!(Point[])(path, points));
    assert(JsonAP.APexistsFile(path));
    assert(JsonAP.APgetJsonFileSize(path).get > 0);

    Point[] fromFile = JsonAP.APreadJsonArray!Point(path).get;
    assert(fromFile.length == 2);
    assert(fromFile[1] == Point(3, 4));

    Point[] fromText = JsonAP.APdeserializeJsonArray!Point(`[{"x":5,"y":6}]`).get;
    assert(fromText[0] == Point(5, 6));
    assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJsonArray!Point(`{"x":5}`));

    assert(JsonAP.APupdateJsonValueARRAY!int(path, "[1].y", 99));
    assert(JsonAP.APaddJsonItemARRAY!Point(path, "[2]", Point(7, 8)));
    assert(JsonAP.APremoveJsonItemARRAY(path, "[0]"));

    Point[] edited = JsonAP.APreadJsonArray!Point(path).get;
    assert(edited.length == 2);
    assert(edited[0] == Point(3, 99));
    assert(edited[1] == Point(7, 8));

    cleanUp(path);
}

unittest
{
    writeln("-- 10. object file edits: update, nested add, remove, merge");

    string path = tempJson("object");
    cleanUp(path);

    Message message;
    message.text = "before";
    message.level = Level.low;
    assert(JsonAP.APwriteJsonFile!Message(path, message));

    assert(JsonAP.APupdateJsonValueOBJECT!string(path, "text", "after"));
    assert(JsonAP.APaddJsonItemOBJECT!int(path, "extra.count", 5));
    assert(JsonAP.APaddJsonItemOBJECT!string(path, "extra.label", "made"));

    JSONValue root = JsonAP.APreadJsonFile!JSONValue(path).get;
    assert(root["text"].str == "after");
    assert(root["extra"]["count"].integer == 5);

    assert(JsonAP.APremoveJsonItemOBJECT(path, "extra.count"));
    root = JsonAP.APreadJsonFile!JSONValue(path).get;
    assert("count" !in root["extra"].object);

    assert(JsonAP.APmergeJson(path, parseJSON(`{"text":"merged","added":1}`), true, false));
    root = JsonAP.APreadJsonFile!JSONValue(path).get;
    assert(root["text"].str == "merged");
    assert(root["added"].integer == 1);

    cleanUp(path);
}

unittest
{
    writeln("-- 11. JSON path parsing keeps the case of every key");

    PathStep[] steps = JsonAP.APJsonPathParser("MainData.items[2]");
    assert(steps.length == 3);
    assert(steps[0].type == PathStepType.ObjectKey);
    assert(steps[0].key == "MainData");
    assert(steps[1].key == "items");
    assert(steps[2].type == PathStepType.ArrayIndex);
    assert(steps[2].index == 2);

    assert(JsonAP.APgetJsonValue!string(`{"a":{"b":"c"}}`, "a.b").get == "c");
    assert(JsonAP.APisValidJson(`{"ok":true}`));
    assert(!JsonAP.APisValidJson(`{"ok":`));
    assert(JsonAP.APisJsonObject(`{"ok":true}`));
    assert(JsonAP.APisJsonArray(`[1,2]`));
    assert(JsonAP.APgetJsonItemCount(`{"a":1,"b":2}`).get == 2);
}

unittest
{
    writeln("-- 12. an empty or broken input is reported, never silently repaired");

    assert(APstrIsNil_isNull("", "path"), "empty path must be rejected");
    assert(!APstrIsNil_isNull("path", "path"));
}

unittest
{
    writeln("-- 13. a missing file is reported, never a silent null");

    string path = tempJson("missing");
    cleanUp(path);

    assert(!JsonAP.APexistsFile(path));
    assertThrown!FileOperationExceptionAP(JsonAP.APreadJsonFile!Point(path));
    assertThrown!FileOperationExceptionAP(JsonAP.APreadJsonArray!Point(path));
    assertThrown!FileOperationExceptionAP(JsonAP.APgetJsonFileSize(path));

    string message;
    assert(!JsonAP.APupdateJsonValueOBJECTWithMessage!int(path, "x", 1, message));
    assert(canFind(message, "does not exist"), message);
    assert(!JsonAP.APaddJsonItemOBJECTWithMessage!int(path, "x", 1, message));
    assert(canFind(message, "does not exist"), message);
    assert(!JsonAP.APremoveJsonItemARRAYWithMessage(path, "[0]", message));
    assert(canFind(message, "does not exist"), message);
}

unittest
{
    writeln("-- 14. broken JSON on disk is reported, not repaired");

    string path = tempJson("broken");
    std.file.write(path, `{"settings":{"retry": ,}}`);

    assertThrown!JsonOperationExceptionAP(JsonAP.APreadJsonFile!JSONValue(path));
    assertThrown!JsonOperationExceptionAP(JsonAP.APreadJsonArray!Point(path));

    string message;
    assert(!JsonAP.APupdateJsonValueOBJECTWithMessage!int(path, "settings.retry", 3, message));
    assert(canFind(message, "Invalid JSON format in file."), message);

    cleanUp(path);
}

unittest
{
    writeln("-- 15. an unusable path returns false with a reason");

    string path = tempJson("paths");
    cleanUp(path);

    Point[] points = [Point(1, 2)];
    assert(JsonAP.APwriteJsonFile!(Point[])(path, points));

    string message;
    assert(!JsonAP.APupdateJsonValueOBJECTWithMessage!int(path, "[0].x", 5, message),
            "the object overload must not edit a file whose root is an array");
    assert(canFind(message, "not a JSON object"), message);

    assert(!JsonAP.APupdateJsonValueARRAYWithMessage!int(path, "[5].y", 5, message));
    assert(canFind(message, "out of range"), message);

    assert(!JsonAP.APaddJsonItemOBJECTWithMessage!int(path, "made.up.key", 1, message),
            "the root is an array, so no object key can be created");
    assert(canFind(message, "not a JSON object"), message);

    assert(!JsonAP.APremoveJsonItemOBJECTWithMessage(path, "missing.key", message));
    assert(canFind(message, "not a JSON object"), message);

    assert(JsonAP.APwriteJsonFile!JSONValue(path, parseJSON(`{"items":{"k":1}}`)));
    assert(!JsonAP.APupdateJsonValueOBJECTWithMessage!int(path, "items[0].x", 5, message),
            "the object overload must not follow an array step");
    assert(canFind(message, "APupdateJsonValueARRAY"), message);

    assert(JsonAP.APwriteJsonFile!(Point[])(path, points));
    assert(!JsonAP.APmergeJsonWithMessage(path, JSONValue.init, true, false, message));
    assert(canFind(message, "empty"), message);

    Point[] untouched = JsonAP.APreadJsonArray!Point(path).get;
    assert(untouched.length == 1, "a failed edit must leave the file as it was");
    assert(untouched[0] == Point(1, 2));

    cleanUp(path);
}

unittest
{
    writeln("-- 16. a successful edit leaves an empty message");

    string path = tempJson("messages");
    cleanUp(path);

    Message message;
    message.text = "before";
    message.level = Level.low;
    assert(JsonAP.APwriteJsonFile!Message(path, message));

    string reason = "sentinel";
    assert(JsonAP.APupdateJsonValueOBJECTWithMessage!string(path, "text", "after", reason));
    assert(reason.length == 0, "a successful call must clear the message");

    assert(JsonAP.APaddJsonItemOBJECTWithMessage!int(path, "extra", 1, reason));
    assert(reason.length == 0);

    assert(JsonAP.APremoveJsonItemOBJECTWithMessage(path, "extra", reason));
    assert(reason.length == 0);

    cleanUp(path);
}

unittest
{
    writeln("-- 17. an unusable array index is an exception, never a dead process");

    assertThrown!InvalidArgumentExceptionAP(JsonAP.APJsonPathParser("items[]"));
    assertThrown!InvalidArgumentExceptionAP(JsonAP.APJsonPathParser("items[x]"));
    assertThrown!InvalidArgumentExceptionAP(JsonAP.APJsonPathParser("items[2"));
    assertThrown!ConvertExceptionAP(JsonAP.APJsonPathParser("items[2147483648]"));

    PathStep[] parsed = JsonAP.APJsonPathParser("items[2].name");
    assert(parsed.length == 3);
    assert(parsed[1].type == PathStepType.ArrayIndex);
    assert(parsed[1].index == 2);
}

unittest
{
    writeln("-- 18. digits from every supported block reach the same conversion");

    assert(JsonAP.APisDigitAP('7'));
    assert(JsonAP.APisDigitAP('۵'));
    assert(JsonAP.APisDigitAP('٧'));
    assert(!JsonAP.APisDigitAP('x'));

    assert(JsonAP.APnormalizeDigitsAP("۵٧7x") == "577x", JsonAP.APnormalizeDigitsAP("۵٧7x"));

    PathStep[] persian = JsonAP.APJsonPathParser("items[۲]");
    assert(persian[1].index == 2, "a Persian digit index must parse like an ASCII one");

    PathStep[] arabic = JsonAP.APJsonPathParser("items[٢]");
    assert(arabic[1].index == 2, "an Arabic digit index must parse like an ASCII one");
}

unittest
{
    writeln("-- 19. a whole number request on a float says so precisely");

    string json = `{"meta":{"count":2.5,"rating":4}}`;

    auto rating = JsonAP.APgetJsonValue!long(json, "meta.rating");
    assert(!rating.isNull);
    assert(rating.get == 4);

    assertThrown!ConvertExceptionAP(JsonAP.APgetJsonValue!long(json, "meta.count"));

    auto asDouble = JsonAP.APgetJsonValue!double(json, "meta.count");
    assert(!asDouble.isNull);
    assert(asDouble.get == 2.5);
}

unittest
{
    writeln("-- 20. both call shapes of the merge API agree");

    string path = tempJson("mergeShapes");
    cleanUp(path);

    assert(JsonAP.APwriteJsonFile!JSONValue(path, parseJSON(`{"title":"first","size":1}`)));

    assert(JsonAP.APmergeJsonWithMessage(path, parseJSON(`{"title":"second"}`)).length == 0,
            "an empty string is the only thing a successful merge may return");

    string reason;
    assert(JsonAP.APmergeJsonWithMessage(path, parseJSON(`{"extra":true}`), true, false, reason));
    assert(reason.length == 0);

    assert(!JsonAP.APmergeJsonWithMessage(path, JSONValue.init, true, false, reason));
    assert(canFind(reason, "empty"), reason);

    assert(JsonAP.APmergeJsonWithMessage(path, JSONValue.init).length > 0);

    JSONValue stored = JsonAP.APreadJsonFile!JSONValue(path).get;
    assert(stored["title"].str == "second");
    assert(stored["extra"].type == JSONType.TRUE);

    cleanUp(path);
}

private bool APstrIsNil_isNull(string input, string paramName)
{
    bool rejected;
    string errorText;
    JsonAP.APstrIsNil(input, paramName, rejected, errorText);
    return rejected;
}
