# JsonDAP — Learn

**JsonDAP** is a JSON and file-handling library for the D programming language: serialization of
your own types, editing JSON files by path, and one exception tree that says what broke.

- API reference: [README.md](../README.md) · CHANGELOG: [CHANGELOG.md](../CHANGELOG.md)
- The reference program: **TextDAP** in `JsonDAPtest/` — a console text editor whose whole state
  lives in a JSON document. Every chapter cites the line that does the job there.

## Read this if you are new

| Chapter | What you get |
|---|---|
| [01 — Setup](Learn/English/01-setup.md) | the dependency in `dub.json`, the imports, how to build and test |
| [02 — Types and the round trip](Learn/English/02-types-and-the-round-trip.md) | your `struct` goes out and comes back; field names, `@JsonIgnore`, strict vs lenient |
| [03 — Files and arrays](Learn/English/03-files-and-arrays.md) | the six file methods, records in arrays, folders created for you |

## Read this if you already use it

| Chapter | What you get |
|---|---|
| [04 — Path syntax](Learn/English/04-path-syntax.md) | exactly what a path becomes, and the eight refusals |
| [05 — Reading one value](Learn/English/05-reading-a-value.md) | `APgetJsonValue!V`: which `V` matches which node |
| [06 — Editing a file by path](Learn/English/06-editing-a-file-by-path.md) | add / update / remove, and the reason a call said no |
| [07 — Merging and copying](Learn/English/07-merge-and-copy.md) | four merge APIs and why a plain `JSONValue` assignment is not a copy |
| [08 — SumType](Learn/English/08-sumtype.md) | the envelope, custom tags, the handler pair |
| [09 — Inspecting and guarding](Learn/English/09-inspecting-and-guarding.md) | predicates, digits in three scripts, blank guards |
| [10 — Exceptions](Learn/English/10-exceptions.md) | the tree, the fields worth printing, the catch ladder |
| [11 — The API, one example at a time](Learn/English/11-api-coverage-map.md) | nine programs that each run on their own, and every exported name in one table |

## The rules the library is built on

1. **Nothing is repaired silently.** A missing field, an unknown enum value or a bad path is an
   error, never a default, a cast or a guess.
2. **`false` always has a reason.** Every edit method that answers `bool` has a `…WithMessage` twin
   that answers the reason in the same breath.
3. **`Optional!T` means "there is no value".** Since 2.4.0 no reader hides an error inside it.
4. **Everything derives from `BaseExceptionAP`,** and everything carries the file and the line it
   was raised at.

Persian version: [StartPe.md](StartPe.md)
