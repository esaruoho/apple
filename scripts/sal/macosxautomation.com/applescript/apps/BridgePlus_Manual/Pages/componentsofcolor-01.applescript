use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theColor to current application's NSColor's brownColor()
set theResult to current application's SMSForder's componentsOfColor:theColor
ASify from theResult
-->	{0.6, 0.4, 0.2, 1.0}
theResult as list -- 10.11 only
-->	{0.6, 0.4, 0.2, 1.0}
theResult as list -- 10.9 and 10.10
-->	<as above, but real values lose precision>

set theColor to current application's NSColor's colorWithDeviceWhite:0.5 alpha:1.0
set theResult to current application's SMSForder's componentsOfColor:theColor
ASify from theResult
-->	{0.5, 1.0}
theResult as list -- 10.11 only
-->	{0.5, 1.0}
theResult as list -- 10.9 and 10.10
-->	<as above, but real values lose precision>
