use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set {theResult, theError} to current application's SMSForder's passForInternetItem:"Name" account:"account_name" server:"www.blahblah.com" |path|:"/blah/blah" |port|:80 |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
ASify from theResult
-->	"password"
theResult as text
-->	"password"
