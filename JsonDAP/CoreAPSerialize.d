module CoreAPSerialize;

import std.string;
import std.conv;
import std.json;
import std.traits;
import std.typecons;
import std.exception;
import std.sumtype : isSumType, get;
import PublicCodeOtherCode;
import ExceptionAP;
import ExceptionJsonAP;
import CheckVariablesAP;
import CoreAPConv;
import CoreAP;

alias Optional = Nullable;

public static class CL_CoreAP_Serialize
{
    public static JSONValue serializeTToJsonValue(T)(T obj)
    {
        bool[void* ] visited;
        return serializeInternal(obj, visited);
    }

    private static JSONValue serializeInternal(T)(T obj, ref bool[void* ] visited)
    {
        static assert(!is(T == JSONValue),
                "Serializing JSONValue to JSONValue is redundant. Please ensure T is not JSONValue.");
        try
        {
            static if (CheckVariablesAP.IsNumberAP!T.value || CheckVariablesAP.IsBoolAP!T.value)
            {
                return JSONValue(obj);
            }
            else static if (CheckVariablesAP.IsStringAP!T.value)
            {
                return JSONValue(obj);
            }
            else static if (is(T : Optional!U, U))
            {
                if (obj.isNull)
                {
                    return JSONValue.init;
                }
                else
                {
                    return serializeInternal!U(obj.get , visited);
                }
            }
            else static if (CheckVariablesAP.IsArrayAP!T.value)
            {
                alias ElementType = typeof(T.init[0]);
                JSONValue[] jsonArray;
                foreach (o; obj)
                {
                    jsonArray ~= serializeInternal!ElementType(o , visited);
                }
                return JSONValue(jsonArray);
            }
            else static if (isSumType!T)
            {
                return serializeSumTypeInternal(obj, visited, null);
            }
            else static if (CheckVariablesAP.IsClassAP!T.value
                    || CheckVariablesAP.IsStructAP!T.value)
            {
                static if (CheckVariablesAP.IsClassAP!T.value)
                {
                    if (obj is null)
                    {
                        return JSONValue.init;
                    }

                    void* addr = cast(void*) obj;
                    if (addr in visited)
                    {
                        throw new JsonOperationExceptionAP("Circular reference detected while serializing "
                                ~ T.stringof ~ ".", null, T.stringof, __FILE__, __LINE__);
                    }

                    visited[addr] = true;
                }

                JSONValue jsonObject;
                jsonObject.object = null;
                static foreach (memberName; jsonFieldNames!T)
                {
                    {
                        alias TargetType = typeof(__traits(getMember, T, memberName));

                        auto fieldValue = mixin("obj." ~ memberName);

                        JSONValue memberJsonValue = serializeInternal!TargetType(fieldValue , visited);

                        jsonObject[jsonFieldName!(T, memberName)] = memberJsonValue;
                    }
                }

                static if (CheckVariablesAP.IsClassAP!T.value)
                {
                    visited.remove(cast(void*) obj);
                }

                return jsonObject;
            }
            else static if (CheckVariablesAP.IsEnumAP!T.value)
            {
                static if (is(typeof(T.init) : int))
                {
                    return JSONValue(cast(int) obj);
                }
                else
                {
                    return JSONValue(obj.toString());
                }
            }
            else
            {
                static assert(0, "Unsupported type " ~ T.stringof ~ " for JSON serialization.");
            }

        }
        catch (BaseExceptionAP e)
        {
            throw e;
        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("Error during JSON serialization.",
                    null, T.stringof, __FILE__, __LINE__, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorExceptionAP("An unexpected error occurred during object to JSON conversion.",
                    __FILE__, __LINE__, e);
        }
    }
    /**
     * Writes a std.sumtype.SumType value as a tagged envelope so a peer written
     * in another language can route on "tag" and decode "value" with the type it names.
     */
    public static JSONValue serializeSumType(T)(T value, string delegate(string memberName) tagOf = null)
    {
        static assert(isSumType!T, "serializeSumType expects a std.sumtype.SumType value.");

        bool[void* ] visited;
        return serializeSumTypeInternal(value, visited, tagOf);
    }

    /**
     * Reads the envelope written by serializeSumType back into a SumType value;
     * the tag selects the member type that decodes the payload.
     */
    public static Optional!T deserializeSumType(T)(JSONValue jsonValue,
            bool lenient = false, string delegate(string memberName) tagOf = null)
    {
        static assert(isSumType!T, "deserializeSumType expects a std.sumtype.SumType type.");

        string tag = sumTypeEnvelopeTag(jsonValue);
        JSONValue payload = sumTypeEnvelopePayload(jsonValue);

        string[] knownTags;
        static foreach (MemberType; T.Types)
        {
            knownTags ~= sumTypeTagName!MemberType(tagOf);
        }

        Optional!T result = Optional!T.init;
        static foreach (i, MemberType; T.Types)
        {
            if (result.isNull && sumTypeTagName!MemberType(tagOf) == tag)
            {
                auto convertedPayload = CL_CoreAP_Conv.convertJsonValueToT!MemberType(payload, lenient);
                if (convertedPayload.isNull)
                {
                    result = Optional!T(T(MemberType.init));
                }
                else
                {
                    result = Optional!T(T(convertedPayload.get));
                }
            }
        }

        if (result.isNull)
        {
            throw new JSONConvertExceptionAP("Unknown tag in SumType envelope.",
                    "tag", tag, JSONType.STRING.to!string, T.stringof, "UnknownSumTypeTag", null,
                    "Known tags: " ~ knownTags.join(", "), __FILE__, __LINE__);
        }

        return result;
    }

    /**
     * Same wire format as serializeSumType, but the tag and the payload of
     * every member are decided by the caller, usually with match!.
     */
    public static JSONValue serializeSumTypeWithHandlers(T)(T value,
            string delegate(T) tagOf, JSONValue delegate(T) payloadOf)
    {
        static assert(isSumType!T, "serializeSumTypeWithHandlers expects a std.sumtype.SumType value.");

        string tag = tagOf(value);
        if (tag.empty)
        {
            throw new JsonOperationExceptionAP("SumType member produced an empty tag.",
                    null, T.stringof, __FILE__, __LINE__);
        }

        JSONValue envelope = JSONValue.emptyObject;
        envelope["tag"] = JSONValue(tag);
        envelope["value"] = payloadOf(value);
        return envelope;
    }

    /**
     * Reads an envelope whose tag and payload are interpreted by the caller;
     * the resolver throws for a tag it does not know.
     */
    public static Optional!T deserializeSumTypeWithHandlers(T)(JSONValue jsonValue,
            T delegate(string tag, JSONValue payload) resolver)
    {
        static assert(isSumType!T, "deserializeSumTypeWithHandlers expects a std.sumtype.SumType type.");

        string tag = sumTypeEnvelopeTag(jsonValue);
        JSONValue payload = sumTypeEnvelopePayload(jsonValue);
        return Optional!T(resolver(tag, payload));
    }

    private static JSONValue serializeSumTypeInternal(T)(T value,
            ref bool[void* ] visited, string delegate(string memberName) tagOf)
    {
        string tag;
        JSONValue payload;
        bool matched = false;

        static foreach (i, MemberType; T.Types)
        {
            if (!matched && value.typeIndex == i)
            {
                matched = true;
                tag = sumTypeTagName!MemberType(tagOf);
                payload = serializeInternal(get!MemberType(value), visited);
            }
        }

        if (!matched)
        {
            throw new JsonOperationExceptionAP("SumType holds a member that Types does not list.",
                    null, T.stringof, __FILE__, __LINE__);
        }

        JSONValue envelope = JSONValue.emptyObject;
        envelope["tag"] = JSONValue(tag);
        envelope["value"] = payload;
        return envelope;
    }

    private static string sumTypeTagName(T)(string delegate(string memberName) tagOf)
    {
        string memberName = jsonTypeName(T.stringof);
        return tagOf is null ? memberName : tagOf(memberName);
    }

    private static string sumTypeEnvelopeTag(JSONValue jsonValue)
    {
        if (jsonValue.type != JSONType.OBJECT || "tag" !in jsonValue.object
                || jsonValue.object["tag"].type != JSONType.STRING)
        {
            throw new JSONConvertExceptionAP("SumType envelope must be an object with a string \"tag\".",
                    "tag", jsonValue.to!string, jsonValue.type.to!string, "string",
                    "SumTypeEnvelopeInvalid", null,
                    "Expected {\"tag\": \"...\", \"value\": ...}.", __FILE__, __LINE__);
        }

        return jsonValue.object["tag"].str;
    }

    private static JSONValue sumTypeEnvelopePayload(JSONValue jsonValue)
    {
        if (jsonValue.type != JSONType.OBJECT || "value" !in jsonValue.object)
        {
            return JSONValue.init;
        }

        return jsonValue.object["value"];
    }
}
