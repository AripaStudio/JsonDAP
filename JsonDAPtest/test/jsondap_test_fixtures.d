module jsondap_test_fixtures;

import std.conv;
import std.file;
import std.path;
import std.process;
import std.typecons;
import std.sumtype;

import JsonDAP;

alias Optional = Nullable;

enum Level
{
    low,
    medium,
    high
}

struct Point
{
    int x;
    int y;
}

class Attachment
{
    string name;
}

struct Message
{
    string text;
    Level level;
    Point origin;
    Attachment attachment;
    Optional!int count;
}

struct Envelope
{
    @JsonName("msg_id") string messageId;
    @JsonIgnore int scratch;
    Message body;
}

alias Payload = SumType!(Point, string);

struct Routed
{
    string route;
    Payload payload;
}

string tempJson(string name)
{
    return buildPath(tempDir, "jsondap_" ~ name ~ "_" ~ to!string(thisProcessID) ~ ".json");
}

void cleanUp(string path)
{
    if (exists(path))
    {
        remove(path);
    }
}
