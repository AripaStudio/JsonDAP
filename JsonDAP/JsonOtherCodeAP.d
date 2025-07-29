module jsonOtherCodeAP;


import ExceptionAP;
import std.stdio;
import std.string;
import std.array;
import PublicCodeOtherCode;
import std.conv;
import std.exception;
import std.json;
import CheckVariablesAP;

public static enum PathStepType{
	ObjectKey,
	ArrayIndex
}

public static struct PathStep{
	PathStepType type;
	union{
		string key;
		int index;
	}
}


public class CL_JsonOtherCode{
	
	public static PathStep[] JsonPathParserAP(string input ){
		string errorTextStrIsNull;
		bool CheckStrIsNull;
		CL_PublicCodeOtherCode.StrIsNUll(input , "input" , CheckStrIsNull ,  errorTextStrIsNull);
		if(CheckStrIsNull)
		{
			throw new UnknownErrorexceptionAP("Unknown error." ~ errorTextStrIsNull ~ " |____|  " , __FILE__ , __LINE__);
		}

		PathStep[] pathSteps; 
		int currentIndex = 0;

		while(currentIndex < input.length)
		{
			if(input[currentIndex] == '.')
			{
				currentIndex++;				
				continue;
			}

			if(input[currentIndex] == '[')
			{		
				currentIndex++;
				auto startIndex = currentIndex;
				auto closingBracketIndexlong  = input.indexOf(']' , startIndex);
				int closingBracketIndex;
				try{
					closingBracketIndex = to!int(closingBracketIndexlong);
				}catch(Exception e)
				{
					throw new UnknownErrorexceptionAP("Convert Error: Convert Not Complete (in JsonPathParserAP). |____|  " , __FILE__ , __LINE__);
				}

				if(closingBracketIndex == -1)
				{
					throw new UnknownErrorexceptionAP("Syntax Error: Missing closing bracket in JSON path. |____|  " , __FILE__ , __LINE__);
				}

				string indexString = input[startIndex .. closingBracketIndex];
				if(indexString.empty)
				{
					throw new UnknownErrorexceptionAP("Syntax Error: Empty array index in JSON path. |____|  " , __FILE__ , __LINE__);
				}

				int IndexValue;
				try{
					IndexValue = to!int(indexString);
				}catch(Exception e)
				{
					throw new UnknownErrorexceptionAP("Convert Error: Convert Not Complete (in JsonPathParserAP). |____|  " , __FILE__ , __LINE__);
				}

				PathStep newStep;
				newStep.type = PathStepType.ArrayIndex;
				newStep.index = IndexValue;

				pathSteps ~= newStep;

				currentIndex = closingBracketIndex + 1;
				continue;
			}else{
				auto startIndex = currentIndex;
				ulong nextSeparatorIndexlong = input.length;
				int nextSeparatorIndex ;
				try{
					nextSeparatorIndex = to!int(nextSeparatorIndexlong);
				}catch(Exception e)
				{
					throw new UnknownErrorexceptionAP("Convert Error: Convert Not Complete (in JsonPathParserAP). |____|  " , __FILE__ , __LINE__);
				}

				long dotIndexlong = input.indexOf('.' , startIndex);
				long bracketIndexlong = input.indexOf('[' , startIndex);
				int bracketIndex;
				int dotIndex;
				try{
					dotIndex = to!int(dotIndexlong);
					bracketIndex = to!int(bracketIndexlong);
				}catch(Exception e)
				{
					throw new UnknownErrorexceptionAP("Convert Error: Convert Not Complete (in JsonPathParserAP). |____|  " , __FILE__ , __LINE__);
				}


				if (dotIndex != -1 && (dotIndex < nextSeparatorIndex)) 
				{
					nextSeparatorIndex = dotIndex;
				}

				if (bracketIndex != -1 && (bracketIndex < nextSeparatorIndex))
				{
					nextSeparatorIndex = bracketIndex;
				}

				string keyString = input[startIndex .. nextSeparatorIndex];

				if(keyString.empty)
				{
					throw new UnknownErrorexceptionAP("Syntax Error: Empty object key in JSON path. |____|  " , __FILE__ , __LINE__);
				}

				PathStep newStep;

				newStep.type = PathStepType.ObjectKey;
				newStep.key = keyString;

				pathSteps ~= newStep;
				currentIndex = nextSeparatorIndex;
			}



		}

		return pathSteps;
	}

	//اضافه شود : 
	public static bool recursiveMerge(JSONValue* target , JSONValue* source , bool overwrite , bool mergeArrays , string message = "")
	{
		if(*source == JSONValue.init)
		{
			return false;
		}
		if(*target == JSONValue.init)
		{
			if(overwrite)
			{
				message = "Target is uninitialized, overwriting with source.";
				*target = *source;
				return true;
			}else
			{
				return false;
			}
		}

		if((*source).type == JSONType.TRUE || (*source).type == JSONType.FALSE ||
		   (*source).type == JSONType.INTEGER || (*source).type == JSONType.STRING ||
		   (*source).type == JSONType.NULL)
		{
			if(overwrite)
			{
				message = "Source is a primitive type, overwriting target.";
				*target = *source;
				return true;
			}else
			{
				return false;
			}
		}

		if((*source).type == JSONType.OBJECT && (*target).type == JSONType.OBJECT)
		{
			foreach(key , value; (*source).object)
			{
				if(key in (*target).object)
				{
					recursiveMerge(&(*target).object[key], &value, overwrite, mergeArrays);
				}else
				{
					(*target).object[key] = value;
				}
			}
			return true;
		}else if((*source).type == JSONType.ARRAY && (*target).type == JSONType.ARRAY)
		{
			if(mergeArrays)	
			{
				(*target).array ~= (*source).array;
				return true;
			}else
			{
				message = "Target and source are arrays, but array merging is disabled. Overwriting target.";
				*target = *source;
				return true;
			}

		}else if((*target).type == JSONType.ARRAY && (*source).type != JSONType.ARRAY)
		{
			if(overwrite)
			{
				message = "Target is an array, source is not. Overwriting target with source.";
				*target = *source;
				return true;
			}else
			{
				return false;
			}
		}else
		{
			if(overwrite)
			{
				message = "Target and source types are incompatible. Overwriting target with source.";
				*target = *source;
				return true;
			}else
			{
				return false;
			}
		}
	}
}
