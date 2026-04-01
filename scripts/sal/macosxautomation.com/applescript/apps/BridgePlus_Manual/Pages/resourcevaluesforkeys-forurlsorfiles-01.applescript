use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set fileAliasOrPath to (choose file with multiple selections allowed)
set theResult to current application's SMSForder's resourceValuesForKeys:{current application's NSURLAddedToDirectoryDateKey, current application's NSURLIsPackageKey} forURLsOrFiles:fileAliasOrPath
ASify from theResult
-->	{{NSURLIsPackageKey:true, _NSURLPathKey:"/Users/shane/Library/Script Libraries/BridgePlus.scptd", NSURLAddedToDirectoryDateKey:date "Sunday, 22 November 2015 at 11:08:46 PM"}, {NSURLIsPackageKey:false, _NSURLPathKey:"/Users/shane/Library/Script Libraries/BridgePlus ReadMe.rtf", NSURLAddedToDirectoryDateKey:date "Friday, 20 November 2015 at 10:56:39 AM"}}
theResult as list -- 10.11 only
-->	{{NSURLIsPackageKey:true, _NSURLPathKey:"/Users/shane/Library/Script Libraries/BridgePlus.scptd", NSURLAddedToDirectoryDateKey:date "Sunday, 22 November 2015 at 11:08:46 PM"}, {NSURLIsPackageKey:false, _NSURLPathKey:"/Users/shane/Library/Script Libraries/BridgePlus ReadMe.rtf", NSURLAddedToDirectoryDateKey:date "Friday, 20 November 2015 at 10:56:39 AM"}}
theResult as list -- 10.9 and 10.10
-->	{{NSURLIsPackageKey:true, _NSURLPathKey:"/Users/shane/Library/Script Libraries/BridgePlus.scptd", NSURLAddedToDirectoryDateKey:(NSDate) 2015-11-22 12:08:46  0000}, {NSURLIsPackageKey:false, _NSURLPathKey:"/Users/shane/Library/Script Libraries/BridgePlus ReadMe.rtf", NSURLAddedToDirectoryDateKey:(NSDate) 2015-11-19 23:56:39  0000}}
