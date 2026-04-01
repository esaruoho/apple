use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set fileAliasOrPath to "~/Desktop/Test/IMG_0829.JPG"
set theResult to current application's SMSForder's infoForFile:fileAliasOrPath
ASify from theResult
-->	{isAliasFile:false, fileResourceType:"NSURLFileResourceTypeRegular", isExcludedFromBackup:false, contentModificationDate:date "Monday, 12 October 2015 at 3:12:56 PM", isReadable:true, isSystemImmutable:false, isSymbolicLink:false, isExecutable:false, parentDirectoryURL:file "Macintosh HD:Users:shane:Desktop:Test:", hasHiddenExtension:false, labelNumber:0, isWritable:true, path:"/Users/shane/Desktop/Test/IMG_0829.JPG", isPackage:false, name:"IMG_0829.JPG", isDirectory:false, linkCount:1, attributeModificationDate:date "Monday, 9 November 2015 at 11:00:55 AM", creationDate:date "Monday, 12 October 2015 at 3:12:55 PM", isHidden:false, isRegularFile:true, contentAccessDate:date "Monday, 23 November 2015 at 9:48:41 AM", isUserImmutable:false}
theResult as record
-->	{isAliasFile:false, fileResourceType:"NSURLFileResourceTypeRegular", isExcludedFromBackup:false, contentModificationDate:date "Monday, 12 October 2015 at 3:12:56 PM", isReadable:true, isSystemImmutable:false, isSymbolicLink:false, isExecutable:false, parentDirectoryURL:file "Macintosh HD:Users:shane:Desktop:Test:", hasHiddenExtension:false, labelNumber:0, isWritable:true, path:"/Users/shane/Desktop/Test/IMG_0829.JPG", isPackage:false, name:"IMG_0829.JPG", isDirectory:false, linkCount:1, attributeModificationDate:date "Monday, 9 November 2015 at 11:00:55 AM", creationDate:date "Monday, 12 October 2015 at 3:12:55 PM", isHidden:false, isRegularFile:true, contentAccessDate:date "Monday, 23 November 2015 at 9:48:41 AM", isUserImmutable:false}
