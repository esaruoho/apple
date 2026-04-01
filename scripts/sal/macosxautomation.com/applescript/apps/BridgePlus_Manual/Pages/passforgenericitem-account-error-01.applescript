use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set {theResult, theError} to current application's SMSForder's passForGenericItem:"TesterName" account:"shane" |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
ASify from theResult
-->	"password"
theResult as text
-->	"password"
