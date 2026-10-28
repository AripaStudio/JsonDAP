# 03 — Files and arrays

Index: [StartEn.md](../../StartEn.md) · Previous: [02](02-types-and-the-round-trip.md)

## One save, one load

Here is a `save` almost as it is
([TextDAPSession.d:83](../../../JsonDAPtest/TextDAPSession.d#L83)) — serialize, merge into the
existing file, then read the result back:

```d
JSONValue wire = JsonAP.APserializeToJson!SessionFile(session);

if (JsonAP.APexistsFile(filePath))
{
    if (JsonAP.APmergeJsonWithMessage(filePath, wire, true, false, message))
    {
        return verify(filePath, message);
    }
}

if (!JsonAP.APwriteJsonFile!JSONValue(filePath, wire))
{
    message = format!"nothing was written to %s."(filePath);
    return false;
}
```

Why merge instead of overwrite: keys the app does not know about — a `cursor` written by
another feature — survive the save. `verify` then re-reads the file: it exists, it is readable,
it is still valid JSON.

| Line | What it does |
|---|---|
| `APexistsFile(path)` | `false` for a missing file; never throws |
| `APwriteJsonFile!T` | `bool`; the `!T` is the type of the second argument |
| `APmergeJsonWithMessage` | merges `wire` into the file on disk; answers with `bool` + `message` |
| `verify` | no silent success: what was written must read back |

`APreadJsonFile!T` throws `FileOperationExceptionAP` when the file is not there:

```d
catch (FileOperationExceptionAP caught)
{
    caught.filePath;      // which file
    caught.operationType; // "read"
}
```

## Parent folders are created for you

```d
// a state file at a nested path on the first run:
JsonAP.APwriteJsonFile!JSONValue("state/session/textdap_session.json", wire);
// state/ and state/session/ are made on the way
```

No `mkdirRecurse` of your own needed: the writer creates missing folders.

## An array of records

The history export builds a `JSONValue[]` and writes it as one document
([TextDAPConvert.d:102](../../../JsonDAPtest/TextDAPConvert.d#L102)):

```d
JSONValue[] wire;
foreach (record; records)
{
    wire ~= JsonAP.APserializeToJsonArray!DocumentRecord(record);  // one record -> one array
}

JsonAP.APwriteJsonFile!JSONValue(outPath, JSONValue(wire));

Optional!(DocumentRecord[]) imported = JsonAP.APreadJsonArray!DocumentRecord(outPath);
```

`APserializeToJsonArray!T` always answers a **one-element** array wrapping that record;
that is why appending with `~=` does the right thing. `APreadJsonArray!T` wants the element
type `T`, not `T[]`, and refuses a file whose root is an object.

The same conversion from text, not a file, is `APdeserializeJsonArray!T`
([TextDAPConvert.d:186](../../../JsonDAPtest/TextDAPConvert.d#L186)):

```d
auto many = JsonAP.APdeserializeJsonArray!DocumentRecord(pack);
assert(many.get.length == 2);
assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJsonArray!DocumentRecord(`{"x":5}`));
```

## The file API in one table

| Method | Returns | Failure mode |
|---|---|---|
| `APwriteJsonFile!T(path, data)` | `bool` | `false`, or a library exception from the OS layer |
| `APreadJsonFile!T(path)` | `Optional!T` | throws when the file or its JSON is unusable |
| `APreadJsonArray!T(path)` | `Optional!(T[])` | throws when the root is not an array |
| `APgetJsonFileSize(path)` | `Optional!long` | empty `Optional` when the size cannot be measured |
| `APexistsFile(path)` | `bool` | `false`, never throws |
| `APexists(path)` | `bool` | the same answer, the older name |

Next: [04 — Path syntax](04-path-syntax.md)