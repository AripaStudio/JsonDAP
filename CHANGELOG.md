# Changelog

All notable changes to JsonDAP. The version in `JsonDAP/dub.json`, `README.md` and
`README.fa.md` must always agree with the top entry here.

**How the old entries were written.** JsonDAP had releases long before it had tags, so
`0.1.0` … `2.1.7` are reconstructed from the repository itself, not from memory. For every
version the span is a pair of commits — the commit that announces the version and the last
commit before the next version announces itself — and three things were read out of that span:
the commit subjects, `git diff --shortstat <span>` and the set of `export`ed `AP…` names in
`JsonDAP/*.d` at each tip. A version with `+0` names changed no callable surface. Where an
entry says a defect existed, it is either named by a commit message in that span or still
visible in the code the span produced; nothing here is inferred from how the library "must"
have behaved.

**Tags.** Existing tags use mixed spellings. The newly reconstructed tags are bare numbers:
`0.1.0`, `1.1.4`, `2.0.1`, `2.1.6`, `2.2.2`, `2.3.0` and `2.4.0`, each pointing at the
**tip** of its span. The requested `v2.4.1` tag is annotated and **local only** — never pushed,
not in a GitHub Release. For a dub Git dependency, `version` must be the exact Git ref name;
therefore this release uses `"version": "v2.4.1"`. `1.0.0`, `2.0.0` and `2.1.7` were already
tagged (at the announcing commit rather than the tip) and were deliberately **not** moved:
they exist on the remote, and re-pointing a published tag means a force-push. There is no
`2.2.0` tag and there never will be — that number was in a release archive only and never in
`dub.json` (`git log -S'"version": "2.2.0"' -- JsonDAP/dub.json` is empty).

---

## 2.4.1 — 2026-10-27 · tag `v2.4.1` (local, unpublished)

*Why this release exists: 2.4.0 was tagged at `7d04598` in the middle of the session that was
still writing the tutorial, so everything produced after that tag is this patch release. The
requested tag name `v2.4.1` is local on purpose — no push, no GitHub Release.*

### Fixed

- `APgetJsonValue!double` / `!float` reading an **integer** node no longer crashes. The guard
  accepted `JSONType.INTEGER`, then read `current.floating`, which is the one thing `std.json`
  refuses on an integer: the call died as `JsonOperationExceptionAP: Error parsing JSON while
  getting value.` for a perfectly valid document, while the README promised `double` accepts
  either type. Found by writing the tutorial examples — the integer branch now converts
  (`CoreAPPath.d:83-96`), with a regression assert at `JsonDAPtest/test/jsondap_path_tests.d:115`.

### Documentation added

- `Docs/` holds an eleven-chapter bilingual tutorial (`Docs/Start.md` → `Learn/English/`,
  `Learn/Persian/`). Every code block, every error message and every JSON output quoted there was
  compiled and run against these sources before it was written down.
- The READMEs now install JsonDAP from the **git repository** with a tag, next to the `path` form;
  the dub-registry block is gone, because the package was never published there.

### Changed

- `JsonDAP/dub.json`: the `unittest` configuration excludes `bin/**`, `Output/**` and `x64/**`
  and drops `test` from `sourcePaths`, so `dub test` on the library root survives the zip copies
  under `Output/` (the duplicate-module trap); a top-level `targetPath: Output` keeps build
  output out of the package root.
- `.gitignore`: `!Docs/` after `docs/` — with `core.ignorecase=true` the old pattern swallowed
  the whole tutorial folder; `/JsonDAP/test` and `/CHANGELOG.md` are gone (tests live in
  `JsonDAPtest/test/`, the changelog is tracked) and TextDAP's runtime files are listed.
- `JsonDAP.visualdproj` builds a static library (`<lib>1</lib>`, `.lib`) instead of the DLL-era
  `<lib>2</lib>` — the visuald mapping of `sourceLibrary` is `StaticLib` — and
  `JsonDAPtest.visualdproj` carries `<imppath>..\JsonDAP</imppath>` with `-i` in every config so
  Visual D resolves `import JsonDAP;`.
- Indentation is spaces everywhere: the tab-indented block in `FileAPJson.d` (101 lines), two
  lines in `JsonDAP.d` and two in `CoreAPPath.d` were converted, and the `}		catch` artefacts
  became a closing brace and a `catch` on their own lines. One of those two lines sits inside
  `mixin(q{ … })`, so the change is inside a string literal's contents — whitespace only, and
  the suite passes. No logic changed.

### Testing and packaging

- **The unit tests live with the application now.** `JsonDAP/test/` moved to
  `JsonDAPtest/test/` and is tracked in git (it was ignored before, so none of the scenarios
  were in the repository). Run them with `cd JsonDAPtest && dub test` — the package has a
  `unittest` configuration that compiles the library plus the test modules and nothing of the
  TextDAP shell except its data. `JsonDAPtest` itself, the console editor, is the library's
  biggest test bench.
- `CHANGELOG.md` is tracked in git (it was ignored before).
- `JsonDAP/Output/release/` is the zip-ready source package: 18 `.d` files, `dub.json`, the icon
  and the two READMEs, `LICENSE`, this file and `Docs/`. It was verified by building an unrelated
  consumer against it through a dub path dependency — deserialization, serialization,
  `APgetJsonValue` with `rows[1].name`, an edit-by-path and `APJsonPathParser("rows[۱].name")`
  all ran, exit 0 — and by copying the folder outside the tree and running `dub test` on it:
  every scenario passed.

---

## 2.4.0 — 2026-10-27 · tag `2.4.0` (`7d04598`)

*Why this release exists: everything up to 2.3.0 built a `JsonDAP.dll` that nobody consumed.
Half of the API is templates, and a template can only be instantiated where the sources are,
so the binary was always half a library — and `__ModuleInfo` is never exported, which is why a
consumer of the DLL hit `LNK2001`/`LNK2019` no matter what it did.*

### Breaking

- **JsonDAP is a dub source package now.** `targetType` is `sourceLibrary`, so there is no
  `JsonDAP.dll`, no import library and no `libs` block. `dub build` on the library root is
  refused by dub on purpose ("Main package must not have target type sourceLibrary") — verify
  the library with `dub test`, and build it by depending on it (see *Install* in the README).
  This closes the DLL boundary problem (was G3).
- **One path grammar.** `APgetJsonValue` now parses with the same character-level parser as
  `APJsonPathParser` and the file-edit API, so a bare numeric segment is an object key and only
  `[n]` is an index. `items.1` on an array, which used to read the second element, now raises
  `JSON path invalid: key '1' not found.` Write `items[1]`.
- **`APaddJsonItemARRAY` inserts instead of appending.** The item is placed at the index in the
  path, `index == length` is the append position, and anything past that returns
  `array index N is out of range (length M); nothing was changed.` — the file is left untouched,
  which the old "appended" wording did not promise (was H1, H2).
- **`APrecursiveMerge` takes its source by value.** The signature is
  `APrecursiveMerge(ref JSONValue target, JSONValue source, ...)`: the source is deep-copied
  first, so an rvalue is accepted and the document you pass in is never rewritten as a side
  effect of the merge (was H4).

### Added

- **`CL_PublicCodeOtherCode.parsePath`** — the single path parser now behind `APJsonPathParser`,
  `APgetJsonValue` and every file-edit method: `\` escapes (so a key can contain `.`, `[` or `]`),
  chained brackets (`rows[0][1]`), Persian and Arabic-Indic digits inside `[ ]`, and a typed
  `InvalidArgumentExceptionAP` for `""`, `"   "`, `a..b`, `items[3`, `items]`, `items[0]x`,
  `items[abc]` and `items[-1]` (was G1, was H7).
- **`APdeepCopy(JSONValue v)`** — an independent copy of a JSON tree; no array, object or nested
  node is shared with the original.
- **`APrecursiveMergeCopy(JSONValue target, JSONValue source, bool overwrite, bool mergeArrays,
  out JSONValue result, out string message)`** — the non-destructive merge: `target` stays as it
  was and the outcome arrives in `result`. `APdeepCopy` is what both it and the copy-on-merge in
  `APrecursiveMerge` are built from.
- **`APisSignedInteger(string)`** and **`APisDecimal(string)`** — the two gates `APisInteger` was
  described as covering: `APisInteger` is digits-only, `"7.5"` and `"+7"` belong to these.
- **`APstrIsNil(input, paramName, out bool, out string reason)`**.
- `normalizeSymbolAP` maps `٫`/`٬` to `.` and `−` (U+2212) to `-`, so `APnormalizeDigitsAP("۱۲٫۵")`
  is `"12.5"` and `APisSignedInteger("−7")` is `true`.

### Fixed

- Negative array indexes are refused at the parser as `non-negative`, instead of reaching a
  `[0 .. -1]` slice through an implicit `int → size_t` widening (was H3).
- An out-of-bounds index on an **empty** array reported `0-18446744073709551615`; the hint now
  says `the array is empty` (was H13).
- `APisInteger` is documented as digits-only, which is what it always did (was H5).
- The commented-out `enforce(...)` block in `FileAP.d` is gone (was H8).

### Changed

- `UnknownErrorexceptionAP` → `UnknownErrorExceptionAP`, matching `SyntaxErrorExceptionAP`. The
  old spelling remains as a `deprecated` alias.
- `APStrIsNUll` → `APstrIsNil` (and `StrIsNUll` → `strIsNil`), with the message parameter renamed
  from `ErrorText` to `reason`. The old names remain as `deprecated` forwarders (was H6).
- `dub.json` no longer lists `msvcrt`, `legacy_stdio_definitions` or `oldnames`, and no build
  type forces `dynamicLibrary`.

### Testing

- The 2.3.0-era expectations in `JsonDAPtest/test/jsondap_file_tests.d` scenario 17 were
  re-typed for the single grammar: `items[]`, `items[x]` and `items[2]` now raise
  `InvalidArgumentExceptionAP` instead of `ConvertExceptionAP` / `UnknownErrorexceptionAP`, and
  `items[2147483648]` is asserted as `ConvertExceptionAP`. That was the last use of the
  deprecated `UnknownErrorexceptionAP` spelling in the repo.
- `JsonDAPtest/test/jsondap_path_tests.d` corrected itself: an array `add` is an insert (so
  `items[3]` and the `index == length` append are asserted as they now behave), `a.b[2].c` is
  four steps not three, and an out-of-range update is probed at the first refused index.

### Packaging and repository hygiene (same release)

- Every binary left over from the DLL era was deleted: `JsonDAPtest/JsonDAP.{dll,lib,exp}`,
  `JsonDAP/Output/{debug,release}/JsonDAP.{dll,lib,exp}` and the stale test runner. A source
  package has no use for them and their presence made it look like 2.4.0 still shipped one.


---

## 2.3.0 — 2026-10-26 · tag `2.3.0` (`7e4e89a` … `340961c`)

*Defect it answers: 2.2.2 still let a raw `std.conv.ConvException` escape from the path parser,
and `APgetJsonValue` swallowed every failure into `UnknownErrorexceptionAP`, so the reason was
gone before the caller saw it (G1, G2).*

### Added

- **Digit normalization** — `APnormalizeDigitsAP(string)` rewrites Persian (`U+06F0-06F9`) and
  Arabic-Indic (`U+0660-0669`) digits as ASCII digits and leaves every other character alone
  (`CL_PublicCodeOtherCode.toAsciiDigit` does the per-character mapping). `APJsonPathParser`
  and the array branch of `APgetJsonValue` run an index through it, so `items[۲]` and
  `items[٢]` now mean `items[2]`.
- **A one-string merge answer** — `APmergeJsonWithMessage(filePath, jsonContentToMerge,
  overwriteExisting = true, mergeArrays = false)` returns `string`: an empty string means the
  merge happened, any text is the reason it did not. The `bool` + `out string message` form is
  still available — it had to be re-declared in `JsonAP`, because a member of a derived class
  hides the inherited member of the same name in D.
- **Test scenarios 17 to 20** — an unusable array index raises instead of killing the process,
  digits from every supported block reach the same conversion, a whole-number request on a
  float node reports precisely, and both call shapes of the merge API agree.

### Fixed

- `JsonPathParserAP` no longer leaks `std.conv.ConvException`: converting the text inside
  `[ ]` is wrapped, and a bad index now arrives as `ConvertExceptionAP` — inside
  `BaseExceptionAP`, where every consumer already catches (was G1).
- `APgetJsonValue!V` rethrows its own exception tree instead of swallowing it into
  `UnknownErrorexceptionAP`, so the reason survives the call (was G2).
- `APisDigitAP` agrees with conversion for both digit blocks (was G5).

### Changed

- `APgetJsonValue!long` and `!int` now require an `INTEGER` node: reading `2.5` as a whole
  number raises `ConvertExceptionAP("JSON value is not an integer.")` instead of silently
  returning `2`. `!double` still accepts both nodes.
- The filename of the path-parsing module matches its module declaration
  (`jsonOtherCodeAP.d`); the capitalised copy broke `dub test` with "module specified twice".

## 2.2.2 — 2026-10-25 · tag `2.2.2` (`e5d4c8b` … `5226820`, number set in `e439623`)

*Defect it answers: every `bool`-returning edit call reported failure by returning `false` and
saying nothing, so a rejected edit could not be told apart from an unrelated problem; and
`APremoveJsonItemOBJECT` refused every top-level key.*

### Added

- **Message-carrying edit API** — `APupdateJsonValueOBJECTWithMessage`,
  `APupdateJsonValueARRAYWithMessage`, `APaddJsonItemOBJECTWithMessage`,
  `APaddJsonItemARRAYWithMessage`, `APremoveJsonItemOBJECTWithMessage`,
  `APremoveJsonItemARRAYWithMessage` and `APmergeJsonWithMessage`. Each returns the same
  `bool` and fills `out string message` with the reason of a failure; the message stays
  empty on success. They never throw, so a missing file, a broken document or an unusable
  path all arrive as `false` + explanation. Callable surface: 34 → 47 exported `AP…` names.
- **File-error test coverage** — scenarios 13 to 16: missing file, corrupt JSON on disk,
  unusable paths, and the success/failure protocol of the message API.

### Changed

- `convertJsonValueToT` is a dispatch table over private helpers (`convertPrimitive`,
  `convertArray`, `convertNullable`, `convertEnum`) with the struct/class field loop moved
  to the new module `CoreAPConvObject.d`. Same behaviour, same error messages.
- `mergeJson` moved to `FileAPMerge.d` (`CL_FileAP_Merge`).
- `dub.json` now keeps one source list: the `library` configuration inherits the top-level
  `sourceFiles`, and the `unittest` configuration takes everything under `.` and `test/`
  and excludes `bin/`. The ignored `targetPath` keys inside `buildTypes` were removed.
- Test harness split into `jsondap_test_fixtures.d`, `jsondap_tests.d` (scenarios 1–8) and
  `jsondap_file_tests.d` (scenarios 9–16).
- The library went from 7 files to 18 single-responsibility modules (the split itself landed in
  this span, together with the 2.2.0 fixes below).

### Fixed

- `APremoveJsonItemOBJECT` refused every top-level key because of a `parsedSteps.length <= 1`
  guard; it now removes root keys like the update and add APIs already did.
- `APupdateJsonValueOBJECT` threw `FileOperationExceptionAP` for a missing file while every
  other edit call returned `false`. All edit calls now share the `false` + message contract.

## 2.2.0 — 2026-10-20 · **no tag** (release archive only)

*Defect it answers: the strict/lenient contract did not exist, so a JSON document that left a
field out threw instead of deserializing; `null` class references and empty `Nullable` fields
threw; an unknown `enum` value was silently `cast` to whatever the integer happened to be; and
`readJsonArray` was dead code because of `enforce(cond, throw new E(...))`. This number was
never written into `dub.json` — `git log -S'"version": "2.2.0"' -- JsonDAP/dub.json` returns
nothing — it exists in `JsonDAP/bin/version2.2.0/JsonDAP2-2-0.rar`. The same content was
committed under 2.2.2.*

### Added

- `SumType` support: `APserializeSumType`, `APdeserializeSumType`,
  `APdeserializeSumTypeFromString` and both `…WithHandlers` variants, using the
  `{"tag":"<member>","value":<payload>}` envelope.
- Field-level contract: `@JsonName` and `@JsonIgnore`, honoured in both directions.
- Lenient deserialization: `APdeserializeJsonLenient`.
- JSON path editing: update/add/remove for objects and arrays, plus `APmergeJson`.
- Automatic test suite (`dub test`, 12 scenarios at the time) and a single `dub.json` for
  build and tests.

### Fixed

- `readJsonArray` was dead because of `enforce(cond, throw new E(...))`.
- Unknown `enum` values were silently `cast`; they are now reported with the valid members.
- `null` class references and empty `Nullable` fields threw instead of mapping to `null`.
- `JSONValue.object` accessed on a non-object node threw out of `bool`-returning APIs; the
  type guard now runs first.
- Deep JSON paths failed on a missing intermediate key because `JSONValue.init` was used
  instead of `JSONValue.emptyObject`.

## 2.1.7 — 2026-06-09 · tag `2.1.7` (`f36329c`, existing tag, not moved; span tip `eeee8a0`)

*Defect it answers: 2.1.6 rewrote half the library and the test suite no longer matched it;
the dub description file also carried settings that only made sense while the project still
built a DLL.*

### Fixed

- The test suite passes again (`4dab4a4` "Fix Other Error in Test - Update Version 2.1.7").
- `dub.json` and `.gitignore` cleaned (`f36329c` "Fix dub file and gitignore").
- `Error: undefined identifier 'PathStep'` when the path module was compiled before its
  consumer — the import that made `PathStep` visible was missing (`eeee8a0`).

## 2.1.6 — 2026-06-09 · tag `2.1.6` (`07cd1b4` … `83243b3`)

*Defect it answers: 2.0.x corrupted documents in three ways that were hard to see — a merge
could write the source into the target, a type that referenced itself never terminated, and a
path with a dot inside a key was split as if it were two keys.*

### Fixed

- `mergeJson` corrected; `recursiveMerge` optimised (`07cd1b4`).
- Circular references in `serializeTToJsonValue` handled instead of recursing forever.
- `JsonPathParserAP` updated and fixed; `checkStringIsNull_array` updated and fixed.
- One more exception type added to the tree (the ancestor of today's `BaseExceptionAP` set).
- Callable surface unchanged: still 34 exported `AP…` names, 7 modules.

## 2.0.1 — 2025-08-02 · tag `2.0.1` (`3d1f73c` … `a4724d9`)

*Defect it answers: 2.0.0 did not compile everywhere. Two commits in this span are literally
"Fix Error ref/:" and "fix Error __traits".*

### Fixed

- A `__traits` misuse in the type-trait checks (`CheckVariablesAP.d`) that failed outside the
  test file that introduced it.
- A reference (`ref`) error in the file layer (`FileAP.d`).
- `dub.json` corrected, including the version field that dub requires the root package to
  declare (`3d1f73c` "fix dub (start V2.0.1)", `a9c7537` "update Dub and FileRelease").
- Callable surface unchanged: 34 exported `AP…` names.

## 2.0.0 — 2025-07-29 · tag `2.0.0` (`72f6dac`, existing tag, not moved)

*Defect it answers: 1.1.4 could read a JSON document into a D type and nothing else. There was
no way to change one value in a file, no way to combine two documents, and the failure modes
were `Exception` strings rather than a hierarchy.*

This span is 64 commits and 1 840 added lines over 10 files — the largest in the project's
history. Callable surface: 15 → 34 exported `AP…` names, 4 → 7 modules.

### Added

- **Edit a JSON file by path**: `APupdateJsonValueOBJECT`, `APupdateJsonValueARRAY`,
  `APaddJsonItemOBJECT`, `APaddJsonItemARRAY`, `APremoveJsonItemOBJECT`,
  `APremoveJsonItemARRAY` and `APmergeJson`.
- **A path parser**: `JsonPathParserAP` in the new `JsonOtherCodeAP.d`, exposed as
  `APJsonPathParser`.
- **The conversion layer**: `APconvertJsonValueToT`, `APserializeToJson`,
  `APserializeToJsonArray`, `APserializeTToJsonValue`, `APdeserializeJson`,
  `APdeserializeJsonArray`, `APgetJsonValueType`.
- **Compile-time type traits** in `CheckVariablesAP.d`: `IsIntAP`, `IsFloatAP`, `IsNumberAP`,
  `IsBoolAP`, `IsStringAP`, `IsArrayAP`, `IsClassAP`, `IsEnumAP`, `IsStructAP` (`84526f4`).
- **`recursiveMerge`** — the deep merge the file API is built on (`75f50f0`, `2d88a1f`).
- **The exception module** `ExceptionAP.d` rewritten: `BaseExceptionAP` with a correlation id,
  `ParameterRelatedExceptionAP`, `FileOperationExceptionAP`, and the `ConvertExceptionAP` /
  `JSONConvertExceptionAP` pair (`51d6a8d`, `3ae47d4` "Close Issues #1").
- `APexists`, `APStrIsNUll`, `APCheckStringIsNullArray` — the guards that 2.4.0 renamed.

### Fixed

- `readFile`/`writeFile`, `existsFile`, `writeJsonFile` and the two `updateJsonValue` methods
  were rewritten through this span; the commit subjects name each one
  (`f61c880`, `309a97e`, `36774e0`, `8d5e597`, `a75b6cc`, `9b84c66`).
- A self-conversion bug — a value converted into its own type — closed (`5dae130`).

## 1.1.4 — 2025-07-14 · tag `1.1.4` (`91f973d` … `be75fe1`)

*Defect it answers: 1.0.0 could only turn a whole document into a `JSONValue`; there was no
generic "give me this D type" conversion and no way to ask what a node even is.*

### Added

- `convertJsonValueToT` and `getJsonValueType` — the ancestors of today's
  `APconvertJsonValueToT!T` and `APgetJsonValueType` (`c8c2b9f`).
- The first custom exception types, before there was an exception module.

### Fixed

- `existsFile` (`88ae306`) and `ConvertJsonValueToT` (`be75fe1`).
- Callable surface unchanged (15 names): these were helpers, not `export`ed API yet.

## 1.0.0 — 2025-07-13 · tag `1.0.0` (`f441fa4`, existing tag, not moved)

*Defect it answers: the dub package would not build. "Fix Dub" is the commit this version is
tagged at.*

### Added

- `APexistsFile` (`8511faa`) — a file-exists check on the API, not just in the internals.
- The first `README.md` (`f612fe3`).
- First dub-clean build (`f441fa4`).

## 0.1.0 — 2025-07-12/13 · tag `0.1.0` (`3c7558d` … `3c2cbcf`)

*The starting point: 9 commits, 1 403 lines, 4 modules (`JsonDAP.d`, `CoreAP.d`, `FileAP.d`,
`PublicCodeOtherCode.d`), 14 exported `AP…` names.*

### Added

- Read and write a JSON file (`APreadJsonFile`, `APwriteJsonFile`, `APreadJsonArray`).
- Read one value by path (`APgetJsonValue`) and inspect a document
  (`APisValidJson`, `APisJsonObject`, `APisJsonArray`, `APisJsonNumber`, `APisJsonString`,
  `APgetJsonItemCount`, `APgetJsonFileSize`, `APprettyPrintJson`).
- The two helpers that survived to today almost unchanged: `APisDigitAP`, `APisInteger`.
- `LICENSE` (MIT), the Visual Studio solution and the first `dub.json`.

### Fixed

- `JSON_TYPE` renamed to `JSONType` to match `std.json` (`086add0`).
- The DLL entry point problem of the very first build ("Fix Main Dll", `7617fba`) — the same
  boundary that finally made 2.4.0 stop shipping a DLL at all.
