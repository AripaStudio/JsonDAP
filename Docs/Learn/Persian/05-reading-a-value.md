# ۰۵ — خواندن یک مقدار

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۴](04-path-syntax.md)

`APgetJsonValue!V(string jsonContent, string path)` یک مسیر را طی می‌کند و **گره‌ای که رویش
می‌نشیند** را به `V` تبدیل می‌کند. این متد متن را می‌خواند نه فایل را — اول فایل را به رشته بدهید،
یا از `APreadJsonFile` استفاده کنید ([۰۳](03-files-and-arrays.md)).

```d
string text = `{"settings":{"retry":7,"ratio":1.5,"label":"Aripa","on":true},`
        ~ `"rows":[{"name":"first"},{"name":"second"}]}`;

assert(JsonAP.APgetJsonValue!long(text, "settings.retry") == 7);
assert(JsonAP.APgetJsonValue!int(text, "settings.retry") == 7);
assert(JsonAP.APgetJsonValue!double(text, "settings.ratio") == 1.5);
assert(JsonAP.APgetJsonValue!double(text, "settings.retry") == 7.0);    // an integer node is a number
assert(JsonAP.APgetJsonValue!string(text, "settings.label") == "Aripa");
assert(JsonAP.APgetJsonValue!bool(text, "settings.on") == true);
assert(JsonAP.APgetJsonValue!string(text, "rows[1].name") == "second");
```

| `V` | چه گره‌ای را می‌پذیرد | چه چیزی را رد می‌کند |
|---|---|---|
| `string` | `STRING` | هر چیز دیگر |
| `int`, `long` | `INTEGER` | `FLOAT` — هیچ truncate بی‌سر‌وصدایی در کار نیست |
| `float`, `double` | `FLOAT` **یا** `INTEGER` | رشته، bool، object |
| `bool` | `TRUE` / `FALSE` | `0` / `1` صحیح‌اند نه بولین |

آن `V` نوع **خواسته** است، نه نوعِ گره. ناهمخوانی خطاست، هرگز تبدیل (cast) نیست:

```d
try
{
    JsonAP.APgetJsonValue!int(text, "settings.ratio");      // 1.5 read as int
}
catch (ConvertExceptionAP caught)
{
    caught.msg;     // JSON value is not an integer.
    caught.inputType;    // FLOAT
}
```

## پاسخ خالی، دقیقاً یک حالت

```d
assert(JsonAP.APgetJsonValue!string("", "a.b").isNull);     // empty text
assert(JsonAP.APgetJsonValue!string(text, "").isNull);      // empty path
```

هر چیز دیگر یا مقداری برمی‌گرداند یا استثنا پرتاب می‌کند. از 2.4.0 این getter آنچه کتابخانه پرتاب
کرده بود را دوباره **پرتاب می‌کند** (rethrow) و دیگر آن را در یک `Optional` خالی قورت نمی‌دهد، پس
`isNull` دیگر معنایش «چیزی اشتباه شد» نیست.

| چه چیزی خراب است | استثنا | پیامی که می‌گیرید |
|---|---|---|
| متن اصلاً JSON نیست | `JsonOperationExceptionAP` | `Error parsing JSON while getting value.` |
| یکی از کلیدهای سر راه غایب است | `JSONExceptionAP` | `JSON path invalid: key 'nope' not found.` |
| یک ایندکس روی چیزی غیر از array به‌کار رفته | `JSONExceptionAP` | `JSON path invalid: index used on a non-array.` |
| ایندکس فراتر از پایان آرایه | `InvalidArgumentExceptionAP` | `JSON array index out of bounds.` به‌همراه `expectedFormatOrRange` |
| گره نوعش اشتباه است | `ConvertExceptionAP` | `JSON value is not an integer.` و هم‌خانواده‌هایش |
| خودِ مسیر بدشکل است | `InvalidArgumentExceptionAP` | رد کردنِ خودِ پارسر، ر.ک [۰۴](04-path-syntax.md) |

## خواندن چهار گونه، آن‌طور که یک اپ انجامش می‌دهد

[TextDAPJsonTools.d:108](../../../JsonDAPtest/TextDAPJsonTools.d#L108) مسیر و گونه را از کاربر
می‌گیرد، و آن چهار `V` چهار شاخه‌اند:

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
// … double, bool
```

```d
private static void reportValue(V)(Optional!V found, string dotPath)
{
    if (found.isNull)                                   // only reachable for empty text/path
    {
        CL_TextDap_Console.sayFail(format!"'%s' holds no %s value."(dotPath, V.stringof));
        return;
    }

    CL_TextDap_Console.sayDone(format!"%s = %s"(dotPath, to!string(found.get)));
}
```

همان `catch (BaseExceptionAP caught)` که دور تمام ماجرا پیچیده شده
([:142](../../../JsonDAPtest/TextDAPJsonTools.d#L142)) است که یک مسیر غلط را به یک خط چاپی تبدیل
می‌کند، نه به یک stack trace.

## خواندن یک گرهٔ کامل به‌جای یک اسکالر

`APgetJsonValue` تبدیل می‌کند، پس نمی‌تواند یک object یا یک array به شما بدهد. برای آن کار فایل را
به‌صورت `JSONValue` بخوانید و رویش ایندکس بزنید:

```d
JSONValue root = JsonAP.APreadJsonFile!JSONValue(path).get;

foreach (key; root.object.byKey)
{
    writeln(key, " is a ", JsonAP.APgetJsonValueType(root.object[key]));   // INTEGER, OBJECT, ARRAY…
}
```

این همان [TextDAPJsonTools.d:162](../../../JsonDAPtest/TextDAPJsonTools.d#L162) است — `inspectRoot`.

بعدی: [۰۶ — ویرایش یک فایل با مسیر](06-editing-a-file-by-path.md)
