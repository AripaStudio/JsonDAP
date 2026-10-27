# 11 — API coverage map

Index: [StartEn.md](../../StartEn.md) · Previous: [10](10-exceptions.md)

Every exported `AP…` name, the chapter that explains it, and the line that already uses it. "—"
means neither the app nor the tests call it, so the tutorial's example is the only demonstration.
App = `JsonDAPtest/*.d`, Tests = `JsonDAPtest/test/*.d`.

## Files

| API | Chapter | App | Tests |
|---|---|---|---|
| `APreadJsonFile!T` | [03](03-files-and-arrays.md) | [TextDAPSession.d:159](../../../JsonDAPtest/TextDAPSession.d#L159) | jsondap_api_tests.d:34, jsondap_file_tests.d:60 |
| `APwriteJsonFile!T` | [03](03-files-and-arrays.md) | [TextDAPConvert.d:108](../../../JsonDAPtest/TextDAPConvert.d#L108) | jsondap_file_tests.d:20 |
| `APreadJsonArray!T` | [03](03-files-and-arrays.md) | [TextDAPConvert.d:114](../../../JsonDAPtest/TextDAPConvert.d#L114) | [jsondap_file_tests.d:24](../../../JsonDAPtest/test/jsondap_file_tests.d#L24) |
| `APgetJsonFileSize` | [03](03-files-and-arrays.md) | [TextDAPSession.d:191](../../../JsonDAPtest/TextDAPSession.d#L191) | [jsondap_file_tests.d:22](../../../JsonDAPtest/test/jsondap_file_tests.d#L22) |
| `APexistsFile` | [03](03-files-and-arrays.md) | [TextDAPSession.d:30](../../../JsonDAPtest/TextDAPSession.d#L30) | [jsondap_file_tests.d:21](../../../JsonDAPtest/test/jsondap_file_tests.d#L21) |
| `APexists` | [03](03-files-and-arrays.md) | [TextDAPDocument.d:91](../../../JsonDAPtest/TextDAPDocument.d#L91) | — |

## Types and conversion

| API | Chapter | App | Tests |
|---|---|---|---|
| `APserializeToJson!T` | [02](02-types-and-the-round-trip.md) | [TextDAPSession.d:91](../../../JsonDAPtest/TextDAPSession.d#L91) | [jsondap_api_tests.d:57](../../../JsonDAPtest/test/jsondap_api_tests.d#L57) |
| `APserializeTToJsonValue!T` | [02](02-types-and-the-round-trip.md) | [TextDAPConvert.d:22](../../../JsonDAPtest/TextDAPConvert.d#L22) | — |
| `APserializeToJsonArray!T` | [03](03-files-and-arrays.md) | [TextDAPConvert.d:105](../../../JsonDAPtest/TextDAPConvert.d#L105) | — |
| `APdeserializeJson!T` | [02](02-types-and-the-round-trip.md) | [TextDAPConvert.d:265](../../../JsonDAPtest/TextDAPConvert.d#L265) | [jsondap_api_tests.d:60](../../../JsonDAPtest/test/jsondap_api_tests.d#L60) |
| `APdeserializeJsonLenient!T` | [02](02-types-and-the-round-trip.md) | [TextDAPSession.d:53](../../../JsonDAPtest/TextDAPSession.d#L53) | [jsondap_tests.d:59](../../../JsonDAPtest/test/jsondap_tests.d#L59) |
| `APdeserializeJsonArray!T` | [03](03-files-and-arrays.md) | [TextDAPConvert.d:186](../../../JsonDAPtest/TextDAPConvert.d#L186) | [jsondap_file_tests.d:28](../../../JsonDAPtest/test/jsondap_file_tests.d#L28) |
| `APconvertJsonValueToT!T` | [02](02-types-and-the-round-trip.md) | [TextDAPConvert.d:29](../../../JsonDAPtest/TextDAPConvert.d#L29) | [jsondap_tests.d:151](../../../JsonDAPtest/test/jsondap_tests.d#L151) |
| `APgetJsonValueType` | [05](05-reading-a-value.md) | [TextDAPJsonTools.d:176](../../../JsonDAPtest/TextDAPJsonTools.d#L176) | jsondap_tests.d |
| `IsIntAP` … `IsNumberAP` (traits) | [02](02-types-and-the-round-trip.md) | [TextDAPModel.d:232](../../../JsonDAPtest/TextDAPModel.d#L232) | jsondap_tests.d |

## Paths and reading

| API | Chapter | App | Tests |
|---|---|---|---|
| `APJsonPathParser` | [04](04-path-syntax.md) | [TextDAPJsonEdit.d:131](../../../JsonDAPtest/TextDAPJsonEdit.d#L131) | [jsondap_file_tests.d:80](../../../JsonDAPtest/test/jsondap_file_tests.d#L80) |
| `APgetJsonValue!V` | [05](05-reading-a-value.md) | [TextDAPJsonTools.d:120](../../../JsonDAPtest/TextDAPJsonTools.d#L120) | [jsondap_file_tests.d:88](../../../JsonDAPtest/test/jsondap_file_tests.d#L88), [jsondap_path_tests.d:111](../../../JsonDAPtest/test/jsondap_path_tests.d#L111) |

## Editing a file

| API | Chapter | App | Tests |
|---|---|---|---|
| `APupdateJsonValueOBJECT!V` | [06](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:56](../../../JsonDAPtest/test/jsondap_file_tests.d#L56) |
| `APupdateJsonValueARRAY!V` | [06](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:32](../../../JsonDAPtest/test/jsondap_file_tests.d#L32) |
| `APaddJsonItemOBJECT!T` | [06](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:57](../../../JsonDAPtest/test/jsondap_file_tests.d#L57) |
| `APaddJsonItemARRAY!T` | [06](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:33](../../../JsonDAPtest/test/jsondap_file_tests.d#L33) |
| `APremoveJsonItemOBJECT` | [06](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:64](../../../JsonDAPtest/test/jsondap_file_tests.d#L64) |
| `APremoveJsonItemARRAY` | [06](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:34](../../../JsonDAPtest/test/jsondap_file_tests.d#L34) |
| `APupdateJsonValueOBJECTWithMessage!V` | [06](06-editing-a-file-by-path.md) | [TextDAPSession.d:135](../../../JsonDAPtest/TextDAPSession.d#L135) | [jsondap_file_tests.d:117](../../../JsonDAPtest/test/jsondap_file_tests.d#L117) |
| `APupdateJsonValueARRAYWithMessage!V` | [06](06-editing-a-file-by-path.md) | [TextDAPScalar.d:203](../../../JsonDAPtest/TextDAPScalar.d#L203) | [jsondap_file_tests.d:157](../../../JsonDAPtest/test/jsondap_file_tests.d#L157) |
| `APaddJsonItemOBJECTWithMessage!T` | [06](06-editing-a-file-by-path.md) | [TextDAPSession.d:129](../../../JsonDAPtest/TextDAPSession.d#L129) | [jsondap_file_tests.d:119](../../../JsonDAPtest/test/jsondap_file_tests.d#L119) |
| `APaddJsonItemARRAYWithMessage!T` | [06](06-editing-a-file-by-path.md) | [TextDAPScalar.d:192](../../../JsonDAPtest/TextDAPScalar.d#L192) | [jsondap_path_tests.d:36](../../../JsonDAPtest/test/jsondap_path_tests.d#L36) |
| `APremoveJsonItemOBJECTWithMessage` | [06](06-editing-a-file-by-path.md) | [TextDAPJsonEdit.d:71](../../../JsonDAPtest/TextDAPJsonEdit.d#L71) | [jsondap_file_tests.d:164](../../../JsonDAPtest/test/jsondap_file_tests.d#L164) |
| `APremoveJsonItemARRAYWithMessage` | [06](06-editing-a-file-by-path.md) | [TextDAPJsonEdit.d:67](../../../JsonDAPtest/TextDAPJsonEdit.d#L67) | [jsondap_file_tests.d:121](../../../JsonDAPtest/test/jsondap_file_tests.d#L121) |
| `APEditMessages` | [06](06-editing-a-file-by-path.md) | the base class of `JsonAP` — never instantiated | — |

## Merging and copying

| API | Chapter | App | Tests |
|---|---|---|---|
| `APmergeJson` | [07](07-merge-and-copy.md) | — | [jsondap_file_tests.d:68](../../../JsonDAPtest/test/jsondap_file_tests.d#L68) |
| `APmergeJsonWithMessage` (`out` form) | [07](07-merge-and-copy.md) | [TextDAPSession.d:95](../../../JsonDAPtest/TextDAPSession.d#L95) | [jsondap_file_tests.d:173](../../../JsonDAPtest/test/jsondap_file_tests.d#L173) |
| `APmergeJsonWithMessage` (`string` form) | [07](07-merge-and-copy.md) | — | jsondap_file_tests.d |
| `APrecursiveMerge` | [07](07-merge-and-copy.md) | — | [jsondap_path_tests.d:130](../../../JsonDAPtest/test/jsondap_path_tests.d#L130) |
| `APrecursiveMergeCopy` | [07](07-merge-and-copy.md) | [TextDAPConvert.d:198](../../../JsonDAPtest/TextDAPConvert.d#L198) | [jsondap_path_tests.d:137](../../../JsonDAPtest/test/jsondap_path_tests.d#L137) |
| `APdeepCopy` | [07](07-merge-and-copy.md) | — | [jsondap_path_tests.d:144](../../../JsonDAPtest/test/jsondap_path_tests.d#L144) |

## SumType

| API | Chapter | App | Tests |
|---|---|---|---|
| `APserializeSumType!T` | [08](08-sumtype.md) | [TextDAPConvert.d:61](../../../JsonDAPtest/TextDAPConvert.d#L61) | [jsondap_tests.d:161](../../../JsonDAPtest/test/jsondap_tests.d#L161) |
| `APdeserializeSumType!T` | [08](08-sumtype.md) | [TextDAPConvert.d:64](../../../JsonDAPtest/TextDAPConvert.d#L64) | [jsondap_tests.d:163](../../../JsonDAPtest/test/jsondap_tests.d#L163) |
| `APdeserializeSumTypeFromString!T` | [08](08-sumtype.md) | — | — |
| `APserializeSumTypeWithHandlers!T` | [08](08-sumtype.md) | [TextDAPSession.d:147](../../../JsonDAPtest/TextDAPSession.d#L147) | [jsondap_tests.d:138](../../../JsonDAPtest/test/jsondap_tests.d#L138) |
| `APdeserializeSumTypeWithHandlers!T` | [08](08-sumtype.md) | [TextDAPSession.d:172](../../../JsonDAPtest/TextDAPSession.d#L172) | [jsondap_tests.d:146](../../../JsonDAPtest/test/jsondap_tests.d#L146) |

## Inspecting, guarding, digits

| API | Chapter | App | Tests |
|---|---|---|---|
| `APisValidJson` | [09](09-inspecting-and-guarding.md) | [TextDAPSession.d:42](../../../JsonDAPtest/TextDAPSession.d#L42) | [jsondap_api_tests.d:71](../../../JsonDAPtest/test/jsondap_api_tests.d#L71) |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | [09](09-inspecting-and-guarding.md) | [TextDAPJsonTools.d:232](../../../JsonDAPtest/TextDAPJsonTools.d#L232) | [jsondap_file_tests.d:91](../../../JsonDAPtest/test/jsondap_file_tests.d#L91) |
| `APgetJsonItemCount` | [09](09-inspecting-and-guarding.md) | [TextDAPJsonTools.d:27](../../../JsonDAPtest/TextDAPJsonTools.d#L27) | [jsondap_file_tests.d:93](../../../JsonDAPtest/test/jsondap_file_tests.d#L93) |
| `APprettyPrintJson` | [09](09-inspecting-and-guarding.md) | [TextDAPJsonTools.d:58](../../../JsonDAPtest/TextDAPJsonTools.d#L58) | — |
| `APisDigitAP` | [09](09-inspecting-and-guarding.md) | [TextDAPConvert.d:236](../../../JsonDAPtest/TextDAPConvert.d#L236) | [jsondap_file_tests.d:227](../../../JsonDAPtest/test/jsondap_file_tests.d#L227) |
| `APnormalizeDigitsAP` | [09](09-inspecting-and-guarding.md) | [TextDAPConvert.d:253](../../../JsonDAPtest/TextDAPConvert.d#L253) | [jsondap_file_tests.d:232](../../../JsonDAPtest/test/jsondap_file_tests.d#L232) |
| `APisInteger` | [09](09-inspecting-and-guarding.md) | [TextDAPConsole.d:67](../../../JsonDAPtest/TextDAPConsole.d#L67) | [jsondap_path_tests.d:151](../../../JsonDAPtest/test/jsondap_path_tests.d#L151) |
| `APisSignedInteger` | [09](09-inspecting-and-guarding.md) | [TextDAPConvert.d:247](../../../JsonDAPtest/TextDAPConvert.d#L247) | [jsondap_path_tests.d:155](../../../JsonDAPtest/test/jsondap_path_tests.d#L155) |
| `APisDecimal` | [09](09-inspecting-and-guarding.md) | [TextDAPConvert.d:248](../../../JsonDAPtest/TextDAPConvert.d#L248) | [jsondap_path_tests.d:157](../../../JsonDAPtest/test/jsondap_path_tests.d#L157) |
| `APstrIsNil` | [09](09-inspecting-and-guarding.md) | [TextDAPSession.d:22](../../../JsonDAPtest/TextDAPSession.d#L22) | [jsondap_file_tests.d:290](../../../JsonDAPtest/test/jsondap_file_tests.d#L290) |
| `APCheckStringIsNullArray` | [09](09-inspecting-and-guarding.md) | [TextDAPSession.d:123](../../../JsonDAPtest/TextDAPSession.d#L123) | — |
| `APStrIsNUll` *(deprecated)* | [09](09-inspecting-and-guarding.md) | — | — |

## What a reader who only has the app would miss

Three names are used by nothing but this tutorial: `APStrIsNUll` (kept as the deprecated alias),
`APdeserializeSumTypeFromString`, and the `string`-answering `APmergeJsonWithMessage` overload.
`APexists` is used only for folders ([TextDAPDocument.d:91](../../../JsonDAPtest/TextDAPDocument.d#L91)).

Nine are used by the tests but never by the app — the six non-message edit twins
(`APupdateJsonValueOBJECT`, `APupdateJsonValueARRAY`, `APaddJsonItemOBJECT`, `APaddJsonItemARRAY`,
`APremoveJsonItemOBJECT`, `APremoveJsonItemARRAY`), plus `APmergeJson`, `APrecursiveMerge` and
`APdeepCopy`. They are **not** dead code: a console program always wants the reason, a test only
wants the flag. Nothing here was removed on that basis.

Back to the [index](../../StartEn.md).
