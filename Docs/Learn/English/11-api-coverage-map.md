# 11 — The API, one example at a time

Index: [StartEn.md](../../StartEn.md) · Previous: [10](10-exceptions.md)

Every exported `AP…` name in one place, each with a program that runs on its own. This chapter is
a workbench, not a lesson: read it after the earlier ones, or jump straight to the section you
need and copy the block.

**Setup is one line.** Each block begins with the imports it needs — `import JsonDAP` plus Phobos
is the whole of it, and chapter [01](01-setup.md) shows the `dub.json` entry. Put the block in
`app.d`, run `dub run`, and compare the output with the note under it. No file from
`JsonDAPtest/` is used anywhere below: the packaged `Docs/` folder travels without that project.

**Two habits worth keeping.** A method that answers `bool` never hides a failure — its
`…WithMessage` twin hands you the sentence. A reader that answers `Optional!T` means only "there
is no value"; a broken document throws (chapter [10](10-exceptions.md)).

## 1 — A file round trip

Six methods, one file, no surprises. `APwriteJsonFile` creates the folders on the way, so the
first write into `data/app/` is not a special case.

```d
import JsonDAP, std.file, std.stdio;

struct Point
{
    int x;
    int y;
}

void main()
{
    string file = "point.json";
    if (JsonAP.APexistsFile(file))
    {
        remove(file);
    }

    writeln(JsonAP.APexistsFile(file));
    writeln(JsonAP.APwriteJsonFile!Point(file, Point(3, 4)));
    writeln(readText(file));
    writeln(JsonAP.APexists(file));
    writeln(JsonAP.APgetJsonFileSize(file).get);

    Point back = JsonAP.APreadJsonFile!Point(file).get;
    writeln(back.x, " ", back.y);

    string list = "points.json";
    JsonAP.APwriteJsonFile!(Point[])(list, [Point(1, 2), Point(3, 4)]);
    writeln(readText(list));

    Point[] all = JsonAP.APreadJsonArray!Point(list).get;
    writeln(all.length);
}
```

prints:

```text
false
true
{"x":3,"y":4}
true
13
3 4
[{"x":1,"y":2},{"x":3,"y":4}]
2
```

| Method | Answers | What it means |
|---|---|---|
| `APwriteJsonFile!T(file, value)` | `bool` | serialises `T` and writes it; missing folders are created |
| `APreadJsonFile!T(file)` | `Optional!T` | the file must hold an **object** |
| `APreadJsonArray!T(file)` | `Optional!(T[])` | the file must hold an **array** |
| `APgetJsonFileSize(file)` | `Optional!long` | size in bytes |
| `APexistsFile(file)` | `bool` | a file is there |
| `APexists(path)` | `bool` | a file **or** a folder is there |

`APreadJsonFile` and `APreadJsonArray` split by shape on purpose: one document is one record, a
list of records is one array. Asking for the wrong shape is an error, not an empty result.

`.get` is safe in this block because the write just happened. In real code check `isNull` or let
the exception fly — never `.get` blind after reading a path someone typed.

## 2 — Types and the round trip

`APserializeToJson` walks your type and gives you a `JSONValue`; `APdeserializeJson` walks back.
Both sides obey the same field names, and `@JsonIgnore` fields stay home.

```d
import JsonDAP, std.json, std.stdio, std.typecons;

alias Optional = Nullable;

enum Priority
{
    low,
    high
}

struct Settings
{
    @JsonName("tab_width") int tabWidth;
    @JsonIgnore string cacheKey;
    Optional!bool autosave;
}

void main()
{
    Settings editor = Settings(4, "never-serialised", Optional!bool(true));

    JSONValue wire = JsonAP.APserializeToJson!Settings(editor);
    writeln(wire.toString());

    Settings back = JsonAP.APdeserializeJson!Settings(wire.toString()).get;
    writeln(back.tabWidth);

    auto lenient = JsonAP.APdeserializeJsonLenient!Settings(`{"autosave":false}`);
    writeln(lenient.get.tabWidth);

    JSONValue lowLevel = JsonAP.APserializeTToJsonValue!Settings(Settings(8, null, Optional!bool.init));
    writeln(lowLevel.toString());
    auto converted = JsonAP.APconvertJsonValueToT!Settings(lowLevel, false);
    writeln(converted.get.tabWidth);

    JSONValue[] oneItem = JsonAP.APserializeToJsonArray!Settings(editor);
    writeln(oneItem.length);
    auto many = JsonAP.APdeserializeJsonArray!Settings(`[{"tab_width":1},{"tab_width":2}]`);
    writeln(many.get.length);

    writeln(JsonAP.APgetJsonValueType(wire));

    static assert(IsIntAP!int.value && IsFloatAP!double.value && IsBoolAP!bool.value);
    static assert(IsStringAP!string.value && IsArrayAP!(int[]).value && IsClassAP!Object.value);
    static assert(IsEnumAP!Priority.value && IsStructAP!Settings.value);
    static assert(IsNumberAP!long.value && !IsNumberAP!string.value);
    writeln("the traits agree");
}
```

prints:

```text
{"autosave":true,"tab_width":4}
4
0
{"autosave":null,"tab_width":8}
8
1
2
object
the traits agree
```

| Method | Takes | Gives |
|---|---|---|
| `APserializeToJson!T(value)` | any serialisable `T` | `JSONValue` |
| `APserializeTToJsonValue!T(value)` | the same, one step lower | `JSONValue` — no `JSONValue` shortcut, no error translation |
| `APdeserializeJson!T(text)` | JSON **text** holding an object | `Optional!T`, strict |
| `APdeserializeJsonLenient!T(text)` | the same | `Optional!T`, a missing field keeps its default |
| `APdeserializeJsonArray!T(text)` | JSON text holding an array | `Optional!(T[])` |
| `APconvertJsonValueToT!T(node, lenient)` | a node you already hold | `Optional!T` |
| `APserializeToJsonArray!T(value)` | one value | `JSONValue[]` with **one** element |
| `APgetJsonValueType(node)` | a node | `JSONType` (`object`, `array`, `integer`, …) |

Four things this block proves without a comment:

- `tab_width` on the wire, `tabWidth` in D — `@JsonName` renames one direction and the other.
- `cacheKey` never appears, and comes back as `null` — `@JsonIgnore` is not a suggestion.
- an empty `Optional!bool` is written as `null`, and read back empty.
- strict mode refuses a document with a missing field; `Lenient` fills it with `0`.

The second half is the same walk without the conveniences: `serializeTToJsonValue` plus
`convertJsonValueToT` is exactly what `serializeToJson` plus `deserializeJson` do, which is why
holding a `JSONValue` in the middle — to inspect, to merge, to store — costs nothing.

`APserializeToJsonArray` is a one-element wrapper, useful for a function that must always answer
with a list. Writing a real array to a file needs no helper: `APwriteJsonFile!(Point[])(path,
points)` in example 1 already did it.

The `Is…AP` structs are compile-time questions for your own generic code — `static if
(IsStructAP!T.value)` — and each is an `enum bool value`, so it costs nothing at runtime.

## 3 — Paths and one value

`APJsonPathParser` shows what a path becomes; `APgetJsonValue` walks it for you.

```d
import JsonDAP, std.json, std.stdio;

void main()
{
    string text = `{"a.b":1,"items":[{"y":1},{"y":2}],"settings":{"theme":"dark"}}`;

    foreach (step; JsonAP.APJsonPathParser(`items[۱].y`))
    {
        if (step.type == PathStepType.ObjectKey)
        {
            writeln("key   ", step.key);
        }
        else
        {
            writeln("index ", step.index);
        }
    }

    writeln(JsonAP.APgetJsonValue!string(text, "settings.theme").get);
    writeln(JsonAP.APgetJsonValue!int(text, "items[1].y").get);
    writeln(JsonAP.APgetJsonValue!int(text, `a\.b`).get);

    try
    {
        JsonAP.APgetJsonValue!int(text, "settings.missing");
    }
    catch (JSONExceptionAP caught)
    {
        writeln(caught.msg);
    }
}
```

prints:

```text
key   items
index 1
key   y
dark
2
1
JSON path invalid: key 'missing' not found.
```

| Method | Answers |
|---|---|
| `APJsonPathParser(path)` | `PathStep[]` — each step is `ObjectKey` with `.key` or `ArrayIndex` with `.index` |
| `APgetJsonValue!V(text, path)` | `Optional!V` for a node of that type |

`V` may be `string`, `int`, `long`, `double`, `float` or `bool`; an integer node also converts to
`double`, a `double` node does not convert to `int`. Two facts the printout makes visible: the
Persian `۱` inside the brackets is normalised to `1`, and `a\.b` reaches a key that really
contains a dot (the full syntax is chapter [04](04-path-syntax.md)).

Empty text or an empty path gives an **empty** `Optional`; a path that does not match the
document **throws**. Those are different situations and the library keeps them apart.

## 4 — Editing a file by path

Six methods edit one node without rewriting the document. The plain forms answer `bool`; the
`…WithMessage` twins answer `bool` **and** say why.

```d
import JsonDAP, std.file, std.json, std.stdio, std.typecons;

struct Point
{
    int x;
    int y;
}

void main()
{
    string file = "doc.json";
    JsonAP.APwriteJsonFile!JSONValue(file, parseJSON(
            `{"text":"before","items":[{"x":0,"y":0},{"x":1,"y":1}],"limits":{"rows":10}}`));

    writeln(JsonAP.APupdateJsonValueOBJECT!string(file, "text", "after"));
    writeln(JsonAP.APaddJsonItemOBJECT!int(file, "limits.cols", 80));
    writeln(JsonAP.APupdateJsonValueARRAY!int(file, "items[1].y", 99));
    writeln(JsonAP.APaddJsonItemARRAY!Point(file, "items[2]", Point(7, 8)));
    writeln(JsonAP.APremoveJsonItemARRAY(file, "items[0]"));
    writeln(JsonAP.APremoveJsonItemOBJECT(file, "limits.cols"));
    writeln(readText(file));

    string message;
    writeln(JsonAP.APremoveJsonItemOBJECTWithMessage(file, "missing", message), ": ", message);
    writeln(JsonAP.APupdateJsonValueOBJECTWithMessage!int(file, "settings.retry", 3, message), ": ", message);
    writeln(JsonAP.APaddJsonItemOBJECTWithMessage!int(file, "text", 1, message), ": ", message);
    writeln(JsonAP.APupdateJsonValueARRAYWithMessage!int(file, "items[9].y", 5, message), ": ", message);
    writeln(JsonAP.APaddJsonItemARRAYWithMessage!int(file, "items[9]", 0, message), ": ", message);
    writeln(JsonAP.APremoveJsonItemARRAYWithMessage(file, "items[9]", message), ": ", message);
}
```

prints:

```text
true
true
true
true
true
true
{"items":[{"x":1,"y":99},{"x":7,"y":8}],"limits":{"rows":10},"text":"after"}
false: the key 'missing' does not exist.
false: the path 'settings.retry' does not exist: key 'settings' is missing.
false: the key 'text' already exists; use APupdateJsonValueOBJECT.
false: array index 9 is out of range (length 2).
false: array index 9 is out of range (length 2); nothing was changed.
false: array index 9 is out of range (length 2).
```

| Plain | Twin | Contract |
|---|---|---|
| `APupdateJsonValueOBJECT!V(file, path, value)` | `…WithMessage` | the key must exist; `V` is the value's type |
| `APaddJsonItemOBJECT!T(file, path, value)` | `…WithMessage` | the key must **not** exist |
| `APremoveJsonItemOBJECT(file, path)` | `…WithMessage` | removes a nested or a top-level key |
| `APupdateJsonValueARRAY!V(file, path, value)` | `…WithMessage` | replaces the element at the index |
| `APaddJsonItemARRAY!T(file, path, value)` | `…WithMessage` | **inserts at** the index; `index == length` appends |
| `APremoveJsonItemARRAY(file, path)` | `…WithMessage` | removes the element at the index |

A missing intermediate **object key** is created on the way, which is why `limits.cols` worked on
a document that had only `limits`. A missing intermediate **array index** is not created — there
is nothing to extend.

The twins clear `message` before they look at anything, so one variable serves every call in a
row. `APEditMessages` is the base class that holds them; you never name it, you call the twins on
`JsonAP`.

## 5 — Merging and copying

Two questions: merge into a **file**, or merge two trees **in memory**. And one trap: assigning a
`JSONValue` copies the handle, not the tree.

```d
import JsonDAP, std.file, std.json, std.stdio;

void main()
{
    string file = "merge.json";
    JsonAP.APwriteJsonFile!JSONValue(file, parseJSON(
            `{"keep":1,"shared":{"deep":1},"cursor":{"line":3}}`));

    JSONValue incoming = parseJSON(`{"shared":{"deep":2,"added":3},"fresh":true}`);
    writeln(JsonAP.APmergeJson(file, incoming, true, false));
    writeln(readText(file));

    string reason = JsonAP.APmergeJsonWithMessage(file, parseJSON(`{"fresh":false}`), false, false);
    writeln(reason == "" ? "merged" : reason);

    string message;
    writeln(JsonAP.APmergeJsonWithMessage(file, parseJSON(`{"extra":1}`), true, false, message));

    JSONValue target = parseJSON(`{"a":1,"shared":{"deep":1}}`);
    JSONValue source = parseJSON(`{"a":2,"shared":{"deep":2,"added":3}}`);
    writeln(JsonAP.APrecursiveMerge(target, source, true, false, message));
    writeln(target.toString());

    JSONValue result;
    JSONValue untouched = parseJSON(`{"a":1}`);
    writeln(JsonAP.APrecursiveMergeCopy(untouched, source, true, false, result, message));
    writeln(untouched.toString(), " -> ", result.toString());

    JSONValue original = parseJSON(`{"list":[1,{"k":"v"}]}`);
    JSONValue shallow = original;
    shallow.object["list"].array[0] = JSONValue(7);
    writeln(original.toString());

    JSONValue deep = JsonAP.APdeepCopy(original);
    deep.object["list"].array[0] = JSONValue(0);
    writeln(original.toString(), " | ", deep.toString());
}
```

prints:

```text
true
{"cursor":{"line":3},"fresh":true,"keep":1,"shared":{"added":3,"deep":2}}
merged
true
true
{"a":2,"shared":{"added":3,"deep":2}}
true
{"a":1} -> {"a":2,"shared":{"added":3,"deep":2}}
{"list":[7,{"k":"v"}]}
{"list":[7,{"k":"v"}]} | {"list":[0,{"k":"v"}]}
```

| Method | Writes into | Answers |
|---|---|---|
| `APmergeJson(file, source, overwrite, mergeArrays)` | the file on disk | `bool` |
| `APmergeJsonWithMessage(file, source, overwrite, mergeArrays, out message)` | the file on disk | `bool` + reason |
| `APmergeJsonWithMessage(file, source, overwrite, mergeArrays)` | the file on disk | `""` on success, the reason otherwise |
| `APrecursiveMerge(target, source, overwrite, mergeArrays, out message)` | `target` itself | `bool` |
| `APrecursiveMergeCopy(target, source, overwrite, mergeArrays, out result, out message)` | a fresh `result` | `bool` |
| `APdeepCopy(node)` | — | a detached copy |

`overwrite` decides what happens when both sides have the key; `mergeArrays` decides whether an
array is replaced or appended. The first printout is the reason merge exists: `keep` and `cursor`,
keys this code never mentions, survived the write.

The last two lines are the trap in full. `JSONValue shallow = original` shares one tree, so
editing one edits the other. `APdeepCopy` rebuilds every node, and only then can a tree be edited
without moving its neighbour. The sources passed to the merge functions are deep-copied for the
same reason — your `source` is never modified.

## 6 — SumType

A `SumType` holds one member, so JSON needs a tag. The envelope is `{"tag":…,"value":…}`.

```d
import JsonDAP, std.conv, std.json, std.stdio, std.sumtype;

alias Cursor = SumType!(int, string);

string describe(Cursor held)
{
    return held.match!((int line) => "line " ~ line.to!string,
                       (string needle) => "search " ~ needle);
}

void main()
{
    Cursor line = Cursor(42);

    JSONValue wire = JsonAP.APserializeSumType!Cursor(line);
    writeln(wire.toString());

    auto back = JsonAP.APdeserializeSumType!Cursor(wire);
    writeln(describe(back.get));

    auto fromText = JsonAP.APdeserializeSumTypeFromString!Cursor(
            `{"tag":"string","value":"needle"}`);
    writeln(describe(fromText.get));

    string delegate(string) tagOf = (string memberName) => memberName == "int" ? "line" : "search";

    JSONValue renamed = JsonAP.APserializeSumType!Cursor(line, tagOf);
    writeln(renamed.toString());
    auto reopened = JsonAP.APdeserializeSumType!Cursor(renamed, false, tagOf);
    writeln(describe(reopened.get));

    JSONValue handled = JsonAP.APserializeSumTypeWithHandlers!Cursor(line,
            (Cursor held) => held.match!((int n) => "line", (string s) => "search"),
            (Cursor held) => held.match!((int n) => JSONValue(n), (string s) => JSONValue(s)));
    writeln(handled.toString());

    auto resolved = JsonAP.APdeserializeSumTypeWithHandlers!Cursor(handled,
            (string tag, JSONValue payload) => tag == "line"
                    ? Cursor(cast(int) payload.integer)
                    : Cursor(payload.str));
    writeln(describe(resolved.get));
}
```

prints:

```text
{"tag":"int","value":42}
line 42
search needle
{"tag":"line","value":42}
line 42
{"tag":"line","value":42}
line 42
```

| Method | In | Out |
|---|---|---|
| `APserializeSumType!T(value, tagOf = null)` | a value | `JSONValue` |
| `APdeserializeSumType!T(node, lenient = false, tagOf = null)` | an envelope | `Optional!T` |
| `APdeserializeSumTypeFromString!T(text, lenient = false, tagOf = null)` | JSON text | `Optional!T` |
| `APserializeSumTypeWithHandlers!T(value, tagOf, payloadOf)` | value + two delegates | `JSONValue` |
| `APdeserializeSumTypeWithHandlers!T(node, resolver)` | envelope + resolver | `Optional!T` |

Default tags are D type names — `"int"`, `"string"` — which leak your types into the file. Give
both directions the **same** function (`tagOf` above) and the wire says `"line"`, while the
reader still knows which member to build. An unknown tag is refused with a list of the tags that
exist; a payload that contradicts its tag is refused too.

`…WithHandlers` passes the whole value instead of a member name, so two `int` members can carry
different tags. The `resolver` is the only place that decides which member to build — treat it as
the checking door, not a cast.

## 7 — Inspecting and guarding

Nothing in this section writes a file. These calls come **before** you trust text from a file, a
path box or the keyboard.

```d
import JsonDAP, std.json, std.stdio;

void main()
{
    writeln(JsonAP.APisValidJson(`{"a":1}`));
    writeln(JsonAP.APisValidJson(`{"a":`));

    writeln(JsonAP.APisJsonObject(`{"a":1}`));
    writeln(JsonAP.APisJsonArray(`[1,2]`));
    writeln(JsonAP.APisJsonNumber(`42`));
    writeln(JsonAP.APisJsonString(`"text"`));
    writeln(JsonAP.APisJsonObject(`[1,2]`));

    writeln(JsonAP.APgetJsonItemCount(`{"a":1,"b":2}`).get);
    writeln(JsonAP.APprettyPrintJson(`{"a":1,"b":[1,2]}`).get);

    bool flag;
    string reason;
    JsonAP.APstrIsNil("notes.txt", "file path", flag, reason);
    writeln(flag);
    JsonAP.APstrIsNil("   ", "file path", flag, reason);
    writeln(flag, " ", reason);

    writeln(JsonAP.APCheckStringIsNullArray(["a", "b"]));
    writeln(JsonAP.APCheckStringIsNullArray([]));
}
```

prints:

```text
true
false
true
true
true
true
false
2
{
    "a": 1,
    "b": [
        1,
        2
    ]
}
false
true Parameter 'file path' cannot be just whitespace.
false
true
```

| Method | Answers |
|---|---|
| `APisValidJson(text)` | does it parse at all — never throws |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | the **top** node's shape |
| `APgetJsonItemCount(text)` | `Optional!long` — keys of an object, elements of an array |
| `APprettyPrintJson(text)` | `Optional!string`, four-space indent |
| `APstrIsNil(input, paramName, out flag, out reason)` | `void`; `flag` says "unusable", `reason` names the parameter |
| `APCheckStringIsNullArray(inputs)` | `bool`; throws `UnknownErrorExceptionAP` listing every blank index |

Read the pairs in the printout. `APisValidJson` answers `false` for broken text instead of
throwing, and `APisJsonObject` answers `false` for valid JSON of another shape — "is it JSON" and
"is it the thing I need" are two questions. `APCheckStringIsNullArray` answers `true` for an
**empty list**: nothing to check is not a failure.

`APstrIsNil` is the opposite pattern to the predicates on purpose: it is `void`, because the caller
needs two answers — a flag and the sentence to show — from one call.

## 8 — Digits in three scripts

Numbers arrive typed, in whatever digits the keyboard produced. Normalise, then ask, then convert.

```d
import JsonDAP, std.conv, std.stdio;

void main()
{
    writeln(JsonAP.APisDigitAP('7'), " ", JsonAP.APisDigitAP('۵'), " ",
            JsonAP.APisDigitAP('٧'), " ", JsonAP.APisDigitAP('x'));

    foreach (sample; ["7", "+7", "−7", "۱۲", "12.5", "۱۲٫۵", "1e9", "x"])
    {
        writeln(sample, " -> ", JsonAP.APisInteger(sample), " ",
                JsonAP.APisSignedInteger(sample), " ", JsonAP.APisDecimal(sample));
    }

    writeln(JsonAP.APnormalizeDigitsAP("۱۲٫۵"), " ", JsonAP.APnormalizeDigitsAP("−7"));

    string raw = "۱۲";
    if (JsonAP.APisInteger(raw))
    {
        writeln(JsonAP.APnormalizeDigitsAP(raw).to!int + 1);
    }
}
```

prints:

```text
true true true false
7 -> true true false
+7 -> false true false
−7 -> false true false
۱۲ -> true true false
12.5 -> false false true
۱۲٫۵ -> false false true
1e9 -> false false false
x -> false false false
12.5 -7
13
```

| Method | Question it answers |
|---|---|
| `APisDigitAP(dchar)` | is this one character a digit in Persian, Arabic-Indic or ASCII |
| `APisInteger(s)` | digits only — no sign, no point |
| `APisSignedInteger(s)` | an optional `+`/`-` (or `−`), then digits |
| `APisDecimal(s)` | sign, digits, **one** point (or `٫`), digits |
| `APnormalizeDigitsAP(s)` | digits → ASCII, `٫` → `.`, `−` → `-`; every other character untouched |

The last two lines are the lesson. `APisInteger("۱۲")` is true, yet `"۱۲".to!int` throws — the
gate checked the text, `std.conv` still wants ASCII. `APnormalizeDigitsAP` is the bridge:
normalise first, convert second. (Paths do this for you; chapter [04](04-path-syntax.md) is where
`items[۲]` works.)

Exponent form is not a decimal here: `1e9` answers `false` to all three gates. Check for it
yourself if your input can contain it.

## 9 — The deprecated names

Two names are still exported for old code. They forward to the current spelling, marked
`deprecated`, so old code keeps compiling and new code gets a warning.

```d
import JsonDAP, std.stdio;

deprecated("Use APstrIsNil; the name was only kept for old code.")
void legacyBlankGuard(string input, out bool flag, out string reason)
{
    JsonAP.APStrIsNUll(input, "input", flag, reason);
}

void main()
{
    bool flag;
    string reason;
    legacyBlankGuard("", flag, reason);
    writeln(flag, " ", reason);
}
```

prints:

```text
true Parameter 'input' cannot be empty.
```

Calling `legacyBlankGuard` from your own `main` prints a deprecation warning at compile time —
that is the mechanism working. Register the inner call in one small function, as above, and the
warning stays at the edge of your program instead of in every file.

| Deprecated | Use |
|---|---|
| `APStrIsNUll(input, paramName, out flag, out text)` | `APstrIsNil(input, paramName, out flag, out reason)` |
| `StrIsNUll` on the helper class | `strIsNil` |

## The whole surface in one table

Every exported name, the example that runs it, and what it answers. This is the page to keep
open while writing code.

| API | Example | Answers |
|---|---|---|
| `APwriteJsonFile!T(file, value)` | [1](#1--a-file-round-trip) | `bool` |
| `APreadJsonFile!T(file)` | [1](#1--a-file-round-trip) | `Optional!T` |
| `APreadJsonArray!T(file)` | [1](#1--a-file-round-trip) | `Optional!(T[])` |
| `APgetJsonFileSize(file)` | [1](#1--a-file-round-trip) | `Optional!long` |
| `APexistsFile(file)` / `APexists(path)` | [1](#1--a-file-round-trip) | `bool` |
| `APserializeToJson!T(value)` | [2](#2--types-and-the-round-trip) | `JSONValue` |
| `APserializeTToJsonValue!T(value)` | [2](#2--types-and-the-round-trip) | `JSONValue` |
| `APdeserializeJson!T(text)` | [2](#2--types-and-the-round-trip) | `Optional!T`, strict |
| `APdeserializeJsonLenient!T(text)` | [2](#2--types-and-the-round-trip) | `Optional!T`, missing fields defaulted |
| `APdeserializeJsonArray!T(text)` | [2](#2--types-and-the-round-trip) | `Optional!(T[])` |
| `APconvertJsonValueToT!T(node, lenient)` | [2](#2--types-and-the-round-trip) | `Optional!T` |
| `APserializeToJsonArray!T(value)` | [2](#2--types-and-the-round-trip) | `JSONValue[]`, one element |
| `APgetJsonValueType(node)` | [2](#2--types-and-the-round-trip) | `JSONType` |
| `IsIntAP` `IsFloatAP` `IsBoolAP` `IsStringAP` `IsArrayAP` `IsClassAP` `IsEnumAP` `IsStructAP` `IsNumberAP` | [2](#2--types-and-the-round-trip) | `enum bool value` |
| `APJsonPathParser(path)` | [3](#3--paths-and-one-value) | `PathStep[]` |
| `APgetJsonValue!V(text, path)` | [3](#3--paths-and-one-value) | `Optional!V` |
| `APupdateJsonValueOBJECT!V(file, path, value)` | [4](#4--editing-a-file-by-path) | `bool` |
| `APupdateJsonValueARRAY!V(file, path, value)` | [4](#4--editing-a-file-by-path) | `bool` |
| `APaddJsonItemOBJECT!T(file, path, value)` | [4](#4--editing-a-file-by-path) | `bool` |
| `APaddJsonItemARRAY!T(file, path, value)` | [4](#4--editing-a-file-by-path) | `bool` |
| `APremoveJsonItemOBJECT(file, path)` | [4](#4--editing-a-file-by-path) | `bool` |
| `APremoveJsonItemARRAY(file, path)` | [4](#4--editing-a-file-by-path) | `bool` |
| `…WithMessage` twins of the six above | [4](#4--editing-a-file-by-path) | `bool` + `out string message` |
| `APEditMessages` | [4](#4--editing-a-file-by-path) | the base class that carries the twins; never named in code |
| `APmergeJson(file, source, overwrite, mergeArrays)` | [5](#5--merging-and-copying) | `bool` |
| `APmergeJsonWithMessage(…, out message)` | [5](#5--merging-and-copying) | `bool` + reason |
| `APmergeJsonWithMessage(…)` | [5](#5--merging-and-copying) | `string` — `""` on success |
| `APrecursiveMerge(target, source, …, out message)` | [5](#5--merging-and-copying) | `bool`, edits `target` |
| `APrecursiveMergeCopy(target, source, …, out result, out message)` | [5](#5--merging-and-copying) | `bool`, fills `result` |
| `APdeepCopy(node)` | [5](#5--merging-and-copying) | `JSONValue`, detached |
| `APserializeSumType!T(value, tagOf)` | [6](#6--sumtype) | `JSONValue` |
| `APdeserializeSumType!T(node, lenient, tagOf)` | [6](#6--sumtype) | `Optional!T` |
| `APdeserializeSumTypeFromString!T(text, lenient, tagOf)` | [6](#6--sumtype) | `Optional!T` |
| `APserializeSumTypeWithHandlers!T(value, tagOf, payloadOf)` | [6](#6--sumtype) | `JSONValue` |
| `APdeserializeSumTypeWithHandlers!T(node, resolver)` | [6](#6--sumtype) | `Optional!T` |
| `APisValidJson(text)` | [7](#7--inspecting-and-guarding) | `bool` |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | [7](#7--inspecting-and-guarding) | `bool` |
| `APgetJsonItemCount(text)` | [7](#7--inspecting-and-guarding) | `Optional!long` |
| `APprettyPrintJson(text)` | [7](#7--inspecting-and-guarding) | `Optional!string` |
| `APstrIsNil(input, paramName, out flag, out reason)` | [7](#7--inspecting-and-guarding) | `void` |
| `APCheckStringIsNullArray(inputs)` | [7](#7--inspecting-and-guarding) | `bool` |
| `APisDigitAP(dchar)` | [8](#8--digits-in-three-scripts) | `bool` |
| `APisInteger` / `APisSignedInteger` / `APisDecimal` | [8](#8--digits-in-three-scripts) | `bool` |
| `APnormalizeDigitsAP(text)` | [8](#8--digits-in-three-scripts) | `string` |
| `APStrIsNUll` *(deprecated)* | [9](#9--the-deprecated-names) | `void` |

Every failure raised by the readers is a `BaseExceptionAP` with the file and line that raised it;
chapter [10](10-exceptions.md) has the tree and the catch ladder.

Back to the [index](../../StartEn.md).
