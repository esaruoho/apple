use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set urlFileOrPath to "~/Desktop"
set resourceKeys to {current application's NSURLAddedToDirectoryDateKey, current application's NSURLCreationDateKey}
set theResult to current application's SMSForder's resourceValuesForKeys:resourceKeys forItemsIn:urlFileOrPath recursive:true skipHidden:true skipInsidePackages:true
ASify from theResult
-->	{​​​​​{​​​​​​​NSURLCreationDateKey:date "Tuesday, 9 June 2015 at 10:53:10 AM", ​​​​​​​_NSURLPathKey:"/Users/shane/Desktop/10.11 Changes.webarchive", ​​​​​​​NSURLAddedToDirectoryDateKey:date "Friday, 25 September 2015 at 5:39:05 PM"​​​​​}, [...]}
theResult as list -- 10.11 only
-->	{​​​​​{​​​​​​​NSURLCreationDateKey:date "Tuesday, 9 June 2015 at 10:53:10 AM", ​​​​​​​_NSURLPathKey:"/Users/shane/Desktop/10.11 Changes.webarchive", ​​​​​​​NSURLAddedToDirectoryDateKey:date "Friday, 25 September 2015 at 5:39:05 PM"​​​​​}, [...]}
theResult as list -- 10.9 and 10.10
-->	{​​​​​{​​​​​​​NSURLCreationDateKey:(NSDate) 2015-06-09 00:53:10  0000, ​​​​​​​_NSURLPathKey:"/Users/shane/Desktop/10.11 Changes.webarchive", ​​​​​​​NSURLAddedToDirectoryDateKey:(NSDate) 2015-09-25 07:39:05  0000​​​​​}, [...]}


set sortDesc to current application's NSSortDescriptor's sortDescriptorWithKey:(current application's NSURLCreationDateKey) ascending:true
set sortedValues to theResult's sortedArrayUsingDescriptors:{sortDesc}
set thePaths to sortedValues's valueForKey:(current application's NSURLPathKey)
ASify from thePaths
-->	<recursive list of POSIX paths of files and folders sorted by creation date>
thePaths as list
-->	<recursive list of POSIX paths of files and folders sorted by creation date>
