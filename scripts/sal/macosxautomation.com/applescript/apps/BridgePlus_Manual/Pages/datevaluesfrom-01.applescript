use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

get (current date)
--> date "Monday, 23 November 2015 at 11:57:34 AM" 
set theResult to current application's SMSForder's dateValuesFrom:(current date)
ASify from theResult
-->	{1, 2015, 11, 23}
theResult as list
-->	{1, 2015, 11, 23}
