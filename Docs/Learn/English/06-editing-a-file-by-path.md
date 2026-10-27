# 06 — Editing a file by path

Index: [StartEn.md](../../StartEn.md) · Previous: [05](05-reading-a-value.md)

Each of these calls reads the file, changes one node, writes the file back, and answers `bool`.
Nothing is thrown at you on a bad path — you get `false`, and the `…WithMessage` twin tells you why.

```d
string path = /* a file holding {"autosave":false,"tab_width":4} */;

assert(JsonAP.APupdateJsonValueOBJECT!bool(path, "autosave", true));    // replace an existing key
assert(JsonAP.APaddJsonItemOBJECT!int(path, "max_history", 12));        // add a key that is not there
assert(JsonAP.APaddJsonItemOBJECT!int(path, "limits.rows", 50));        // creates "limits" on the way
assert(JsonAP.APremoveJsonItemOBJECT(path, "max_history"));             // removes a key
```

After those four calls the file is `{"autosave":true,"limits":{"rows":50},"tab_width":4}`; the
removal above leaves `{"autosave":true,"limits":{},"tab_width":4}` — an empty object stays, because
only the named node was removed.

| Method | Contract |
|---|---|
| `APupdateJsonValueOBJECT!V` | the key must exist; `V` is the value's type |
| `APaddJsonItemOBJECT!T` | the key must **not** exist, otherwise `false` |
| `APremoveJsonItemOBJECT` | removes a nested or a top-level key |
| `APupdateJsonValueARRAY!V` | replaces the element at the index |
| `APaddJsonItemARRAY!T` | **inserts at** the index; `index == length` is the append position |
| `APremoveJsonItemARRAY` | removes the element at the index |

A missing intermediate **object key** is created. A missing intermediate **array index** is not.

```d
string arrayPath = /* a file holding [{"x":1,"y":1},{"x":2,"y":2}] */;

assert(JsonAP.APupdateJsonValueARRAY!int(arrayPath, "[1].y", 99));        // [{"x":1,"y":1},{"x":2,"y":99}]
assert(JsonAP.APaddJsonItemARRAY!Point(arrayPath, "[2]", Point(7, 8)));   // append at length
// [{"x":1,"y":1},{"x":2,"y":99},{"x":7,"y":8}]
assert(JsonAP.APremoveJsonItemARRAY(arrayPath, "[0]"));                   // [{"x":2,"y":99},{"x":7,"y":8}]
```

Indexes start at the file's root, so `"[1].y"` means *the second element's `y`*. There is no way
to say "an element of the root array" without the leading bracket, and `APupdateJsonValueARRAY`
refuses an index that is not there — updating a non-existent element is not a replacement.

## Why it returned `false`

Every method above has a twin with `out string message`
([JsonAPMessages.d:13](../../../JsonDAP/JsonAPMessages.d#L13)). These twins **never throw**: a
missing file, a broken document, an unusable path — all come back as `false` plus a sentence.

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

assert(JsonAP.APremoveJsonItemOBJECTWithMessage(path, "limits.rows", message));

if (!JsonAP.APaddJsonItemARRAYWithMessage!Point(arrayPath, "[9]", Point(0, 0), message))
{
    writeln(message);
    // array index 9 is out of range (length 2); nothing was changed.
}
```

`message` is cleared at the start of every call, so one variable is safe to reuse — which is what
[TextDAPSession.d:118](../../../JsonDAPtest/TextDAPSession.d#L118) relies on:

```d
bool added = JsonAP.APaddJsonItemOBJECTWithMessage!V(filePath, jsonPath, value, message);
if (added)
{
    return true;                                  // the key did not exist: it is new
}

return JsonAP.APupdateJsonValueOBJECTWithMessage!V(filePath, jsonPath, value, message);
```

| Line | What it does |
|---|---|
| `add` first | the cheap way to say "create or replace" without reading the file |
| `if (added) return true` | returns now, so the update never overwrites `message` |
| the second call | same `message` variable, overwritten from the inside |

That function is `writeValue` — the single write path of the whole app. Options, cursor, current
file and every document field go through it
([TextDAPSession.d:138](../../../JsonDAPtest/TextDAPSession.d#L138) adds the document index to the
path before calling it).

## The two families side by side

| Non-message (used by the tests) | Message twin (used by the app) |
|---|---|
| `APupdateJsonValueOBJECT` | `APupdateJsonValueOBJECTWithMessage` |
| `APupdateJsonValueARRAY` | `APupdateJsonValueARRAYWithMessage` |
| `APaddJsonItemOBJECT` | `APaddJsonItemOBJECTWithMessage` |
| `APaddJsonItemARRAY` | `APaddJsonItemARRAYWithMessage` |
| `APremoveJsonItemOBJECT` | `APremoveJsonItemOBJECTWithMessage` |
| `APremoveJsonItemARRAY` | `APremoveJsonItemARRAYWithMessage` |

The plain forms answer `bool` and stay quiet about the reason; the tests use them because an
assertion on `false` is enough there
([jsondap_file_tests.d:32](../../../JsonDAPtest/test/jsondap_file_tests.d#L32),
[:56](../../../JsonDAPtest/test/jsondap_file_tests.d#L56)). Keep the twins — neither replaces the
other.

Next: [07 — Merging and copying](07-merge-and-copy.md)
