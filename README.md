# JsonDAP

**A JSON and file-handling library for the D programming language** — serialization,
path-based file editing, and one exception tree.
Built by [Aripa Pars Studio](https://github.com/AripaStudio) · MIT licensed · latest version **2.4.1**.

**[English](README.md) · [فارسی](README.fa.md)**

[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> This file is the **reference**. The step-by-step tutorial — eleven chapters, every example
> compiled and run — is in [`Docs/`](Docs/StartEn.md).

---

## Contents

- [Why JsonDAP](#why-jsondap)
- [Install](#install)
- [Quick start](#quick-start)
- [JSON contract](#json-contract)
- [API reference](#api-reference)
- [Path syntax](#path-syntax)
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

| Item       | Version                                          |
| ---------- | ------------------------------------------------ |
| D compiler | DMD 2.100+ (tested with DMD 2.113.0, x86_64)     |
| Build tool | dub 1.30+ (tested with dub 1.42.0)               |
| Platform   | any platform DMD runs on — Windows, Linux, macOS |

## Install

JsonDAP is a **dub source package**: `targetType` is `sourceLibrary`, so there is no
`JsonDAP.dll`, no import library and no binary to keep in step with the sources. Your build
compiles the JsonDAP `.d` files together with yours, which is the only way the templated
methods (`APdeserializeJson!T`, `APgetJsonValue!V`, …) can be instantiated.

**From a local checkout**

```json
{
  "dependencies": {
    "jsondap": { "path": "../JsonDAP" }
  }
}
```

**From the git repository**

```json
{
  "dependencies": {
    "jsondap": {
      "repository": "git+https://github.com/AripaStudio/JsonDAP.git",
      "version": "v2.4.1"
    }
  }
}
```

`repository` is the clone URL; `version` is the exact Git tag dub checks out. The 2.4.1 tag is
`v2.4.1`, so keep the prefix in this field. dub clones that tag and compiles its sources into
your build, so the pinned version is the source you read on GitHub.

JsonDAP is **not** published on the dub registry, so `"jsondap": "~>2.4.1"` resolves to
nothing. Use the path form for a checkout you keep beside your project and the git form for
everything else.

Then `import JsonDAP;` and use `JsonAP.AP…`. Nothing else to install: the library's sources
arrive with the dependency and are compiled into your executable on every platform.

```d
import JsonDAP;

void main()
{
    auto loaded = JsonAP.APdeserializeJson!User(`{"name":"Aripa","age":2026}`);
}
```

> Because the sources are compiled inside the consumer, a version mismatch cannot happen —
> and a stale `JsonDAP.dll`, `.lib` or `.exp` left over from an older release does nothing at
> all. Delete them if you are upgrading from 2.3.0 or earlier.

**Callers that are not D programs** (C#, C, other FFI) have never been the target of this
library, and 2.4.0 stops shipping a DLL for them. If you need one, build the sources into a
shared library yourself — the D sources are portable and no Windows-only code is involved.

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
| `APserializeToJsonArray!T(T data)` | `JSONValue[]` | **one** value → a one-element array, ready to `~=` into a batch; a `JSONValue[]` comes back unchanged |
| `APserializeTToJsonValue!T(T obj)` | `JSONValue` | low-level `T` → JSON value |
| `APdeserializeJson!T(string jsonContent)` | `Optional!T` | JSON text → `T` (strict) |
| `APdeserializeJsonLenient!T(string jsonContent)` | `Optional!T` | JSON text → `T` (missing fields allowed) |
| `APdeserializeJsonArray!T(string jsonContent)` | `Optional!(T[])` | JSON array text → `T[]` |
| `APconvertJsonValueToT!T(JSONValue jsonValue, bool lenient = false)` | `Optional!T` | JSON value → `T` |
| `APgetJsonValue!V(string jsonContent, string path)` | `Optional!V` | reads the value at `path` through the [shared parser](#path-syntax); the node type must match `V` (`long`/`int` need an integer node, `double` accepts either). An absent key, a bad index or a type mismatch **throws** — the empty `Optional` means the text or the path was empty, nothing more |
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
| `APisDigitAP(dchar c)` | `bool` | one character that is an ASCII, Persian **or** Arabic-Indic digit |
| `APnormalizeDigitsAP(string s)` | `string` | digits rewritten as ASCII, plus `٫`/`٬` → `.` and `−` → `-`; every other character untouched |
| `APisInteger(string s)` | `bool` | **only digits** — no sign, no decimal point (`"7"` yes, `"+7"` and `"12.5"` no) |
| `APisSignedInteger(string s)` | `bool` | optional `+`/`-` then only digits (`"−7"` yes, `"7.5"` no) |
| `APisDecimal(string s)` | `bool` | optional sign, digits, one `.`, digits (`"12.5"`, `"۱۲٫۵"` yes; `"1e9"`, `"12."` no) |
| `APJsonPathParser(string input)` | `PathStep[]` | the JSON path parser — see [Path syntax](#path-syntax) |
| `APstrIsNil(string input, string paramName, out bool, out string reason)` | `void` | null/empty/blank guard + reason |
| `APCheckStringIsNullArray(string[] inputs)` | `bool` | guard for a list of strings |
| `APrecursiveMerge(ref JSONValue target, JSONValue source, bool overwrite, bool mergeArrays, out string message)` | `bool` | deep merge into `target`; `source` is copied first, so the value you pass in is never touched |
| `APrecursiveMergeCopy(JSONValue target, JSONValue source, bool overwrite, bool mergeArrays, out JSONValue result, out string message)` | `bool` | the same merge into a **copy**: `target` stays as it was and the outcome arrives in `result` |
| `APdeepCopy(JSONValue v)` | `JSONValue` | an independent copy of a JSON tree — no array, object or nested node is shared |

`APStrIsNUll` and `StrIsNUll` are still there, marked `deprecated`, and forward to
`APstrIsNil` / `strIsNil`. The old names mixed the case of `Null` and spelled their message
parameter `ErrorText`; 2.5.0 removes them.

**Editing a file by path**

Each call reads the file, edits one node, writes the file back, and returns `false` instead
of throwing when the path or the file is unusable.

| Method | What it does |
|---|---|
| `APupdateJsonValueOBJECT!V(string filePath, string jsonPath, V value)` | replaces `path` in an object |
| `APupdateJsonValueARRAY!V(string filePath, string jsonPath, V value)` | replaces `path` in an array |
| `APaddJsonItemOBJECT!T(string filePath, string jsonPath, T item)` | adds a new key (fails if it exists) |
| `APaddJsonItemARRAY!T(string filePath, string jsonPath, T item)` | inserts into the array at `path` |
| `APremoveJsonItemOBJECT(string filePath, string jsonPath)` | removes a key |
| `APremoveJsonItemARRAY(string filePath, string jsonPath)` | removes an array element |
| `APmergeJson(string filePath, JSONValue jsonContentToMerge, bool overwriteExisting = true, bool mergeArrays = false)` | merges another document into the file |

### Path syntax

**One syntax, everywhere.** As of 2.4.0 `APgetJsonValue`, `APJsonPathParser` and the whole
file-edit API share a single parser, so one string means the same thing in all of them:

```
MainData.items[2].name
```

| Form | Meaning |
|---|---|
| `a.b` | object key `b` inside object `a` |
| `items[2]` | the third element of the array `items` |
| `rows[0][1]` | chained indexes — the second element of `rows[0]` |
| `weird\.key.next` | `\` escapes the next character, so a key may contain `.`, `[` or `]` |
| `rows[۲]` | Persian and Arabic-Indic digits are normalised before the index is converted |

> **Breaking in 2.4.0 — `items.1` no longer indexes an array.** Up to 2.3.0 `APgetJsonValue`
> split its path on `.` alone, so a bare numeric segment was used as an array index. With one
> parser shared by every method, a bare segment is always an object key and only `[n]` is an
> index; `items.1` on an array now raises `JSON path invalid: key '1' not found.` Write
> `items[1]`. Nothing else in the path grammar changed.

A path is read character by character, so a broken one is refused instead of quietly producing
a wrong step. All of these raise `InvalidArgumentExceptionAP` (a `BaseExceptionAP`):

| Path | Why it is refused |
|---|---|
| `""`, `"   "` | `JSON path is empty.` |
| `a..b` | `JSON path contains an empty key.` |
| `items[3` | `JSON path has a missing closing bracket.` |
| `items]` | `JSON path has a ']' without '['.` |
| `items[0]x` | `Unexpected character after ']'.` |
| `items[abc]` | `array index must be a non-negative integer.` |
| `items[-1]` | `array index must be a non-negative integer.` — negative indexes are not Python |

`APgetJsonValue` uses the same parser and the same refusals; it also refuses an index past the
end of the array and a key that is not there, and it rethrows every library exception rather
than swallowing it into an empty `Optional`.

A missing **intermediate object key** in the file-edit API is created; a missing intermediate
**array index** is not. `APremoveJsonItemOBJECT` removes top-level keys as well as nested ones.

**Arrays: add inserts, update replaces.** `APaddJsonItemARRAY` inserts the item **at** the
index it is given, so `index == length` is the append position and anything larger is refused
with `array index N is out of range (length M); nothing was changed.`. `APupdateJsonValueARRAY`
rejects that same index, because updating an element that does not exist is not a replacement.

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
| `APaddJsonItemARRAYWithMessage!T(filePath, jsonPath, item, out string message)` | the reason an item was not inserted |
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
└── UnknownErrorExceptionAP
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

Every path refusal is an `InvalidArgumentExceptionAP` — an empty path, an empty key, a missing
`]`, a `]` without a `[`, a character after `]`, an index that is not a non-negative integer.
The one exception is an index too large for an `int`, which is a `ConvertExceptionAP`. Both
live inside this tree, so a consumer that catches `BaseExceptionAP` never dies on a stray
`std.conv.ConvException`.

`UnknownErrorexceptionAP` was spelled with a lower-case `e` in `exception`, unlike its sibling
`SyntaxErrorExceptionAP`. 2.4.0 renames it to `UnknownErrorExceptionAP` and keeps the old
spelling as a `deprecated` alias, so existing code still compiles and gets told to move.
