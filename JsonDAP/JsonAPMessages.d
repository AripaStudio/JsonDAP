module JsonAPMessages;

import std.json;
import FileAPAdd;
import FileAPMerge;
import FileAPRemove;
import FileAPUpdate;

// Message-carrying twins of the path-edit API. They live in their own class so
// JsonAP keeps one delegate per call and this file keeps one responsibility.
public class APEditMessages
{
    export static bool APupdateJsonValueOBJECTWithMessage(V)(string filePath, string jsonPath,
            V value, out string message)
    {
        return CL_FileAP_Update.updateJsonValueOBJECT!V(filePath, jsonPath, value, message);
    }

    export static bool APupdateJsonValueARRAYWithMessage(V)(string filePath, string jsonPath,
            V value, out string message)
    {
        return CL_FileAP_Update.updateJsonValueARRAY!V(filePath, jsonPath, value, message);
    }

    export static bool APaddJsonItemOBJECTWithMessage(T)(string filePath, string jsonPath,
            T item, out string message)
    {
        return CL_FileAP_Add.addJsonItemOBJECT!T(filePath, jsonPath, item, message);
    }

    export static bool APaddJsonItemARRAYWithMessage(T)(string filePath, string jsonPath,
            T item, out string message)
    {
        return CL_FileAP_Add.addJsonItemARRAY!T(filePath, jsonPath, item, message);
    }

    export static bool APremoveJsonItemOBJECTWithMessage(string filePath, string jsonPath,
            out string message)
    {
        return CL_FileAP_Remove.removeJsonItemOBJECTWithMessage(filePath, jsonPath, message);
    }

    export static bool APremoveJsonItemARRAYWithMessage(string filePath, string jsonPath,
            out string message)
    {
        return CL_FileAP_Remove.removeJsonItemARRAYWithMessage(filePath, jsonPath, message);
    }

    export static bool APmergeJsonWithMessage(string filePath, JSONValue jsonContentToMerge,
            bool overwriteExisting, bool mergeArrays, out string message)
    {
        return CL_FileAP_Merge.mergeJsonWithMessage(filePath, jsonContentToMerge,
                overwriteExisting, mergeArrays, message);
    }
}
