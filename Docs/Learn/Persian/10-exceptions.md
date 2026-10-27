# ۱۰ — استثناها

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۹](09-inspecting-and-guarding.md)

همه‌ی شکست‌هایی که کتابخانه پرتاب می‌کند از `BaseExceptionAP` مشتق می‌شوند
([ExceptionAP.d:7](../../../JsonDAP/ExceptionAP.d#L7))، و همه‌ی آن‌ها *با همان جایی که اتفاق افتاده‌اند*
پرتاب می‌شوند: سازنده‌ها `string file = __FILE__, size_t line = __LINE__` را می‌گیرند و آن را به
`Exception` منتقل می‌کنند.

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

## خواندنِ خطا به‌جای حدس‌زدنِ آن

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

| خط | چه کاری انجام می‌دهد |
|---|---|
| `classinfo.name` | نامِ کاملِ کلاس در زمان اجرا، به‌اضافه‌ی ماژول — ارزش چاپ‌کردن در یک گزارشِ باگ |
| `parameterName` | همان‌طور که در D اعلام شده نام‌گذاری می‌شود؛ نامِ روی سیم فقط در JSON است، نه اینجا |
| `jsonSpecificError` | یک کدِ پایدار (`MissingField`، `TypeMismatch`، `ObjectConversionFailed`)، نه متنِ آزاد |
| `file` / `line` | محلِ پرتاب. یک throw داخل `mixin(q{…})` به شکل `CoreAPPath.d-mixin-62:79` گزارش می‌شود |

## کدام استثنا برای کدام مشکل

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

## نردبانِ catch

ترتیب مهم است: اول کلاسِ مخصوصِ JSON، در آخر ریشه.

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

همان [TextDAPSession.d:71](../../../JsonDAPtest/TextDAPSession.d#L71) است. پوشاندنِ خطا در خودِ
کتابخانه هم همین نردبان است، فقط از سمتِ دیگر
([FileAP.d:52](../../../JsonDAP/FileAP.d#L52)):

```d
catch (BaseExceptionAP e) throw e;                                 // already ours: rethrow unchanged
catch (FileException   e) → FileOperationExceptionAP;              // Phobos → ours
catch (JSONException   e) → JsonOperationExceptionAP;
catch (Exception       e) → UnknownErrorExceptionAP;               // nothing escapes unnamed
```

## چه چیزی استثنا *نیست*

| کانال | چه کسی استفاده می‌کند |
|---|---|
| `bool` | نویسنده‌ها (writers)، متدهای ویرایش، predicateها |
| `bool` + `out string message` | دوقلوهای `…WithMessage` ([۰۶](06-editing-a-file-by-path.md)) |
| `Optional!T` | خواننده‌ها (readers) — و از 2.4.0 فقط برای «مقداری وجود ندارد»، هرگز برای «خطایی رخ داد» |

قاعده‌ای که باید برنامه‌تان را با آن بنویسید: **هر `false` از این کتابخانه یک دلیل دارد، و این
دوقلوی `WithMessage` است که آن را چاپ می‌کند.** از استثناها جایی استفاده کنید که یک شکستِ غیرمنتظره
باید دستور را متوقف کند؛ از دوقلوها جایی که مسیرِ بد، چیزِ عادی‌ای است که کاربر تایپ می‌کند.

بعدی: [۱۱ — نقشه‌ی پوشش API](11-api-coverage-map.md)
