# 10 — Exceptions

Index: [StartEn.md](../../StartEn.md) · Previous: [09](09-inspecting-and-guarding.md)

Every failure the library raises derives from `BaseExceptionAP`
([ExceptionAP.d:7](../../../JsonDAP/ExceptionAP.d#L7)), and every one of them is raised *with the
place it happened*: the constructors take `string file = __FILE__, size_t line = __LINE__` and
forward them to `Exception`.

```
BaseExceptionAP                      correlationId, file, line
├── ParameterRelatedExceptionAP      parameterName, invalidValue
│   ├── ConvertExceptionAP           inputType, outputType, conversionMethod, reasonForFailure
│   │   └── JSONConvertExceptionAP   jsonSpecificError
│   ├── InvalidArgumentExceptionAP   expectedFormatOrRange
│   └── ArgumentNullExceptionAP
├── JSONExceptionAP                  jsonPath, jsonSnippet
│   └── JsonOperationExceptionAP
├── FileOperationExceptionAP         filePath, operationType, systemErrorCode
├── SyntaxErrorExceptionAP
└── UnknownErrorExceptionAP
```

## Reading a failure instead of guessing at one

```d
import std.exception : assertThrown;
import JsonDAP;

try
{
    JsonAP.APdeserializeJson!Options(`{"autosave":true}`);     // tab_width is missing
}
catch (JSONConvertExceptionAP caught)
{
    caught.classinfo.name;      // ExceptionJsonAP.JSONConvertExceptionAP
    caught.parameterName;       // tabWidth              (the D field, not "tab_width")
    caught.invalidValue;        // Not Found
    caught.jsonSpecificError;   // MissingField
    caught.reasonForFailure;    // Mandatory field missing for object conversion.
    caught.inputType;           // N/A
    caught.outputType;          // int
    caught.file;                // the D source file that raised it
    caught.line;                // and its line
}
```

| Line | What it does |
|---|---|
| `classinfo.name` | the module-qualified runtime class — worth printing in a bug report |
| `parameterName` | named as declared in D; the wire name is only in the JSON, not here |
| `jsonSpecificError` | a stable code (`MissingField`, `TypeMismatch`, `ObjectConversionFailed`), not prose |
| `file` / `line` | the raise site. A throw inside a `mixin(q{…})` reports as `CoreAPPath.d-mixin-62:79` |

## Which exception for which problem

```d
try { JsonAP.APreadJsonFile!Point(buildPath(tempDir, "no_such.json")); }
catch (FileOperationExceptionAP e) { e.filePath; e.operationType; }   // …json, "read"

try { JsonAP.APgetJsonValue!string(text, "settings.nope"); }
catch (JSONExceptionAP e) { e.jsonPath; e.jsonSnippet; }              // the path, the whole document

try { JsonAP.APJsonPathParser("items[abc]"); }
catch (InvalidArgumentExceptionAP e) { e.expectedFormatOrRange; }     // "0, 1, 2, …"

try { JsonAP.APgetJsonValue!int(text, "settings.ratio"); }
catch (ConvertExceptionAP e) { e.inputType; e.outputType; }           // FLOAT -> int
```

## The catch ladder

Order matters: the JSON-specific class first, the root last.

```d
try
{
    auto parsed = JsonAP.APdeserializeJsonLenient!SessionFile(text);
    return Optional!SessionFile(parsed.get);
}
catch (JSONExceptionAP caught)          // anything the JSON layer knows about
{
    CL_TextDap_Console.sayFail(caught.msg);
    return Optional!SessionFile.init;
}
catch (BaseExceptionAP caught)          // every other library failure
{
    CL_TextDap_Console.sayFail(caught.msg);
    return Optional!SessionFile.init;
}
```

That is [TextDAPSession.d:71](../../../JsonDAPtest/TextDAPSession.d#L71). The library's own wrapping
is the same ladder, seen from the other side
([FileAP.d:52](../../../JsonDAP/FileAP.d#L52)):

```d
catch (BaseExceptionAP e) throw e;                                 // already ours: rethrow unchanged
catch (FileException   e) → FileOperationExceptionAP;              // Phobos → ours
catch (JSONException   e) → JsonOperationExceptionAP;
catch (Exception       e) → UnknownErrorExceptionAP;               // nothing escapes unnamed
```

## What is *not* an exception

| Channel | Used by |
|---|---|
| `bool` | the writers, the edit methods, the predicates |
| `bool` + `out string message` | the `…WithMessage` twins ([06](06-editing-a-file-by-path.md)) |
| `Optional!T` | the readers — and since 2.4.0 only for "there is no value", never for "an error happened" |

The rule to write your program by: **a `false` from this library always has a reason, and the
`WithMessage` twin is what prints it.** Use exceptions where an unexpected failure should abort a
command; use the twins where a bad path is a normal thing for a user to type.

Next: [11 — API coverage map](11-api-coverage-map.md)
