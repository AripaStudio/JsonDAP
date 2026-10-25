# JsonDAP

**A JSON and file-handling library for the D programming language** — serialization,
path-based file editing, and one exception tree.
Built by [Aripa Pars Studio](https://github.com/AripaStudio) · MIT licensed · latest version **2.3.0**.

**[English](README.md) · [فارسی](README.fa.md)**

[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## Contents

- [Why JsonDAP](#why-jsondap)
- [Install](#install)
- [Quick start](#quick-start)
- [JSON contract](#json-contract)
- [API reference](#api-reference)
- [Exceptions](#exceptions)

---

## Why JsonDAP

`std.json` gives you a parse tree; `toJSON`/`fromJSON` give you automatic mapping but no
control over the wire format. JsonDAP sits in between:

- **Round-trip your own types** — `struct`, `class`, `enum`, arrays and `Nullable` fields
  convert in both directions, with an explicit, documented mapping.
- **Control the field names on the wire** — `@JsonName("msg_id")` and `@JsonIgnore` are
  honoured in both directions.
- **Two strictness levels** — strict (every field required, the default) or lenient
  (`APdeserializeJsonLenient`, missing fields keep their default).
- **Edit JSON files by path** — `"MainData.items[2].name"` — without reading the whole
  document into your own code.
- **One exception tree** — every failure is a `BaseExceptionAP` subclass carrying the file,
  the line and the JSON path that broke, so a bug report contains evidence instead of a shrug.
- **No silent repairs** — an unknown `enum` value, a missing field or a broken file is
  reported, never quietly cast or dropped.

### Requirements

| Item | Version |
|---|---|
| D compiler | DMD 2.100+ (tested with DMD 2.113.0, x86_64) |
| Build tool | dub 1.30+ (tested with dub 1.42.0) |
| Platform | Windows (DLL build uses the MSVC linker); the D sources are portable |

## Install

**As a dub dependency**

```json
{
  "dependencies": {
    "jsondap": "~>2.3.0"
  }
}
```

**As copied sources (D consumer)**

Copy the `.d` files from `JsonDAP/` into your project (only the files, not `bin/`) and let
your build compile them — that is where the templates are instantiated:

```json
{
  "sourcePaths": [ "vendor/JsonDAP" ]
}
```

A D consumer does not link `JsonDAP.dll` at all. The DLL is for callers that cannot compile
D; a D binary that links only the import library cannot resolve the templated calls, because
their bodies live in the sources, not in the DLL.

> **Keep sources and DLL from the same build.** Only non-template symbols live in
> `JsonDAP.dll`; an old `JsonDAP.dll` next to new sources (or the other way round) is not a
> supported combination.

**Prebuilt binaries** — Windows `JsonDAP.dll` + import library, with matching sources, are
published in the repository's **Releases** section and kept under `JsonDAP/bin/versionX.Y.Z/`.
Take the archive whose version matches your `dub.json` and put `JsonDAP.dll` next to the
executable.

## Quick start

```d
import std.json : JSONValue;   // JsonDAP does not re-export std.json's JSONValue
import std.stdio;
import JsonDAP;

struct User
{
    string name;
    int age;
}

void main()
{
    User user = User("Aripa", 2026);

    // struct -> JSONValue
    JSONValue json = JsonAP.APserializeToJson!User(user);
    writeln(json.toString());          // {"age":2026,"name":"Aripa"}

    // JSON text -> struct
    auto loaded = JsonAP.APdeserializeJson!User(`{"name":"Aripa","age":2026}`);
    if (!loaded.isNull)
    {
        writeln(loaded.get.name);      // Aripa
    }

    // file round trip
    JsonAP.APwriteJsonFile!User("user.json", user);
    auto fromFile = JsonAP.APreadJsonFile!User("user.json");
}
```

Every method is `static` on `JsonAP` and prefixed with `AP`. Names that return a value that
may be absent return `Nullable!T` — always check `.isNull` before `.get`; `bool` methods
return `false` on a recoverable failure (missing file, wrong node type).

> `JSONValue` and `JSONType` come from `std.json`; `import JsonDAP;` does not re-export them.
> `JSONValue` is an associative array, so the **key order of the produced text is not stable**
> (the example above prints `age` before `name`); compare parsed values, never raw text.

## JSON contract

| D type | On the wire |
|---|---|
| `struct` / `class` | object |
| array / `T[]` | array |
| `enum` | integer — and only a **valid member**, otherwise an error |
| `Nullable!T` (`Optional!T`) | `null` when empty, the wrapped value otherwise |
| `class` reference set to `null` | `null` (accepted in both directions) |
| `std.sumtype.SumType` | `{"tag":"<member name>","value":<payload>}` |

**Field names**

- `@JsonName("msg_id") string messageId;` — the wire name is `msg_id`.
- `@JsonIgnore int scratch;` — the field never appears on the wire.
- No attribute — the D field name is used verbatim.

**Strict vs lenient**

| Situation | strict (default) | `lenient = true` / `APdeserializeJsonLenient` |
|---|---|---|
| Field missing from JSON | `JSONConvertExceptionAP` (`MissingField`) | field keeps its default value |
| `Nullable` / `class` field missing | `JSONConvertExceptionAP` | stays empty / `null` |
| Unknown `enum` value | error | error (never cast) |
| Unknown SumType tag | error listing the known tags | error listing the known tags |

## API reference

All methods are `static` members of `class JsonAP` (module `JsonDAP`), grouped by what they
touch. The conversion layer's compile-time type traits are public too — each is a `struct`
with `enum bool value`: `IsIntAP`, `IsFloatAP`, `IsNumberAP`, `IsBoolAP`, `IsStringAP`,
`IsArrayAP`, `IsClassAP`, `IsEnumAP`, `IsStructAP`.

**Files**

| Method | Returns | What it does |
|---|---|---|
| `APreadJsonFile!T(string filePath)` | `Optional!T` | reads and deserializes a file |
| `APwriteJsonFile!T(string filePath, T data)` | `bool` | serializes `T` into a file |
| `APgetJsonFileSize(string filePath)` | `Optional!long` | file size in bytes |
| `APreadJsonArray!T(string filePath)` | `Optional!(T[])` | reads a JSON array file into `T[]` |
| `APexistsFile(string filePath)` | `bool` | file exists |
| `APexists(string filePath)` | `bool` | same check, kept for older code |

**Reading and writing values**

| Method | Returns | What it does |
|---|---|---|
| `APserializeToJson!T(T obj)` | `JSONValue` | `T` → JSON value |
| `APserializeToJsonArray!T(T data)` | `JSONValue[]` | array/range → JSON array |
| `APserializeTToJsonValue!T(T obj)` | `JSONValue` | low-level `T` → JSON value |
| `APdeserializeJson!T(string jsonContent)` | `Optional!T` | JSON text → `T` (strict) |
| `APdeserializeJsonLenient!T(string jsonContent)` | `Optional!T` | JSON text → `T` (missing fields allowed) |
| `APdeserializeJsonArray!T(string jsonContent)` | `Optional!(T[])` | JSON array text → `T[]` |
| `APconvertJsonValueToT!T(JSONValue jsonValue, bool lenient = false)` | `Optional!T` | JSON value → `T` |
| `APgetJsonValue!V(string jsonContent, string path)` | `Optional!V` | reads the value at `path`; the node type must match `V` (`long`/`int` need an integer node, `double` accepts either) |
| `APgetJsonValueType(JSONValue jsonValue)` | `JSONType` | the `std.json` type of a node |
| `APprettyPrintJson(string jsonContent)` | `Optional!string` | indented, human-readable JSON |

**Validating and inspecting**

| Method | Returns | What it does |
|---|---|---|
| `APisValidJson(string jsonContent)` | `bool` | the text parses as JSON |
| `APisJsonObject(string jsonContent)` | `bool` | top-level node is an object |
| `APisJsonArray(string jsonContent)` | `bool` | top-level node is an array |
| `APisJsonNumber(string jsonContent)` | `bool` | top-level node is a number |
| `APisJsonString(string jsonContent)` | `bool` | top-level node is a string |
| `APgetJsonItemCount(string jsonContent)` | `Optional!long` | number of top-level items |
| `APisDigitAP(dchar c)` | `bool` | an ASCII, Persian **or** Arabic-Indic digit |
| `APnormalizeDigitsAP(string s)` | `string` | Persian and Arabic-Indic digits rewritten as ASCII digits, every other character untouched |
| `APisInteger(string s)` | `bool` | the whole string is a number |
| `APJsonPathParser(string input)` | `PathStep[]` | splits `"a.b[2]"` into path steps |
| `APStrIsNUll(string input, string paramName, out bool, out string)` | `void` | null/empty/blank guard + reason |
| `APCheckStringIsNullArray(string[] inputs)` | `bool` | guard for a list of strings |
| `APrecursiveMerge(ref JSONValue target, ref JSONValue source, bool overwrite, bool mergeArrays, out string message)` | `bool` | deep merge with a message on failure |

**Editing a file by path**

Each call reads the file, edits one node, writes the file back, and returns `false` instead
of throwing when the path or the file is unusable.

| Method | What it does |
|---|---|
| `APupdateJsonValueOBJECT!V(string filePath, string jsonPath, V value)` | replaces `path` in an object |
| `APupdateJsonValueARRAY!V(string filePath, string jsonPath, V value)` | replaces `path` in an array |
| `APaddJsonItemOBJECT!T(string filePath, string jsonPath, T item)` | adds a new key (fails if it exists) |
| `APaddJsonItemARRAY!T(string filePath, string jsonPath, T item)` | appends to the array at `path` |
| `APremoveJsonItemOBJECT(string filePath, string jsonPath)` | removes a key |
| `APremoveJsonItemARRAY(string filePath, string jsonPath)` | removes an array element |
| `APmergeJson(string filePath, JSONValue jsonContentToMerge, bool overwriteExisting = true, bool mergeArrays = false)` | merges another document into the file |

**Two path syntaxes, on purpose.** The file-edit API and `APJsonPathParser` take
`MainData.items[2].name` with brackets. `APgetJsonValue` splits its path on `.` only, so an
array element is its own segment: `items.1` reads the second element and `items[1]` is reported
as a missing key. `APJsonPathParser` accepts ASCII, Persian and Arabic-Indic digits inside the
brackets; they are normalized before the index is converted. A missing intermediate object key
is created; a missing intermediate array index is **not** created. `APremoveJsonItemOBJECT`
removes top-level keys as well as nested ones.

**Arrays: add and update are not symmetric.** `APaddJsonItemARRAY` accepts `index == length` and
appends there; `APupdateJsonValueARRAY` rejects that same index, because updating an element that
does not exist is not a replacement. An out-of-range update reports
`array index N is out of range (length M)`.

Every call above has a twin that answers *why* it returned `false`:

```d
string reason;
if (!JsonAP.APupdateJsonValueOBJECTWithMessage!int(file, "settings.retry", 3, reason))
{
    writeln("edit rejected: ", reason);
    // edit rejected: the path 'settings.retry' does not exist: key 'retry' is missing.
}
```

| Method | What it adds |
|---|---|
| `APupdateJsonValueOBJECTWithMessage!V(filePath, jsonPath, value, out string message)` | the reason for an object-value update |
| `APupdateJsonValueARRAYWithMessage!V(filePath, jsonPath, value, out string message)` | the reason for an array-value update |
| `APaddJsonItemOBJECTWithMessage!T(filePath, jsonPath, item, out string message)` | the reason a key was not added |
| `APaddJsonItemARRAYWithMessage!T(filePath, jsonPath, item, out string message)` | the reason an item was not appended |
| `APremoveJsonItemOBJECTWithMessage(filePath, jsonPath, out string message)` | the reason a key was not removed |
| `APremoveJsonItemARRAYWithMessage(filePath, jsonPath, out string message)` | the reason an element was not removed |
| `APmergeJsonWithMessage(filePath, jsonContentToMerge, overwriteExisting, mergeArrays, out string message)` | the reason a merge did not happen |
| `APmergeJsonWithMessage(filePath, jsonContentToMerge, overwriteExisting = true, mergeArrays = false)` | the same merge, answering with one `string` instead of `bool` + `out` |

**The one-string merge answer.** The short form returns the reason for failure, and **an empty
string means the merge succeeded** — `""` is `true`, anything else is `false`:

```d
string reason = JsonAP.APmergeJsonWithMessage(file, incoming);
if (reason.length != 0)
{
    writeln("merge rejected: ", reason);
}
```

It exists because a `static` method cannot hand back two values without an `out` parameter; the
`bool` + `out string` form above is still there and is the one to prefer when you need the flag.

`message` is cleared at the start of every call and stays empty on success, so it is safe to
reuse one variable. These twins never throw: a missing file, a broken document or an
unusable path all come back as `false` plus a message.

**SumType**

`std.sumtype` has no reflection, so SumType support is an explicit API:

| Method | Returns | What it does |
|---|---|---|
| `APserializeSumType!T(T value, string delegate(string) tagOf = null)` | `JSONValue` | writes the `{"tag","value"}` envelope |
| `APdeserializeSumType!T(JSONValue jsonValue, bool lenient = false, string delegate(string) tagOf = null)` | `Optional!T` | rebuilds the member the tag names |
| `APdeserializeSumTypeFromString!T(string jsonContent, bool lenient = false, string delegate(string) tagOf = null)` | `Optional!T` | same, from JSON text |
| `APserializeSumTypeWithHandlers!T(T value, string delegate(T) tagOf, JSONValue delegate(T) payloadOf)` | `JSONValue` | caller decides tag **and** payload |
| `APdeserializeSumTypeWithHandlers!T(JSONValue jsonValue, T delegate(string tag, JSONValue payload) resolver)` | `Optional!T` | caller resolves tag and payload |

```d
alias Payload = SumType!(int, string);

JSONValue wire = JsonAP.APserializeSumType!Payload(Payload(42));
// {"tag":"int","value":42}

auto back = JsonAP.APdeserializeSumType!Payload(wire);
assert(back.get == Payload(42));
```

An unknown tag is an error that lists the tags that do exist — not a silent fallback.

## Exceptions

All of them derive from `BaseExceptionAP`, which carries a `correlationId`, the source file
and the line where the failure was raised.

```
BaseExceptionAP
├── ParameterRelatedExceptionAP
│   ├── ConvertExceptionAP
│   │   └── JSONConvertExceptionAP   (jsonPath + jsonSnippet + specific reason)
│   ├── InvalidArgumentExceptionAP
│   └── ArgumentNullExceptionAP
├── JSONExceptionAP
│   └── JsonOperationExceptionAP     (jsonPath + jsonSnippet)
├── FileOperationExceptionAP         (systemErrorCode)
├── SyntaxErrorExceptionAP
└── UnknownErrorexceptionAP
```

```d
try
{
    auto user = JsonAP.APdeserializeJson!User(jsonText).get;
}
catch (JSONConvertExceptionAP e)
{
    // e.jsonPath names the field, e.jsonSnippet the offending input
    writeln(e.toString());
}
```

A JSON path with an unusable index (`items[]`, `items[x]`) is a `ConvertExceptionAP`, and a path
with a missing `]` is an `UnknownErrorexceptionAP` — both inside this tree, so a consumer that
catches `BaseExceptionAP` never dies on a stray `std.conv.ConvException`.
