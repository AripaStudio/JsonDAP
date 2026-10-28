# ۰۵ — خواندن یک مقدار

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۴](04-path-syntax.md)

## خواندن چهار نوع

`readValueAt` نوع را از انتخاب کاربر برمی‌دارد و در یک فراخوانی مقدار را می‌خواند
([TextDAPJsonTools.d:114](../../../JsonDAPtest/TextDAPJsonTools.d#L114)):

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
if (kind == scalarKindNumber)
{
    reportValue(JsonAP.APgetJsonValue!double(text, dotPath), dotPath);
    return true;
}
if (kind == scalarKindFlag)
{
    reportValue(JsonAP.APgetJsonValue!bool(text, dotPath), dotPath);
    return true;
}
```

خواننده `Optional!V` برمی‌گرداند — خالی یعنی چیزی پیدا نشد، و گزارش همان را می‌گوید:

```d
private static void reportValue(V)(Optional!V found, string dotPath)
{
    if (found.isNull)
    {
        CL_TextDap_Console.sayFail(format!"'%s' holds no %s value."(dotPath, V.stringof));
        return;
    }

    CL_TextDap_Console.sayDone(format!"%s = %s"(dotPath, to!string(found.get)));
}
```

کلِ ماجرا داخلِ یک `catch` نشسته، پس مسیرِ غلط به یک خطِ چاپی تبدیل می‌شود نه به یک stack
trace:

```d
catch (BaseExceptionAP caught)
{
    CL_TextDap_Console.sayFail(caught.msg);
    return false;
}
```

## هر نوع چه چیزی را می‌پذیرد

| `V` خواسته‌شده | گرهٔ پذیرفته‌شده | ردشده |
|---|---|---|
| `string` | `STRING` | هر چیز دیگر |
| `long`, `int` | `INTEGER` | `FLOAT` — هیچ truncate بی‌سر‌وصدایی نیست |
| `double`, `float` | `FLOAT` **یا** `INTEGER` | رشته، بولین، شیء |
| `bool` | `TRUE` / `FALSE` | `0` / `1` صحیح‌اند نه بولین |

آن `V` نوعِ **خواسته‌شده** است، نه نوعِ گره. ناهمخوانی `ConvertExceptionAP` با `inputType` و
`outputType` پرتاب می‌کند — مقدار هرگز بی‌سر‌وصدا cast نمی‌شود.

```d
//
// Result of APgetJsonValue!double on {"items":[10,20,30]} "items[1]":  20.0
// گرهِ INTEGER برای درخواستِ اعشاری پذیرفته می‌شود — ر.ک jsondap_path_tests.d:115
//
```

## پاسخ خالی، دقیقاً یک حالت

```d
assert(JsonAP.APgetJsonValue!string("", "a.b").isNull);   // متن خالی
assert(JsonAP.APgetJsonValue!string(text, "").isNull);    // مسیر خالی
```

هر چیز دیگری یا مقداری برمی‌گرداند یا استثنا پرتاب می‌کند. پس `isNull` هرگز معنایش «چیزی خراب
شد» نیست — خطای واقعی همیشه یک استثنای قابل‌گرفتن است.

## چه چیزی استثنا می‌دهد

| چه خراب است | استثنا |
|---|---|
| متن JSON نیست | `JsonOperationExceptionAP` |
| کلیدی در مسیر غایب است | `JSONExceptionAP` با `jsonPath` و `jsonSnippet` |
| ایندکس روی چیزی غیر از array | `JSONExceptionAP` |
| ایندکس پس از پایان آرایه | `InvalidArgumentExceptionAP` با `expectedFormatOrRange` |
| نوع گره اشتباه است | `ConvertExceptionAP` با `inputType` و `outputType` |
| خودِ مسیر بدشکل است | `InvalidArgumentExceptionAP` — ر.ک [۰۴](04-path-syntax.md) |

## خواندنِ شکل یک سند

برای دیدن کلیدها و نوع مقادیر به‌جای تبدیلِ یک گره، فایل را به‌صورت `JSONValue` بخوانید و رویش
طری کنید — `inspectRoot` همین کار را می‌کند و هر کلید را با نوعش فهرست می‌کند
([TextDAPJsonTools.d:166](../../../JsonDAPtest/TextDAPJsonTools.d#L166)):

```d
auto read = JsonAP.APreadJsonFile!JSONValue(filePath);
if (read.get.type != JSONType.OBJECT)
{
    // "the root is <type>, so there are no member names to list."
    return true;
}

foreach (key; read.get.object.byKey.array)
{
    // key -> JsonAP.APgetJsonValueType(read.get.object[key])   INTEGER, OBJECT, ARRAY…
}
```

بعدی: [۰۶ — ویرایش یک فایل با مسیر](06-editing-a-file-by-path.md)