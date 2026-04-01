use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set fileAliasOrPath to (choose file with multiple selections allowed)
set theResult to current application's SMSForder's resourceValueForKey:(current application's NSURLAddedToDirectoryDateKey) forURLsOrFiles:fileAliasOrPath
ASify from theResult
-->	{date "Thursday, 19 November 2015 at 2:07:27 PM", date "Thursday, 29 October 2015 at 3:12:21 PM", date "Friday, 25 September 2015 at 6:07:40 PM"}
theResult as list -- 10.11 only
-->	{date "Thursday, 19 November 2015 at 2:07:27 PM", date "Thursday, 29 October 2015 at 3:12:21 PM", date "Friday, 25 September 2015 at 6:07:40 PM"}
theResult as list -- 10.9 and 10.10
-->	{(NSDate) 2015-11-19 03:07:27  0000, (NSDate) 2015-10-29 04:12:21  0000, (NSDate) 2015-09-25 08:07:40  0000}
