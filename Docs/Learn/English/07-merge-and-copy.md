# 07 — Merging and copying

Index: [StartEn.md](../../StartEn.md) · Previous: [06](06-editing-a-file-by-path.md)

Four APIs, three questions: merge **into a file**, merge **two `JSONValue`s**, and copy a tree so
the original survives.

## Merge another document into a file

```d
string path = /* a file holding {"a":1,"nested":{"x":1}} */;

JSONValue incoming = parseJSON(`{"a":2,"b":3,"nested":{"y":2}}`);

assert(JsonAP.APmergeJson(path, incoming, true, false));   // overwrite, do not join arrays
JSONValue merged = JsonAP.APreadJsonFile!JSONValue(path).get;

assert(merged.object["a"] == JSONValue(2));                // overwriteExisting = true
assert(merged.object["nested"].object["x"] == JSONValue(1));   // the untouched key survived
assert(merged.object["nested"].object["y"] == JSONValue(2));   // the new key arrived
// {"a":2,"b":3,"nested":{"x":1,"y":2}}
```

| Argument | Effect |
|---|---|
| `overwriteExisting` | `true` replaces a key the target already has; `false` leaves the target's value |
| `mergeArrays` | `false` replaces the whole array; `true` appends the source elements |

Two message forms, one `bool`:

```d
bool ok = JsonAP.APmergeJsonWithMessage(path, incoming, true, false, message);   // the out-param form

string reason = JsonAP.APmergeJsonWithMessage(path, parseJSON(`{"b":4}`));       // the short form
assert(reason.length == 0);                              // "" means the merge happened
```

The short form is the two-argument call (`overwriteExisting = true`, `mergeArrays = false` by
default) and answers with a `string` instead of `bool` + `out`
([JsonDAP.d:217](../../../JsonDAP/JsonDAP.d#L217)) — a `static` method cannot hand back two values
without an `out`. `""` is `true`.

The app saves a session by merging rather than overwriting, so a second window's edits are not
lost ([TextDAPSession.d:95](../../../JsonDAPtest/TextDAPSession.d#L95)):

```d
if (JsonAP.APexistsFile(filePath))
{
    if (JsonAP.APmergeJsonWithMessage(filePath, wire, true, false, message))
    {
        return verify(filePath, message);            // the file was already there: merge into it
    }

    CL_TextDap_Console.sayNote(message);             // the merge refused: fall through to a write
}

if (!JsonAP.APwriteJsonFile!JSONValue(filePath, wire))   // first save, or a merge that failed
{
    message = format!"nothing was written to %s."(filePath);
    return false;
}
```

## Merge two trees in memory

```d
JSONValue target = parseJSON(`{"keep":1,"shared":{"deep":1}}`);
JSONValue source = parseJSON(`{"shared":{"deep":2,"added":3},"fresh":true}`);

string mergeMessage;
assert(JsonAP.APrecursiveMerge(target, source, true, false, mergeMessage));

assert(target.object["shared"].object["deep"] == JSONValue(2));   // the deep key was replaced
assert(target.object["shared"].object["added"] == JSONValue(3));  // the new sibling was added
assert(target.object["fresh"].type == JSONType.TRUE);              // the new top key arrived
```

`target` is modified — the signature takes `ref JSONValue target`
([JsonDAP.d:133](../../../JsonDAP/JsonDAP.d#L133)). The `source` is copied before anything is read
out of it, so the tree you passed in is never touched either way.

## Keep the original intact

```d
JSONValue untouched = parseJSON(`{"keep":1,"shared":{"deep":1}}`);
JSONValue result;

assert(JsonAP.APrecursiveMergeCopy(untouched, source, true, false, result, mergeMessage));

assert("fresh" !in untouched.object);                     // the target was not written into
assert(result.object["shared"].object["added"] == JSONValue(3));   // the outcome is in result
// {"fresh":true,"keep":1,"shared":{"added":3,"deep":2}}
```

`APrecursiveMerge` answers `bool` and writes into `target`; `APrecursiveMergeCopy` answers `bool`
and writes into an `out JSONValue result` — both with the same four flags, so a caller picks one
without re-learning the merge rules.

## Why a copy of a `JSONValue` is not a copy

```d
JSONValue original = parseJSON(`{"list":[1,2,{"k":"v"}]}`);

JSONValue shallow = original;              // no new tree: the same handle
shallow.object["list"].array[0] = JSONValue(7);
assert(original.object["list"].array[0] == JSONValue(7));   // the "copy" and the original moved together

JSONValue deep = JsonAP.APdeepCopy(original);
deep.object["list"].array[2].object["k"] = JSONValue("changed");
assert(original.object["list"].array[2].object["k"] == JSONValue("v"));   // the original did not move
```

| Line | What it does |
|---|---|
| `JSONValue shallow = original` | `std.json.JSONValue` is an associative-array handle; assignment shares the data |
| `APdeepCopy(original)` | walks objects and arrays and rebuilds every node ([JsonDAP.d:147](../../../JsonDAP/JsonDAP.d#L147)) |
| the nested write | only a tree that shares no node can be edited without moving the other |

`APdeepCopy` is what makes `APrecursiveMerge`'s promise about `source` true, and it is the API to
call before editing a tree you read from somewhere else. It is exercised in
[jsondap_path_tests.d:144](../../../JsonDAPtest/test/jsondap_path_tests.d#L144).

Next: [08 — SumType](08-sumtype.md)
