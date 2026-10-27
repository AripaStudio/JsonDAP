# 05 — Reading one value

Index: [StartEn.md](../../StartEn.md) · Previous: [04](04-path-syntax.md)

`APgetJsonValue!V(string jsonContent, string path)` walks a path and converts **the node it
lands on** to `V`. It reads text, not a file — take the file to a string first, or use
`APreadJsonFile` ([03](03-files-and-arrays.md)).

```d
string text = `{"settings":{"retry":7,"ratio":1.5,"label":"Aripa","on":true},`
        ~ `"rows":[{"name":"first"},{"name":"second"}]}`;

assert(JsonAP.APgetJsonValue!long(text, "settings.retry") == 7);
assert(JsonAP.APgetJsonValue!int(text, "settings.retry") == 7);
assert(JsonAP.APgetJsonValue!double(text, "settings.ratio") == 1.5);
assert(JsonAP.APgetJsonValue!double(text, "settings.retry") == 7.0);    // an integer node is a number
assert(JsonAP.APgetJsonValue!string(text, "settings.label") == "Aripa");
assert(JsonAP.APgetJsonValue!bool(text, "settings.on") == true);
assert(JsonAP.APgetJsonValue!string(text, "rows[1].name") == "second");
```

| `V` | Accepts which node | Refuses |
|---|---|---|
| `string` | `STRING` | anything else |
| `int`, `long` | `INTEGER` | `FLOAT` — no silent truncation |
| `float`, `double` | `FLOAT` **or** `INTEGER` | a string, a bool, an object |
| `bool` | `TRUE` / `FALSE` | `0` / `1` are integers, not booleans |

The `V` is the **requested** type, not the node's type. The mismatch is an error, never a cast:

```d
try
{
    JsonAP.APgetJsonValue!int(text, "settings.ratio");      // 1.5 read as int
}
catch (ConvertExceptionAP caught)
{
    caught.msg;     // JSON value is not an integer.
    caught.inputType;    // FLOAT
}
```

## Empty answer, exactly one case

```d
assert(JsonAP.APgetJsonValue!string("", "a.b").isNull);     // empty text
assert(JsonAP.APgetJsonValue!string(text, "").isNull);      // empty path
```

Anything else either returns a value or throws. Since 2.4.0 the getter **rethrows** what the library
raised instead of swallowing it into an empty `Optional`, so `isNull` no longer means "something
went wrong".

| What is wrong | Exception | Message you get |
|---|---|---|
| the text is not JSON at all | `JsonOperationExceptionAP` | `Error parsing JSON while getting value.` |
| a key on the way is missing | `JSONExceptionAP` | `JSON path invalid: key 'nope' not found.` |
| an index used on a non-array | `JSONExceptionAP` | `JSON path invalid: index used on a non-array.` |
| an index past the end | `InvalidArgumentExceptionAP` | `JSON array index out of bounds.` + `expectedFormatOrRange` |
| the node is the wrong type | `ConvertExceptionAP` | `JSON value is not an integer.` and friends |
| the path itself is malformed | `InvalidArgumentExceptionAP` | the parser's own refusal, see [04](04-path-syntax.md) |

## Reading four kinds, the way an app does it

[TextDAPJsonTools.d:108](../../../JsonDAPtest/TextDAPJsonTools.d#L108) gets the path and the kind
from a user, and the four `V` are four branches:

```d
if (kind == scalarKindText)
{
    reportValue(JsonAP.APgetJsonValue!string(text, dotPath), dotPath);
    return true;
}
if (kind == scalarKindWhole)
{
    reportValue(JsonAP.APgetJsonValue!long(text, dotPath), dotPath);
    return true;
}
// … double, bool
```

```d
private static void reportValue(V)(Optional!V found, string dotPath)
{
    if (found.isNull)                                   // only reachable for empty text/path
    {
        CL_TextDap_Console.sayFail(format!"'%s' holds no %s value."(dotPath, V.stringof));
        return;
    }

    CL_TextDap_Console.sayDone(format!"%s = %s"(dotPath, to!string(found.get)));
}
```

The `catch (BaseExceptionAP caught)` around the whole thing
([:142](../../../JsonDAPtest/TextDAPJsonTools.d#L142)) is what turns a wrong path into one printed
line instead of a stack trace.

## Reading a whole node instead of a scalar

`APgetJsonValue` converts, so it cannot hand you an object or an array. For that, read the file
as `JSONValue` and index it:

```d
JSONValue root = JsonAP.APreadJsonFile!JSONValue(path).get;

foreach (key; root.object.byKey)
{
    writeln(key, " is a ", JsonAP.APgetJsonValueType(root.object[key]));   // INTEGER, OBJECT, ARRAY…
}
```

That is [TextDAPJsonTools.d:162](../../../JsonDAPtest/TextDAPJsonTools.d#L162) — `inspectRoot`.

Next: [06 — Editing a file by path](06-editing-a-file-by-path.md)
