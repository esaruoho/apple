use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set fileAliasOrPath to "~/Desktop/Test/IMG_0829.JPG"
set theResult to current application's SMSForder's sizeInfoForFile:fileAliasOrPath
ASify from theResult
-->	{totalFileSize:1867090, totalFileAllocatedSize:1867776, fileAllocatedSize:1867776, fileSize:1867090}
theResult as record
-->	{totalFileSize:1867090, totalFileAllocatedSize:1867776, fileAllocatedSize:1867776, fileSize:1867090}
