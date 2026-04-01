use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

get (current date)
-->	date "Monday, 23 November 2015 at 11:59:15 AM"
set theResult to current application's SMSForder's extraDateValuesFrom:(current date)
ASify from theResult
-->	{1, 2015, 48, 2}
theResult as list
-->	{1, 2015, 48, 2}
