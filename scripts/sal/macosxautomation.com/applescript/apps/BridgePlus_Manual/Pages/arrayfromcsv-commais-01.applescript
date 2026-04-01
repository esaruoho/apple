use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "1,2,3" & linefeed & "4,\"5,00\",6" & linefeed & "7,8,9"
set theResult to current application's SMSForder's arrayFromCSV:aString commaIs:","
ASify from theResult
-->	{{"1", "2", "3"}, {"4", "5,00", "6"}, {"7", "8", "9"}}
theResult as list
-->	{{"1", "2", "3"}, {"4", "5,00", "6"}, {"7", "8", "9"}}
