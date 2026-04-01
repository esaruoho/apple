use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {"one", "two", "three", "four", "five"}
set theResult to current application's SMSForder's sortedArrayFrom:listOrArray stableSort:true usingSelector:"compareThis:withThis:" target:me
ASify from theResult
-->	{"one", "three", "five", "two", "four"}
theResult as list
-->	{"one", "three", "five", "two", "four"}

on compareThis:x withThis:y
	-- sort by last character of string
	set x to x as text
	set y to y as text
	if last character of x > last character of y then
		return 1
	else if last character of x < last character of y then
		return -1
	else
		return 0
	end if
end compareThis:withThis:
