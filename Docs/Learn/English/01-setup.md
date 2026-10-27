# 01 — Setting up

Index: [StartEn.md](../../StartEn.md)

## The two ways to depend on JsonDAP

JsonDAP is a dub **source package** (`"targetType": "sourceLibrary"`). There is no DLL, no
import library, nothing to keep in step with the sources — dub compiles the `.d` files into
your own build.

A checkout that sits next to your project:

```json
{
  "dependencies": {
    "jsondap": { "path": "../JsonDAP" }   // the folder holding JsonDAP/dub.json
  }
}
```

Any other project, pinned to a tag:

```json
{
  "dependencies": {
    "jsondap": {
      "repository": "git+https://github.com/AripaStudio/JsonDAP.git",
      "version": "v2.4.1"                 // the exact Git tag name
    }
  }
}
```

JsonDAP is not on the dub registry, so `"jsondap": "~>2.4.1"` resolves to nothing. The Git tag is named `v2.4.1`, so keep the prefix in the repository dependency.

## The first lines of a program

```d
import std.json;          // JSONValue / JSONType / parseJSON stay Phobos' own types
import std.typecons;      // Nullable, which the library calls Optional
import JsonDAP;           // one module brings the whole API

struct Greeting
{
    @JsonName("text") string body;          // the wire key is "text"
}

void main()
{
    auto parsed = JsonAP.APdeserializeJson!Greeting(`{"text":"hello"}`);   // always qualified, always AP…
    if (!parsed.isNull)
    {
        parsed.get.body;                     // "hello"
    }
}
```

| Line | What it does |
|---|---|
| `import std.json;` | `JsonDAP` does not re-export `JSONValue`; import it yourself |
| `import std.typecons;` | the return type of the readers is `Nullable!T`, aliased `Optional!T` |
| `import JsonDAP;` | exposes `JsonAP`, `PathStep`, the exceptions and the traits |
| `JsonAP.AP…` | every method is `export static` on the `JsonAP` class — there are no free functions |
| `APdeserializeJson!Greeting` | takes **JSON text whose top node is an object**; a bare `"text"` or `[1,2]` is refused |

## Build, test, and the reference program

```bash
dub build          # in your own package
dub test           # compiles the library and runs every unittest in it
```

The repository ships a complete consumer, **TextDAP**, in `JsonDAPtest/` — a console text
editor whose state file is a JSON document. It is the largest real test of this library, and
every chapter of this tutorial points at the line that does the job there.

```bash
cd JsonDAPtest
dub build --force  # Output/TextDAP.exe
dub test  --force  # the library's own test suite, living in JsonDAPtest/test/
```

| File | What it is worth reading |
|---|---|
| [TextDAPModel.d:27](../../../JsonDAPtest/TextDAPModel.d#L27) | the structs, the enum, the `@JsonName` / `@JsonIgnore` usage |
| [TextDAPSession.d:18](../../../JsonDAPtest/TextDAPSession.d#L18) | load: guard, exists, validate, lenient read, catch ladder |
| [TextDAPSession.d:83](../../../JsonDAPtest/TextDAPSession.d#L83) | save: serialize, merge, write, verify |
| [TextDAPConvert.d:18](../../../JsonDAPtest/TextDAPConvert.d#L18) | the round trips of a record, a cursor and an array |
| [TextDAPJsonTools.d:108](../../../JsonDAPtest/TextDAPJsonTools.d#L108) | reading one value at a path |
| [TextDAPJsonEdit.d:113](../../../JsonDAPtest/TextDAPJsonEdit.d#L113) | picking the right edit method from the shape of a path |

Next: [02 — Types and the round trip](02-types-and-the-round-trip.md)
