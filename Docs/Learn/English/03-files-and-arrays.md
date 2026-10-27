# 03 — Files and arrays

Index: [StartEn.md](../../StartEn.md) · Previous: [02](02-types-and-the-round-trip.md)

## One record, one file

```d
struct Point
{
    @JsonName("x") int x;
    @JsonName("y") int y;
}

string path = buildPath(tempDir, "note.json");

assert(!JsonAP.APexistsFile(path));                              // nothing there yet
assert(JsonAP.APwriteJsonFile!Point(path, Point(1, 2)));         // serialize + write, true on success
assert(JsonAP.APexists(path));                                   // the same check, the older name
assert(JsonAP.APgetJsonFileSize(path).get > 0);                   // Optional!long, bytes
assert(JsonAP.APreadJsonFile!Point(path).get == Point(1, 2));     // read + deserialize
```

The file now holds `{"x":1,"y":2}`.

| Line | What it does |
|---|---|
| `APwriteJsonFile!Point` | the template argument is the type of the *second* argument; `bool` answer, no value back |
| `APexistsFile` | one call, no exception on a missing file — it just answers `false` |
| `APgetJsonFileSize` | `Optional!long`; empty when the size cannot be measured |
| `APreadJsonFile!Point` | **throws** `FileOperationExceptionAP` when the file is not there (see below) |

```d
try
{
    JsonAP.APreadJsonFile!Point(buildPath(tempDir, "no_such_file.json"));
}
catch (FileOperationExceptionAP caught)
{
    caught.filePath;        // C:\Users\…\Temp\no_such_file.json
    caught.operationType;   // read
    // File not found for reading.
}
```

## Parent folders are created for you

```d
string nested = buildPath(tempDir, "a", "b", "note.json");
assert(JsonAP.APwriteJsonFile!Point(nested, Point(9, 9)));   // a/ and a/b/ are made on the way
assert(exists(nested));
```

[FileAP.d:87](../../../JsonDAP/FileAP.d#L87) calls `mkdirRecurse` before writing, so a first run
of a program that stores its state in `state/app.json` does not need to create anything by hand.

## An array of records in a file

```d
Point[] points = [Point(1, 2), Point(3, 4)];

assert(JsonAP.APwriteJsonFile!(Point[])(path, points));       // writes [{"x":1,"y":2},{"x":3,"y":4}]
Point[] fromFile = JsonAP.APreadJsonArray!Point(path).get;    // the array reader wants T, not T[]
assert(fromFile.length == 2);
assert(fromFile[1] == Point(3, 4));
```

`APreadJsonArray!T` reads the whole file, insists the top node is an array, and hands back
`Optional!(T[])`. The same conversion from **text** is `APdeserializeJsonArray!T`:

```d
Point[] fromText = JsonAP.APdeserializeJsonArray!Point(`[{"x":5,"y":6}]`).get;
assert(fromText[0] == Point(5, 6));
assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJsonArray!Point(`{"x":5}`));  // not an array
```

## `APserializeToJsonArray` appends

```d
JSONValue[] wire;
foreach (record; records)
{
    wire ~= JsonAP.APserializeToJsonArray!Point(Point(7, 8));   // one value in, ONE element out
}
assert(wire.length == records.length);
```

| Input `T` | `JSONValue[]` out |
|---|---|
| a struct, a class, an enum | a one-element array holding that node |
| `JSONValue` | a one-element array holding it |
| `JSONValue[]` | the same array, untouched |

[FileAPJson.d:155](../../../JsonDAP/FileAPJson.d#L155). It exists to build an array of records in
a loop, which is exactly what [TextDAPConvert.d:102](../../../JsonDAPtest/TextDAPConvert.d#L102)
does before writing the history file and reading it back with `APreadJsonArray` two lines later
([:114](../../../JsonDAPtest/TextDAPConvert.d#L114)).

## The file API in one table

| Method | Returns | Failure mode |
|---|---|---|
| `APwriteJsonFile!T(filePath, data)` | `bool` | `false`, or a library exception from the OS layer |
| `APreadJsonFile!T(filePath)` | `Optional!T` | throws when the file or its JSON is unusable |
| `APreadJsonArray!T(filePath)` | `Optional!(T[])` | throws when the top node is not an array |
| `APgetJsonFileSize(filePath)` | `Optional!long` | empty `Optional` |
| `APexistsFile(filePath)` | `bool` | `false`, never throws |
| `APexists(filePath)` | `bool` | the same answer, the older name |

Next: [04 — Path syntax](04-path-syntax.md)
