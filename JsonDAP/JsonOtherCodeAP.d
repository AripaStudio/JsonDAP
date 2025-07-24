module jsonOtherCodeAP;


import ExceptionAP;
import std.stdio;
import std.string;
import std.array;
import PublicCodeOtherCode;
import std.conv;
import std.exception;

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


//اضافه شود 
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
}
