# ۰۸ — سام‌تایپ (SumType)

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۷](07-merge-and-copy.md)

یک `SumType` **یکی** از اعضایش را نگه می‌دارد، و JSON باید بگوید کدام‌شان است. پاکت (envelope)
این شکلی است:

```json
{"tag":"line","value":42}
```

## دو فراخوانی‌ای که واقعاً استفاده می‌کنید

```d
alias CursorTarget = SumType!(int, string);

// نوشتن — تگ پیش‌فرض نامِ نوعِ عضو است
JSONValue wire = JsonAP.APserializeSumType!CursorTarget(CursorTarget(42));
// {"tag":"int","value":42}

// خواندن
auto back = JsonAP.APdeserializeSumType!CursorTarget(wire, false);
assert(back.get.get!int == 42);
```

تگِ ناشناخته در پاکت، همراه با فهرستِ تگ‌های موجود رد می‌شود — نه پیش‌فرضِ بی‌صدا، نه مقدارِ خالی:

```d
catch (BaseExceptionAP caught)
{
    caught.msg;   // Unknown tag in SumType envelope.  (تگ‌های موجود فهرست می‌شوند)
}
```

## اسم‌گذاری تگ‌ها به سبک خودتان

تگ‌های پیش‌فرض نامِ نوع‌های D هستند (`"int"`، `"string"`). به هر دو جهت **همان** تابع را بدهید تا
فایل‌تان نام‌های ثابت بگیرد. `cursorTagName` عضو ↔ تگ را نگاشت می‌کند
([TextDAPModel.d:163](../../../JsonDAPtest/TextDAPModel.d#L163)):

```d
string cursorTagName(string memberName)
{
    if (memberName == "int")    return CursorTag.line;    // "line"
    if (memberName == "string") return CursorTag.search;  // "search"
    return memberName;
}

JSONValue wire = JsonAP.APserializeSumType!CursorTarget(target,
        (string memberName) => cursorTagName(memberName));

auto back = JsonAP.APdeserializeSumType!CursorTarget(wire, false,
        (string memberName) => cursorTagName(memberName));
```

حالا فایل `{"tag":"line","value":42}` می‌شود، نه `{"tag":"int",…}`.

| خط | چه کاری انجام می‌دهد |
|---|---|
| delegate در نوشتن | نامِ عضو ← تگ، پیش از نوشتن payload |
| `false` در خواندن | همان فلگ `lenient` که هر خواننده‌ای دارد |
| delegate در خواندن | تگ ← نامِ عضو، تا خواننده بداند کدام عضو را بسازد |
| همان تابع در هر دو طرف | تنها راهِ هماهنگ ماندنِ دو جهت |

`cursorRoundTrip` خودِ TextDAP دقیقاً همین جفت را در هر رفت‌وبرگشت اجرا می‌کند:

```d
JSONValue envelope = JsonAP.APserializeSumType!CursorTarget(target,
        (string memberName) => cursorTagName(memberName));

Optional!CursorTarget readBack = JsonAP.APdeserializeSumType!CursorTarget(envelope,
        false, (string memberName) => cursorTagName(memberName));
```

## وقتی خودِ مقدار تگ را تعیین می‌کند

`…WithHandlers` به‌جای نامِ عضو، **کلِ مقدار** را به شما می‌دهد؛ ذخیره مکان‌نما را همین‌طور
می‌نویسد ([TextDAPSession.d:147](../../../JsonDAPtest/TextDAPSession.d#L147)):

```d
JSONValue envelope = JsonAP.APserializeSumTypeWithHandlers!CursorTarget(target,
        (CursorTarget held) => cursorTagOf(held),       // مقدار -> "line" | "search"
        (CursorTarget held) => cursorPayloadOf(held));  // مقدار -> JSONValue
```

و `readCursor` آن را از راه یک تابعِ خودتان برمی‌گرداند
([TextDAPSession.d:172](../../../JsonDAPtest/TextDAPSession.d#L172)،
[TextDAPModel.d:192](../../../JsonDAPtest/TextDAPModel.d#L192)):

```d
return JsonAP.APdeserializeSumTypeWithHandlers!CursorTarget(*stored,
        (string tag, JSONValue payload) => resolveCursor(tag, payload));
```

داخلِ `resolveCursor`، payload پیش از اعتماد با تگش سنجیده می‌شود — payload رشته‌ای زیرِ تگ
`"line"` به‌جای تبدیلِ اجباری `JSONConvertExceptionAP` پرتاب می‌کند. همین تفاوتِ *کدگذاری* و *حدس
زدن* است:

```d
if (tag == CursorTag.line)
{
    requireNodeType(tag, payload, JSONType.INTEGER);    // مگر اینکه payload عدد صحیح باشد
    return CursorTarget(cast(int) payload.integer);
}
```

| خط | چه کاری انجام می‌دهد |
|---|---|
| delegate `tagOf` | **کلِ مقدار** را می‌گیرد، پس دو عضوِ `int` می‌توانند تگِ متفاوت داشته باشند |
| delegate `payloadOf` | همان `JSONValue` را که باید نوشته شود برمی‌گرداند — هر قالبی |
| `resolver` | `T delegate(string tag, JSONValue payload)` — تنها جایی که تصمیم می‌گیرد کدام عضو ساخته شود |
| `held.match!` | بازدیدِ کاملِ Phobos؛ «switch» داخل همان لامبدا زندگی می‌کند |

## پنج متد در یک جدول

| متد | ورودی | خروجی |
|---|---|---|
| `APserializeSumType!T(value, tagOf = null)` | یک مقدار | `JSONValue` |
| `APdeserializeSumType!T(json, lenient = false, tagOf = null)` | یک پاکت | `Optional!T` |
| `APdeserializeSumTypeFromString!T(text, lenient = false, tagOf = null)` | متن JSON | `Optional!T` |
| `APserializeSumTypeWithHandlers!T(value, tagOf, payloadOf)` | مقدار + دو delegate | `JSONValue` |
| `APdeserializeSumTypeWithHandlers!T(json, resolver)` | پاکت + resolver | `Optional!T` |

جفت `…WithHandlers` در کدِ واقعی همانی است که ترجیحش می‌دهید: تگ کنارِ همان مقداری می‌نشیند که
توصیفش می‌کند، و خواننده payloadهایی را که با تگشان در تضادند رد می‌کند.

بعدی: [۰۹ — بررسی و نگهبان‌ها](09-inspecting-and-guarding.md)