module jsondap_tests;

import std.exception;
import std.json;
import std.stdio;
import std.sumtype;

import JsonDAP;
import jsondap_test_fixtures;

unittest
{
    writeln("-- 1. struct round trip: enum, nested struct, null class field, Nullable field");

    Message message;
    message.text = "hello";
    message.level = Level.high;
    message.origin = Point(3, 4);
    message.attachment = null;
    message.count = 7;

    JSONValue json = JsonAP.APserializeToJson!Message(message);
    assert(json["text"].str == "hello");
    assert(json["level"].integer == 2);
    assert(json["origin"]["x"].integer == 3);
    assert(json["attachment"].type == JSONType.NULL, "a null class field must serialize as null, not crash");
    assert(json["count"].integer == 7);

    Message loaded = JsonAP.APdeserializeJson!Message(json.toString).get;
    assert(loaded.text == "hello");
    assert(loaded.level == Level.high);
    assert(loaded.origin.y == 4);
    assert(loaded.attachment is null, "a null class field must come back as null");
    assert(loaded.count.get == 7);
}

unittest
{
    writeln("-- 2. an untouched Nullable field stays null through a round trip");

    Message message;
    message.text = "empty";
    message.level = Level.low;

    Message loaded = JsonAP.APdeserializeJson!Message(
            JsonAP.APserializeToJson!Message(message).toString).get;
    assert(loaded.attachment is null);
    assert(loaded.count.isNull, "an absent Nullable field must not become 0");
}

unittest
{
    writeln("-- 3. strict mode rejects a missing field, lenient mode keeps the default");

    string partial = `{"text": "partial"}`;

    assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJson!Message(partial));

    Message loaded = JsonAP.APdeserializeJsonLenient!Message(partial).get;
    assert(loaded.text == "partial");
    assert(loaded.level == Level.low, "a missing enum keeps its first member");
    assert(loaded.attachment is null);
}

unittest
{
    writeln("-- 4. an unknown enum value is rejected instead of being cast");

    string badInt = `{"text":"t","level":99,"origin":{"x":0,"y":0},"attachment":null}`;
    string badText = `{"text":"t","level":"ultra","origin":{"x":0,"y":0},"attachment":null}`;

    assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJson!Message(badInt));
    assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJson!Message(badText));
}

unittest
{
    writeln("-- 5. @JsonName and @JsonIgnore own the JSON contract of a field");

    Envelope envelope;
    envelope.messageId = "id-1";
    envelope.scratch = 42;
    envelope.body.text = "routed";
    envelope.body.level = Level.medium;

    JSONValue json = JsonAP.APserializeToJson!Envelope(envelope);
    assert("msg_id" in json.object);
    assert("messageId" !in json.object, "@JsonName must replace the D field name");
    assert("scratch" !in json.object, "@JsonIgnore must drop the field from the wire");
    assert(json["msg_id"].str == "id-1");

    Envelope loaded = JsonAP.APdeserializeJson!Envelope(json.toString).get;
    assert(loaded.messageId == "id-1");
    assert(loaded.scratch == 0, "an ignored field is not read back");
    assert(loaded.body.text == "routed");
}

unittest
{
    writeln("-- 6. a SumType field round trips through the tagged envelope");

    Routed routed;
    routed.route = "dns";
    routed.payload = Payload(Point(8, 8));

    JSONValue json = JsonAP.APserializeToJson!Routed(routed);
    assert(json["payload"]["tag"].str == "Point", "the tag is the short name of the active member");
    assert(json["payload"]["value"]["x"].integer == 8);

    Routed loaded = JsonAP.APdeserializeJson!Routed(json.toString).get;
    assert(loaded.route == "dns");
    assert(loaded.payload.has!Point);
    assert(loaded.payload.get!Point == Point(8, 8));

    Routed textRouted;
    textRouted.route = "plain";
    textRouted.payload = Payload("ping");

    Routed textLoaded = JsonAP.APdeserializeJson!Routed(
            JsonAP.APserializeToJson!Routed(textRouted).toString).get;
    assert(textLoaded.payload.get!string == "ping");
}

unittest
{
    writeln("-- 7. an unknown SumType tag reports the tags that do exist");

    string bad = `{"route":"x","payload":{"tag":"Unknown","value":{}}}`;
    assertThrown!JSONConvertExceptionAP(JsonAP.APdeserializeJson!Routed(bad));
}

unittest
{
    writeln("-- 8. SumType with the explicit handler API");

    Payload payload = Payload("ping");

    JSONValue json = JsonAP.APserializeSumTypeWithHandlers!Payload(payload,
            (Payload v) => v.match!((Point p) => "geometry", (string s) => "text"),
            (Payload v) => v.match!((Point p) => JsonAP.APserializeToJson!Point(p),
                    (string s) => JSONValue(s)));

    assert(json["tag"].str == "text");
    assert(json["value"].str == "ping");

    Payload loaded = JsonAP.APdeserializeSumTypeWithHandlers!Payload(json,
            (string tag, JSONValue value) {
                switch (tag)
                {
                case "geometry":
                    return Payload(JsonAP.APconvertJsonValueToT!Point(value).get);
                case "text":
                    return Payload(value.str);
                default:
                    throw new JSONExceptionAP("unknown tag " ~ tag);
                }
            }).get;

    assert(loaded.get!string == "ping");

    JSONValue generated = JsonAP.APserializeSumType!Payload(Payload(Point(1, 2)));
    assert(generated["tag"].str == "Point");
    assert(JsonAP.APdeserializeSumType!Payload(generated).get.get!Point == Point(1, 2));
}
