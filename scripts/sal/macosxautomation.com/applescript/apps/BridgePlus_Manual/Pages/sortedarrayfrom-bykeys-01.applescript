use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"}
set theResult to current application's SMSForder's sortedArrayFrom:listOrArray byKeys:{"length", "self"}
ASify from theResult
-->	{"one", "six", "ten", "two", "five", "four", "nine", "eight", "seven", "three"}
theResult as list
-->	{"one", "six", "ten", "two", "five", "four", "nine", "eight", "seven", "three"}

set listOrArray to current application's SMSForder's resourceValuesForKeys:{current application's NSURLCreationDateKey} forFilesIn:(path to desktop) recursive:true
set theResult to current application's SMSForder's sortedArrayFrom:listOrArray byKeys:{current application's NSURLCreationDateKey}
set theResult to theResult's valueForKey:(current application's NSURLPathKey)
ASify from theResult
--> list of POSIX paths in creation date order
theResult as list
--> list of POSIX paths in creation date order
