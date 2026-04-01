use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's allAvailableInputSourceIDs()
ASify from theResult
-->	<long list of installed input sources>
theResult as list
-->	<long list of installed input sources>
