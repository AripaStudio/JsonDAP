module PublicCodeOtherCode;


import std.json;
import std.typecons; 
import std.stdio;
import std.conv;
import std.string;

alias Optional = Nullable;


//ایکسپشن ها به لیست ایکسپورت ها اضافه شود 
public static class JsonOperationExceptionAP : Exception{
	this(string msg, string file = __FILE__ , size_t line = __LINE__ , Throwable next = null) pure{
		super(msg,file,line,next);
	}
}

public static class FileOperationExceptionAP : Exception{
	string filePath;
	this(string msg, string filePath, string file = __FILE__, int line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
        this.filePath = filePath;
    }
}

public static class JSONExceptionAP : Exception {
    this(string msg, string file = __FILE__, int line = __LINE__, Throwable next = null) pure {
        super(msg, file, line, next);
    }
}

public static class JSONConvertExceptionAP : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__ , Throwable next = null) pure
    {
        super(msg, file, line , next);
    }
}
public static class CL_PublicCodeOtherCode
{
	public static isDigitAP(dchar c)
	{
		if(c >= '0'  && c <= '9')
		{
			return true;
		}
		if (c >= '۰' && c <= '۹') {
            return true;
        }

		return false;
	}


	public static bool isInteger(string s) {
        if (s.empty) return false;

		foreach(dchar c; s)
		{
			if(!isDigitAP(c))
			{
				return false;
			}
		}
        return true;
    }

	




}