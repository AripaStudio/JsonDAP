# ۰۲ — انواع و رفت‌وبرگشت

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۱](01-setup.md)

## نوعی که یک session ذخیره می‌کند

کلِ وضعیتِ یک session یک struct است. اول `DocumentRecord` را بخوانید — هر قانونِ پایین همین‌جا
دیده می‌شود
([TextDAPModel.d:35](../../../JsonDAPtest/TextDAPModel.d#L35)):

```d
public struct DocumentRecord
{
    @JsonName("file_path") string filePath;
    @JsonName("title") string title;
    @JsonName("open_count") int openCount;
    @JsonName("state") DocumentState state;      // enum -> روی سیم عدد صحیح
    @JsonName("note") Optional!string note;      // Optional خالی -> null
    @JsonIgnore string lookupKey;                // در حافظه ساخته می‌شود، هرگز نوشته نمی‌شود
}
```

`@JsonName` و `@JsonIgnore` تنها دو صفتی‌اند که کتابخانه می‌خواند. فیلد بدون صفت، نام D خودش را
نگه می‌دارد.

## بیرون، و بعد دوباره درون

همان رفت‌وبرگشتی که در هر ذخیره اجرا می‌شود
([TextDAPSession.d:91](../../../JsonDAPtest/TextDAPSession.d#L91)):

```d
JSONValue wire = JsonAP.APserializeToJson!SessionFile(session);      // struct -> JSONValue
auto back = JsonAP.APdeserializeJson!SessionFile(wire.toString());   // متن -> Optional!SessionFile

assert(back.get.schema == session.schema);
assert(back.get.documents.length == session.documents.length);
```

ترتیب `wire.toString()` از آرایهٔ انجمنیِ `std.json` می‌آید؛ پس هرگز متن تولیدشده را با متن
انتظار مقایسه نکنید — مقدارهای پارسه‌شده را مقایسه کنید.

| خط | چه کاری انجام می‌دهد |
|---|---|
| `APserializeToJson!T` | نویسندهٔ سطح‌بالا؛ `APserializeTToJsonValue!T` هم‌تای سطح‌پایینش است، با همان خروجی |
| `APdeserializeJson!T` | **سخت‌گیر**: هر فیلد باید حاضر باشد، وگرنه استثنا پرتاب می‌کند |
| `back.get` | خواننده پاسخ `Optional!T` می‌دهد؛ `.get` فقط بعد از بررسی `.isNull` قانونی است |

## قرارداد

| نوع D | روی سیم |
|---|---|
| `struct` / `class` | object |
| `T[]` | array |
| `enum` | عدد صحیح، و تنها یک **عضو معتبر** |
| `Optional!T` (= `Nullable!T`) | خالی که باشد `null` |
| مرجع کلاسِ `null` | `null` |
| `SumType` | `{"tag":"<عضو>","value":<payload>}` — ر.ک [۰۸](08-sumtype.md) |

## سخت‌گیر در برابر مداراگر

خواندن فایلی که شاید دستی ویرایش شده باشد، در حالت سخت‌گیر استثنا می‌دهد؛ مداراگر جاهای خالی را
پر می‌کند:

```d
string partial = `{"schema":"textdap.session.1"}`;

auto strict  = JsonAP.APdeserializeJson!SessionFile(partial);        // MissingField پرتاب می‌کند
auto lenient = JsonAP.APdeserializeJsonLenient!SessionFile(partial); // documents == []
```

| موقعیت | سخت‌گیر | مداراگر |
|---|---|---|
| فیلد غایب | `JSONConvertExceptionAP` با `MissingField` | مقدار پیش‌فرض را نگه می‌دارد |
| فیلد `Optional` / کلاسِ غایب | استثنا | خالی / `null` می‌ماند |
| مقدار `enum` ناشناخته | خطا | خطا — هرگز cast نمی‌شود |
| tag ناشناختهٔ `SumType` | خطا با فهرست tagها | خطا با فهرست tagها |

خودِ `load` فایلِ session را عمداً مداراگر می‌خواند:

```d
auto parsed = JsonAP.APdeserializeJsonLenient!SessionFile(text);
if (parsed.isNull)
{
    CL_TextDap_Console.sayFail("the session document read back as empty.");
    return Optional!SessionFile.init;
}
```

## رد شدن یک enum چه شکلی است

`DocumentState` عضوهای `saved=0`، `edited=1`، `missing=2` را دارد. به خواننده `"state":9` بدهید
تا به‌جای cast آن را رد کند — همین کاری که `enumGuardDemo` با گرفتنِ شکست و چاپِ هر فیلدِ آن
نشان می‌دهد:

```d
catch (JSONConvertExceptionAP caught)
{
    // field   caught.parameterName      // "state"
    // value   caught.invalidValue      // "9"
    // code    caught.jsonSpecificError // InvalidEnumMember
    // wanted  caught.reasonForFailure  // a valid DocumentState member
    return true;
}
```

```text
rejected enum
  field   state
  value   9
  code    InvalidEnumMember
  wanted  a valid DocumentState member
```

بعدی: [۰۳ — فایل‌ها و آرایه‌ها](03-files-and-arrays.md)