use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set urlFileOrPath to "~/Desktop"
set theResult to current application's SMSForder's itemsIn:urlFileOrPath recursive:true asPaths:true
ASify from theResult
-->	<recursive list of POSIX paths of files and folders on Desktop>
theResult as list
-->	<recursive list of POSIX paths of files and folders on Desktop>
set theResult to current application's SMSForder's itemsIn:urlFileOrPath recursive:true asPaths:false
ASify from theResult
-->	<recursive list of file references of files and folders on Desktop>
theResult as list -- 10.11 only
-->	<recursive list of file references of files and folders on Desktop>
theResult as list -- 10.9 and 10.10
-->	<recursive list of NSURLs of files and folders on Desktop>
