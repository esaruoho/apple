use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's acoshValueOf:(45 / 180 * pi)
ASify from theResult
-->	missing value
set theResult to current application's SMSForder's acoshValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{missing value, 0.306042108613, 1.023227478548}
theResult as list
-->	{missing value, 0.306042108613, 1.023227478548}
