# 07 — Merging and copying

Index: [StartEn.md](../../StartEn.md) · Previous: [06](06-editing-a-file-by-path.md)

Four APIs, three questions: merge **into a file**, merge **two trees in memory**, and copy a tree
so the original survives.

## Why merge instead of overwriting

`save` merges into whatever is already on disk, so keys the app does not know about — a `cursor`
written by another feature — survive a save
([TextDAPSession.d:83](../../../JsonDAPtest/TextDAPSession.d#L83)):

```d
JSONValue wire = JsonAP.APserializeToJson!SessionFile(session);

if (JsonAP.APexistsFile(filePath))
{
    if (JsonAP.APmergeJsonWithMessage(filePath, wire, true, false, message))
    {
        return verify(filePath, message);      // merged, then re-read and checked
    }

    CL_TextDap_Console.sayNote(message);       // the reason it refused
}

if (!JsonAP.APwriteJsonFile!JSONValue(filePath, wire))   // first save, or merge fell through
{
    message = format!"nothing was written to %s."(filePath);
    return false;
}
```

| Argument | Effect |
|---|---|
| `overwriteExisting` | `true` replaces a key the target already has; `false` keeps the target's value |
| `mergeArrays` | `false` replaces the whole array; `true` appends the source's elements |

`message` is the reason: empty means the merge happened, anything else says why it did not.
`"" <=> true`.

## Two trees in memory

```d
JSONValue target = parseJSON(`{"keep":1,"shared":{"deep":1}}`);
JSONValue source = parseJSON(`{"shared":{"deep":2,"added":3},"fresh":true}`);
JSONValue result;

// in place — target itself changes
assert(JsonAP.APrecursiveMerge(target, source, true, false, mergeMessage));
assert(target.object["shared"].object["deep"] == JSONValue(2));    // replaced
assert(target.object["shared"].object["added"] == JSONValue(3));   // added
assert(target.object["fresh"].type == JSONType.TRUE);              // new top key

// into a fresh out-parameter — the target stays untouched
assert(JsonAP.APrecursiveMergeCopy(untouched, source, true, false, result, mergeMessage));
assert("fresh" !in untouched.object);                              // untouched really is
assert(result.object["shared"].object["added"] == JSONValue(3));   // the outcome is in result
```

The `source` is deep-copied before anything is read out of it, so the tree you passed in is never
touched either way. TextDAP's `arrayAndMergeDemo` is that idea end to end — read an array of two
records from text, merge them, convert one back:

```d
Optional!(DocumentRecord[]) many = JsonAP.APdeserializeJsonArray!DocumentRecord(pack);

JSONValue base   = JsonAP.APserializeToJson!DocumentRecord(many.get[0]);
JSONValue added  = JsonAP.APserializeToJson!DocumentRecord(many.get[1]);

JSONValue mergedValue;
if (JsonAP.APrecursiveMergeCopy(base, added, true, false, mergedValue, mergeMessage))
{
    auto merged = JsonAP.APconvertJsonValueToT!DocumentRecord(mergedValue, true);
    // base is untouched: its "title" still holds the original
}
```

## Why a copy of a `JSONValue` is not a copy

```d
JSONValue original = parseJSON(`{"list":[1,2,{"k":"v"}]}`);

JSONValue shallow = original;                                   // same handle underneath
shallow.object["list"].array[0] = JSONValue(7);
assert(original.object["list"].array[0] == JSONValue(7));       // both moved together

JSONValue deep = JsonAP.APdeepCopy(original);
deep.object["list"].array[2].object["k"] = JSONValue("changed");
assert(original.object["list"].array[2].object["k"] == JSONValue("v"));   // original stayed
```

| Line | What it does |
|---|---|
| `JSONValue shallow = original` | `JSONValue` is an associative-array handle; assignment shares the data |
| `APdeepCopy(original)` | walks objects and arrays and rebuilds every node |
| the nested write | only a tree sharing no node can be edited without moving the other |

Call `APdeepCopy` before editing a tree you read from somewhere else. It is exercised in
[jsondap_path_tests.d:144](../../../JsonDAPtest/test/jsondap_path_tests.d#L144).

## The four in one place

| Method | Writes into | Answers |
|---|---|---|
| `APmergeJson(path, source, overwrite, mergeArrays)` | the file on disk | `bool` |
| `APmergeJsonWithMessage(path, source, overwrite, mergeArrays, out message)` | the file on disk | `bool` + reason |
| `APrecursiveMerge(target, source, …, out message)` | `target` itself | `bool` |
| `APrecursiveMergeCopy(target, source, …, out result, out message)` | fresh `result` | `bool` |
| `APdeepCopy(node)` | — | a detached copy |

Next: [08 — SumType](08-sumtype.md)