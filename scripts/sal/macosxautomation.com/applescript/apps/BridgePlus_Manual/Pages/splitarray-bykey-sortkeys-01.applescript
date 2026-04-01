use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"}
set theResult to current application's SMSForder's splitArray:listOrArray byKey:"length" sortKeys:{"self"}
ASify from theResult
-->	{{"one", "six", "ten", "two"}, {"five", "four", "nine"}, {"eight", "seven", "three"}}
theResult as list
-->	{{"one", "six", "ten", "two"}, {"five", "four", "nine"}, {"eight", "seven", "three"}}

set listOrArray to current application's SMSForder's resourceValuesForKeys:{current application's NSURLTypeIdentifierKey, current application's NSURLNameKey} forFilesIn:(path to desktop) recursive:true
set theResult to current application's SMSForder's splitArray:listOrArray byKey:(current application's NSURLTypeIdentifierKey) sortKeys:{current application's NSURLNameKey}
set finalList to {}
repeat with anArray in theResult
	set end of finalList to ASify from (anArray's valueForKey:(current application's NSURLPathKey))
end repeat
return finalList
--> list of sublists of POSIX paths, one sublist for each identifier
return
