# 05 — Reading one value

Index: [StartEn.md](../../StartEn.md) · Previous: [04](04-path-syntax.md)

`APgetJsonValue!V(jsonContent, path)` walks a path and converts **the node it lands on** to `V`.
It reads text, not a file — turn the file into a string first, or read the file as `JSONValue`
(see [03](03-files-and-arrays.md)).

```d
string text = `{"options":{"tab_width":4,"autosave":true,` ~ `"session_title":"TextDAP"},`
        ~ `"documents":[{"file_path":"a.txt","title":"first"}]}`;

assert(JsonAP.APgetJsonValue!int(text, "options.tab_width") == 4);
assert(JsonAP.APgetJsonValue!bool(text, "options.autosave") == true);
assert(JsonAP.APgetJsonValue!string(text, "options.session_title") == "TextDAP");
assert(JsonAP.APgetJsonValue!string(text, "documents[0].title") == "first");
assert(JsonAP.APgetJsonValue!double(text, "options.tab_width") == 4.0);   // INTEGER node, float request
```

| `V` | Accepts | Refuses |
|---|---|---|
| `string` | `STRING` | anything else |
| `int`, `long` | `INTEGER` | `FLOAT` — no silent truncation |
| `float`, `double` | `FLOAT` **or** `INTEGER` | a string, a bool, an object |
| `bool` | `TRUE` / `FALSE` | `0` / `1` are integers, not booleans |

The `V` is the **requested** type, not the node's type, and a mismatch is an error, never a cast:

```d
try
{
    JsonAP.APgetJsonValue!int(text, "options.session_title");   // a string read as int
}
catch (ConvertExceptionAP caught)
{
    caught.inputType;    // STRING
    caught.outputType;   // int
}
```

## Empty answer, exactly one case

```d
assert(JsonAP.APgetJsonValue!string("", "a.b").isNull);     // empty text
assert(JsonAP.APgetJsonValue!string(text, "").isNull);      // empty path
```

Everything else either returns a value or throws — since 2.4.0 the getter **rethrows** instead of
swallowing an error into an empty `Optional`, so `isNull` no longer means "something went wrong".

| What is wrong | Exception |
|---|---|
| the text is not JSON at all | `JsonOperationExceptionAP` |
| a key on the way is missing | `JSONExceptionAP` (`jsonPath`, `jsonSnippet`) |
| an index used on a non-array | `JSONExceptionAP` — `index used on a non-array.` |
| an index past the end | `InvalidArgumentExceptionAP` (`expectedFormatOrRange`) |
| the node is the wrong type | `ConvertExceptionAP` (`inputType`, `outputType`) |
| the path itself is malformed | the parser's refusal — see [04](04-path-syntax.md) |

## Reading four kinds

`readValueAt` takes the path and a `kind` string from the user, and the four `V`s are four
branches ([TextDAPJsonTools.d:108](../../../JsonDAPtest/TextDAPJsonTools.d#L108)):

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
// … double, bool — four branches, four types
```

```d
private static void reportValue(V)(Optional!V found, string dotPath)
{
    if (found.isNull)                            // only reachable for empty text/path
    {
        CL_TextDap_Console.sayFail(format!"'%s' holds no %s value."(dotPath, V.stringof));
        return;
    }

    CL_TextDap_Console.sayDone(format!"%s = %s"(dotPath, to!string(found.get)));
}
```

The whole thing sits inside one `catch`, so a wrong path becomes one printed line instead of a
stack trace:

```d
catch (BaseExceptionAP caught)
{
    CL_TextDap_Console.sayFail(caught.msg);
    return false;
}
```

## Reading a whole node instead of a scalar

`APgetJsonValue` converts, so it cannot hand you an object or an array. Read the file as
`JSONValue` and index it — that is what `inspectRoot` does
([TextDAPJsonTools.d:162](../../../JsonDAPtest/TextDAPJsonTools.d#L162)):

```d
JSONValue root = JsonAP.APreadJsonFile!JSONValue(path).get;

foreach (key; root.object.byKey)
{
    writeln(key, " is a ", JsonAP.APgetJsonValueType(root.object[key]));   // INTEGER, OBJECT…
}
```

Next: [06 — Editing a file by path](06-editing-a-file-by-path.md)