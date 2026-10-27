# ۰۶ — ویرایش فایل با مسیر

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۵](05-reading-a-value.md)

هر یک از این فراخوانی‌ها فایل را می‌خواند، یک گره را عوض می‌کند، فایل را دوباره می‌نویسد و در پاسخ
`bool` می‌دهد. در برابر مسیر بد، هیچ‌چیز به سمت شما پرتاب نمی‌شود — فقط `false` می‌گیرید، و
دوقلوی `…WithMessage` دلیلش را می‌گوید.

```d
string path = /* a file holding {"autosave":false,"tab_width":4} */;

assert(JsonAP.APupdateJsonValueOBJECT!bool(path, "autosave", true));    // replace an existing key
assert(JsonAP.APaddJsonItemOBJECT!int(path, "max_history", 12));        // add a key that is not there
assert(JsonAP.APaddJsonItemOBJECT!int(path, "limits.rows", 50));        // creates "limits" on the way
assert(JsonAP.APremoveJsonItemOBJECT(path, "max_history"));             // removes a key
```

پس از آن چهار فراخوانی فایل `{"autosave":true,"limits":{"rows":50},"tab_width":4}` است؛ حذفِ بالا
`{"autosave":true,"limits":{},"tab_width":4}` را باقی می‌گذارد — یک شیء خالی سر جایش می‌ماند، چون
فقط همان گره‌ای که نامش آمده بود حذف شده است.

| متد | قرارداد |
|---|---|
| `APupdateJsonValueOBJECT!V` | کلید باید وجود داشته باشد؛ `V` نوعِ مقدار است |
| `APaddJsonItemOBJECT!T` | کلید باید وجود **نداشته** باشد، وگرنه `false` |
| `APremoveJsonItemOBJECT` | یک کلید تودرتو یا یک کلید سطح‌بالا را حذف می‌کند |
| `APupdateJsonValueARRAY!V` | عنصرِ موجود در آن index را جایگزین می‌کند |
| `APaddJsonItemARRAY!T` | **در** آن index درج می‌کند؛ `index == length` همان محل افزودن به انتهاست |
| `APremoveJsonItemARRAY` | عنصرِ موجود در آن index را حذف می‌کند |

اگر یک **کلید شیء** میانی وجود نداشته باشد، ساخته می‌شود. اگر یک **index آرایه** میانی وجود
نداشته باشد، ساخته نمی‌شود.

```d
string arrayPath = /* a file holding [{"x":1,"y":1},{"x":2,"y":2}] */;

assert(JsonAP.APupdateJsonValueARRAY!int(arrayPath, "[1].y", 99));        // [{"x":1,"y":1},{"x":2,"y":99}]
assert(JsonAP.APaddJsonItemARRAY!Point(arrayPath, "[2]", Point(7, 8)));   // append at length
// [{"x":1,"y":1},{"x":2,"y":99},{"x":7,"y":8}]
assert(JsonAP.APremoveJsonItemARRAY(arrayPath, "[0]"));                   // [{"x":2,"y":99},{"x":7,"y":8}]
```

شماره‌ی index‌ها از ریشه‌ی فایل شروع می‌شود، پس `"[1].y"` یعنی *`y`ِ عنصر دوم*. راهی نیست که
بدون براکتِ ابتدایی بگوییم «یک عنصر از آرایه‌ی ریشه»، و `APupdateJsonValueARRAY` indexِ
وجودنداشته را قبول نمی‌کند — به‌روزرسانیِ عنصری که وجود ندارد، جایگزینی حساب نمی‌شود.

## چرا `false` برگشت

هر متدِ بالا یک دوقلو با `out string message` دارد
([JsonAPMessages.d:13](../../../JsonDAP/JsonAPMessages.d#L13)). این دوقلوها **هرگز throw نمی‌کنند**:
فایلِ نبود، سندِ خراب، مسیرِ به‌دردنخور — همه‌شان به شکل `false` به‌اضافه یک جمله برمی‌گردند.

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

assert(JsonAP.APremoveJsonItemOBJECTWithMessage(path, "limits.rows", message));

if (!JsonAP.APaddJsonItemARRAYWithMessage!Point(arrayPath, "[9]", Point(0, 0), message))
{
    writeln(message);
    // array index 9 is out of range (length 2); nothing was changed.
}
```

`message` در ابتدای هر فراخوانی پاک می‌شود، پس یک متغیر برای استفاده‌ی دوباره بی‌خطر است — و
[TextDAPSession.d:118](../../../JsonDAPtest/TextDAPSession.d#L118) دقیقاً همین را می‌خواهد:

```d
bool added = JsonAP.APaddJsonItemOBJECTWithMessage!V(filePath, jsonPath, value, message);
if (added)
{
    return true;                                  // the key did not exist: it is new
}

return JsonAP.APupdateJsonValueOBJECTWithMessage!V(filePath, jsonPath, value, message);
```

| خط | چه کاری انجام می‌دهد |
|---|---|
| اول `add` | ارزان‌ترین راه برای گفتنِ «ایجاد یا جایگزینی» بدون خواندنِ فایل |
| `if (added) return true` | همان‌جا برمی‌گردد، تا update هرگز `message` را بازنویسی نکند |
| فراخوانی دوم | همان متغیر `message`، از داخل بازنویسی می‌شود |

همان تابع `writeValue` است — تنها مسیرِ نوشتن در کل اپ. گزینه‌ها، مکان‌نما (cursor)، فایل جاری و
هر فیلدِ سند از آن رد می‌شوند
([TextDAPSession.d:138](../../../JsonDAPtest/TextDAPSession.d#L138) قبل از فراخوانی، indexِ سند را به
مسیر اضافه می‌کند).

## دو خانواده در کنار هم

| نسخه‌ی ساده (تست‌ها استفاده می‌کنند) | دوقلوی پیام‌دار (اپ استفاده می‌کند) |
|---|---|
| `APupdateJsonValueOBJECT` | `APupdateJsonValueOBJECTWithMessage` |
| `APupdateJsonValueARRAY` | `APupdateJsonValueARRAYWithMessage` |
| `APaddJsonItemOBJECT` | `APaddJsonItemOBJECTWithMessage` |
| `APaddJsonItemARRAY` | `APaddJsonItemARRAYWithMessage` |
| `APremoveJsonItemOBJECT` | `APremoveJsonItemOBJECTWithMessage` |
| `APremoveJsonItemARRAY` | `APremoveJsonItemARRAYWithMessage` |

نسخه‌های ساده `bool` برمی‌گردانند و درباره‌ی دلیل ساکت می‌مانند؛ تست‌ها همان‌ها را استفاده می‌کنند، چون
آنجا یک assertion روی `false` کافی است
([jsondap_file_tests.d:32](../../../JsonDAPtest/test/jsondap_file_tests.d#L32)،
[:56](../../../JsonDAPtest/test/jsondap_file_tests.d#L56)). هر دو دوقلو را نگه دارید — هیچ‌کدام جانشین
دیگری نمی‌شود.

بعدی: [۰۷ — ادغام و کپی](07-merge-and-copy.md)
