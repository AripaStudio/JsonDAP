# ۱۰ — استثناها

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۹](09-inspecting-and-guarding.md)

هر شکستی که کتابخانه پرتاب می‌کند از `BaseExceptionAP` مشتق می‌شود و همه‌شان جایی را که اتفاق
افتاده‌اند می‌شناسند — سازنده‌ها `string file = __FILE__, size_t line = __LINE__` را می‌گیرند و
آن را به `Exception` منتقل می‌کنند.

## درخت

```text
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
try
{
    JsonAP.APdeserializeJson!Options(`{"autosave":true}`);     // tab_width غایب است
}
catch (JSONConvertExceptionAP caught)
{
    caught.classinfo.name;      // ExceptionJsonAP.JSONConvertExceptionAP
    caught.parameterName;       // tabWidth (فیلدِ D، نه "tab_width")
    caught.invalidValue;        // Not Found
    caught.jsonSpecificError;   // MissingField
    caught.reasonForFailure;    // Mandatory field missing for object conversion.
    caught.outputType;          // int
    caught.file;                // فایل سورسی که آنجا پرتاب شد
    caught.line;                // و خطِ آن
}
```

| خط | چه کاری انجام می‌دهد |
|---|---|
| `classinfo.name` | نامِ کلاسِ زمانِ اجرا به‌همراه ماژول — ارزش چاپ در یک گزارشِ باگ |
| `parameterName` | همان‌طور که در D اعلام شده؛ نامِ روی سیم فقط در JSON است |
| `jsonSpecificError` | کدِ پایدار (`MissingField`، `TypeMismatch`…) نه متنِ آزاد |
| `file` / `line` | محلِ پرتاب — اول کجا را نگاه کنید |

## کدام استثنا برای کدام مشکل

```d
try { JsonAP.APreadJsonFile!Point(path); }
catch (FileOperationExceptionAP e) { e.filePath; e.operationType; }   // …json، "read"

try { JsonAP.APgetJsonValue!string(text, "settings.nope"); }
catch (JSONExceptionAP e) { e.jsonPath; e.jsonSnippet; }              // مسیر و سند

try { JsonAP.APJsonPathParser("items[abc]"); }
catch (InvalidArgumentExceptionAP e) { e.expectedFormatOrRange; }     // "0, 1, 2, …"

try { JsonAP.APgetJsonValue!int(text, "options.session_title"); }
catch (ConvertExceptionAP e) { e.inputType; e.outputType; }           // STRING -> int
```

## نردبانِ catch: دو پله

اول خاص‌ترین، آخر ریشه
([TextDAPSession.d:71](../../../JsonDAPtest/TextDAPSession.d#L71)):

```d
try
{
    auto parsed = JsonAP.APdeserializeJsonLenient!SessionFile(text);
    // … استفاده از parsed.get
}
catch (JSONExceptionAP caught)          // هر چیزی که لایهٔ JSON می‌شناسد
{
    CL_TextDap_Console.sayFail(caught.msg);
    return Optional!SessionFile.init;
}
catch (BaseExceptionAP caught)          // هر شکستِ دیگرِ کتابخانه
{
    CL_TextDap_Console.sayFail(caught.msg);
    return Optional!SessionFile.init;
}
```

معمولاً دو پله کافی است: اول مشکلات JSON، بعد بقیه، و هر دو با انتها رسیدن بهِ پرینترِ پیامِ
خودتان.

در پشتِ صحنه، خودِ کتابخانه استثناهای Phobos را به همین شکل می‌پوشاند، پس چیزِ بیگانه‌ای تقریباً
به `catch` شما نمی‌رسد:

```d
catch (BaseExceptionAP e) throw e;             // از قبل مالِ ماست: بی‌تغییر دوباره پرتاب
catch (FileException   e) → FileOperationExceptionAP;
catch (JSONException   e) → JsonOperationExceptionAP;
catch (Exception       e) → UnknownErrorExceptionAP;   // هیچ‌چیز بی‌نام فرار نمی‌کند
```

## چه چیزی استثنا *نیست*

| کانال | چه کسی استفاده می‌کند |
|---|---|
| `bool` | نویسنده‌ها، متدهای ویرایش، predicateها |
| `bool` + `out string message` | دوقلوهای `…WithMessage` ([۰۶](06-editing-a-file-by-path.md)) |
| `Optional!T` | خواننده‌ها — فقط برای «مقداری نیست»، هرگز برای «خطایی رخ داد» |

قاعده‌ای که باید برنامه‌تان را با آن بنویسید: **هر `false` از این کتابخانه یک دلیل دارد، و این
دوقلوی `WithMessage` است که آن را چاپ می‌کند.** از استثناها جایی استفاده کنید که یک شکستِ
غیرمنتظره باید دستور را متوقف کند؛ از دوقلوها جایی که مسیرِ بد، چیزِ عادی‌ای است که کاربر
تایپ می‌کند.

بعدی: [۱۱ — نقشه‌ی پوشش API](11-api-coverage-map.md)