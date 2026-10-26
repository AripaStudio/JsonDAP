module FileAP;

import std.file;
import std.string;
import std.json;
import std.typecons;
import std.traits;
import std.conv;
import std.exception;
import CoreAP;
import PublicCodeOtherCode;
import ExceptionAP;
import jsonOtherCodeAP;
import FileAPJson;
import ExceptionJsonAP;

alias Optional = Nullable;

public static class CL_FileAP
{

    public static Optional!T readJsonFile(T)(string filePath)
    {
        try
        {
            string errorTextStrIsNull;
            bool CheckStrIsNull;

            CL_PublicCodeOtherCode.strIsNil(filePath, "input",
                    CheckStrIsNull, errorTextStrIsNull);
            if (CheckStrIsNull)
            {
                throw new InvalidArgumentExceptionAP("Input file path cannot be empty or null.",
                        "filePath", filePath, "Non-empty string expected", null, 0);
            }

            if (!existsFile(filePath))
            {
                throw new FileOperationExceptionAP(
                        "File not found for reading.", filePath, "read", 0, null, 0);
            }
            auto jsonContent = readText(filePath);
            static if (is(T == JSONValue))
            {
                return Optional!T(parseJSON(jsonContent));
            }
            else
            {
                return CL_File_JSON.deserializeJson!T(jsonContent);
            }
        }
        catch (BaseExceptionAP e)
        {
            throw e;
        }
        catch (FileException e)
        {
            throw new FileOperationExceptionAP("File I/O error reading file.",
                    filePath, "read", 0, null, 0, e);
        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("Invalid JSON format in file.",
                    filePath, null, null, 0, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorExceptionAP(
                    "An unexpected error occurred while reading JSON file.", null, 0, e);
        }
    }

    public static bool writeJsonFile(T)(string filePath, T data)
    {
        try
        {
            if (filePath.empty)
            {
                throw new InvalidArgumentExceptionAP("Output file path cannot be empty.",
                        "filePath", filePath, "Non-empty string expected", null, 0);
            }
            import std.path : dirName;

            string dir = dirName(filePath);
            if (!dir.empty && !exists(dir))
            {
                mkdirRecurse(dir);
            }

            auto jsonContent = CL_File_JSON.serializeToJson(data);
            std.file.write(filePath, jsonContent.toString());
            return true;
        }
        catch (BaseExceptionAP e)
        {
            throw e;
        }
        catch (FileException e)
        {
            throw new FileOperationExceptionAP("File I/O error writing to file.",
                    filePath, "write", 0, null, 0, e);
        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("Serialization error while writing JSON to file.",
                    filePath, null, null, 0, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorExceptionAP(
                    "An unexpected error occurred while writing JSON file.", null, 0, e);
        }
    }

    public static Optional!long getJsonFileSize(string filePath)
    {
        try
        {
            if (filePath.empty)
            {
                throw new InvalidArgumentExceptionAP("File path cannot be empty when getting file size.",
                        "filePath", filePath, "Non-empty string expected", null, 0);
            }
            if (!existsFile(filePath))
            {
                throw new FileOperationExceptionAP(
                        "File not found for size check.", filePath, "get size", 0, null, 0);
            }
            long fileSize = std.file.getSize(filePath);
            return Optional!long(fileSize);
        }
        catch (BaseExceptionAP e)
        {
            throw e;
        }
        catch (FileException e)
        {
            throw new FileOperationExceptionAP("File I/O error getting size of file.",
                    filePath, "get size", 0, null, 0, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorExceptionAP(
                    "An unexpected error occurred while getting file size.", null, 0, e);
        }
    }

    public static Optional!(T[]) readJsonArray(T)(string filepath)
    {
        try
        {
            string errorTextStrIsNull;
            bool CheckStrIsNull;
            CL_PublicCodeOtherCode.strIsNil(filepath, "input",
                    CheckStrIsNull, errorTextStrIsNull);
            if (CheckStrIsNull)
            {
                throw new InvalidArgumentExceptionAP("Input file path cannot be empty or null.",
                        "filePath", filepath, "Non-empty string expected", null, 0);
            }
            if (!existsFile(filepath))
            {
                throw new FileOperationExceptionAP(
                        "File not found for reading array.", filepath, "read array", 0, null, 0);
            }
            string jsonContent = readText(filepath);
            return CL_File_JSON.deserializeJsonArray!T(jsonContent);
        }
        catch (BaseExceptionAP e)
        {
            throw e;
        }
        catch (FileException e)
        {
            throw new FileOperationExceptionAP("File I/O error reading array from file.",
                    filepath, "read array", 0, null, 0, e);
        }
        catch (JSONException e)
        {
            throw new JsonOperationExceptionAP("Invalid JSON format for array in file.",
                    filepath, null, null, 0, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorExceptionAP(
                    "An unexpected error occurred while reading JSON array from file.", null, 0, e);
        }
    }

    public static bool Exists(string filePath)
    {
        if (filePath.empty)
        {
            return false;
        }
        if (!exists(filePath))
        {
            return false;
        }
        return true;
    }

    public static bool existsFile(string filePath)
    {
        try
        {
            if (!Exists(filePath))
            {
                return false;
            }
            return true;
        }
        catch (FileException e)
        {
            throw new FileOperationExceptionAP("File I/O error during existence check.",
                    filePath, "check existence", 0, null, 0, e);
        }
        catch (Exception e)
        {
            throw new UnknownErrorExceptionAP(
                    "An unexpected error occurred during file existence check.", null, 0, e);
        }

    }

}
