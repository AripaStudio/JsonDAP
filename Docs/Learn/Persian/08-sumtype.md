# ۰۸ — سام‌تایپ (SumType)

فهرست: [StartPe.md](../../StartPe.md) · قبلی: [۰۷](07-merge-and-copy.md)

`std.sumtype.SumType` هیچ بازتابی (reflection) به همراه ندارد — یک کتابخانه نمی‌تواند بپرسد اعضایش چه
نامی دارند. پس پشتیبانی به شکلِ یک جفتِ آشکار (explicit) است: **یک پاکت (envelope) بنویسید**،
**یک پاکت بخوانید**.

```
{"tag":"<which member>","value":<the payload>}
```

## برچسب‌های پیش‌فرض

```d
import std.sumtype;

alias Payload = SumType!(int, string);

JSONValue envelope = JsonAP.APserializeSumType!Payload(Payload(42));
// {"tag":"int","value":42}

auto back = JsonAP.APdeserializeSumType!Payload(envelope, false);
assert(back.get == Payload(42));
```

بدون delegate، برچسب همان نامِ نوعِ عضو در D است — `"int"`، `"string"`. کار می‌کند، ولی قالبِ
ردوپاشِ (wire format) شما را به نام‌های نوعِ Phobos قفل می‌کند.

## نام‌های خودتان

```d
JSONValue named = JsonAP.APserializeSumType!Payload(Payload("search"),
        (string memberName) => memberName == "int" ? "line" : "term");
// {"tag":"term","value":"search"}

auto namedBack = JsonAP.APdeserializeSumType!Payload(named, false,
        (string memberName) => memberName == "int" ? "line" : "term");
assert(namedBack.get == Payload("search"));
```

| خط | چه کاری انجام می‌دهد |
|---|---|
| delegate | `string delegate(string memberName) tagOf` — `int` / `string` را می‌گیرد و برچسبی که باید نوشته شود را برمی‌گرداند |
| همان delegate در سمتِ خواندن | **برعکس** به کار می‌رود: برچسب را به نامِ عضوی که باید انتخاب شود نگاشت می‌کند |
| `false` | `lenient` — پارامترِ دومِ تابعِ خواندن |

delegate باید در دو طرف یکی باشد، وگرنه برچسب‌ها جور نمی‌شوند. اپ برای این کار یک تابع دارد
([TextDAPModel.d:163](../../../JsonDAPtest/TextDAPModel.d#L163) با نام `cursorTagName`) و همان را به
هر دو فراخوانی می‌دهد ([TextDAPConvert.d:61](../../../JsonDAPtest/TextDAPConvert.d#L61)).

## از متن، و برچسب‌های ناشناخته

```d
auto fromText = JsonAP.APdeserializeSumTypeFromString!Payload(`{"tag":"string","value":"later"}`);
assert(fromText.get == Payload("later"));
```

برچسبِ ناشناخته رد می‌شود، و پیام برچسب‌هایی که واقعاً وجود دارند را فهرست می‌کند — هیچ عضو
پیش‌فرضی در کار نیست و هیچ مقدارِ خالی‌ای بی‌صدا ساخته نمی‌شود:

```d
try
{
    JsonAP.APdeserializeSumType!Payload(parseJSON(`{"tag":"bool","value":1}`));
}
catch (BaseExceptionAP caught)
{
    caught.msg;    // Unknown tag in SumType envelope.
}
```

## وقتی payload بیشتر از تبدیلِ خودِ عضو بخواهد

`APserializeSumType` مقدارِ payload را با سریال‌کننده‌ی معمولی می‌نویسد. وقتی یک عضو قالبِ مخصوصِ
خودش را می‌خواهد، یا برچسب به مقدار بستگی دارد نه به نوع، از جفتِ handler استفاده کنید:

```d
JSONValue written = JsonAP.APserializeSumTypeWithHandlers!Payload(Payload(7),
        (Payload held) => held.match!((int n) => "number", (string s) => "text"),
        (Payload held) => held.match!((int n) => JSONValue(n), (string s) => JSONValue(s)));
// {"tag":"number","value":7}

auto resolved = JsonAP.APdeserializeSumTypeWithHandlers!Payload(written,
        (string tag, JSONValue value) => tag == "number"
                ? Payload(cast(int) value.integer)
                : Payload(value.str));
assert(resolved.get == Payload(7));
```

| خط | چه کاری انجام می‌دهد |
|---|---|
| `tagOf` | کلِ `Payload` را می‌گیرد، نه نامِ یک عضو را — پس دو عضوِ `int` می‌توانند برچسبِ متفاوت داشته باشند |
| `payloadOf` | همان `JSONValue`ای را که باید نوشته شود برمی‌گرداند، با هر قالبی که می‌خواهید |
| `resolver` | `T delegate(string tag, JSONValue payload)` — تنها جایی که تصمیم می‌گیرد کدام عضو ساخته شود |
| `held.match!(…)` | بازدیدِ کامل (exhaustive) Phobos روی `SumType`؛ delegate همان‌جایی است که switch در آن زندگی می‌کند |

مکان‌نمای (cursor) اپ مثالِ واقعی همین است: یا یک شماره‌ی خط یا یک عبارتِ جست‌وجو، در یک فیلد داخل
فایلِ نشست
([TextDAPSession.d:145](../../../JsonDAPtest/TextDAPSession.d#L145) با handlerها می‌نویسد،
[:153](../../../JsonDAPtest/TextDAPSession.d#L153) از راه `resolveCursor` در
[TextDAPModel.d:192](../../../JsonDAPtest/TextDAPModel.d#L192) می‌خواند، که برای برچسبِ
ناشناخته `JsonOperationExceptionAP` پرتاب می‌کند).

## پنج متد

| متد | ورودی | خروجی |
|---|---|---|
| `APserializeSumType!T(T value, string delegate(string) tagOf = null)` | یک مقدار | `JSONValue` |
| `APdeserializeSumType!T(JSONValue, bool lenient = false, string delegate(string) tagOf = null)` | یک پاکت | `Optional!T` |
| `APdeserializeSumTypeFromString!T(string jsonContent, bool lenient = false, string delegate(string) tagOf = null)` | متن JSON | `Optional!T` |
| `APserializeSumTypeWithHandlers!T(T value, string delegate(T) tagOf, JSONValue delegate(T) payloadOf)` | یک مقدار و دو delegate | `JSONValue` |
| `APdeserializeSumTypeWithHandlers!T(JSONValue, T delegate(string tag, JSONValue payload) resolver)` | یک پاکت و یک resolver | `Optional!T` |

بعدی: [۰۹ — بررسی و نگهبان‌ها](09-inspecting-and-guarding.md)
