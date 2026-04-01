use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

get (current date)
-->	date "Monday, 23 November 2015 at 11:59:42 AM"
set theResult to current application's SMSForder's timeValuesFrom:(current date)
ASify from theResult
-->	{11, 59, 42, 0}
theResult as list
-->	{11, 59, 42, 0}
