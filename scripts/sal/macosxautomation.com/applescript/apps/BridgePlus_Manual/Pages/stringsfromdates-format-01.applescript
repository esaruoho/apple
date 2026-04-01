use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theDates to {current date, (current date)   30 * days}
set theResult to current application's SMSForder's stringsFromDates:theDates |format|:"yyyy.MM.dd HH.mm.ss"
ASify from theResult
-->	{"2015.11.20 18.17.02", "2015.12.20 18.17.02"}
theResult as list
-->	{"2015.11.20 18.17.02", "2015.12.20 18.17.02"}
