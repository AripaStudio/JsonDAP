# 06 — Editing a file by path

Index: [StartEn.md](../../StartEn.md) · Previous: [05](05-reading-a-value.md)

Six methods change one node of a file at a time; six twins do the same and also tell you **why**
when they answer `false`. The two you need most are `add` and `update` — here is how a real save
uses them together.

## Build a save on one twin

`writeValue` tries to add, then updates — create-or-replace in two calls
([TextDAPSession.d:114](../../../JsonDAPtest/TextDAPSession.d#L114)):

```d
public static bool writeValue(V)(string filePath, string jsonPath, V value, out string message)
{
    message = "";

    string[] blankInputs = [filePath, jsonPath];
    if (JsonAP.APCheckStringIsNullArray(blankInputs))
    {
        message = "the session path and the file path must both hold text.";
        return false;
    }

    bool added = JsonAP.APaddJsonItemOBJECTWithMessage!V(filePath, jsonPath, value, message);
    if (added)
    {
        return true;                  // it did not exist: it was added
    }

    return JsonAP.APupdateJsonValueOBJECTWithMessage!V(filePath, jsonPath, value, message);
}
```

| Line | What it does |
|---|---|
| `APCheckStringIsNullArray` | one guard for both inputs, before any file is touched |
| `add` first | if the key is new, it is created — no pre-read needed |
| `update` second | if it existed, `add` already said so; `message` now carries the real reason |

Options, cursor, and every document field really do go through this one function — the
document variant only composes the path first:

```d
public static bool writeDocumentValue(V)(string filePath, int index, string memberPath,
        V value, out string message)
{
    return writeValue(filePath, CL_TextDap_History.documentPath(index) ~ "." ~ memberPath,
            value, message);
}
```

## Picking OBJECT or ARRAY from the path

The path says which family you need — the **last step** decides (see
[04](04-path-syntax.md) and `itemShape` at
[TextDAPJsonEdit.d:113](../../../JsonDAPtest/TextDAPJsonEdit.d#L113)):

```d
return Optional!bool(steps[$ - 1].type == PathStepType.ArrayIndex);
```

`true` → the `…ARRAY…` family, `false` → the `…OBJECT…` family.

## What the six do

| Method | Contract |
|---|---|
| `APupdateJsonValueOBJECT!V(path, key, value)` | the key must exist; `V` is the value's type |
| `APaddJsonItemOBJECT!T(path, key, value)` | the key must **not** exist, or `false` |
| `APremoveJsonItemOBJECT(path, key)` | removes a nested or a top-level key |
| `APupdateJsonValueARRAY!V(path, index, value)` | replaces the element at the index |
| `APaddJsonItemARRAY!T(path, index, value)` | **inserts at** the index; `index == length` appends |
| `APremoveJsonItemARRAY(path, index)` | removes the element at the index |

A missing intermediate **object key** is created on the way. A missing intermediate **array
index** is not — there is nothing there to extend.

```d
assert(JsonAP.APaddJsonItemOBJECTWithMessage!int(path, "limits.rows", 50, message));
// makes "limits" on the way → {"limits":{"rows":50}, …}

assert(JsonAP.APupdateJsonValueARRAYWithMessage!int(path, "[1].y", 99, message));
// [{…,"y":1},{…,"y":2}] → the second element's y becomes 99
```

Negative indexes are refused (`items[-1]`), and updating an index that does not exist is refused
too — replacing nothing is not a replacement.

## Why it returned `false`

Every method above has a twin with `out string message`. These twins **never throw**: a missing
file, a broken document, an unusable path — all come back as `false` plus a sentence. `message`
is cleared at the start of every call, so one variable is safe to reuse, exactly as `writeValue`
does.

```d
string message;

if (!JsonAP.APaddJsonItemOBJECTWithMessage!int(path, "max_history", 99, message))
{
    writeln(message);
    // the key 'max_history' already exists; use APupdateJsonValueOBJECT.
}

if (!JsonAP.APupdateJsonValueOBJECTWithMessage!int(path, "settings.retry", 3, message))
{
    writeln(message);
    // the path 'settings.retry' does not exist: key 'settings' is missing.
}

if (!JsonAP.APaddJsonItemARRAYWithMessage!Point(arrayPath, "[9]", Point(0, 0), message))
{
    writeln(message);
    // array index 9 is out of range (length 2); nothing was changed.
}
```

## The two families side by side

| Plain (`bool`) | Twin (`bool` + `message`) |
|---|---|
| `APupdateJsonValueOBJECT` | `APupdateJsonValueOBJECTWithMessage` |
| `APupdateJsonValueARRAY` | `APupdateJsonValueARRAYWithMessage` |
| `APaddJsonItemOBJECT` | `APaddJsonItemOBJECTWithMessage` |
| `APaddJsonItemARRAY` | `APaddJsonItemARRAYWithMessage` |
| `APremoveJsonItemOBJECT` | `APremoveJsonItemOBJECTWithMessage` |
| `APremoveJsonItemARRAY` | `APremoveJsonItemARRAYWithMessage` |

TextDAP itself always takes the twin — it wants the reason on every failure. The plain forms are
for the moment when only success matters, such as a test that just asserts the edit happened:

```d
assert(JsonAP.APupdateJsonValueARRAY!int(path, "[1].y", 99));
assert(JsonAP.APaddJsonItemARRAY!Point(path, "[2]", Point(7, 8)));
assert(JsonAP.APremoveJsonItemARRAY(path, "[0]"));

assert(JsonAP.APupdateJsonValueOBJECT!string(path, "text", "after"));
assert(JsonAP.APaddJsonItemOBJECT!int(path, "extra.count", 5));
assert(JsonAP.APremoveJsonItemOBJECT(path, "extra.count"));
```

Keep both families: neither replaces the other.

Next: [07 — Merging and copying](07-merge-and-copy.md)