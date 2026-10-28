# ۰۶ — ویرایش فایل با مسیر

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۵](05-reading-a-value.md)

شش متد، یک گره از فایل را جابه‌جا می‌کنند؛ شش دوقلویشان همان کار را می‌کنند و وقتی `false`
برگردانند **چرا** را هم می‌گویند. دوتایی که بیشتر لازم می‌شوند `add` و `update`‌اند — این هم یک
ذخیرهٔ واقعی که هر دو را با هم به کار می‌گیرد.

## ساختن یک ذخیره روی یک دوقلو

`writeValue` اول add می‌زند، بعد update — «ایجاد یا جایگزینی» در دو فراخوانی
([TextDAPSession.d:114](../../../JsonDAPtest/TextDAPSession.d#L114)):

```d
public static bool writeValue(V)(string filePath, string jsonPath, V value, out string message)
{
    message = "";

    string[] blankInputs = [filePath, jsonPath];
    if (JsonAP.APCheckStringIsNullArray(blankInputs))
    {
        message = "the session path and the file path must both hold text.";
        return false;
    }

    bool added = JsonAP.APaddJsonItemOBJECTWithMessage!V(filePath, jsonPath, value, message);
    if (added)
    {
        return true;                  // نبود: اضافه شد
    }

    return JsonAP.APupdateJsonValueOBJECTWithMessage!V(filePath, jsonPath, value, message);
}
```

| خط | چه می‌کند |
|---|---|
| `APCheckStringIsNullArray` | یک گارد برای هر دو ورودی، پیش از دست زدن به فایل |
| اول `add` | اگر کلید تازه باشد ساخته می‌شود — نیازی به پیش‌خواندن نیست |
| بعد `update` | اگر از قبل بوده، `add` همین را گفته؛ `message` حالا دلیل واقعی را دارد |

گزینه‌ها، مکان‌نما و هر فیلدِ سند واقعاً از همین یک تابع می‌گذرند — تابعِ سند فقط اول مسیر را
می‌سازد:

```d
public static bool writeDocumentValue(V)(string filePath, int index, string memberPath,
        V value, out string message)
{
    return writeValue(filePath, CL_TextDap_History.documentPath(index) ~ "." ~ memberPath,
            value, message);
}
```

## انتخاب OBJECT یا ARRAY از روی مسیر

خودِ مسیر می‌گوید کدام خانواده لازم است — **گام آخر** تصمیم می‌گیرد (ر.ک [۰۴](04-path-syntax.md)
و `itemShape` در [TextDAPJsonEdit.d:113](../../../JsonDAPtest/TextDAPJsonEdit.d#L113)):

```d
return Optional!bool(steps[$ - 1].type == PathStepType.ArrayIndex);
```

`true` → خانوادهٔ `…ARRAY…`، `false` → خانوادهٔ `…OBJECT…`.

## آن شش تا چه می‌کنند

| متد | قرارداد |
|---|---|
| `APupdateJsonValueOBJECT!V(path, key, value)` | کلید باید وجود داشته باشد؛ `V` نوعِ مقدار است |
| `APaddJsonItemOBJECT!T(path, key, value)` | کلید باید وجود **نداشته** باشد، وگرنه `false` |
| `APremoveJsonItemOBJECT(path, key)` | یک کلید تودرتو یا سطح‌بالا را حذف می‌کند |
| `APupdateJsonValueARRAY!V(path, index, value)` | عنصرِ در آن index را جایگزین می‌کند |
| `APaddJsonItemARRAY!T(path, index, value)` | **درج در** آن index؛ `index == length` یعنی الحاق |
| `APremoveJsonItemARRAY(path, index)` | عنصرِ در آن index را حذف می‌کند |

اگر یک **کلید شیء** میانی نبود، در مسیر ساخته می‌شود. اگر یک **index آرایه** میانی نبود، ساخته
نمی‌شود — چیزی نیست که گسترش پیدا کند.

```d
assert(JsonAP.APaddJsonItemOBJECTWithMessage!int(path, "limits.rows", 50, message));
// "limits" در همین مسیر ساخته می‌شود → {"limits":{"rows":50}, …}

assert(JsonAP.APupdateJsonValueARRAYWithMessage!int(path, "[1].y", 99, message));
// [{…,"y":1},{…,"y":2}] → yِ عنصر دوم می‌شود 99
```

ایندکس منفی رد می‌شود (`items[-1]`)، و به‌روزرسانیِ ایندکسی که نیست هم رد می‌شود — جایگزین‌کردنِ
هیچ، جایگزینی حساب نمی‌شود.

## چرا `false` برگرداند

هر متدِ بالا یک دوقلو با `out string message` دارد. این دوقلوها **هرگز throw نمی‌کنند**:
فایلِ نبود، سندِ خراب، مسیرِ نامناسب — همه به شکل `false` به‌همراه یک جمله برمی‌گردند. `message`
در ابتدای هر فراخوانی پاک می‌شود، پس یک متغیر برای استفادهٔ دوباره بی‌خطر است — دقیقاً همان‌طور
که `writeValue` استفاده می‌کند.

```d
string message;

if (!JsonAP.APaddJsonItemOBJECTWithMessage!int(path, "max_history", 99, message))
{
    writeln(message);
    // the key 'max_history' already exists; use APupdateJsonValueOBJECT.
}

if (!JsonAP.APupdateJsonValueOBJECTWithMessage!int(path, "settings.retry", 3, message))
{
    writeln(message);
    // the path 'settings.retry' does not exist: key 'settings' is missing.
}

if (!JsonAP.APaddJsonItemARRAYWithMessage!Point(arrayPath, "[9]", Point(0, 0), message))
{
    writeln(message);
    // array index 9 is out of range (length 2); nothing was changed.
}
```

## دو خانواده در کنار هم

| ساده (`bool`) | دوقلو (`bool` + `message`) |
|---|---|
| `APupdateJsonValueOBJECT` | `APupdateJsonValueOBJECTWithMessage` |
| `APupdateJsonValueARRAY` | `APupdateJsonValueARRAYWithMessage` |
| `APaddJsonItemOBJECT` | `APaddJsonItemOBJECTWithMessage` |
| `APaddJsonItemARRAY` | `APaddJsonItemARRAYWithMessage` |
| `APremoveJsonItemOBJECT` | `APremoveJsonItemOBJECTWithMessage` |
| `APremoveJsonItemARRAY` | `APremoveJsonItemARRAYWithMessage` |

خودِ TextDAP همیشه دوقلو را انتخاب می‌کند — در هر شکستی دلیل را می‌خواهد. نسخه‌های ساده برای
همان لحظه‌ای‌اند که فقط موفقیت اهمیت دارد، مثلاً یک تست که صرفاً انجام شدنِ ویرایش را assert
می‌کند:

```d
assert(JsonAP.APupdateJsonValueARRAY!int(path, "[1].y", 99));
assert(JsonAP.APaddJsonItemARRAY!Point(path, "[2]", Point(7, 8)));
assert(JsonAP.APremoveJsonItemARRAY(path, "[0]"));

assert(JsonAP.APupdateJsonValueOBJECT!string(path, "text", "after"));
assert(JsonAP.APaddJsonItemOBJECT!int(path, "extra.count", 5));
assert(JsonAP.APremoveJsonItemOBJECT(path, "extra.count"));
```

هر دو خانواده را نگه دارید: هیچ‌کدام جانشین دیگری نمی‌شود.

بعدی: [۰۷ — ادغام و کپی](07-merge-and-copy.md)