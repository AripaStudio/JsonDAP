# 01 — Setting up

Index: [StartEn.md](../../StartEn.md)

## Adding the dependency

JsonDAP is a dub **source package**: no DLL, no import library, nothing to keep in step with
the sources. dub compiles the `.d` files straight into your own build.

A checkout next to your project:

```json
{
  "dependencies": {
    "jsondap": { "path": "../../JsonDAP" }
  }
}
```

Any other project, pinned to a tag:

```json
{
  "dependencies": {
    "jsondap": {
      "repository": "git+https://github.com/AripaStudio/JsonDAP.git",
      "version": "v2.4.1"
    }
  }
}
```

JsonDAP is not on the dub registry, so `~>2.4.1` resolves to nothing. The Git tag is `v2.4.1`,
prefix included.

## Your first program

Everything goes through the `JsonAP` class. This is TextDAP's own model, stripped down:

```d
import std.json;
import std.typecons;      // Nullable, which the library calls Optional
import JsonDAP;

struct Session
{
    @JsonName("current_file") string currentFile;   // the wire key differs from the field name
    @JsonName("tab_width") int tabWidth;
    @JsonIgnore string lookupKey;                   // memory-only, never written
}

void main()
{
    auto session = JsonAP.APdeserializeJsonLenient!Session(
            `{"current_file":"notes.txt"}`);

    if (!session.isNull)
    {
        session.get.currentFile;   // "notes.txt"
        session.get.tabWidth;      // 0 — a missing field keeps its default in lenient mode
    }
}
```

| Line | What it does |
|---|---|
| `import std.typecons;` | the readers return `Nullable!T`, aliased `Optional!T` |
| `import JsonDAP;` | one module exposes `JsonAP`, the exceptions and the traits |
| `JsonAP.AP…` | every method is `export static` on `JsonAP` — there are no free functions |
| `@JsonName("…")` | changes the key on the wire; no attribute means the D field name is used |
| `@JsonIgnore` | the field stays in memory and never reaches the file |
| `APdeserializeJsonLenient!Session` | missing fields keep their defaults instead of throwing |

## Build, test, and the reference program

```bash
cd JsonDAPtest
dub build --force   # Output/TextDAP.exe
dub test  --force   # the library's own test suite, living in JsonDAPtest/test/
```

**TextDAP** (`JsonDAPtest/`) is a console text editor whose state file is a JSON document —
the largest real test of this library. Every chapter below points at the file and the line that
does the job:

| File | What it is worth reading |
|---|---|
| [TextDAPModel.d:27](../../../JsonDAPtest/TextDAPModel.d#L27) | the structs, the enum, `@JsonName` / `@JsonIgnore` |
| [TextDAPSession.d:18](../../../JsonDAPtest/TextDAPSession.d#L18) | load: guard, exists, validate, lenient read, catch ladder |
| [TextDAPSession.d:83](../../../JsonDAPtest/TextDAPSession.d#L83) | save: serialize, merge, write, verify |
| [TextDAPConvert.d:18](../../../JsonDAPtest/TextDAPConvert.d#L18) | round trips of a record, a cursor and an array |
| [TextDAPJsonTools.d:108](../../../JsonDAPtest/TextDAPJsonTools.d#L108) | reading one value at a path |
| [TextDAPJsonEdit.d:113](../../../JsonDAPtest/TextDAPJsonEdit.d#L113) | picking the right edit method from the shape of a path |

Next: [02 — Types and the round trip](02-types-and-the-round-trip.md)