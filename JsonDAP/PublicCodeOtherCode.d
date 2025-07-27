module PublicCodeOtherCode;


import std.json;
import std.typecons; 
import std.stdio;
import std.conv;
import std.string;
import std.array;
import std.exception;
import ExceptionAP;

alias Optional = Nullable;

public  class CL_PublicCodeOtherCode
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


    public static void StrIsNUll(string input, string paramName = "input" , out bool outputBool , out string ErrorText) 
    {
        try
		{
			if (input is null)
			{
				throw new InvalidArgumentExceptionAP("Parameter '" ~ paramName ~ "' cannot be null.", paramName, "null");
			}
			if (input.empty)
			{
				throw new InvalidArgumentExceptionAP("Parameter '" ~ paramName ~ "' cannot be empty.", paramName, "''");
			}
			if (input.strip.empty)
			{
				throw new InvalidArgumentExceptionAP("Parameter '" ~ paramName ~ "' cannot be just whitespace.", paramName, "'" ~ input ~ "'");
			}
			outputBool = false;
			ErrorText = "";
		}catch(Exception e)
		{
			outputBool = true;
			ErrorText = e.msg;
		}
    }

		
	public static  bool checkStringIsNull_array(string[] inputs) {
		

		if(inputs.length == 0)
		{
			return true;
		}
		foreach(input; inputs)
		{
			string errorText;
			bool isNull;
			string paramName;			
			CL_PublicCodeOtherCode.StrIsNUll(input , paramName , isNull, errorText);
			if (isNull) {
				throw new UnknownErrorexceptionAP("Unknown error: " ~ errorText ~ " |__| Like input : ~ "~ paramName ~  " |____| " , __FILE__, __LINE__);
			}
		}

		return false;
	
	}

	

	




}

/*
	انجام شود و اضافه شود به متد های اصلی و از این متد ها استفاده شود در 
	serializeTToJsonValue
	
*/
public  class CL_CheckVariables
{
	public static bool isIntAP(T)(T input)
	{

	}

	public static bool isFloatAP(T)(T input)
	{

	}

	public static bool isBoolAP(T)(T input){

	}

	public static bool isNumberAP(T)(T input)
	{

	}

	public static bool isStringAP(T)(T input)
	{

	}

	public static bool isArrayAP(T)(T input)
	{

	}

	public static bool isClassAP(T)(T input)
	{

	}

	public static bool isStructAP(T)(T input)
	{

	}

}


