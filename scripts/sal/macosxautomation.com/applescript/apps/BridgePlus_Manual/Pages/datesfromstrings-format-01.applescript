use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set dateStrings to {"2015.11.19 12:30:00", "2016.02.03 03:15:30"}
set theDates to current application's SMSForder's datesFromStrings:dateStrings |format|:"yyyy.MM.dd HH.mm.ss"
-->	(NSArray) {(NSDate) 2015-11-19 01:30:00  0000, (NSDate) 2016-02-02 16:15:30  0000}
ASify from theDates
-->	{date "Thursday, 19 November 2015 at 12:30:00 PM", date "Wednesday, 3 February 2016 at 3:15:30 AM"}
theDates as list -- in 10.10 produces NSDates
-->	{2015-11-19 01:30:00  0000, 2016-02-02 16:15:30  0000}
theDates as list -- in 10.11 produces AS dates
-->	{date "Thursday, 19 November 2015 at 12:30:00 PM", date "Wednesday, 3 February 2016 at 3:15:30 AM"}
