# ۱۱ — نقشه‌ی پوشش API

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۱۰](10-exceptions.md)

هر نامِ exportشده‌ی `AP…`، فصلی که آن را توضیح می‌دهد، و خطی که همین حالا از آن استفاده می‌کند. «—»
یعنی نه اپ و نه تست‌ها آن را صدا نمی‌زنند، پس مثالِ همین آموزش تنها نمایشِ آن است.
App = `JsonDAPtest/*.d`، Tests = `JsonDAPtest/test/*.d`.

## فایل‌ها

| API | فصل | App | Tests |
|---|---|---|---|
| `APreadJsonFile!T` | [۰۳](03-files-and-arrays.md) | [TextDAPSession.d:159](../../../JsonDAPtest/TextDAPSession.d#L159) | jsondap_api_tests.d:34, jsondap_file_tests.d:60 |
| `APwriteJsonFile!T` | [۰۳](03-files-and-arrays.md) | [TextDAPConvert.d:108](../../../JsonDAPtest/TextDAPConvert.d#L108) | jsondap_file_tests.d:20 |
| `APreadJsonArray!T` | [۰۳](03-files-and-arrays.md) | [TextDAPConvert.d:114](../../../JsonDAPtest/TextDAPConvert.d#L114) | [jsondap_file_tests.d:24](../../../JsonDAPtest/test/jsondap_file_tests.d#L24) |
| `APgetJsonFileSize` | [۰۳](03-files-and-arrays.md) | [TextDAPSession.d:191](../../../JsonDAPtest/TextDAPSession.d#L191) | [jsondap_file_tests.d:22](../../../JsonDAPtest/test/jsondap_file_tests.d#L22) |
| `APexistsFile` | [۰۳](03-files-and-arrays.md) | [TextDAPSession.d:30](../../../JsonDAPtest/TextDAPSession.d#L30) | [jsondap_file_tests.d:21](../../../JsonDAPtest/test/jsondap_file_tests.d#L21) |
| `APexists` | [۰۳](03-files-and-arrays.md) | [TextDAPDocument.d:91](../../../JsonDAPtest/TextDAPDocument.d#L91) | — |

## انواع و تبدیل

| API | فصل | App | Tests |
|---|---|---|---|
| `APserializeToJson!T` | [۰۲](02-types-and-the-round-trip.md) | [TextDAPSession.d:91](../../../JsonDAPtest/TextDAPSession.d#L91) | [jsondap_api_tests.d:57](../../../JsonDAPtest/test/jsondap_api_tests.d#L57) |
| `APserializeTToJsonValue!T` | [۰۲](02-types-and-the-round-trip.md) | [TextDAPConvert.d:22](../../../JsonDAPtest/TextDAPConvert.d#L22) | — |
| `APserializeToJsonArray!T` | [۰۳](03-files-and-arrays.md) | [TextDAPConvert.d:105](../../../JsonDAPtest/TextDAPConvert.d#L105) | — |
| `APdeserializeJson!T` | [۰۲](02-types-and-the-round-trip.md) | [TextDAPConvert.d:265](../../../JsonDAPtest/TextDAPConvert.d#L265) | [jsondap_api_tests.d:60](../../../JsonDAPtest/test/jsondap_api_tests.d#L60) |
| `APdeserializeJsonLenient!T` | [۰۲](02-types-and-the-round-trip.md) | [TextDAPSession.d:53](../../../JsonDAPtest/TextDAPSession.d#L53) | [jsondap_tests.d:59](../../../JsonDAPtest/test/jsondap_tests.d#L59) |
| `APdeserializeJsonArray!T` | [۰۳](03-files-and-arrays.md) | [TextDAPConvert.d:186](../../../JsonDAPtest/TextDAPConvert.d#L186) | [jsondap_file_tests.d:28](../../../JsonDAPtest/test/jsondap_file_tests.d#L28) |
| `APconvertJsonValueToT!T` | [۰۲](02-types-and-the-round-trip.md) | [TextDAPConvert.d:29](../../../JsonDAPtest/TextDAPConvert.d#L29) | [jsondap_tests.d:151](../../../JsonDAPtest/test/jsondap_tests.d#L151) |
| `APgetJsonValueType` | [۰۵](05-reading-a-value.md) | [TextDAPJsonTools.d:176](../../../JsonDAPtest/TextDAPJsonTools.d#L176) | jsondap_tests.d |
| `IsIntAP` … `IsNumberAP` (traits) | [۰۲](02-types-and-the-round-trip.md) | [TextDAPModel.d:232](../../../JsonDAPtest/TextDAPModel.d#L232) | jsondap_tests.d |

## مسیرها و خواندن

| API | فصل | App | Tests |
|---|---|---|---|
| `APJsonPathParser` | [۰۴](04-path-syntax.md) | [TextDAPJsonEdit.d:131](../../../JsonDAPtest/TextDAPJsonEdit.d#L131) | [jsondap_file_tests.d:80](../../../JsonDAPtest/test/jsondap_file_tests.d#L80) |
| `APgetJsonValue!V` | [۰۵](05-reading-a-value.md) | [TextDAPJsonTools.d:120](../../../JsonDAPtest/TextDAPJsonTools.d#L120) | [jsondap_file_tests.d:88](../../../JsonDAPtest/test/jsondap_file_tests.d#L88), [jsondap_path_tests.d:111](../../../JsonDAPtest/test/jsondap_path_tests.d#L111) |

## ویرایش یک فایل

| API | فصل | App | Tests |
|---|---|---|---|
| `APupdateJsonValueOBJECT!V` | [۰۶](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:56](../../../JsonDAPtest/test/jsondap_file_tests.d#L56) |
| `APupdateJsonValueARRAY!V` | [۰۶](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:32](../../../JsonDAPtest/test/jsondap_file_tests.d#L32) |
| `APaddJsonItemOBJECT!T` | [۰۶](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:57](../../../JsonDAPtest/test/jsondap_file_tests.d#L57) |
| `APaddJsonItemARRAY!T` | [۰۶](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:33](../../../JsonDAPtest/test/jsondap_file_tests.d#L33) |
| `APremoveJsonItemOBJECT` | [۰۶](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:64](../../../JsonDAPtest/test/jsondap_file_tests.d#L64) |
| `APremoveJsonItemARRAY` | [۰۶](06-editing-a-file-by-path.md) | — | [jsondap_file_tests.d:34](../../../JsonDAPtest/test/jsondap_file_tests.d#L34) |
| `APupdateJsonValueOBJECTWithMessage!V` | [۰۶](06-editing-a-file-by-path.md) | [TextDAPSession.d:135](../../../JsonDAPtest/TextDAPSession.d#L135) | [jsondap_file_tests.d:117](../../../JsonDAPtest/test/jsondap_file_tests.d#L117) |
| `APupdateJsonValueARRAYWithMessage!V` | [۰۶](06-editing-a-file-by-path.md) | [TextDAPScalar.d:203](../../../JsonDAPtest/TextDAPScalar.d#L203) | [jsondap_file_tests.d:157](../../../JsonDAPtest/test/jsondap_file_tests.d#L157) |
| `APaddJsonItemOBJECTWithMessage!T` | [۰۶](06-editing-a-file-by-path.md) | [TextDAPSession.d:129](../../../JsonDAPtest/TextDAPSession.d#L129) | [jsondap_file_tests.d:119](../../../JsonDAPtest/test/jsondap_file_tests.d#L119) |
| `APaddJsonItemARRAYWithMessage!T` | [۰۶](06-editing-a-file-by-path.md) | [TextDAPScalar.d:192](../../../JsonDAPtest/TextDAPScalar.d#L192) | [jsondap_path_tests.d:36](../../../JsonDAPtest/test/jsondap_path_tests.d#L36) |
| `APremoveJsonItemOBJECTWithMessage` | [۰۶](06-editing-a-file-by-path.md) | [TextDAPJsonEdit.d:71](../../../JsonDAPtest/TextDAPJsonEdit.d#L71) | [jsondap_file_tests.d:164](../../../JsonDAPtest/test/jsondap_file_tests.d#L164) |
| `APremoveJsonItemARRAYWithMessage` | [۰۶](06-editing-a-file-by-path.md) | [TextDAPJsonEdit.d:67](../../../JsonDAPtest/TextDAPJsonEdit.d#L67) | [jsondap_file_tests.d:121](../../../JsonDAPtest/test/jsondap_file_tests.d#L121) |
| `APEditMessages` | [۰۶](06-editing-a-file-by-path.md) | کلاس پایه‌ی `JsonAP` — هرگز نمونه‌سازی نمی‌شود | — |

## ادغام و کپی

| API | فصل | App | Tests |
|---|---|---|---|
| `APmergeJson` | [۰۷](07-merge-and-copy.md) | — | [jsondap_file_tests.d:68](../../../JsonDAPtest/test/jsondap_file_tests.d#L68) |
| `APmergeJsonWithMessage` (`out` form) | [۰۷](07-merge-and-copy.md) | [TextDAPSession.d:95](../../../JsonDAPtest/TextDAPSession.d#L95) | [jsondap_file_tests.d:173](../../../JsonDAPtest/test/jsondap_file_tests.d#L173) |
| `APmergeJsonWithMessage` (`string` form) | [۰۷](07-merge-and-copy.md) | — | jsondap_file_tests.d |
| `APrecursiveMerge` | [۰۷](07-merge-and-copy.md) | — | [jsondap_path_tests.d:130](../../../JsonDAPtest/test/jsondap_path_tests.d#L130) |
| `APrecursiveMergeCopy` | [۰۷](07-merge-and-copy.md) | [TextDAPConvert.d:198](../../../JsonDAPtest/TextDAPConvert.d#L198) | [jsondap_path_tests.d:137](../../../JsonDAPtest/test/jsondap_path_tests.d#L137) |
| `APdeepCopy` | [۰۷](07-merge-and-copy.md) | — | [jsondap_path_tests.d:144](../../../JsonDAPtest/test/jsondap_path_tests.d#L144) |

## SumType

| API | فصل | App | Tests |
|---|---|---|---|
| `APserializeSumType!T` | [۰۸](08-sumtype.md) | [TextDAPConvert.d:61](../../../JsonDAPtest/TextDAPConvert.d#L61) | [jsondap_tests.d:161](../../../JsonDAPtest/test/jsondap_tests.d#L161) |
| `APdeserializeSumType!T` | [۰۸](08-sumtype.md) | [TextDAPConvert.d:64](../../../JsonDAPtest/TextDAPConvert.d#L64) | [jsondap_tests.d:163](../../../JsonDAPtest/test/jsondap_tests.d#L163) |
| `APdeserializeSumTypeFromString!T` | [۰۸](08-sumtype.md) | — | — |
| `APserializeSumTypeWithHandlers!T` | [۰۸](08-sumtype.md) | [TextDAPSession.d:147](../../../JsonDAPtest/TextDAPSession.d#L147) | [jsondap_tests.d:138](../../../JsonDAPtest/test/jsondap_tests.d#L138) |
| `APdeserializeSumTypeWithHandlers!T` | [۰۸](08-sumtype.md) | [TextDAPSession.d:172](../../../JsonDAPtest/TextDAPSession.d#L172) | [jsondap_tests.d:146](../../../JsonDAPtest/test/jsondap_tests.d#L146) |

## بررسی، نگهبانی، رقم‌ها

| API | فصل | App | Tests |
|---|---|---|---|
| `APisValidJson` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPSession.d:42](../../../JsonDAPtest/TextDAPSession.d#L42) | [jsondap_api_tests.d:71](../../../JsonDAPtest/test/jsondap_api_tests.d#L71) |
| `APisJsonObject` / `APisJsonArray` / `APisJsonNumber` / `APisJsonString` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPJsonTools.d:232](../../../JsonDAPtest/TextDAPJsonTools.d#L232) | [jsondap_file_tests.d:91](../../../JsonDAPtest/test/jsondap_file_tests.d#L91) |
| `APgetJsonItemCount` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPJsonTools.d:27](../../../JsonDAPtest/TextDAPJsonTools.d#L27) | [jsondap_file_tests.d:93](../../../JsonDAPtest/test/jsondap_file_tests.d#L93) |
| `APprettyPrintJson` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPJsonTools.d:58](../../../JsonDAPtest/TextDAPJsonTools.d#L58) | — |
| `APisDigitAP` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPConvert.d:236](../../../JsonDAPtest/TextDAPConvert.d#L236) | [jsondap_file_tests.d:227](../../../JsonDAPtest/test/jsondap_file_tests.d#L227) |
| `APnormalizeDigitsAP` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPConvert.d:253](../../../JsonDAPtest/TextDAPConvert.d#L253) | [jsondap_file_tests.d:232](../../../JsonDAPtest/test/jsondap_file_tests.d#L232) |
| `APisInteger` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPConsole.d:67](../../../JsonDAPtest/TextDAPConsole.d#L67) | [jsondap_path_tests.d:151](../../../JsonDAPtest/test/jsondap_path_tests.d#L151) |
| `APisSignedInteger` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPConvert.d:247](../../../JsonDAPtest/TextDAPConvert.d#L247) | [jsondap_path_tests.d:155](../../../JsonDAPtest/test/jsondap_path_tests.d#L155) |
| `APisDecimal` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPConvert.d:248](../../../JsonDAPtest/TextDAPConvert.d#L248) | [jsondap_path_tests.d:157](../../../JsonDAPtest/test/jsondap_path_tests.d#L157) |
| `APstrIsNil` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPSession.d:22](../../../JsonDAPtest/TextDAPSession.d#L22) | [jsondap_file_tests.d:290](../../../JsonDAPtest/test/jsondap_file_tests.d#L290) |
| `APCheckStringIsNullArray` | [۰۹](09-inspecting-and-guarding.md) | [TextDAPSession.d:123](../../../JsonDAPtest/TextDAPSession.d#L123) | — |
| `APStrIsNUll` *(deprecated)* | [۰۹](09-inspecting-and-guarding.md) | — | — |

## چیزی که خواننده‌ای فقط با اپ نمی‌بیند

سه نام فقط همین آموزش استفاده‌شان می‌کند: `APStrIsNUll` (به‌عنوانِ نامِ مستعارِ deprecated نگه داشته
شده)، `APdeserializeSumTypeFromString`، و overloadِ `APmergeJsonWithMessage` که با `string` جواب
می‌دهد. `APexists` فقط برای پوشه‌ها به کار می‌رود
([TextDAPDocument.d:91](../../../JsonDAPtest/TextDAPDocument.d#L91)).

نه نام را تست‌ها استفاده می‌کنند ولی اپ هرگز — شش دوقلویِ بدون‌پیامِ ویرایش
(`APupdateJsonValueOBJECT`، `APupdateJsonValueARRAY`، `APaddJsonItemOBJECT`، `APaddJsonItemARRAY`،
`APremoveJsonItemOBJECT`، `APremoveJsonItemARRAY`)، به‌اضافه‌ی `APmergeJson`، `APrecursiveMerge` و
`APdeepCopy`. این‌ها کدِ مرده **نیستند**: یک برنامه‌ی کنسولی همیشه دلیل را می‌خواهد، یک تست فقط flag
را. هیچ‌چیز به این بهانه حذف نشده است.

بازگشت به [فهرست](../../StartPe.md).
