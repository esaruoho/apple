use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's log10ValueOf:2.71828182846
ASify from theResult
-->	0.434294481903
theResult as real
-->	0.434294481903
set theResult to current application's SMSForder's log10ValueOf:{1, 2, 10, 100, 400}
ASify from theResult
-->	{0.0, 0.301029995664, 1.0, 2.0, 2.602059991328}
theResult as list
-->	{0.0, 0.301029995664, 1.0, 2.0, 2.602059991328}
