use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theNSBezierPath to current application's NSBezierPath's bezierPath()
set theResult to current application's SMSForder's lineDashCountAndPhaseOfBezier:theNSBezierPath
ASify from theResult
-->	{0.0, 0, 0.0}
theResult as list -- 10.11 only
-->	{0.0, 0, 0.0}
theResult as list -- 10.9 and 10.10
-->	<as above, but real values lose precision>
