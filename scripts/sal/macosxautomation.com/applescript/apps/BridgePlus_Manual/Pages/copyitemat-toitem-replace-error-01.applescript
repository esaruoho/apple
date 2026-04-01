use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set {theResult, theError} to (current application's SMSForder's copyItemAt:"~/Documents/Something" toItem:"~/Desktop/Something" replace:true |error|:(reference))
if theResult as boolean is false then error (theError's localizedDescription() as text)
